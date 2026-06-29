-- Staging: Support Tickets
-- Cleans and standardizes raw support ticket data

WITH source AS (
    SELECT * FROM raw.support_tickets
),

cleaned AS (
    SELECT
        id                                          AS ticket_id,
        company_id,
        contact_id,
        TRIM(subject)                               AS subject,
        TRIM(status)                                AS status,
        TRIM(priority)                              AS priority,
        TRIM(category)                              AS category,
        TRIM(channel)                               AS channel,
        assigned_to,
        created_at,
        first_response_at,
        resolved_at,
        closed_at,
        COALESCE(satisfaction_score, 0)             AS satisfaction_score,
        _ingested_at,
        CASE
            WHEN first_response_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (first_response_at - created_at)) / 3600
            ELSE NULL
        END                                         AS first_response_hours,
        CASE
            WHEN resolved_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600
            ELSE NULL
        END                                         AS resolution_hours,
        CASE
            WHEN priority = 'Critical' THEN 4
            WHEN priority = 'High'     THEN 3
            WHEN priority = 'Medium'   THEN 2
            WHEN priority = 'Low'      THEN 1
            ELSE 0
        END                                         AS priority_rank
    FROM source
    WHERE id IS NOT NULL
)

SELECT * FROM cleaned