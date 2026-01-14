{{ config(
    materialized='table'
) }}

WITH stg_customer AS (
    SELECT * FROM {{ ref('stg_customer') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    customer_id,
    first_name,
    last_name,
    email_address,
    company_name,
    load_timestamp
FROM stg_customer