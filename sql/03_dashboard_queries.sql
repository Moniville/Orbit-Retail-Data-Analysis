-- ANALYTICS QUERY A: Top 3 Selling Products by Region (ROW_NUMBER())

WITH RegionalProductSales AS (
    -- 1. Calculate Total Sales for each Product within its Region and Category
    SELECT
        EXTRACT(YEAR FROM order_date) AS order_year,
        region,
        category,
        product_name,
        ROUND(SUM(sales), 2) AS total_sales
    FROM
        analytics.fact_sales
    WHERE
        -- Dynamically filter for the latest year in the data (e.g., 2018)
        EXTRACT(YEAR FROM order_date) = (SELECT MAX(EXTRACT(YEAR FROM order_date)) FROM analytics.fact_sales)
    GROUP BY
        1, 2, 3, 4
),
RankedProducts AS (
    -- 2. Rank the products within each Region-Category partition by total sales
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY region, category
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM
        RegionalProductSales
)
-- 3. Select only the top 3 ranked products
SELECT
    order_year,
    region,
    category,
    product_name,
    total_sales
FROM
    RankedProducts
WHERE
    sales_rank <= 3
ORDER BY
    region, category, sales_rank;



-- (1). Proactive Operations (Anomaly): Which specific Orders and Products are currently flagged as high or low sales anomalies, and how much did they deviate from the expected 30-day regional trend?
SELECT
    order_date,
    order_id,
    region,
    category,
    product_name,
    sales,
    avg_sales_30d,
    anomaly_flag
FROM
    analytics.sales_anomalies
ORDER BY
    order_date DESC, sales DESC
LIMIT 15;


-- (2). Regional Performance: How do our four Regions (East, West, Central, South) rank against each other in overall revenue, and which Customer Segments (Consumer, Corporate, Home Office) are driving the most value?
SELECT
    region,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    --  Used CASE statement to identify the aggregation level, as GROUPING_ID is unsupported in PostgreSQL.
    CASE
        WHEN region IS NULL AND segment IS NULL THEN 'Grand Total'
        WHEN region IS NULL THEN 'Total by Segment'
        WHEN segment IS NULL THEN 'Total by Region'
        ELSE 'Detail'
    END AS aggregation_level
FROM
    analytics.fact_sales
GROUP BY GROUPING SETS (
    (region, segment), -- Level 1: Sales by Region and Segment (Detail)
    (region),          -- Level 2: Sales by Region Subtotal
    (segment),         -- Level 3: Sales by Segment Subtotal
    ()                 -- Level 4: Overall Total Sales (Grand Total)
)
ORDER BY
    region NULLS FIRST, segment NULLS FIRST;


-- (3). Product Strategy (Ranking): What were the Top 3 highest-selling products within each product Category and Region in the last year, providing guidance for inventory and marketing strategy?
WITH RegionalProductSales AS (
    -- 1. Calculate Total Sales for each Product within its Region and Category
    SELECT
        EXTRACT(YEAR FROM order_date) AS order_year,
        region,
        category,
        product_name,
        ROUND(SUM(sales), 2) AS total_sales
    FROM
        analytics.fact_sales
    WHERE
        -- Dynamically filter for the latest year in the data (e.g., 2018)
        EXTRACT(YEAR FROM order_date) = (SELECT MAX(EXTRACT(YEAR FROM order_date)) FROM analytics.fact_sales)
    GROUP BY
        1, 2, 3, 4
),
RankedProducts AS (
    -- 2. Rank the products within each Region-Category partition by total sales
    SELECT
        *,
        -- ROW_NUMBER() creates the rank reset for every unique combination of Region and Category
        ROW_NUMBER() OVER (
            PARTITION BY region, category
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM
        RegionalProductSales
)
-- 3. Select only the top 3 ranked products
SELECT
    order_year,
    region,
    category,
    product_name,
    total_sales
FROM
    RankedProducts
WHERE
    sales_rank <= 3
ORDER BY
    region, category, sales_rank;




-- (4). Logistics Efficiency: Is there a measurable difference in the average Sales value or the Order-to-Ship Time across the various Ship Modes (e.g., 'Same Day' vs. 'Standard Class'), indicating potential logistics inefficiencies?
SELECT
    ship_mode,
    ROUND(AVG(sales), 2) AS avg_sales_value,
    -- Calculate the average time in days from order to shipment
    ROUND(AVG(ship_date - order_date), 2) AS avg_order_to_ship_days
FROM
    analytics.fact_sales
GROUP BY
    ship_mode
ORDER BY
    avg_order_to_ship_days;




-- (5). Demand & Trend Analysis: What is the overall Month-over-Month (MoM) sales growth trend?
WITH MonthlySales AS (
    -- 1. Aggregate total sales by year and month
    SELECT
        DATE_TRUNC('month', order_date)::date AS sales_month,
        ROUND(SUM(sales), 2) AS current_month_sales
    FROM
        analytics.fact_sales
    GROUP BY
        1
    ORDER BY
        1
),
LaggedSales AS (
    -- 2. Use the LAG Window Function to fetch the previous month's sales
    -- This is crucial for calculating the difference between two rows (months)
    SELECT
        sales_month,
        current_month_sales,
        LAG(current_month_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM
        MonthlySales
)
-- 3. Calculate the Month-over-Month (MoM) Growth Rate
SELECT
    sales_month,
    current_month_sales,
    previous_month_sales,
    -- Formula: ((Current - Previous) / Previous) * 100
    ROUND(((current_month_sales - previous_month_sales) / previous_month_sales) * 100, 2) AS mom_growth_percent
FROM
    LaggedSales
ORDER BY
    sales_month DESC;



-- (4). Logistics Efficiency (business friendly): Average Order-to-Ship Time in Days, Hours, and Minutes.
SELECT
    ship_mode,
    ROUND(AVG(sales), 2) AS avg_sales_value,
    
    -- Use the successful decimal days calculation as the basis
    ROUND(AVG(ship_date - order_date), 2) AS avg_days_decimal,

    -- 1. Calculate DAYS (Use FLOOR on the decimal days)
    FLOOR(AVG(ship_date - order_date))::int AS avg_days,
    
    -- 2. Calculate HOURS (Isolate the fraction, multiply by 24, then FLOOR)
    FLOOR((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24)::int AS avg_hours,
    
    -- 3. Calculate MINUTES (Isolate the remaining fraction of the hour, multiply by 60, then ROUND)
    ROUND((((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24) - FLOOR((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24)) * 60)::int AS avg_minutes,
    
    -- 4. Concatenate into a final, non-technical string
    CONCAT(
        FLOOR(AVG(ship_date - order_date))::int, 'd ',
        FLOOR((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24)::int, 'h ',
        ROUND((((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24) - FLOOR((AVG(ship_date - order_date) - FLOOR(AVG(ship_date - order_date))) * 24)) * 60)::int, 'm'
    ) AS business_friendly_shipping_time
    
FROM
    analytics.fact_sales
GROUP BY
    ship_mode
ORDER BY
    AVG(ship_date - order_date);


-- Retrieve the top 15 most recent anomalies to showcase the Anomaly Detection System
SELECT
    order_date,
    order_id,
    region,
    category,
    product_name,
    sales,
    avg_sales_30d,
    anomaly_flag
FROM
    analytics.sales_anomalies
ORDER BY
    order_date DESC, sales DESC
LIMIT 15;