
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 11_dashboard_data.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- TITLE:
-- Power BI Dashboard Data Preparation
--
-- PURPOSE:
-- Prepare six aggregated datasets for a two-page
-- Power BI dashboard covering operational performance,
-- payment behaviour, and customer RFM segmentation.
--
-- DASHBOARD PAGE 1:
-- Sales & Operations Overview
--
-- OUTPUT FILES:
-- 1. executive_kpis.csv
-- 2. monthly_performance.csv
-- 3. payment_methods.csv
--
-- DASHBOARD PAGE 2:
-- Customer Behaviour & Segmentation
--
-- OUTPUT FILES:
-- 4. customer_kpis.csv
-- 5. customer_segments.csv
-- 6. customer_frequency.csv
--
-- DATA SOURCES:
-- olist_orders_dataset
-- olist_customers_dataset
-- olist_order_payments_dataset
--
-- REPORTING DEFINITIONS:
--
-- Overall order KPIs:
-- All records in the Orders dataset.
--
-- Monthly operational performance:
-- 2017-01-01 inclusive to 2018-09-01 exclusive.
--
-- Payment methods:
-- All records in the Payments dataset.
--
-- Customer RFM:
-- Delivered orders purchased before 2018-09-01,
-- with matching customer and payment records.
--
-- Customer identifier:
-- customer_unique_id
--
-- IMPORTANT:
-- The six output schemas and their column names
-- are retained for compatibility with Power BI.
--
-- All queries are read-only.
-- ============================================================


USE ecommerce_analysis;


-- ============================================================
-- PAGE 1: SALES & OPERATIONS OVERVIEW
-- ============================================================


-- ------------------------------------------------------------
-- EXPORT 1: executive_kpis.csv
-- ------------------------------------------------------------
-- Business Question:
-- What is the overall operational performance
-- of the recorded orders?
--
-- PURPOSE:
-- Calculate the four core KPI cards:
-- total_orders
-- delivered_orders
-- canceled_orders
-- cancellation_rate_pct
--
-- SCOPE:
-- Full Orders dataset, including all order statuses.
--
-- CANCELLATION RATE:
-- Canceled Orders / Total Orders * 100.
--
-- IMPORTANT:
-- cancellation_rate_pct is already multiplied by 100.
-- For example, 0.63 represents 0.63%.
-- Do not apply an additional percentage conversion
-- to this value in Power BI.


SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN order_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS canceled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_status = 'canceled' THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM olist_orders_dataset;


-- ------------------------------------------------------------
-- EXPORT 2: monthly_performance.csv
-- ------------------------------------------------------------
-- Business Question:
-- How did monthly order volume, deliveries,
-- cancellations, and cancellation rates change?
--
-- PURPOSE:
-- Prepare the operational time-series dataset.
--
-- SCOPE:
-- January 2017 through August 2018.
--
-- The date range matches Dashboard Page 1.
--
-- MONTH FORMAT:
-- YYYY-MM, e.g., 2017-01.
--
-- Each month includes orders of all statuses.
--
-- NOTE:
-- Power BI may use a separate display column
-- to show English month labels such as Jan 2017.
-- The underlying order_month output is unchanged.


SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN order_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS canceled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_status = 'canceled' THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM olist_orders_dataset

WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp < '2018-09-01'

GROUP BY DATE_FORMAT(
    order_purchase_timestamp,
    '%Y-%m'
)

ORDER BY order_month;


-- ------------------------------------------------------------
-- EXPORT 3: payment_methods.csv
-- ------------------------------------------------------------
-- Business Question:
-- Which payment methods contribute the highest
-- recorded payment values?
--
-- PURPOSE:
-- Prepare the Payment Value by Method chart.
--
-- SCOPE:
-- Full Payments dataset.
--
-- This query does not filter by order status
-- or purchase date.
--
-- OUTPUT COLUMNS:
-- payment_type
-- payment_records
-- unique_orders
-- total_payment_value
--
-- IMPORTANT:
-- A single order can contain multiple payments.
-- Therefore, unique_orders can overlap between
-- different payment_type categories.
--
-- The raw payment_type labels are preserved.
-- Display-friendly labels can be created in Power BI.
--
-- Recorded payment value is not verified
-- platform net revenue or profit.


SELECT
    payment_type,

    COUNT(*) AS payment_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value

FROM olist_order_payments_dataset

GROUP BY payment_type

ORDER BY total_payment_value DESC, payment_type;


-- ============================================================
-- PAGE 2: CUSTOMER BEHAVIOUR & SEGMENTATION
-- ============================================================
--
-- SNAPSHOT DATE:
-- 2018-09-01
--
-- ELIGIBLE ORDERS:
-- 1. order_status = 'delivered'
-- 2. order_purchase_timestamp < '2018-09-01'
-- 3. Matching Customers record
-- 4. Matching Payments record
-- 5. Non-null customer_unique_id
--
-- PAYMENT GRANULARITY:
-- Payments are aggregated by order_id before
-- being joined to the Orders and Customers tables.
--
-- CUSTOMER GRANULARITY:
-- One row per customer_unique_id in customer_rfm.
--
-- RFM METRICS:
-- Recency = Days since latest eligible purchase.
-- Frequency = Distinct eligible order count.
-- Monetary = Sum of eligible order payment values.
-- ============================================================


-- ------------------------------------------------------------
-- EXPORT 4: customer_kpis.csv
-- ------------------------------------------------------------
-- Business Question:
-- How many eligible customers are included in
-- the analysis, and how frequently do they repurchase?
--
-- PURPOSE:
-- Prepare the customer KPI cards:
-- total_customers
-- repeat_customers
-- repeat_purchase_rate_pct
-- avg_customer_value
--
-- REPEAT CUSTOMER:
-- frequency >= 2.
--
-- REPEAT PURCHASE RATE:
-- Repeat Customers / Total Customers * 100.
--
-- AVERAGE CUSTOMER VALUE:
-- Average accumulated payment value per
-- eligible unique customer.
--
-- This is not Customer Lifetime Value (CLV).


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value

    FROM olist_order_payments_dataset

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
    ) AS avg_customer_value

FROM customer_rfm;


-- ------------------------------------------------------------
-- EXPORT 5: customer_segments.csv
-- ------------------------------------------------------------
-- Business Question:
-- How are customers distributed across RFM segments,
-- and how much payment value is associated with them?
--
-- PURPOSE:
-- Prepare two Power BI visuals:
-- 1. Customers by Segment
-- 2. Payment Value by Segment
--
-- SEGMENT DEFINITIONS:
--
-- Champions:
-- Recency <= 90
-- Frequency >= 2
-- Monetary >= BRL 200
--
-- Loyal Customers:
-- Recency <= 180
-- Frequency >= 2
-- Not already classified as Champions
--
-- At Risk:
-- Recency > 180
-- Frequency >= 2
--
-- New / Occasional:
-- Recency <= 90
-- Frequency = 1
--
-- Other Customers:
-- Remaining eligible customers.
--
-- IMPORTANT:
-- CASE WHEN conditions are evaluated in order.
-- These rules match Lesson 10 and are illustrative,
-- not statistically optimised.
--
-- OUTPUT COLUMNS:
-- customer_segment
-- customer_count
-- total_payment_value
-- avg_customer_value


WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value

    FROM olist_order_payments_dataset

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
        frequency,
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

ORDER BY customer_count DESC;


-- ------------------------------------------------------------
-- EXPORT 6: customer_frequency.csv
-- ------------------------------------------------------------
-- Business Question:
-- How many customers purchased once versus
-- at least twice during the observation period?
--
-- PURPOSE:
-- Prepare the One-time vs Repeat Customers chart.
--
-- CATEGORY DEFINITIONS:
-- One-time Customers: frequency = 1
-- Repeat Customers: frequency >= 2
--
-- SCOPE:
-- Identical to the customer KPI and segment queries.
--
-- IMPORTANT:
-- Payments are deduplicated by order_id before
-- joining to avoid duplicating order records.
--
-- OUTPUT COLUMNS:
-- purchase_group
-- customer_count
--
-- The sum of customer_count should equal
-- customer_kpis.total_customers.
--
-- The Repeat Customers count should equal
-- customer_kpis.repeat_customers.


WITH order_payments AS (
    SELECT
        order_id

    FROM olist_order_payments_dataset

    GROUP BY order_id
),

customer_orders AS (
    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS frequency

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
    CASE
        WHEN frequency = 1
        THEN 'One-time Customers'

        ELSE 'Repeat Customers'
    END AS purchase_group,

    COUNT(*) AS customer_count

FROM customer_orders

GROUP BY purchase_group

ORDER BY customer_count DESC;


-- ============================================================
-- DATA VALIDATION NOTES
-- ============================================================
--
-- PAGE 1:
--
-- 1. Executive KPIs use all recorded orders.
--
-- 2. The monthly trend uses January 2017
--    through August 2018 only.
--
-- 3. Payment method values use all payment records,
--    regardless of order status.
--
-- PAGE 2:
--
-- 4. Customer KPIs, segments, and frequency share
--    the same eligible customer population.
--
-- 5. The sum of customer segment counts should
--    equal total_customers.
--
-- 6. One-time Customers + Repeat Customers should
--    equal total_customers.
--
-- 7. Repeat Customers should equal repeat_customers.
--
-- 8. Customer monetary values are calculated
--    from order-level payment totals.
--
-- 9. The segmentation thresholds are exploratory.
--    A large Other Customers category limits
--    behavioural differentiation.
--
-- 10. SQL results should be verified before
--     refreshing the final Power BI dashboard.
--
-- ============================================================
-- END OF LESSON 11
-- ============================================================
