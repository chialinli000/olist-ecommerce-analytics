
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 06_sql_joins.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Combine order, customer, and payment data using SQL
-- JOINs while maintaining accurate analytical granularity.
--
-- BUSINESS QUESTIONS:
-- 1. Where are customers placing orders from?
-- 2. Which Brazilian states generate the most orders?
-- 3. Can every order be matched to customer data?
-- 4. How do multiple payment records affect JOIN results?
-- 5. How can payment values be aggregated accurately?
--
-- SQL TECHNIQUES:
-- INNER JOIN, LEFT JOIN, GROUP BY, COUNT,
-- COUNT DISTINCT, SUM, CTE, and COALESCE.
--
-- DATASETS:
-- olist_orders_dataset
-- olist_customers_dataset
-- olist_order_payments_dataset
--
-- DATA GRANULARITY:
-- Orders: One record per order_id.
-- Customers: One record per customer_id.
-- Payments: One or more records per order_id.
--
-- NOTE:
-- customer_id identifies a customer record associated
-- with an order, whereas customer_unique_id identifies
-- an individual customer across multiple orders.
--
-- All queries are read-only.
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Verify Dataset Record Counts
-- ------------------------------------------------------------
-- Business Question:
-- How many records are available in each dataset?
--
-- Purpose:
-- Establish baseline record counts before joining tables.


-- 1.1 Orders dataset

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM olist_orders_dataset;


-- 1.2 Customers dataset

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;


-- 1.3 Payments dataset

SELECT
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders_with_payments
FROM olist_order_payments_dataset;


-- ------------------------------------------------------------
-- PART 2: INNER JOIN - Orders and Customers
-- ------------------------------------------------------------
-- Business Question:
-- Where are customers placing orders from?
--
-- Purpose:
-- Retrieve location details for orders with a matching
-- customer record.
--
-- JOIN KEY:
-- o.customer_id = c.customer_id
--
-- INNER JOIN only returns matching records.


SELECT
    o.order_id,
    o.order_status,
    c.customer_city,
    c.customer_state
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 3: LEFT JOIN - Preserve All Orders
-- ------------------------------------------------------------
-- Business Question:
-- Can order records be retained even when customer
-- information is unavailable?
--
-- Purpose:
-- Demonstrate LEFT JOIN, which preserves all records
-- from the Orders table.


SELECT
    o.order_id,
    o.customer_id,
    c.customer_state
FROM olist_orders_dataset AS o
LEFT JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id
LIMIT 10;


-- 3.1 Identify orders without a matching customer
-- Expected result should be reviewed, not assumed.

SELECT
    COUNT(*) AS orders_without_customer_match
FROM olist_orders_dataset AS o
LEFT JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ------------------------------------------------------------
-- PART 4: Regional Order Analysis
-- ------------------------------------------------------------
-- Business Question:
-- Which Brazilian states generated the most orders?
--
-- Purpose:
-- Join Orders with Customers and aggregate orders
-- by customer_state.
--
-- This counts orders, not unique customers.
-- All order statuses are included.


SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC, c.customer_state
LIMIT 10;


-- ------------------------------------------------------------
-- PART 5: Multiple JOINs - Orders, Customers, Payments
-- ------------------------------------------------------------
-- Business Question:
-- Which payment methods and amounts are associated
-- with orders from different Brazilian states?
--
-- Purpose:
-- Connect three datasets.
--
-- IMPORTANT:
-- The Payments table may contain multiple records
-- for the same order_id.
--
-- Consequently, this query returns payment-level
-- records rather than one row per order.


SELECT
    o.order_id,
    c.customer_state,
    p.payment_type,
    p.payment_value
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
INNER JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
ORDER BY o.order_id, p.payment_sequential
LIMIT 10;


-- ------------------------------------------------------------
-- PART 6: Investigate JOIN Granularity
-- ------------------------------------------------------------
-- Business Question:
-- Does joining Orders with Payments increase row counts?
--
-- Purpose:
-- Compare joined records against distinct order IDs.
--
-- Multiple payments can create multiple joined rows
-- for a single order.


-- 6.1 Count rows after joining Orders and Payments

SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT o.order_id)
        AS additional_payment_rows
FROM olist_orders_dataset AS o
INNER JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id;


-- 6.2 Identify orders with multiple payment records

SELECT
    order_id,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_records DESC, order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 7: Aggregate Payments Before Joining
-- ------------------------------------------------------------
-- Business Question:
-- How can we obtain one payment amount per order?
--
-- Purpose:
-- Use a Common Table Expression (CTE) to aggregate
-- payment records before joining them with Orders.
--
-- This creates one row per order_id in order_payments.
--
-- IMPORTANT:
-- Summing payment_value directly is valid for total
-- recorded payment value, but joining payment-level
-- records can duplicate order-level attributes.
--
-- Pre-aggregation prevents that duplication.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.order_status,
    c.customer_state,
    ROUND(p.order_payment_value, 2)
        AS order_payment_value
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
INNER JOIN order_payments AS p
    ON o.order_id = p.order_id
ORDER BY o.order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 8: Regional Payment Value Analysis
-- ------------------------------------------------------------
-- Business Question:
-- Which Brazilian states recorded the highest
-- total payment values?
--
-- Purpose:
-- Calculate order counts and payment totals by state.
--
-- METHODOLOGY:
-- 1. Aggregate Payments at order level.
-- 2. Join the aggregated payments to Orders.
-- 3. Join Orders to Customers.
-- 4. Group results by customer state.
--
-- INTERPRETATION:
-- Payment value does not represent net revenue,
-- profit, or completed delivery value.
--
-- This query includes orders with payment records
-- regardless of their order status.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders_with_payments,
    ROUND(SUM(p.order_payment_value), 2)
        AS total_payment_value
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
INNER JOIN order_payments AS p
    ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_payment_value DESC, c.customer_state
LIMIT 10;


-- ------------------------------------------------------------
-- PART 9: Orders Without Payment Records
-- ------------------------------------------------------------
-- Business Question:
-- How many orders do not have matching payment records?
--
-- Purpose:
-- Identify orders that would be excluded when an
-- INNER JOIN is used with payment data.
--
-- COUNT DISTINCT is not required here because
-- each order is counted once from the Orders table.


SELECT
    COUNT(*) AS orders_without_payment
FROM olist_orders_dataset AS o
LEFT JOIN olist_order_payments_dataset AS p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;


-- ------------------------------------------------------------
-- PART 10: Validate the Aggregated JOIN
-- ------------------------------------------------------------
-- Business Question:
-- Does payment aggregation preserve one row per order?
--
-- Purpose:
-- Check the number of joined rows and distinct
-- orders after payments have been aggregated.
--
-- If Orders and Customers have unique join keys,
-- the result should contain one row per matched order.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
),

joined_orders AS (
    SELECT
        o.order_id,
        c.customer_state,
        p.order_payment_value
    FROM olist_orders_dataset AS o
    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id
    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id
)

SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_or_null_order_rows,
    ROUND(SUM(order_payment_value), 2)
        AS total_payment_value
FROM joined_orders;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. INNER JOIN retains only matching records.
--
-- 2. LEFT JOIN preserves all records from the left table.
--
-- 3. customer_id and customer_unique_id serve
--    different analytical purposes.
--
-- 4. Orders and Payments have different data granularity.
--
-- 5. Multiple payment records per order are not
--    automatically duplicates or data errors.
--
-- 6. Aggregating Payments by order_id before joining
--    supports accurate order-level calculations.
--
-- 7. JOIN results should be validated using both
--    record counts and distinct identifiers.
--
-- 8. Data scope and order status filters must be
--    defined before interpreting payment metrics.
--
-- ============================================================
-- END OF LESSON 06
-- ============================================================
