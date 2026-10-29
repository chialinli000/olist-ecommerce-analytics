
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 10_customer_rfm_segmentation.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- TITLE:
-- Customer Behaviour & Rule-Based RFM Segmentation
--
-- PURPOSE:
-- Analyse customer purchasing behaviour, calculate
-- Recency, Frequency, and Monetary (RFM) metrics,
-- and classify customers into five business segments.
--
-- BUSINESS QUESTIONS:
-- 1. How many unique customers are in the dataset?
-- 2. What proportion of customers made repeat purchases?
-- 3. How much payment value is associated with
--    individual customers?
-- 4. How recently did each customer place an order?
-- 5. How are customers distributed across RFM segments?
-- 6. What limitations exist in the segmentation rules?
--
-- SQL TECHNIQUES:
-- COUNT DISTINCT, SUM, AVG, MAX, DATEDIFF, CASE WHEN,
-- GROUP BY, HAVING, JOINs, CTEs, and conditional
-- aggregation.
--
-- DATASETS:
-- olist_orders_dataset
-- olist_customers_dataset
-- olist_order_payments_dataset
--
-- ANALYSIS SNAPSHOT:
-- 2018-09-01
--
-- CUSTOMER ANALYSIS SCOPE:
-- 1. Only delivered orders are included.
-- 2. Order purchase timestamp must be before
--    2018-09-01.
-- 3. Orders must have matching customer records.
-- 4. Orders must have matching payment records.
-- 5. customer_unique_id must not be NULL.
--
-- RFM DEFINITIONS:
-- Recency: Days since the latest eligible order.
-- Frequency: Number of distinct eligible orders.
-- Monetary: Total payment value of eligible orders.
--
-- IMPORTANT:
-- RFM segments are based on illustrative rules,
-- not machine-learning clustering or optimised
-- statistical thresholds.
--
-- All queries are read-only.
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Customer Identifier Exploration
-- ------------------------------------------------------------
-- Business Question:
-- How many customer records and unique customers
-- are available in the Customers dataset?
--
-- Purpose:
-- Understand the difference between customer_id
-- and customer_unique_id.
--
-- customer_id:
-- Identifies an order-associated customer record.
--
-- customer_unique_id:
-- Identifies a customer across different orders.
--
-- NOTE:
-- This is a full Customers-table overview, not
-- the filtered RFM customer population.


SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM olist_customers_dataset;


-- ------------------------------------------------------------
-- PART 2: Repeat Purchase Analysis
-- ------------------------------------------------------------
-- Business Question:
-- What proportion of eligible customers placed
-- at least two delivered orders?
--
-- Purpose:
-- Calculate repeat customers using the same
-- observation scope as Dashboard Page 2.
--
-- METHODOLOGY:
-- 1. Identify orders with payment records.
-- 2. Join Orders and Customers.
-- 3. Filter eligible delivered orders.
-- 4. Count distinct orders per unique customer.
-- 5. Calculate the repeat-purchase rate.
--
-- FORMULA:
-- Repeat Purchase Rate (%) =
-- Repeat Customers / Total Customers * 100
--
-- Repeat Customer:
-- A customer with frequency >= 2.
--
-- This metric measures observed repeat purchasing,
-- not a cohort-based customer retention rate.


WITH paid_orders AS (
    SELECT
        order_id
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN paid_orders AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN frequency >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN frequency >= 2 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_rate_pct

FROM customer_orders;


-- ------------------------------------------------------------
-- PART 3: Customer Monetary Value
-- ------------------------------------------------------------
-- Business Question:
-- Which customers have the highest accumulated
-- payment values?
--
-- Purpose:
-- Aggregate payments at order level before
-- calculating total payment value by customer.
--
-- IMPORTANT:
-- Multiple payment records can belong to one order.
-- Pre-aggregation avoids multiplying order-level
-- records in the customer analysis.
--
-- The ranking uses unrounded payment totals.
-- Only the displayed values are rounded.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_value AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(p.order_payment_value) AS monetary_value

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value

FROM customer_value
ORDER BY monetary_value DESC, customer_unique_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 4: Recency and Frequency Analysis
-- ------------------------------------------------------------
-- Business Question:
-- How recently did customers place their latest
-- eligible orders, and how often did they purchase?
--
-- Purpose:
-- Calculate Recency and Frequency using the
-- historical snapshot date.
--
-- SNAPSHOT DATE:
-- 2018-09-01
--
-- Recency is based on order purchase date,
-- not the actual delivery date.
--
-- CURRENT_DATE() is not used because it would
-- measure activity relative to today's date
-- instead of the historical observation period.


WITH paid_orders AS (
    SELECT
        order_id
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    c.customer_unique_id,

    MAX(o.order_purchase_timestamp) AS last_order_date,

    COUNT(DISTINCT o.order_id) AS frequency,

    DATEDIFF(
        '2018-09-01',
        DATE(MAX(o.order_purchase_timestamp))
    ) AS recency_days

FROM olist_orders_dataset AS o

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

INNER JOIN paid_orders AS p
    ON o.order_id = p.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND c.customer_unique_id IS NOT NULL

GROUP BY c.customer_unique_id

ORDER BY recency_days ASC, c.customer_unique_id
LIMIT 10;


-- ------------------------------------------------------------
-- PART 5: Complete Customer RFM Analysis
-- ------------------------------------------------------------
-- Business Question:
-- What are each customer's Recency, Frequency,
-- and Monetary values?
--
-- Purpose:
-- Create customer-level RFM metrics for eligible
-- delivered orders with matching payment records.
--
-- DATA GRAIN:
-- One row per customer_unique_id.
--
-- R:
-- Days since latest eligible purchase.
--
-- F:
-- Number of distinct eligible orders.
--
-- M:
-- Sum of eligible order payment values.
--
-- This calculation matches the methodology
-- used in Lesson 11 for Dashboard Page 2.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,

        DATEDIFF(
            '2018-09-01',
            DATE(MAX(o.order_purchase_timestamp))
        ) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(p.order_payment_value) AS monetary_value

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value

FROM customer_rfm

ORDER BY monetary_value DESC, customer_unique_id
LIMIT 20;


-- ------------------------------------------------------------
-- PART 6: Rule-Based Customer Segmentation
-- ------------------------------------------------------------
-- Business Question:
-- How can customers be classified into meaningful
-- groups based on purchasing behaviour?
--
-- Purpose:
-- Apply predefined RFM thresholds using CASE WHEN.
--
-- SEGMENT RULES (evaluated in order):
--
-- Champions:
-- Recency <= 90 days
-- Frequency >= 2
-- Monetary >= BRL 200
--
-- Loyal Customers:
-- Recency <= 180 days
-- Frequency >= 2
-- Not already classified as Champions
--
-- At Risk:
-- Recency > 180 days
-- Frequency >= 2
--
-- New / Occasional:
-- Recency <= 90 days
-- Frequency = 1
--
-- Other Customers:
-- All remaining eligible customers.
--
-- IMPORTANT:
-- These rules are illustrative rather than
-- statistically optimised segmentation criteria.
--
-- The CASE WHEN order is significant.
-- This definition matches Lesson 11.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,

        DATEDIFF(
            '2018-09-01',
            DATE(MAX(o.order_purchase_timestamp))
        ) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(p.order_payment_value) AS monetary_value

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,

    ROUND(
        monetary_value,
        2
    ) AS monetary_value,

    CASE
        WHEN recency_days <= 90
             AND frequency >= 2
             AND monetary_value >= 200
        THEN 'Champions'

        WHEN recency_days <= 180
             AND frequency >= 2
        THEN 'Loyal Customers'

        WHEN recency_days > 180
             AND frequency >= 2
        THEN 'At Risk'

        WHEN recency_days <= 90
             AND frequency = 1
        THEN 'New / Occasional'

        ELSE 'Other Customers'
    END AS customer_segment

FROM customer_rfm

ORDER BY monetary_value DESC, customer_unique_id
LIMIT 20;


-- ------------------------------------------------------------
-- PART 7: Customer Segment Summary
-- ------------------------------------------------------------
-- Business Question:
-- How many customers belong to each RFM segment,
-- and what payment values are associated with them?
--
-- Purpose:
-- Generate the segment summary used in
-- Dashboard Page 2.
--
-- OUTPUT:
-- customer_segment
-- customer_count
-- total_payment_value
-- avg_customer_value
--
-- Monetary values represent recorded payments,
-- not net revenue or profit.
--
-- NOTE:
-- Segment counts should sum to the total number
-- of eligible customers in Part 2.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,

        DATEDIFF(
            '2018-09-01',
            DATE(MAX(o.order_purchase_timestamp))
        ) AS recency_days,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(p.order_payment_value) AS monetary_value

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
),

segmented_customers AS (
    SELECT
        customer_unique_id,
        monetary_value,

        CASE
            WHEN recency_days <= 90
                 AND frequency >= 2
                 AND monetary_value >= 200
            THEN 'Champions'

            WHEN recency_days <= 180
                 AND frequency >= 2
            THEN 'Loyal Customers'

            WHEN recency_days > 180
                 AND frequency >= 2
            THEN 'At Risk'

            WHEN recency_days <= 90
                 AND frequency = 1
            THEN 'New / Occasional'

            ELSE 'Other Customers'
        END AS customer_segment

    FROM customer_rfm
)

SELECT
    customer_segment,

    COUNT(*) AS customer_count,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_payment_value,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value

FROM segmented_customers

GROUP BY customer_segment

ORDER BY customer_count DESC, customer_segment;


-- ------------------------------------------------------------
-- PART 8: High-Value Customer Analysis
-- ------------------------------------------------------------
-- Business Question:
-- Which customers accumulated more than BRL 500
-- in eligible order payments?
--
-- Purpose:
-- Identify customers above a predefined payment
-- value threshold.
--
-- NOTE:
-- BRL 500 is an illustrative analysis threshold,
-- not a validated high-value customer definition.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
)

SELECT
    c.customer_unique_id,

    COUNT(DISTINCT o.order_id) AS frequency,

    ROUND(
        SUM(p.order_payment_value),
        2
    ) AS monetary_value

FROM olist_orders_dataset AS o

INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id

INNER JOIN order_payments AS p
    ON o.order_id = p.order_id

WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp < '2018-09-01'
  AND c.customer_unique_id IS NOT NULL

GROUP BY c.customer_unique_id

HAVING SUM(p.order_payment_value) > 500

ORDER BY monetary_value DESC, c.customer_unique_id;


-- ------------------------------------------------------------
-- PART 9: RFM and Repeat-Purchase Validation
-- ------------------------------------------------------------
-- Business Question:
-- Do customer counts, repeat counts, and payment
-- totals reconcile at the customer level?
--
-- Purpose:
-- Verify the overall RFM population and calculate
-- the same customer KPIs used in Dashboard Page 2.
--
-- EXPECTED DASHBOARD REFERENCE:
-- Total customers: 93,357
-- Repeat customers: 2,801
-- Repeat purchase rate: 3.00%
--
-- These values must be verified against the
-- actual SQL execution results.
--
-- Average customer monetary value is calculated
-- before final rounding.


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    WHERE order_id IS NOT NULL
    GROUP BY order_id
),

customer_rfm AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS frequency,

        SUM(p.order_payment_value) AS monetary_value

    FROM olist_orders_dataset AS o

    INNER JOIN olist_customers_dataset AS c
        ON o.customer_id = c.customer_id

    INNER JOIN order_payments AS p
        ON o.order_id = p.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND c.customer_unique_id IS NOT NULL

    GROUP BY c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN frequency >= 2 THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN frequency >= 2 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_purchase_rate_pct,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_customer_value,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_customer_payment_value

FROM customer_rfm;


-- ============================================================
-- LIMITATIONS AND INTERPRETATION
-- ============================================================
--
-- 1. The analysis uses historical delivered orders
--    placed before 2018-09-01 with payment records.
--
-- 2. Recency reflects purchase dates rather than
--    delivery dates.
--
-- 3. Repeat purchase rate is not a cohort-based
--    retention or customer lifetime value measure.
--
-- 4. Monetary value reflects recorded payments,
--    not confirmed net revenue or profitability.
--
-- 5. RFM segments use illustrative thresholds
--    rather than statistically validated cutoffs.
--
-- 6. A large Other Customers segment limits
--    the segmentation's behavioural precision.
--
-- 7. Further work could use percentile-based RFM
--    scoring, cohort analysis, and segment validation.
--
-- ============================================================
-- END OF LESSON 10
-- ============================================================
