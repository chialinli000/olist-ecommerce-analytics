
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 07_revenue_payment_analysis.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- TITLE:
-- Payment Value & Average Order Value Analysis
--
-- PURPOSE:
-- Analyse recorded payment values, average order
-- payments, payment methods, and regional performance.
--
-- BUSINESS QUESTIONS:
-- 1. How much payment value was recorded?
-- 2. What is the average payment value per order?
-- 3. Which payment methods account for the highest value?
-- 4. Which Brazilian states have the highest payments?
-- 5. How did payment values change over time?
--
-- SQL TECHNIQUES:
-- COUNT, COUNT DISTINCT, SUM, AVG, ROUND,
-- GROUP BY, subqueries, CTEs, and JOINs.
--
-- DATASETS:
-- olist_order_payments_dataset
-- olist_orders_dataset
-- olist_customers_dataset
--
-- DATA GRANULARITY:
-- Payments: One row per payment record.
-- Orders: One row per order_id.
-- Customers: One row per customer_id.
--
-- METRIC DEFINITIONS:
-- Total Payment Value:
--     SUM(payment_value)
--
-- Average Order Value (payment-based):
--     Total payment value / Orders with payments
--
-- NOTE:
-- Payment value represents recorded payment amounts,
-- not verified platform net revenue or profit.
--
-- Unless otherwise stated, analyses include all
-- available payment records regardless of order status.
--
-- All queries are read-only.
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Payment Data Overview
-- ------------------------------------------------------------
-- Business Question:
-- How many payment records and distinct paid orders
-- are available in the dataset?
--
-- Purpose:
-- Understand payment-level granularity before
-- calculating order-level payment metrics.


SELECT
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(MIN(payment_value), 2) AS min_payment_value,
    ROUND(MAX(payment_value), 2) AS max_payment_value
FROM olist_order_payments_dataset;


-- ------------------------------------------------------------
-- PART 2: Total Recorded Payment Value
-- ------------------------------------------------------------
-- Business Question:
-- What is the total recorded payment value?
--
-- Purpose:
-- Sum payment amounts across all payment records.
--
-- IMPORTANT:
-- This represents gross recorded payment value.
-- It should not be labelled as net revenue or profit.


SELECT
    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value
FROM olist_order_payments_dataset;


-- ------------------------------------------------------------
-- PART 3: Average Order Value (AOV)
-- ------------------------------------------------------------
-- Business Question:
-- What is the average payment value per order?
--
-- Purpose:
-- Calculate a payment-based Average Order Value.
--
-- IMPORTANT:
-- A single order_id may appear in multiple
-- payment records.
--
-- Therefore, AVG(payment_value) calculates the
-- average payment RECORD, not the average ORDER.
--
-- Only orders with payment records are included.


-- 3.1 Average payment record value
-- Demonstrates the difference in data granularity.

SELECT
    ROUND(
        AVG(payment_value),
        2
    ) AS avg_payment_record_value
FROM olist_order_payments_dataset;


-- 3.2 Aggregate payments to one row per order

SELECT
    order_id,
    ROUND(
        SUM(payment_value),
        2
    ) AS order_payment_value
FROM olist_order_payments_dataset
GROUP BY order_id
ORDER BY order_id
LIMIT 10;


-- 3.3 Calculate the payment-based AOV using a CTE
-- Each row in order_payments represents one order.

WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    COUNT(*) AS orders_with_payments,

    ROUND(
        SUM(order_payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(order_payment_value),
        2
    ) AS avg_order_value

FROM order_payments;


-- ------------------------------------------------------------
-- PART 4: Payment Method Performance
-- ------------------------------------------------------------
-- Business Question:
-- Which payment methods account for the highest
-- recorded payment value?
--
-- Purpose:
-- Compare payment counts, distinct orders,
-- and total amounts across payment methods.
--
-- NOTE:
-- An order can use more than one payment method.
-- Therefore, unique_orders may overlap across
-- different payment_type categories.
--
-- The output uses the same monetary definition
-- as the Payment Value by Method chart in Power BI.


SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(payment_value),
        2
    ) AS avg_payment_record_value

FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_payment_value DESC, payment_type;


-- ------------------------------------------------------------
-- PART 5: Payment Value Share by Method
-- ------------------------------------------------------------
-- Business Question:
-- What percentage of total recorded payment value
-- is associated with each payment method?
--
-- Purpose:
-- Calculate each payment method's contribution
-- to overall recorded payment value.
--
-- FORMULA:
-- Payment Share (%) =
-- Payment Method Value / Total Payment Value * 100
--
-- NULLIF prevents division by zero.


SELECT
    payment_type,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        100.0 * SUM(payment_value) /
        NULLIF(
            (
                SELECT SUM(payment_value)
                FROM olist_order_payments_dataset
            ),
            0
        ),
        2
    ) AS payment_share_pct

FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY payment_share_pct DESC, payment_type;


-- ------------------------------------------------------------
-- PART 6: Regional Payment Value Analysis
-- ------------------------------------------------------------
-- Business Question:
-- Which Brazilian states recorded the highest total
-- payment value?
--
-- Purpose:
-- Combine Orders, Customers, and Payments to
-- compare geographic payment performance.
--
-- METHODOLOGY:
-- 1. Aggregate payments by order_id.
-- 2. Join aggregated payments to Orders.
-- 3. Join Orders to Customers.
-- 4. Summarise results by customer_state.
--
-- This avoids multiplying order counts due
-- to multiple payment records.
--
-- SCOPE:
-- Includes matched orders with payment records,
-- regardless of order_status.


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
        SUM(p.order_payment_value),
        2
    ) AS total_payment_value,

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
ORDER BY total_payment_value DESC, c.customer_state
LIMIT 10;


-- ------------------------------------------------------------
-- PART 7: Monthly Payment Value Trend
-- ------------------------------------------------------------
-- Business Question:
-- How did total payment values and average order
-- values change across reporting months?
--
-- Purpose:
-- Summarise payment values by order purchase month.
--
-- REPORTING PERIOD:
-- January 2017 through August 2018.
--
-- >= 2017-01-01 and < 2018-09-01.
--
-- This matches the monthly reporting window
-- used by Dashboard Page 1.
--
-- NOTE:
-- The monthly chart currently shown in Power BI
-- tracks order counts, not payment values.
-- This query is a separate supporting analysis.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,

    COUNT(DISTINCT o.order_id) AS orders_with_payments,

    ROUND(
        SUM(p.order_payment_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(p.order_payment_value),
        2
    ) AS avg_order_value

FROM olist_orders_dataset AS o

INNER JOIN order_payments AS p
    ON o.order_id = p.order_id

WHERE o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'

GROUP BY DATE_FORMAT(
    o.order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 8: Payment Granularity Validation
-- ------------------------------------------------------------
-- Business Question:
-- Does the order-level payment CTE contain one
-- record per order?
--
-- Purpose:
-- Verify that payment aggregation removes
-- multiple payment rows per order_id.
--
-- EXPECTED:
-- row_difference = 0
--
-- This is a structural check, not proof that
-- all original payment records are valid.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    COUNT(*) AS order_count,
    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS row_difference

FROM order_payments;


-- ------------------------------------------------------------
-- PART 9: Payment Value Reconciliation
-- ------------------------------------------------------------
-- Business Question:
-- Does the order-level aggregation preserve the
-- payment value from the original records?
--
-- Purpose:
-- Reconcile payment totals across two granularities.
--
-- This comparison uses payment records with
-- non-null order_id.
--
-- EXPECTED:
-- payment_value_difference = 0.00
-- apart from possible floating-point rounding effects.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

original_payments AS (
    SELECT
        SUM(payment_value) AS total_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
)

SELECT
    ROUND(
        op.total_payment_value,
        2
    ) AS original_payment_value,

    ROUND(
        (
            SELECT SUM(order_payment_value)
            FROM order_payments
        ),
        2
    ) AS aggregated_payment_value,

    ROUND(
        op.total_payment_value -
        (
            SELECT SUM(order_payment_value)
            FROM order_payments
        ),
        2
    ) AS payment_value_difference

FROM original_payments AS op;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. Payment records and orders have different
--    levels of data granularity.
--
-- 2. SUM(payment_value) calculates total recorded
--    payment value, not verified company revenue.
--
-- 3. AVG(payment_value) measures the average
--    payment record, not Average Order Value.
--
-- 4. A payment-based AOV should be calculated
--    from payment totals aggregated by order_id.
--
-- 5. Payment method totals can be compared
--    with the Power BI payment method chart.
--
-- 6. Payment share percentages describe the
--    distribution of recorded payment amounts.
--
-- 7. Pre-aggregating payments before JOINs
--    preserves order-level analytical granularity.
--
-- 8. Reconciliation checks help confirm that
--    payment aggregation preserves total value.
--
-- 9. Monthly payment analysis and customer RFM
--    analysis use different data scopes.
--
-- ============================================================
-- END OF LESSON 07
-- ============================================================
