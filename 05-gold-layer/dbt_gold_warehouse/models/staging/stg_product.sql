{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT
        ProductID,
        Name,
        ProductNumber,
        Color,
        Size,
        ListPrice,
        ProductCategoryID,
        load_timestamp
    FROM {{ source('silver_lakehouse', 'product_silver') }}
)

SELECT
    ProductID AS product_id,
    Name AS product_name,
    ProductNumber AS product_number,
    Color AS color,
    Size AS size,
    CAST(ListPrice AS DECIMAL(19,4)) AS list_price,
    ProductCategoryID AS category_id,
    load_timestamp
FROM source