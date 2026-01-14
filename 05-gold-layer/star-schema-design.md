# Gold Layer - Star Schema Design

## Purpose
Transform Silver layer data into analytics-ready star schema optimized for BI reporting and analysis.

## Architecture
```
Silver Lakehouse (Delta tables)
    ↓ (dbt models - T-SQL)
Gold Warehouse (Star schema - Delta tables)
```

## Star Schema Design

### Schema Diagram
```
           dim_date
               |
               |
dim_customer---fact_sales---dim_product
```

## Dimensional Model

### Fact Table: fact_sales

**Grain:** One row per order line item (SalesOrderDetailID level)

**Measures:**
- `order_qty` - Quantity ordered
- `unit_price` - Price per unit at time of sale
- `line_total` - Extended amount (qty × unit_price)
- `subtotal` - Order subtotal (from header)
- `tax_amt` - Tax amount (from header)
- `total_due` - Total order amount (from header)

**Foreign Keys:**
- `customer_key` → dim_customer
- `product_key` → dim_product
- `order_date_key` → dim_date

**Degenerate Dimensions:**
- `sales_order_id` - Order number (no separate dim)
- `sales_order_detail_id` - Line item ID

**Dates:**
- `order_date` - When order placed
- `due_date` - Expected delivery
- `ship_date` - Actual ship date

**Schema:**
```sql
CREATE TABLE fact_sales (
    sales_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Foreign Keys
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    order_date_key INT NOT NULL,
    -- Degenerate Dimensions
    sales_order_id INT NOT NULL,
    sales_order_detail_id INT NOT NULL,
    -- Measures
    order_qty INT NOT NULL,
    unit_price DECIMAL(19,4) NOT NULL,
    line_total DECIMAL(19,4) NOT NULL,
    subtotal DECIMAL(19,4) NOT NULL,
    tax_amt DECIMAL(19,4) NOT NULL,
    total_due DECIMAL(19,4) NOT NULL,
    -- Dates
    order_date DATE NOT NULL,
    due_date DATE NOT NULL,
    ship_date DATE NULL
);
```

**Expected Rows:** 542 (one per SalesOrderDetail)

---

### Dimension: dim_customer

**Type:** SCD Type 1 (current state only)

**Attributes:**
- Customer demographics
- Contact information
- Company affiliation

**Schema:**
```sql
CREATE TABLE dim_customer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL UNIQUE,  -- business key
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    email_address NVARCHAR(50),
    company_name NVARCHAR(128),
    -- Audit
    load_timestamp DATETIME2
);
```

**Expected Rows:** 847

**Why SCD Type 1:**
- Source data is snapshot (single day)
- No historical changes to track
- Simplifies queries

---

### Dimension: dim_product

**Type:** SCD Type 1 (current state only)

**Attributes:**
- Product details
- Category hierarchy (denormalized)
- Pricing information

**Schema:**
```sql
CREATE TABLE dim_product (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL UNIQUE,  -- business key
    product_name NVARCHAR(50),
    product_number NVARCHAR(25),
    color NVARCHAR(15),
    size NVARCHAR(5),
    list_price DECIMAL(19,4),
    -- Category (denormalized)
    category_id INT,
    category_name NVARCHAR(50),
    parent_category_id INT,
    parent_category_name NVARCHAR(50),
    -- Audit
    load_timestamp DATETIME2
);
```

**Expected Rows:** 295

**Design Decision - Denormalized Categories:**
- ✅ Avoid snowflake complexity
- ✅ Faster queries (no category joins)
- ✅ Small category count (41 rows)
- ⚠️ Slight data redundancy acceptable

---

### Dimension: dim_date

**Type:** Generated dimension (no source table)

**Attributes:**
- Calendar hierarchy
- Fiscal periods (optional)
- Business day flags

**Schema:**
```sql
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,  -- YYYYMMDD format
    full_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name NVARCHAR(10) NOT NULL,
    week_of_year INT NOT NULL,
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name NVARCHAR(10) NOT NULL,
    is_weekend BIT NOT NULL,
    is_holiday BIT NULL  -- future enhancement
);
```

**Date Range:** 2008-01-01 to 2010-12-31 (3 years = 1,096 rows)

**Why 3 years:**
- Source data: 2008-06-01
- Buffer before/after for analysis flexibility
- Small enough to generate quickly

**date_key Format:** YYYYMMDD (e.g., 20080601)
- ✅ Readable integer
- ✅ Sortable naturally
- ✅ Standard BI pattern

---

## Design Decisions

### Warehouse vs Lakehouse for Gold

**Chosen: Warehouse**

**Reasons:**
- ✅ Heavy Power BI usage (Direct Lake optimized)
- ✅ T-SQL familiarity for BI team
- ✅ Better BI tool integration
- ✅ Separate compute scaling from storage
- ✅ dbt-fabric supports Warehouse targets

---

### dbt vs Native Fabric Approaches

**Chosen: dbt Core + dbt-fabric adapter**

**Reasons:**
- ✅ Version control for SQL transformations
- ✅ Automated testing framework
- ✅ Documentation generation
- ✅ Dependency management (DAG)
- ✅ Industry standard tool

**Alternative considered:**
- Warehouse stored procedures (less portable, no testing framework)
- Fabric notebooks with Spark SQL (wrong engine for Warehouse)

---

### Slowly Changing Dimensions Strategy

**Chosen: SCD Type 1 (overwrite)**

**Reasons:**
- Source is snapshot data (2008-06-01)
- No historical changes exist to track
- Simplifies fact table grain

**For production with change tracking:**
```sql
-- SCD Type 2 pattern (future)
ALTER TABLE dim_customer ADD (
    effective_date DATE NOT NULL,
    end_date DATE NULL,
    is_current BIT NOT NULL DEFAULT 1
);
```

---

### Fact Table Grain Analysis

**Considered Options:**

| Grain | Pros | Cons | Choice |
|-------|------|------|--------|
| Order Header | Simple | Loses line-item detail | ❌ |
| Order Line Item | Full detail | Slightly larger | ✅ Selected |
| Daily aggregates | Fast queries | Loses transaction detail | ❌ |

**Decision:** Order line item grain
- Preserves maximum analytical flexibility
- Allows product-level analysis
- Small dataset (542 rows) - no performance concern

---

### Surrogate Keys vs Natural Keys

**Pattern:** Surrogate keys for all dimensions

**Benefits:**
- ✅ Supports future SCD Type 2 (multiple versions)
- ✅ Isolates DW from source system changes
- ✅ Smaller fact table FK size (INT vs composite)
- ✅ Industry best practice

**Implementation:**
```sql
customer_key INT IDENTITY(1,1)  -- surrogate
customer_id INT NOT NULL        -- natural/business key
```

---

## Data Lineage

### dim_customer
```
Silver: customer_silver
  → Gold: dim_customer
     Transformations: Select relevant columns, business key preserved
```

### dim_product
```
Silver: product_silver + productcategory_silver
  → Gold: dim_product
     Transformations: Join categories, denormalize hierarchy
```

### dim_date
```
Generated via dbt macro (no source)
  → Gold: dim_date
     Transformations: Date range 2008-2010, calculated attributes
```

### fact_sales
```
Silver: salesorderheader_silver + salesorderdetail_silver
  → Gold: fact_sales
     Transformations: Join header+detail, lookup dimension keys
```

---

## Performance Optimization

### Indexing Strategy (Future - Phase 2)
```sql
-- Fact table indexes
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_product ON fact_sales(product_key);
CREATE INDEX idx_fact_date ON fact_sales(order_date_key);

-- Dimension indexes (auto-created on PK)
-- customer_key, product_key, date_key already indexed
```

### Partitioning (Not needed)
- Dataset too small (542 fact rows)
- Single date snapshot
- Future: Partition by order_date when data grows

### Statistics (Auto-managed by Fabric Warehouse)
- Column statistics updated automatically
- Query optimizer uses for execution plans

---

## Data Quality Rules

### Fact Table
- ✅ All FKs must match dimension keys (referential integrity)
- ✅ Measures > 0 (order_qty, unit_price, line_total)
- ✅ line_total = order_qty × unit_price (business rule)
- ✅ total_due = subtotal + tax_amt (business rule)
- ✅ No NULL in measures or date columns

### Dimensions
- ✅ Unique business keys (customer_id, product_id, date)
- ✅ No NULL in key attributes (names, dates)
- ✅ Valid date ranges in dim_date

**dbt tests implement these validations**

---

## Verification Queries

### Row Count Validation
```sql
-- Expected counts
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dim_product
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;

-- Expected results:
-- dim_customer: 847
-- dim_product: 295
-- dim_date: 1,096
-- fact_sales: 542
```

### Referential Integrity Check
```sql
-- Orphan fact rows (should be 0)
SELECT COUNT(*) AS orphan_customers
FROM fact_sales f
LEFT JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

SELECT COUNT(*) AS orphan_products
FROM fact_sales f
LEFT JOIN dim_product p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

SELECT COUNT(*) AS orphan_dates
FROM fact_sales f
LEFT JOIN dim_date d ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL;
```

### Business Rule Validation
```sql
-- Line total calculation check
SELECT COUNT(*) AS calculation_errors
FROM fact_sales
WHERE ABS(line_total - (order_qty * unit_price)) > 0.01;

-- Should return 0
```

---

## Cost Impact

### Storage
- Dimensions: ~1 MB total
- Fact table: ~50 KB
- Total Gold layer: ~1 MB

### Compute
- dbt run: ~0.3 CU per execution
- Query performance: Sub-second (small dataset)

---

## Phase 2 Enhancements

1. **Advanced Dimensions:**
   - Customer segmentation (RFM analysis)
   - Product profitability metrics
   - Fiscal calendar in dim_date

2. **Additional Facts:**
   - fact_customer_summary (aggregated metrics)
   - fact_product_sales (daily aggregates)

3. **SCD Type 2:**
   - Track customer address changes
   - Track product price changes

4. **Aggregations:**
   - Pre-aggregated fact tables for performance
   - Materialized views for common queries

---

## References
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Fabric Warehouse Documentation](https://learn.microsoft.com/en-us/fabric/data-warehouse/)