import os
import psycopg2
import psycopg2.extras


DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://saruser:sarpass123@localhost:5432/sar_assistant")


def get_connection():
    return psycopg2.connect(DATABASE_URL)


def fetch_alert(alert_id: str) -> dict:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM alerts WHERE id = %s", (alert_id,))
        alert = cur.fetchone()
        cur.close()
        return dict(alert) if alert else None
    finally:
        conn.close()


def fetch_customer(customer_id: str) -> dict:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM customers WHERE id = %s", (customer_id,))
        customer = cur.fetchone()
        cur.close()
        return dict(customer) if customer else None
    finally:
        conn.close()


def fetch_flagged_transactions(alert_id: str) -> list:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT flagged_transaction_ids FROM alerts WHERE id = %s", (alert_id,))
        row = cur.fetchone()
        if not row or not row["flagged_transaction_ids"]:
            cur.close()
            return []

        txn_ids = row["flagged_transaction_ids"]
        if not txn_ids:
            cur.close()
            return []

        cur.execute(
            "SELECT * FROM transactions WHERE id = ANY(%s) ORDER BY transaction_date ASC",
            (txn_ids,)
        )
        transactions = [dict(r) for r in cur.fetchall()]
        cur.close()
        return transactions
    finally:
        conn.close()


def count_prior_alerts(customer_id: str, current_alert_id: str) -> int:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT COUNT(*) FROM alerts WHERE customer_id = %s AND id != %s",
            (customer_id, current_alert_id)
        )
        count = cur.fetchone()[0]
        cur.close()
        return count
    finally:
        conn.close()


def save_narrative(alert_id: str, narrative_text: str, llm_model: str,
                   prompt_tokens: int, completion_tokens: int) -> dict:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        cur.execute(
            "SELECT COALESCE(MAX(version), 0) FROM sar_narratives WHERE alert_id = %s",
            (alert_id,)
        )
        max_version = cur.fetchone()["coalesce"]
        new_version = max_version + 1

        cur.execute(
            """INSERT INTO sar_narratives 
            (alert_id, narrative_text, version, status, generated_by, llm_model, prompt_tokens, completion_tokens)
            VALUES (%s, %s, %s, 'draft', 'ai', %s, %s, %s)
            RETURNING *""",
            (alert_id, narrative_text, new_version, llm_model, prompt_tokens, completion_tokens)
        )
        narrative = dict(cur.fetchone())
        conn.commit()
        cur.close()
        return narrative
    finally:
        conn.close()


def update_narrative(narrative_id: str, narrative_text: str) -> dict:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            """UPDATE sar_narratives 
            SET narrative_text = %s, updated_at = NOW(), generated_by = 'manual'
            WHERE id = %s RETURNING *""",
            (narrative_text, narrative_id)
        )
        narrative = cur.fetchone()
        conn.commit()
        cur.close()
        return dict(narrative) if narrative else None
    finally:
        conn.close()


def get_narratives_for_alert(alert_id: str) -> list:
    conn = get_connection()
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute(
            "SELECT * FROM sar_narratives WHERE alert_id = %s ORDER BY version DESC",
            (alert_id,)
        )
        narratives = [dict(r) for r in cur.fetchall()]
        cur.close()
        return narratives
    finally:
        conn.close()


def log_audit(entity_type: str, entity_id: str, action: str, performed_by: str, details: dict = None):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """INSERT INTO audit_log (entity_type, entity_id, action, performed_by, details)
            VALUES (%s, %s, %s, %s, %s)""",
            (entity_type, entity_id, action, performed_by, psycopg2.extras.Json(details))
        )
        conn.commit()
        cur.close()
    finally:
        conn.close()