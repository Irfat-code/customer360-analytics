-- Staging: Companies
-- Cleans and standardizes raw company data

WITH source AS (
    SELECT * FROM raw.companies
),

cleaned AS (
    SELECT
        id                                          AS company_id,
        TRIM(name)                                  AS company_name,
        TRIM(industry)                              AS industry,
        TRIM(country)                               AS country,
        TRIM(city)                                  AS city,
        COALESCE(employee_count, 0)                 AS employee_count,
        COALESCE(annual_revenue, 0)                 AS annual_revenue,
        TRIM(tier)                                  AS tier,
        TRIM(status)                                AS status,
        owner_id,
        created_at,
        updated_at,
        _ingested_at,
        CASE
            WHEN status = 'Active'   THEN TRUE
            ELSE FALSE
        END                                         AS is_active,
        CASE
            WHEN tier = 'Enterprise' THEN 4
            WHEN tier = 'Mid-Market' THEN 3
            WHEN tier = 'SMB'        THEN 2
            WHEN tier = 'Startup'    THEN 1
            ELSE 0
        END                                         AS tier_rank
    FROM source
    WHERE id IS NOT NULL
)

SELECT * FROM cleaned