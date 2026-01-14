# Fabric Medallion Architecture - End-to-End Data Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![dbt](https://img.shields.io/badge/dbt-1.9.8-orange.svg)](https://docs.getdbt.com/)
[![Microsoft Fabric](https://img.shields.io/badge/Microsoft%20Fabric-F64-blue.svg)](https://www.microsoft.com/en-us/microsoft-fabric)

## 📋 Project Overview

Production-grade implementation of the **Medallion Architecture** (Bronze → Silver → Gold) using **Microsoft Fabric**, demonstrating modern cloud data engineering practices with parallel processing, parameterization, and automated testing.

### Business Context
AdventureWorksLT sales data pipeline transforming raw operational data into analytics-ready star schema for BI reporting and data science use cases.

---

## 🏗️ Architecture
```
Azure SQL Database (AdventureWorksLT)
    ↓
Bronze Layer (OneLake - Raw Parquet)
    ↓
Silver Layer (Delta Tables - Cleaned)
    ↓
Gold Layer (Warehouse - Star Schema)
    ↓
Power BI / Analytics
```

### Technology Stack
- **Platform:** Microsoft Fabric (F64 capacity)
- **Storage:** OneLake (Delta Lake format)
- **Compute:** Serverless Spark, SQL Warehouse
- **Orchestration:** Fabric Data Pipelines
- **Transformation:** PySpark notebooks, dbt
- **Version Control:** Git

---

## 📊 Data Model

### Source Tables (5)
- **SalesLT.Customer** - Customer demographics (847 rows)
- **SalesLT.Product** - Product catalog (295 rows)
- **SalesLT.ProductCategory** - Category hierarchy (41 rows)
- **SalesLT.SalesOrderHeader** - Order headers (32 rows)
- **SalesLT.SalesOrderDetail** - Order line items (542 rows)

### Star Schema (Gold Layer)
```
           dim_date (1,096)
               |
               |
dim_customer (847) --- fact_sales (542) --- dim_product (295)
```

**Grain:** Order line item level (SalesOrderDetailID)

---

## 🚀 Key Features

### Production-Grade Patterns
- ✅ **Parallel processing** - ForEach activities with concurrent execution
- ✅ **Parameterization** - Dynamic table processing via pipeline parameters
- ✅ **Error handling** - Try-catch blocks and retry logic (Phase 2)
- ✅ **Data quality** - 34 automated dbt tests (unique, not_null, referential integrity)
- ✅ **Idempotency** - Safe to re-run pipelines multiple times
- ✅ **Version control** - All code and configuration in Git
- ✅ **Documentation** - Comprehensive setup guides and architecture decisions

### Cost Optimization
- OneLake auto-scaling (no idle costs)
- Spot instances for Spark compute
- Query result caching
- Trial capacity (F64 - 60 days free)
- **Estimated monthly cost (post-trial):** < $10 for this dataset volume

---

## 📁 Project Structure
```
medallion-architecture-fabric-project/
├── 01-infrastructure/          # Fabric workspace, lakehouse, warehouse setup
├── 02-data-source/            # Azure SQL connection configuration
├── 03-bronze-layer/           # Raw data ingestion pipeline
│   └── pipelines/             # pipeline_bronze_ingest.json
├── 04-silver-layer/           # Data cleansing transformations
│   └── notebooks/             # nb_silver_transformation.ipynb
├── 05-gold-layer/             # Star schema implementation
│   └── dbt_gold_warehouse/    # dbt models, tests, seeds
├── 06-orchestration/          # Master pipeline coordination
├── 07-monitoring/             # Observability and alerts
└── README.md
```

---

## 🔧 Setup Instructions

### Prerequisites
- Microsoft Fabric workspace (trial or paid)
- Azure SQL Database access
- Azure CLI installed
- Python 3.11+ with dbt-fabric
- ODBC Driver 18 for SQL Server

### Quick Start

#### 1. Infrastructure Setup
```bash
# Follow detailed guides in 01-infrastructure/
# - Create Fabric workspace
# - Create bronze_lakehouse, silver_lakehouse, gold_warehouse
```

#### 2. Bronze Layer (Parallel Ingestion)
```bash
# Import pipeline: 03-bronze-layer/pipelines/pipeline_bronze_ingest.json
# Configure Azure SQL connection
# Run pipeline - 5 tables ingest in parallel (~1 min)
```

#### 3. Silver Layer (Spark Transformations)
```bash
# Import notebook: 04-silver-layer/notebooks/nb_silver_transformation.ipynb
# Attach to silver_lakehouse
# Parameterized execution via pipeline (per table)
```

#### 4. Gold Layer (dbt Star Schema)
```bash
cd 05-gold-layer/dbt_gold_warehouse

# Configure profiles.yml
az login
dbt debug

# Build models
dbt run      # 8 models (5 views + 3 tables)
dbt test     # 34 tests - all passing
dbt docs generate
```

---

## 📈 Performance Metrics

| Layer | Volume | Processing Time | CU Consumption |
|-------|--------|-----------------|----------------|
| Bronze | 1,750 rows | ~1 min (parallel) | 0.1 CU |
| Silver | 1,750 rows | ~30 sec (parallel) | 0.2 CU |
| Gold | 2,780 rows | ~2 min (dbt run) | 0.3 CU |

**Total pipeline:** ~3.5 minutes end-to-end

---

## ✅ Data Quality

### dbt Tests (34 total)
- **Unique constraints:** 10 tests (surrogate keys, business keys)
- **Not null constraints:** 14 tests (critical columns)
- **Referential integrity:** 3 tests (fact → dimension FKs)
- **Source freshness:** 7 tests (Silver table validation)

**Test coverage:** 100% of dimensions and facts

---

## 📖 Documentation

Each layer includes comprehensive markdown documentation:

- **Architecture decisions** - Why specific patterns were chosen
- **Step-by-step setup** - Reproducible instructions with screenshots
- **Cost management** - Optimization strategies and budget tracking
- **Security notes** - Best practices for production deployment
- **Troubleshooting** - Common issues and solutions
- **Verification checklists** - Quality assurance steps

---

## 🎯 Learning Outcomes

This project demonstrates proficiency in:

1. **Cloud Data Engineering**
   - Microsoft Fabric ecosystem (Lakehouse, Warehouse, Pipelines)
   - OneLake and Delta Lake formats
   - Serverless compute patterns

2. **Data Modeling**
   - Medallion architecture (Bronze/Silver/Gold)
   - Dimensional modeling (Kimball methodology)
   - Star schema design with surrogate keys

3. **Pipeline Development**
   - Parallel processing and parameterization
   - PySpark transformations
   - dbt modeling and testing

4. **DevOps Practices**
   - Version control (Git)
   - Infrastructure as Code
   - Automated testing and documentation

5. **Production Standards**
   - Error handling and retry logic
   - Data quality frameworks
   - Cost optimization
   - Security best practices

---

## 🔮 Phase 2 Enhancements (Planned)

- [ ] Incremental loading with watermarks
- [ ] Advanced error handling and alerting
- [ ] Row count validation (Bronze → Silver → Gold)
- [ ] Schema drift detection
- [ ] SCD Type 2 for customer dimension
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Power BI dashboard integration
- [ ] Monitoring and observability (Capacity Metrics)

---

## 📝 Notes

- **Data Source:** AdventureWorksLT sample database (2008-06-01 snapshot)
- **Environment:** Fabric trial capacity (F64 - 60 days)
- **Purpose:** Learning project to master modern data engineering tools
- **Confidentiality:** All workspace IDs and credentials sanitized for Git

---

## 🤝 Contributing

This is a personal learning project. Feedback and suggestions welcome via issues!

---

## 📄 License

MIT License - Feel free to use this project structure for your own learning!

---

## 👤 Author

**Vignesh Dharmarajan**
- Portfolio: [GitHub Profile](https://github.com/vignesh-ships)
- Learning Focus: Cloud Data Engineering, Analytics Engineering

---

## 🙏 Acknowledgments

- Microsoft Learn documentation
- dbt Labs community
- Kimball Group dimensional modeling resources