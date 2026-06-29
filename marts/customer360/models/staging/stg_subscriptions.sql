-- Staging: Subscriptions
-- Cleans and standardizes raw subscription data

WITH source AS (
    SELECT * FROM raw.subscriptions
),

cleaned AS (
    SELECT
        id                                          AS subscription_id,
        company_id,
        TRIM(plan_name)                             AS plan_name,
        TRIM(plan_tier)                             AS plan_tier,
        TRIM(status)                                AS status,
        COALESCE(mrr, 0)                            AS mrr,
        COALESCE(arr, 0)                            AS arr,
        currency,
        started_at,
        renewed_at,
        expires_at,
        cancelled_at,
        created_at,
        updated_at,
        _ingested_at,
        CASE
            WHEN status = 'Active' THEN TRUE
            ELSE FALSE
        END                                         AS is_active,
        CASE
            WHEN cancelled_at IS NOT NULL
            THEN EXTRACT(DAY FROM cancelled_at - started_at)
            ELSE NULL
        END                                         AS days_to_churn
    FROM source
    WHERE id IS NOT NULL
)

SELECT * FROM cleaned