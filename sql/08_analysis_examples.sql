-- Total spending per customer while preserving each order row.
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
    ) AS customer_total
FROM legacy_orders
ORDER BY customer_id, order_date;

-- Running total by customer.
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS running_total
FROM legacy_orders
ORDER BY customer_id, order_date;

-- Previous order amount.
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS previous_amount
FROM legacy_orders
ORDER BY customer_id, order_date;

-- Latest order per customer.
WITH ranked_orders AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC
        ) AS rn
    FROM legacy_orders
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount
FROM ranked_orders
WHERE rn = 1
ORDER BY customer_id;
