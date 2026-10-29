
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 03_basic_sql_queries.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Explore the Orders dataset using fundamental SQL
-- techniques to understand its structure, order statuses,
-- purchase dates, and data completeness.
--
-- SQL TECHNIQUES:
-- 1. SELECT, FROM, and LIMIT
-- 2. DISTINCT
-- 3. WHERE and comparison operators
-- 4. AND, OR, and IN
-- 5. Date range filtering
-- 6. NULL and blank value checks
-- 7. ORDER BY
--
-- DATASET:
-- olist_orders_dataset
--
-- NOTE:
-- All queries are read-only and do not modify data.
--
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Basic Data Exploration
-- ------------------------------------------------------------
-- Business Question:
-- What information is available in the Orders dataset?
--
-- Purpose:
-- Preview the dataset and identify relevant columns.


-- 1.1 Preview the first 10 records

SELECT
    *
FROM olist_orders_dataset
LIMIT 10;


-- 1.2 Select specific columns
-- Display the order identifier and operational status.

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
LIMIT 10;


-- ------------------------------------------------------------
-- PART 2: Explore Unique Order Statuses
-- ------------------------------------------------------------
-- Business Question:
-- What types of order statuses exist in the dataset?
--
-- Purpose:
-- Identify distinct operational categories before
-- conducting order performance analysis.


SELECT DISTINCT
    order_status
FROM olist_orders_dataset
ORDER BY order_status;


-- ------------------------------------------------------------
-- PART 3: Filter Orders by Status
-- ------------------------------------------------------------
-- Business Question:
-- Which orders were delivered or canceled?
--
-- Purpose:
-- Use WHERE to retrieve records meeting specific
-- operational conditions.


-- 3.1 Identify delivered orders

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
WHERE order_status = 'delivered'
LIMIT 10;


-- 3.2 Identify canceled orders

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
WHERE order_status = 'canceled'
LIMIT 10;


-- 3.3 Identify orders that were not delivered
-- The <> operator means "not equal to".
-- NULL statuses are not included by this condition.

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
WHERE order_status <> 'delivered'
LIMIT 10;


-- ------------------------------------------------------------
-- PART 4: Multiple Filtering Conditions
-- ------------------------------------------------------------
-- Business Question:
-- How can we combine conditions to find specific orders?
--
-- Purpose:
-- Apply AND, OR, and IN to filter multiple conditions.


-- 4.1 AND: Delivered orders placed from January 2018

SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_purchase_timestamp >= '2018-01-01'
ORDER BY order_purchase_timestamp
LIMIT 10;


-- 4.2 OR: Orders that were canceled or unavailable

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
WHERE order_status = 'canceled'
   OR order_status = 'unavailable'
LIMIT 10;


-- 4.3 IN: A shorter alternative to multiple OR conditions

SELECT
    order_id,
    order_status
FROM olist_orders_dataset
WHERE order_status IN ('canceled', 'unavailable')
LIMIT 10;


-- ------------------------------------------------------------
-- PART 5: Date Range Filtering
-- ------------------------------------------------------------
-- Business Question:
-- Which orders were placed during January 2018?
--
-- Purpose:
-- Select orders within a specific reporting period.
--
-- METHOD:
-- Use an inclusive start date and exclusive end date.
-- This includes every timestamp during January 2018,
-- including orders placed on 31 January.


SELECT
    order_id,
    order_purchase_timestamp
FROM olist_orders_dataset
WHERE order_purchase_timestamp >= '2018-01-01'
  AND order_purchase_timestamp < '2018-02-01'
ORDER BY order_purchase_timestamp
LIMIT 10;


-- ------------------------------------------------------------
-- PART 6: Missing Delivery Date Checks
-- ------------------------------------------------------------
-- Business Question:
-- Which orders do not have a recorded delivery date?
--
-- Purpose:
-- Identify missing delivery information that may
-- require further investigation.
--
-- NOTE:
-- Missing delivery dates can be expected for canceled
-- or incomplete orders and are not necessarily errors.


-- 6.1 Identify NULL delivery dates

SELECT
    order_id,
    order_status,
    order_delivered_customer_date
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL
LIMIT 10;


-- 6.2 Identify NULL or blank delivery dates
-- CAST makes this check applicable to text or
-- date/datetime columns in MySQL.

SELECT
    order_id,
    order_status,
    order_delivered_customer_date
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL
   OR TRIM(
       CAST(order_delivered_customer_date AS CHAR)
   ) = ''
LIMIT 10;


-- ------------------------------------------------------------
-- PART 7: Sort Orders by Purchase Date
-- ------------------------------------------------------------
-- Business Question:
-- What are the earliest and latest orders in the dataset?
--
-- Purpose:
-- Use ORDER BY to explore chronological records.


-- 7.1 Earliest orders (ascending order)

SELECT
    order_id,
    order_purchase_timestamp
FROM olist_orders_dataset
ORDER BY order_purchase_timestamp ASC, order_id ASC
LIMIT 10;


-- 7.2 Latest orders (descending order)

SELECT
    order_id,
    order_purchase_timestamp
FROM olist_orders_dataset
ORDER BY order_purchase_timestamp DESC, order_id DESC
LIMIT 10;


-- 7.3 Most recently placed canceled orders
-- Combine WHERE, ORDER BY, and LIMIT.

SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM olist_orders_dataset
WHERE order_status = 'canceled'
ORDER BY order_purchase_timestamp DESC, order_id DESC
LIMIT 10;


-- ------------------------------------------------------------
-- PART 8: Integrated SQL Query
-- ------------------------------------------------------------
-- Business Question:
-- What are the latest canceled or unavailable orders?
--
-- Purpose:
-- Combine SELECT, FROM, WHERE, IN, ORDER BY, and LIMIT
-- in a single query.


SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM olist_orders_dataset
WHERE order_status IN ('canceled', 'unavailable')
ORDER BY order_purchase_timestamp DESC, order_id DESC
LIMIT 20;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
--
-- 1. SELECT retrieves the required columns.
--
-- 2. DISTINCT identifies unique values.
--
-- 3. WHERE filters records based on business conditions.
--
-- 4. AND, OR, and IN support more complex filtering.
--
-- 5. Half-open date ranges avoid excluding timestamps
--    at the end of the reporting period.
--
-- 6. NULL checks help identify missing information.
--
-- 7. ORDER BY and LIMIT help retrieve relevant records
--    in a controlled and readable format.
--
-- 8. These queries establish the foundation for
--    aggregation, KPI analysis, and time-series analysis
--    in subsequent project files.
--
-- ============================================================
-- END OF LESSON 03
-- ============================================================
