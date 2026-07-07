-- Mart: Customer Health
-- Combines company, subscription, support, and NPS data
-- into a single customer intelligence view

WITH companies AS (
    SELECT * FROM {{ ref('stg_companies') }}
),

subscriptions AS (
    SELECT
        company_id,
        COUNT(*)                                    AS total_subscriptions,
        SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_subscriptions,
        SUM(mrr)                                    AS total_mrr,
        SUM(arr)                                    AS total_arr,
        MAX(plan_name)                              AS current_plan,
        MIN(started_at)                             AS first_subscription_date,
        MAX(renewed_at)                             AS last_renewal_date
    FROM {{ ref('stg_subscriptions') }}
    GROUP BY company_id
),

support AS (
    SELECT
        company_id,
        COUNT(*)                                        AS total_tickets,
        AVG(satisfaction_score)                         AS avg_satisfaction_score,
        AVG(first_response_hours)                       AS avg_first_response_hours,
        AVG(resolution_hours)                           AS avg_resolution_hours,
        SUM(CASE WHEN priority = 'Critical'
            THEN 1 ELSE 0 END)                          AS critical_tickets,
        SUM(CASE WHEN created_at >= NOW() - INTERVAL '30 days'
            THEN 1 ELSE 0 END)                          AS tickets_last_30_days
    FROM {{ ref('stg_support_tickets') }}
    GROUP BY company_id
),

nps AS (
    SELECT
        company_id,
        COUNT(*)                                        AS total_nps_responses,
        AVG(score)                                      AS avg_nps_score,
        SUM(is_promoter)                                AS promoters,
        SUM(is_detractor)                               AS detractors,
        MAX(survey_date)                                AS last_nps_date
    FROM {{ ref('stg_nps_responses') }}
    GROUP BY company_id
),

final AS (
    SELECT
        c.company_id,
        c.company_name,
        c.industry,
        c.country,
        c.tier,
        c.tier_rank,
        c.status,
        c.is_active,
        c.employee_count,
        c.annual_revenue,

        -- Subscription metrics
        COALESCE(s.total_subscriptions, 0)          AS total_subscriptions,
        COALESCE(s.active_subscriptions, 0)         AS active_subscriptions,
        COALESCE(s.total_mrr, 0)                    AS total_mrr,
        COALESCE(s.total_arr, 0)                    AS total_arr,
        s.current_plan,
        s.first_subscription_date,
        s.last_renewal_date,

        -- Support metrics
        -- Counts default to 0 (no tickets = no burden)
        -- Averages stay NULL (no tickets = no data, not bad data)
        COALESCE(sup.total_tickets, 0)              AS total_support_tickets,
        sup.avg_satisfaction_score                  AS avg_satisfaction_score,
        sup.avg_first_response_hours                AS avg_first_response_hours,
        sup.avg_resolution_hours                    AS avg_resolution_hours,
        COALESCE(sup.critical_tickets, 0)           AS critical_tickets,
        COALESCE(sup.tickets_last_30_days, 0)       AS tickets_last_30_days,

        -- NPS metrics
        -- Count defaults to 0, average stays NULL (no survey = no opinion expressed)
        COALESCE(n.total_nps_responses, 0)          AS total_nps_responses,
        n.avg_nps_score                             AS avg_nps_score,
        COALESCE(n.promoters, 0)                    AS nps_promoters,
        COALESCE(n.detractors, 0)                   AS nps_detractors,
        n.last_nps_date,

        -- Health score (0-100)
        -- Missing averages use neutral midpoints in the score calculation only:
        -- NPS midpoint = 5 (middle of 0-10 scale)
        -- Satisfaction midpoint = 3 (middle of 1-5 scale)
        -- This means missing data is treated as neutral, not worst-case
        ROUND(
            LEAST(100, GREATEST(0,
                -- NPS component (30 points max)
                (COALESCE(n.avg_nps_score, 5) / 10.0 * 30)
                -- Satisfaction component (30 points max)
                + (COALESCE(sup.avg_satisfaction_score, 3) / 5.0 * 30)
                -- Subscription component (25 points max)
                + (CASE WHEN COALESCE(s.active_subscriptions, 0) > 0
                    THEN 25 ELSE 0 END)
                -- Support burden penalty (up to -15 points)
                - (LEAST(15, COALESCE(sup.critical_tickets, 0) * 3))
            ))
        , 2)                                        AS health_score,

        NOW()                                       AS calculated_at

    FROM companies c
    LEFT JOIN subscriptions s  ON c.company_id = s.company_id
    LEFT JOIN support sup      ON c.company_id = sup.company_id
    LEFT JOIN nps n            ON c.company_id = n.company_id
)

SELECT * FROM final