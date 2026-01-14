# Gold Warehouse - Schema Setup

## Purpose
Create database schema in Fabric Warehouse to host star schema tables built by dbt.

## Prerequisites
- Gold warehouse created in Fabric workspace
- Access to warehouse SQL endpoint

## Setup Steps

### 1. Access Warehouse SQL Endpoint
```
1. Workspace → gold_warehouse
2. Click to open warehouse
3. Top toolbar → New SQL query
```

---

### 2. Create Schema (Optional - use dbo)
```sql
-- Option 1: Use default dbo schema (recommended for learning)
-- No action needed - dbt will use dbo by default

-- Option 2: Create dedicated schema (production pattern)
CREATE SCHEMA gold;
GO

-- Grant permissions if needed
-- GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gold TO [user];
```

**Recommendation:** Use `dbo` schema for this project (simpler configuration)

---

### 3. Verify Warehouse Connection

**Get SQL Endpoint:**
```
1. Warehouse → Settings icon (top right)
2. Copy "SQL connection string"
3. Format: [workspace-name].datawarehouse.fabric.microsoft.com
4. Database: gold_warehouse
```

**Test Connection (optional):**
```sql
SELECT @@VERSION AS sql_server_version;
SELECT DB_NAME() AS current_database;
```

---

### 4. Create dbt Service Account (Production Pattern)

**For learning:** Use your personal account

**For production:**
```sql
-- Create login (workspace admin does this)
CREATE LOGIN dbt_service_account WITH PASSWORD = 'SecurePassword123!';

-- Create user in warehouse
CREATE USER dbt_service_account FOR LOGIN dbt_service_account;

-- Grant permissions
GRANT CREATE TABLE TO dbt_service_account;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO dbt_service_account;
```

---

## dbt Connection Configuration

### profiles.yml Location
- **Windows:** `C:\Users\[username]\.dbt\profiles.yml`
- **Mac/Linux:** `~/.dbt/profiles.yml`

### Profile Configuration
```yaml
gold_warehouse:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server'
      server: [workspace-name].datawarehouse.fabric.microsoft.com
      port: 1433
      database: gold_warehouse
      schema: dbo
      authentication: CLI
      encrypt: true
      trust_cert: false
      retries: 1
```

**Authentication Methods:**

| Method | Use Case | Configuration |
|--------|----------|---------------|
| CLI | Development (personal) | `authentication: CLI` |
| Service Principal | Production CI/CD | `authentication: ServicePrincipal` + client_id/secret |
| SQL Auth | Not recommended | `authentication: sql` + username/password |

**Chosen:** CLI authentication (uses Azure CLI credentials)

---

## Azure CLI Setup (Required for dbt)

### Install Azure CLI
```bash
# Windows (PowerShell)
winget install Microsoft.AzureCLI

# Mac
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Login to Azure
```bash
az login

# Verify
az account show
```

### Install Fabric Extension (if needed)
```bash
az extension add --name fabric
```

---

## ODBC Driver Setup

### Check Installed Drivers
```bash
# Windows (PowerShell)
Get-OdbcDriver | Where-Object {$_.Name -like "*SQL Server*"}

# Mac/Linux
odbcinst -q -d
```

### Install ODBC Driver 18 (if missing)

**Windows:**
```
Download: https://go.microsoft.com/fwlink/?linkid=2249004
Run installer: msodbcsql.msi
```

**Mac:**
```bash
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install msodbcsql18
```

**Linux (Ubuntu):**
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
```

---

## dbt Project Initialization

### Install dbt-fabric
```bash
pip install dbt-fabric

# Verify installation
dbt --version
```

**Expected output:**
```
Core:
  - installed: 1.8.x
  - latest:    1.8.x

Plugins:
  - fabric: 1.8.x
```

---

### Initialize dbt Project
```bash
# Navigate to project folder
cd 05-gold-layer

# Initialize dbt project
dbt init dbt_gold_warehouse

# Follow prompts:
# - Project name: dbt_gold_warehouse
# - Database adapter: fabric
```

**Created structure:**
```
05-gold-layer/
└── dbt_gold_warehouse/
    ├── models/
    ├── dbt_project.yml
    ├── profiles.yml (move to ~/.dbt/)
    └── README.md
```

---

### Configure dbt_project.yml
```yaml
name: 'dbt_gold_warehouse'
version: '1.0.0'
config-version: 2

profile: 'gold_warehouse'

model-paths: ["models"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  dbt_gold_warehouse:
    +materialized: table
    staging:
      +schema: staging
    dimensions:
      +schema: dbo
    facts:
      +schema: dbo
```

---

### Move profiles.yml
```bash
# Windows PowerShell
Move-Item .\dbt_gold_warehouse\profiles.yml ~\.dbt\profiles.yml

# Mac/Linux
mv ./dbt_gold_warehouse/profiles.yml ~/.dbt/profiles.yml
```

---

## Test dbt Connection

### Debug Connection
```bash
cd dbt_gold_warehouse
dbt debug
```

**Expected output:**
```
Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
  - git [OK found]

Connection:
  server: [workspace].datawarehouse.fabric.microsoft.com
  database: gold_warehouse
  schema: dbo
  authentication: CLI
  Connection test: [OK connection ok]

All checks passed!
```

---

### Common Issues

**Issue:** ODBC Driver not found
```
Error: ('01000', "[01000] [unixODBC][Driver Manager]Can't open lib 'ODBC Driver 18 for SQL Server'")
Solution: Install ODBC Driver 18 (see installation steps above)
```

**Issue:** Authentication failed
```
Error: Login failed for user
Solution: Run 'az login' and ensure correct Azure subscription selected
```

**Issue:** Database not found
```
Error: Cannot open database "gold_warehouse"
Solution: Verify warehouse name in profiles.yml matches Fabric workspace
```

**Issue:** Permission denied
```
Error: CREATE TABLE permission denied
Solution: Verify user has CREATE TABLE permission in warehouse
```

---

## Warehouse Settings & Optimization

### Auto-pause Configuration
```
1. Warehouse settings → Compute
2. Auto-pause after: 5 minutes (default)
3. This saves CU when idle
```

### Query Result Caching
- ✅ Enabled by default
- Subsequent identical queries return cached results
- Cache invalidated on table updates

### Concurrency
- Default: Up to 10 concurrent queries
- Scales with capacity (F64 = higher limits)

---

## Security Best Practices

### For Learning (Current)
- ✅ Personal account with CLI auth
- ✅ No credentials in Git
- ✅ profiles.yml in user directory (not project folder)

### For Production
- ✅ Service Principal for dbt
- ✅ Row-level security (RLS) for BI users
- ✅ Column-level security for sensitive data
- ✅ Separate dev/prod warehouses
- ✅ Audit logging enabled

---

## Verification Checklist
- [ ] Warehouse accessible via SQL endpoint
- [ ] Azure CLI installed and logged in
- [ ] ODBC Driver 18 installed
- [ ] dbt-fabric installed (`dbt --version`)
- [ ] dbt project initialized in 05-gold-layer/
- [ ] profiles.yml moved to ~/.dbt/
- [ ] dbt_project.yml configured correctly
- [ ] `dbt debug` passes all checks
- [ ] Test query runs successfully in warehouse

---

## Cost Monitoring

### Warehouse CU Consumption
```
Workspace → Settings → Capacity metrics
Filter by: gold_warehouse
Monitor: Query execution CU usage
```

**Expected costs (per dbt run):**
- Initial run: ~0.3 CU (~$0.003 on F64)
- Incremental runs: ~0.1 CU (cached execution plans)

---

## References
- [dbt-fabric Documentation](https://github.com/microsoft/dbt-fabric)
- [Fabric Warehouse Security](https://learn.microsoft.com/en-us/fabric/data-warehouse/security)
- [ODBC Driver Download](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)