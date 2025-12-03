WITH -- gathering all of the relevant cohort data
cohort AS (
    SELECT
        account_id,
        first_contact_month as cohort_month,
        closed_month,
        predicted_sales as first_year_value,
    FROM
        DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_OPPORTUNITY_FUNNEL
),
-- monthly spend
-- assuming half advertising is going to both inbound and outbounc
Monthly_CAC AS (
    SELECT
        TO_CHAR(TO_DATE(month, 'MON-YY'), 'MM-YY') as cohort_month,
        total_cac
    FROM
        DEMO_DB.DE_CASE_HENRYRICHARDSON_SCHEMA._DEV_AD_AND_SALES_DATA
),
-- counting new customers per month
customers_per_month AS (
    SELECT
        cohort_month,
        count(*) as new_customers
    FROM
        cohort
    group by
        1
),
-- cac per customer
-- inboundvs outbound
cac_per_customer AS (
    SELECT
        c.cohort_month,
        m.total_cac,
        c.new_customers,
        m.total_cac / NULLIF(c.new_customers, 0)AS cac
    FROM
        customers_per_month c
        LEFT JOIN monthly_cac m ON c.cohort_month = m.cohort_month
),
-- lifetmie value
ltv AS (
    SELECT
        cohort_month,
        avg(first_year_value * 2) as avg_ltv
    FROM
        cohort
    group by
        1
)
SELECT
    c.cohort_month
    , c.new_customers
    , c.cac
    , l.avg_ltv AS ltv
    , l.avg_ltv / NULLIF(c.cac, 0) AS ltv_ratio
FROM
    cac_per_customer c
LEFT JOIN 
    ltv l USING (cohort_month)
WHERE 
    ltv_ratio is not null 
ORDER BY
    cohort_month
