# cuny-cohort-etl-engine
This database automation module models an enterprise **Student Information System (SIS)** data architecture engineered to clean raw landing arrays, handle idempotency, and guarantee record retention accountability.

# CUNY Cohort Data Ingestion Engine & Compliance Ledger

## 🔗 Live Click-to-Run Environment
👉 **[Run the PostgreSQL Engine Directly in Your Browser]https://www.db-fiddle.com/f/75GkZP37gm4V2EPVDTpDV5/0
*(Click the "Run" button at the top of the interface to see the database create the environment, calculate statistics, and fire the logging triggers live).*

## 📊 Programmatic Proof of Pass Status
The continuous deployment test harness validates full environment lifecycle execution on impact. Below is the verified ledger output caught and written by the event listener upon intercepted administrative table deletions:

![SQL Test Verification Log](./sql_unit_test_passed.png)

## 🏗️ Production System Architecture
This database automation module models an enterprise **Student Information System (SIS)** data architecture engineered to clean raw landing arrays, handle idempotency, and guarantee record retention accountability.

* **Database Engine:** PostgreSQL 15+
* **Procedural Automation:** PL/pgSQL
* **Data Cleansing Core:** Regular expression string parsing handles mixed cases and isolates numeric year indicators dynamically.
* **Idempotency Rule:** Core processing blocks leverage an isolated `ON CONFLICT` strategy to capture and adjust live cohort shifts without pipeline termination.
* **Security & Governance:** An event-driven trigger intercepts standard system operations to populate an append-only system ledger tracking the historical state of deleted information.

## 📂 File Manifest
* `schema_and_test_suite.sql`: Consolidated transactional schemas, staging arrays, core procedural code, and test matrices.
* `sql_unit_test_passed.png`: Inline platform validation confirmation record.
