-- Mart: Churn Risk
-- Predictive churn risk scoring based on engagement, support, NPS, and subscription signals

WITH health AS (
    SELECT * FROM {{ ref('customer_health') }}
),

engagement AS (
    SELECT
        company_id,
        COUNT(*)                                          AS total_sessions,
        SUM(duration_seconds)                              AS total_engaged_seconds,
        AVG(duration_seconds)                               AS avg_session_duration,
        SUM(actions_count)                                  AS total_actions,
        MAX(session_date)                                   AS last_session_date,
        SUM(CASE WHEN session_date >= CURRENT_DATE - INTERVAL '30 days'
            THEN 1 ELSE 0 END)                              AS sessions_last_30_days
    FROM {{ ref('stg_product_sessions') }}
    GROUP BY company_id
),

scored AS (
    SELECT
        h.company_id,
        h.company_name,
        h.industry,
        h.tier,
        h.status,
        h.total_mrr,
        h.total_arr,
        h.health_score,
        h.avg_nps_score,
        h.nps_detractors,
        h.total_support_tickets,
        h.critical_tickets,
        h.avg_satisfaction_score,
        h.active_subscriptions,

        COALESCE(e.total_sessions, 0)                       AS total_sessions,
        COALESCE(e.sessions_last_30_days, 0)                AS sessions_last_30_days,
        e.last_session_date,
        CASE
            WHEN e.last_session_date IS NULL THEN NULL
            ELSE CURRENT_DATE - e.last_session_date
        END                                                  AS days_since_last_session,

        -- Churn risk score (0-100, higher = more risk)
        ROUND(
            LEAST(100, GREATEST(0,
                -- No active subscription is the biggest risk factor (35 points)
                (CASE WHEN h.active_subscriptions = 0 THEN 35 ELSE 0 END)
                -- Low engagement: no sessions in last 30 days (25 points)
                + (CASE WHEN COALESCE(e.sessions_last_30_days, 0) = 0 THEN 25 ELSE 0 END)
                -- High critical ticket volume (up to 20 points)
                + LEAST(20, COALESCE(h.critical_tickets, 0) * 4)
                -- NPS detractors (up to 15 points)
                + LEAST(15, COALESCE(h.nps_detractors, 0) * 3)
                -- Low satisfaction score (up to 15 points)
                + (CASE WHEN COALESCE(h.avg_satisfaction_score, 5) < 3 THEN 15 ELSE 0 END)
                -- Low health score correlation (up to 10 points)
                + (CASE WHEN COALESCE(h.health_score, 100) < 40 THEN 10 ELSE 0 END)
            ))
        , 2)                                                 AS churn_risk_score,

        NOW()                                                AS calculated_at

    FROM health h
    LEFT JOIN engagement e ON h.company_id = e.company_id
),

final AS (
    SELECT
        *,
        CASE
            WHEN churn_risk_score >= 70 THEN 'Critical'
            WHEN churn_risk_score >= 50 THEN 'High'
            WHEN churn_risk_score >= 30 THEN 'Medium'
            ELSE 'Low'
        END                                                  AS churn_risk_category
    FROM scored
)

SELECT * FROM final