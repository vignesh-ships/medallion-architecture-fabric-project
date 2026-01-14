{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT
        SalesOrderID,
        OrderDate,
        DueDate,
        ShipDate,
        CustomerID,
        SubTotal,
        TaxAmt,
        TotalDue
    FROM {{ source('silver_lakehouse', 'salesorderheader_silver') }}
)

SELECT
    SalesOrderID AS sales_order_id,
    CAST(OrderDate AS DATE) AS order_date,
    CAST(DueDate AS DATE) AS due_date,
    CAST(ShipDate AS DATE) AS ship_date,
    CustomerID AS customer_id,
    CAST(SubTotal AS DECIMAL(19,4)) AS subtotal,
    CAST(TaxAmt AS DECIMAL(19,4)) AS tax_amt,
    CAST(TotalDue AS DECIMAL(19,4)) AS total_due
FROM source