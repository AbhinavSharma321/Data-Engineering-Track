-- select all from table
SELECT * FROM FISCAL_CALENDAR

--drop table command
DROP TABLE IF EXISTS API_DB.API_SCHEMA.fiscal_calendar;

--try to alter table date
ALTER TABLE fiscal_calendar 
MODIFY COLUMN "Date" DATE;

-- if the data in the column is convertible
SELECT "Date", TRY_TO_DATE("Date", 'YYYY-MM-DD') 
FROM API_DB.API_SCHEMA.ORDERS
WHERE TRY_TO_DATE("Date", 'YYYY-MM-DD') IS NULL 
AND "Date" IS NOT NULL;

--  Script to Change VARCHAR to DATE

-- Step 1: Add a new DATE column
ALTER TABLE API_DB.API_SCHEMA.ORDERS 
ADD COLUMN "Date_NEW" DATE;

-- Step 2: Convert existing VARCHAR values to DATE and copy data
UPDATE API_DB.API_SCHEMA.ORDERS 
SET "Date_NEW" = TRY_TO_DATE("Date", 'YYYY-MM-DD');

-- Step 3: Drop the old VARCHAR column
ALTER TABLE API_DB.API_SCHEMA.ORDERS 
DROP COLUMN "Date";

-- Step 4: Rename the new column to "Date"
ALTER TABLE API_DB.API_SCHEMA.ORDERS 
RENAME COLUMN "Date_NEW" TO "Date";

--to check date before creating new col and drop previous
SELECT "Date", TO_DATE("Date") FROM fiscal_calendar LIMIT 10;

--create view 01
CREATE OR REPLACE VIEW API_SCHEMA.v_order_f AS
SELECT 
    o."Order ID",
    o."Date",
    o."Customer ID",
    c."Customer Name",
    c."Email",
    c."Region",
    c."Country",
    c."Customer City",
    p."Product ID",
    p."Product Name",
    p."Category",
    p."Sub Category",
    o."Quantity",
    o."Total Price" AS Amount_Local,
    e."Source Currency" AS Local_Currency,
    e."Exchange Rate",
    (o."Total Price" * e."Exchange Rate") AS Amount_USD,
    f."Fiscal Year",
    f."Fiscal Quarter",
    f."Fiscal Month",
    f."Calendar Year",
    f."Calendar Quarter",
    f."Calendar Month",
    f."Week of Year",
    f."Fiscal Week"
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.CUSTOMERS c 
    ON o."Customer ID" = c."Customer ID"
JOIN API_DB.API_SCHEMA.PRODUCTS p 
    ON o."Product ID" = p."Product ID"
LEFT JOIN API_DB.API_SCHEMA.EXCHANGE_RATES e 
    ON o."Date" = e."Date" 
    AND e."Target Currency" = 'USD'
LEFT JOIN API_DB.API_SCHEMA.FISCAL_CALENDAR f 
    ON o."Date" = f."Date";


--show views query
SHOW VIEWS IN API_DB.API_SCHEMA;
SELECT * FROM API_DB.API_SCHEMA.V_CUST_PURCH_SUMMARY_F ;

--to check fical have order date
SELECT DISTINCT o."Date"
FROM API_DB.API_SCHEMA.ORDERS o
LEFT JOIN API_DB.API_SCHEMA.FISCAL_CALENDAR f 
    ON TO_DATE(o."Date") = f."Date"
WHERE f."Date" IS NULL;


-- create view Customer Purchase summary view
CREATE OR REPLACE VIEW API_SCHEMA.v_cust_purch_summary_f AS
SELECT 
    c."Customer ID",
    c."Customer Name",
    COUNT(DISTINCT o."Order ID") AS Total_Orders,
    SUM(o."Total Price") AS Total_Spent,
    MIN(o."Date") AS First_Order_Date,
    AVG(o."Total Price") AS Avg_Order_Value,
    AVG(o."Total Price" * p."Price") AS Avg_Org_Earnings
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.CUSTOMERS c 
    ON o."Customer ID" = c."Customer ID"
JOIN API_DB.API_SCHEMA.PRODUCTS p 
    ON o."Product ID" = p."Product ID"
GROUP BY c."Customer ID", c."Customer Name";


select COUNT(*) from  API_DB.API_SCHEMA.ORDERS where "Customer ID" =25;

--create view 03 product view fact
CREATE OR REPLACE VIEW API_DB.API_SCHEMA.product_f AS
SELECT 
    p."Product ID",
    p."Product Name",
    f."Calendar Month",
    SUM(o."Quantity") AS Total_Quantity_Sold,
    AVG(SUM(o."Quantity")) OVER (
        PARTITION BY p."Product ID" 
        ORDER BY f."Calendar Month"
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Moving_3_Month_Avg_Sales
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.PRODUCTS p 
    ON o."Product ID" = p."Product ID"
JOIN API_DB.API_SCHEMA.FISCAL_CALENDAR f 
    ON o."Date" = f."Date"
GROUP BY p."Product ID", p."Product Name", f."Calendar Month";

--testing view 03
SELECT * FROM API_DB.API_SCHEMA.product_f LIMIT 10;
-- check for null
SELECT * FROM API_DB.API_SCHEMA.product_f WHERE Moving_3_Month_Avg_Sales IS NULL;

--checking total quantitiy sold is correct or not
SELECT 
    p."Product ID",
    f."Calendar Month",
    SUM(o."Quantity") AS Expected_Total_Quantity
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.PRODUCTS p ON o."Product ID" = p."Product ID"
JOIN API_DB.API_SCHEMA.FISCAL_CALENDAR f ON o."Date" = f."Date"
GROUP BY p."Product ID", f."Calendar Month";

--for a specific product:
SELECT 
    "Product ID", 
    "Calendar Month", 
    Total_Quantity_Sold, 
    Moving_3_Month_Avg_Sales
FROM API_DB.API_SCHEMA.product_f
WHERE "Product ID" = 6  
ORDER BY "Product ID", "Calendar Month";


--profit margin and revenue contribution for each product.
-- The CASE statement prevents division by zero by setting NULL when revenue is zero.
CREATE OR REPLACE VIEW API_DB.API_SCHEMA.product_profit_f AS
SELECT 
    p."Product ID",
    p."Product Name",
    SUM(o."Total Price") AS Total_Revenue,
    SUM(o."Total Price" - (p."Price" * o."Quantity")) AS Total_Profit,
    CASE 
        WHEN SUM(o."Total Price") > 0 
        THEN (SUM(o."Total Price" - (p."Price" * o."Quantity")) / SUM(o."Total Price")) * 100
        ELSE NULL 
    END AS Profit_Margin_Percentage
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.PRODUCTS p 
    ON o."Product ID" = p."Product ID"
GROUP BY p."Product ID", p."Product Name";

--Fetch Sample Data
SELECT * FROM API_DB.API_SCHEMA.product_profit_f LIMIT 10;

--  Cross-Check Revenue & Profit
SELECT 
    o."Product ID",
    p."Product Name",
    SUM(o."Total Price") AS Expected_Total_Revenue,
    SUM(o."Total Price" - (p."Price" * o."Quantity")) AS Expected_Total_Profit
FROM API_DB.API_SCHEMA.ORDERS o
JOIN API_DB.API_SCHEMA.PRODUCTS p ON o."Product ID" = p."Product ID"
WHERE o."Product ID" = 101 -- Replace with an actual Product ID
GROUP BY o."Product ID", p."Product Name";


-- Check for NULL Profit Margins
SELECT * FROM API_DB.API_SCHEMA.product_profit_f WHERE Profit_Margin_Percentage IS NULL;


--  top 10 most profitable products
SELECT * FROM API_DB.API_SCHEMA.product_profit_f 
ORDER BY Total_Profit DESC 
LIMIT 10;

