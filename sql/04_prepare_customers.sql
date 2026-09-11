DROP TABLE IF EXISTS rejected_customers;
DROP TABLE IF EXISTS migration_ready_customers;
DROP TABLE IF EXISTS clean_customers;

-- Keep the latest version of each customer.
CREATE TABLE clean_customers AS
WITH ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM legacy_customers
)
SELECT
    customer_id,
    name,
    email,
    city,
    updated_at
FROM ranked_customers
WHERE rn = 1;

-- Required-field validation.
CREATE TABLE rejected_customers AS
SELECT
    customer_id,
    name,
    email,
    city,
    updated_at,
    CASE
        WHEN customer_id IS NULL THEN 'missing_customer_id'
        WHEN name IS NULL THEN 'missing_name'
        WHEN email IS NULL THEN 'missing_email'
        WHEN updated_at IS NULL THEN 'missing_updated_at'
        ELSE 'unknown'
    END AS rejection_reason
FROM clean_customers
WHERE customer_id IS NULL
   OR name IS NULL
   OR email IS NULL
   OR updated_at IS NULL;

CREATE TABLE migration_ready_customers AS
SELECT
    customer_id,
    name,
    email,
    city,
    updated_at
FROM clean_customers
WHERE customer_id IS NOT NULL
  AND name IS NOT NULL
  AND email IS NOT NULL
  AND updated_at IS NOT NULL;
