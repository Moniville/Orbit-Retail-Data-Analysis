# Orbit Retail: End-to-End Sales Performance and Risk Analysis

## 🧑‍💻 Context & My Role: Analytics Engineer Intern
I joined **Orbit Retail**, a high-growth e-commerce startup specializing in the global distribution of office, furniture, and technology products. As the company scaled, they faced a critical challenge: their raw transactional data was **messy, slow to process, and led to reactive decision-making**. Specifically, errors like non-standard date formats (e.g., `DD/MM/YYYY`) and missing information were breaking reports, and a lack of real-time insights meant the team often missed catastrophic sales events until it was too late.

Working closely with the Lead Data Analyst, my core focus was to **bridge the gap between messy raw data and clean, reliable business intelligence reports.**

## 🎯 Project Objectives (The Deliverables)
This project was designed to establish data trust and platform performance through three core deliverables that align with the role of an Analytics Engineer:

| Objective Category | Deliverable | Technical Skill Demonstrated |
| :--- | :--- | :--- |
| **Data Trust & Structure (ELT)** | Design and implement a professional two-tier data architecture (`raw` $\rightarrow$ `analytics` schemas) in PostgreSQL to separate source data from final reports. | Schema Design, Data Modeling |
| **Optimize Report Performance (DE)** | Utilize **Materialized Views** to pre-calculate complex, slow-running queries (like the rolling 30-day average sales baseline). | Performance Tuning, Materialized Views |
| **Implement Proactive Alerting** | Employ Advanced SQL **Window Functions** (`AVG() OVER (...)`) to create an automated system that flags immediate Sales Anomaly Alerts. | Advanced SQL, Proactive Analytics |

---

## 🚀 Project Overview
This initiative demonstrates an end-to-end Data Analytics workflow, transforming messy, raw sales data into actionable business intelligence using a structured ELT pipeline. The final report is organized across a **3-Page Power BI Report**: a Cover/Summary Page, a **Performance Dashboard**, and a **Sales Trends Dashboard**.

**Technology Stack:**
- **Data Warehousing & Transformation (ELT):** PostgreSQL (Postgres)
- **Advanced SQL:** Window Functions (`ROW_NUMBER()`, `LAG()`), CTEs, `GROUPING SETS`.
- **Visualization & Reporting (BI):** Power BI Desktop

---

## 🧹 Data Transformation (ELT) and Cleaning
The raw data (`train.csv`) contained inconsistent date formats (DD/MM/YYYY) and missing postal codes. The ELT process created a clean `analytics.fact_sales` table (detailed in `sql/01_elt_data_cleaning.sql`):

1.  **Date Conversion:** Used `TO_DATE(order_date_raw, 'DD/MM/YYYY')` to correctly parse and store date fields, essential for accurate time series analysis.
2.  **Null Imputation:** Used `COALESCE(postal_code, '99999')` to handle missing geographical data, preventing record loss.
3.  **Anomaly Detection View:** The complex 30-day rolling average required for anomaly detection was pre-calculated and stored in a **Materialized View** (`analytics.sales_anomalies`) to ensure sub-second query performance for the dashboard.

---

## 📊 Key Business Findings & Data Validation

The final analysis, driven by the queries in `sql/03_dashboard_queries.sql`, produced validated insights across the two visual pages of the Power BI Report:

### Performance Dashboard Findings

| Finding | Supported by Data | Actionable Insight |
| :--- | :--- | :--- |
| **Regional Dominance** | The **West Region** leads in overall revenue (**~31%** of total sales, \$710K), followed by the East. The **Consumer Segment** is the largest overall contributor. | Focus growth and inventory investment in the West, while prioritizing marketing spend towards the high-value Consumer segment. |
| **Top Product Strategy**| High-value items, specifically the **Canon imageCLASS 2200 Advanced Copier**, consistently rank as the top-selling technology product in both East and West regions. | Secure stable inventory and identify regional distribution differences for these specific high-demand, high-margin products. |
| **Anomaly Detection** | The system successfully flagged a **High Sales Spike** for the `DMI Arturo Collection Chair` in the South, registering **\$1,207.84** compared to its 30-day regional average of **\$404.38**. | The detection system is effective for alerting operational managers to potential fraud or unexpected demand spikes, enabling proactive investigation. |

### Sales Trends Dashboard Findings

| Finding | Supported by Data | Actionable Insight |
| :--- | :--- | :--- |
| **Logistics Inefficiency** | **Standard Class** shipping averages **5 days, 0 hours, and 12 minutes** (`5.01 days`), representing an almost two-day lag compared to the next slowest mode, `Second Class` (`3.25 days`). | Investigate the Standard Class fulfillment process to identify and eliminate the cause of the nearly 2-day delay, improving customer satisfaction. |
| **Predictable Seasonality** | Sales trends show massive, recurring annual growth peaks in **March** (e.g., **195.48%** MoM growth) and **November** (major holiday prep spike). | Budgeting, inventory pre-orders, and staffing must be scheduled annually around these two critical peak months to capitalize on demand. |

---

## 🖼️ Dashboard Visualization

The Power BI report utilizes dynamic measures, clean visual design, and filter panes to allow users to drill into the specific findings above. The visuals are split into a **Performance Dashboard** (focusing on regional ranking, product metrics, and alerts) and a **Sales Trends Dashboard** (focusing on MoM growth and logistics).

<img width="784" height="438" alt="image" src="https://github.com/user-attachments/assets/62f13cfb-51f0-40fd-ad39-d1e6c158fb73" />

<img width="783" height="439" alt="Screenshot 2025-11-29 085725" src="https://github.com/user-attachments/assets/655cf2b1-2bd3-47b2-9720-6eccb1f62e6e" />




---

## 🔗 Repository Contents

| File Path | Description |
| :--- | :--- |
| `sql/01_elt_data_cleaning.sql` | Contains the database setup, staging table DDL, and the final `analytics.fact_sales` table creation with date and null handling. |
| `sql/02_analytical_views.sql` | Contains the logic for the complex **Materialized View** (`analytics.sales_anomalies`), which uses window functions to calculate 30-day moving averages and flag deviations. |
| `sql/03_dashboard_queries.sql` | Contains the five final, verified `SELECT` queries used to extract data for the Power BI report. |
| 'raw/train.csv` | The original, messy source file. |
| `power_bi/Orbit_Retail_Dashboard.pbix` | The final Power BI Report file. |
