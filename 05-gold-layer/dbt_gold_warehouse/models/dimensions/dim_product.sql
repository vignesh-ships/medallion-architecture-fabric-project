{{ config(
    materialized='table'
) }}

WITH stg_product AS (
    SELECT * FROM {{ ref('stg_product') }}
),

stg_category AS (
    SELECT * FROM {{ ref('stg_product_category') }}
),

-- Self-join for parent category
parent_category AS (
    SELECT
        c.category_id,
        c.category_name,
        c.parent_category_id,
        p.category_name AS parent_category_name
    FROM stg_category c
    LEFT JOIN stg_category p ON c.parent_category_id = p.category_id
)

SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_key,
    p.product_id,
    p.product_name,
    p.product_number,
    p.color,
    p.size,
    p.list_price,
    c.category_id,
    c.category_name,
    c.parent_category_id,
    c.parent_category_name,
    p.load_timestamp
FROM stg_product p
LEFT JOIN parent_category c ON p.category_id = c.category_id