{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT
        SalesOrderID,
        SalesOrderDetailID,
        ProductID,
        OrderQty,
        UnitPrice,
        LineTotal
    FROM {{ source('silver_lakehouse', 'salesorderdetail_silver') }}
)

SELECT
    SalesOrderID AS sales_order_id,
    SalesOrderDetailID AS sales_order_detail_id,
    ProductID AS product_id,
    OrderQty AS order_qty,
    CAST(UnitPrice AS DECIMAL(19,4)) AS unit_price,
    CAST(LineTotal AS DECIMAL(19,4)) AS line_total
FROM source