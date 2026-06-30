# Data Model

## customer_health

**Purpose.** One row per company summarizing overall account health.

**Inputs.** `stg_companies`, `stg_subscriptions`, `stg_support_tickets`, `stg_nps_responses`

**Key outputs.**
- `health_score` (0-100): weighted composite of NPS, satisfaction, active subscription status, and support burden
- `active_subscriptions`, `total_mrr`, `total_arr`
- `avg_nps_score`, `nps_promoters`, `nps_detractors`
- `critical_tickets`, `avg_satisfaction_score`

## churn_risk

**Purpose.** One row per company, scoring and categorizing churn likelihood.

**Inputs.** `customer_health`, `stg_product_sessions`

**Key outputs.**
- `churn_risk_score` (0-100, higher = more risk)
- `churn_risk_category` (Low / Medium / High / Critical)
- `days_since_last_session`, `sessions_last_30_days`

## recommended_actions

**Purpose.** One row per company with a concrete next step for Customer Success.

**Inputs.** `churn_risk`

**Key outputs.**
- `recommended_action`: a specific task, chosen based on the dominant risk signal rather than the risk category alone
- `action_owner`: who should act, based on tier and ARR
- `action_sla`: how quickly, based on severity
- `action_priority`: integer used to sort the work queue