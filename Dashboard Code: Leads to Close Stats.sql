WITH 

dash AS (
SELECT
    first_contact_month as period
    , leads
    , conversions as lead_conversions
    , ROUND(100.00*(conversions/leads),2) as lead_conversion_rate
    , account_total as customers_obtained
    , ROUND(100.00*(account_total/conversions),2) as opp_conversion_rate
    , demos_total
    , ROUND(100.00*(demos_total /customers_obtained),2) as demo_conversion_rate

    
    FROM 
    DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._PROD_LEAD_OPP_SALES_STATS

)  
select * from dash ORDER BY
    TO_DATE(period, 'MON-YY') ASC; -- Convert string back to date for ordering
