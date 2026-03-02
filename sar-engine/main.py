from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from models import GenerateRequest, RegenerateRequest, NarrativeUpdate, NarrativeResponse
from database import (
    fetch_alert, fetch_customer, fetch_flagged_transactions,
    count_prior_alerts, save_narrative, update_narrative,
    get_narratives_for_alert, log_audit
)
from narrative_generator import build_prompt, call_llm

app = FastAPI(title="SAR Narrative Engine", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def serialize_narrative(n: dict) -> dict:
    result = {}
    for key, value in n.items():
        if hasattr(value, "isoformat"):
            result[key] = value.isoformat()
        elif isinstance(value, (int, float, str, bool, type(None))):
            result[key] = value
        else:
            result[key] = str(value)
    return result


@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "sar-engine"}


@app.post("/api/generate-narrative")
async def generate_narrative(request: GenerateRequest):
    alert = fetch_alert(request.alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")

    customer = fetch_customer(str(alert["customer_id"]))
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    transactions = fetch_flagged_transactions(request.alert_id)
    prior_count = count_prior_alerts(str(alert["customer_id"]), request.alert_id)

    prompt = build_prompt(customer, alert, transactions, prior_count)

    try:
        llm_result = await call_llm(prompt)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"LLM API error: {str(e)}")

    narrative = save_narrative(
        alert_id=request.alert_id,
        narrative_text=llm_result["narrative"],
        llm_model=llm_result["model"],
        prompt_tokens=llm_result["prompt_tokens"],
        completion_tokens=llm_result["completion_tokens"]
    )

    log_audit("narrative", str(narrative["id"]), "created", "system", {
        "alert_id": request.alert_id,
        "model": llm_result["model"]
    })

    return serialize_narrative(narrative)


@app.post("/api/regenerate-narrative/{narrative_id}")
async def regenerate_narrative(narrative_id: str, request: RegenerateRequest = None):
    narratives_conn = get_narratives_by_id(narrative_id)
    if not narratives_conn:
        raise HTTPException(status_code=404, detail="Narrative not found")

    existing = narratives_conn
    alert_id = str(existing["alert_id"])

    alert = fetch_alert(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")

    customer = fetch_customer(str(alert["customer_id"]))
    transactions = fetch_flagged_transactions(alert_id)
    prior_count = count_prior_alerts(str(alert["customer_id"]), alert_id)

    prompt = build_prompt(customer, alert, transactions, prior_count)

    extra = request.instructions if request else None

    try:
        llm_result = await call_llm(prompt, extra_instructions=extra)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"LLM API error: {str(e)}")

    narrative = save_narrative(
        alert_id=alert_id,
        narrative_text=llm_result["narrative"],
        llm_model=llm_result["model"],
        prompt_tokens=llm_result["prompt_tokens"],
        completion_tokens=llm_result["completion_tokens"]
    )

    log_audit("narrative", str(narrative["id"]), "regenerated", "system", {
        "alert_id": alert_id,
        "model": llm_result["model"],
        "instructions": extra
    })

    return serialize_narrative(narrative)


@app.put("/api/narratives/{narrative_id}")
async def edit_narrative(narrative_id: str, request: NarrativeUpdate):
    updated = update_narrative(narrative_id, request.narrative_text)
    if not updated:
        raise HTTPException(status_code=404, detail="Narrative not found")

    log_audit("narrative", narrative_id, "edited", "analyst", {
        "text_length": len(request.narrative_text)
    })

    return serialize_narrative(updated)


@app.get("/api/narratives/{alert_id}")
async def get_narratives(alert_id: str):
    narratives = get_narratives_for_alert(alert_id)
    return [serialize_narrative(n) for n in narratives]


def get_narratives_by_id(narrative_id: str) -> dict:
    import psycopg2
    import psycopg2.extras
    from database import get_connection

    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM sar_narratives WHERE id = %s", (narrative_id,))
        row = cur.fetchone()
        cur.close()
        return dict(row) if row else None
    finally:
        conn.close()