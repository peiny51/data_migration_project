# PostgreSQL Data Migration Pipeline

A small end-to-end data migration project built with PostgreSQL and Python.

The project simulates migration from a legacy customer/order system into a clean target schema. It demonstrates data profiling, deduplication, validation, rejected-record handling, staging, referential-integrity checks, transaction control, and post-migration reconciliation.

## What this project demonstrates

- PostgreSQL data profiling and quality checks
- CTEs and window functions
- `ROW_NUMBER() OVER (PARTITION BY ...)`
- `SUM() OVER (...)` and `LAG()`
- Customer deduplication using latest-record logic
- Null and required-field validation
- Orphan record detection with `LEFT JOIN`
- Ready/rejected record separation
- Staging tables
- Primary-key and foreign-key constraints
- Mock migration into target tables
- Row-count and financial reconciliation
- Python database automation with `psycopg`
- Transactions with commit/rollback
- Repeatable migration pipeline

## Architecture

```text
legacy_customers ──► clean_customers
                         │
                         ├──► migration_ready_customers ──► staging_customers ──► target_customers
                         └──► rejected_customers

legacy_orders ────────────────────────────────────────────┐
                                                         ▼
                                  migration_ready_orders ──► staging_orders ──► target_orders
                                  rejected_orders
```

## Example data-quality problems

The included demo data intentionally contains:

- Multiple versions of the same customer
- A latest customer record with a missing required email
- Historical customer records containing nulls
- An order referencing a customer that does not exist

These issues allow the pipeline to demonstrate deduplication, validation, rejected-record handling, and referential-integrity checks.

## Project structure

```text
data_migration_project/
├── data/
│   ├── legacy_customers.csv
│   └── legacy_orders.csv
├── python/
│   ├── migrate.py
│   └── setup_demo.py
├── sql/
│   ├── 01_create_source_tables.sql
│   ├── 02_seed_source_data.sql
│   ├── 03_profile_source_data.sql
│   ├── 04_prepare_customers.sql
│   ├── 05_prepare_orders.sql
│   ├── 06_build_staging.sql
│   ├── 07_create_target_tables.sql
│   └── 08_analysis_examples.sql
├── .env.example
├── .gitignore
├── requirements.txt
└── README.md
```

## Requirements

- Python 3.10+
- PostgreSQL
- A PostgreSQL database such as `migration_demo`

Install Python dependencies:

```bash
pip install -r requirements.txt
```

## Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env`:

```text
DB_HOST=localhost
DB_PORT=5432
DB_NAME=migration_demo
DB_USER=your_postgres_user
DB_PASSWORD=your_postgres_password
```

## Run the demo

### 1. Create and seed the source tables

From the project root:

```bash
python python/setup_demo.py
```

This recreates the demo source tables and inserts the sample legacy records.

### 2. Optional: inspect source data

Run `sql/03_profile_source_data.sql` in PostgreSQL or VS Code to inspect:

- Duplicate customer IDs
- Null values
- Source row counts
- Source order totals

### 3. Run the migration

```bash
python python/migrate.py
```

The pipeline will:

1. Deduplicate customers using the most recent record.
2. Split customers into migration-ready and rejected records.
3. Validate orders and identify orphan references.
4. Split orders into migration-ready and rejected records.
5. Build staging tables.
6. Validate staging data.
7. Create target tables with database constraints.
8. Reset the mock target data.
9. Load customers and orders.
10. Reconcile target data against staging data.
11. Commit only if every validation passes.

If any step fails, the transaction is rolled back.

## Key SQL example: deduplication

```sql
WITH ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM legacy_customers
)
SELECT *
FROM ranked_customers
WHERE rn = 1;
```

`PARTITION BY customer_id` restarts the ranking for each customer, while `ORDER BY updated_at DESC` places the newest version first.

## Key SQL example: orphan detection

```sql
SELECT o.*
FROM legacy_orders o
LEFT JOIN migration_ready_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

This finds orders whose `customer_id` does not exist in the migration-ready customer dataset.

## Key SQL example: window analytics

`sql/08_analysis_examples.sql` contains examples of:

```sql
SUM(amount) OVER (PARTITION BY customer_id)
```

for customer lifetime totals while preserving each order row,

```sql
SUM(amount) OVER (
    PARTITION BY customer_id
    ORDER BY order_date
)
```

for running totals, and

```sql
LAG(amount) OVER (
    PARTITION BY customer_id
    ORDER BY order_date
)
```

for accessing the previous order value.

## Why staging exists

The staging layer separates validated migration data from the final target schema. It provides a controlled point for pre-load validation and reconciliation without modifying source data or partially loading the target system.

## Validation strategy

The project checks:

- Ready + rejected counts equal the relevant source count
- Ready + rejected order amounts equal the source order amount
- No duplicate customer IDs in staging
- No duplicate order IDs in staging
- No orphan orders in staging
- Staging and target customer counts match
- Staging and target order counts match
- Staging and target order totals match
- No target orders are missing
- Key target fields match staging values

## Notes

This is an educational practice project. The source data is synthetic and the target system is simulated with PostgreSQL tables.
