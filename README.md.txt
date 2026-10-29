# Olist E-commerce Analytics | SQL & Power BI

**An end-to-end business analytics portfolio project exploring e-commerce operations, payment behaviour, and customer segmentation using MySQL and Power BI.**

## 1. Project Overview

This project analyses the Brazilian E-Commerce Public Dataset by Olist, available on Kaggle, to explore operational performance, recorded payment values, customer purchasing behaviour, and RFM customer segmentation.

The project follows an end-to-end analytics workflow, from data validation and SQL-based analysis to Power BI dashboard development and business recommendations.

**Project Objectives**

- Evaluate order volume, delivery status, and cancellation performance.
- Analyse payment methods and recorded transaction values.
- Investigate customer purchasing frequency and repeat-purchase behaviour.
- Develop rule-based customer segments using Recency, Frequency, and Monetary (RFM) metrics.
- Communicate findings through interactive business dashboards.

## 2. Tools & Technical Skills

| Tool / Skill | Application |
|---|---|
| MySQL 8.0 | Data validation, filtering, aggregation, JOINs, subqueries, and CTEs |
| Advanced SQL | Window functions, ranking, running totals, and month-over-month growth |
| Power BI Desktop | KPI reporting, interactive dashboards, and business data visualisation |
| Customer Analytics | Repeat-purchase analysis, RFM metrics, and rule-based segmentation |
| Business Analytics | KPI definition, trend interpretation, data quality assessment, and recommendations |

## 3. Business Questions

This project addresses four core business questions:

1. How did monthly order volumes and cancellation rates change over time?
2. Which payment methods contributed the highest recorded payment value?
3. What proportion of customers placed repeat orders during the observation period?
4. How can customers be grouped based on Recency, Frequency, and Monetary Value?

## 4. Data Source & Scope

**Dataset:** Brazilian E-Commerce Public Dataset by Olist

**Data Provider:** Olist

**Platform:** Kaggle

**Original Dataset:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

**Dataset License:** CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike 4.0 International)

The dataset contains approximately 100,000 historical e-commerce orders placed in Brazil between 2016 and 2018, covering several dimensions of order activity and customer behaviour.

This project uses three primary source tables:

| Source Table | Description |
|---|---|
| `olist_orders_dataset` | Order identifiers, order status, and purchase timestamps |
| `olist_customers_dataset` | Customer identifiers and geographical information |
| `olist_order_payments_dataset` | Payment methods, payment amounts, and payment records |

### Reporting Scope

Different analyses use different populations and reporting periods.

| Analysis | Reporting Scope |
|---|---|
| Overall operational KPIs | All records in the Orders dataset |
| Monthly order performance | January 2017 – August 2018 |
| Payment method analysis | All available records in the Payments dataset |
| Customer behaviour and RFM | Delivered orders placed before 1 September 2018, with matching customer and payment records |

The original source files are not included in this repository. They can be obtained from the Kaggle dataset page.

The six aggregated CSV files in `dashboard_data/` are SQL-generated reporting outputs, rather than copies of the complete original source tables.

## 5. Analytical Workflow

The project follows five stages:

**Stage 1 — Data Validation**

Validated record counts, unique identifiers, missing values, and relationships between the Orders, Customers, and Payments datasets.

**Stage 2 — Operational Analysis**

Calculated order-level KPIs, evaluated cancellation rates, and analysed monthly order trends using SQL aggregation and window functions.

**Stage 3 — Payment Analysis**

Aggregated payment records by `order_id` to calculate order-level payment values, compare payment methods, and avoid incorrect order counts from one-to-many joins.

**Stage 4 — Customer Behaviour & RFM Segmentation**

Used `customer_unique_id` to calculate purchasing frequency, monetary value, and recency for eligible customers, followed by rule-based customer segmentation.

**Stage 5 — Dashboard Development**

Prepared six aggregated CSV outputs from MySQL and developed a two-page Power BI dashboard to communicate operational and customer insights.

## 6. Dashboard 1 — Sales & Operations Overview

![Sales and Operations Dashboard](images/sales_overview.png)

### Key Performance Indicators

| Metric | Result |
|---|---:|
| Total Orders | 99,441 |
| Delivered Orders | 96,478 |
| Canceled Orders | 625 |
| Cancellation Rate | 0.63% |

The overall KPI calculations use all records in the Orders dataset.

Cancellation Rate is calculated as:

**Canceled Orders / Total Orders × 100**

Only orders with the status `canceled` are included in the numerator.

### Key Findings

**1. Monthly order demand**

Monthly order volume reached 7,544 in November 2017, the highest month in the January 2017–August 2018 reporting window.

This suggests that demand varied considerably across months and highlights the importance of monitoring purchasing patterns when planning operational capacity.

**2. Order cancellation performance**

The overall cancellation rate was approximately 0.63%.

Cancellation rates can also be monitored monthly to identify periods requiring further operational investigation. A low overall percentage does not necessarily imply that individual high-volume months have identical cancellation performance.

**3. Payment method distribution**

Credit cards accounted for the highest recorded payment value among the available payment methods.

| Payment Method | Recorded Payment Value (BRL) |
|---|---:|
| Credit Card | 12,542,084.19 |
| Boleto | 2,869,361.27 |
| Voucher | 379,436.87 |
| Debit Card | 217,989.79 |
| Not Defined | 0.00 |

Payment values represent recorded payment amounts and should not be interpreted as platform net revenue or profit.

## 7. Dashboard 2 — Customer Behaviour & Segmentation

![Customer Analytics Dashboard](images/customer_analytics.png)

**Analysis Snapshot:** 1 September 2018

This dashboard analyses customers with delivered orders placed before the snapshot date and associated payment records.

### Customer KPIs

| Metric | Result |
|---|---:|
| Customers Analysed | 93,357 |
| One-time Customers | 90,556 |
| Repeat Customers | 2,801 |
| Repeat Purchase Rate | 3.00% |
| Average Customer Payment Value | BRL 165.20 |

A repeat customer is defined as a `customer_unique_id` with at least two eligible orders.

The Repeat Purchase Rate is calculated as:

**Repeat Customers / Total Customers × 100**

This measures historical repeat purchasing within the available observation window, rather than cohort-based retention.

### RFM Methodology

Customer segmentation is based on three purchasing behaviour metrics:

| Metric | Definition |
|---|---|
| Recency (R) | Days between 1 September 2018 and the customer's latest eligible purchase |
| Frequency (F) | Number of distinct eligible orders placed by the customer |
| Monetary (M) | Total recorded payment value associated with the customer's eligible orders |

Payment records were first aggregated at order level to avoid incorrectly multiplying order-level values.

### Customer Segmentation Rules

Five customer segments were created using predefined business rules.

| Customer Segment | Classification Rule |
|---|---|
| Champions | Recency ≤ 90 days, Frequency ≥ 2, Monetary ≥ BRL 200 |
| Loyal Customers | Recency ≤ 180 days, Frequency ≥ 2, excluding customers already classified as Champions |
| At Risk | Recency > 180 days, Frequency ≥ 2 |
| New / Occasional | Recency ≤ 90 days, Frequency = 1 |
| Other Customers | All remaining eligible customers |

The rules are applied in the stated order using SQL `CASE WHEN` logic.

### Segmentation Results

| Customer Segment | Customers | Share |
|---|---:|---:|
| Other Customers | 73,087 | 78.29% |
| New / Occasional | 17,469 | 18.71% |
| At Risk | 1,587 | 1.70% |
| Loyal Customers | 846 | 0.91% |
| Champions | 368 | 0.39% |
| **Total** | **93,357** | **100.00%** |

### Key Findings

**1. Limited observed repeat purchasing**

Approximately 3.00% of eligible customers placed two or more delivered orders during the available observation period.

This finding motivates further investigation into customer purchasing cycles, repeat-purchase opportunities, and the limitations of the historical observation window.

**2. A large general customer segment**

Approximately 78.3% of customers were classified as "Other Customers".

This indicates that the simplified RFM thresholds did not meaningfully differentiate a large proportion of the analysed customer population.

**3. Opportunities for further customer analysis**

Additional RFM scoring, cohort analysis, and behavioural features could help create more informative segments for future customer engagement strategies.

## 8. Business Recommendations

### Recommendation 1 — Investigate Repeat-Purchase Opportunities

The low observed repeat-purchase rate suggests that customer purchasing frequency deserves further investigation.

Potential next steps include:

- Conducting cohort analysis to compare customer behaviour across acquisition periods.
- Examining the time between first and subsequent purchases.
- Investigating product categories and purchasing patterns associated with repeat orders.
- Testing targeted post-purchase engagement strategies where appropriate.

These are proposed analytical and commercial next steps; they were not implemented or experimentally evaluated in this project.

### Recommendation 2 — Improve Operational Planning

Monthly order trends can help identify periods of increased order demand.

Further analysis could examine:

- Seasonal purchasing patterns.
- Order cancellations during higher-volume periods.
- Delivery performance and fulfilment capacity.
- Potential operational bottlenecks.

These findings could support more informed operational monitoring and resource planning.

### Recommendation 3 — Refine Customer Segmentation

The concentration of customers in the "Other Customers" segment highlights the need for more granular customer classification.

Potential improvements include:

- Percentile-based RFM scoring.
- Additional customer behavioural variables.
- Analysis of purchasing patterns within the "Other Customers" category.
- Evaluation of segment stability and future purchasing outcomes.

A refined segmentation framework could provide more actionable customer insights.

## 9. SQL Methodology & Data Quality

### Data Validation

Initial checks included:

- Dataset record counts.
- Distinct and duplicate identifiers.
- Missing values in key fields.
- Order status distributions.
- Purchase date coverage.
- Matching customer and payment records.
- Multiple payment records associated with the same order.

### JOIN and Data Granularity

The Orders, Customers, and Payments tables were connected using `customer_id` and `order_id`.

Because a single order can have multiple payment records, payment amounts were aggregated before performing order-level and customer-level analysis.

Example:

```sql
WITH order_payments AS (
    SELECT
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
```

This approach allows downstream analyses to work with one aggregated payment value per order, subject to the uniqueness of the other JOIN keys.

### Customer Identification

`customer_id` identifies the customer record associated with an order, whereas `customer_unique_id` identifies a customer across multiple orders.

The customer-level analysis therefore uses `customer_unique_id` to measure repeat purchasing and generate RFM metrics.

### Time-Series Analysis

Monthly order performance was analysed using `DATE_FORMAT()`, aggregation, and the `LAG()` window function.

Month-over-month growth was calculated as:

**(Current Month Orders − Previous Month Orders) / Previous Month Orders × 100**

The first reporting month does not have a preceding month within the selected analysis window.

## 10. Project Structure

```text
Olist_Ecommerce_Analytics_Portfolio/
|
|-- README.md
|
|-- sql/
|   |-- 01_create_database.sql
|   |-- 02_data_validation.sql
|   |-- 03_basic_sql_queries.sql
|   |-- 04_business_kpi_analysis.sql
|   |-- 05_date_trend_analysis.sql
|   |-- 06_sql_joins.sql
|   |-- 07_revenue_payment_analysis.sql
|   |-- 08_subqueries_cte.sql
|   |-- 09_window_functions.sql
|   |-- 10_customer_rfm_segmentation.sql
|   |-- 11_dashboard_data.sql
|
|-- dashboard_data/
|   |-- executive_kpis.csv
|   |-- monthly_performance.csv
|   |-- payment_methods.csv
|   |-- customer_kpis.csv
|   |-- customer_segments.csv
|   |-- customer_frequency.csv
|
|-- dashboard/
|   |-- Olist_Ecommerce_Dashboard.pbix
|
|-- images/
    |-- sales_overview.png
    |-- customer_analytics.png
```

### SQL File Descriptions

| SQL File | Main Purpose |
|---|---|
| 01 — Create Database | Set up the MySQL database environment |
| 02 — Data Validation | Examine data completeness, uniqueness, and table relationships |
| 03 — Basic SQL Queries | Explore orders using filtering, sorting, and conditional queries |
| 04 — Business KPI Analysis | Calculate operational KPIs and cancellation rates |
| 05 — Date & Trend Analysis | Analyse monthly order volume, growth, and cancellations |
| 06 — SQL JOINs | Combine related tables and examine data granularity |
| 07 — Payment Analysis | Analyse recorded payment values and payment-based AOV |
| 08 — Subqueries & CTEs | Perform multi-stage payment and regional analysis |
| 09 — Window Functions | Calculate rankings, running totals, and monthly growth |
| 10 — Customer RFM Segmentation | Calculate customer behaviour metrics and segment customers |
| 11 — Dashboard Data Preparation | Generate six aggregated datasets for Power BI |

### Dashboard Data Files

The `dashboard_data/` directory contains six aggregated reporting outputs generated from SQL queries.

These files support the Power BI dashboard and enable users to inspect the data behind the visualisations without processing the complete original dataset.

## 11. Reproducing the Analysis

To reproduce the analysis:

1. Download the original Olist dataset from Kaggle using the link in Section 4.
2. Install MySQL 8.0 and import the Orders, Customers, and Payments CSV files.
3. Run `01_create_database.sql` to create the database if it does not already exist. Ensure the source tables are imported before running the remaining scripts.
4. Run the SQL scripts in the `sql/` directory to explore and analyse the data.
5. Run `11_dashboard_data.sql` and export its six query results using the corresponding CSV filenames.
6. Open `dashboard/Olist_Ecommerce_Dashboard.pbix` in Power BI Desktop.
7. If necessary, update the Power BI CSV source paths to point to the downloaded `dashboard_data/` files.
8. Refresh the report and review the dashboard results.

**Note:** The SQL scripts assume that the original datasets have been imported under their corresponding table names in the `ecommerce_analysis` database. CSV import and column-type configuration may be required before executing the analytical scripts.

## 12. Limitations

**Historical observation period**

The dataset represents historical transactions from 2016–2018. Findings may not reflect contemporary e-commerce behaviour.

**Different reporting scopes**

Operational KPIs, monthly order trends, payment method analysis, and RFM customer analysis use different reporting populations. These differences are documented in the methodology.

**Payment value interpretation**

Recorded payment value does not necessarily equal recognised revenue, net revenue, or profit. The project does not model refunds, margins, or complete platform financial performance.

**Repeat-purchase analysis**

The repeat-purchase rate describes the proportion of eligible customers with at least two orders during the observed period. It is not a cohort-based retention measure.

**RFM segmentation**

The segmentation uses predefined illustrative thresholds rather than statistically optimised or validated cut-offs.

Approximately 78.3% of analysed customers fall into "Other Customers", limiting the ability of the current segmentation to differentiate customer behaviour.

**Business recommendations**

Recommendations are exploratory and have not been validated through business implementation, controlled experiments, or causal analysis.

## 13. Data Attribution & Usage

The underlying dataset was created and released by Olist and made available through Kaggle.

**Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

**License:** [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/)

This repository is intended as an educational, non-commercial analytics portfolio. The underlying data remains subject to the original dataset's licensing conditions.

The SQL analysis, reporting workflow, dashboard design, and written interpretation are presented as project work using the publicly available dataset.

## 14. Project Summary

This project demonstrates an end-to-end business analytics workflow using MySQL and Power BI, from validating transactional data to developing performance dashboards and customer segmentation.

The main learning outcomes include working with relational data, maintaining analytical granularity, defining consistent business KPIs, and communicating both findings and analytical limitations.

The project illustrates how SQL and data visualisation can support structured business investigation and inform further analysis.