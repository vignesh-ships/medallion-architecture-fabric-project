# Cost Management Strategy

## Trial Period (60 Days)
- **Capacity:** F64 (64 CU)
- **Cost:** $0 (free trial)
- **Storage:** OneLake included
- **Compute:** All operations free

## Post-Trial Costs (if continuing)

### Capacity Pricing
| SKU | CU | Monthly Cost | Hourly Cost |
|-----|----|--------------| ------------|
| F2 | 2 | $262 | ~$0.36 |
| F4 | 4 | $524 | ~$0.73 |
| F64 | 64 | $8,196 | ~$11.38 |

### Storage Pricing
- OneLake: $0.023 per GB/month (standard tier)
- Our dataset: ~5MB = negligible cost

### Compute Pricing
- CU consumption based on operations
- Example: Notebook run = 0.5-2 CU depending on complexity
- Pipeline run = 0.1-0.5 CU per activity

## Cost Optimization for Learning

### ✅ During Trial
1. Use F64 freely (no charges)
2. Run pipelines multiple times for testing
3. Experiment with different approaches

### ⚠️ Before Trial Expires
**Option 1: Delete Everything**
```
1. Workspace settings → Delete workspace
2. Deletes all lakehouses, warehouses, pipelines
3. No charges incurred
```

**Option 2: Downgrade to F2**
```
1. Switch to F2 capacity ($262/month)
2. Suitable for low-volume workloads
3. Can pause capacity when not in use
```

**Option 3: Export & Pause**
```
1. Export all notebooks, pipeline definitions
2. Delete workspace
3. Rebuild later in new trial or paid capacity
```

## Monitoring Costs

### Capacity Metrics App
```
1. Workspace → Browse → Capacity Metrics
2. View CU consumption by item
3. Identify expensive operations
```

### Key Metrics to Watch
- **CU Hours:** Total compute consumed
- **Throttling events:** Capacity limit reached
- **Top consumers:** Which pipelines/notebooks using most CU

## Recommendations for This Project
1. ✅ Complete project within 60-day trial
2. ✅ Document everything for portfolio
3. ✅ Delete workspace before trial expires
4. ⚠️ Set calendar reminder 7 days before expiry

## Budget Alert Setup
```
(Fabric doesn't have native budget alerts yet)
Alternative: Set Outlook reminder for trial expiry date
```

## Cost Comparison (Azure Databricks vs Fabric)

| Aspect | Databricks | Fabric |
|--------|-----------|--------|
| Compute | $0.40-0.60/hr (DBU + VM) | $0.36-11/hr (CU based) |
| Storage | ADLS ($0.018/GB) | OneLake ($0.023/GB) |
| Idle costs | Yes (if cluster running) | No (serverless) |
| Trial | 14 days | 60 days |

**For learning:** Fabric = better value (longer trial, no idle costs)

## References
- [Fabric Pricing](https://azure.microsoft.com/en-us/pricing/details/microsoft-fabric/)
- [OneLake Pricing](https://learn.microsoft.com/en-us/fabric/onelake/onelake-consumption)