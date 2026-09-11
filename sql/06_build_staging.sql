DROP TABLE IF EXISTS staging_orders;
DROP TABLE IF EXISTS staging_customers;

CREATE TABLE staging_customers AS
SELECT *
FROM migration_ready_customers;

CREATE TABLE staging_orders AS
SELECT *
FROM migration_ready_orders;
