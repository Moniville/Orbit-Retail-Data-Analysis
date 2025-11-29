-- Creating the Database
CREATE DATABASE orbit_retail;


-- 1. Create the 'raw' schema (safe check)
CREATE SCHEMA IF NOT EXISTS raw;

-- 2. Create the staging table matching the ORIGINAL CSV's messy format
DROP TABLE IF EXISTS raw.retail_transactions_staging;

CREATE TABLE raw.retail_transactions_staging (
    row_id INTEGER,
    order_id VARCHAR(50),
    order_date_raw TEXT,         -- Back to TEXT for DD/MM/YYYY
    ship_date_raw TEXT,          -- Back to TEXT for DD/MM/YYYY
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code NUMERIC,         -- Back to NUMERIC for potential null/float values
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales NUMERIC(10, 4)
);

SELECT * FROM raw.retail_transactions_staging

-- 1. Create the 'analytics' schema (DE Best Practice)
CREATE SCHEMA IF NOT EXISTS analytics;

-- 2. Create the clean, transformed Fact Table (T in ELT)
-- This handles cleaning, data typing, and structuring for analysis.
DROP TABLE IF EXISTS analytics.fact_sales;

CREATE TABLE analytics.fact_sales AS
SELECT
    -- Keys and IDs
    t.row_id AS sales_key,
    t.order_id,
    t.customer_id,
    t.product_id,

    -- 💥 Transformation Logic 1: Cleaning Dates (The Payoff!)
    -- Converts the messy 'DD/MM/YYYY' text into a proper DATE type
    TO_DATE(t.order_date_raw, 'DD/MM/YYYY') AS order_date,
    TO_DATE(t.ship_date_raw, 'DD/MM/YYYY') AS ship_date,

    -- Categorical Dimensions
    t.ship_mode,
    t.segment,
    t.country,
    t.city,
    t.state,
    -- 💥 Transformation Logic 2: Handling Nulls
    -- Fills missing postal codes with a placeholder '99999' and casts to VARCHAR
    COALESCE(t.postal_code::text, '99999') AS postal_code,
    t.region,
    t.category,
    t.sub_category,

    -- Metrics
    t.product_name,
    t.sales
FROM
    raw.retail_transactions_staging t;

-- 3. Add a primary key (Good DE/DA practice for performance)
ALTER TABLE analytics.fact_sales ADD PRIMARY KEY (sales_key);

SELECT * FROM ANALYTICS.FACT_SALES


