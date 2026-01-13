# Azure SQL Database Connection

## Data Source
- **Server:** sqlserver-medallion-dev.database.windows.net
- **Database:** AdventureWorksLT
- **Schema:** SalesLT
- **Authentication:** SQL Authentication

## Tables Selected
1. SalesLT.Customer (~847 rows)
2. SalesLT.Product (~295 rows)
3. SalesLT.ProductCategory (~41 rows)
4. SalesLT.SalesOrderHeader (~32 rows)
5. SalesLT.SalesOrderDetail (~542 rows)

## Connection Setup in Fabric

### Create Connection
```
1. Workspace → + New → Data pipeline
2. Add Copy activity
3. Source tab → + New connection
4. Connection settings:
   - Data source type: Azure SQL Database
   - Connection name: conn_azure_sql_adventureworks
   - Server: sqlserver-medallion-dev.database.windows.net
   - Database: AdventureWorksLT
   - Authentication: SQL Authentication
   - Username: [your_username]
   - Password: [your_password]
5. Test connection → Success
6. Create
```

### Connection Properties
- **Encrypted:** Yes (TLS 1.2)
- **Trust server certificate:** No
- **Connection timeout:** 30 seconds
- **Command timeout:** 30 seconds

## Security Notes
- ❌ Credentials NOT stored in Git
- ✅ Connection stored encrypted in Fabric workspace
- ⚠️ For production: Use Service Principal or Managed Identity
- 💡 SQL Auth acceptable for learning environments

## Data Profile

### SalesLT.Customer
```sql
Columns: CustomerID, FirstName, LastName, EmailAddress, CompanyName, ...
Primary Key: CustomerID
Nulls: Minimal (CompanyName can be NULL)
```

### SalesLT.Product
```sql
Columns: ProductID, Name, ProductNumber, Color, Size, ListPrice, ProductCategoryID
Primary Key: ProductID
Nulls: Color, Size (expected for certain product types)
Foreign Key: ProductCategoryID → ProductCategory
```

### SalesLT.ProductCategory
```sql
Columns: ProductCategoryID, ParentProductCategoryID, Name
Primary Key: ProductCategoryID
Hierarchy: Self-referencing (ParentProductCategoryID)
```

### SalesLT.SalesOrderHeader
```sql
Columns: SalesOrderID, OrderDate, DueDate, ShipDate, CustomerID, SubTotal, TaxAmt, TotalDue
Primary Key: SalesOrderID
Foreign Key: CustomerID → Customer
Date Range: Single day snapshot (2008-06-01)
```

### SalesLT.SalesOrderDetail
```sql
Columns: SalesOrderID, SalesOrderDetailID, ProductID, OrderQty, UnitPrice, LineTotal
Primary Key: SalesOrderDetailID
Foreign Keys: 
  - SalesOrderID → SalesOrderHeader
  - ProductID → Product
Grain: One row per product per order
```

## Data Quality Observations
- ✅ Referential integrity maintained
- ✅ No obvious orphan records
- ⚠️ Single date snapshot (2008-06-01) - limited temporal analysis
- ⚠️ Small dataset - not suitable for performance testing

## Refresh Strategy
- **Type:** Full load (snapshot data, no incremental possible)
- **Frequency:** On-demand for learning
- **Volume:** ~1,750 total rows
- **Load time:** < 1 minute

## Connection String (for reference)
```
Server=sqlserver-medallion-dev.database.windows.net;
Database=AdventureWorksLT;
User ID=[username];
Password=[password];
Encrypt=yes;
TrustServerCertificate=no;
```

## Troubleshooting
**Issue:** Connection test fails
- **Solution:** Check firewall rules, verify credentials

**Issue:** Timeout errors
- **Solution:** Increase command timeout in connection settings

## References
- [AdventureWorks Sample Database](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)