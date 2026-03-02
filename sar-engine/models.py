from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from uuid import UUID


class GenerateRequest(BaseModel):
    alert_id: str


class RegenerateRequest(BaseModel):
    instructions: Optional[str] = None


class NarrativeUpdate(BaseModel):
    narrative_text: str


class NarrativeResponse(BaseModel):
    id: str
    alert_id: str
    narrative_text: str
    version: int
    status: str
    generated_by: str
    llm_model: Optional[str] = None
    prompt_tokens: Optional[int] = None
    completion_tokens: Optional[int] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class CustomerInfo(BaseModel):
    name: str
    account_number: str
    account_type: str
    risk_rating: str
    country: str
    opened_date: str
    occupation: Optional[str] = None


class TransactionInfo(BaseModel):
    id: str
    type: str
    amount: float
    direction: str
    counterparty_name: Optional[str] = None
    counterparty_country: Optional[str] = None
    description: Optional[str] = None
    branch: Optional[str] = None
    transaction_date: str


class AlertInfo(BaseModel):
    id: str
    customer_id: str
    rule_triggered: str
    severity: str
    status: str
    total_flagged_amount: float
    detection_date: str


class CaseContext(BaseModel):
    alert: AlertInfo
    customer: CustomerInfo
    transactions: list[TransactionInfo]
    prior_alert_count: int