-- Staging: NPS Responses
-- Cleans and standardizes raw NPS data

WITH source AS (
    SELECT * FROM raw.nps_responses
),

cleaned AS (
    SELECT
        id                                          AS response_id,
        company_id,
        contact_id,
        score,
        TRIM(category)                              AS nps_category,
        TRIM(comment)                               AS comment,
        survey_date,
        created_at,
        _ingested_at,
        CASE
            WHEN score >= 9 THEN 1
            ELSE 0
        END                                         AS is_promoter,
        CASE
            WHEN score <= 6 THEN 1
            ELSE 0
        END                                         AS is_detractor
    FROM source
    WHERE id IS NOT NULL
      AND score BETWEEN 0 AND 10
)

SELECT * FROM cleaned