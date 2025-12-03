CREATE OR REPLACE TABLE DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._dev_Opportunity_Funnel AS

-- want to normalize all of the lead datat to make it readable
-- going to change the column types and make the raw data readable 
WITH 

-- cte will simplifiy the lead data 
lead_data_raw AS (
select 
TO_VARCHAR(TO_DATE(COALESCE(form_submission_date, first_sales_call_date, first_text_sent_date )), 'MM-YY') as first_contact_month
, form_submission_date
, lead_id
, IFF(converted_opportunity_id IS NULL, FALSE, TRUE) AS is_converted
, converted_opportunity_id
, connected_with_decision_maker
, TO_DECIMAL(
         REPLACE(
           REGEXP_REPLACE(predicted_sales_with_owner, '\s', ''),   -- remove any whitespace
           ',', '.'
         )
       ) AS predicted_sales
,   CASE
        WHEN TRIM(REPLACE(REPLACE(REPLACE(marketplaces_used, '[', ''), ']', ''), '''', '')) = '' THEN ''
        ELSE TRIM(REPLACE(REPLACE(REPLACE(marketplaces_used, '[', ''), ']', ''), '''', ''))
    END AS marketplaces_used_clean    
,   CASE 
        WHEN TRIM(REPLACE(REPLACE(REPLACE(online_ordering_used, '[', ''), ']', ''), '''', '')) = '' THEN ''
        ELSE TRIM(REPLACE(REPLACE(REPLACE(online_ordering_used, '[', ''), ']', ''), '''', ''))
    END AS online_ordering_used_clean
,   CASE 
        WHEN TRIM(REPLACE(REPLACE(REPLACE(cuisine_types, '[', ''), ']', ''), '''', '')) = '' THEN ''
        ELSE TRIM(REPLACE(REPLACE(REPLACE(cuisine_types, '[', ''), ']', ''), '''', ''))
    END AS cuisine_types_used_clean
, first_sales_call_date
, last_sales_activity_date
, last_sales_call_date
, sales_call_count

, last_sales_email_date
, sales_email_count

, first_text_sent_date
, sales_text_count

, first_meeting_booked_date
, location_count
, status


FROM 
DEMO_DB.GTM_CASE.LEADS
) ,

-- adding in a case stsment for lead sales channel
lead_data_enriched AS (
SELECT 
CASE WHEN form_submission_date IS NOT NULL THEN 'Inbound'
ELSE 'Outbound' END AS lead_channel

, *

from
    lead_data_raw
),

-- combing lead data with oopporunity data 
opportunity_funnel AS (
SELECT 
    l.*
    , o.*
    , TO_VARCHAR(TO_DATE(o.created_date), 'MM-YY') as opp_created_month
    ,
        CASE 
            WHEN o.how_did_you_hear_about_us_c ilike 'cold call' then 'Outbound'
            WHEN 
                (o.how_did_you_hear_about_us_c ilike '%google%' 
                OR o.how_did_you_hear_about_us_c ilike '%facebook%') THEN 'Inbound'
            ELSE 'Undefined' END AS sales_channel
    , TO_VARCHAR(TO_DATE(o.close_date), 'MM-YY') as closed_month
    , TO_VARCHAR(TO_DATE(o.demo_set_date), 'MM-YY') as demo_month
FROM 
    lead_data_enriched l
LEFT JOIN 
    DEMO_DB.GTM_CASE.OPPORTUNITIES o
    ON l.converted_opportunity_id = o.opportunity_id

)


select *
From 
    opportunity_funnel
order by form_submission_date asc
