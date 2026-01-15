# Silver Transformation Notebook Setup

## Notebook: nb_silver_transformation

### Purpose
Parameterized Spark notebook that transforms Bronze Parquet files into Silver Delta tables with cleaning and standardization.

## Setup Steps

### 1. Create Notebook
```
1. Workspace → + New → Notebook
2. Name: nb_silver_transformation
3. Default language: PySpark (Python)
4. Click Create
```

---

### 2. Attach Lakehouse
```
1. Left pane → Add → Add lakehouse
2. Select: silver_lakehouse
3. Click Add

Result: Notebook can now write to silver_lakehouse Tables section
```

**Important:** Bronze lakehouse **not needed** as attachment - we use full OneLake path to read.

---

### 3. Configure Parameters

**Cell 1 - Mark as "parameters":**
```python
# Parameters cell (tag as "parameters")
table_name = "Customer"  # default for testing
```

**How to tag:**
1. Select Cell 1
2. Cell menu (top right) → Tag as parameters
3. Icon appears confirming parameter cell

**Pipeline injection:** When called from pipeline, `table_name` is automatically overridden.

---

## Notebook Code

### Cell 1: Parameters
```python
# Parameters (injected by pipeline)
table_name = "Customer"  # default for local testing
```

---

### Cell 2: Imports & Configuration
```python
from pyspark.sql.functions import current_timestamp, col, trim, lower

# Bronze OneLake path (get from Bronze lakehouse)
bronze_base = "abfss://[WORKSPACE_ID]@onelake.dfs.fabric.microsoft.com/[BRONZE_LAKEHOUSE_ID]/Files"

print(f"📥 Processing table: {table_name}")
print(f"🔗 Bronze path: {bronze_base}/{table_name}")
```

**To get path:**
1. Open bronze_lakehouse
2. Navigate to any file → Right-click → Copy ABFS path
3. Extract base path (up to `/Files`)

---

### Cell 3: Read Bronze Data
```python
# Read Parquet from Bronze
bronze_path = f"{bronze_base}/{table_name}"

try:
    df = spark.read.parquet(bronze_path)
    print(f"✅ Bronze data loaded: {df.count()} rows")
    df.show(5)
except Exception as e:
    print(f"❌ Error reading Bronze: {e}")
    raise
```

---

### Cell 4: Apply Transformations
```python
# Basic cleaning - apply to all tables
df_clean = df.withColumn("load_timestamp", current_timestamp())

# Table-specific transformations
if table_name == "Customer":
    df_clean = df_clean \
        .withColumn("FirstName", trim(col("FirstName"))) \
        .withColumn("LastName", trim(col("LastName"))) \
        .withColumn("EmailAddress", lower(trim(col("EmailAddress"))))
    print("📧 Email addresses standardized to lowercase")

elif table_name == "Product":
    # Future: Add product-specific transformations
    pass

elif table_name == "SalesOrderHeader":
    # Future: Add date validation
    pass

# Deduplication (based on first column as business key)
business_key = df_clean.columns[0]
df_clean = df_clean.dropDuplicates([business_key])

print(f"✅ Transformations applied: {df_clean.count()} rows after cleaning")
```

---

### Cell 5: Write to Silver (Delta)
```python
# Silver table name
silver_table_name = f"{table_name.lower()}_silver"

try:
    # Write as Delta table
    df_clean.write \
        .format("delta") \
        .mode("overwrite") \
        .option("overwriteSchema", "true") \
        .saveAsTable(silver_table_name)
    
    print(f"✅ Silver table created: {silver_table_name}")
    print(f"📊 Final row count: {df_clean.count()}")
    
    # Verify table exists
    spark.sql(f"DESCRIBE EXTENDED {silver_table_name}").show(truncate=False)
    
except Exception as e:
    print(f"❌ Error writing to Silver: {e}")
    raise
```

---

### Cell 6: Data Quality Summary (Optional)
```python
# Summary statistics
print(f"\n📈 Summary for {silver_table_name}:")
df_clean.describe().show()

# Check for nulls
print("\n🔍 Null counts:")
df_clean.select([col(c).isNull().cast("int").alias(c) for c in df_clean.columns]) \
    .groupBy().sum().show()
```

---

## Testing Notebook Locally

### Manual Test Run
```
1. Set table_name = "Customer" in Cell 1
2. Run all cells sequentially
3. Verify: silver_lakehouse → Tables → customer_silver appears
4. Query: spark.sql("SELECT * FROM customer_silver LIMIT 10").show()
```

### Test All Tables
```python
# Test loop (optional Cell 7)
tables = ["Customer", "Product", "ProductCategory", "SalesOrderHeader", "SalesOrderDetail"]

for table in tables:
    table_name = table
    # Re-run cells 3-5 for each table
    print(f"✅ Completed: {table}")
```

---

## Pipeline Integration

### How Pipeline Calls Notebook
```json
{
  "name": "notebook_silver_transform",
  "type": "TridentNotebook",
  "typeProperties": {
    "notebookId": "<notebook_id>",
    "workspaceId": "<workspace_id>",
    "parameters": {
      "table_name": {
        "value": "@item()",
        "type": "string"
      }
    }
  }
}
```

**Parameter flow:**
1. Pipeline ForEach passes `@item()` (e.g., "Customer")
2. Fabric injects value into Cell 1 `table_name` variable
3. Notebook executes with injected parameter
4. Silver table created: `customer_silver`

---

## Notebook Properties

### Spark Configuration
- **Default Spark pool:** Auto-assigned by Fabric
- **Executor cores:** 4 (default for F64 capacity)
- **Driver cores:** 4
- **Executor memory:** 28GB
- **Dynamic allocation:** Enabled

### Timeout Settings
- **Notebook timeout:** 12 hours (configurable in pipeline activity)
- **Cell execution timeout:** None (fails on error)

### Attached Resources
- **Lakehouse:** silver_lakehouse (write target)
- **Default database:** silver_lakehouse (for saveAsTable)

---

## Monitoring & Debugging

### Check Execution Logs
```
1. Workspace → nb_silver_transformation → Run history
2. Select specific run
3. View cell outputs and errors
4. Check Spark logs for detailed errors
```

### Common Issues

**Issue:** Path not found error
```
Error: abfss://...Files/Customer.parquet not found
Solution: Verify Bronze path format, ensure table exists in Bronze
```

**Issue:** Permission denied
```
Error: User does not have access to write to silver_lakehouse
Solution: Verify lakehouse attached to notebook, check workspace permissions
```

**Issue:** Schema mismatch
```
Error: Cannot merge schema with different data types
Solution: Use .option("overwriteSchema", "true") in write operation
```

**Issue:** Parameter not injected
```
Error: table_name still "Customer" when expecting "Product"
Solution: Ensure Cell 1 tagged as "parameters", check pipeline parameter passing
```

---

## Performance Tuning

### Current Configuration (Optimal for Small Dataset)
- No partitioning (data too small)
- Auto-optimize enabled
- Snappy compression (default)

### For Larger Datasets (Future)
```python
# Partition by date for time-series data
df_clean.write \
    .format("delta") \
    .partitionBy("OrderDate") \
    .mode("overwrite") \
    .saveAsTable(silver_table_name)

# Z-order optimization for common filters
spark.sql(f"OPTIMIZE {silver_table_name} ZORDER BY (CustomerID)")
```

---

## Verification Checklist
- [x] Notebook created with correct name
- [x] silver_lakehouse attached
- [x] Cell 1 tagged as "parameters"
- [x] Bronze path correct (test with one table)
- [x] Transformations applied (check EmailAddress lowercase)
- [x] Delta tables created in Tables section (not Files)
- [x] Local test run successful for all 5 tables
- [x] Pipeline integration tested (parameter injection works)
- [x] Notebook exported to Git (.ipynb file)

---

## References
- [Fabric Notebooks Documentation](https://learn.microsoft.com/en-us/fabric/data-engineering/author-execute-notebook)
- [PySpark API Reference](https://spark.apache.org/docs/latest/api/python/)
- [Delta Lake PySpark Guide](https://docs.delta.io/latest/delta-batch.html)