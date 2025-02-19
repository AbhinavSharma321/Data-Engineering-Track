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
SELECT * FROM API_DB.API_SCHEMA.v_order_f;

--to check fical have order date
SELECT DISTINCT o."Date"
FROM API_DB.API_SCHEMA.ORDERS o
LEFT JOIN API_DB.API_SCHEMA.FISCAL_CALENDAR f 
    ON TO_DATE(o."Date") = f."Date"
WHERE f."Date" IS NULL;


