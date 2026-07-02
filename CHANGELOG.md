# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [1.0.0] — 2026-06-30

### Added
- Docker Compose stack: PostgreSQL 17, Apache Airflow 2.9, dbt 1.8, Metabase
- PostgreSQL warehouse with raw, staging, marts, and audit schemas
- 10 raw tables across 6 source domains: CRM, billing, support, product usage, marketing, surveys
- Python data generation script producing 22,000+ rows of realistic enterprise data
- 6 dbt staging models with cleaning, standardization, and type casting
- 3 dbt mart models: customer_health, churn_risk, recommended_actions
- 24 automated dbt data quality tests: not_null, unique, relationships, accepted_values
- Airflow DAG orchestrating the full pipeline on a daily schedule
- GitHub Actions CI workflow running dbt models and tests on every push to main
- Metabase dashboard: churn risk distribution, health score histogram, MRR by tier, critical accounts
- Architecture documentation, ADRs, data model reference, scoring methodology, pipeline overview