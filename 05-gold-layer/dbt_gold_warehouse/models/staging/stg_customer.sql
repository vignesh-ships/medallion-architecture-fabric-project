{{ config(
    materialized='view'
) }}

WITH source AS (
    SELECT
        CustomerID,
        FirstName,
        LastName,
        EmailAddress,
        CompanyName,
        load_timestamp
    FROM {{ source('silver_lakehouse', 'customer_silver') }}
)

SELECT
    CustomerID AS customer_id,
    FirstName AS first_name,
    LastName AS last_name,
    EmailAddress AS email_address,
    CompanyName AS company_name,
    load_timestamp
FROM source