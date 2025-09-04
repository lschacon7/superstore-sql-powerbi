/* 1) Structures & Types
- Column presence & types
- Row count
*/
-- Top 10 rows
SELECT * 
FROM superstore.orders 
LIMIT 10;

-- Column names and types
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'superstore' 
AND TABLE_NAME = 'orders';
-- "Order Date" and "Ship Date" are texts, we will change this to type date in our materialized table

-- Total rows (9694)
SELECT COUNT(*) AS row_count 
FROM superstore.orders;

----------------------------------------------------------------------------------------------------------------------------------
/* 2) Uniqueness & Duplicates
- Primary key candidate
- Order line duplication
- Exact duplicate rows
*/
-- Duplicate Row IDs (None)
SELECT `Row ID`, COUNT(*) AS c 
FROM superstore.orders 
GROUP BY `Row ID` 
HAVING c > 1 
ORDER BY c DESC;

-- Potential duplicate order lines (same order + product)
SELECT `Order ID`, `Product ID`, COUNT(*) AS c
FROM superstore.orders
GROUP BY `Order ID`, `Product ID`
HAVING c > 1
ORDER BY c DESC;
-- Some rows had duplicates, so we will return the entire row for rows where c > 2 to check if they are true duplicates

-- Return full rows where the same Order ID + Product ID appear more than once
SELECT o.*
FROM superstore.orders o
JOIN (
    SELECT `Order ID`, `Product ID`
    FROM superstore.orders
    GROUP BY `Order ID`, `Product ID`
    HAVING COUNT(*) > 1
) dup
ON o.`Order ID` = dup.`Order ID`
AND o.`Product ID` = dup.`Product ID`
ORDER BY o.`Order ID`, o.`Product ID`;
-- We can see that the "Sales", "Quantity", and "Profit" columns are different despite "Order ID" and "Product ID" being the same
-- We can infer that these are not true duplicate orders, but instead they're line-splits, likely due to  split shipments, partial 
-- backorders, or discounts applied differently. Since the discounts are the same, we can exlude this from being one of the potential causes.
-- Later we will want to calculate total sales/quantity/profit per order/product, and to avoid double counting in our calculations later,
-- we will aggregate these rows. The only reason we would want to avoid this would be if we wanted to analyze differences in discounts,
-- however we can see that the discounts are the same for these duplicate rows, so we don't need to worry aobut that
-- Since we don't want to touch our raw data table, we have two options: Create a view, or Create a materialized table
-- Since our goal is to eventually connect to Power BI and create a dashboard, we will create a materialized table.
-- We will do this in the next section

-- Exact duplicate rows (None)
SELECT COUNT(*) AS exact_dup_lines
FROM (
  SELECT `Row ID`,`Order ID`,`Order Date`,`Ship Date`,`Ship Mode`,
         `Customer ID`,`Customer Name`,`Segment`,`Country`,`City`,`State`,
         `Postal Code`,`Region`,`Product ID`,`Category`,`Sub-Category`,
         `Product Name`,`Sales`,`Quantity`,`Discount`,`Profit`,
         COUNT(*) AS c
  FROM superstore.orders
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
  HAVING c > 1
) d;

----------------------------------------------------------------------------------------------------------------------------------
/* 3) Nulls / Missing Values
- Critical fields
- categoricals
*/
-- Count null values in relevant columns (None)
SELECT
  SUM(`Order ID` IS NULL)      AS null_order_id,
  SUM(`Order Date` IS NULL)    AS null_order_date,
  SUM(`Ship Date` IS NULL)     AS null_ship_date,
  SUM(`Customer ID` IS NULL)   AS null_customer_id,
  SUM(`Product ID` IS NULL)    AS null_product_id,
  SUM(`Sales` IS NULL)         AS null_sales,
  SUM(`Quantity` IS NULL)      AS null_qty,
  SUM(`Profit` IS NULL)        AS null_profit,
  SUM(`Category` IS NULL)        AS null_category,
  SUM(`Sub-Category` IS NULL)        AS null_sub_category,
  SUM(`Region` IS NULL)        AS null_region,
  SUM(`State` IS NULL)        AS null_state
FROM superstore.orders;

----------------------------------------------------------------------------------------------------------------------------------
/* 4) Categorical Consistency
- Standardized labels
- One-to-many sanity
*/
-- See original vs lower-cased forms to catch “Office Supplies” vs “office supplies”
SELECT LOWER(`Category`) AS cat_key,
       GROUP_CONCAT(DISTINCT `Category` ORDER BY `Category` SEPARATOR ' | ') AS raw_variants, -- Lists distinct original spellings
       COUNT(*) AS rows_
FROM superstore.orders
GROUP BY LOWER(`Category`)
ORDER BY rows_ DESC;

-- Check lower-cased forms against raw_variants for all relevant columns, returns cases with more than one raw_variant
WITH variants AS (
  SELECT 'Category' AS col,
         LOWER(TRIM(`Category`))                       AS key_lower,
         COUNT(DISTINCT `Category`)                    AS variant_count,
         GROUP_CONCAT(DISTINCT `Category`
                       ORDER BY `Category` SEPARATOR ' | ') AS raw_variants,
         COUNT(*)                                      AS rows_
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Category`))
  UNION ALL
  SELECT 'Sub-Category',
         LOWER(TRIM(`Sub-Category`)),
         COUNT(DISTINCT `Sub-Category`),
         GROUP_CONCAT(DISTINCT `Sub-Category` ORDER BY `Sub-Category` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Sub-Category`))
  UNION ALL
  SELECT 'Ship Mode',
         LOWER(TRIM(`Ship Mode`)),
         COUNT(DISTINCT `Ship Mode`),
         GROUP_CONCAT(DISTINCT `Ship Mode` ORDER BY `Ship Mode` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Ship Mode`))
  UNION ALL
  SELECT 'Segment',
         LOWER(TRIM(`Segment`)),
         COUNT(DISTINCT `Segment`),
         GROUP_CONCAT(DISTINCT `Segment` ORDER BY `Segment` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Segment`))
  UNION ALL
  SELECT 'Country',
         LOWER(TRIM(`Country`)),
         COUNT(DISTINCT `Country`),
         GROUP_CONCAT(DISTINCT `Country` ORDER BY `Country` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Country`))
  UNION ALL
  SELECT 'Region',
         LOWER(TRIM(`Region`)),
         COUNT(DISTINCT `Region`),
         GROUP_CONCAT(DISTINCT `Region` ORDER BY `Region` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Region`))
  UNION ALL
  SELECT 'State',
         LOWER(TRIM(`State`)),
         COUNT(DISTINCT `State`),
         GROUP_CONCAT(DISTINCT `State` ORDER BY `State` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`State`))
  UNION ALL
  SELECT 'City',
         LOWER(TRIM(`City`)),
         COUNT(DISTINCT `City`),
         GROUP_CONCAT(DISTINCT `City` ORDER BY `City` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`City`))
  UNION ALL
  SELECT 'Product Name',
         LOWER(TRIM(`Product Name`)),
         COUNT(DISTINCT `Product Name`),
         GROUP_CONCAT(DISTINCT `Product Name` ORDER BY `Product Name` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Product Name`))
  UNION ALL
  SELECT 'Customer Name',
         LOWER(TRIM(`Customer Name`)),
         COUNT(DISTINCT `Customer Name`),
         GROUP_CONCAT(DISTINCT `Customer Name` ORDER BY `Customer Name` SEPARATOR ' | '),
         COUNT(*)
  FROM superstore.orders
  GROUP BY LOWER(TRIM(`Customer Name`))
)
SELECT col, key_lower, variant_count, raw_variants, rows_
FROM variants
WHERE variant_count > 1
ORDER BY col, variant_count DESC;

-- Frequency of every Category, Sub-Category pair
SELECT `Category`,`Sub-Category`, COUNT(*) c
FROM superstore.orders
GROUP BY `Category`,`Sub-Category`
ORDER BY `Category`,`Sub-Category`;

----------------------------------------------------------------------------------------------------------------------------------
/* 5) Date Sanity & Timelines
- Order vs. Ship sequence
- Shipping delay
- Coverage
*/
-- Count rows with Ship Date < Order Date (None)
SELECT COUNT(*) AS ship_before_order
FROM superstore.orders
WHERE STR_TO_DATE(`Ship Date`, '%m/%d/%Y') < STR_TO_DATE(`Order Date`, '%m/%d/%Y');

-- Shipping delay in days (min: 0, avg: 3.9540, max: 7)
SELECT
  MIN(DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS min_ship_days,
  AVG(DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS avg_ship_days,
  MAX(DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS max_ship_days
FROM superstore.orders;

-- Very long or negative delays (None)
SELECT *
FROM superstore.orders
WHERE DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),STR_TO_DATE(`Order Date`, '%m/%d/%Y')) < 0
   OR DATEDIFF(STR_TO_DATE(`Ship Date`, '%m/%d/%Y'),STR_TO_DATE(`Order Date`, '%m/%d/%Y')) > 30
LIMIT 50;

-- Range and distinct months (48, Spans 4 years)
SELECT MIN(DATE(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS first_order,
       MAX(DATE(STR_TO_DATE(`Order Date`, '%m/%d/%Y'))) AS last_order,
       COUNT(DISTINCT DATE_FORMAT(STR_TO_DATE(`Order Date`, '%m/%d/%Y'),'%Y-%m')) AS distinct_months
FROM superstore.orders;

-- Month-by-month counts (look for gaps/spikes)
SELECT DATE_FORMAT(DATE(STR_TO_DATE(`Order Date`, '%m/%d/%Y')),'%Y-%m') AS order_month,
       COUNT(*) AS rows_,
       ROUND(SUM(`Sales`),2) AS sales
FROM superstore.orders
GROUP BY 1
ORDER BY 1;

----------------------------------------------------------------------------------------------------------------------------------
/* 6) Numeric Reasonableness
- Discount bounds
- Quantity
- Sales/Profit 
*/
SELECT
  SUM(`Quantity` <= 0)                         AS nonpositive_qty,
  SUM(`Sales`    <  0)                         AS negative_sales,
  SUM(`Profit`   <  0)                         AS negative_profit_rows,
  ROUND(AVG(`Discount`),3)                     AS avg_discount,
  MIN(`Discount`)                              AS min_discount,
  MAX(`Discount`)                              AS max_discount,
  SUM(`Discount` < 0 OR `Discount` > 1)        AS discount_out_of_0_1
FROM superstore.orders;

----------------------------------------------------------------------------------------------------------------------------------
/* 7) Outliers
- Simple 3-sigma scan
- Context outliers
*/
-- Sales outliers by 3-sigma
WITH stats AS (
  SELECT AVG(`Sales`) AS mu, STDDEV_SAMP(`Sales`) AS sigma
  FROM superstore.orders
)
SELECT o.*
FROM superstore.orders o
CROSS JOIN stats s
WHERE o.`Sales` > s.mu + 3*s.sigma
   OR o.`Sales` < s.mu - 3*s.sigma
LIMIT 100;
-- These outliers are legitimate orders so we will keep them, but they might be useful to look at in our analysis

----------------------------------------------------------------------------------------------------------------------------------
/* 8) Geographic Consistency
- Regiont-State-City alignment
- Postal Code format
*/
-- States with multiple regions (None)
SELECT `State`, COUNT(DISTINCT `Region`) AS region_count
FROM superstore.orders
GROUP BY `State`
HAVING region_count > 1
ORDER BY region_count DESC, `State`;

-- Full State-Region distribution
SELECT `State`, `Region`, COUNT(*) AS rows_
FROM superstore.orders
GROUP BY `State`, `Region`
ORDER BY `State`, rows_ DESC;

-- City within a given State mapped to multiple regions (None)
SELECT `State`, `City`, COUNT(DISTINCT `Region`) AS region_count
FROM superstore.orders
GROUP BY `State`, `City`
HAVING region_count > 1
ORDER BY `State`, `City`;

-- Invalid Postal Code doesn't match ##### or #####-####
SELECT
  COUNT(*) AS total_rows,
  SUM(`Postal Code` IS NULL OR TRIM(CAST(`Postal Code` AS CHAR)) = '') AS blank_postal,
  SUM( NOT (CAST(`Postal Code` AS CHAR) REGEXP '^[0-9]{5}(-[0-9]{4})?$') ) AS invalid_format
FROM superstore.orders;
-- Invalid Postal Codes likely #### format where the leading 0 was dropped

-- Return lengths of Postal Codes
SELECT
  LENGTH(TRIM(CAST(`Postal Code` AS CHAR))) AS zip_len,
  COUNT(*) AS rows_
FROM superstore.orders
WHERE `Postal Code` IS NOT NULL
  AND TRIM(CAST(`Postal Code` AS CHAR)) <> ''
GROUP BY zip_len
ORDER BY zip_len;
-- This confirms that the Invalid Postal Codes are of the format ####
-- To fix this we will restore the leading 0 in the materialized table later

-- Returns invalid Postal Codes
SELECT DISTINCT CAST(`Postal Code` AS CHAR) AS postal_sample
FROM superstore.orders
WHERE `Postal Code` IS NOT NULL -- ignore blank rows
  AND TRIM(CAST(`Postal Code` AS CHAR)) <> '' -- ignore rows that are just whitespace
  AND NOT (CAST(`Postal Code` AS CHAR) REGEXP '^[0-9]{5}(-[0-9]{4})?$') -- removes valid postal code format
ORDER BY postal_sample
LIMIT 50;

----------------------------------------------------------------------------------------------------------------------------------
/* 9) Logical/Business Rules
- Profit math
- Shop Mode vs ship_days
*/
-- High discount (≥ 50%) AND high profit margin (≥ 30%) (None)
SELECT *
FROM superstore.orders
WHERE `Sales` > 0
  AND `Discount` >= 0.50
  AND (`Profit` / `Sales`) >= 0.30
ORDER BY `Discount` DESC, (`Profit` / `Sales`) DESC
LIMIT 200;

-- Bucket discounts into tenths: 0.0, 0.1, 0.2, …, 0.9, 1.0
SELECT
  ROUND(`Discount`*10)/10 AS discount_bin,
  COUNT(*)                      AS rows_,
  ROUND(AVG(`Profit`/NULLIF(`Sales`,0)),3) AS avg_margin,
  ROUND(SUM(`Sales`),2)        AS total_sales,
  ROUND(SUM(`Profit`),2)       AS total_profit
FROM superstore.orders
WHERE `Sales` > 0
GROUP BY discount_bin
ORDER BY discount_bin;
-- There is a direct correlation between a higher discount and less total profit
-- Discount 0.6 stands out for total profit loss not being as large as other large discounts

-- Margins outside a plausible range
SELECT
  SUM(`Sales` <= 0)                                AS nonpositive_sales_rows, -- 0
  SUM(`Profit`/NULLIF(`Sales`,0) >  1.0)           AS margin_gt_100pct_rows, -- 0
  SUM(`Profit`/NULLIF(`Sales`,0) < -1.0)           AS `margin_lt_-100pct_rows` -- 332
FROM superstore.orders;

-- Check sales with the largest negative margin
SELECT
  `Order ID`, `Order Date`, `Category`, `Sub-Category`, `Product Name`,
  `Sales`, `Discount`, `Quantity`, `Profit`,
  ROUND(`Profit`/`Sales`, 3) AS margin
FROM superstore.orders
WHERE `Sales` > 0
  AND (`Profit`/`Sales`) < -1.0
ORDER BY margin ASC
LIMIT 50;
-- Looks like sales with the largest negative margin had high discount rates

-- Check average margin by discount rate
SELECT
  CASE
    WHEN `Discount` = 0 THEN '0%'
    WHEN `Discount` < 0.2 THEN '0–20%'
    WHEN `Discount` < 0.4 THEN '20–40%'
    WHEN `Discount` < 0.6 THEN '40–60%'
    ELSE '60%+'
  END AS discount_band,
  COUNT(*) AS rows_,
  ROUND(AVG(`Profit`/`Sales`),3) AS avg_margin
FROM superstore.orders
WHERE `Sales` > 0
GROUP BY discount_band
ORDER BY rows_ DESC;
-- Confirms that sales with the largest negative margin had high discount rates

-- Compare ship_mode against ship_days
WITH base AS (
  SELECT
    `Ship Mode`                           AS ship_mode,
    DATEDIFF(
      STR_TO_DATE(`Ship Date`,  '%m/%d/%Y'),
      STR_TO_DATE(`Order Date`, '%m/%d/%Y')
    )                                     AS ship_days
  FROM superstore.orders
)
-- Basic distribution by mode
SELECT
  ship_mode,
  COUNT(*)                    AS rows_,
  MIN(ship_days)              AS min_days,
  ROUND(AVG(ship_days),2)     AS avg_days,
  MAX(ship_days)              AS max_days
FROM base
GROUP BY ship_mode
ORDER BY avg_days;
-- More premium shipping modes had fewer delivery days

----------------------------------------------------------------------------------------------------------------------------------
/* 10) Exactness & Duplication Across Dates
- Order ID reuse
- Product reuse
*/
-- Order IDs whose lines span multiple days (None)
WITH ord AS (
  SELECT `Order ID`,
         STR_TO_DATE(`Order Date`, '%m/%d/%Y') AS order_dt
  FROM superstore.orders
)
SELECT `Order ID`,
       MIN(order_dt) AS min_order_dt,
       MAX(order_dt) AS max_order_dt,
       DATEDIFF(MAX(order_dt), MIN(order_dt)) AS span_days,
       COUNT(*) AS line_count
FROM ord
GROUP BY `Order ID`
HAVING span_days > 1
ORDER BY span_days DESC, line_count DESC;

-- Same Order ID appearing in multiple regions/states/cities (None)
SELECT `Order ID`,
       COUNT(DISTINCT `Region`) AS regions,
       COUNT(DISTINCT `State`)  AS states,
       COUNT(DISTINCT `City`)   AS cities
FROM superstore.orders
GROUP BY `Order ID`
HAVING regions > 1 OR states > 1 OR cities > 1
ORDER BY regions DESC, states DESC, cities DESC;

-- Same Order ID tied to multiple customers (None)
SELECT `Order ID`,
       COUNT(DISTINCT `Customer ID`)   AS distinct_customers,
       COUNT(DISTINCT `Customer Name`) AS distinct_names
FROM superstore.orders
GROUP BY `Order ID`
HAVING distinct_customers > 1 OR distinct_names > 1
ORDER BY distinct_customers DESC, distinct_names DESC;


-- Same Product ID mapped to multiple Product Names
SELECT `Product ID`,
       COUNT(DISTINCT `Product Name`) AS name_variants,
       GROUP_CONCAT(DISTINCT `Product Name` ORDER BY `Product Name` SEPARATOR ' | ') AS variants
FROM superstore.orders
GROUP BY `Product ID`
HAVING name_variants > 1
ORDER BY name_variants DESC, `Product ID`;

-- Check row count of Product Ids with multiple Product Names
SELECT t.`Product ID`, t.`Product Name`, t.row_count
FROM (
    SELECT 
        `Product ID`,
        `Product Name`,
        COUNT(*) AS row_count
    FROM superstore.orders
    GROUP BY `Product ID`, `Product Name`
) t
JOIN (
    SELECT 
        `Product ID`
    FROM superstore.orders
    GROUP BY `Product ID`
    HAVING COUNT(DISTINCT `Product Name`) > 1
) v
ON t.`Product ID` = v.`Product ID`
ORDER BY t.`Product ID`, t.row_count DESC;
-- We will standardize product names and aggregate rows in the materialized table

-- Same Product Name mapped to multiple Product ID
SELECT `Product Name`,
       COUNT(DISTINCT `Product ID`) AS id_variants,
       GROUP_CONCAT(DISTINCT `Product ID` ORDER BY `Product ID` SEPARATOR ' | ') AS ids
FROM superstore.orders
GROUP BY `Product Name`
HAVING id_variants > 1
ORDER BY id_variants DESC, `Product Name`;

-- Product names with multiple Product IDs
-- Plus breakdowns by region, year, ship mode, and discount buckets
WITH multi_names AS (
  SELECT `Product Name`
  FROM superstore.orders
  GROUP BY `Product Name`
  HAVING COUNT(DISTINCT `Product ID`) > 1
)
SELECT
  o.`Product Name`,
  o.`Product ID`,
  -- Region breakdown
  SUM(o.`Region` = 'West')    AS West,
  SUM(o.`Region` = 'East')    AS East,
  SUM(o.`Region` = 'Central') AS Central,
  SUM(o.`Region` = 'South')   AS South,
  -- Year breakdown
  SUM(YEAR(STR_TO_DATE(o.`Order Date`, '%m/%d/%Y')) = 2014) AS y2014,
  SUM(YEAR(STR_TO_DATE(o.`Order Date`, '%m/%d/%Y')) = 2015) AS y2015,
  SUM(YEAR(STR_TO_DATE(o.`Order Date`, '%m/%d/%Y')) = 2016) AS y2016,
  SUM(YEAR(STR_TO_DATE(o.`Order Date`, '%m/%d/%Y')) = 2017) AS y2017,
  -- Ship Mode breakdown
  SUM(o.`Ship Mode` = 'Same Day')       AS same_day,
  SUM(o.`Ship Mode` = 'First Class')    AS first_class,
  SUM(o.`Ship Mode` = 'Second Class')   AS second_class,
  SUM(o.`Ship Mode` = 'Standard Class') AS standard_class,
  -- Discount buckets (0.0, 0.1, 0.2, ... 0.9+)
  SUM(o.`Discount` = 0.0)                         AS disc_0,
  SUM(o.`Discount` >= 0.1 AND o.`Discount` < 0.2) AS disc_10,
  SUM(o.`Discount` >= 0.2 AND o.`Discount` < 0.3) AS disc_20,
  SUM(o.`Discount` >= 0.3 AND o.`Discount` < 0.4) AS disc_30,
  SUM(o.`Discount` >= 0.4 AND o.`Discount` < 0.5) AS disc_40,
  SUM(o.`Discount` >= 0.5 AND o.`Discount` < 0.6) AS disc_50,
  SUM(o.`Discount` >= 0.6 AND o.`Discount` < 0.7) AS disc_60,
  SUM(o.`Discount` >= 0.7 AND o.`Discount` < 0.8) AS disc_70,
  SUM(o.`Discount` >= 0.8 AND o.`Discount` < 0.9) AS disc_80,
  SUM(o.`Discount` >= 0.9)                        AS disc_90plus,
  COUNT(*) AS total_rows
FROM superstore.orders o
JOIN multi_names m
  ON m.`Product Name` = o.`Product Name`
GROUP BY o.`Product Name`, o.`Product ID`
ORDER BY o.`Product Name`, o.`Product ID`;
-- When we investigate Product Names with multiple Product IDs, we can see that those Product IDs appear evenly throughout each 
-- region, year, ship mode, and discount, so we can conclude that rather than them being legit variations, they are true duplicates
-- We will standardize Product ID and aggregate rows in the materialized dataset