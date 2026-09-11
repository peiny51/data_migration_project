-- SQLBook: Code
CREATE TABLE legacy_customers (
    customer_id INTEGER,
    name VARCHAR(100),
    email VARCHAR(200),
    city VARCHAR(100),
    updated_at DATE
);
-- SQLBook: Code
INSERT INTO legacy_customers
    (customer_id, name, email, city, updated_at)
VALUES
    (101, 'Tom',   'oldtom@gmail.com',  'Edmonton',  '2024-01-01'),
    (101, 'Tom',   'tom@gmail.com',     'Edmonton',  '2025-05-01'),
    (102, 'Amy',   'amy@gmail.com',     'Calgary',   '2025-03-10'),
    (103, 'Bob',   NULL,                'Toronto',   '2025-02-20'),
    (103, 'Bob',   'bob@gmail.com',     'Toronto',   '2025-06-15'),
    (104, 'Alice', 'alice@gmail.com',   'Vancouver', '2025-01-08'),
    (105, 'John',  'john@gmail.com',    'Montreal',  '2025-04-15'),
    (105, 'John',  'john_new@gmail.com','Montreal',  '2025-08-01');
-- SQLBook: Code
SELECT customer_id
FROM legacy_customers;
-- SQLBook: Markup
每个 customer_id 出现多少次？
-- SQLBook: Code
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM legacy_customers
GROUP BY customer_id;
-- SQLBook: Markup
出现次数 > 1 的 customer。 
WHERE 过滤行。
HAVING 过滤分组后的结果。
-- SQLBook: Code
SELECT
    customer_id,
    COUNT(*) AS record_count
FROM legacy_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- SQLBook: Code
SELECT *
FROM legacy_customers
WHERE email IS NULL;
-- SQLBook: Markup
我们应该先统计每一列的 NULL 数：
COUNT(*)统计所有行。
COUNT(email)只统计 email IS NOT NULL 的行。
-- SQLBook: Code
SELECT
    COUNT(*) AS total_rows,

    COUNT(*) - COUNT(customer_id) AS customer_id_nulls,
    COUNT(*) - COUNT(name) AS name_nulls,
    COUNT(*) - COUNT(email) AS email_nulls,
    COUNT(*) - COUNT(city) AS city_nulls,
    COUNT(*) - COUNT(updated_at) AS updated_at_nulls

FROM legacy_customers;
-- SQLBook: Markup
ROW_NUMBER()： 给结果编号
-- SQLBook: Code
SELECT
    *,
    ROW_NUMBER() OVER (
        ORDER BY updated_at DESC
    ) AS rn
FROM legacy_customers;
-- SQLBook: Markup
每换一个 customer，编号重新从 1 开始。
partition by: 编号的范围是什么。
partition by x: “每个 X 分开算（单独算）。”
-- SQLBook: Code
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) AS rn
FROM legacy_customers;
-- SQLBook: Markup
但问题来了：我们现在只是标出来了，还没有真的筛选。你很自然会想写下面的
但 PostgreSQL 会报错，因为 WHERE 执行的时候，rn 这个别名还没生成。

这就是 CTE 出现的原因。
-- SQLBook: Code
SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY updated_at DESC
    ) AS rn
FROM legacy_customers
WHERE rn = 1;
-- SQLBook: Code
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
FROM ranked_customers;
-- SQLBook: Markup
所以实际更好的逻辑是先做版本排序：
-- SQLBook: Code
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM legacy_customers
)
SELECT *
FROM ranked
WHERE rn = 1;
-- SQLBook: Markup
删除rn
-- SQLBook: Code
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
-- SQLBook: Markup
得到每个客户最新版本后，再检查：
-- SQLBook: Code
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC
        ) AS rn
    FROM legacy_customers
)
SELECT *
FROM ranked
WHERE rn = 1
  AND (
      customer_id IS NULL
      OR name IS NULL
      OR email IS NULL
      OR city IS NULL
      OR updated_at IS NULL
  );
-- SQLBook: Markup
1. 运行后面的 SELECT
2. 用 SELECT 的结果创建 clean_customers

CREATE TABLE clean_customers AS

可以简单理解成：

“把后面查询出来的数据存成一张新表。”
-- SQLBook: Code
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
-- SQLBook: Code
SELECT
    customer_id,
    COUNT(*) AS count
FROM clean_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- SQLBook: Code
SELECT *
FROM clean_customers;
-- SQLBook: Code
SELECT *
FROM clean_customers
WHERE
    customer_id IS NULL
    OR name IS NULL
    OR email IS NULL
    OR city IS NULL
    OR updated_at IS NULL;
-- SQLBook: Code
INSERT INTO legacy_customers
    (customer_id, name, email, city, updated_at)
VALUES
    (106, 'David', NULL, 'Edmonton', '2025-09-01');
-- SQLBook: Code
DROP TABLE clean_customers;
-- SQLBook: Code
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
-- SQLBook: Code
SELECT *
FROM clean_customers
WHERE
    customer_id IS NULL
    OR name IS NULL
    OR email IS NULL
    OR city IS NULL
    OR updated_at IS NULL;
-- SQLBook: Code
CREATE TABLE rejected_customers AS
SELECT *
FROM clean_customers
WHERE
    customer_id IS NULL
    OR name IS NULL
    OR email IS NULL;
-- SQLBook: Code
SELECT *
FROM rejected_customers;
-- SQLBook: Markup
真正迁移的数据
-- SQLBook: Code
CREATE TABLE migration_ready_customers AS
SELECT *
FROM clean_customers
WHERE
    customer_id IS NOT NULL
    AND name IS NOT NULL
    AND email IS NOT NULL;
-- SQLBook: Code
CREATE TABLE legacy_orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    amount NUMERIC(10, 2)
);
-- SQLBook: Code
INSERT INTO legacy_orders
    (order_id, customer_id, order_date, amount)
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
    (1011, 105, '2025-07-25', 100.00);
-- SQLBook: Code
SELECT *
FROM legacy_orders
ORDER BY customer_id, order_date;
-- SQLBook: Markup
每个客户总共消费了多少钱？
-- SQLBook: Code
SELECT
    customer_id,
    SUM(amount) AS total_spent
FROM legacy_orders
GROUP BY customer_id;
-- SQLBook: Markup
如果我既想保留每笔订单，又想看到客户总消费？
SUM(amount) OVER (PARTITION BY customer_id)

是：
对每个 customer 分别算总额，但保留原始每一行。
-- SQLBook: Code
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
-- SQLBook: Markup
累积消费
PARTITION BY customer_id
决定：
每个客户单独算。
而：
ORDER BY order_date
决定：
按时间顺序累计
-- SQLBook: Code
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
-- SQLBook: Markup
LAG() —— 看上一笔订单


每笔订单和上一笔订单相比变化多少？
先只取上一笔金额：
-- SQLBook: Code
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
-- SQLBook: Markup
算差额
-- SQLBook: Code
SELECT
    order_id,
    customer_id,
    order_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS previous_amount,

    amount - LAG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS amount_change

FROM legacy_orders
ORDER BY customer_id, order_date;
-- SQLBook: Markup
找每个客户最近一笔订单
-- SQLBook: Code
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
WHERE rn = 1;
-- SQLBook: Code
SELECT
    o.order_id,
    o.customer_id,
    c.name,
    c.email,
    o.order_date,
    o.amount
FROM legacy_orders o
INNER JOIN clean_customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;
-- SQLBook: Markup
制造一个坏订单 Orphan Record（孤儿记录）customer id 999不存在
-- SQLBook: Code
INSERT INTO legacy_orders
    (order_id, customer_id, order_date, amount)
VALUES
    (1012, 999, '2025-08-10', 500.00);
-- SQLBook: Markup
Reconciliation

也就是：

源数据和迁移结果能不能对得上？
-- SQLBook: Code
SELECT
    o.order_id,
    o.customer_id,
    c.name,
    o.order_date,
    o.amount
FROM legacy_orders o
INNER JOIN clean_customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;
-- SQLBook: Code
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.amount,
    c.name
FROM legacy_orders o
LEFT JOIN clean_customers c
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;
-- SQLBook: Markup
只找有问题的订单 referential integrity check

-- SQLBook: Code
SELECT
    o.*
FROM legacy_orders o
LEFT JOIN clean_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- SQLBook: Markup
Reconciliation
-- SQLBook: Code
SELECT COUNT(*) AS source_order_count
FROM legacy_orders;
-- SQLBook: Code
SELECT COUNT(*) AS valid_order_count
FROM legacy_orders o
INNER JOIN clean_customers c
    ON o.customer_id = c.customer_id;
-- SQLBook: Code
SELECT COUNT(*) AS orphan_order_count
FROM legacy_orders o
LEFT JOIN clean_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- SQLBook: Markup
金额也要 reconciliation
source amount
=
valid amount + orphan amount
-- SQLBook: Code
SELECT
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount
FROM legacy_orders;
-- SQLBook: Code
SELECT
    COUNT(*) AS valid_orders,
    SUM(o.amount) AS valid_amount
FROM legacy_orders o
INNER JOIN clean_customers c
    ON o.customer_id = c.customer_id;
-- SQLBook: Code
SELECT
    COUNT(*) AS orphan_orders,
    SUM(o.amount) AS orphan_amount
FROM legacy_orders o
LEFT JOIN clean_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- SQLBook: Code
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.amount,
    c.customer_id AS matched_customer_id
FROM legacy_orders o
LEFT JOIN migration_ready_customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;
-- SQLBook: Markup
这里的null指
有 customer_id，但 customer 999 不存在。

第二种只有 JOIN 以后才能发现。

-- SQLBook: Code
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.amount
FROM legacy_orders o
LEFT JOIN migration_ready_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
ORDER BY o.order_id;
-- SQLBook: Markup
1. order_id 不能为 NULL
2. customer_id 不能为 NULL
3. order_date 不能为 NULL
4. amount 不能为 NULL
5. amount > 0
6. customer_id 必须存在于 migration_ready_customers

先找 rejected orders

case when else = 
if ...
elif ...
elif ...
else ...
-- SQLBook: Code
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
    END AS rejection_reason
FROM legacy_orders o
LEFT JOIN migration_ready_customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;
-- SQLBook: Code
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

SELECT *
FROM checked_orders
WHERE status <> 'valid';
-- SQLBook: Markup
现在创建 rejected_orders
-- SQLBook: Code
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

SELECT *
FROM checked_orders
WHERE status <> 'valid';
-- SQLBook: Markup
创建 migration_ready_orders
-- SQLBook: Code
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
-- SQLBook: Markup
do reconcilation: 
make sure
source total
=
ready total + rejected total
-- SQLBook: Markup
创建 staging表
-- SQLBook: Code
CREATE TABLE staging_customers (
    customer_id INTEGER,
    name VARCHAR(100),
    email VARCHAR(200),
    city VARCHAR(100),
    updated_at DATE
);
-- SQLBook: Code
CREATE TABLE staging_orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date DATE,
    amount NUMERIC(10, 2)
);
-- SQLBook: Code
INSERT INTO staging_customers (
    customer_id,
    name,
    email,
    city,
    updated_at
)
SELECT
    customer_id,
    name,
    email,
    city,
    updated_at
FROM migration_ready_customers;
-- SQLBook: Code
INSERT INTO staging_orders (
    order_id,
    customer_id,
    order_date,
    amount
)
SELECT
    order_id,
    customer_id,
    order_date,
    amount
FROM migration_ready_orders;
-- SQLBook: Markup
validation
-- SQLBook: Code
SELECT
    customer_id,
    COUNT(*) AS count
FROM staging_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
-- SQLBook: Code
SELECT *
FROM staging_customers
WHERE
    customer_id IS NULL
    OR name IS NULL
    OR email IS NULL;
-- SQLBook: Code
SELECT
    o.*
FROM staging_orders o
LEFT JOIN staging_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- SQLBook: Markup
创建真正的 target tables
-- SQLBook: Code
CREATE TABLE target_customers (
    customer_id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    updated_at DATE
);
-- SQLBook: Code
CREATE TABLE target_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (customer_id)
        REFERENCES target_customers(customer_id)
);
-- SQLBook: Markup
Mock Migration
顺序重要
-- SQLBook: Code
INSERT INTO target_customers
SELECT *
FROM staging_customers;
-- SQLBook: Code
INSERT INTO target_orders
SELECT *
FROM staging_orders;
-- SQLBook: Markup
reconciliation for order, customer, amount...
-- SQLBook: Code
SELECT SUM(amount)
FROM staging_orders;
-- SQLBook: Code
SELECT SUM(amount)
FROM target_orders;