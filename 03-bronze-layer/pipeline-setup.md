# Bronze Pipeline Setup

## Pipeline: pipeline_bronze_ingest

### Architecture
```
Pipeline Parameter (table_list)
    ↓
ForEach Activity (parallel)
    ↓
Copy Activity (per table)
    ↓
Bronze Lakehouse (Parquet files)
```

## Setup Steps

### 1. Create Pipeline
```
1. Workspace → + New → Data pipeline
2. Name: pipeline_bronze_ingest
3. Click Create
```

---

### 2. Add Pipeline Parameter
```
1. Click empty canvas area
2. Bottom pane → Parameters tab
3. Click + New
4. Settings:
   - Name: table_list
   - Type: Array
   - Default value:
     ["Customer","Product","ProductCategory","SalesOrderHeader","SalesOrderDetail"]
```

**Why parameterize:**
- ✅ Easy to add/remove tables
- ✅ Reusable for different table sets
- ✅ Version controlled (JSON export)

---

### 3. Add ForEach Activity
```
1. Activities pane → ForEach → Drag to canvas
2. Name: foreach_table_ingestion
3. Settings tab:
   - Items: @pipeline().parameters.table_list
   - Sequential: UNCHECKED (enables parallel execution)
   - Batch count: Leave default (depends on capacity)
```

**Parallel Execution:**
- All 5 tables process simultaneously
- Faster execution (~1 min vs ~5 min sequential)
- Standard production pattern for independent tables

---

### 4. Add Copy Activity (Inside ForEach)
```
1. Double-click foreach_table_ingestion (opens inner canvas)
2. Activities → Copy data → Drag to canvas
3. Name: copy_table_to_bronze
```

**Source Configuration:**
```
Source tab:
- Data source type: External
- Connection: conn_azure_sql_adventureworks (created earlier)
- Use query: Table
- Schema: SalesLT
- Table: @{item()} (dynamic - uses current array item)
```

**Destination Configuration:**
```
Destination tab:
- Data destination type: Workspace
- Workspace item type: Lakehouse
- Lakehouse: bronze_lakehouse
- Root folder: Files
- File path: @{item()}/@{item()}.parquet
  - Creates folder per table
  - Example: Customer/Customer.parquet
- File format: Parquet
- Compression: Snappy (default, good balance)
```

---

### 5. Pipeline Structure
```
pipeline_bronze_ingest
├── Parameters
│   └── table_list (Array)
└── Activities
    └── foreach_table_ingestion (ForEach - Parallel)
        └── copy_table_to_bronze (Copy Data)
            ├── Source: Azure SQL (dynamic table)
            └── Destination: Bronze Lakehouse (Parquet)
```

---

## Testing

### Debug Run
```
1. Top toolbar → Debug
2. Monitor execution in Output pane
3. Verify all 5 tables show "Succeeded"
4. Execution time: ~1 minute
```

### Validation
```
1. Open bronze_lakehouse
2. Navigate to Files folder
3. Verify 5 folders created:
   - Customer/Customer.parquet
   - Product/Product.parquet
   - ProductCategory/ProductCategory.parquet
   - SalesOrderHeader/SalesOrderHeader.parquet
   - SalesOrderDetail/SalesOrderDetail.parquet
4. Check file sizes (should be ~1-2 KB each)
```

---

## Pipeline Properties

### Execution Settings
- **Timeout:** 7 days (default)
- **Retry:** 0 (default, no automatic retry)
- **Retry interval:** 30 seconds
- **Secure output:** No
- **Secure input:** No

### Concurrency
- **ForEach concurrency:** Controlled by capacity (auto-scaled)
- **Max concurrent tables:** Up to 50 (Fabric handles throttling)

---

## Monitoring

### Pipeline Run History
```
1. Workspace → pipeline_bronze_ingest → View run history
2. Each run shows:
   - Status (Succeeded/Failed/In Progress)
   - Start time
   - Duration
   - CU consumption
```

### Activity-Level Monitoring
```
1. Click on specific run
2. Expand foreach_table_ingestion
3. See individual Copy activity status per table
4. Identify which table failed (if any)
```

---

## Performance Tuning

### Current Configuration
- **Parallel degree:** 5 (all tables)
- **DIU (Data Integration Units):** Auto (Fabric managed)
- **Staging:** Not used (direct copy)

### Optimization Options (if needed)
1. **Increase batch count:** For more tables
2. **Enable staging:** For very large datasets (not needed here)
3. **Partition data:** For incremental loads (Phase 2)

---

## Error Handling (Current)

### Built-in Retry
- Pipeline-level: 0 retries (default)
- Activity-level: No retry policy

### Failure Behavior
- One table fails → Others continue (parallel execution benefit)
- Pipeline status = Failed if any table fails
- No automatic notifications

### Manual Intervention
```
If failure occurs:
1. Check pipeline run history
2. Identify failed table in ForEach details
3. Re-run entire pipeline (safe - idempotent overwrite)
```

---

## Phase 2 Enhancements
1. **Row count validation:** Compare source vs destination
2. **Email alerts:** On failure or success
3. **Metadata logging:** Capture load timestamps, row counts
4. **Schema validation:** Detect schema drift
5. **Incremental load:** Watermark-based ingestion
6. **Retry policy:** Per-table retry logic

---

## Scheduling (Optional)

### Add Trigger
```
1. Pipeline toolbar → Add trigger → New/Edit
2. Trigger types:
   - Schedule: Run daily/hourly
   - Tumbling window: Time-based intervals
   - Event-based: On file arrival
3. For learning: Manual trigger (on-demand) sufficient
```

---

## Cost Analysis
- **Per run:** ~0.1 CU (~$0.001 on F64 capacity)
- **Daily (if scheduled):** ~3 CU/month
- **Storage:** Negligible (~5 MB)

---

## Troubleshooting

### Issue: Table not found
**Error:** "Invalid object name 'SalesLT.Customer'"
**Solution:** Verify schema name and table name in source query

### Issue: Permission denied
**Error:** "Login failed for user"
**Solution:** Check SQL authentication credentials, firewall rules

### Issue: Timeout
**Error:** "Operation timed out"
**Solution:** Increase command timeout in connection settings

### Issue: Parquet write failure
**Error:** "Failed to write to OneLake"
**Solution:** Verify lakehouse exists and workspace has permissions

---

## Verification Checklist
- [x] Pipeline created with correct name
- [x] Parameter table_list configured with 5 tables
- [x] ForEach activity set to parallel execution
- [x] Copy activity uses dynamic table names (@item())
- [x] Destination creates folder per table
- [x] Debug run succeeds for all 5 tables
- [x] Parquet files visible in bronze_lakehouse/Files
- [x] File sizes reasonable (~1-2 KB per table)

---

## References
- [Fabric Copy Activity Documentation](https://learn.microsoft.com/en-us/fabric/data-factory/copy-data-activity)
- [ForEach Activity Documentation](https://learn.microsoft.com/en-us/fabric/data-factory/foreach-activity)
- [Pipeline Parameters](https://learn.microsoft.com/en-us/fabric/data-factory/parameters)