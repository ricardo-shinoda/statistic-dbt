# Statistic dbt Project

This repository contains the Analytics Engineering layer for the personal finance and statistics data pipeline. Using **dbt (Data Build Tool)** and **PostgreSQL**, it transforms raw data extracted from credit card PDFs, bank statements, investments, and vehicle logs into clean, modeled dimensional tables and analytical facts.

---

## 🏗️ Project Architecture & Directory Structure

Following modern analytics engineering workflows, all files are located at the root of the project for a seamless terminal experience (as seen in `image_de2aab.png`):

```text
STATISTIC-DBT/
├── macros/                  # Reusable SQL macro functions
├── models/
│   ├── staging/             # Raw data cleaning & type casting
│   │   └── postgres_raw/    # Sources definitions & initial views
│   └── marts/               # Analytical models (Business Layer)
│       ├── core/            # Universal dimensions (e.g., categories)
│       ├── finance/         # Unified cash flow & statements data
│       ├── investments/     # Portfolio & asset tracking facts
│       └── vehicle/         # Log analysis & consumption metrics
├── seeds/                   # Static mappings (CSV files)
├── tests/                   # Generic & data quality tests
├── dbt_project.yml          # Core dbt configuration file
├── requirements.txt         # Python dependencies (dbt-core, dbt-postgres)
└── README.md                # Project documentation
``` 

📊 Data Pipeline Flow

    Extraction (Upstream): Raw data is loaded into the PostgreSQL container via custom Python/Pandas scripts.

    Staging Layer (models/staging/):

        Maps raw data from postgres_raw.sources.yml.

        Cleans field names, fixes timestamps, and enforces correct data types (stg_card_payments, stg_income, stg_pix_payments, etc.).

    Seeds (seeds/): Enriches raw data with manual mappings such as category_mapping.csv and keyword_mapping.csv.

    Marts Layer (models/marts/):

        Core: Builds dimensional contexts like dim_categories.

        Finance: Aggregates facts like fct_credit_card_statements and outputs a consolidated financial view in fct_unified_payments.

        Vehicle & Investments: Tracks consumption profiles and portfolio performance over time.

🚀 Getting Started (Local Development)
1. Environment Setup

Ensure your local Python virtual environment is active and all dependencies are installed:
Bash

# Activate the virtual environment
source .venv/bin/activate

# Install core packages
pip install -r requirements.txt

2. Infrastructure (Database Container)

This project relies on a PostgreSQL instance running inside a Docker container (statistic_db). Ensure the container is active before running dbt:
Bash

# Check container status
docker ps -a

# Start the database container if stopped
docker start statistic_db

3. Verify Connection

To ensure your local configuration file (~/.dbt/profiles.yml) is correctly configured and reaching the database:
Bash

dbt debug

🛠️ Execution & Deployment Commands

Run these core commands inside your activated terminal to execute the transformation pipeline:

Load Reference Seeds: Inserts static CSV mapping files into the database.

```Bash
  dbt seed
``` 
Run Transformations: Compiles and runs all Staging views and Mart tables.

```Bash
  dbt run
```
Execute Combined Pipeline (Recommended): Sequential execution of seeds followed by models.

```Bash
  dbt seed && dbt run
``
Run Data Quality Tests: Validates constraints and unique/null expressions.

```Bash
  dbt test
``

💻 Cross-Platform Notes (Debian / macOS)

    Profiles Location: The profiles.yml file containing database credentials must reside in your local user directory:

        Linux (Debian): /home/<username>/.dbt/profiles.yml

        macOS: /Users/<username>/.dbt/profiles.yml

    VS Code Productivity Shortcut: To instantly preview compiled SQL scripts or test queries, use the universal shortcut: Ctrl + Enter (or mapped Cmd + Enter on macOS architecture).