
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 05_date_trend_analysis.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Analyse historical order trends, monthly growth,
-- and cancellation rates using the Olist Orders dataset.
--
-- BUSINESS QUESTIONS:
-- 1. How did order volume change over time?
-- 2. Which months recorded the highest order volumes?
-- 3. How did orders grow or decline month over month?
-- 4. How did cancellation rates vary across months?
--
-- SQL TECHNIQUES:
-- YEAR, MONTH, DATE_FORMAT, COUNT, SUM, CASE WHEN,
-- GROUP BY, CTEs, LAG, ROUND, and NULLIF.
--
-- DATASET:
-- olist_orders_dataset
--
-- REPORTING PERIOD:
-- 2017-01-01 (inclusive) to 2018-09-01 (exclusive).
--
-- This represents January 2017 through August 2018.
--
-- The monthly reporting period matches the trend
-- analysis in Dashboard Page 1.
--
-- IMPORTANT:
-- Monthly order counts include all order statuses.
-- Overall dashboard KPIs use the full dataset.
-- These two reporting scopes should not be confused.
--
-- NOTE:
-- All queries are read-only.
--
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Verify the Purchase Date Field
-- ------------------------------------------------------------
-- Business Question:
-- What data type is used for purchase timestamps?
--
-- Purpose:
-- Inspect the column definition before performing
-- time-based calculations and filtering.


SHOW COLUMNS FROM olist_orders_dataset
LIKE 'order_purchase_timestamp';


-- ------------------------------------------------------------
-- PART 2: Annual Order Volume
-- ------------------------------------------------------------
-- Business Question:
-- How many orders were placed in each calendar year?
--
-- Purpose:
-- Provide a high-level overview of the historical
-- distribution of orders.
--
-- NOTE:
-- This query covers the full dataset.
-- Some years may have incomplete coverage.


SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


-- ------------------------------------------------------------
-- PART 3: Monthly Order Volume in 2018
-- ------------------------------------------------------------
-- Business Question:
-- How many orders were placed in each month of 2018?
--
-- Purpose:
-- Demonstrate monthly aggregation within one year.
--
-- NOTE:
-- Months without records will not appear.


SELECT
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp < '2019-01-01'
GROUP BY MONTH(order_purchase_timestamp)
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 4: Historical Monthly Order Trend
-- ------------------------------------------------------------
-- Business Question:
-- How did monthly order volume change over time?
--
-- Purpose:
-- Aggregate order counts by year and month.
--
-- DATE_FORMAT('%Y-%m') produces sortable labels
-- such as 2017-01, 2017-02, and 2018-08.
--
-- This query explores the full dataset.


SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(
    order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 5: Dashboard Reporting Period
-- ------------------------------------------------------------
-- Business Question:
-- What was the monthly order volume from January 2017
-- to August 2018?
--
-- Purpose:
-- Produce the monthly order series used in
-- Dashboard Page 1: Sales & Operations Overview.
--
-- Reporting window:
-- >= 2017-01-01 and < 2018-09-01.
--
-- This avoids including September 2018, which has
-- incomplete coverage in the historical dataset.


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
ORDER BY order_month;


-- ------------------------------------------------------------
-- PART 6: Compare Annual Order Volumes
-- ------------------------------------------------------------
-- Business Question:
-- How many orders were placed in 2017 and 2018?
--
-- Purpose:
-- Demonstrate conditional aggregation using CASE.
--
-- IMPORTANT:
-- This query compares calendar-year totals
-- available in the dataset.
--
-- Because 2018 coverage is incomplete, the results
-- should not be interpreted as a like-for-like
-- annual growth comparison.


SELECT
    SUM(
        CASE
            WHEN YEAR(order_purchase_timestamp) = 2017
            THEN 1 ELSE 0
        END
    ) AS orders_2017,

    SUM(
        CASE
            WHEN YEAR(order_purchase_timestamp) = 2018
            THEN 1 ELSE 0
        END
    ) AS orders_2018

FROM olist_orders_dataset;


-- ------------------------------------------------------------
-- PART 7: Month-over-Month Order Growth
-- ------------------------------------------------------------
-- Business Question:
-- By what percentage did monthly order volume increase
-- or decrease compared with the previous month?
--
-- Purpose:
-- Use LAG to compare each month with its predecessor.
--
-- FORMULA:
-- MoM Growth (%) =
-- (Current Month Orders - Previous Month Orders)
-- / Previous Month Orders * 100
--
-- NOTE:
-- The first month has no previous observation.
-- Its MoM growth value will therefore be NULL.
--
-- NULLIF prevents division by zero.
-- Missing months are not automatically generated.
-- LAG compares adjacent rows in the monthly result.


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
-- PART 8: Monthly Cancellation Rate
-- ------------------------------------------------------------
-- Business Question:
-- How did order cancellation rates change over time?
--
-- Purpose:
-- Track canceled orders and cancellation rates by
-- purchase month.
--
-- KPI DEFINITION:
-- Cancellation Rate (%) =
-- Canceled Orders / Total Orders * 100
--
-- Numerator:
-- Orders with order_status = 'canceled'.
--
-- Denominator:
-- All orders placed in the corresponding month.
--
-- This matches the KPI calculation methodology
-- in Lessons 04 and 11.


SELECT
    DATE_FORMAT(
        order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'canceled'
            THEN 1 ELSE 0
        END
    ) AS canceled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_status = 'canceled'
                THEN 1 ELSE 0
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
-- PART 9: Highest-Volume Months
-- ------------------------------------------------------------
-- Business Question:
-- Which months recorded the highest order volume
-- during the dashboard reporting period?
--
-- Purpose:
-- Identify periods of elevated order activity.
--
-- This query uses the same reporting window as
-- the Power BI monthly trend chart.


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
ORDER BY total_orders DESC, order_month ASC
LIMIT 3;


-- ------------------------------------------------------------
-- PART 10: Compare May 2017 and May 2018
-- ------------------------------------------------------------
-- Business Question:
-- How did May order volume compare across the two years?
--
-- Purpose:
-- Compare the same calendar month across years,
-- reducing the impact of seasonal differences.
--
-- NOTE:
-- This is a descriptive comparison, not a
-- seasonality-adjusted statistical analysis.


SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp >= '2017-05-01'
  AND order_purchase_timestamp < '2018-06-01'
  AND MONTH(order_purchase_timestamp) = 5
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. YEAR and MONTH extract calendar information
--    from purchase timestamps.
--
-- 2. DATE_FORMAT enables monthly aggregation and
--    chronological reporting.
--
-- 3. Consistent reporting periods are essential
--    for comparing SQL outputs with dashboards.
--
-- 4. CTEs make multi-step time-series queries
--    easier to understand and maintain.
--
-- 5. LAG retrieves the previous month's value
--    without requiring a self-join.
--
-- 6. NULLIF avoids division-by-zero errors
--    when calculating percentage growth.
--
-- 7. Monthly cancellation rates use the same
--    numerator and denominator definitions
--    as the operational KPI analysis.
--
-- 8. Partial-year data should not be presented
--    as a complete annual growth comparison.
--
-- 9. The monthly order trend is aligned with
--    the reporting scope of Dashboard Page 1.
--
-- ============================================================
-- END OF LESSON 05
-- ============================================================
