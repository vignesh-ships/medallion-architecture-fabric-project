# Silver Layer - Data Cleansing & Standardization

## Purpose
Transform raw Bronze data into cleaned, validated, and standardized Delta tables for downstream consumption.

## Architecture
```
Bronze Lakehouse (Parquet files)
    ↓ (Fabric Notebook - Spark transformations)
Silver Lakehouse (Delta tables)
```

## Design Decisions

### Storage Format: Delta Lake
**Why Delta over Parquet:**
- ✅ ACID transactions (data consistency)
- ✅ Time travel (version history)
- ✅ Schema enforcement & evolution
- ✅ Efficient upserts & deletes
- ✅ Metadata optimization (faster queries)

**Storage location:** Silver Lakehouse → **Tables section** (managed Delta tables)

### Transformation Strategy: Spark Notebooks
**Why Notebooks over Pipelines:**
- ✅ Complex transformations (joins, aggregations)
- ✅ Data quality checks with Spark SQL
- ✅ Reusable code patterns
- ✅ Interactive development & debugging

**Pattern:** One notebook processes all tables (parameterized by table name)

### Parallel Execution
- Notebook invoked per table from pipeline ForEach loop
- Each table processes independently
- No cross-table dependencies in Silver layer

## Data Transformations

### Applied to All Tables
1. **Add load timestamp:** `load_timestamp` column (audit trail)
2. **Trim whitespace:** String columns cleaned
3. **Lowercase emails:** Standardized format (Customer table)
4. **Deduplication:** Based on business key (e.g., CustomerID)

### Table-Specific Transformations
**Customer:**
- Email standardization (lowercase, trim)
- Name field trimming

**Product:**
- Category join (ProductCategory lookup - future enhancement)
- Price validation (future enhancement)

**SalesOrderHeader & SalesOrderDetail:**
- Date validation (future enhancement)
- Amount calculations verification (future enhancement)

## Delta Table Design

### Customer Silver
```sql
Schema:
- CustomerID (INT) - business key
- FirstName (STRING)
- LastName (STRING)
- EmailAddress (STRING) - lowercased
- CompanyName (STRING)
- ... (all original columns)
- load_timestamp (TIMESTAMP)

Partition: None (small dataset)
Table Properties: 
  - delta.autoOptimize.optimizeWrite = true
  - delta.autoOptimize.autoCompact = true
```

### Product Silver
```sql
Schema:
- ProductID (INT) - business key
- Name (STRING)
- ProductNumber (STRING)
- Color (STRING) - nullable
- Size (STRING) - nullable
- ListPrice (DECIMAL)
- ProductCategoryID (INT)
- ... (all original columns)
- load_timestamp (TIMESTAMP)

Partition: None (295 rows)
```

### ProductCategory Silver
```sql
Schema:
- ProductCategoryID (INT) - business key
- ParentProductCategoryID (INT) - nullable
- Name (STRING)
- load_timestamp (TIMESTAMP)

Partition: None (41 rows)
Hierarchy: Self-referencing for parent-child relationships
```

### SalesOrderHeader Silver
```sql
Schema:
- SalesOrderID (INT) - business key
- OrderDate (DATE)
- DueDate (DATE)
- ShipDate (DATE) - nullable
- CustomerID (INT) - FK to Customer
- SubTotal (DECIMAL)
- TaxAmt (DECIMAL)
- TotalDue (DECIMAL)
- ... (all original columns)
- load_timestamp (TIMESTAMP)

Partition: None (32 rows, single date snapshot)
```

### SalesOrderDetail Silver
```sql
Schema:
- SalesOrderDetailID (INT) - business key
- SalesOrderID (INT) - FK to SalesOrderHeader
- ProductID (INT) - FK to Product
- OrderQty (INT)
- UnitPrice (DECIMAL)
- LineTotal (DECIMAL)
- load_timestamp (TIMESTAMP)

Partition: None (542 rows)
Grain: One row per product per order
```

## Data Quality Checks (Current)

### Implemented
- ✅ Basic deduplication (implicit via overwrite mode)
- ✅ Timestamp audit trail

### Not Implemented (Phase 2)
- ⚠️ Row count validation (Bronze vs Silver)
- ⚠️ Null checks on critical columns
- ⚠️ Schema validation
- ⚠️ Referential integrity checks
- ⚠️ Data type validation
- ⚠️ Business rule validation (e.g., TotalDue = SubTotal + TaxAmt)

## Performance Characteristics
- **Execution time:** ~30 seconds per table (parallel)
- **Total Silver processing:** ~30 seconds (all 5 tables in parallel)
- **Data volume:** ~1,750 rows total
- **CU consumption:** ~0.2 CU per run
- **Delta file size:** ~10-50 KB per table

## Write Strategy
- **Mode:** Overwrite (full refresh)
- **Reason:** Snapshot data, no incremental updates needed
- **Idempotent:** Safe to re-run multiple times

**For production incremental loads:**
```python
# Future pattern - merge/upsert
df.write \
  .format("delta") \
  .mode("merge") \
  .option("mergeSchema", "true") \
  .saveAsTable("customer_silver")
```

## Metadata Management
- **Delta log:** Tracks all write operations
- **Version history:** Accessible via time travel
- **Schema evolution:** Enabled for future changes

**Time travel example:**
```python
# Read previous version
df = spark.read.format("delta") \
  .option("versionAsOf", 0) \
  .table("customer_silver")
```

## OneLake Path Structure
```
silver_lakehouse/
└── Tables/
    ├── customer_silver/
    │   └── _delta_log/
    ├── product_silver/
    │   └── _delta_log/
    ├── productcategory_silver/
    │   └── _delta_log/
    ├── salesorderheader_silver/
    │   └── _delta_log/
    └── salesorderdetail_silver/
        └── _delta_log/
```

## Data Lineage
```
Bronze: customer.parquet → Silver: customer_silver (Delta)
Bronze: product.parquet → Silver: product_silver (Delta)
Bronze: productcategory.parquet → Silver: productcategory_silver (Delta)
Bronze: salesorderheader.parquet → Silver: salesorderheader_silver (Delta)
Bronze: salesorderdetail.parquet → Silver: salesorderdetail_silver (Delta)
```

## Error Handling (Current)
- **Spark errors:** Fail fast, no retry logic
- **Logging:** Basic Spark logs only
- **Monitoring:** Pipeline-level status only

**Phase 2 enhancements:**
- Try-catch blocks per table
- Custom logging to Delta table
- Data quality metrics logging
- Email/Teams alerts on failure

## Verification Checklist
- [x] All 5 Delta tables created in Silver lakehouse
- [x] Tables section (not Files section) used
- [x] load_timestamp column present
- [x] Delta format confirmed (check _delta_log folder)
- [x] Row counts match Bronze source

## Cost Impact
- **Storage:** Negligible (~50 KB total)
- **Compute:** ~0.2 CU per run (~$0.002 on F64 capacity)
- **Delta optimization:** Auto-compaction enabled (minimal overhead)

## Phase 2 Enhancements
1. **Data quality framework:**
   - Great Expectations integration
   - Custom validation rules
   - Quality metrics dashboard

2. **Incremental processing:**
   - Watermark-based merges
   - Change data capture (CDC)
   - Slowly Changing Dimensions (SCD Type 2)

3. **Schema evolution:**
   - Automated schema drift detection
   - Schema registry integration

4. **Advanced transformations:**
   - Product-Category denormalization
   - Customer segmentation
   - Order aggregation metrics

## References
- [Delta Lake Documentation](https://docs.delta.io/)
- [Fabric Spark Documentation](https://learn.microsoft.com/en-us/fabric/data-engineering/spark-overview)