--------------------------------------------------------------------------------------------------------------------------------------------------



**README.md**
**Superstore Sales Analytics Dashboard**


This project demonstrates end-to-end data analysis: from data cleaning in SQL to dashboarding in Power BI, showcasing technical and analytical 
skills in database management, data quality checks, and business intelligence.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Project Overview**

* Dataset: Superstore sales dataset (2014–2017).
* Database: MySQL (Workbench for queries, schema design, and materialized table creation).
* Visualization Tool: Power BI.
* Objective: Clean, model, and analyze Superstore sales data to build professional dashboards with actionable business insights.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Key Features**

* SQL Data Cleaning: Identified and fixed duplicates, inconsistent categories, invalid postal codes, product ID/name mismatches, and ensured 
  accurate dates.
* Materialized Table: Built a clean dataset (orders\_clean) with corrected data types and aggregated rows for accurate reporting.
* Power BI Dashboards: Created an interactive report with 5 tabs:
* Executive Overview – Sales, Quantity, Profit, Margin trends.
* Customer Insights – Sales per customer, retention, profitability.
* Product & Profitability – Best sellers, product margins, profit drivers.
* Regional Performance – Geographic sales heatmaps, regional KPIs.
* Order Efficiency – Shipping speed, discounts, order-level profitability.



--------------------------------------------------------------------------------------------------------------------------------------------------



**KPIs Tracked**

* Total Sales, Total Quantity, Total Profit.
* Sales per Customer, Profit per Customer, Quantity per Customer.
* Sales per Product, Profit per Product, Margin %.
* Order-level metrics: Sales per Order, Profit per Order.
* Year-over-Year growth and Weekly/Monthly sales trends.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Dashboard Preview**

Power BI Dashboard: superstore_sales_dashboard.pdf



--------------------------------------------------------------------------------------------------------------------------------------------------



**Tech Stack**

* SQL: MySQL (Workbench for queries, schema, and cleaning).
* Power BI: Data modeling, DAX measures, visualization.
* Data Source: Superstore dataset (CSV → SQL).
* Excel: Answer business questions with visuals.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Repository Structure**

├── README.md              # High-level overview
├── WORKFLOW.md            # Detailed step-by-step process
├── sql/
│   ├── data_quality_check.sql  # All data quality checks
│   ├── build_materialized_table.sql # Final materialized table
├── powerbi/
│   └── superstore_sales_dashboard.pdf
├── excel/
│   └── superstore_business_questions.pdf



--------------------------------------------------------------------------------------------------------------------------------------------------



**Outcomes**

* Built a fully cleaned SQL dataset ready for BI tools.
* Designed 5 professional dashboards with clear themes and KPIs.
* Showcased end-to-end ETL + Analytics + Visualization workflow.
* Answered business related questions with visuals backing it up.



