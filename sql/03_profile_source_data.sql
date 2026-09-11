-- Customer row count
SELECT COUNT(*) AS customer_rows
FROM legacy_customers;

-- Duplicate customer IDs
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM legacy_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY customer_id;

-- Null profile for customer columns
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_id) AS customer_id_nulls,
    COUNT(*) - COUNT(name) AS name_nulls,
    COUNT(*) - COUNT(email) AS email_nulls,
    COUNT(*) - COUNT(city) AS city_nulls,
    COUNT(*) - COUNT(updated_at) AS updated_at_nulls
FROM legacy_customers;

-- Any rows containing nulls
SELECT *
FROM legacy_customers
WHERE customer_id IS NULL
   OR name IS NULL
   OR email IS NULL
   OR city IS NULL
   OR updated_at IS NULL;

-- Order summary
SELECT
    COUNT(*) AS order_rows,
    COALESCE(SUM(amount), 0) AS order_amount
FROM legacy_orders;
