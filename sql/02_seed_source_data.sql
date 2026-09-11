INSERT INTO legacy_customers (customer_id, name, email, city, updated_at)
VALUES
    (101, 'Tom',   'oldtom@gmail.com',   'Edmonton',  '2024-01-01'),
    (101, 'Tom',   'tom@gmail.com',      'Edmonton',  '2025-05-01'),
    (102, 'Amy',   'amy@gmail.com',      'Calgary',   '2025-03-10'),
    (103, 'Bob',   NULL,                 'Toronto',   '2025-02-20'),
    (103, 'Bob',   'bob@gmail.com',      'Toronto',   '2025-06-15'),
    (104, 'Alice', 'alice@gmail.com',    'Vancouver', '2025-01-08'),
    (105, 'John',  'john@gmail.com',     'Montreal',  '2025-04-15'),
    (105, 'John',  'john_new@gmail.com', 'Montreal',  '2025-08-01'),
    (106, 'David', NULL,                 'Edmonton',  '2025-09-01');

INSERT INTO legacy_orders (order_id, customer_id, order_date, amount)
VALUES
    (1001, 101, '2025-01-10', 120.00),
    (1002, 101, '2025-02-15', 80.00),
    (1003, 101, '2025-04-01', 150.00),
    (1004, 102, '2025-01-20', 200.00),
    (1005, 102, '2025-03-05', 50.00),
    (1006, 103, '2025-02-10', 90.00),
    (1007, 103, '2025-06-01', 110.00),
    (1008, 104, '2025-03-15', 300.00),
    (1009, 105, '2025-02-01', 75.00),
    (1010, 105, '2025-05-10', 125.00),
    (1011, 105, '2025-07-25', 100.00),
    (1012, 999, '2025-08-10', 500.00);
