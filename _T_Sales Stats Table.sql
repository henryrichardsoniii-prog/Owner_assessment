CREATE OR REPLACE TABLE DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._prod_Lead_Opp_Sales_Stats AS

WITH 

-- closed date of opp with relavant stats
closed_opp_stats AS (
SELECT
CONCAT_WS('-', abbrev, '24') as closed_month
, account_total
, demos_total
, opp_predicted_sales
, predicted_rev_take_rate
, predicted_rev_monthly_subscription
FROM 
    (
    select
    distinct closed_month
    , LEFT(TO_CHAR(TO_DATE(closed_month, 'MM-YY'), 'MMMM'), 3) as abbrev
    , count(distinct account_id) as account_total
    , count(demo_set_date) as demos_total
    , sum(predicted_sales) as opp_predicted_sales
    , sum(predicted_sales) * 0.05 as predicted_rev_take_rate
    , 500*count(distinct account_id) as predicted_rev_monthly_subscription
    
    From 
    DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_OPPORTUNITY_FUNNEL
    
    WHERE 
        stage_name ilike 'closed won'
    
    group by 1,2
    order by 1 
    )
-- ORDER BY 1
) ,

-- lead first contact date with relevant stats
lead_stats AS (
select 
CONCAT_WS('-', abbrev, '24') as first_contact_month
, lead_predicted_sales
, leads 
, conversions
, sales_call_count
, sales_email_count
, sales_text_count
from (
    select 
    first_contact_month
    , LEFT(TO_CHAR(TO_DATE(first_contact_month, 'MM-YY'), 'MMMM'), 3) as abbrev
    , sum(predicted_sales) as lead_predicted_sales
    , count(lead_id) as  leads
    , count(converted_opportunity_id) as conversions
    , sum(sales_call_count) as sales_call_count
    , sum(sales_email_count) as sales_email_count
    , sum(sales_text_count) as sales_text_count
    
    from DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_OPPORTUNITY_FUNNEL
    WHERE 
        first_contact_month ilike '%24'
    group by 1,2
    order by 1 
    )
) , 

-- combining leads and opps stats 
Final_Stats AS (
select 
l.first_contact_month
, l.lead_predicted_sales
, l.leads 
, l.conversions
, l.sales_call_count
, l.sales_email_count
, l.sales_text_count
, c.account_total
, c.demos_total
, c.opp_predicted_sales
, c.predicted_rev_take_rate
, c.predicted_rev_monthly_subscription
, s.advertising
, s.inbound_sales
, s.outbound_sales
FROM 
    lead_stats l 
LEFT JOIN 
    closed_opp_stats c 
    ON l.first_contact_month = c.closed_month
LEFT JOIN 
    DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_AD_AND_SALES_DATA s
    ON l.first_contact_month = s.month

)

SELECT 
*
FROM
Final_Stats