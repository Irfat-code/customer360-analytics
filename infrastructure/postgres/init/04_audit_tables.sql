-- =============================================================================
-- CUSTOMER360 INTELLIGENCE PLATFORM
-- Audit Layer Tables
-- Tracks every pipeline run, row counts, and data quality results
-- =============================================================================

CREATE TABLE IF NOT EXISTS audit.pipeline_runs (
    id                  SERIAL PRIMARY KEY,
    pipeline_name       VARCHAR(255) NOT NULL,
    source_system       VARCHAR(100),
    status              VARCHAR(30),
    rows_extracted      INTEGER,
    rows_loaded         INTEGER,
    rows_rejected       INTEGER,
    started_at          TIMESTAMP DEFAULT NOW(),
    completed_at        TIMESTAMP,
    error_message       TEXT,
    run_metadata        JSONB
);

CREATE TABLE IF NOT EXISTS audit.data_quality_results (
    id                  SERIAL PRIMARY KEY,
    run_id              INTEGER REFERENCES audit.pipeline_runs(id),
    table_name          VARCHAR(255),
    test_name           VARCHAR(255),
    status              VARCHAR(20),
    rows_tested         INTEGER,
    rows_failed         INTEGER,
    tested_at           TIMESTAMP DEFAULT NOW(),
    details             JSONB
);

CREATE TABLE IF NOT EXISTS audit.row_counts (
    id                  SERIAL PRIMARY KEY,
    schema_name         VARCHAR(100),
    table_name          VARCHAR(255),
    row_count           INTEGER,
    counted_at          TIMESTAMP DEFAULT NOW()
);