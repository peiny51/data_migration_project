DROP TABLE IF EXISTS rejected_orders;
DROP TABLE IF EXISTS migration_ready_orders;

CREATE TABLE rejected_orders AS
WITH checked_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.amount,
        CASE
            WHEN o.order_id IS NULL THEN 'missing_order_id'
            WHEN o.customer_id IS NULL THEN 'missing_customer_id'
            WHEN o.order_date IS NULL THEN 'missing_order_date'
            WHEN o.amount IS NULL THEN 'missing_amount'
            WHEN o.amount <= 0 THEN 'invalid_amount'
            WHEN c.customer_id IS NULL THEN 'customer_not_found'
            ELSE 'valid'
        END AS status
    FROM legacy_orders o
    LEFT JOIN migration_ready_customers c
        ON o.customer_id = c.customer_id
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    status AS rejection_reason
FROM checked_orders
WHERE status <> 'valid';

CREATE TABLE migration_ready_orders AS
WITH checked_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.amount,
        CASE
            WHEN o.order_id IS NULL THEN 'missing_order_id'
            WHEN o.customer_id IS NULL THEN 'missing_customer_id'
            WHEN o.order_date IS NULL THEN 'missing_order_date'
            WHEN o.amount IS NULL THEN 'missing_amount'
            WHEN o.amount <= 0 THEN 'invalid_amount'
            WHEN c.customer_id IS NULL THEN 'customer_not_found'
            ELSE 'valid'
        END AS status
    FROM legacy_orders o
    LEFT JOIN migration_ready_customers c
        ON o.customer_id = c.customer_id
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount
FROM checked_orders
WHERE status = 'valid';
