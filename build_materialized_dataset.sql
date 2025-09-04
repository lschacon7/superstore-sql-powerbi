----------------------------------------------------------------------------------------------------------------------------------
/* 11) Materialized Dataset With Changes
- Change “Order Date” and “Ship Date” from text data type to date data type, as well as other column’s data types
- Aggregate rows on “Sales”, “Quantity”, “Profit”, “Order Date”, “Ship Date”, and any other relevant columns where Order ID and 
  Product ID are the same.
- Change “Postal Code” to type text and add the leading zero back to Postal Codes with four characters ####
- Standardize Product Names to the most common Product Name for that Product ID and aggregate rows
- Standardize Product ID to the most common Product ID and aggregate rows
*/

/* 0) Use schema */
USE superstore;

/* 1) Helper maps - clean slate */
DROP TABLE IF EXISTS product_name_canonical;
DROP TABLE IF EXISTS product_id_canonical;

/* 2) Canonical Product Name per Product ID */
CREATE TABLE product_name_canonical (
  `Product ID`        VARCHAR(30)  NOT NULL,
  canon_product_name  VARCHAR(255) NOT NULL,
  PRIMARY KEY (`Product ID`)
) ENGINE=InnoDB;

INSERT INTO product_name_canonical (`Product ID`, canon_product_name)
SELECT `Product ID`, `Product Name`
FROM (
  SELECT
    x.`Product ID`,
    x.`Product Name`,
    x.cnt,
    ROW_NUMBER() OVER (
      PARTITION BY x.`Product ID`
      ORDER BY x.cnt DESC, x.`Product Name` ASC
    ) AS rn
  FROM (
    SELECT `Product ID`, `Product Name`, COUNT(*) AS cnt
    FROM superstore.orders
    GROUP BY `Product ID`, `Product Name`
  ) AS x
) AS ranked
WHERE rn = 1;

/* 3) Canonical Product ID per Product Name */
CREATE TABLE product_id_canonical (
  `Product Name`   VARCHAR(255) NOT NULL,
  canon_product_id VARCHAR(30)  NOT NULL,
  PRIMARY KEY (`Product Name`)
) ENGINE=InnoDB;

INSERT INTO product_id_canonical (`Product Name`, canon_product_id)
SELECT `Product Name`, `Product ID`
FROM (
  SELECT
    x.`Product Name`,
    x.`Product ID`,
    x.cnt,
    ROW_NUMBER() OVER (
      PARTITION BY x.`Product Name`
      ORDER BY x.cnt DESC, x.`Product ID` ASC
    ) AS rn
  FROM (
    SELECT `Product Name`, `Product ID`, COUNT(*) AS cnt
    FROM superstore.orders
    GROUP BY `Product Name`, `Product ID`
  ) AS x
) AS ranked
WHERE rn = 1;

/* 4) Clean target table (explicit column types + indexes) */
DROP TABLE IF EXISTS orders_clean;
CREATE TABLE orders_clean (
  clean_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Order ID`      VARCHAR(30)     NOT NULL,
  `Product ID`    VARCHAR(30)     NOT NULL,
  `Product Name`  VARCHAR(255)    NOT NULL,
  `Order Date`    DATE            NOT NULL,
  `Ship Date`     DATE            NOT NULL,
  `Ship Mode`     VARCHAR(30)     NOT NULL,
  `Customer ID`   VARCHAR(30)     NOT NULL,
  `Customer Name` VARCHAR(100)    NOT NULL,
  `Segment`       VARCHAR(30)     NOT NULL,
  `Country`       VARCHAR(50)     NOT NULL,
  `City`          VARCHAR(100)    NOT NULL,
  `State`         VARCHAR(50)     NOT NULL,
  `Postal Code`   CHAR(5)         NOT NULL,
  `Region`        VARCHAR(50)     NOT NULL,
  `Category`      VARCHAR(50)     NOT NULL,
  `Sub-Category`  VARCHAR(50)     NOT NULL,
  `Sales`         DECIMAL(12,2)   NOT NULL,
  `Quantity`      INT             NOT NULL,
  `Profit`        DECIMAL(12,2)   NOT NULL,
  `Discount`      DECIMAL(6,4)    NOT NULL,
  PRIMARY KEY (clean_id),
  KEY idx_order   (`Order ID`),
  KEY idx_product (`Product ID`),
  KEY idx_dates   (`Order Date`, `Ship Date`),
  KEY idx_geo     (`Region`, `State`, `City`)
) ENGINE=InnoDB;

/* 5) Load cleaned, aggregated data */
INSERT INTO orders_clean (
  `Order ID`, `Product ID`, `Product Name`,
  `Order Date`, `Ship Date`,
  `Ship Mode`, `Customer ID`, `Customer Name`, `Segment`,
  `Country`, `City`, `State`, `Postal Code`, `Region`, `Category`, `Sub-Category`,
  `Sales`, `Quantity`, `Profit`, `Discount`
)
SELECT
  n.`Order ID`,
  /* Canonicalize Product ID (by name) if available, else original */
  COALESCE(pid.canon_product_id, n.`Product ID`)                                             AS final_product_id,
  /* Canonical Product Name by final Product ID, else original */
  COALESCE(MAX(pname.canon_product_name), MAX(n.`Product Name`))                             AS final_product_name,
  /* Dates */
  MIN(STR_TO_DATE(n.`Order Date`, '%m/%d/%Y'))                                               AS order_date,
  MIN(STR_TO_DATE(n.`Ship Date`,  '%m/%d/%Y'))                                               AS ship_date,
  /* Dimensions (kept as-is in the group) */
  n.`Ship Mode`,
  n.`Customer ID`,
  n.`Customer Name`,
  n.`Segment`,
  n.`Country`,
  n.`City`,
  n.`State`,
  MAX(LPAD(CAST(n.`Postal Code` AS CHAR), 5, '0'))                                           AS postal_code,
  n.`Region`,
  n.`Category`,
  n.`Sub-Category`,
  /* --- CLEAN NUMERICS BEFORE AGGREGATION --- */
  ROUND(SUM(
    CAST(
      REPLACE(REPLACE(TRIM(CAST(n.`Sales`  AS CHAR)),'$',''), ',', '') AS DECIMAL(13,4)
    )
  ), 2)                                                                                      AS sales,
  SUM(
    CAST(
      REPLACE(REPLACE(TRIM(CAST(n.`Quantity` AS CHAR)),'$',''), ',', '') AS DECIMAL(13,4)
    )
  )                                                                                          AS quantity,
  ROUND(SUM(
    CAST(
      REPLACE(REPLACE(TRIM(CAST(n.`Profit` AS CHAR)),'$',''), ',', '') AS DECIMAL(13,4)
    )
  ), 2)                                                                                      AS profit,
  ROUND(AVG(
    CAST(
      REPLACE(REPLACE(TRIM(CAST(n.`Discount` AS CHAR)),'$',''), ',', '') AS DECIMAL(13,4)
    )
  ), 4)                                                                                      AS discount
FROM superstore.orders AS n
LEFT JOIN product_id_canonical   AS pid
       ON n.`Product Name` = pid.`Product Name`
LEFT JOIN product_name_canonical AS pname
       ON COALESCE(pid.canon_product_id, n.`Product ID`) = pname.`Product ID`
GROUP BY
  n.`Order ID`,
  final_product_id,
  n.`Ship Mode`,
  n.`Customer ID`,
  n.`Customer Name`,
  n.`Segment`,
  n.`Country`,
  n.`City`,
  n.`State`,
  n.`Region`,
  n.`Category`,
  n.`Sub-Category`;

----------------------------------------------------------------------------------------------------------------------------------
/* 12) Verify Changes in Table orders_clean
- Check new column data types
- Make sure there are no Order ID + Product ID duplicates for the same dates and location
- Make sure there are no invalid Postal Codes
- Make sure each Product Name is mapped to one Product ID
- Make sure each Product ID is mapped to one Product Name
*//
-- Check new column data types
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'superstore'
  AND TABLE_NAME   = 'orders_clean'
  AND COLUMN_NAME IN (
    'Order ID','Product ID','Order Date','Ship Date','Postal Code',
    'Sales','Quantity','Profit','Region','State','City','Product Name'
  )
ORDER BY COLUMN_NAME;

-- No duplicates on Order ID + Product ID for the same dates & location (None)
SELECT 
  `Order ID`,`Product ID`,`Order Date`,`Ship Date`,`Region`,`State`,`City`,
  COUNT(*) AS c
FROM superstore.orders_clean
GROUP BY 
  `Order ID`,`Product ID`,`Order Date`,`Ship Date`,`Region`,`State`,`City`
HAVING c > 1
ORDER BY c DESC, `Order ID`, `Product ID`;

SELECT
  SUM(TRIM(COALESCE(`Postal Code`,'')) = '')                                           AS blank_zip_rows,
  SUM( NOT (TRIM(`Postal Code`) REGEXP '^[0-9]{5}(-[0-9]{4})?$') )                     AS invalid_zip_rows
FROM superstore.orders_clean;

-- No invalid postal codes and no blanks (None)
SELECT `Product Name`,
       COUNT(DISTINCT `Product ID`) AS id_variants
FROM superstore.orders_clean
GROUP BY `Product Name`
HAVING id_variants > 1
ORDER BY id_variants DESC, `Product Name`;

-- Each Product Name maps to one Product ID
SELECT `Product ID`,
       COUNT(DISTINCT `Product Name`) AS name_variants
FROM superstore.orders_clean
GROUP BY `Product ID`
HAVING name_variants > 1
ORDER BY name_variants DESC, `Product ID`;

-- Each Product ID maps to one Product Name
SELECT `Product ID`,
       COUNT(DISTINCT `Product Name`) AS name_variants
FROM superstore.orders_clean
GROUP BY `Product ID`
HAVING name_variants > 1
ORDER BY name_variants DESC, `Product ID`;

-- Total Sales in raw orders
SELECT ROUND(SUM(CAST(`Sales` AS DECIMAL(12,2))),2) AS total_sales_raw
FROM superstore.orders;

-- Total Sales in cleaned orders
SELECT ROUND(SUM(`Sales`),2) AS total_sales_clean
FROM superstore.orders_clean;

-- Compare Quantity
SELECT 
  (SELECT SUM(CAST(`Quantity` AS DECIMAL(12,2))) FROM superstore.orders) AS qty_raw,
  (SELECT SUM(`Quantity`) FROM superstore.orders_clean) AS qty_clean;

-- Compare Profit
SELECT 
  (SELECT ROUND(SUM(CAST(`Profit` AS DECIMAL(12,2))),2) FROM superstore.orders) AS profit_raw,
  (SELECT ROUND(SUM(`Profit`),2) FROM superstore.orders_clean) AS profit_clean;

-- Return 10 lines from superstore.orders_clean
SELECT * 
FROM superstore.orders_clean
LIMIT 10;

-- Was there an Order/Shipment eveery dat from 2014 to 2017?
SET SESSION cte_max_recursion_depth = 2000;
WITH RECURSIVE calendar AS (
    SELECT DATE('2014-01-01') AS cal_date
    UNION ALL
    SELECT DATE_ADD(cal_date, INTERVAL 1 DAY)
    FROM calendar
    WHERE cal_date < '2017-12-31'
)
-- Missing Order Dates
SELECT 'Order Date' AS date_type, c.cal_date
FROM calendar c
LEFT JOIN superstore.orders_clean o
       ON DATE(o.`Order Date`) = c.cal_date
GROUP BY c.cal_date
HAVING COUNT(o.`Order ID`) = 0
UNION ALL
-- Missing Ship Dates
SELECT 'Ship Date' AS date_type, c.cal_date
FROM calendar c
LEFT JOIN superstore.orders_clean o
       ON DATE(o.`Ship Date`) = c.cal_date
GROUP BY c.cal_date
HAVING COUNT(o.`Order ID`) = 0
ORDER BY cal_date, date_type;