# Fabric Workspace Setup

## Prerequisites
- Microsoft work account with Fabric access
- Fabric trial capacity available (F64, 60 days free)

## Setup Steps

### 1. Start Fabric Trial
```
1. Navigate to https://app.fabric.microsoft.com
2. Sign in with work account
3. Top right corner → Click profile icon
4. Select "Start trial"
5. Accept terms and conditions
6. F64 capacity automatically assigned
```

### 2. Create Workspace
```
1. Left sidebar → Workspaces → + New workspace
2. Workspace name: medallion-architecture-fabric-pro
3. License mode: Trial (F64 capacity auto-selected)
4. Advanced settings (optional):
   - Description: "Medallion architecture learning project"
5. Click Apply
```

### 3. Verify Workspace
```
Workspace should show:
- Capacity: Trial (F64)
- Status: Active
- Storage: OneLake enabled
```

## Cost Management
- ✅ Trial: 60 days free, F64 capacity (64 CU)
- ✅ No storage charges during trial
- ⚠️ Post-trial: F64 ≈ $8,196/month (pause/delete workspace to avoid charges)
- 💡 Tip: Use trial for learning, delete before expiry

## Security Notes
- Workspace isolation: Each workspace = separate security boundary
- Default: Creator has Admin role
- For production: Configure Azure AD groups for access control

## Verification Checklist
- [x] Trial activated successfully
- [x] Workspace created and accessible
- [x] F64 capacity assigned
- [x] OneLake storage enabled

## Troubleshooting
**Issue:** Trial button not visible
- **Solution:** Contact Microsoft admin to enable Fabric in tenant

**Issue:** Capacity limit reached
- **Solution:** Delete unused workspaces or wait for trial to reset

## References
- [Fabric Trial Documentation](https://learn.microsoft.com/en-us/fabric/get-started/fabric-trial)