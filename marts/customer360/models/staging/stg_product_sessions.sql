-- Staging: Product Sessions
-- Cleans and aggregates product usage signals per company

WITH source AS (
    SELECT * FROM raw.product_sessions
),

cleaned AS (
    SELECT
        id                                          AS session_id,
        company_id,
        contact_id,
        session_date,
        COALESCE(duration_seconds, 0)               AS duration_seconds,
        COALESCE(page_views, 0)                      AS page_views,
        COALESCE(actions_count, 0)                   AS actions_count,
        device_type,
        created_at,
        _ingested_at
    FROM source
    WHERE id IS NOT NULL
)

SELECT * FROM cleaned