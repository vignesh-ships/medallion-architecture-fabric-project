{{ config(
    materialized='table'
) }}

WITH stg_header AS (
    SELECT * FROM {{ ref('stg_sales_order_header') }}
),

stg_detail AS (
    SELECT * FROM {{ ref('stg_sales_order_detail') }}
),

dim_customer AS (
    SELECT customer_key, customer_id FROM {{ ref('dim_customer') }}
),

dim_product AS (
    SELECT product_key, product_id FROM {{ ref('dim_product') }}
),

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

-- Join header and detail
sales_data AS (
    SELECT
        d.sales_order_id,
        d.sales_order_detail_id,
        h.customer_id,
        d.product_id,
        h.order_date,
        h.due_date,
        h.ship_date,
        d.order_qty,
        d.unit_price,
        d.line_total,
        h.subtotal,
        h.tax_amt,
        h.total_due
    FROM stg_detail d
    INNER JOIN stg_header h ON d.sales_order_id = h.sales_order_id
)

SELECT
    ROW_NUMBER() OVER (ORDER BY s.sales_order_detail_id) AS sales_key,
    -- Foreign Keys
    c.customer_key,
    p.product_key,
    d.date_key AS order_date_key,
    -- Degenerate Dimensions
    s.sales_order_id,
    s.sales_order_detail_id,
    -- Measures
    s.order_qty,
    s.unit_price,
    s.line_total,
    s.subtotal,
    s.tax_amt,
    s.total_due,
    -- Dates
    s.order_date,
    s.due_date,
    s.ship_date
FROM sales_data s
INNER JOIN dim_customer c ON s.customer_id = c.customer_id
INNER JOIN dim_product p ON s.product_id = p.product_id
INNER JOIN dim_date d ON s.order_date = d.full_date