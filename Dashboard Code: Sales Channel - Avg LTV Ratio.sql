WITH -- gathering all of the relevant cohort data
cohort AS (
    SELECT
        account_id,
        first_contact_month as cohort_month,
        closed_month,
        predicted_sales as first_year_value,
        sales_channel
    FROM
        DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_OPPORTUNITY_FUNNEL
),
-- monthly spend
-- assuming half advertising is going to both inbound and outbounc
Monthly_CAC AS (
    SELECT
        TO_CHAR(TO_DATE(month, 'MON-YY'), 'MM-YY') as cohort_month,
        outbound_sales + (advertising / 2) as outbound_total,
        inbound_sales + (advertising / 2) as inbound_total
    FROM
        DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_AD_AND_SALES_DATA
),
-- counting new customers per month
customers_per_month AS (
    SELECT
        cohort_month,
        sales_channel,
        count(*) as new_customers
    FROM
        cohort
    group by
        1,
        2
),
-- cac per customer
-- inboundvs outbound
cac_per_customer AS (
    SELECT
        c.cohort_month,
        c.sales_channel,
        m.outbound_total,
        m.inbound_total,
        c.new_customers,
        CASE
            WHEN c.sales_channel ilike 'Inbound' THEN m.inbound_total / NULLIF(c.new_customers, 0)
            WHEN c.sales_channel ilike 'Outbound' THEN m.outbound_total / NULLIF(c.new_customers, 0)
            ELSE null
        end AS cac
    FROM
        customers_per_month c
        LEFT JOIN monthly_cac m ON c.cohort_month = m.cohort_month
),
-- lifetmie value
ltv AS (
    SELECT
        cohort_month,
        sales_channel,
        avg(first_year_value * 2) as avg_ltv
    FROM
        cohort
    group by
        1,
        2
) ,

Final_v2 AS (
SELECT
    c.cohort_month
    , c.sales_channel
    , c.new_customers
    , c.cac
    , l.avg_ltv AS ltv
    , l.avg_ltv / NULLIF(c.cac, 0) AS ltv_ratio
FROM
    cac_per_customer c
LEFT JOIN 
    ltv l USING (cohort_month, sales_channel)
WHERE 
    ltv_ratio is not null 
ORDER BY
    cohort_month
    , sales_channel
)
SELECT 
    sales_channel
    , avg(cac) as avg_cac
    , avg(ltv) as avg_ltv
    , avg(ltv_ratio) as avg_ltv_ratio
FROM 
    final_v2
GROUP BY 1
