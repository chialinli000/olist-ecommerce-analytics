
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 02_data_validation.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Assess the quality, completeness, and consistency of
-- the imported Olist e-commerce data before analysis.
--
-- DATASETS:
-- 1. olist_orders_dataset
-- 2. olist_customers_dataset
-- 3. olist_order_payments_dataset
--
-- VALIDATION OBJECTIVES:
-- 1. Check record counts and unique identifiers.
-- 2. Identify duplicate order IDs.
-- 3. Examine missing values in key fields.
-- 4. Review order status and date coverage.
-- 5. Check relationships between datasets.
-- 6. Validate payment records and amounts.
--
-- NOTE:
-- This script performs read-only validation.
-- It does not modify or delete any records.
--
-- PREREQUISITE:
-- Import the three datasets before running this script.
--
-- ============================================================


USE ecommerce_analysis;


-- ------------------------------------------------------------
-- PART 1: Dataset Record Counts
-- ------------------------------------------------------------
-- Business Question:
-- How many records are available in each dataset?
--
-- Purpose:
-- Confirm successful data import and understand the
-- size of each dataset.


-- 1.1 Total order records

SELECT
    COUNT(*) AS total_orders
FROM olist_orders_dataset;


-- 1.2 Total customer records

SELECT
    COUNT(*) AS total_customer_records
FROM olist_customers_dataset;


-- 1.3 Total payment records

SELECT
    COUNT(*) AS total_payment_records
FROM olist_order_payments_dataset;


-- ------------------------------------------------------------
-- PART 2: Order ID Uniqueness
-- ------------------------------------------------------------
-- Business Question:
-- Does each order_id uniquely identify one order?
--
-- Purpose:
-- Verify the primary analytical identifier in the
-- Orders dataset.


-- 2.1 Count distinct order IDs

SELECT
    COUNT(DISTINCT order_id) AS unique_orders
FROM olist_orders_dataset;


-- 2.2 Compare total records with distinct order IDs

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_or_null_rows
FROM olist_orders_dataset;


-- 2.3 Identify duplicated non-null order IDs
-- Expected result: No rows if order IDs are unique.

SELECT
    order_id,
    COUNT(*) AS occurrence_count
FROM olist_orders_dataset
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, order_id;


-- ------------------------------------------------------------
-- PART 3: Missing Value Checks
-- ------------------------------------------------------------
-- Business Question:
-- Are important identifiers or dates missing?
--
-- Purpose:
-- Identify incomplete records that may affect
-- joins, date analysis, and KPI calculations.


-- 3.1 Missing values in the Orders dataset
-- NULL and blank strings are both checked.

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_id IS NULL
                 OR TRIM(order_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_order_id,

    SUM(
        CASE
            WHEN customer_id IS NULL
                 OR TRIM(customer_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer_id,

    SUM(
        CASE
            WHEN order_status IS NULL
                 OR TRIM(order_status) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_order_status,

    SUM(
        CASE
            WHEN order_purchase_timestamp IS NULL
                 OR TRIM(CAST(
                     order_purchase_timestamp AS CHAR
                 )) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_purchase_timestamp

FROM olist_orders_dataset;


-- 3.2 Missing customer identifiers

SELECT
    COUNT(*) AS total_customer_records,

    SUM(
        CASE
            WHEN customer_id IS NULL
                 OR TRIM(customer_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer_id,

    SUM(
        CASE
            WHEN customer_unique_id IS NULL
                 OR TRIM(customer_unique_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_customer_unique_id

FROM olist_customers_dataset;


-- 3.3 Missing payment information

SELECT
    COUNT(*) AS total_payment_records,

    SUM(
        CASE
            WHEN order_id IS NULL
                 OR TRIM(order_id) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_order_id,

    SUM(
        CASE
            WHEN payment_type IS NULL
                 OR TRIM(payment_type) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_payment_type,

    SUM(
        CASE
            WHEN payment_value IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_payment_value

FROM olist_order_payments_dataset;


-- ------------------------------------------------------------
-- PART 4: Order Status Distribution
-- ------------------------------------------------------------
-- Business Question:
-- What is the distribution of order statuses?
--
-- Purpose:
-- Understand the operational status categories
-- before calculating delivered and canceled KPIs.


SELECT
    order_status,
    COUNT(*) AS order_count,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(*)
             FROM olist_orders_dataset),
            0
        ),
        2
    ) AS percentage_of_orders

FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- PART 5: Purchase Date Coverage
-- ------------------------------------------------------------
-- Business Question:
-- What time period does the dataset cover?
--
-- Purpose:
-- Identify the historical observation period
-- and support appropriate date filtering.


-- 5.1 Earliest and latest purchase timestamps

SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM olist_orders_dataset;


-- 5.2 Orders placed by year

SELECT
    YEAR(order_purchase_timestamp) AS order_year,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;


-- ------------------------------------------------------------
-- PART 6: Referential Integrity Checks
-- ------------------------------------------------------------
-- Business Question:
-- Can orders be matched to customer and payment data?
--
-- Purpose:
-- Detect missing relationships that could lead to
-- excluded records during INNER JOIN operations.


-- 6.1 Orders without a matching customer record

SELECT
    COUNT(*) AS orders_without_customer_match
FROM olist_orders_dataset AS o
LEFT JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 6.2 Orders without a matching payment record
-- NOT EXISTS avoids duplicate counting from payments.

SELECT
    COUNT(*) AS orders_without_payment
FROM olist_orders_dataset AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM olist_order_payments_dataset AS p
    WHERE p.order_id = o.order_id
);


-- 6.3 Customer IDs duplicated in the Customers table
-- Expected result: No rows if customer_id is unique.

SELECT
    customer_id,
    COUNT(*) AS occurrence_count
FROM olist_customers_dataset
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC, customer_id;


-- ------------------------------------------------------------
-- PART 7: Payment Data Validation
-- ------------------------------------------------------------
-- Business Question:
-- Are payment records complete and consistent?
--
-- Purpose:
-- Check payment amounts and determine whether
-- multiple records exist for individual orders.


-- 7.1 Payment record summary

SELECT
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders_with_payments,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(MIN(payment_value), 2) AS min_payment_value,
    ROUND(MAX(payment_value), 2) AS max_payment_value
FROM olist_order_payments_dataset;


-- 7.2 Count orders with multiple payment records

SELECT
    COUNT(*) AS orders_with_multiple_payments
FROM (
    SELECT
        order_id
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS multiple_payments;


-- 7.3 Identify negative payment values

SELECT
    COUNT(*) AS negative_payment_records
FROM olist_order_payments_dataset
WHERE payment_value < 0;


-- 7.4 Identify payment records without matching orders

SELECT
    COUNT(*) AS payments_without_order_match
FROM olist_order_payments_dataset AS p
LEFT JOIN olist_orders_dataset AS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- VALIDATION NOTES
-- ============================================================
--
-- 1. Order IDs should be unique in the Orders dataset.
--
-- 2. Multiple payment records per order can be valid.
--    They must be aggregated to order level when
--    calculating Average Order Value.
--
-- 3. Missing customer or payment relationships can
--    affect the number of records included in JOINs.
--
-- 4. Missing delivery dates may be expected for
--    canceled or incomplete orders and should not
--    automatically be treated as data errors.
--
-- 5. Validation results should be reviewed before
--    drawing conclusions from the dataset.
--
-- ============================================================
-- END OF LESSON 02
-- ============================================================