-- Staging: Contacts
-- Cleans and standardizes raw contact data

WITH source AS (
    SELECT * FROM raw.contacts
),

cleaned AS (
    SELECT
        id                                          AS contact_id,
        company_id,
        TRIM(first_name)                            AS first_name,
        TRIM(last_name)                             AS last_name,
        TRIM(first_name) || ' ' || TRIM(last_name) AS full_name,
        LOWER(TRIM(email))                          AS email,
        TRIM(phone)                                 AS phone,
        TRIM(job_title)                             AS job_title,
        TRIM(department)                            AS department,
        COALESCE(is_primary, FALSE)                 AS is_primary,
        created_at,
        updated_at,
        _ingested_at
    FROM source
    WHERE id IS NOT NULL
      AND email IS NOT NULL
)

SELECT * FROM cleaned