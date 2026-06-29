-- =============================================================================
-- CUSTOMER360 INTELLIGENCE PLATFORM
-- PostgreSQL Initialization Script
-- =============================================================================

-- Airflow metadata database and user
CREATE USER airflow WITH PASSWORD 'airflow';
CREATE DATABASE airflow OWNER airflow;
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;

-- Metabase metadata database
CREATE DATABASE metabase OWNER postgres;
GRANT ALL PRIVILEGES ON DATABASE metabase TO postgres;