
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 04_business_kpi_analysis.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Analyse order performance using SQL aggregation
-- functions and calculate operational business KPIs.
--
-- BUSINESS QUESTIONS:
-- 1. How many orders are recorded in the dataset?
-- 2. What is the historical order date range?
-- 3. How are orders distributed across statuses?
-- 4. How many orders were delivered or canceled?
-- 5. What percentage of orders were canceled?
--
-- SQL TECHNIQUES:
-- COUNT, MIN, MAX, GROUP BY, SUM, CASE WHEN,
-- ROUND, AVG, HAVING, and NULLIF.
--
-- DATASET:
-- olist_orders_dataset
--
-- KPI DEFINITIONS:
-- Total Orders = All records in the Orders dataset.
-- Delivered Orders = Orders with status 'delivered'.
-- Canceled Orders = Orders with status 'canceled'.
-- Cancellation Rate (%) =
--     Canceled Orders / Total Orders * 100.
--
-- REPORTING SCOPE:
-- The overall KPIs cover the full Orders dataset.
-- They are not restricted to the monthly reporting
-- period used in the Power BI trend chart.
--
-- NOTE:
-- This script is read-only and does not modify data.
--
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Basic Aggregation Functions
-- ------------------------------------------------------------
-- Business Question:
-- How many orders are available, and what is the
-- historical date range of the dataset?


-- 1.1 Count total orders

SELECT
    COUNT(*) AS total_orders
FROM olist_orders_dataset;


-- 1.2 Identify the earliest and latest purchase dates

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM olist_orders_dataset;


-- ------------------------------------------------------------
-- PART 2: Order Status Distribution
-- ------------------------------------------------------------
-- Business Question:
-- How are orders distributed across operational statuses?
--
-- Purpose:
-- Understand the relative size of each status category
-- before calculating operational KPIs.


SELECT
    order_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- PART 3: Canceled Order Count
-- ------------------------------------------------------------
-- Business Question:
-- How many orders were canceled?
--
-- Definition:
-- Count only orders where order_status = 'canceled'.
-- Other statuses such as 'unavailable' are excluded.


SELECT
    COUNT(*) AS canceled_orders
FROM olist_orders_dataset
WHERE order_status = 'canceled';


-- ------------------------------------------------------------
-- PART 4: Conditional Aggregation
-- ------------------------------------------------------------
-- Business Question:
-- How many total, delivered, and canceled orders
-- are recorded in the dataset?
--
-- Purpose:
-- Use SUM and CASE WHEN to calculate multiple KPIs
-- in a single query.


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
    ) AS canceled_orders

FROM olist_orders_dataset;


-- ------------------------------------------------------------
-- PART 5: Cancellation Rate KPI
-- ------------------------------------------------------------
-- Business Question:
-- What percentage of all orders were canceled?
--
-- Formula:
-- Cancellation Rate (%) =
--     Canceled Orders / Total Orders * 100
--
-- Example:
-- 625 / 99,441 * 100 = approximately 0.63%.
--
-- IMPORTANT:
-- The SQL result is already multiplied by 100.
-- A result of 0.63 represents 0.63%, not 63%.
--
-- This definition matches the Executive KPI
-- calculation in 11_dashboard_data.sql.


SELECT
    COUNT(*) AS total_orders,

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
-- PART 6: Filtering Aggregated Results with HAVING
-- ------------------------------------------------------------
-- Business Question:
-- Which order statuses contain more than 100 orders?
--
-- Purpose:
-- Use HAVING to filter results after GROUP BY.
--
-- WHERE filters individual rows before aggregation.
-- HAVING filters aggregated groups.


SELECT
    order_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY order_status
HAVING COUNT(*) > 100
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- PART 7: Average Delivered Order Indicator
-- ------------------------------------------------------------
-- Business Question:
-- What proportion of all orders were delivered?
--
-- Purpose:
-- Demonstrate AVG with a conditional expression.
--
-- Delivered orders are assigned 1.
-- All other order statuses are assigned 0.
--
-- The average therefore represents the proportion
-- of records with status 'delivered'.
--
-- NOTE:
-- This query returns a proportion between 0 and 1,
-- not a percentage between 0 and 100.


SELECT
    ROUND(
        AVG(
            CASE
                WHEN order_status = 'delivered' THEN 1.0
                ELSE 0.0
            END
        ),
        4
    ) AS delivered_order_ratio

FROM olist_orders_dataset;


-- ------------------------------------------------------------
-- PART 8: Additional Operational KPI
-- ------------------------------------------------------------
-- Business Question:
-- How many orders were canceled or marked unavailable?
--
-- Purpose:
-- Distinguish the cancellation KPI from a broader
-- measure of orders with unsuccessful statuses.
--
-- IMPORTANT:
-- The resulting count is NOT the cancellation count
-- used in the Power BI dashboard.


SELECT
    COUNT(*) AS canceled_or_unavailable_orders
FROM olist_orders_dataset
WHERE order_status IN ('canceled', 'unavailable');


-- ------------------------------------------------------------
-- PART 9: Executive KPI Summary
-- ------------------------------------------------------------
-- Business Question:
-- What are the core order performance metrics?
--
-- Purpose:
-- Consolidate the four operational KPIs used in
-- Dashboard Page 1: Sales & Operations Overview.
--
-- OUTPUT COLUMNS:
-- total_orders
-- delivered_orders
-- canceled_orders
-- cancellation_rate_pct
--
-- This query uses the same KPI definitions
-- and calculation logic as Lesson 11.


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


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. COUNT calculates the number of records.
--
-- 2. MIN and MAX identify the historical date range.
--
-- 3. GROUP BY summarises orders by operational status.
--
-- 4. SUM with CASE WHEN supports conditional KPIs.
--
-- 5. NULLIF prevents division by zero.
--
-- 6. HAVING filters aggregated results.
--
-- 7. AVG can calculate proportions using binary
--    conditional expressions.
--
-- 8. The cancellation rate includes only canceled
--    orders in the numerator and all orders in
--    the denominator.
--
-- 9. The final KPI summary is consistent with
--    Dashboard Page 1 in Lesson 11.
--
-- ============================================================
-- END OF LESSON 04
-- ============================================================
