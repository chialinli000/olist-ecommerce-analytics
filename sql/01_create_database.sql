
-- ============================================================
-- PROJECT: Olist E-commerce Analytics
-- FILE: 01_create_database.sql
-- DATABASE: ecommerce_analysis
-- TOOL: MySQL 8.0
-- ============================================================
--
-- PURPOSE:
-- Set up the database environment for analysing the
-- Olist Brazilian E-Commerce Dataset.
--
-- PROJECT OBJECTIVES:
-- 1. Analyse order and operational performance.
-- 2. Explore customer payment behaviour.
-- 3. Evaluate customer purchasing patterns.
-- 4. Develop rule-based RFM customer segmentation.
-- 5. Prepare analytical outputs for Power BI dashboards.
--
-- ============================================================


-- ------------------------------------------------------------
-- STEP 1: Create the database
-- ------------------------------------------------------------
-- Create the database only if it does not already exist.
-- This prevents an error when the script is executed again.

CREATE DATABASE IF NOT EXISTS ecommerce_analysis;


-- ------------------------------------------------------------
-- STEP 2: Select the database
-- ------------------------------------------------------------
-- Set ecommerce_analysis as the active database for
-- subsequent SQL queries.

USE ecommerce_analysis;


-- ------------------------------------------------------------
-- STEP 3: Verify database creation
-- ------------------------------------------------------------
-- Display all available databases to confirm that
-- ecommerce_analysis has been created successfully.

SHOW DATABASES;


-- ============================================================
-- END OF LESSON 01
-- ============================================================
