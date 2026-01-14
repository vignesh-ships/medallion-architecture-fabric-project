{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT
        ProductCategoryID,
        ParentProductCategoryID,
        Name
    FROM {{ source('silver_lakehouse', 'productcategory_silver') }}
)

SELECT
    ProductCategoryID AS category_id,
    ParentProductCategoryID AS parent_category_id,
    Name AS category_name
FROM source