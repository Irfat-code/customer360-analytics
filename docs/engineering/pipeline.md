# Pipeline Execution

The platform follows an ELT workflow orchestrated by Apache Airflow.

1. Load raw source data into PostgreSQL
2. Execute dbt staging models
3. Build business mart models
4. Run dbt data quality tests
5. Record pipeline metadata

The DAG (`customer360_pipeline`, defined in [`ingestion/dags/customer360_pipeline.py`](../../ingestion/dags/customer360_pipeline.py)) can be triggered manually from the Airflow UI or CLI, or executed on its schedule.

Separately, a GitHub Actions workflow runs on every push to `main`: it spins up a fresh PostgreSQL instance, applies the schema, generates synthetic data, and runs the full dbt build and test suite, independent of any local environment.