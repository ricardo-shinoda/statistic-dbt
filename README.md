# Personal Finance ETL Pipeline: Google Drive to PostgreSQL

A modern data engineering pipeline designed to automate personal finance tracking. This project implements an **ELT (Extract, Load, Transform)** architecture, extracting raw financial data from Google Drive, loading it into a PostgreSQL container, and transforming it into analytical models using dbt.

## 🏗 System Architecture
The pipeline is divided into two main stages:
1.  **Ingestion Layer (Python):** Handles OAuth2 authentication with Google Drive API, downloads credit card invoices and control spreadsheets, and loads them into the `postgres_raw` schema.
2.  **Transformation Layer (dbt):** Cleans, tests, and models the raw data into a star schema (`analytics` schema) for financial insights.

---

## 🚀 Getting Started

### 1. Data Ingestion (Python Repository)
This repository handles the **Extract & Load** phases. It targets the `postgres_raw` schema and manages database dependencies.

* **Step 1: Activate Virtual Environment**
    ```bash
    source venv/bin/activate
    ```
* **Step 2: Spin up the Infrastructure**
    Ensure your PostgreSQL container is running via OrbStack or terminal:
    ```bash
    docker-compose up -d
    ```
* **Step 3: Database Connection**
    Verify connection to `statistic_db` via port **5433** (standardized for macOS compatibility).
* **Step 4: Execute Ingestion**
    Run the control script to sync Google Drive data with the database:
    ```bash
    python3 src/script/control11.py
    ```
    *Note: The script is configured to automatically drop the `analytics` schema to handle DDL dependencies.*

---

### 2. Data Transformation (dbt Repository)
This repository handles the **Transform** phase, turning raw data into business-ready tables.

* **Step 1: Activate Virtual Environment**
    ```bash
    source venv/bin/activate
    ```
* **Step 2: Initialize Seeds**
    Load static mapping files (CSV) into the database:
    ```bash
    dbt seed
    ```
* **Step 3: Run Transformations**
    Execute the models to build the analytical layers:
    ```bash
    dbt run
    ```

---

## ✅ Best Practices & Validation

To ensure data integrity and pipeline health, it is recommended to run the following checks:

1.  **Connection Test:** Before running models, verify the dbt-to-Postgres connection:
    ```bash
    dbt debug
    ```
2.  **Data Quality Tests:** Validate your data integrity (null checks, unique keys, accepted values) after every run:
    ```bash
    dbt test
    ```
3.  **Source Freshness:** Check if the Python ingestion successfully updated the raw tables:
    ```bash
    dbt source freshness
    ```

---

## 🛠 Tech Stack
* **Language:** Python 3.9+ (SQLAlchemy, Pandas)
* **Database:** PostgreSQL 15 (Docker/OrbStack)
* **Transformation:** dbt-core (Data Build Tool)
* **API:** Google Drive API v3

---
**Author:** Ricardo Shinoda
**Role:** Data Engineer