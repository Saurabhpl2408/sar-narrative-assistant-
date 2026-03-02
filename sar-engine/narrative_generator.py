import os
import httpx
from pathlib import Path

LLM_PROVIDER = os.getenv("LLM_PROVIDER", "anthropic")
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

TEMPLATE_PATH = Path(__file__).parent / "prompts" / "sar_template.txt"

RULE_DESCRIPTIONS = {
    "STRUCTURING": "Structuring - Multiple cash transactions below the $10,000 CTR threshold within a short time window, totaling above $10,000. This pattern is consistent with deliberate structuring to avoid Currency Transaction Report (CTR) filing requirements.",
    "HIGH_RISK_JURISDICTION": "High-Risk Jurisdiction - Wire transfers to or from countries on the FATF high-risk or OFAC sanctioned list. These jurisdictions carry elevated money laundering and terrorist financing risk.",
    "RAPID_FUND_MOVEMENT": "Rapid Fund Movement (Layering) - Large inbound deposit followed by a large outbound wire transfer within 24 hours. This pass-through pattern is consistent with layering, a technique used to obscure the origin of funds.",
    "VOLUME_SPIKE": "Volume Spike - Transaction volume or total amount significantly exceeds the customer's established 90-day baseline (3x or greater). Sudden deviations from normal behavior are a key AML indicator.",
    "LARGE_CASH": "Large Cash Transaction - Cash deposits or withdrawals of $10,000 or more, triggering Currency Transaction Report (CTR) requirements and warranting additional review."
}


def build_prompt(customer: dict, alert: dict, transactions: list, prior_alert_count: int) -> str:
    template = TEMPLATE_PATH.read_text()

    txn_lines = []
    for t in transactions:
        line = (
            f"  - {t['transaction_date'].strftime('%Y-%m-%d %H:%M')} | "
            f"{t['type']} | "
            f"${t['amount']:,.2f} | "
            f"{t['direction']} | "
            f"Counterparty: {t.get('counterparty_name') or 'N/A'} | "
            f"Country: {t.get('counterparty_country') or 'USA'} | "
            f"Branch: {t.get('branch') or 'N/A'}"
        )
        txn_lines.append(line)
    transaction_table = "\n".join(txn_lines)

    dates = [t['transaction_date'] for t in transactions]
    if dates:
        date_range = f"{min(dates).strftime('%Y-%m-%d')} to {max(dates).strftime('%Y-%m-%d')}"
    else:
        date_range = "Unknown"

    rule_detail = RULE_DESCRIPTIONS.get(alert['rule_triggered'], alert['rule_triggered'])

    prompt = template.format(
        customer_name=customer['name'],
        account_number=customer['account_number'],
        account_type=customer['account_type'],
        occupation=customer.get('occupation') or 'Unknown',
        risk_rating=customer['risk_rating'],
        country=customer['country'],
        opened_date=customer['opened_date'].strftime('%Y-%m-%d'),
        rule_triggered=rule_detail,
        severity=alert['severity'],
        transaction_table=transaction_table,
        total_amount=f"{float(alert['total_flagged_amount']):,.2f}",
        date_range=date_range,
        prior_alert_count=prior_alert_count
    )

    return prompt


async def call_llm(prompt: str, extra_instructions: str = None) -> dict:
    if extra_instructions:
        prompt = prompt + f"\n\nAdditional instructions from the analyst: {extra_instructions}"

    if LLM_PROVIDER == "anthropic" and ANTHROPIC_API_KEY:
        try:
            return await call_anthropic(prompt)
        except Exception as e:
            print(f"Anthropic API failed, falling back to template: {e}")
            return generate_fallback(prompt)
    elif LLM_PROVIDER == "openai" and OPENAI_API_KEY:
        try:
            return await call_openai(prompt)
        except Exception as e:
            print(f"OpenAI API failed, falling back to template: {e}")
            return generate_fallback(prompt)
    else:
        return generate_fallback(prompt)


async def call_anthropic(prompt: str) -> dict:
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": ANTHROPIC_API_KEY,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json"
                },
                json={
                    "model": "claude-3-haiku-20240307",
                    "max_tokens": 1024,
                    "messages": [
                        {"role": "user", "content": prompt}
                    ]
                }
            )

            data = response.json()

            if response.status_code != 200:
                print(f"Anthropic API returned {response.status_code}, falling back to template")
                return generate_fallback(prompt)

            narrative_text = ""
            for block in data.get("content", []):
                if block.get("type") == "text":
                    narrative_text += block["text"]

            return {
                "narrative": narrative_text.strip(),
                "model": data.get("model", "claude-3-haiku-20240307"),
                "prompt_tokens": data.get("usage", {}).get("input_tokens", 0),
                "completion_tokens": data.get("usage", {}).get("output_tokens", 0)
            }
    except Exception as e:
        print(f"Anthropic call exception, falling back to template: {e}")
        return generate_fallback(prompt)


async def call_openai(prompt: str) -> dict:
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {OPENAI_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "gpt-4o-mini",
                    "max_tokens": 1024,
                    "messages": [
                        {"role": "user", "content": prompt}
                    ]
                }
            )

            data = response.json()

            if response.status_code != 200:
                print(f"OpenAI API returned {response.status_code}, falling back to template")
                return generate_fallback(prompt)

            narrative_text = data["choices"][0]["message"]["content"]

            return {
                "narrative": narrative_text.strip(),
                "model": data.get("model", "gpt-4o-mini"),
                "prompt_tokens": data.get("usage", {}).get("prompt_tokens", 0),
                "completion_tokens": data.get("usage", {}).get("completion_tokens", 0)
            }
    except Exception as e:
        print(f"OpenAI call exception, falling back to template: {e}")
        return generate_fallback(prompt)


def generate_fallback(prompt: str) -> dict:
    lines = prompt.split("\n")
    fields = {}

    for line in lines:
        if ":" in line and not line.strip().startswith("-"):
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()

    customer_name = fields.get("Customer Name", "Unknown")
    account_number = fields.get("Account Number", "Unknown")
    account_type = fields.get("Account Type", "Unknown")
    occupation = fields.get("Occupation", "Unknown")
    risk_rating = fields.get("Risk Rating", "Unknown")
    opened_date = fields.get("Account Opened", "Unknown")
    total_amount = fields.get("Total Flagged Amount", "$0")
    date_range = fields.get("Date Range", "Unknown")
    prior_alerts = fields.get("Prior Alerts on This Customer", "0")

    rule_raw = fields.get("Detection Rule Triggered", "Unknown")
    severity = fields.get("Alert Severity", "Unknown")

    if "Structuring" in rule_raw:
        rule_name = "structuring"
        activity_desc = (
            f"Multiple cash deposits were made in amounts just below the $10,000 Currency "
            f"Transaction Report (CTR) threshold. The transactions were conducted within a "
            f"short time window across different branch locations. This pattern is consistent "
            f"with deliberate structuring to avoid CTR filing requirements, which is a violation "
            f"of the Bank Secrecy Act."
        )
    elif "High-Risk Jurisdiction" in rule_raw:
        rule_name = "wire transfers involving high-risk jurisdictions"
        activity_desc = (
            f"Wire transfers were conducted to or from countries identified on the FATF "
            f"high-risk jurisdictions list or subject to OFAC sanctions. These transactions "
            f"warrant enhanced due diligence given the elevated money laundering and terrorist "
            f"financing risks associated with these jurisdictions."
        )
    elif "Rapid Fund Movement" in rule_raw:
        rule_name = "rapid movement of funds"
        activity_desc = (
            f"A large inbound deposit was received and subsequently transferred outbound via "
            f"wire transfer within 24 hours. This pass-through pattern is inconsistent with "
            f"normal account usage and may indicate layering activity designed to obscure "
            f"the origin of funds."
        )
    elif "Volume Spike" in rule_raw:
        rule_name = "unusual volume spike"
        activity_desc = (
            f"Transaction volume and total amounts during the flagged period significantly "
            f"exceeded the customer's established 90-day behavioral baseline by a factor of "
            f"three or more. This sudden deviation from normal activity patterns is inconsistent "
            f"with the customer's expected account usage."
        )
    elif "Large Cash" in rule_raw:
        rule_name = "large cash transactions"
        activity_desc = (
            f"Cash deposits or withdrawals of $10,000 or more were identified, triggering "
            f"Currency Transaction Report (CTR) requirements. Given the customer's profile "
            f"and account history, these cash transactions warrant additional review."
        )
    else:
        rule_name = "suspicious activity"
        activity_desc = (
            f"Transactions were flagged by the automated monitoring system as inconsistent "
            f"with the customer's expected account behavior."
        )

    prior_text = ""
    if prior_alerts and prior_alerts != "0":
        prior_text = (
            f" It should be noted that {prior_alerts} prior alert(s) have been generated "
            f"on this customer's account, which may indicate a pattern of suspicious behavior."
        )

    narrative = (
        f"This SAR is being filed to report suspicious activity involving {customer_name}, "
        f"account number {account_number} ({account_type} account). The subject is employed "
        f"as a/an {occupation} and has maintained this account since {opened_date}. "
        f"The customer's current risk rating is {risk_rating}.\n\n"
        f"The institution's automated transaction monitoring system detected {rule_name} "
        f"during the period of {date_range}. {activity_desc}\n\n"
        f"The total amount involved in the flagged transactions is {total_amount}. "
        f"The activity identified is inconsistent with the expected transaction patterns "
        f"for this customer's account profile, occupation, and historical banking behavior.{prior_text}\n\n"
        f"This filing is being made pursuant to 31 USC 5318(g) and 31 CFR 1020.320. "
        f"The institution will continue to monitor this account for additional suspicious activity."
    )

    return {
        "narrative": narrative,
        "model": "fallback-template",
        "prompt_tokens": 0,
        "completion_tokens": 0
    }