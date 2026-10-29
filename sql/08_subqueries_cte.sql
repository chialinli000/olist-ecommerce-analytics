
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 08_subqueries_cte.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- TITLE:
-- Subqueries & Common Table Expressions (CTEs)
--
-- PURPOSE:
-- Apply subqueries and CTEs to analyse payment values,
-- identify above-average orders, and compare regional
-- order-level payment performance.
--
-- BUSINESS QUESTIONS:
-- 1. Which payment records exceed the average payment?
-- 2. Which orders have the highest total payment values?
-- 3. Which orders exceed the average order payment?
-- 4. How many orders have above-average payment values?
-- 5. Which Brazilian states have the highest average
--    order payment values?
--
-- SQL TECHNIQUES:
-- WHERE subqueries, derived tables, CTEs, multiple CTEs,
-- INNER JOIN, CROSS JOIN, COUNT, SUM, AVG, and ROUND.
--
-- DATASETS:
-- olist_order_payments_dataset
-- olist_orders_dataset
-- olist_customers_dataset
--
-- DATA GRANULARITY:
-- Payments: One row per payment record.
-- Orders: One row per order_id.
-- Aggregated payments: One row per order_id.
--
-- METRIC DEFINITIONS:
-- Average Payment Record =
--     AVG(payment_value)
--
-- Average Order Payment =
--     AVG(SUM(payment_value) per order_id)
--
-- IMPORTANT:
-- Payment value is not equivalent to verified
-- platform net revenue or profit.
--
-- Unless specified otherwise, all payment-based
-- analyses include available payment records
-- regardless of order status.
--
-- All queries are read-only.
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: WHERE Subquery
-- ------------------------------------------------------------
-- Business Question:
-- Which individual payment records have values
-- above the average payment record?
--
-- Purpose:
-- Use a scalar subquery to calculate a comparison
-- value within the WHERE clause.
--
-- IMPORTANT:
-- The comparison is made at payment-record level.
-- It does not identify above-average orders.


SELECT
    order_id,
    payment_type,
    payment_value
FROM olist_order_payments_dataset
WHERE payment_value > (
    SELECT
        AVG(payment_value)
    FROM olist_order_payments_dataset
)
ORDER BY payment_value DESC, order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 2: FROM Subquery (Derived Table)
-- ------------------------------------------------------------
-- Business Question:
-- Which orders have the highest total payment values?
--
-- Purpose:
-- Aggregate individual payment records by order_id
-- inside a derived table.
--
-- The outer query then ranks the aggregated orders.
--
-- A derived table must have an alias in MySQL.


SELECT
    p.order_id,

    ROUND(
        p.order_payment_value,
        2
    ) AS order_payment_value

FROM (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
) AS p

ORDER BY p.order_payment_value DESC, p.order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 3: Single CTE
-- ------------------------------------------------------------
-- Business Question:
-- Which orders have the highest total payment values?
--
-- Purpose:
-- Demonstrate how a Common Table Expression (CTE)
-- can organise the same analytical logic as a
-- derived table.
--
-- The CTE creates one payment total per order.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    order_id,

    ROUND(
        order_payment_value,
        2
    ) AS order_payment_value

FROM order_payments
ORDER BY order_payment_value DESC, order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 4: Multiple CTEs - Above-Average Orders
-- ------------------------------------------------------------
-- Business Question:
-- Which orders have payment values above the
-- average order payment value?
--
-- Purpose:
-- Divide a multi-step analysis into two CTEs.
--
-- STEP 1:
-- Aggregate payment records by order_id.
--
-- STEP 2:
-- Calculate the average payment value per order.
--
-- STEP 3:
-- Return orders exceeding that average.
--
-- CROSS JOIN attaches the single average value
-- to every order without requiring a join key.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

average_payment AS (
    SELECT
        AVG(order_payment_value) AS avg_order_payment
    FROM order_payments
)

SELECT
    o.order_id,

    ROUND(
        o.order_payment_value,
        2
    ) AS order_payment_value,

    ROUND(
        a.avg_order_payment,
        2
    ) AS avg_order_payment

FROM order_payments AS o

CROSS JOIN average_payment AS a

WHERE o.order_payment_value > a.avg_order_payment

ORDER BY o.order_payment_value DESC, o.order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 5: Count Above-Average Orders
-- ------------------------------------------------------------
-- Business Question:
-- How many orders have payment values above the
-- average order payment value?
--
-- Purpose:
-- Extend the previous analysis from identifying
-- individual orders to calculating a summary KPI.
--
-- Only orders with payment records are included.
--
-- The comparison uses unrounded monetary values.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

average_payment AS (
    SELECT
        AVG(order_payment_value) AS avg_order_payment
    FROM order_payments
)

SELECT
    COUNT(*) AS above_average_orders

FROM order_payments AS o

CROSS JOIN average_payment AS a

WHERE o.order_payment_value > a.avg_order_payment;


-- ------------------------------------------------------------
-- PART 6: CTE + JOIN - Regional Average Order Payment
-- ------------------------------------------------------------
-- Business Question:
-- Which Brazilian states have the highest average
-- payment value per order?
--
-- Purpose:
-- Combine an order-level payment CTE with Orders
-- and Customers to analyse geographic differences.
--
-- METHODOLOGY:
-- 1. Aggregate payments to one row per order_id.
-- 2. Join the aggregated data to the Orders table.
-- 3. Join customer information using customer_id.
-- 4. Calculate average order payment by state.
--
-- IMPORTANT:
-- customer_state represents the customer's state,
-- not necessarily the seller's location.
--
-- Orders without matching customer or payment
-- records are excluded by INNER JOIN.
--
-- All order statuses are included.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS orders_with_payments,

    ROUND(
        AVG(p.order_payment_value),
        2
    ) AS avg_order_value

FROM olist_orders_dataset AS o

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

INNER JOIN order_payments AS p
    ON o.order_id = p.order_id

GROUP BY c.customer_state

ORDER BY avg_order_value DESC, c.customer_state
LIMIT 10;


-- ------------------------------------------------------------
-- PART 7: Top Five States by Average Order Payment
-- ------------------------------------------------------------
-- Business Question:
-- Which five customer states have the highest
-- average payment value per order?
--
-- Purpose:
-- Present a shorter ranking suitable for
-- communicating a regional business finding.
--
-- The calculation is the same as Part 6,
-- but the result is limited to five states.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    c.customer_state,

    COUNT(DISTINCT o.order_id) AS orders_with_payments,

    ROUND(
        AVG(p.order_payment_value),
        2
    ) AS avg_order_value

FROM olist_orders_dataset AS o

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

INNER JOIN order_payments AS p
    ON o.order_id = p.order_id

GROUP BY c.customer_state

ORDER BY avg_order_value DESC, c.customer_state
LIMIT 5;


-- ------------------------------------------------------------
-- PART 8: Validate Order-Level Payment Granularity
-- ------------------------------------------------------------
-- Business Question:
-- Does the payment CTE contain only one row per order?
--
-- Purpose:
-- Verify that aggregating payments by order_id
-- produces unique order-level records.
--
-- EXPECTED:
-- duplicate_order_rows = 0
--
-- This does not independently validate the
-- accuracy of the original payment amounts.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_rows

FROM order_payments;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. A WHERE subquery can calculate a benchmark
--    used to filter individual records.
--
-- 2. A derived table enables an aggregated result
--    to be queried as a temporary result set.
--
-- 3. A CTE improves readability by naming
--    intermediate analytical steps.
--
-- 4. Multiple CTEs support multi-stage analysis,
--    such as comparing orders with an average.
--
-- 5. CROSS JOIN can attach a single-row summary
--    value to each detailed record.
--
-- 6. Payment records should be aggregated by
--    order_id before calculating order-level AOV.
--
-- 7. CTEs combined with JOINs support regional
--    analysis across multiple related datasets.
--
-- 8. Average order payment is different from
--    average payment-record value.
--
-- 9. Validation helps confirm that intermediate
--    datasets preserve the intended granularity.
--
-- ============================================================
-- END OF LESSON 08
-- ============================================================
