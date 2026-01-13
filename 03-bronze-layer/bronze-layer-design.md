# Bronze Layer - Raw Data Ingestion

## Purpose
Ingest raw data from Azure SQL Database into Fabric OneLake as-is with minimal transformation.

## Architecture
```
Azure SQL Database (SalesLT schema)
    ↓ (Fabric Data Pipeline - parallel copy)
Bronze Lakehouse (OneLake - Parquet format)
```

## Design Decisions

### Storage Format: Parquet
**Why Parquet over CSV:**
- ✅ Columnar storage (better compression)
- ✅ Schema preservation (data types maintained)
- ✅ Faster read performance for downstream processing
- ✅ Native Spark support

**Cost:** ~60% smaller than CSV for this dataset

### Folder Structure
```
bronze_lakehouse/
└── Files/
    ├── Customer/
    │   └── Customer.parquet
    ├── Product/
    │   └── Product.parquet
    ├── ProductCategory/
    │   └── ProductCategory.parquet
    ├── SalesOrderHeader/
    │   └── SalesOrderHeader.parquet
    └── SalesOrderDetail/
        └── SalesOrderDetail.parquet
```

**Pattern:** One folder per table, one Parquet file per table

### Ingestion Strategy: Full Load
**Why Full Load:**
- Source data is snapshot (single day: 2008-06-01)
- No change tracking available
- Small dataset (~1,750 rows total)
- Acceptable for learning project

**For production:** Would implement incremental load with watermarks

### Parallelization: Enabled
**Approach:** ForEach loop with parallel execution
- All 5 tables load simultaneously
- No dependencies between tables
- CU consumption optimized (faster execution)

**Sequential vs Parallel:**
| Approach | Execution Time | CU Usage | When to Use |
|----------|---------------|----------|-------------|
| Sequential | ~5 min | Lower | Resource constraints, dependent tables |
| Parallel | ~1 min | Higher | Independent tables, speed priority |

**Choice:** Parallel (production standard for independent tables)

## Data Lineage
```
SalesLT.Customer (SQL) → bronze_lakehouse/Files/Customer (Parquet)
SalesLT.Product (SQL) → bronze_lakehouse/Files/Product (Parquet)
SalesLT.ProductCategory (SQL) → bronze_lakehouse/Files/ProductCategory (Parquet)
SalesLT.SalesOrderHeader (SQL) → bronze_lakehouse/Files/SalesOrderHeader (Parquet)
SalesLT.SalesOrderDetail (SQL) → bronze_lakehouse/Files/SalesOrderDetail (Parquet)
```

## Schema Preservation
- ✅ All source columns retained
- ✅ Data types preserved by Parquet
- ✅ No transformations applied
- ✅ NULL values maintained

## Performance Characteristics
- **Execution time:** ~1 minute (parallel)
- **Data volume:** ~5 MB total
- **CU consumption:** ~0.1 CU per run
- **Throughput:** ~1,750 rows/minute

## Idempotency
- **Write mode:** Overwrite
- **Behavior:** Each run replaces existing data
- **Safe to re-run:** Yes (deterministic output)

## Monitoring Points
1. Pipeline run status (success/failure)
2. Row counts per table (source vs destination)
3. File sizes in OneLake
4. Execution duration

## Error Handling Strategy
**Current (Phase 1):** Basic Fabric pipeline retry
**Future (Phase 2):**
- Per-table error handling
- Email/Teams notifications
- Row count validation
- Schema drift detection

## Cost Impact
- **Storage:** Negligible (~5 MB)
- **Compute:** ~0.1 CU per run
- **Network:** Within Azure (no egress charges)

## Verification Checklist
- [x] All 5 tables loaded successfully
- [x] Parquet files created in correct folders
- [x] Row counts match source tables
- [x] Schema preserved (data types correct)

## Limitations (Phase 1)
- ⚠️ No incremental load
- ⚠️ No data quality checks
- ⚠️ No row count validation
- ⚠️ No schema evolution handling
- ⚠️ No error notifications

## Future Enhancements (Phase 2)
1. Implement watermark-based incremental load
2. Add row count validation (source vs destination)
3. Schema drift detection
4. Failed table retry logic
5. Email/Teams alerts on failure
6. Metadata logging (load timestamp, row counts)

## References
- [Fabric Data Pipeline Documentation](https://learn.microsoft.com/en-us/fabric/data-factory/data-factory-overview)
- [Parquet Format Specification](https://parquet.apache.org/docs/)