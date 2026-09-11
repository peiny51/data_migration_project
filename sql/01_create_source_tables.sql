DROP TABLE IF EXISTS target_orders CASCADE;
DROP TABLE IF EXISTS target_customers CASCADE;
DROP TABLE IF EXISTS staging_orders CASCADE;
DROP TABLE IF EXISTS staging_customers CASCADE;
DROP TABLE IF EXISTS rejected_orders CASCADE;
DROP TABLE IF EXISTS migration_ready_orders CASCADE;
DROP TABLE IF EXISTS rejected_customers CASCADE;
DROP TABLE IF EXISTS migration_ready_customers CASCADE;
DROP TABLE IF EXISTS clean_customers CASCADE;
DROP TABLE IF EXISTS legacy_orders CASCADE;
DROP TABLE IF EXISTS legacy_customers CASCADE;

CREATE TABLE legacy_customers (
    customer_id INTEGER,
    name VARCHAR(100),
    email VARCHAR(200),
    city VARCHAR(100),
    updated_at DATE
);

CREATE TABLE legacy_orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    amount NUMERIC(10, 2)
);
