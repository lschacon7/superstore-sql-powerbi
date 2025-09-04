--------------------------------------------------------------------------------------------------------------------------------------------------



WORKFLOW.md
Workflow: From Raw Data to Dashboard



--------------------------------------------------------------------------------------------------------------------------------------------------



**Step 1: Choose and Download a Dataset**

**Dataset**: Superstore Dataset from Kaggle

**Why This Dataset?**

* I chose a Sales/Orders dataset because it is very practical and is immediately relevant for both data and finance roles.
* The dataset comes pretty clean already, but we will still do our basic checks to demonstrate due diligence and attention to detail.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Step 2: MySQL Setup**

**Install:** MySQL Workbench and MySQL Server 8.0.43

**Setup:**

* Open MySQL Server 8.0.43
* Create Schema “superstore”
* Right Click and Select “Table Data Import Wizard” to Import Dataset into Schema
* Name the New Table “orders”.



--------------------------------------------------------------------------------------------------------------------------------------------------



**Step 3: Data Quality Checks**

**SQL Code: Data Quality Checks**

1. Structures \& Types
   - Column presence \& types
   - Row count
2. Uniqueness \& Duplicates
   - Primary key candidate
   - Order line duplications
   - Exact duplicate rows
3. Nulls / Missing Values
   - Critical fields
4. Categorical Consistency
   - Standardized labels
   - One-to-many sanity
5. Date Sanity \& Timelines
   - Order vs. Ship sequence
   - Shipping delay
   - Coverage
6. Numeric Reasonableness
   - Discount bounds
   - Quantity
   -Sales/Profit
7. Outliers
   - Simple 3-sigma scan
   - Context outliers
8. Geographic Consistency
   - Region-State-City alignment
   - Postal Code format
9. Logical/Business Rules
   - Profit math
   - Shop Mode vs ship days
10. Exactness \& Duplication Across Dates
    - Order ID reuse
    - Product reuse



--------------------------------------------------------------------------------------------------------------------------------------------------



**Step 4: Data Cleaning (Materialized Table)**

**SQL Code: Build Materialized Table**

**Changes:**

* Change “Order Date” and “Ship Date” from text data type to date data type, as well as other column’s data types
* Aggregate rows on “Sales”, “Quantity”, “Profit”, “Order Date”, and any other relevant columns where Order ID and Product ID are the same.
* Change “Postal Code” to type text and add the leading zero back to Postal Codes with four characters ####
* Standardize Product Names to the most common Product Name for that Product ID and aggregate rows
* Standardize Product ID to the most common Product ID and aggregate rows



--------------------------------------------------------------------------------------------------------------------------------------------------



**Step 5: Define KPIs \& Filters**

**Core KPIs:**

* Sales
* Quantity
* Profit
* Profit Margin ( Profit / Sales )
* Total Orders ( COUNT(DISTINCT Order ID) )
* Avg Discount

**Customer KPIs:**

* Sales per Customer → SUM(Sales) / COUNT(DISTINCT Customer ID)
* Profit per Customer → SUM(Profit) / COUNT(DISTINCT Customer ID)
* Top 10 Customers by Sales/Profit
* Customer Lifetime Value (CLV proxy) → cumulative sales per customer across all orders

**Product KPIs:**

* Sales per Product → SUM(Sales) GROUP BY Product ID
* Profit per Product → SUM(Profit) GROUP BY Product ID
* Quantity Sold per Product → SUM(Quantity) GROUP BY Product ID
* Top/Bottom 10 Products by Sales, Profit, or Margin
* % of Sales from Top 20 Products → Pareto analysis

**Time-Based KPIs:**

* Sales per Week/Month/Year → SUM(Sales) GROUP BY DATE\_FORMAT(Order Date, '%Y-%m')
* Profit per Week/Month/Year
* Order Growth Rate → (This Period Orders – Last Period Orders) / Last Period Orders
* Sales Seasonality → e.g., peak months vs low months

**Operational KPIs:**

* Average Shipping Days → AVG(Ship Date – Order Date)
* Late Shipments → % where Ship Date > Expected
* Sales by Ship Mode
* Profitability by Ship Mode

**Advanced/Analytical KPIs:**

* Discount Impact → Compare Profit Margin for discounted vs. non-discounted orders
* Return Risk Proxy → Very high discount + very low profit combinations
* Contribution Analysis → % of Sales/Profit by Segment, Category, Sub-Category
* Profitability Index → Profit per Quantity to show “bang for buck”

**Filters:**

* Product Name
* Order Date
* Ship Date
* Ship Mode
* Customer Name
* Segment
* Country
* City
* State
* Postal Code
* Region
* Category
* Sub-Category
* Discount

--------------------------------------------------------------------------------------------------------------------------------------------------

**Step 6: Connect to Power BI**

**Download:** Power BI Connector

--------------------------------------------------------------------------------------------------------------------------------------------------

**Step 7: Create Tables, Columns, and Measures with DAX**

DAX Code: Dax Code Link

Tables: Date (DayOfWeekName, DayOfWeekNum, MonthName, MonthNum, MonthYear, MonthYearNum, Quarter, Year)

DAX Measures: Avg Profit per Customer per Month, Avg Profit per Product per Month, Avg Quantity per Customer per Month, Avg Quantity per Product 
per Month, Avg Sales per Customer per Month, Avg Sales per Product per Month, Customers (Monthly), Months Sold, Products (Monthly), Profit per 
Customer, Profit per Customer (Monthly), Profit per Order, Profit per Product, Profit per Product (Monthly), Quantity per Customer, Quantity per 
Customer (Monthly), Quantity per Order, Quantity per Product, Quantity per Product (Monthly), Sales per Customer, Sales per Customer (Monthly), 
Sales per Order, Sales per Product, Sales per Product (Monthly), Ship Date, Total Margin, Total Profit, Total Quantity, Total Sales


DAX Columns: Margin, NumMonths

--------------------------------------------------------------------------------------------------------------------------------------------------

**Step 8: Build Dashboard**

**Dashboard Tabs:**

* Executive Overview → company-wide KPIs & YoY trends
* Customer Insights → sales per customer, profit per customer
* Product & Profitability → product-level sales, margins
* Regional Performance → state/city/regional maps & KPIs
* Order Efficiency → order-level sales, quantity, and profit metrics

--------------------------------------------------------------------------------------------------------------------------------------------------

**Step 9: Answer Real Business Questions**

Excel File: Superstore Business Questions

Executive Overview			
1. What is the overall trend in sales and profit from 2014 to 2017?	
A: Total Sales steadily increased across the 4 years, with especially strong Q4 spikes every year, likely driven by the holidays. Total Profit 
grew as well but showed more volatility, suggesting discount-heavy promotions or margin pressures in certain categories. Profit Margins overall 
remained about the same while Total Quantity saw an increase, indicating the business grew in a sustainable way.	

2. Are we growing more through volume (quantity) or price (margin)?	
A: Sales per Product and Profit per Product each saw a slight increase each year, while Quantity Ordered increased significantly, indicating that 
most of the growth came from the quantity sold. Total Sales and Quantity Ordered follow a similar growth trend their it's peaks in Q4, however 
Total Profit doesn't see the same level of growth in Q4, indicating that there were likely heavy promotions in Q4.	

Customer Insights			
3. Which customer segment contributes the most to profitability?
A: From 2014 to 2017, the Consumer segment has the highest Total Profit, while the Home Office segment has the lowest Total Profit. However this 
is due to the Consumer segment having the largest Quantity Ordered, when we look at Profit Margin, we can see that Home Office is actually the 
largest, meaning it is the most efficient segment. When we look at 2017 alone (the most recent year), we can see that the Consumer segment now 
has the largest Profit Margin, indicating that it is both the most profitable and the most efficient.		

4. Do customers tend to be one-time buyers or repeat customers?	
A: When looking at Total Customers and Total Profit grouped by the Number of Months the customer returned, we can see that these two metrics 
follow a similar trend, with both of them peaking at around 5 to 8 months of retention, suggesting that the customers generating the most 
profit tend to be repeat customers. In 2017 alone (the most recent year), Total Customers and Total Profit both peak at customers with 2 months 
of retention, indicating that even in the last year, the customers generating the most profit were repeat customers.	

Product & Profitability	
5. Which products drive the most sales vs the most profit?
A: We can see that the two items the bring in the most Total Sales and the two items that bring in the most Total Profit are actually the same, 
and both are in the technology category. In fact almost all the items in the Top 10 for Total Sales and Total Profit belong in the Technology 
category, indicating that it is the most profitable category. We can also see the Top 10 products with the largest Profit Margin and Total Profit 
greater than $1,000, indicating these are the most efficient items to sell.

6. Do we have any products with duplicated SKUs or inconsistent IDs?
A: Yes, there were multiple cases of one product ID being linked to several product names, and vice versa. After cleaning, we standardized all 
Product IDs and all Product Names to the most common one, and aggregated duplicates rows. This ensures accurate reporting and prevents under or 
over counting errors when creating calculated columns in Power BI. We also found that there were multiple Segments mapped to the same Product, 
but this didn't affect our calculations so we left it as is.

Regional Performance			

7. Which regions are the strongest and weakest performers?	
A: The West Region has the largest Total Sales and Total Profit, with the East Region close behind it. The South and Central Regions had 
significantly lower Total Sales, Total Profit, and Quantity Ordered. The East Region benefits the most from the holidays in Q4 with the largest 
spike out of any region. The South has high potential for growth with a large Profit per Customer and low Quantity.	

8. Were there geographic data quality issues?	
A: Yes, there were about 400 postal codes that were only 4 digits long, while the rest were 5 digits long, which would have distorted geographic 
reporting. These were cleaned and standardized into proper 5-digit codes, improving regional mapping accuracy. We also checked that the mapping 
for state, region, and zip codes were unique and we didn't find any issues.	

Order Efficiency	
9. What is the average sales per order, and how has this changed over time?
A: Sales per order grew slightly year over year, but inconsistently across categories. Technology orders are much higher in value, while Office 
Supplies orders are frequent but smaller. This points to cross-selling opportunities, encouraging low-value customers to bundle technology items.	

10. How do the different trends throughout the year per order compare?
A: Sales per Order and Profit per Order follow a similar trend, while Profit 
per Order stays more constant over time. This suggests that Sales per Order is more heavily affected by changes in Quantity per Order, while 
Profit per Order is balanced out by discounts and promotions.					


--------------------------------------------------------------------------------------------------------------------------------------------------

**Step 10: Final Deliverables**

* SQL table superstore_orders_clean (ready for BI).
* Power BI dashboard (superstore_sales_dashboard.pdf).
* Excel workbook with Business Questions and Answers.
* Repository with README + Workflow + SQL + Power BI + Excel.

├── README.md              # High-level overview
├── WORKFLOW.md            # Detailed step-by-step process
├── sql/
│   ├── data_quality_check.sql  # All data quality checks
│   ├── build_materialized_table.sql # Final materialized table
├── powerbi/
│   └── superstore_sales_dashboard.pdf
├── excel/
│   └── superstore_business_questions.pdf



