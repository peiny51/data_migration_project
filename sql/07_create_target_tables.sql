CREATE TABLE IF NOT EXISTS target_customers (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    updated_at DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS target_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    CONSTRAINT fk_target_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES target_customers(customer_id)
);
