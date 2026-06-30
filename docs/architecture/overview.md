# Architecture Overview

## Layers

**Raw** — Data lands here exactly as it would arrive from source systems. No transformations, no business logic. Ten tables across six domains: CRM (companies, contacts), billing (subscriptions, invoices), support (tickets), product usage (sessions, feature events), marketing (campaigns, email events), and surveys (NPS responses).

**Staging** — One model per raw table. Responsibilities: trim whitespace, standardize casing, cast types, derive simple boolean/numeric flags (e.g. `is_active`, `tier_rank`). Staging models never join across sources — that's the mart layer's job.

**Marts** — Business-ready tables that combine multiple staging models:

- `customer_health` joins companies, subscriptions, support tickets, and NPS into a single 0-100 health score.
- `churn_risk` builds on `customer_health` plus product session data to score and categorize churn risk.
- `recommended_actions` builds on `churn_risk` to produce a reason-based recommendation, owner, and SLA per account.

**Audit** — Pipeline run metadata: `pipeline_runs`, `data_quality_results`, `row_counts`. Populated by the Airflow DAG on every run.

## Why this structure

Each mart depends only on the layer below it, never sideways. This keeps the dbt lineage graph a strict DAG and makes it possible to test, rebuild, or debug any single layer without touching the others.

## Orchestration

A single Airflow DAG (`customer360_pipeline`) runs daily: `run_staging_models` → `run_mart_models` → `run_dbt_tests` → `log_pipeline_run`. Each step is a BashOperator calling dbt directly inside the Airflow container, with dbt's log and target paths redirected to `/tmp` to avoid permission issues on the Docker-mounted volume.

## CI/CD

Every push to `main` triggers a GitHub Actions workflow that spins up a fresh PostgreSQL instance, applies the schema, generates synthetic data, runs all dbt models, and runs all 24 data quality tests — independent of any local environment.