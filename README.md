# Financial Data Transformation Pipeline (dbt)

This repository contains the **dbt (data build tool)** project designed to transform, clean, and model raw personal finance and investment data stored in a PostgreSQL database into analytical-ready schemas.

By leveraging dbt's modular development practices, this project structures raw transaction inputs, vehicle consumption metrics, and stock portfolio details into distinct dimensional (`dim_`) and fact (`fct_`) tables.

## 🚀 Key Features

* **Multi-Layer Architecture:** Strictly follows dbt best practices separating **Staging** (cleaning and renaming), **Intermediate** (mid-level processing), and **Marts** (business-ready facts and dimensions).
* **Data Enrichment (Seeds):** Integrates seed files (like transaction category mappings) directly into the transformation DAG.
* **Consolidated Financial Marts:** Builds unified models for credit card transactions, investment portfolio valuations, and overall cash flows (Pix, credit card, and income).
* **Automated Documentation & Testing:** Uses schema configuration files (`schema.yml` and `sources.yml`) to enforce data quality constraints and document model dependencies.

## 📁 Repository Structure

```text
STATISTIC-DBT/
├── analyses/                  # One-off analytical SQL queries
├── dbt_packages/              # Installed external dbt packages
├── macros/                    # Reusable SQL helper functions and macros
├── models/                    
│   ├── staging/               # Layer 1: Raw data cleaning, casting, and renaming
│   │   └── postgres_raw/
│   │       ├── sources.yml    # Database source definitions
│   │       ├── schema.yml     # Staging-level tests and documentation
│   │       ├── stg_card_payments.sql
│   │       ├── stg_current_prices.sql
│   │       ├── stg_income.sql
│   │       ├── stg_investments.sql
│   │       ├── stg_pix_payments.sql
│   │       └── stg_vehicle_consumption.sql
│   └── marts/                 # Layer 2 & 3: Business-ready analytical tables
│       ├── core/
│       │   └── dim_categories.sql
│       ├── finance/           # Personal expense & payment tracking
│       │   ├── intermediate/  # Internal transformation models
│       │   ├── fct_credit_card_statements.sql
│       │   ├── fct_investments_dividends.sql
│       │   ├── fct_investments_portfolio.sql
│       │   ├── fct_lucas_investments.sql
│       │   ├── fct_monthly_investments.sql
│       │   └── fct_unified_payments.sql
│       ├── investments/       # Specialized portfolio tracking
│       │   └── fct_investments.sql
│       └── vehicle/           # Car expenses and mileage tracking
│           └── fct_vehicle_consumption.sql
├── seeds/                     # Static CSV maps (e.g., category_mapping.csv)
├── snapshots/                 # Slow-changing dimension (SCD) setups
├── dbt_project.yml            # Main dbt configuration file
├── profiles.yml               # Local connection profiles (Excluded from Git)
└── requirements.txt           # Python dbt dependencies
```

## ⚙️ Getting Started

### Prerequisites

* Python 3.10+ installed.
* Access to the PostgreSQL database containing the raw ingested data.

### Connection Profiles (`profiles.yml`)

Make sure your dbt profile is correctly set up. Typically located in `~/.dbt/profiles.yml` (or customized in your project root using `--profiles-dir`), it should point to your PostgreSQL database:

```yaml
# Local Developer Configuration (profiles.yml Template)
statistic:
  outputs:
    dev:
      type: postgres
      threads: 4
      host: localhost
      port: 5432
      user: YOUR_DB_USER
      password: YOUR_DB_PASSWORD
      dbname: YOUR_DB_NAME
      schema: dev # Target schema where dbt will write models
  target: dev
```

### Quick Setup & Commands

Run the following block of commands in your terminal to set up your virtual environment, install dependencies, load seed data, and execute the transformations:

```bash
# 1. Setup Python Virtual Environment
python -m venv .venv
source .venv/bin/activate  # On Windows use: .venv\Scripts\activate

# 2. Install dbt-postgres and dependencies
pip install -r requirements.txt

# 3. Pull dbt packages (if any are declared in packages.yml)
dbt deps

# 4. Load static CSV seeds (like category mapping) to the database
dbt seed

# 5. Run and Test the pipeline models
dbt build
```

## 📊 Analytical Pipeline Lineage (Logical Flow)

1. **Sources (`postgres_raw`):** Raw tables populated by the Python ingestion pipeline.
2. **Staging:** Standardization of timestamps, string schemas, and numerical columns.
3. **Seeds:** `category_mapping.csv` is mapped against staging payment streams to build `dim_categories`.
4. **Marts:** Models under `marts/` combine investments, credit card details, income, and vehicle costs to produce clean fact models like `fct_unified_payments` and portfolio health metrics.