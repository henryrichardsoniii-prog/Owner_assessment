CREATE OR REPLACE TABLE DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._prod_cac_ltv AS

WITH

-- all closed won opps
deals as (
select 
account_id
, closed_month
, predicted_sales as first_year_value
from DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_OPPORTUNITY_FUNNEL
WHERE 
stage_name ilike '%Closed Won'
) ,


-- counting the number of customers that closer per month
customers_per_month AS (

SELECT
    closed_month
    , count(*) as customers_closed
from deals
group by 1 
) ,


monthly_spend AS (
SELECT
TO_CHAR(TO_DATE(month, 'MON-YY'), 'MM-YY') as closed_month
, total_cac

From DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._dev_AD_AND_SALES_DATA
)

,

Final_Data AS (
SELECT
    d.account_id
    , d.closed_month
    , d.first_year_value
    , m.total_cac
    , cpm.customers_closed
    , m.total_cac / NULLIF(cpm.customers_closed,0) AS cac_per_customer
    , first_year_value/6000 as lifetime_years -- monthly rev * yearly rev
    , 12*(first_year_value/6000) as lifetime_months
    , first_year_value*2 AS estimated_ltv
    , cac_per_customer / NULLIF((first_year_value * 2.0),0) AS CAC_LTV_Ratio

FROM 
    deals d
LEFT JOIN 
    customers_per_month cpm
    ON d.closed_month = cpm.closed_month
LEFT JOIN 
    monthly_spend m 
    ON d.closed_month = m.closed_month
)
SELECT
    account_id
    ,closed_month

    ,first_year_value

    -- CAC
    ,cac_per_customer

    -- Lifetime
    ,lifetime_years
    ,lifetime_months

    -- LTV
    ,estimated_ltv 

    -- CAC : LTV ratio
   ,cac_ltv_ratio
   , 
   CASE 
    WHEN (cac_per_customer / NULLIF((first_year_value * 2.0),0)) < 0.33 THEN 'Excellent (1:3 or better)'
    WHEN (cac_per_customer / NULLIF((first_year_value * 2.0),0)) BETWEEN 0.33 AND 0.75 THEN 'Moderate'
    ELSE 'High (Needs work)'
END AS ratio_quality

   FROM Final_Data