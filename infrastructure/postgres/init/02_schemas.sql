-- =============================================================================
-- CUSTOMER360 INTELLIGENCE PLATFORM
-- Schema Architecture
-- =============================================================================

-- Raw layer: data lands here exactly as it comes from source systems
CREATE SCHEMA IF NOT EXISTS raw AUTHORIZATION postgres;

-- Staging layer: dbt cleans, standardizes, and validates data here
CREATE SCHEMA IF NOT EXISTS staging AUTHORIZATION postgres;

-- Marts layer: final business-ready tables for analysts and dashboards
CREATE SCHEMA IF NOT EXISTS marts AUTHORIZATION postgres;

-- Audit layer: pipeline logs, data quality results, row counts
CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION postgres;

-- Grant airflow user access to all schemas
GRANT USAGE ON SCHEMA raw, staging, marts, audit TO airflow;
GRANT CREATE ON SCHEMA raw, staging, marts, audit TO airflow;