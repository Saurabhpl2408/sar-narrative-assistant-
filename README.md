# SAR Narrative Assistant

**AI-Powered Suspicious Activity Report Generator for Banking Compliance Teams**

SAR Narrative Assistant is a full-stack application that helps compliance officers at banks detect suspicious transactions and generate high-quality SAR (Suspicious Activity Report) narratives for FinCEN filing. The system ingests bank transaction data, applies rule-based AML detection, flags suspicious activity, and uses LLM-powered narrative generation to draft SAR filings — saving compliance teams hours of manual writing per case.

---

## The Problem

Banks file hundreds of thousands of SARs with FinCEN annually. Each requires a detailed free-text narrative explaining why activity is suspicious. Compliance analysts spend 30–60 minutes writing each narrative manually. FinCEN has noted that many SARs are filed with inadequate narratives, reducing their value to law enforcement. Recent FinCEN guidance (October 2025) emphasizes filing quality over quantity — making better narratives more important than ever.

## The Solution

SAR Narrative Assistant automates the first draft of SAR narratives while keeping the human compliance officer in the loop for review, editing, and approval. The system:

- **Detects** suspicious patterns using 5 real AML detection rules
- **Generates** FinCEN-compliant SAR narratives using LLM APIs (Claude, GPT-4o-mini, or fallback templates)
- **Enables** compliance officers to review, edit, and approve narratives through a modern dashboard
- **Tracks** full version history and audit trails for regulatory compliance

---

## Architecture

```
┌──────────────┐     ┌──────────────────────┐     ┌─────────────────┐
│              │     │                      │     │                 │
│   React      │────▶│  Java Spring Boot    │────▶│  PostgreSQL     │
│   Dashboard  │     │  Transaction Service │     │  Database       │
│   (Port 3000)│     │  (Port 8080)         │     │  (Port 5432)    │
│              │     │                      │     │                 │
└──────┬───────┘     └──────────────────────┘     └────────┬────────┘
       │                                                    │
       │             ┌──────────────────────┐               │
       │             │                      │               │
       └────────────▶│  Python FastAPI      │───────────────┘
                     │  SAR Narrative Engine │
                     │  (Port 8000)         │
                     │                      │
                     └──────────────────────┘
```

| Component | Technology | Responsibility |
|-----------|-----------|----------------|
| Transaction Service | Java 21, Spring Boot 3.2, JPA | Ingests transactions, runs 5 AML detection rules, exposes REST APIs |
| SAR Narrative Engine | Python 3.12, FastAPI | Assembles case context, calls LLM API, generates SAR narrative drafts |
| Database | PostgreSQL 16 | Stores customers, transactions, alerts, narratives, audit log |
| Dashboard | React 18, Tailwind CSS, Recharts | Compliance officer UI: alert queue, case review, narrative editing |

---

## AML Detection Rules

The transaction monitoring engine implements 5 real-world AML detection patterns:

### 1. Structuring Detection
Multiple cash deposits below $10,000 within a 48-hour window that total above $10,000. Structuring (also called "smurfing") is a federal crime — deliberately breaking transactions into smaller amounts to avoid Currency Transaction Report (CTR) filing requirements.

### 2. High-Risk Jurisdiction
Wire transfers to or from FATF high-risk or OFAC sanctioned countries (Iran, North Korea, Myanmar, Syria, etc.). These jurisdictions carry elevated money laundering and terrorist financing risk.

### 3. Rapid Fund Movement (Layering)
Large inbound deposit followed by a large outbound wire transfer within 24 hours. This "pass-through" pattern is consistent with layering — rapidly moving funds through accounts to obscure their origin.

### 4. Volume Spike
Transaction volume or total amount in a recent period exceeds 3x the customer's 90-day historical baseline. Sudden deviations from established behavioral patterns are a key AML indicator.

### 5. Large Cash Transaction
Cash deposits or withdrawals of $10,000 or more, triggering CTR requirements and warranting additional review based on the customer's profile.

---

## SAR Narrative Generation

The narrative engine follows FinCEN's SAR Narrative Guidance framework, structuring every narrative around the "5 W's":

- **Who** — Subject identification (name, account, occupation, relationship to the bank)
- **What** — Specific transactions with dates, amounts, types, and counterparties
- **When** — Exact date range of suspicious activity
- **Where** — Branch locations and jurisdictions involved
- **Why** — Clear explanation of why the activity is suspicious relative to the customer's profile

The system supports three LLM providers with automatic fallback:

1. **Anthropic Claude** — Highest quality narratives
2. **OpenAI GPT-4o-mini** — Cost-effective alternative
3. **Fallback Template** — Rule-specific template narratives that work without any API key

If an LLM API call fails (quota exceeded, network error, etc.), the system automatically falls back to template-based generation — ensuring the application always produces a usable narrative.

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Backend (Transactions) | Java 21, Spring Boot 3.2, Spring Data JPA | Industry standard for enterprise banking applications |
| Backend (SAR Engine) | Python 3.12, FastAPI, httpx | Best ecosystem for LLM integration, fast async API |
| Database | PostgreSQL 16 | Production-grade relational DB for transactional banking data |
| Frontend | React 18, Tailwind CSS, Recharts | Modern SPA with responsive dark theme and data visualization |
| Infrastructure | Docker, Docker Compose | One-command setup, consistent environments |

---

## Database Schema

```
customers          transactions        alerts              sar_narratives      audit_log
├── id (UUID)      ├── id (UUID)       ├── id (UUID)       ├── id (UUID)       ├── id (SERIAL)
├── name           ├── customer_id     ├── customer_id     ├── alert_id        ├── entity_type
├── account_number ├── type            ├── rule_triggered   ├── narrative_text  ├── entity_id
├── account_type   ├── amount          ├── severity         ├── version         ├── action
├── risk_rating    ├── direction       ├── status           ├── status          ├── performed_by
├── country        ├── counterparty    ├── flagged_txn_ids  ├── generated_by    ├── details (JSONB)
├── opened_date    ├── branch          ├── total_amount     ├── llm_model       └── created_at
├── occupation     ├── transaction_date├── detection_date   ├── prompt_tokens
└── created_at     └── created_at      └── created_at       └── created_at
```

---

## Getting Started

### Prerequisites

- Docker and Docker Compose
- (Optional) Anthropic or OpenAI API key for AI-powered narratives

### Setup

```bash
git clone https://github.com/yourusername/sar-narrative-assistant.git
cd sar-narrative-assistant

cp .env.example .env
# Edit .env with your LLM provider choice and API key (or leave as fallback)

docker compose up --build
```

This starts all 4 services:
- PostgreSQL on port 5432 (auto-seeds with 47 customers and 122 transactions)
- Java Transaction Service on port 8080
- Python SAR Engine on port 8000
- React Dashboard on port 3000

### Run a Transaction Scan

```bash
curl -X POST http://localhost:8080/api/transactions/scan \
  -H "Content-Type: application/json" \
  -d '{"from":"2025-11-01T00:00:00","to":"2025-11-30T23:59:59"}'
```

This scans November 2025 transactions and creates alerts for detected suspicious activity.

### Open the Dashboard

Navigate to `http://localhost:3000` to see the compliance dashboard with all detected alerts.

---

## Dashboard Features

### Alert Queue
- Table of all alerts sorted by severity and date
- Filter by status (New, Reviewing, SAR Filed, Dismissed) and severity (High, Medium, Low)
- Click any alert to open the full case detail view

### Alert Detail
- Customer profile card with account information and risk rating
- Timeline of flagged transactions with amounts, dates, and counterparties
- Detection rule explanation
- SAR Narrative editor with Generate, Edit, Save, and Version History
- Status management buttons (Mark Reviewing, Mark SAR Filed, Dismiss)

### Dashboard Analytics
- Summary stat cards: total alerts, new alerts, SARs filed, total transactions
- Bar chart of alerts by detection rule type
- Donut chart of severity distribution
- Status breakdown grid

---

## API Reference

### Transaction Service (Port 8080)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/alerts` | List all alerts (filters: `?status=new&severity=high`) |
| GET | `/api/alerts/{id}` | Get alert with customer and transaction details |
| PUT | `/api/alerts/{id}/status` | Update alert status |
| POST | `/api/transactions/scan` | Run detection rules on a date range |
| GET | `/api/customers/{id}` | Get customer profile |
| GET | `/api/customers/{id}/transactions` | Get customer transaction history |
| GET | `/api/dashboard/stats` | Summary statistics for dashboard |

### SAR Engine (Port 8000)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/generate-narrative` | Generate SAR narrative for an alert |
| POST | `/api/regenerate-narrative/{id}` | Regenerate with additional instructions |
| PUT | `/api/narratives/{id}` | Edit narrative text |
| GET | `/api/narratives/{alert_id}` | Get all narrative versions for an alert |
| GET | `/api/health` | Health check |

---

## Project Structure

```
sar-narrative-assistant/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
│
├── db/
│   ├── init.sql                         # Schema + seed data (47 customers, 122 transactions)
│   └── seed_transactions.py             # Optional: generate additional synthetic data
│
├── transaction-service/                 # Java Spring Boot
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/sar/
│       │   ├── SarApplication.java
│       │   ├── config/CorsConfig.java
│       │   ├── model/
│       │   │   ├── Customer.java
│       │   │   ├── Transaction.java
│       │   │   └── Alert.java
│       │   ├── repository/
│       │   │   ├── CustomerRepository.java
│       │   │   ├── TransactionRepository.java
│       │   │   └── AlertRepository.java
│       │   ├── service/
│       │   │   ├── DetectionRuleEngine.java
│       │   │   └── AlertService.java
│       │   └── controller/
│       │       ├── AlertController.java
│       │       └── DashboardController.java
│       └── resources/application.yml
│
├── sar-engine/                          # Python FastAPI
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py
│   ├── models.py
│   ├── database.py
│   ├── narrative_generator.py
│   └── prompts/sar_template.txt
│
└── dashboard/                           # React + Tailwind
    ├── Dockerfile
    ├── package.json
    ├── tailwind.config.js
    ├── postcss.config.js
    ├── public/index.html
    └── src/
        ├── index.js
        ├── index.css
        ├── App.jsx
        ├── api/client.jsx
        ├── components/
        │   ├── Sidebar.jsx
        │   ├── SeverityBadge.jsx
        │   ├── StatusBadge.jsx
        │   ├── StatsCard.jsx
        │   ├── CustomerCard.jsx
        │   ├── TransactionTimeline.jsx
        │   └── NarrativeEditor.jsx
        └── pages/
            ├── AlertQueue.jsx
            ├── AlertDetail.jsx
            └── DashboardStats.jsx
```

---

## Seed Data

The database is pre-loaded with realistic synthetic data:

- **47 customers** with varied profiles (35 normal + 12 suspicious)
- **122 transactions** across September–November 2025
- Embedded suspicious patterns for each detection rule:
  - 3 customers with structuring patterns (multiple sub-$10K cash deposits)
  - 3 customers with high-risk jurisdiction wires (Iran, Myanmar, North Korea)
  - 3 customers with rapid fund movement (large deposit → immediate outbound wire)
  - 3 customers with volume spikes (sudden 5x increase in activity)

All data is fictional and generated for demonstration purposes only.

---

## Environment Configuration

```env
# LLM Provider: "anthropic", "openai", or "fallback"
LLM_PROVIDER=fallback

# Anthropic API Key (for Claude)
ANTHROPIC_API_KEY=

# OpenAI API Key (for GPT-4o-mini)
OPENAI_API_KEY=
```

---

## Built By

**Saurabh Lohokare**
- MS Computer Science, Northeastern University (GPA: 4.0)
- [LinkedIn](https://linkedin.com/in/saurabhlohokare) | [GitHub](https://github.com/saurabhlohokare)

Built as a portfolio project demonstrating full-stack development, AML domain knowledge, and AI integration for banking compliance technology.

---

## Acknowledgments

- SAR narrative structure based on [FinCEN SAR Narrative Guidance](https://www.fincen.gov/system/files/shared/sarnarrcompletguidfinal_112003.pdf)
- Detection rules modeled after real-world AML transaction monitoring patterns
- Built with Java, Python, PostgreSQL, React, and Docker