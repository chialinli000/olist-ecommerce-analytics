
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 09_window_functions.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- TITLE:
-- SQL Window Functions & Advanced Analytics
--
-- PURPOSE:
-- Apply SQL window functions to rank orders, identify
-- high-value transactions, calculate cumulative payment
-- values, measure monthly order growth, and retrieve
-- each customer's latest order.
--
-- BUSINESS QUESTIONS:
-- 1. Which orders have the highest payment values?
-- 2. How do different ranking functions handle ties?
-- 3. What are the top three orders within each state?
-- 4. How does cumulative payment value change over time?
-- 5. How does monthly order volume compare with the
--    previous month?
-- 6. What is the most recent order for each customer?
--
-- SQL TECHNIQUES:
-- ROW_NUMBER, RANK, DENSE_RANK, PARTITION BY,
-- SUM OVER, LAG, CTEs, JOINs, and aggregation.
--
-- DATASETS:
-- olist_orders_dataset
-- olist_customers_dataset
-- olist_order_payments_dataset
--
-- DATA GRANULARITY:
-- Orders: One row per order_id.
-- Payments: Multiple records may exist per order_id.
-- Customers: customer_unique_id identifies a customer
-- across multiple orders.
--
-- REPORTING PERIOD:
-- Monthly analyses cover January 2017 to August 2018.
-- Other queries use the full available dataset.
--
-- NOTE:
-- Payment value is not verified net revenue or profit.
-- All queries are read-only.
--
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: GROUP BY vs. Window Functions
-- ------------------------------------------------------------
-- Business Question:
-- How can individual payment records be displayed
-- alongside an overall payment value?
--
-- Purpose:
-- Demonstrate SUM() OVER() without PARTITION BY.
--
-- Unlike GROUP BY, the window function preserves
-- individual payment records in the result.
--
-- NOTE:
-- The total is calculated over all payment records
-- before LIMIT restricts the displayed output.


SELECT
    order_id,
    payment_value,

    ROUND(
        SUM(payment_value) OVER (),
        2
    ) AS total_payment_value

FROM olist_order_payments_dataset
ORDER BY order_id, payment_sequential
LIMIT 10;


-- ------------------------------------------------------------
-- PART 2: ROW_NUMBER - Rank Orders by Payment Value
-- ------------------------------------------------------------
-- Business Question:
-- Which orders have the highest recorded payments?
--
-- Purpose:
-- Assign a unique sequence number to each order,
-- ranked by total order payment value.
--
-- METHODOLOGY:
-- 1. Aggregate payments by order_id.
-- 2. Rank orders using ROW_NUMBER().
--
-- ORDER BY order_id provides deterministic
-- ordering when two orders have equal values.


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
    ) AS order_payment_value,

    ROW_NUMBER() OVER (
        ORDER BY order_payment_value DESC, order_id
    ) AS payment_rank

FROM order_payments
ORDER BY payment_rank
LIMIT 10;


-- ------------------------------------------------------------
-- PART 3: ROW_NUMBER vs. RANK vs. DENSE_RANK
-- ------------------------------------------------------------
-- Business Question:
-- How should orders with identical payment values
-- be ranked?
--
-- Purpose:
-- Compare three window ranking functions.
--
-- ROW_NUMBER:
-- Gives each order a unique sequential number.
--
-- RANK:
-- Assigns equal rank to tied values but skips
-- the following ranking positions.
--
-- DENSE_RANK:
-- Assigns equal rank to tied values without
-- skipping subsequent ranking positions.
--
-- IMPORTANT:
-- RANK and DENSE_RANK use payment value only.
-- Adding order_id to their ORDER BY would remove
-- meaningful ties between different orders.


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
    ) AS order_payment_value,

    ROW_NUMBER() OVER (
        ORDER BY order_payment_value DESC, order_id
    ) AS row_num,

    RANK() OVER (
        ORDER BY order_payment_value DESC
    ) AS order_rank,

    DENSE_RANK() OVER (
        ORDER BY order_payment_value DESC
    ) AS dense_rank_num

FROM order_payments
ORDER BY order_payment_value DESC, order_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 4: PARTITION BY - Top Three Orders per State
-- ------------------------------------------------------------
-- Business Question:
-- Which three orders have the highest recorded
-- payment values within each Brazilian state?
--
-- Purpose:
-- Rank orders independently within each
-- customer_state.
--
-- PARTITION BY restarts the ranking for each state.
--
-- ROW_NUMBER returns exactly three orders per state
-- when a state has at least three eligible orders.
-- Tied payment values are resolved using order_id.
--
-- NOTE:
-- The geographic grouping refers to the customer's
-- state, not the seller's state.
--
-- Orders must have matching customer and payment data.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

ranked_orders AS (
    SELECT
        c.customer_state,
        o.order_id,
        p.order_payment_value,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_state
            ORDER BY p.order_payment_value DESC, o.order_id
        ) AS state_rank

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id
)

SELECT
    customer_state,
    order_id,

    ROUND(
        order_payment_value,
        2
    ) AS order_payment_value,

    state_rank

FROM ranked_orders
WHERE state_rank <= 3
ORDER BY customer_state, state_rank;


-- ------------------------------------------------------------
-- PART 5: Cumulative Monthly Payment Value
-- ------------------------------------------------------------
-- Business Question:
-- How does cumulative recorded payment value
-- increase over the reporting period?
--
-- Purpose:
-- Calculate monthly payment totals and their
-- running cumulative sum using SUM() OVER().
--
-- REPORTING PERIOD:
-- 2017-01-01 inclusive to 2018-09-01 exclusive.
--
-- METHODOLOGY:
-- 1. Aggregate payments at order level.
-- 2. Match payments to orders.
-- 3. Calculate monthly payment totals.
-- 4. Compute the running cumulative payment value.
--
-- IMPORTANT:
-- Payment values are grouped by purchase month,
-- not by the date when payment was processed.
--
-- All order statuses with matching payments are
-- included. This is not a net revenue measure.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

monthly_payments AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        SUM(p.order_payment_value) AS monthly_payment_value

    FROM olist_orders_dataset AS o

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'

    GROUP BY DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    )
)

SELECT
    order_month,

    ROUND(
        monthly_payment_value,
        2
    ) AS monthly_payment_value,

    ROUND(
        SUM(monthly_payment_value) OVER (
            ORDER BY order_month
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ),
        2
    ) AS cumulative_payment_value

FROM monthly_payments
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 6: LAG - Month-over-Month Order Growth
-- ------------------------------------------------------------
-- Business Question:
-- How did monthly order volume change compared
-- with the previous reporting month?
--
-- Purpose:
-- Use LAG() to retrieve the previous month's
-- order count and calculate percentage growth.
--
-- FORMULA:
-- MoM Growth (%) =
-- (Current Orders - Previous Orders)
-- / Previous Orders * 100
--
-- REPORTING PERIOD:
-- January 2017 to August 2018.
--
-- This uses the same order-volume definition and
-- reporting window as Lesson 05 and Dashboard Page 1.
--
-- NOTE:
-- January 2017 has no previous month in this query.
-- Its growth rate is therefore NULL.
--
-- Missing calendar months are not automatically
-- generated; LAG compares consecutive result rows.


WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(*) AS total_orders

    FROM olist_orders_dataset

    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'

    GROUP BY DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    )
),

monthly_comparison AS (
    SELECT
        order_month,
        total_orders,

        LAG(total_orders) OVER (
            ORDER BY order_month
        ) AS previous_month_orders

    FROM monthly_orders
)

SELECT
    order_month,
    total_orders,
    previous_month_orders,

    ROUND(
        100.0 * (
            total_orders - previous_month_orders
        ) / NULLIF(previous_month_orders, 0),
        2
    ) AS mom_growth_pct

FROM monthly_comparison
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 7: Latest Order for Each Unique Customer
-- ------------------------------------------------------------
-- Business Question:
-- What is the latest recorded order for each customer?
--
-- Purpose:
-- Use ROW_NUMBER with PARTITION BY to identify
-- one latest order for every customer_unique_id.
--
-- JOIN KEY:
-- Orders.customer_id = Customers.customer_id
--
-- PARTITION KEY:
-- customer_unique_id
--
-- ORDERING:
-- Most recent purchase timestamp first.
-- order_id breaks ties deterministically.
--
-- SCOPE:
-- This query includes all order statuses and
-- all available purchase dates.
--
-- Unlike the RFM analysis in Lesson 10, this query
-- does not filter to delivered orders or apply
-- the 2018-09-01 observation cutoff.


WITH ranked_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY
                o.order_purchase_timestamp DESC,
                o.order_id DESC
        ) AS recency_rank

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    WHERE c.customer_unique_id IS NOT NULL
)

SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp

FROM ranked_customer_orders
WHERE recency_rank = 1
ORDER BY customer_unique_id
LIMIT 20;


-- ------------------------------------------------------------
-- PART 8: Cumulative Monthly Order Volume
-- ------------------------------------------------------------
-- Business Question:
-- How many orders accumulated during the
-- reporting period?
--
-- Purpose:
-- Use a running SUM to calculate cumulative
-- order counts by month.
--
-- This query is adapted from the original
-- independent practice in Lesson 09.
--
-- REPORTING PERIOD:
-- January 2017 to August 2018.
--
-- All order statuses are included.


WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(
            order_purchase_timestamp,
            '%Y-%m'
        ) AS order_month,

        COUNT(*) AS total_orders

    FROM olist_orders_dataset

    WHERE order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp < '2018-09-01'

    GROUP BY DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    )
)

SELECT
    order_month,
    total_orders,

    SUM(total_orders) OVER (
        ORDER BY order_month
        ROWS BETWEEN UNBOUNDED PRECEDING
                 AND CURRENT ROW
    ) AS cumulative_orders

FROM monthly_orders
ORDER BY order_month;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. Window functions calculate results across
--    related rows without collapsing those rows.
--
-- 2. ROW_NUMBER assigns a unique position based
--    on the specified ordering.
--
-- 3. RANK and DENSE_RANK preserve tied values,
--    but handle subsequent rank positions differently.
--
-- 4. PARTITION BY divides data into independent
--    ranking or calculation groups.
--
-- 5. Running totals measure cumulative values
--    across chronologically ordered rows.
--
-- 6. LAG retrieves a previous row's value to
--    support period-over-period comparisons.
--
-- 7. Payment aggregation by order_id helps
--    preserve order-level analytical accuracy.
--
-- 8. Reporting windows and status filters must
--    be stated when comparing different analyses.
--
-- 9. These techniques support advanced operational
--    reporting and customer behaviour analysis.
--
-- ============================================================
-- END OF LESSON 09
-- ============================================================
