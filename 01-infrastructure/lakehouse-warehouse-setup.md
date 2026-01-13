# Lakehouse & Warehouse Setup

## Architecture Overview
```
Bronze Lakehouse (raw data)
    ↓
Silver Lakehouse (cleaned data)
    ↓
Gold Warehouse (star schema)
```

## Setup Steps

### 1. Create Bronze Lakehouse
```
1. Inside workspace → + New → Lakehouse
2. Name: bronze_lakehouse
3. Click Create
4. Wait for provisioning (~30 seconds)
5. Verify: Files and Tables folders created
```

**What gets created:**
- Lakehouse: `bronze_lakehouse`
- SQL analytics endpoint: `bronze_lakehouse` (automatic)
- OneLake path: `abfss://[workspace_id]@onelake.dfs.fabric.microsoft.com/bronze_lakehouse.Lakehouse/`

---

### 2. Create Silver Lakehouse
```
1. Workspace → + New → Lakehouse
2. Name: silver_lakehouse
3. Click Create
```

**Purpose:**
- Stores cleaned Delta tables
- Tables section used (not Files)
- SQL endpoint for querying

---

### 3. Create Gold Warehouse
```
1. Workspace → + New → Warehouse
2. Name: gold_warehouse
3. Click Create
```

**Key Differences (Warehouse vs Lakehouse):**
- T-SQL based (not Spark SQL)
- Optimized for BI workloads
- Better Power BI Direct Lake integration
- Separate compute scaling

---

## Lakehouse vs Warehouse

| Feature | Lakehouse | Warehouse |
|---------|-----------|-----------|
| Storage | OneLake (Files + Tables) | OneLake (Tables only) |
| Query engine | Spark SQL | T-SQL |
| Best for | ETL, Data Science | BI, Reporting |
| Compute | Shared Spark pools | Dedicated SQL compute |
| Format | Delta Lake | Delta Lake |

## Cost Optimization
- ✅ OneLake storage: Included in trial
- ✅ No idle compute charges (serverless)
- ⚠️ CU consumption: Charged per query/operation
- 💡 Tip: Monitor Capacity Metrics app for usage

## Security Notes
- Default: Workspace members have access
- Lakehouse permissions: Files vs Tables (separate ACLs)
- Warehouse: SQL-level security (schemas, roles)
- For production: Implement Row-Level Security (RLS)

## Verification Checklist
- [x] bronze_lakehouse created with SQL endpoint
- [x] silver_lakehouse created with SQL endpoint
- [x] gold_warehouse created
- [x] All resources visible in workspace

## OneLake Path Format
```python
# Bronze
"abfss://[workspace_id]@onelake.dfs.fabric.microsoft.com/bronze_lakehouse.Lakehouse/Files/[table_name]"

# Silver (when reading from notebook attached to silver lakehouse)
"Tables/[table_name]"

# Silver (full path)
"abfss://[workspace_id]@onelake.dfs.fabric.microsoft.com/silver_lakehouse.Lakehouse/Tables/[table_name]"
```

## Troubleshooting
**Issue:** SQL endpoint not appearing
- **Solution:** Refresh browser, wait 1-2 minutes for provisioning

**Issue:** Cannot write to Tables section
- **Solution:** Ensure notebook attached to correct lakehouse

## References
- [Lakehouse Documentation](https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview)
- [Warehouse Documentation](https://learn.microsoft.com/en-us/fabric/data-warehouse/data-warehousing)