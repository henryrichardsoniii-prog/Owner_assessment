CREATE OR REPLACE TABLE DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._dev_AD_AND_SALES_DATA AS

WITH 

-- purpose of this CTE is to put advertising spend and sales into one table
-- have to format the sales and spending columns to reflect real numbers 
ad_spend_and_sales AS (
select 
a.month
, TO_DECIMAL(
         REPLACE(
           REGEXP_REPLACE(a.outbound_sales_team, '[^0-9,]', ''),    -- keep only digits + comma
           ',', '.'                                                 -- convert decimal comma to dot
         )
       ) AS outbound_sales
, TO_DECIMAL(
         REPLACE(
           REGEXP_REPLACE(a.inbound_sales_team, '[^0-9,]', ''),     -- keep only digits + comma
           ',', '.'                                                 -- convert decimal comma to dot
         )
       ) AS inbound_sales
, TO_DECIMAL(
         REPLACE(
           REGEXP_REPLACE(b.advertising , '[^0-9,]', ''),           -- keep only digits + comma
           ',', '.'                                                 -- convert decimal comma to dot
         )
       ) AS advertising
FROM 

-- monthly sales table from jan 24 - june 24 
demo_db.gtm_case.expenses_salary_and_commissions a 

LEFT JOIN 
-- monthly ad spend from jan 24 - jun 24 
DEMO_DB.GTM_CASE.EXPENSES_ADVERTISING b 
ON a.month = b.month 
)

SELECT 
    month
    , outbound_sales
    , inbound_sales
    , advertising
    , (outbound_sales + inbound_sales + advertising) AS total_cac
FROM ad_spend_and_sales