# Chapter 02: Models

> **Models are the foundation of your Vulcan project** - SQL or Python transformations that create tables and views. Everything else (semantic layer, metrics, checks) builds on models.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**SQL Proficiency - Level 2 or 3**
- CTEs (Common Table Expressions)
- Window functions (`ROW_NUMBER`, `RANK`, `LAG`/`LEAD`)
- Aggregations and `GROUP BY`
- Joins (`INNER`, `LEFT`, `FULL`)
- Basic date/time functions
- **ANSI SQL syntax** - Vulcan uses SQLGlot for SQL parsing
- **Type casting**: `column::TYPE` syntax (e.g., `customer_id::INT`)
- Your target warehouse SQL dialect (BigQuery, Snowflake, DuckDB, etc.)

**Data Modeling Concepts**
- Primary keys and foreign keys
- Star schema / dimensional modeling basics
- Normalization vs denormalization tradeoffs
- Slowly changing dimensions (helpful but not required)

### Optional but Helpful

**Python - Intermediate Level** (only if writing Python models)
- Pandas DataFrame operations
- Type hints and function signatures
- Working with decorators (`@model`, `@signal`)
- Virtual environments

**Adding Python Dependencies:**

If your Python models need additional packages (e.g., `scikit-learn` for ML, `requests` for API calls):

```bash
# Add to your project's requirements.txt
pandas>=2.0.0
scikit-learn>=1.3.0
requests>=2.31.0
joblib>=1.3.0

# Install in your virtual environment
pip install -r requirements.txt

# Vulcan will use these packages during model execution
```

**Basic Understanding of:**
- Data warehouses (Snowflake, BigQuery, DuckDB, Postgres)
- ETL/ELT concepts
- Version control (Git)

**If you're coming from dbt**, you'll feel right at home - many concepts are similar, with added features for incremental processing, native semantic layer integration, and built-in data quality.

---

## Table of Contents

1. [Model Basics](#1-model-basics)
2. [SQL Models](#2-sql-models)
3. [Python Models](#3-python-models)
4. [Model Kinds](#4-model-kinds)
5. [Essential Model Properties](#5-essential-model-properties)
6. [Grain and Keys](#6-grain-and-keys)
7. [Audits](#7-audits)
8. [Data Quality Checks](#8-data-quality-checks)
9. [Unit Tests](#9-unit-tests)
10. [Signals](#10-signals)
11. [Macros](#11-macros)
12. [Best Practices](#12-best-practices)
13. [Quick Reference](#13-quick-reference)

---

## 1. Model Basics

Models are SQL or Python transformations that create tables and views in your data warehouse. They're the **foundation** of your Vulcan project - everything else (semantic layer, metrics, checks) builds on top of models.

Vulcan extends the transformation layer popularized by dbt with additional features like incremental processing, data quality checks, and native semantic layer integration.

### What Are Models?

**Quick Example:**

```sql
-- models/customers.sql
MODEL (
  name my_project.customers,
  kind FULL,
  cron '@daily'
);

SELECT 
  customer_id,
  email,
  signup_date,
  plan_type
FROM raw.user_accounts;
```

This creates a `customers` table that refreshes daily.

### Model Types

| Type | Use Case | Example |
|------|----------|---------|
| **SQL Model** | Most common - SQL transformations | Aggregations, joins, filters |
| **Python Model** | Complex logic, ML, API calls | Feature engineering, predictions |
| **Seed Model** | Static reference data | Country codes, product categories |
| **External Model** | Existing tables not managed by Vulcan | Raw data sources |

### Model Kinds (Materialization)

| Kind | When to Use | Performance |
|------|-------------|-------------|
| `VIEW` | Fast-changing logic, small data | Instant refresh |
| `FULL` | Complete refresh needed | Slow for large tables |
| `INCREMENTAL_BY_TIME_RANGE` | Time-partitioned data | 10-100x faster |
| `INCREMENTAL_BY_UNIQUE_KEY` | Upsert by key | Fast |
| `SCD_TYPE_2` | Track historical changes | Medium |

### Decision Tree: Which Model Kind?

```
Do you have a timestamp column?
├─ Yes → Use INCREMENTAL_BY_TIME_RANGE ✅ (90% of cases)
│
└─ No → Does the data have a unique key?
   ├─ Yes → Need history tracking?
   │  ├─ Yes → Use SCD_TYPE_2 ✅
   │  └─ No → Use INCREMENTAL_BY_UNIQUE_KEY ✅
   │
   └─ No → Is the table small (<1M rows)?
      ├─ Yes → Use FULL ✅
      └─ No → Use VIEW ✅ (or add a timestamp!)
```

### Model Structure Overview

Every model has two parts:

**1. MODEL DDL (Metadata)**

```sql
MODEL (
  name schema.table_name,     -- Required: Where to store results
  kind INCREMENTAL_BY_...,     -- Required: How to refresh
  cron '@daily',               -- When to run
  grain unique_key,            -- Primary key (optional but recommended)
  assertions (...)             -- Data quality checks (optional)
);
```

**2. Query (Transformation Logic)**

```sql
SELECT
  column1::TYPE,
  column2::TYPE,
  ...
FROM source_table
WHERE conditions;
```

### Vulcan-Specific Considerations

**Key Insight:** Model columns automatically become dimensions in the semantic layer!

```sql
-- This model:
SELECT 
  customer_id,
  customer_tier,
  signup_date
FROM raw.users;

-- Automatically exposes these dimensions:
-- ✓ customer_id
-- ✓ customer_tier  (filterable, groupable)
-- ✓ signup_date    (time dimension)
```

**Design Principle:** Write models with business users in mind, not just technical requirements.

[↑ Back to Top](#chapter-02-models)

---

## 2. SQL Models

SQL models are the most common model type. They define transformations using SQL with metadata in the `MODEL` DDL.

### Basic Structure

```sql
-- models/orders.sql

-- MODEL DDL (metadata)
MODEL (
  name my_project.orders,           -- Required: Fully qualified name
  kind INCREMENTAL_BY_TIME_RANGE (  -- How to refresh data
    time_column order_date
  ),
  cron '@hourly',                   -- When to run
  grain order_id,                   -- Unique identifier
  assertions (not_null(columns := (order_id, customer_id)))  -- Data quality
);

-- SQL Query (transformation logic)
SELECT
  order_id::INT,
  customer_id::INT,
  order_date::DATE,
  total_amount::DECIMAL(10,2),
  status::VARCHAR
FROM raw.orders
WHERE order_date BETWEEN @start_date AND @end_date;
```

### SQL Dialect and Type Casting

**Vulcan uses SQLGlot for SQL parsing**, which supports ANSI SQL and can transpile between dialects.

#### Type Casting Syntax

Always use PostgreSQL-style casting with `::TYPE`:

```sql
SELECT
  customer_id::INT,              -- Cast to integer
  email::VARCHAR,                -- Cast to string
  signup_date::DATE,             -- Cast to date
  revenue::DECIMAL(10,2),        -- Cast to decimal with precision
  is_active::BOOLEAN,            -- Cast to boolean
  metadata::JSON                 -- Cast to JSON
FROM staging.customers;
```

#### Common SQL Types

| Type | Example | Use Case |
|------|---------|----------|
| `::INT` | `customer_id::INT` | Integer IDs, counts |
| `::BIGINT` | `user_id::BIGINT` | Large integers |
| `::VARCHAR` | `email::VARCHAR` | Text/strings |
| `::TEXT` | `description::TEXT` | Long text |
| `::DATE` | `order_date::DATE` | Dates (no time) |
| `::TIMESTAMP` | `created_at::TIMESTAMP` | Dates with time |
| `::DECIMAL(p,s)` | `revenue::DECIMAL(10,2)` | Money, precise numbers |
| `::FLOAT` | `score::FLOAT` | Approximate numbers |
| `::BOOLEAN` | `is_active::BOOLEAN` | True/false |
| `::JSON` | `metadata::JSON` | JSON data |

#### Multi-Dialect Support

- Write models in your **target warehouse dialect** (BigQuery, Snowflake, DuckDB, etc.)
- Vulcan can transpile SQL between dialects when needed
- SQLGlot understands warehouse-specific functions and syntax

#### Why Explicit Type Casting?

Always cast column types for:
- **Clear data contracts** - Documents expected types
- **Type safety** - Catch type mismatches early
- **Better error messages** - Fails fast with clear errors
- **Semantic layer integration** - Knows column types for metrics/dimensions

```sql
-- ❌ Bad: No type casting
SELECT
  customer_id,
  revenue,
  order_date
FROM staging.orders;

-- ✅ Good: Explicit types
SELECT
  customer_id::INT,
  revenue::DECIMAL(10,2),
  order_date::DATE
FROM staging.orders;
```

### Complete Example: Analytics Model

```sql
-- models/analytics/customer_daily_revenue.sql
MODEL (
  name analytics.customer_daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date
  ),
  cron '@hourly',
  start '2024-01-01',
  grain (customer_id, revenue_date),
  owner 'data-team',
  tags ('analytics', 'revenue', 'customer'),
  description 'Daily revenue aggregated by customer',
  column_descriptions (
    customer_id = 'Unique customer identifier',
    revenue_date = 'Date of revenue (YYYY-MM-DD)',
    revenue = 'Total revenue in USD from completed orders',
    order_count = 'Number of completed orders'
  ),
  assertions (
    not_null(columns := (customer_id, revenue_date, revenue)),
    unique_combination_of_columns(columns := (customer_id, revenue_date)),
    accepted_range(column := revenue, min_v := 0, max_v := 10000000)
  )
);

SELECT
  customer_id::INT,
  order_date::DATE as revenue_date,
  SUM(amount)::DECIMAL(10,2) as revenue,
  COUNT(*)::INT as order_count
FROM staging.orders
WHERE order_date BETWEEN @start_date AND @end_date
  AND status = 'completed'
GROUP BY customer_id, order_date;
```

**For comprehensive property reference, see [Chapter 2A: Model Properties](02a-model-properties.md)**

[↑ Back to Top](#chapter-02-models)

---

## 3. Python Models

Use Python models when SQL isn't enough - complex business logic, machine learning, API calls, or data science workflows.

### When to Use Python Models

**✅ Good Use Cases:**
- Machine learning inference
- Complex calculations (statistical models, financial formulas)
- API calls to external services
- Data enrichment from external sources
- Custom data transformations not possible in SQL
- Advanced pandas/numpy operations

**❌ Use SQL Instead:**
- Joins, aggregations, filters (SQL is faster)
- Standard transformations (SQL is more maintainable)
- Simple calculations
- Time-series windowing

### Basic Structure

```python
# models/ml_predictions.py

from vulcan import ExecutionContext, model
import pandas as pd
import typing as t
from datetime import datetime

@model(
    "my_project.customer_predictions",
    kind="FULL",
    cron="@daily",
    columns={
        "customer_id": "INT",
        "churn_probability": "FLOAT",
        "predicted_ltv": "DECIMAL(10,2)",
        "prediction_date": "DATE",
    },
    column_descriptions={
        "churn_probability": "Probability customer will churn in next 30 days (0-1)",
        "predicted_ltv": "Predicted lifetime value in USD",
    }
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """Generate customer churn predictions using ML model."""
    
    # Fetch data from warehouse
    customers = context.fetchdf("""
        SELECT 
            customer_id,
            tenure_days,
            total_spent,
            engagement_score
        FROM analytics.customers
        WHERE status = 'active'
    """)
    
    # Load your ML model
    import joblib
    model = joblib.load("models/churn_model.pkl")
    
    # Make predictions
    features = customers[['tenure_days', 'total_spent', 'engagement_score']]
    customers['churn_probability'] = model.predict_proba(features)[:, 1]
    customers['predicted_ltv'] = customers['total_spent'] * (1 - customers['churn_probability']) * 2
    customers['prediction_date'] = execution_time.date()
    
    return customers[['customer_id', 'churn_probability', 'predicted_ltv', 'prediction_date']]
```

### @model Decorator Parameters

#### Required Parameters

**Model name:**

```python
@model("my_project.table_name")
```

**Column definitions:**

```python
columns={
    "id": "INT",
    "name": "VARCHAR",
    "amount": "DECIMAL(10,2)",
    "created_at": "TIMESTAMP",
}
```

**NOTE:** Required - Python can't infer column types like SQL can

#### Optional Parameters

**Model kind:**

```python
kind="FULL"  # Default for Python models

# Incremental also supported:
kind=dict(
    name="INCREMENTAL_BY_TIME_RANGE",
    time_column="event_date"
)
```

**Scheduling:**

```python
cron="@daily",
owner="ml-team",
tags=["ml", "predictions"],
```

**Column descriptions:**

```python
column_descriptions={
    "churn_probability": "ML model prediction (0-1 scale)",
    "customer_id": "Foreign key to customers table",
}
```

✅ Flows through to semantic layer

**Audits:**

```python
audits=[
    ("not_null", {"columns": ["customer_id"]}),
    ("accepted_range", {"column": "churn_probability", "min_v": 0, "max_v": 1}),
]
```

### ExecutionContext API

The `context` object provides access to your warehouse:

#### Fetch Data

**`context.fetchdf(query)`** - Execute SQL, return pandas DataFrame

```python
df = context.fetchdf("SELECT * FROM customers WHERE active = true")
```

**`context.fetchone(query)`** - Return single row as tuple

```python
(max_id,) = context.fetchone("SELECT MAX(id) FROM customers")
```

**`context.fetchall(query)`** - Return all rows as list of tuples

```python
rows = context.fetchall("SELECT id, name FROM customers LIMIT 10")
```

#### Table Operations

**`context.table(table_name)`** - Get table reference

```python
table_ref = context.table("raw.events")
df = context.fetchdf(f"SELECT * FROM {table_ref} LIMIT 1000")
```

#### Macros and Variables

**Built-in time variables:**

```python
def execute(context, start, end, execution_time, **kwargs):
    print(f"Processing data from {start} to {end}")
    print(f"Execution time: {execution_time}")
    # start/end: datetime objects for incremental models
    # execution_time: when the model is running
```

### Python Model Limitations

**Unsupported model kinds:**
- `VIEW` - Use SQL models for views
- `SEED` - Use SQL models for seed data
- `MANAGED` - Use SQL models for managed tables
- `EMBEDDED` - Use SQL models for embedded queries

**Supported model kinds for Python:**
- ✅ `FULL` - Complete refresh (default)
- ✅ `INCREMENTAL_BY_TIME_RANGE` - Time-partitioned incremental
- ✅ `INCREMENTAL_BY_UNIQUE_KEY` - Upsert by key
- ✅ `SCD_TYPE_2` - Historical tracking

**For advanced Python patterns, see [Chapter 2C: Model Operations](02c-model-operations.md)**

[↑ Back to Top](#chapter-02-models)

---

## 4. Model Kinds

How your model refreshes data - the most important performance decision.

### Quick Reference

| Kind | Refresh Strategy | Use Case | Performance |
|------|-----------------|----------|-------------|
| `VIEW` | Query-time | Fast-changing logic | Instant refresh |
| `FULL` | Drop + recreate | Small tables | Slow for large data |
| `INCREMENTAL_BY_TIME_RANGE` | Partition by date | Time-series data | 10-100x faster |
| `INCREMENTAL_BY_UNIQUE_KEY` | Upsert by key | Slowly changing | Fast |
| `SCD_TYPE_2` | Track history | Historical tracking | Medium |
| `SEED` | Load from CSV | Static reference data | One-time load |
| `EXTERNAL` | No refresh | Existing tables | N/A |
| `EMBEDDED` | Inline subquery | Reusable logic | No storage |
| `MANAGED` | Engine-managed | Engine auto-refresh | Engine-dependent |

### Choosing the Right Kind

**Decision Tree:**

```
Does the data have a timestamp column?
├─ Yes → Use INCREMENTAL_BY_TIME_RANGE ✅ (90% of cases)
│
└─ No → Does the data have a unique key?
   ├─ Yes → Need history tracking?
   │  ├─ Yes → Use SCD_TYPE_2 ✅
   │  └─ No → Use INCREMENTAL_BY_UNIQUE_KEY ✅
   │
   └─ No → Is the table small (<1M rows)?
      ├─ Yes → Use FULL ✅
      └─ No → Use VIEW ✅ (or add a timestamp!)
```

### VIEW - No Materialization

**How it works:** Model is a view - query runs every time someone accesses it

```sql
MODEL (
  name my_project.active_customers,
  kind VIEW
);

SELECT * FROM customers WHERE status = 'active';
```

**When to use:**
- Logic changes frequently
- Data volume is small
- Real-time freshness required
- NOT recommended if queries are slow (use FULL instead)

### FULL - Complete Refresh

**How it works:** Drops table and rebuilds from scratch every run

```sql
MODEL (
  name my_project.customer_summary,
  kind FULL,
  cron '@daily'
);

SELECT 
  customer_id,
  COUNT(*) as order_count,
  SUM(amount) as total_spent
FROM orders
GROUP BY customer_id;
```

**When to use:**
- Small to medium tables (< 10M rows)
- Simple, reliable refresh logic
- NOT recommended for large tables (too slow)

### INCREMENTAL_BY_TIME_RANGE - Time Partitions (Most Common)

**How it works:** Only processes new time intervals

```sql
MODEL (
  name my_project.daily_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    lookback 3  -- Reprocess last 3 days
  ),
  cron '@daily',
  start '2020-01-01'
);

SELECT
  event_id::INT,
  event_date::DATE,
  user_id::INT,
  event_type::VARCHAR
FROM raw.events
WHERE event_date BETWEEN @start_date AND @end_date;  -- Magic variables!
```

**When to use:**
- ✅ Time-series data (events, transactions, metrics)
- ✅ Large datasets (millions+ rows)
- ✅ Need 10-100x performance improvement
- ✅ Data arrives in time order

**Key features:**
- `time_column` - Column that defines time intervals
- `lookback` - Reprocess last N intervals (handles late-arriving data)
- `@start_date` / `@end_date` - Automatic variables for time range

**For advanced incremental properties, see [Chapter 2A: Model Properties](02a-model-properties.md)**

### INCREMENTAL_BY_UNIQUE_KEY - Upsert by Key

**How it works:** Upserts (insert or update) rows based on unique key

```sql
MODEL (
  name my_project.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  ),
  cron '@daily'
);

SELECT
  customer_id::INT,
  email::VARCHAR,
  signup_date::DATE,
  last_login_date::DATE,
  total_spent::DECIMAL(10,2)
FROM raw.customer_updates;
```

**When to use:**
- ✅ Slowly changing dimensions (customer info, product catalog)
- ✅ Upsert semantics (update existing, insert new)
- ✅ No timestamp column available
- ✅ Need to track current state (not history)

**Key features:**
- `unique_key` - Column(s) that uniquely identify a row
- Automatically handles INSERT for new rows, UPDATE for existing rows
- More efficient than FULL refresh for large dimension tables

### SCD_TYPE_2 - Historical Tracking

**How it works:** Tracks historical changes with `valid_from` and `valid_to` columns

```sql
MODEL (
  name my_project.customer_history,
  kind SCD_TYPE_2 (
    unique_key customer_id
  ),
  cron '@daily'
);

SELECT
  customer_id::INT,
  email::VARCHAR,
  customer_tier::VARCHAR,
  updated_at::TIMESTAMP
FROM raw.customer_updates;
```

**When to use:**
- ✅ Need to track historical changes
- ✅ "Point in time" queries (what was customer tier on date X?)
- ✅ Audit trail requirements
- ✅ Dimension tables with changing attributes

**Key features:**
- Automatically adds `valid_from` and `valid_to` columns
- Tracks when each version of a row was valid
- Enables time-travel queries

### SEED - Static Reference Data

**How it works:** Loads data from CSV files stored in your project

```sql
-- models/reference/national_holidays.sql
MODEL (
  name reference.national_holidays,
  kind SEED (
    path 'national_holidays.csv'
  ),
  columns (
    holiday_name VARCHAR,
    holiday_date DATE
  ),
  grain (holiday_date)
);
```

**When to use:**
- ✅ Static reference data (country codes, product categories)
- ✅ Data that changes infrequently
- ✅ Small datasets (< 100K rows)
- ✅ No SQL source available

**Key features:**
- CSV file stored in `seeds/` directory
- Loaded once unless CSV or model changes
- Can be referenced by other models like any table
- **NOTE:** Python models don't support SEED kind - use SQL

**Example CSV:**

```csv
holiday_name,holiday_date
New Year's Day,2024-01-01
Independence Day,2024-07-04
Christmas,2024-12-25
```

### EXTERNAL - Existing Tables

**How it works:** Declares metadata about tables managed outside Vulcan

```yaml
# external_models.yaml
- name: external_db.external_table
  description: Third-party data source
  columns:
    id: int
    name: varchar
    created_at: timestamp
```

**When to use:**
- ✅ Tables created/managed outside Vulcan
- ✅ Third-party data sources
- ✅ Read-only external systems
- ✅ Need column-level lineage

**Key features:**
- No query defined (table exists externally)
- Vulcan doesn't manage or refresh the table
- Used for lineage and type information
- Can define audits on external models

**NOTE:** External models are defined in YAML, not SQL files.

### EMBEDDED - Inline Subqueries

**How it works:** Query is embedded directly into downstream models (no physical table)

```sql
MODEL (
  name my_project.unique_employees,
  kind EMBEDDED
);

SELECT DISTINCT
  employee_name,
  department
FROM raw.employees;
```

**When to use:**
- ✅ Reusable logic that doesn't need storage
- ✅ Common subqueries used by multiple models
- ✅ Performance optimization (avoids materialization)
- ✅ Logic that changes frequently

**Key features:**
- No physical table created
- Query injected as subquery into downstream models
- Useful for reusable CTEs
- **NOTE:** Python models don't support EMBEDDED kind - use SQL

### MANAGED - Engine-Managed Tables

**How it works:** Database engine automatically refreshes the table (no manual refresh needed)

```sql
MODEL (
  name analytics.real_time_events,
  kind MANAGED,
  physical_properties (
    warehouse = 'COMPUTE_WH',
    target_lag = '2 minutes',
    data_retention_time_in_days = 2
  )
);

SELECT
  event_id::INT,
  event_date::DATE,
  event_type::VARCHAR
FROM raw.events;
```

**When to use:**
- ✅ Real-time data freshness requirements
- ✅ Engine-native auto-refresh (Snowflake Dynamic Tables)
- ✅ External data sources not managed by Vulcan
- ✅ Need automatic incremental updates

**Key features:**
- Engine manages data refresh automatically
- No `cron` needed (engine handles scheduling)
- No date filters needed (engine handles incremental updates)
- Currently only supported in **Snowflake** (Dynamic Tables)
- **NOTE:** Python models don't support MANAGED kind - use SQL
- **NOTE:** Still under development - API may change

**⚠️ Important considerations:**
- Engine-specific (not portable between warehouses)
- Additional costs (e.g., Snowflake Dynamic Tables)
- Limited visibility into refresh state
- Typically built off External Models, not other Vulcan models

**For comprehensive model kind details, see [Chapter 2A: Model Properties](02a-model-properties.md)**

[↑ Back to Top](#chapter-02-models)

---

## 5. Essential Model Properties

Model properties control how models behave, when they run, and how they're configured. This section covers the essential properties you'll use most often.

### Required Properties

#### `name` - Model Name

Fully qualified model name in `schema.table` format:

```sql
MODEL (
  name analytics.customers  -- schema.table format
);
```

**Best Practice:** Use consistent naming:
- `raw.*` - Raw ingested data
- `staging.*` - Cleaned, typed data
- `analytics.*` - Business logic transformations
- `metrics.*` - Aggregated metrics

#### `kind` - Materialization Strategy

How the model materializes data:

**For Time-Series Data** (90% of models):

```sql
kind INCREMENTAL_BY_TIME_RANGE (
  time_column event_timestamp
)
```

✅ Only processes new/changed data  
✅ 10-100x faster than FULL refresh  
✅ Required for large datasets

**For Full Refresh:**

```sql
kind FULL
```

⚠️ WARNING: Rebuilds entire table every run  
✅ Simple, reliable  
❌ Slow for large data

### Scheduling Properties

#### `cron` - Schedule Expression

When the model runs:

```sql
cron '@hourly'         -- Every hour
cron '@daily'          -- Every day at midnight UTC
cron '@weekly'         -- Every Monday at midnight
cron '0 */4 * * *'     -- Every 4 hours (cron expression)
```

**TIP:** Match `cron` to your data freshness needs, not your model complexity!

#### `start` - Historical Backfill Start

Earliest date to process:

```sql
start '2024-01-01'      -- Absolute date
start '1 year ago'       -- Relative date
```

#### `end` - Stop Processing After Date

Latest date to process:

```sql
end '2024-12-31'        -- Absolute date
end '1 month ago'       -- Relative date
```

### Data Quality Properties

#### `grain` - Primary Key

Declares the model's primary key:

```sql
grain order_id                    -- Single column
grains (customer_id, order_date)   -- Composite key
```

**Why define grain?**
- ✅ Enables automatic joins in semantic layer
- ✅ Validates uniqueness with audits
- ✅ Documents data model

#### `assertions` - Data Quality Audits

Attach audits to validate data:

```sql
assertions (
  not_null(columns := (order_id, customer_id)),
  unique_values(columns := (order_id)),
  accepted_range(column := amount, min_v := 0, max_v := 1000000)
)
```

**For comprehensive audit documentation, see [Chapter 4: Audits](../04-audits.md)**

### Metadata Properties

#### `description` - Model Description

Human-readable description:

```sql
description 'Daily customer revenue metrics aggregated by customer and date'
```

✅ Flows to data catalog and BI tools

#### `owner` - Model Owner

Team or person responsible:

```sql
owner 'data-team'
```

#### `tags` - Categorization

Organize models with tags:

```sql
tags ('analytics', 'revenue', 'customer', 'pii')
```

#### `column_descriptions` - Column Documentation

Document each column:

```sql
column_descriptions (
  customer_id = 'Unique customer identifier (integer)',
  revenue = 'Total revenue in USD from completed orders',
  customer_tier = 'Subscription tier: Free, Pro, Enterprise'
)
```

✅ Flows to semantic layer and BI tools

### Incremental Model Properties

#### `time_column` - Time Partition Column

Required for `INCREMENTAL_BY_TIME_RANGE`:

```sql
kind INCREMENTAL_BY_TIME_RANGE (
  time_column event_date
)
```

#### `lookback` - Late-Arriving Data

Reprocess last N intervals:

```sql
kind INCREMENTAL_BY_TIME_RANGE (
  time_column event_date,
  lookback 3  -- Reprocess last 3 days
)
```

**For comprehensive property reference, see [Chapter 2A: Model Properties](02a-model-properties.md)**

[↑ Back to Top](#chapter-02-models)

---

## 6. Grain and Keys

Grain defines your model's primary key - the column(s) that uniquely identify each row. This is critical for data quality and semantic layer integration.

### What is Grain?

**Grain = Primary Key**

The grain is the column or combination of columns that uniquely identify a row:

```sql
MODEL (
  name analytics.orders,
  grain order_id  -- Each row = one unique order
);
```

### Single vs Composite Grain

**Single column grain:**

```sql
MODEL (
  name analytics.customers,
  grain customer_id  -- One row per customer
);
```

**Composite grain (multiple columns):**

```sql
MODEL (
  name analytics.daily_customer_metrics,
  grains (customer_id, metric_date)  -- One row per customer per day
);
```

### Foreign Key References

Use `references` to declare foreign key relationships:

```sql
MODEL (
  name analytics.orders,
  grain order_id,
  references (customer_id)  -- Foreign key to customers table
);
```

**Benefits:**
- ✅ Documents relationships
- ✅ Helps with automatic join detection in semantic layer
- ✅ Can be used for referential integrity validation

### Grain as Prerequisite for Joins

**Grains are required for semantic layer joins.** The semantic layer validates that models with joins have grains defined:

```yaml
# Semantic layer automatically creates joins when:
# 1. Model has grains defined (required)
# 2. Join relationships are declared in semantic YAML
# Example: customers (grain: customer_id) ←→ orders (grain: order_id, references: customer_id)
```

**For detailed grain documentation, see [Chapter 2A: Model Properties](02a-model-properties.md)**

[↑ Back to Top](#chapter-02-models)

---

## 7. Audits

> **For comprehensive audit documentation, see [Chapter 4: Audits](../04-audits.md)** - This section provides a brief overview of how to attach audits to models.

### What Are Audits?

**Audits are SQL queries that validate your model's data after execution.** They search for invalid data, and if any is found, they halt the flow of data to prevent bad data from propagating downstream.

**Key characteristics:**
- Run automatically after model execution
- Always blocking in Vulcan (no warning-only mode)
- Query for bad data (returns rows = audit fails)
- For incremental models, only validate newly processed intervals

### Attaching Audits to Models

Use the `assertions` property in your MODEL definition:

```sql
MODEL (
  name analytics.orders,
  kind INCREMENTAL_BY_TIME_RANGE (time_column order_date),
  grain order_id,
  assertions (
    -- Built-in audits
    not_null(columns := (order_id, customer_id, amount)),
    unique_values(columns := (order_id)),
    accepted_range(column := amount, min_v := 0, max_v := 1000000),
    accepted_values(column := status, is_in := ('pending', 'completed', 'cancelled'))
  )
);
```

### Common Built-in Audits

Vulcan provides 29 built-in audits. Here are the most commonly used:

| Audit | Purpose | Example |
|-------|---------|---------|
| `not_null(columns := (...))` | No NULL values | Primary keys, required fields |
| `unique_values(columns := (...))` | No duplicates | Unique identifiers |
| `accepted_values(column := ..., is_in := (...))` | Enum validation | Status codes, categories |
| `accepted_range(column := ..., min_v := ..., max_v := ...)` | Numeric bounds | Revenue, age, counts |
| `forall(criteria := (...))` | Custom logic | Complex business rules |

### When to Use Audits

**Always audit:**
- ✅ Primary keys (not_null + unique_values)
- ✅ Foreign keys (referential integrity)
- ✅ Financial data (non-negative, within ranges)
- ✅ Critical business rules

**For comprehensive audit documentation, see [Chapter 4: Audits](../04-audits.md)** - Complete guide with all 29 built-in audits, advanced patterns, troubleshooting, and best practices.

[↑ Back to Top](#chapter-02-models)

---

## 8. Data Quality Checks

> **For comprehensive quality checks documentation, see [Chapter 5: Quality Checks](../05-quality-checks.md)** - This section provides a brief overview.

### What Are Quality Checks?

**Quality checks are comprehensive validation rules configured in YAML files.** Unlike audits (which block pipeline execution), checks:

- Run separately from model execution (or alongside it)
- Don't block pipelines (non-blocking validation)
- Track trends and historical patterns
- Support complex statistical analysis
- Integrate with Activity API for monitoring

### Checks vs Audits

| Feature | Audits | Checks |
|---------|--------|--------|
| **Purpose** | Critical validation | Monitoring & analysis |
| **When runs** | With model (inline) | Separately or with models |
| **Blocks pipeline?** | Yes (always) | No |
| **Configuration** | In MODEL DDL or .sql files | YAML files (`checks/`) |
| **Output** | Pass/fail | Pass/fail + samples |
| **Best for** | Business rules, data integrity | Trend monitoring, anomalies |

### Basic Check Configuration

Checks are defined in YAML files:

```yaml
# checks/orders.yml
checks:
  analytics.orders:
    completeness:
      - missing_count(customer_id) = 0:
          name: no_missing_customers
          attributes:
            description: "All orders must have a customer"
    
    validity:
      - failed rows:
          name: invalid_amounts
          fail query: |
            SELECT order_id, amount
            FROM analytics.orders
            WHERE amount < 0 OR amount > 1000000
          samples limit: 10
```

**For comprehensive quality checks documentation, see [Chapter 5: Quality Checks](../05-quality-checks.md)** - Complete guide with check types, configuration, and best practices.

[↑ Back to Top](#chapter-02-models)

---

## 9. Unit Tests

Unit tests validate model logic with predefined inputs and expected outputs. They prevent regressions and ensure models behave as expected after changes.

### What Are Unit Tests?

Unit tests:
- Define input fixtures (mock data)
- Specify expected outputs
- Run model logic in isolation
- Execute on demand (`vulcan test`)
- Run automatically during `vulcan plan`

**Unlike audits/checks:**
- Don't run in production
- Use mock data (not real data)
- Test logic, not data quality

### Test Structure

Tests are defined in YAML files in the `tests/` directory:

```yaml
# tests/test_revenue_metrics.yml
test_revenue_aggregation:
  model: analytics.revenue_metrics
  
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 101
          order_date: 2024-01-01
          amount: 100.00
          status: completed
        - order_id: 2
          customer_id: 101
          order_date: 2024-01-01
          amount: 50.00
          status: completed
  
  outputs:
    query:
      rows:
        - customer_id: 101
          metric_date: 2024-01-01
          revenue: 150.00
          order_count: 2
```

### Running Tests

```bash
# Run all tests
vulcan test

# Run specific test
vulcan test --select test_revenue_aggregation

# Run tests for specific model
vulcan test --select analytics.revenue_metrics
```

**For comprehensive testing documentation, see [Chapter 2B: Model Testing](02b-model-testing.md)** - Complete guide with advanced patterns, CI/CD integration, and troubleshooting.

[↑ Back to Top](#chapter-02-models)

---

## 10. Signals

Signals define custom criteria for when models should run. They enable advanced scheduling beyond simple `cron` expressions.

### What Are Signals?

Signals:
- Check if conditions are met before running a model
- Handle late-arriving data
- Wait for external dependencies
- Implement custom scheduling logic
- **Work with the built-in scheduler** (`vulcan run`)

**When to use:**
- Late-arriving data (data lands after scheduled run)
- External API dependencies
- File arrival detection (S3, SFTP)
- Business hours gates
- Complex scheduling logic

### Signal Basics

A signal is a Python function with the `@signal` decorator:

```python
# signals/__init__.py

from vulcan import signal, DatetimeRanges
import typing as t

@signal()
def file_arrived(batch: DatetimeRanges, file_path: str) -> t.Union[bool, DatetimeRanges]:
    """Check if file exists before running model."""
    import os
    return os.path.exists(file_path)
```

**Use in model:**

```sql
MODEL (
  name analytics.partner_data,
  kind INCREMENTAL_BY_TIME_RANGE (time_column data_date),
  signals (
    file_arrived(file_path := '/data/partner_upload.csv')
  )
);

SELECT * FROM raw.partner_data
WHERE data_date BETWEEN @start_date AND @end_date;
```

**For advanced signal patterns, see [Chapter 2C: Model Operations](02c-model-operations.md)**

[↑ Back to Top](#chapter-02-models)

---

## 11. Macros

Macros are reusable logic in SQL models. They enable parameterized queries and reduce repetition.

### Built-in Macros

Vulcan provides predefined macro variables:

#### Time Macros

**Incremental models:**

```sql
-- Date range for incremental processing
WHERE event_date BETWEEN @start_date AND @end_date

-- Date strings (YYYY-MM-DD format)
WHERE event_date BETWEEN @start_ds AND @end_ds

-- Execution time
WHERE processed_at = @execution_ds
```

**Available variables:**
- `@start_date`, `@end_date` - Date objects
- `@start_ds`, `@end_ds` - Date strings
- `@execution_ds` - When model is running

#### Environment Macros

```sql
-- Current environment
WHERE environment = '@{environment}'

-- Gateway name
WHERE gateway = '@{gateway}'
```

### User-Defined Macros

#### Inline Variables

Define variables in your model:

```sql
MODEL (...);

@DEF(size, 1);

SELECT * FROM items
WHERE item_id > @size;
```

#### Python-Based Macros

Create macros in `macros/__init__.py`:

```python
# macros/__init__.py

from vulcan import macro

@macro()
def standardize_email(email: str) -> str:
    """Standardize email to lowercase."""
    return f"LOWER(TRIM({email}))"
```

**Use in models:**

```sql
SELECT
  customer_id,
  @standardize_email(email) AS email_clean
FROM customers;
```

**For advanced macro patterns, see [Chapter 2C: Model Operations](02c-model-operations.md)**

[↑ Back to Top](#chapter-02-models)

---

## 12. Best Practices

Production-ready patterns for maintainable, performant, and business-friendly models.

### Model Organization

Organize models into semantic layers:

```
models/
├── raw/                    # External sources (EXTERNAL models)
├── staging/                # Cleaning, type casting
├── analytics/              # Business logic, semantic layer
└── metrics/                # Pre-aggregated KPIs
```

**Naming conventions:**

```
# ✅ Good
staging/stg_customers.sql
analytics/customer_lifetime_value.sql
metrics/daily_active_users.sql

# ❌ Bad
staging/c.sql
analytics/cust_ltv.sql
metrics/dau.sql
```

### Column Naming

**Design for the semantic layer:**

```sql
-- ❌ Bad: Technical names
SELECT
  cust_id,
  ord_cnt,
  rev_usd

-- ✅ Good: Business names
SELECT
  customer_id,
  order_count,
  revenue  -- Document units in description
```

### Always Use Column Descriptions

```sql
MODEL (
  name analytics.customer_metrics,
  column_descriptions (
    customer_id = 'Unique customer identifier',
    revenue = 'Total revenue in USD from completed orders',
    customer_tier = 'Subscription tier: Free, Pro, Enterprise'
  )
);
```

**Benefits:**
- ✅ Flows to BI tools
- ✅ Shows in data catalog
- ✅ Self-documenting
- ✅ Helps business users

### Production Checklist

**Essential properties for production models:**

```sql
MODEL (
  name analytics.customer_daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    lookback 3
  ),
  cron '@hourly',
  start '2024-01-01',
  
  -- Data quality
  grain (customer_id, revenue_date),
  assertions (
    not_null(columns := (customer_id, revenue_date, revenue)),
    unique_combination_of_columns(columns := (customer_id, revenue_date)),
    accepted_range(column := revenue, min_v := 0, max_v := 10000000)
  ),
  
  -- Metadata
  owner 'data-team',
  tags ('analytics', 'revenue', 'customer'),
  description 'Daily revenue aggregated by customer',
  column_descriptions (
    customer_id = 'Unique customer identifier',
    revenue = 'Total revenue in USD',
    revenue_date = 'Date of revenue (YYYY-MM-DD)'
  )
);
```

**For performance optimization, see [Chapter 2D: Model Optimization](02d-model-optimization.md)**

[↑ Back to Top](#chapter-02-models)

---

## 13. Quick Reference

### Model Kinds Quick Reference

| Kind | Use When | Performance |
|------|----------|-------------|
| `INCREMENTAL_BY_TIME_RANGE` | Time-series data | 10-100x faster |
| `INCREMENTAL_BY_UNIQUE_KEY` | Upsert by key | Fast |
| `FULL` | Small tables | Slow for large data |
| `VIEW` | Fast-changing logic | Instant refresh |
| `SCD_TYPE_2` | Historical tracking | Medium |
| `SEED` | Static CSV data | One-time load |
| `EXTERNAL` | Existing tables | N/A |
| `EMBEDDED` | Reusable subqueries | No storage |
| `MANAGED` | Engine auto-refresh | Engine-dependent |

### Essential Properties Quick Reference

| Property | Required? | Purpose | Example |
|----------|-----------|---------|---------|
| `name` | ✅ Yes | Model name | `analytics.customers` |
| `kind` | ✅ Yes | Materialization | `INCREMENTAL_BY_TIME_RANGE(...)` |
| `cron` | No | Schedule | `@daily` |
| `grain` | No | Primary key | `customer_id` |
| `assertions` | No | Audits | `not_null(columns := (id))` |
| `description` | No | Documentation | `'Customer metrics'` |
| `owner` | No | Ownership | `'data-team'` |
| `tags` | No | Categorization | `('analytics', 'customer')` |

### Common Patterns Cheat Sheet

**Time-series incremental model:**

```sql
MODEL (
  name analytics.daily_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column metric_date,
    lookback 3
  ),
  cron '@daily',
  start '2024-01-01',
  grain (customer_id, metric_date)
);

SELECT * FROM source
WHERE metric_date BETWEEN @start_date AND @end_date;
```

**Upsert dimension model:**

```sql
MODEL (
  name dimensions.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  ),
  cron '@daily',
  grain customer_id
);

SELECT * FROM source;
```

**Full refresh model:**

```sql
MODEL (
  name analytics.customer_summary,
  kind FULL,
  cron '@daily'
);

SELECT 
  customer_id,
  COUNT(*) as order_count,
  SUM(amount) as total_revenue
FROM orders
GROUP BY customer_id;
```

### Cross-References to Detailed Chapters

**For comprehensive documentation:**

- **[Chapter 2A: Model Properties](02a-model-properties.md)** - Complete property reference
- **[Chapter 2B: Model Testing](02b-model-testing.md)** - Advanced testing patterns
- **[Chapter 2C: Model Operations](02c-model-operations.md)** - Advanced SQL/Python patterns, signals, macros
- **[Chapter 2D: Model Optimization](02d-model-optimization.md)** - Performance tuning, warehouse-specific
- **[Chapter 4: Audits](../04-audits.md)** - Comprehensive audit guide
- **[Chapter 5: Quality Checks](../05-quality-checks.md)** - Comprehensive checks guide

[↑ Back to Top](#chapter-02-models)

---

## Summary

You've learned the fundamentals of Vulcan models:

### Core Concepts

**1. Model Basics**
- SQL and Python transformations
- MODEL DDL metadata + query logic
- Integration with semantic layer

**2. Model Kinds**
- `VIEW` - Real-time, no storage
- `FULL` - Complete refresh
- `INCREMENTAL_BY_TIME_RANGE` - Time partitions (most common, 10-100x faster)
- `INCREMENTAL_BY_UNIQUE_KEY` - Upsert by key
- `SCD_TYPE_2` - Historical tracking
- `SEED` - Static CSV data
- `EXTERNAL` - Existing tables
- `EMBEDDED` - Inline subqueries
- `MANAGED` - Engine-managed auto-refresh (Snowflake Dynamic Tables)

**3. Data Quality**
- **Grain** - Primary key definition, enables auto-joins
- **Audits** - Inline SQL checks (blocking)
- **Checks** - YAML-configured validation (monitoring)
- **Unit Tests** - Logic validation with fixtures

**4. Advanced Features**
- **Signals** - Custom scheduling (late data, external dependencies)
- **Macros** - Reusable SQL logic
- **References** - Foreign key relationships

### Next Steps

**Continue to Chapter 03: Semantic Layer**

Learn how to expose your models as business metrics:
- Measures and dimensions
- Joins across models
- Segments for filtering
- Business metrics (time-series KPIs)

**Additional Resources**

- **Vulcan CLI Reference** - `vulcan --help`
- **Examples** - `examples/b2b_saas/` in your Vulcan installation
- **Advanced Chapters** - Model Properties, Testing, Operations, Optimization

---

**Congratulations!** You now have a solid foundation in Vulcan models. You can:
- ✅ Write production-ready SQL and Python models
- ✅ Choose optimal materialization strategies
- ✅ Implement basic data quality checks
- ✅ Test model logic
- ✅ Handle basic scheduling scenarios

**Happy modeling!**

[↑ Back to Top](#chapter-02-models)

