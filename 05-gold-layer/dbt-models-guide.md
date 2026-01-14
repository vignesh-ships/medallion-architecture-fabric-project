# dbt Models - Star Schema Implementation

## dbt Project Structure
```
dbt_gold_warehouse/
├── models/
│   ├── staging/
│   │   ├── stg_customer.sql
│   │   ├── stg_product.sql
│   │   ├── stg_product_category.sql
│   │   ├── stg_sales_order_header.sql
│   │   └── stg_sales_order_detail.sql
│   ├── dimensions/
│   │   ├── dim_customer.sql
│   │   ├── dim_product.sql
│   │   └── dim_date.sql
│   ├── facts/
│   │   └── fact_sales.sql
│   └── schema.yml (tests & documentation)
├── macros/
│   └── generate_date_dimension.sql
├── tests/
├── dbt_project.yml
└── README.md
```

---

## Layer 1: Staging Models

### Purpose
- Read from Silver lakehouse (via SQL endpoint)
- Light transformations (aliasing, type casting)
- Foundation for dimensional models

---

### stg_customer.sql
```sql
{{ config(
    materialized='view',
    schema='staging'
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
```

---

### stg_product.sql
```sql
{{ config(
    materialized='view',
    schema='staging'
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
```

---

### stg_product_category.sql
```sql
{{ config(
    materialized='view',
    schema='staging'
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
```

---

### stg_sales_order_header.sql
```sql
{{ config(
    materialized='view',
    schema='staging'
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
```

---

### stg_sales_order_detail.sql
```sql
{{ config(
    materialized='view',
    schema='staging'
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
```

---

## Layer 2: Dimension Models

### dim_customer.sql
```sql
{{ config(
    materialized='table',
    schema='dbo'
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
```

---

### dim_product.sql
```sql
{{ config(
    materialized='table',
    schema='dbo'
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
```

---

### dim_date.sql
```sql
{{ config(
    materialized='table',
    schema='dbo'
) }}

-- Generate date dimension using macro
{{ generate_date_dimension(
    start_date='2008-01-01',
    end_date='2010-12-31'
) }}
```

---

## Layer 3: Fact Model

### fact_sales.sql
```sql
{{ config(
    materialized='table',
    schema='dbo'
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
```

---

## Macros

### macros/generate_date_dimension.sql
```sql
{% macro generate_date_dimension(start_date, end_date) %}

WITH date_spine AS (
    -- Generate date series
    SELECT CAST('{{ start_date }}' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM date_spine
    WHERE full_date < CAST('{{ end_date }}' AS DATE)
)

SELECT
    -- date_key in YYYYMMDD format
    CAST(FORMAT(full_date, 'yyyyMMdd') AS INT) AS date_key,
    full_date,
    YEAR(full_date) AS year,
    DATEPART(QUARTER, full_date) AS quarter,
    MONTH(full_date) AS month,
    DATENAME(MONTH, full_date) AS month_name,
    DATEPART(WEEK, full_date) AS week_of_year,
    DAY(full_date) AS day_of_month,
    DATEPART(WEEKDAY, full_date) AS day_of_week,
    DATENAME(WEEKDAY, full_date) AS day_name,
    CASE 
        WHEN DATEPART(WEEKDAY, full_date) IN (1, 7) THEN 1 
        ELSE 0 
    END AS is_weekend
FROM date_spine
OPTION (MAXRECURSION 0)

{% endmacro %}
```

---

## Sources Configuration

### models/sources.yml
```yaml
version: 2

sources:
  - name: silver_lakehouse
    description: "Silver layer Delta tables from Fabric lakehouse"
    database: silver_lakehouse
    schema: dbo
    tables:
      - name: customer_silver
        description: "Cleaned customer data"
        columns:
          - name: CustomerID
            description: "Unique customer identifier"
            tests:
              - unique
              - not_null

      - name: product_silver
        description: "Product catalog data"
        columns:
          - name: ProductID
            tests:
              - unique
              - not_null

      - name: productcategory_silver
        description: "Product category hierarchy"
        columns:
          - name: ProductCategoryID
            tests:
              - unique
              - not_null

      - name: salesorderheader_silver
        description: "Order header information"
        columns:
          - name: SalesOrderID
            tests:
              - unique
              - not_null

      - name: salesorderdetail_silver
        description: "Order line item details"
        columns:
          - name: SalesOrderDetailID
            tests:
              - unique
              - not_null
```

---

## Schema Tests & Documentation

### models/schema.yml
```yaml
version: 2

models:
  - name: dim_customer
    description: "Customer dimension with demographic information"
    columns:
      - name: customer_key
        description: "Surrogate key"
        tests:
          - unique
          - not_null
      - name: customer_id
        description: "Business key from source system"
        tests:
          - unique
          - not_null
      - name: email_address
        description: "Customer email (lowercase standardized)"
        tests:
          - not_null

  - name: dim_product
    description: "Product dimension with category hierarchy"
    columns:
      - name: product_key
        description: "Surrogate key"
        tests:
          - unique
          - not_null
      - name: product_id
        description: "Business key from source system"
        tests:
          - unique
          - not_null
      - name: list_price
        description: "Product list price"
        tests:
          - not_null

  - name: dim_date
    description: "Date dimension (2008-2010)"
    columns:
      - name: date_key
        description: "Surrogate key in YYYYMMDD format"
        tests:
          - unique
          - not_null
      - name: full_date
        description: "Actual date value"
        tests:
          - unique
          - not_null

  - name: fact_sales
    description: "Sales fact table at order line item grain"
    columns:
      - name: sales_key
        description: "Surrogate key"
        tests:
          - unique
          - not_null
      - name: customer_key
        description: "Foreign key to dim_customer"
        tests:
          - not_null
          - relationships:
              to: ref('dim_customer')
              field: customer_key
      - name: product_key
        description: "Foreign key to dim_product"
        tests:
          - not_null
          - relationships:
              to: ref('dim_product')
              field: product_key
      - name: order_date_key
        description: "Foreign key to dim_date"
        tests:
          - not_null
          - relationships:
              to: ref('dim_date')
              field: date_key
      - name: order_qty
        description: "Quantity ordered"
        tests:
          - not_null
      - name: line_total
        description: "Extended amount"
        tests:
          - not_null
```

---

## Running dbt Models

### Build All Models
```bash
cd dbt_gold_warehouse

# Run all models
dbt run

# Expected output:
# Running with dbt=1.8.x
# Found 9 models, 15 tests, 0 snapshots, 0 analyses, 1 macro
# 
# Completed successfully
```

### Build Specific Models
```bash
# Run only dimensions
dbt run --select dimensions.*

# Run only facts
dbt run --select facts.*

# Run specific model
dbt run --select dim_customer
```

### Run Tests
```bash
# Test all models
dbt test

# Test specific model
dbt test --select dim_customer
```

### Generate Documentation
```bash
# Generate docs
dbt docs generate

# Serve docs locally
dbt docs serve
```

**Opens browser:** http://localhost:8080 with interactive lineage graph

---

## Verification Queries

### Check Row Counts
```sql
-- Run in gold_warehouse SQL endpoint
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dbo.fact_sales;
```

**Expected:**
- dim_customer: 847
- dim_product: 295
- dim_date: 1,096
- fact_sales: 542

---

### Test Star Schema Join
```sql
SELECT TOP 10
    c.first_name + ' ' + c.last_name AS customer_name,
    p.product_name,
    d.full_date AS order_date,
    f.order_qty,
    f.line_total
FROM dbo.fact_sales f
INNER JOIN dbo.dim_customer c ON f.customer_key = c.customer_key
INNER JOIN dbo.dim_product p ON f.product_key = p.product_key
INNER JOIN dbo.dim_date d ON f.order_date_key = d.date_key
ORDER BY f.sales_key;
```

---

## Troubleshooting

**Issue:** Source table not found
```
Error: Relation silver_lakehouse.dbo.customer_silver not found
Solution: Verify SQL endpoint connection in profiles.yml, check lakehouse name
```

**Issue:** MAXRECURSION error in date dimension
```
Error: Maximum recursion exceeded
Solution: Macro already includes OPTION (MAXRECURSION 0) - check syntax
```

**Issue:** Foreign key test fails
```
Error: Referential integrity test failed
Solution: Check dimension loaded before fact, verify join keys match
```

---

## Performance Notes
- Staging: Views (no storage cost, computed on-demand)
- Dimensions: Tables (materialized for performance)
- Facts: Tables (materialized for performance)
- Expected dbt run time: ~2 minutes (first run), ~30 seconds (subsequent)

---

## Git Commit Structure
```
05-gold-layer/
└── dbt_gold_warehouse/
    ├── models/
    │   ├── staging/
    │   ├── dimensions/
    │   ├── facts/
    │   ├── sources.yml
    │   └── schema.yml
    ├── macros/
    ├── dbt_project.yml
    └── README.md
```

**Exclude from Git:**
- target/
- dbt_packages/
- logs/
- profiles.yml (already in ~/.dbt/)

## References
- [dbt Model Documentation](https://docs.getdbt.com/docs/build/models)
- [dbt Testing Guide](https://docs.getdbt.com/docs/build/tests)
- [dbt Jinja Functions](https://docs.getdbt.com/reference/dbt-jinja-functions)