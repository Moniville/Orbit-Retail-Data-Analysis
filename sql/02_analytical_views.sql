-- Creating an Anomaly Detection Materialized View

-- Note: This pre-calculates the complex rolling average for fast BI dashboards.
DROP MATERIALIZED VIEW IF EXISTS analytics.sales_anomalies;

CREATE MATERIALIZED VIEW analytics.sales_anomalies AS
WITH sales_analysis AS (
    SELECT
        order_date,
        order_id,
        sales,
        region,
        category,
        product_name,
        -- Window Function: Calculates the 30-day rolling average sales for this specific Region and Category
        AVG(sales) OVER (
            PARTITION BY region, category
            ORDER BY order_date
            ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
        ) AS avg_sales_30d
    FROM
        analytics.fact_sales
)
SELECT
    order_date,
    order_id,
    region,
    category,
    product_name,
    sales,
    ROUND(avg_sales_30d, 2) AS avg_sales_30d,
    -- Flag the record based on the anomaly threshold
    CASE
        WHEN sales > 1.5 * avg_sales_30d THEN 'High Sales Anomaly (Spike)'
        WHEN sales < 0.5 * avg_sales_30d THEN 'Low Sales Anomaly (Drop)'
        ELSE 'Normal'
    END AS anomaly_flag
FROM
    sales_analysis
WHERE
    -- Only return the records that meet the anomaly criteria
    sales > 1.5 * avg_sales_30d OR sales < 0.5 * avg_sales_30d
ORDER BY
    order_date DESC, sales DESC;

-- You would run this command periodically to update the view with new data:
-- REFRESH MATERIALIZED VIEW analytics.sales_anomalies;

SELECT * FROM analytics.sales_anomalies;