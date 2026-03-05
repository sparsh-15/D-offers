# Low-Level Design: NBFC-Only Funding with Bank Statement, CIBIL Score & ML

**Version:** 1.0  
**Last Updated:** March 1, 2026  
**Scope:** Bank statement processing, small-transaction extraction, CIBIL score (1–10), Business Rules Engine (BRE) for NBFC-only funding, and ML-based eligibility/scoring.

---

## Table of Contents

1. [Overview & Objectives](#1-overview--objectives)
2. [Bank Statement Processing & Small-Transaction Extraction](#2-bank-statement-processing--small-transaction-extraction)
3. [CIBIL Integration & Score Mapping (1–10)](#3-cibil-integration--score-mapping-110)
4. [Business Rules Engine (BRE) for NBFC-Only Funding](#4-business-rules-engine-bre-for-nbfc-only-funding)
5. [ML Model Design](#5-ml-model-design)
6. [End-to-End Data Flow & Component Diagram](#6-end-to-end-data-flow--component-diagram)
7. [Data Models & Interfaces](#7-data-models--interfaces)
8. [Non-Functional Considerations](#8-non-functional-considerations)

---

## 1. Overview & Objectives

### 1.1 Purpose

Design the low-level behaviour for:

- **Ingesting** a customer’s **3-month bank statement** and **extracting small transactions**.
- **Integrating with CIBIL** (or equivalent bureau) to obtain a **customer score**.
- **Mapping** that score to an internal **1–10 scale** (10 = best, 1 = worst).
- **BRE** to decide **NBFC-only funding** eligibility and limits.
- **ML model** to combine statement behaviour + CIBIL and improve scoring/eligibility.

### 1.2 Out-of-Scope (LLD Assumptions)

- Exact CIBIL API contract (use placeholder; integrate with actual CIBIL/Experian docs).
- Legal/compliance (e.g. consent, data retention) — to be covered in a separate compliance doc.
- UI/UX for upload and consent — referenced only at API level.

---

## 2. Bank Statement Processing & Small-Transaction Extraction

### 2.1 Input: 3-Month Bank Statement

| Aspect | Detail |
|--------|--------|
| **Duration** | Rolling 3 months (90–92 days) from statement end date. |
| **Formats** | PDF (primary), CSV/Excel (optional). PDF via parser + optional OCR fallback. |
| **Validation** | Must contain: account number (masked allowed), date range, transaction list (date, narration, debit/credit, balance). |

### 2.2 Parsing Pipeline

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│ Upload (PDF/CSV)│────▶│ Format Detector  │────▶│ Parser (PDF/CSV)    │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│ Enrichment &    │◀────│ Normalise Txns   │◀────│ Raw Transactions    │
│ Categorisation  │     │ (amount, date)   │     └─────────────────────┘
└─────────────────┘     └──────────────────┘
```

**Steps:**

1. **Format detection**  
   - By file extension and magic bytes (PDF vs CSV/Excel).

2. **PDF parsing**  
   - Use a library (e.g. pdf-parse, pdfplumber, or cloud textract) to extract text/tables.  
   - Table detection: identify columns such as Date, Narration/Description, Debit, Credit, Balance.  
   - Handle multi-page statements and common Indian bank layouts.

3. **CSV/Excel parsing**  
   - Map columns to canonical fields: `date`, `narration`, `debit`, `credit`, `balance`, `reference`.

4. **Normalisation**  
   - Single `amount` (signed: + credit, − debit) and `date` (ISO).  
   - Strip narration (trim, lower case for matching).  
   - Reject rows with invalid date or amount.

### 2.3 Definition of “Small Transaction”

**Small transaction** = transaction whose **absolute amount** is within a configurable range, used to infer **regularity of small-ticket behaviour** (e.g. retail, utility, small repayments).

| Parameter | Default (configurable) | Description |
|-----------|------------------------|-------------|
| `small_txn_min_inr` | 1 | Lower bound (₹). |
| `small_txn_max_inr` | 5,000 | Upper bound (₹). |

**Extraction logic (pseudo):**

```text
FOR each normalised transaction:
  amount_abs = ABS(amount)
  IF amount_abs >= small_txn_min_inr AND amount_abs <= small_txn_max_inr:
    ADD to small_transactions[]
```

### 2.4 Output: Small-Transaction Aggregates (for ML/BRE)

Derived metrics (over 3 months) to be stored and used downstream:

| Metric | Description |
|--------|-------------|
| `small_txn_count` | Number of small transactions. |
| `small_txn_credit_count` | Count of small credits. |
| `small_txn_debit_count` | Count of small debits. |
| `small_txn_avg_amount` | Mean absolute amount of small transactions. |
| `small_txn_std_amount` | Std dev of small transaction amounts. |
| `small_txn_frequency_per_week` | small_txn_count / (weeks in period). |
| `small_txn_share_of_total_count` | small_txn_count / total_txn_count. |
| `small_txn_share_of_total_volume` | Sum(|small amounts|) / Sum(|all amounts|). |

Optional: monthly breakdown (e.g. `small_txn_count_m1`, `m2`, `m3`) for trend features.

### 2.5 Component: Statement Parser Service

- **Input:** File (PDF/CSV) + customer/session identifier.  
- **Output:** Structured statement (account metadata + list of normalised transactions) + small-transaction list + aggregate metrics above.  
- **Failure:** Invalid format, no table found, or date range &lt; 2 months → return error and no small-transaction output.

---

## 3. CIBIL Integration & Score Mapping (1–10)

### 3.1 Bureau Call (Placeholder)

- **Input:** Customer identifiers as required by CIBIL (e.g. PAN, mobile, consent token).  
- **Output:** Bureau response containing score and/or score band (exact fields depend on CIBIL API).  
- **Caching:** Cache bureau response per customer with TTL (e.g. 30 days) to avoid repeated hits.

### 3.2 Internal Score Scale: 1–10

- **10** = best (lowest risk).  
- **1** = worst (highest risk).

Mapping from bureau raw score/band to 1–10:

| Bureau score range (example) | Internal score (1–10) |
|-----------------------------|------------------------|
| 750–900 (or “Excellent”)    | 10                    |
| 700–749                     | 8–9                   |
| 650–699                     | 6–7                   |
| 550–649                     | 4–5                   |
| 300–549 (or “Poor”)         | 1–3                   |

Exact buckets to be set from CIBIL’s actual scale and your risk policy.

**Mapping function (conceptual):**

```text
FUNCTION map_bureau_to_internal(bureau_score, bureau_band) -> 1..10
  IF bureau_band present: use band → 1–10 lookup table
  ELSE: use linear/interpolated mapping from bureau_score min/max to 1–10
  CLAMP result to [1, 10]
```

### 3.3 Output for BRE/ML

- `cibil_score_internal` (1–10).  
- Optional: `cibil_raw_score`, `cibil_band`, `cibil_last_fetched_at`.

---

## 4. Business Rules Engine (BRE) for NBFC-Only Funding

### 4.1 Role of the BRE

- **Input:** Customer attributes + statement-derived metrics + CIBIL internal score (1–10).  
- **Output:** Eligibility for **NBFC-only funding** (yes/no) and optional **tier/limit** (e.g. limit band).  
- **Purpose:** Enforce policy (e.g. “only offer NBFC funding when criteria A, B, C are met”) without hard-coding in application code.

### 4.2 Rule Model (Logical)

Rules are **conditions + outcome**. Example structure:

- **Condition:** list of AND/OR clauses on input fields.  
- **Outcome:** `eligible_nbfc_only: true/false`, optional `tier`, `max_limit_band`.

Example rules (conceptual):

| Rule ID | Condition | Outcome |
|---------|-----------|---------|
| R1 | cibil_score_internal >= 7 AND small_txn_count >= 20 | eligible_nbfc_only = true, tier = A |
| R2 | cibil_score_internal >= 5 AND cibil_score_internal &lt; 7 AND small_txn_frequency_per_week >= 2 | eligible_nbfc_only = true, tier = B |
| R3 | cibil_score_internal &lt; 4 | eligible_nbfc_only = false |
| R4 | default | eligible_nbfc_only = false |

### 4.3 BRE Inputs (from Statement + CIBIL + Customer)

- `cibil_score_internal` (1–10)  
- `small_txn_count`, `small_txn_frequency_per_week`, `small_txn_share_of_total_count`  
- Optional: `small_txn_credit_count`, `small_txn_debit_count`, `small_txn_avg_amount`  
- Customer: `customer_id`, `existing_customer_segment` (if any)

### 4.4 BRE Output

- `eligible_nbfc_only`: boolean  
- `tier`: string (e.g. "A", "B", "C")  
- `max_limit_band`: optional (e.g. "LOW", "MEDIUM", "HIGH")  
- `rule_ids_fired`: list (for audit)

### 4.5 Implementation Options

- **Option A:** Rule set in JSON/YAML; evaluator in application code (e.g. Node service).  
- **Option B:** Embedded rule engine (e.g. json-rules-engine, node-rules).  
- **Option C:** External BRE/decision service (e.g. DMN, custom microservice).

Recommendation: Start with **Option A or B** for speed; move to **Option C** if rules become complex or non-technical users need to edit them.

---

## 5. ML Model Design

### 5.1 Goal

- Use **bank statement behaviour** (especially small-transaction metrics) + **CIBIL internal score (1–10)** to improve **eligibility** or **risk tier** for NBFC-only funding.  
- Optionally predict a **continuous score 1–10** that can override or blend with CIBIL.

### 5.2 Target Variable

- **Primary:** Binary — `eligible_nbfc_only` (or derived from historical disbursement/repayment).  
- **Secondary:** Ordinal/regression — internal score 1–10 (for ranking/limit sizing).

### 5.3 Features

| Source | Features |
|--------|----------|
| **Statement (small txns)** | small_txn_count, small_txn_frequency_per_week, small_txn_share_of_total_count, small_txn_share_of_total_volume, small_txn_avg_amount, small_txn_std_amount, small_txn_credit_count, small_txn_debit_count; optional: monthly counts. |
| **Statement (overall)** | total_txn_count, total_credit_volume, total_debit_volume, avg_balance, min_balance, number of negative_balance_days (if available). |
| **CIBIL** | cibil_score_internal (1–10). |
| **Customer** | tenure_days, segment (if any). |

All numeric features to be normalised/standardised for the model.

### 5.4 Model Choices

- **Eligibility (binary):** Logistic regression, gradient boosting (e.g. XGBoost/LightGBM), or small neural net.  
- **Score 1–10 (ordinal/regression):** Ordinal regression or regression with rounding/clipping to 1–10.

Training data: historical applicants with statement + CIBIL + outcome (e.g. approved/rejected, or repayment performance).  
Label: e.g. `eligible_nbfc_only` from past policy or from actual disbursement + 90-day default flag.

### 5.5 Integration with BRE

- **Option 1:** ML outputs a **probability** or **score 1–10**; BRE uses these as additional inputs (e.g. if ml_score >= 7 then tier = A).  
- **Option 2:** ML output **replaces** CIBIL in rules (e.g. blended_score = 0.6 * cibil + 0.4 * ml_score).  
- **Option 3:** BRE runs first; ML used only for borderline or for limit recommendation.

Recommended: **Option 1** — ML produces score/probability; BRE remains single place for eligibility and tier.

### 5.6 Serving

- Model served via a small **scoring API** (e.g. Python FastAPI/Flask with persisted model — pickle/joblib or ONNX).  
- Input: same features as above (statement aggregates + cibil_score_internal + optional customer).  
- Output: `ml_eligibility_probability`, `ml_score_1_10` (optional).  
- Version model and log inputs/outputs for drift and audit.

---

## 6. End-to-End Data Flow & Component Diagram

```
┌──────────────┐
│   Customer   │
│ (Statement   │
│  upload)     │
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│                     API / Orchestration Layer                     │
│  POST /nbfc-funding/statement  →  POST /nbfc-funding/evaluate   │
└──────┬─────────────────────────────────────────────┬─────────────┘
       │                                              │
       ▼                                              │
┌──────────────────┐     ┌─────────────────────┐     │
│ Statement Parser  │     │ CIBIL Service       │     │
│ (3-month, small  │     │ (score 1–10, cache) │     │
│  txn extraction) │     └──────────┬──────────┘     │
└────────┬─────────┘                │                │
         │                           │                │
         │  statement_aggregates     │ cibil_score    │
         └─────────────┬─────────────┘                │
                       ▼                              │
              ┌─────────────────┐                    │
              │   ML Scoring     │                    │
              │   (features →    │                    │
              │   prob / score)  │                    │
              └────────┬────────┘                    │
                       │                              │
                       │ ml_score, ml_prob            │
                       ▼                              │
              ┌─────────────────┐                    │
              │   BRE Engine    │◀───────────────────┘
              │ (rules →        │   customer_id, etc.
              │  eligible, tier)│
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  Response:       │
              │  eligible_nbfc, │
              │  tier, limit_band│
              └─────────────────┘
```

### 6.1 Sequence (High Level)

1. Customer uploads 3-month statement → **Statement Parser** returns normalised transactions + **small-transaction aggregates**.  
2. System (or separate step) calls **CIBIL** with customer identifiers → get **cibil_score_internal (1–10)**.  
3. **ML Scoring** takes statement aggregates + CIBIL score → **ml_score_1_10**, **ml_eligibility_probability**.  
4. **BRE** takes CIBIL score + statement aggregates + ML output + customer → **eligible_nbfc_only**, **tier**, **max_limit_band**.  
5. API returns eligibility and tier to client.

---

## 7. Data Models & Interfaces

### 7.1 Statement Parser Response (Conceptual)

```json
{
  "customer_id": "string",
  "statement_period_start": "YYYY-MM-DD",
  "statement_period_end": "YYYY-MM-DD",
  "total_transactions": 120,
  "small_transaction_metrics": {
    "small_txn_count": 45,
    "small_txn_credit_count": 20,
    "small_txn_debit_count": 25,
    "small_txn_avg_amount": 1200.50,
    "small_txn_std_amount": 800.20,
    "small_txn_frequency_per_week": 3.75,
    "small_txn_share_of_total_count": 0.375,
    "small_txn_share_of_total_volume": 0.28
  },
  "transactions_sample": []
}
```

### 7.2 CIBIL Service Response (Conceptual)

```json
{
  "customer_id": "string",
  "cibil_score_internal": 8,
  "cibil_raw_score": 765,
  "cibil_band": "Good",
  "cibil_last_fetched_at": "YYYY-MM-DDTHH:mm:ssZ"
}
```

### 7.3 BRE Request / Response

**Request:**

```json
{
  "customer_id": "string",
  "cibil_score_internal": 8,
  "small_txn_count": 45,
  "small_txn_frequency_per_week": 3.75,
  "small_txn_share_of_total_count": 0.375,
  "ml_score_1_10": 7.5,
  "ml_eligibility_probability": 0.82
}
```

**Response:**

```json
{
  "eligible_nbfc_only": true,
  "tier": "A",
  "max_limit_band": "MEDIUM",
  "rule_ids_fired": ["R1"]
}
```

---

## 8. Non-Functional Considerations

| Area | Recommendation |
|------|----------------|
| **Security** | Encrypt statement at rest and in transit; strict access to PII; consent and audit log for CIBIL and statement. |
| **Performance** | Parse statement async where possible; cache CIBIL; keep ML inference &lt; 200 ms. |
| **Config** | Small-transaction min/max, CIBIL→1–10 mapping, and BRE rules in config/DB for change without code deploy. |
| **Observability** | Log rule hits, ML input/output, and CIBIL cache hit/miss; metrics for pipeline stages. |
| **Compliance** | Retain statements and decisions per regulatory requirements; document data retention and consent flow. |

---

## Summary

| Building Block | Responsibility |
|----------------|----------------|
| **3-month statement** | Ingested via PDF/CSV; parsed and normalised. |
| **Small transactions** | Defined by configurable INR range; extracted and aggregated into metrics for BRE/ML. |
| **CIBIL** | Fetched (with cache); mapped to internal **1–10** score (10 = best). |
| **BRE** | Consumes statement metrics + CIBIL + optional ML output; returns **NBFC-only funding** eligibility and tier. |
| **ML** | Uses statement + CIBIL features to produce score/probability; feeds BRE or blended score. |

This LLD provides the structure to implement statement processing, small-transaction extraction, CIBIL integration, BRE, and ML in a consistent way for NBFC-only funding.
