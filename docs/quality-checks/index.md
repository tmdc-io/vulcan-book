# Chapter 05: Quality Checks

> **Monitor and validate data quality with SodaCL-powered checks** - Comprehensive validation rules that run separately from models, track trends over time, and integrate with the Activity API for monitoring and alerting.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**SQL Proficiency - Level 2**
- SELECT statements, WHERE clauses
- Aggregations (COUNT, AVG, SUM)
- Basic window functions (helpful)

**YAML Syntax**
- Basic YAML structure (dictionaries, lists)
- Multi-line strings

**Chapter 2 (Models)** - Understanding of:
- Model execution lifecycle
- Audits vs Checks distinction
- Data quality strategy

### Optional but Helpful

**Data Quality Concepts**
- Data quality dimensions (completeness, validity, accuracy)
- Statistical concepts (mean, standard deviation, anomalies)

**Activity API** (Chapter 6) - Helpful for:
- Querying check results
- Building monitoring dashboards

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Quick Start](#2-quick-start)
3. [Check Configuration](#3-check-configuration)
4. [Built-in Check Types](#4-built-in-check-types)
5. [Data Profiling](#5-data-profiling)
6. [Check Results and Activity API](#6-check-results-and-activity-api)
7. [Advanced Patterns](#7-advanced-patterns)
8. [Best Practices](#8-best-practices)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Introduction

### 1.1 What Are Quality Checks?

**Quality checks are comprehensive validation rules configured in YAML files** that monitor data quality over time. Unlike audits (which block pipeline execution), checks:

- Run separately from model execution (or alongside it)
- Don't block pipelines (non-blocking validation)
- Track trends and historical patterns
- Support complex statistical analysis
- Integrate with Activity API for monitoring

**Key characteristics:**
- Configured in `checks/` directory
- Use SodaCL (Soda Check Language) syntax
- Organized by data quality dimensions
- Results stored for historical analysis
- Integrated with Activity API

### 1.2 Checks vs Audits vs Profiles

Understanding the three data quality mechanisms:

| Feature | Audits | Checks | Profiles |
|---------|--------|--------|----------|
| **Purpose** | Critical validation | Monitoring & analysis | Observation & tracking |
| **When runs** | With model (inline) | Separately or with models | With model |
| **Blocks pipeline?** | Yes (always) | No | No |
| **Configuration** | In MODEL DDL or .sql files | YAML files (`checks/`) | In MODEL DDL |
| **Output** | Pass/fail | Pass/fail + samples | Statistical metrics |
| **Best for** | Business rules, data integrity | Trend monitoring, anomalies | Understanding data |
| **Historical tracking** | No | Yes (Activity API) | Yes (`_check_profiles`) |

**The Three-Layer Strategy:**

```
┌─────────────────────────────────────────┐
│  AUDITS (Critical - Blocks Pipeline)   │
│  • Primary keys must be unique          │
│  • Revenue must be non-negative         │
│  • Foreign key relationships valid      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  CHECKS (Monitoring - Non-Blocking)     │
│  • Row count within expected range      │
│  • Anomaly detection on metrics         │
│  • Cross-table consistency              │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  PROFILES (Observation - Metrics)       │
│  • Track null percentages               │
│  • Monitor column distributions         │
│  • Detect data drift                    │
└─────────────────────────────────────────┘
```

### 1.3 When to Use Checks

✅ **Use Quality Checks for:**
- Monitoring data quality trends over time
- Statistical anomaly detection
- Cross-model validation (joins across models)
- Non-critical validation (warnings, not blockers)
- Complex validation requiring historical context
- Building data quality dashboards

❌ **Use Audits Instead for:**
- Critical business rules that must pass
- Model-specific validation (runs inline)
- Simple SQL assertions
- Blocking invalid data from flowing downstream

❌ **Use Profiles Instead for:**
- Understanding data characteristics
- Discovering patterns (not validation)
- Detecting data drift
- Informing which checks/audits to add

**Example: Revenue validation strategy**

```sql
-- AUDIT (Critical - blocks if fails)
MODEL (
  name analytics.revenue,
  assertions (
    not_null(columns := (customer_id, revenue)),
    accepted_range(column := revenue, min_v := 0, max_v := 100000000)
  )
);
```

```yaml
# CHECK (Monitoring - warns if unusual)
checks:
  analytics.revenue:
    accuracy:
      - anomaly detection for avg(revenue):
          name: revenue_anomaly_detection
      - change for row_count >= -30%:
          name: row_count_drop_alert
```

```sql
-- PROFILE (Observation - tracks over time)
MODEL (
  name analytics.revenue,
  profiles (revenue, order_count, customer_tier)
);
```

### 1.4 SodaCL Overview

Quality checks use **SodaCL (Soda Check Language)**, a declarative YAML-based language for data quality validation.

**Key concepts:**
- **Check** - A validation rule (e.g., "row_count > 1000")
- **Dimension** - Data quality category (completeness, validity, etc.)
- **Filter** - Subset of data to validate
- **Attributes** - Metadata (name, description, severity)
- **Samples** - Example rows that failed validation

**SodaCL example:**

```yaml
checks:
  analytics.customers:
    completeness:
      - row_count > 100:
          name: sufficient_customers
          attributes:
            description: "At least 100 customers expected"
            severity: warning
```

[↑ Back to Top](#chapter-05-quality-checks)

---

## 2. Quick Start

### 2.1 Your First Check

Create `checks/customers.yml`:

```yaml
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_emails
          attributes:
            description: "All customers must have an email address"
```

**Run the check:**

```bash
vulcan check
```

**Output:**

```
Running checks...

✓ analytics.customers.no_missing_emails
  Pass: missing_count(email) = 0 (actual: 0)

----------------------------------------------------------------------
Ran 1 check in 0.234s

OK
```

### 2.2 Common Check Patterns

#### Pattern 1: Completeness Checks

Ensure required data is present:

```yaml
checks:
  analytics.orders:
    completeness:
      - missing_count(customer_id) = 0:
          name: customer_id_required
      
      - missing_percent(email) < 5:
          name: email_mostly_complete
      
      - row_count > 1000:
          name: sufficient_orders
```

#### Pattern 2: Validity Checks

Validate data format and values:

```yaml
checks:
  analytics.users:
    validity:
      - failed rows:
          name: invalid_emails
          fail query: |
            SELECT user_id, email
            FROM analytics.users
            WHERE email NOT LIKE '%@%'
          samples limit: 10
      
      - failed rows:
          name: invalid_ages
          fail query: |
            SELECT user_id, age
            FROM analytics.users
            WHERE age < 0 OR age > 120
```

#### Pattern 3: Uniqueness Checks

Ensure no duplicates:

```yaml
checks:
  analytics.customers:
    uniqueness:
      - duplicate_count(email) = 0:
          name: unique_emails
      
      - duplicate_count(customer_id, order_date) = 0:
          name: unique_customer_date_combination
```

#### Pattern 4: Anomaly Detection

Detect unusual patterns:

```yaml
checks:
  analytics.daily_revenue:
    accuracy:
      - anomaly detection for row_count:
          name: row_count_anomaly
      
      - anomaly detection for avg(revenue):
          name: revenue_anomaly
```

#### Pattern 5: Change Monitoring

Track changes over time:

```yaml
checks:
  analytics.orders:
    timeliness:
      - change for row_count >= -50%:
          name: row_count_drop_alert
          attributes:
            description: "Alert if row count drops more than 50%"
```

[↑ Back to Top](#chapter-05-quality-checks)

---

## 3. Check Configuration

### 3.1 File Structure

Checks are YAML files in the `checks/` directory:

```
project/
├── models/
├── checks/
│   ├── users.yml           # Checks for user tables
│   ├── orders.yml          # Checks for order tables
│   ├── revenue.yml         # Checks for revenue tables
│   └── cross_model.yml     # Checks spanning multiple tables
└── config.yaml
```

**File naming:**
- Must end with `.yml` or `.yaml`
- Name doesn't matter (Vulcan reads all files)
- Organize by domain or table for clarity

### 3.2 Basic Check Syntax

```yaml
checks:
  <fully_qualified_table_name>:
    <dimension>:
      - <check_expression>:
          name: <check_name>
          attributes:
            description: <human_readable_description>
            severity: <warning|error>
            tags: [<tag1>, <tag2>]
```

**Example:**

```yaml
checks:
  analytics.customers:
    completeness:
      - row_count > 100:
          name: sufficient_customers
          attributes:
            description: "At least 100 customers expected in production"
            severity: warning
            tags: [critical, daily]
```

### 3.3 Data Quality Dimensions

Organize checks by **8 standard dimensions** (ODPS v3.1):

#### 1. Completeness
No missing required data

```yaml
completeness:
  - missing_count(customer_id) = 0
  - missing_percent(email) < 5
  - row_count > 1000
```

#### 2. Validity
Data conforms to format/syntax

```yaml
validity:
  - failed rows:
      fail query: |
        SELECT * FROM table
        WHERE email NOT LIKE '%@%'
```

#### 3. Accuracy
Data matches reality

```yaml
accuracy:
  - anomaly detection for avg(revenue)
  - avg(age) between 18 and 65
```

#### 4. Consistency
Data agrees across sources

```yaml
consistency:
  - failed rows:
      fail query: |
        SELECT *
        FROM orders o
        LEFT JOIN customers c ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
```

#### 5. Uniqueness
No duplicates

```yaml
uniqueness:
  - duplicate_count(email) = 0
  - duplicate_count(order_id) = 0
```

#### 6. Timeliness
Data is current

```yaml
timeliness:
  - change for row_count >= -30%
  - failed rows:
      fail query: |
        SELECT *
        FROM orders
        WHERE updated_at < CURRENT_DATE - INTERVAL '7 days'
```

#### 7. Conformity
Follows standards

```yaml
conformity:
  - failed rows:
      fail query: |
        SELECT *
        FROM addresses
        WHERE LENGTH(zip_code) != 5
```

#### 8. Coverage
All records are present

```yaml
coverage:
  - row_count >= 95% of historical_avg(row_count)
```

### 3.4 Filtering Checks

Apply checks to a subset of data:

```yaml
checks:
  analytics.orders:
    filter: "status = 'completed' AND order_date >= CURRENT_DATE - INTERVAL '30 days'"
    
    completeness:
      - missing_count(customer_id) = 0:
          name: completed_orders_have_customers
```

**Multiple filters:**

```yaml
checks:
  analytics.customers:
    filter: "country = 'US'"
    completeness:
      - row_count > 1000
  
  analytics.customers:
    filter: "country = 'EU'"
    completeness:
      - row_count > 500
```

### 3.5 Check Attributes

Add metadata to checks:

```yaml
checks:
  analytics.revenue:
    completeness:
      - row_count > 1000:
          name: sufficient_revenue_data
          attributes:
            description: "Revenue table must have at least 1000 rows for analysis"
            severity: error
            tags: [critical, daily, revenue]
            owner: data-team
            jira: DATA-1234
            sla: "< 1 hour"
```

**Standard attributes:**
- `description` - Human-readable explanation
- `severity` - `error` (default) or `warning`
- `tags` - List of tags for filtering/organization
- `owner` - Team or person responsible
- Custom attributes - Any key-value pairs

[↑ Back to Top](#chapter-05-quality-checks)

---

## 4. Built-in Check Types

### 4.1 Missing Data Checks

#### `missing_count(column)`

Count of NULL values:

```yaml
completeness:
  - missing_count(email) = 0:
      name: no_missing_emails
  
  - missing_count(phone) <= 100:
      name: phone_mostly_complete
```

#### `missing_percent(column)`

Percentage of NULL values:

```yaml
completeness:
  - missing_percent(email) < 5:
      name: email_95_percent_complete
  
  - missing_percent(optional_field) < 50:
      name: optional_field_half_complete
```

### 4.2 Row Count Checks

#### `row_count`

Total rows in table:

```yaml
completeness:
  - row_count > 1000:
      name: sufficient_data
  
  - row_count between 1000 and 100000:
      name: expected_row_range
```

#### `row_count` with filter

```yaml
completeness:
  - row_count > 500:
      name: sufficient_active_users
      filter: "status = 'active'"
```

### 4.3 Duplicate Count Checks

#### `duplicate_count(column)`

Count of duplicate values:

```yaml
uniqueness:
  - duplicate_count(email) = 0:
      name: unique_emails
  
  - duplicate_count(customer_id) = 0:
      name: unique_customer_ids
```

#### `duplicate_count(column1, column2)`

Composite key duplicates:

```yaml
uniqueness:
  - duplicate_count(customer_id, order_date) = 0:
      name: unique_customer_date
      attributes:
        description: "Each customer can have at most one order per day"
```

### 4.4 Failed Rows Checks

#### SQL-based validation with samples

Most flexible check type - any SQL query:

```yaml
validity:
  - failed rows:
      name: invalid_revenue
      fail query: |
        SELECT customer_id, revenue, order_date
        FROM analytics.orders
        WHERE revenue < 0 OR revenue > 10000000
      samples limit: 20
      attributes:
        description: "Revenue must be between 0 and 10M"
```

**Key features:**
- `fail query` - SELECT statement that returns invalid rows
- `samples limit` - How many example rows to capture (default: 5)
- Returns empty = check passes
- Returns rows = check fails (captures samples)

**Complex validation:**

```yaml
validity:
  - failed rows:
      name: orphaned_orders
      fail query: |
        SELECT o.order_id, o.customer_id
        FROM analytics.orders o
        LEFT JOIN analytics.customers c ON o.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
      samples limit: 10
```

### 4.5 Threshold Checks

#### Numeric aggregations

```yaml
accuracy:
  - avg(revenue) between 100 and 10000:
      name: revenue_in_expected_range
  
  - sum(amount) > 1000000:
      name: sufficient_total_revenue
  
  - max(age) <= 120:
      name: age_within_human_range
  
  - min(price) >= 0:
      name: non_negative_prices
```

#### Statistical checks

```yaml
accuracy:
  - stddev(revenue) < 5000:
      name: revenue_low_variance
  
  - percentile(revenue, 95) < 50000:
      name: revenue_95th_percentile_check
```

### 4.6 Anomaly Detection

#### ML-based anomaly detection

Uses historical check results to detect anomalies:

```yaml
accuracy:
  - anomaly detection for row_count:
      name: row_count_anomaly
      attributes:
        description: "Detect unusual changes in row count"
  
  - anomaly detection for avg(revenue):
      name: revenue_anomaly
  
  - anomaly detection for distinct_count(customer_id):
      name: customer_count_anomaly
```

**How it works:**
1. Collects historical metric values over time
2. Builds statistical model (mean, std dev, trends)
3. Compares current value to expected range
4. Flags significant deviations (typically > 3 std devs)

**Requirements:**
- Needs historical data (runs multiple times)
- Works best with regular schedules (daily, hourly)
- More accurate after 30+ data points

### 4.7 Change Over Time Checks

#### Monitor changes compared to previous run

```yaml
timeliness:
  - change for row_count >= -50%:
      name: row_count_drop_alert
      attributes:
        description: "Alert if row count drops more than 50% from last week"
  
  - change for avg(revenue) >= -20%:
      name: revenue_drop_alert
  
  - change for distinct_count(customer_id) >= 10%:
      name: customer_growth_check
```

**Change calculation:**
```
change = (current_value - previous_value) / previous_value * 100
```

**Examples:**
- `change >= -30%` - Alert if metric drops more than 30%
- `change >= 10%` - Alert if metric grows more than 10%
- `change between -10% and 10%` - Alert if metric changes more than 10% either way

[↑ Back to Top](#chapter-05-quality-checks)

---

## 5. Data Profiling

### 5.1 What is Profiling?

**Profiles automatically collect statistical metrics about your data over time.**

Unlike checks (which validate), profiles **observe and track** data characteristics:

```sql
MODEL (
  name analytics.customers,
  kind FULL,
  grains (customer_id),
  profiles (revenue, signup_date, customer_tier, order_count)
);
```

**What gets profiled:**

**Table-level metrics:**
- Row count

**Column-level metrics (all columns):**
- Null count & percentage
- Distinct count
- Duplicate count
- Uniqueness percentage

**Numeric columns:**
- Min, max, avg, sum
- Standard deviation, variance
- Histogram buckets

**Text columns:**
- Min, max, avg length
- Most frequent values

### 5.2 Profile Configuration

Enable profiling in MODEL:

```sql
MODEL (
  name analytics.revenue_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (time_column metric_date),
  
  -- Profile these columns
  profiles (
    revenue,
    order_count,
    customer_tier,
    region
  )
);
```

### 5.3 Profile Storage

Profiles are stored in the `_check_profiles` table:

```sql
SELECT
  data_source,        -- Table name (e.g., 'analytics.customers')
  column_name,        -- Column profiled
  null_count,         -- Number of NULLs
  null_percentage,    -- Percentage NULLs
  distinct_count,     -- Number of unique values
  duplicate_count,    -- Number of duplicates
  min_value,          -- Minimum value (numeric/date)
  max_value,          -- Maximum value (numeric/date)
  avg_value,          -- Average (numeric)
  stddev_value,       -- Standard deviation (numeric)
  profiled_at,        -- When profile was collected
  histogram           -- Distribution (JSON)
FROM _check_profiles
WHERE data_source = 'analytics.customers'
  AND column_name = 'revenue'
ORDER BY profiled_at DESC;
```

### 5.4 Querying Profiles

#### Track null percentage over time

```sql
SELECT
  profiled_at::DATE as date,
  null_percentage
FROM _check_profiles
WHERE data_source = 'analytics.customers'
  AND column_name = 'email'
ORDER BY profiled_at DESC
LIMIT 30;  -- Last 30 days
```

#### Monitor data drift

```sql
WITH current AS (
  SELECT distinct_count, avg_value
  FROM _check_profiles
  WHERE data_source = 'analytics.customers'
    AND column_name = 'revenue'
  ORDER BY profiled_at DESC
  LIMIT 1
),
historical AS (
  SELECT AVG(distinct_count) as avg_distinct, AVG(avg_value) as avg_revenue
  FROM _check_profiles
  WHERE data_source = 'analytics.customers'
    AND column_name = 'revenue'
    AND profiled_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
  c.distinct_count,
  h.avg_distinct,
  (c.distinct_count - h.avg_distinct) / h.avg_distinct * 100 as distinct_change_pct,
  c.avg_value,
  h.avg_revenue,
  (c.avg_value - h.avg_revenue) / h.avg_revenue * 100 as revenue_change_pct
FROM current c, historical h;
```

### 5.5 Using Profiles to Inform Checks

**Workflow:**

1. **Enable profiling** on new models
2. **Observe patterns** for 30+ days
3. **Identify anomalies** in profile data
4. **Create checks** based on observed patterns

**Example:**

```sql
-- Step 1: Enable profiling
MODEL (
  name analytics.orders,
  profiles (order_count, revenue, customer_tier)
);
```

```sql
-- Step 2: Query profiles after 30 days
SELECT
  MIN(avg_value) as min_revenue,
  MAX(avg_value) as max_revenue,
  AVG(avg_value) as typical_revenue,
  STDDEV(avg_value) as revenue_stddev
FROM _check_profiles
WHERE data_source = 'analytics.orders'
  AND column_name = 'revenue'
  AND profiled_at >= CURRENT_DATE - INTERVAL '30 days';

-- Results:
-- min_revenue: 45000
-- max_revenue: 75000
-- typical_revenue: 58000
-- revenue_stddev: 6000
```

```yaml
# Step 3: Create checks based on observed patterns
checks:
  analytics.orders:
    accuracy:
      - avg(revenue) between 40000 and 80000:
          name: revenue_within_observed_range
          attributes:
            description: "Based on 30-day historical analysis"
      
      - anomaly detection for avg(revenue):
          name: revenue_anomaly_detection
```

### 5.6 Profile Best Practices

✅ **DO:**
- Profile high-value production tables
- Profile columns used in downstream analysis
- Use profiles to understand new data sources
- Query profiles to detect data drift
- Use profiles to inform check thresholds

❌ **DON'T:**
- Profile sensitive/PII columns (privacy risk)
- Profile every column (performance overhead)
- Profile temporary/experimental models
- Use profiles as a replacement for checks
- Profile very high-frequency models (storage cost)

**When to use profiles:**
- Building new models (understand the data)
- Monitoring production tables
- Detecting data drift
- Informing audit/check strategy
- Debugging data quality issues

**When to skip profiles:**
- Temporary models
- Models with sensitive data
- Very high-frequency models (> 100 runs/day)
- Models where you only need pass/fail validation

[↑ Back to Top](#chapter-05-quality-checks)

---

## 6. Check Results and Activity API

**Status**: To be determined - will be covered in Chapter 6 (APIs).

This section will cover:
- Activity API endpoints for check results
- Querying check history
- Building monitoring dashboards
- Integrating with alerting systems

[↑ Back to Top](#chapter-05-quality-checks)

---

## 7. Advanced Patterns

### 7.1 Cross-Model Validation

Validate relationships between models:

```yaml
# checks/cross_model.yml
checks:
  analytics.orders:
    consistency:
      - failed rows:
          name: orphaned_orders
          fail query: |
            SELECT o.order_id, o.customer_id
            FROM analytics.orders o
            LEFT JOIN analytics.customers c ON o.customer_id = c.customer_id
            WHERE c.customer_id IS NULL
          samples limit: 10
          attributes:
            description: "All orders must have a valid customer"
      
      - failed rows:
          name: revenue_mismatch
          fail query: |
            SELECT
              o.order_id,
              o.revenue as order_revenue,
              r.revenue as revenue_table_revenue
            FROM analytics.orders o
            JOIN analytics.revenue r ON o.order_id = r.order_id
            WHERE ABS(o.revenue - r.revenue) > 0.01
```

### 7.2 Time-Based Validation

Ensure data timeliness:

```yaml
checks:
  analytics.orders:
    timeliness:
      - failed rows:
          name: stale_data
          fail query: |
            SELECT *
            FROM analytics.orders
            WHERE updated_at < CURRENT_TIMESTAMP - INTERVAL '24 hours'
              AND status != 'completed'
          attributes:
            description: "Pending orders should update within 24 hours"
      
      - failed rows:
          name: future_dates
          fail query: |
            SELECT *
            FROM analytics.orders
            WHERE order_date > CURRENT_DATE
```

### 7.3 Statistical Outlier Detection

Custom outlier detection:

```yaml
checks:
  analytics.revenue:
    accuracy:
      - failed rows:
          name: revenue_outliers
          fail query: |
            WITH stats AS (
              SELECT
                AVG(revenue) as mean,
                STDDEV(revenue) as stddev
              FROM analytics.revenue
            )
            SELECT r.*,
              (r.revenue - s.mean) / s.stddev as z_score
            FROM analytics.revenue r, stats s
            WHERE ABS((r.revenue - s.mean) / s.stddev) > 3
          samples limit: 20
```

### 7.4 Hierarchical Data Validation

Validate parent-child relationships:

```yaml
checks:
  analytics.categories:
    consistency:
      - failed rows:
          name: orphaned_subcategories
          fail query: |
            SELECT c.*
            FROM analytics.categories c
            LEFT JOIN analytics.categories p ON c.parent_id = p.category_id
            WHERE c.parent_id IS NOT NULL
              AND p.category_id IS NULL
          attributes:
            description: "Subcategories must have valid parent"
      
      - failed rows:
          name: circular_references
          fail query: |
            WITH RECURSIVE category_tree AS (
              SELECT category_id, parent_id, 1 as depth
              FROM analytics.categories
              WHERE parent_id IS NOT NULL
              
              UNION ALL
              
              SELECT c.category_id, c.parent_id, ct.depth + 1
              FROM analytics.categories c
              JOIN category_tree ct ON c.parent_id = ct.category_id
              WHERE ct.depth < 10
            )
            SELECT *
            FROM category_tree
            WHERE depth >= 10
```

### 7.5 Multi-Environment Checks

Different thresholds per environment:

```yaml
# checks/orders_prod.yml
checks:
  analytics.orders:
    filter: "@{environment} = 'prod'"
    completeness:
      - row_count > 10000:
          name: sufficient_orders_prod
```

```yaml
# checks/orders_dev.yml
checks:
  analytics.orders:
    filter: "@{environment} = 'dev'"
    completeness:
      - row_count > 100:
          name: sufficient_orders_dev
```

### 7.6 Custom Metrics

Define reusable metric functions:

```yaml
checks:
  analytics.customers:
    accuracy:
      - failed rows:
          name: suspicious_activity
          fail query: |
            WITH customer_metrics AS (
              SELECT
                customer_id,
                COUNT(*) as order_count,
                SUM(amount) as total_spent,
                MAX(amount) as max_order
              FROM analytics.orders
              WHERE order_date >= CURRENT_DATE - INTERVAL '30 days'
              GROUP BY customer_id
            )
            SELECT *
            FROM customer_metrics
            WHERE order_count > 100  -- Unusually high
              OR total_spent > 100000  -- Unusually expensive
              OR max_order > 50000  -- Single large order
```

[↑ Back to Top](#chapter-05-quality-checks)

---

## 8. Best Practices

### 8.1 Check Organization

**By domain:**

```
checks/
├── customers/
│   ├── completeness.yml
│   ├── validity.yml
│   └── consistency.yml
├── orders/
│   ├── completeness.yml
│   └── timeliness.yml
└── revenue/
    └── accuracy.yml
```

**By priority:**

```
checks/
├── critical.yml      # Must never fail
├── important.yml     # Should rarely fail
├── monitoring.yml    # Track trends
└── experimental.yml  # Testing new checks
```

### 8.2 Naming Conventions

**Use descriptive names:**

```yaml
# ❌ Bad
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: check1

# ✅ Good
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_customer_emails
          attributes:
            description: "All customers must have an email for marketing"
```

**Naming pattern:**
- `<dimension>_<what>_<constraint>`
- Examples:
  - `completeness_email_required`
  - `validity_email_format`
  - `uniqueness_email_no_duplicates`
  - `timeliness_order_within_24hrs`

### 8.3 Threshold Selection

**Start conservative, adjust based on data:**

```yaml
# Step 1: Start with wide range
checks:
  analytics.orders:
    completeness:
      - row_count > 100:
          name: sufficient_orders_v1

# Step 2: Monitor for 30 days, see actual range: 5000-10000

# Step 3: Tighten based on observed patterns
checks:
  analytics.orders:
    completeness:
      - row_count between 4000 and 12000:
          name: sufficient_orders_v2
          attributes:
            description: "Based on 30-day historical analysis"
```

**Use profiles to inform thresholds:**

```sql
-- Query profiles
SELECT
  MIN(metric_value) as min_observed,
  MAX(metric_value) as max_observed,
  AVG(metric_value) as typical,
  STDDEV(metric_value) as stddev
FROM check_results
WHERE check_name = 'row_count'
  AND executed_at >= CURRENT_DATE - INTERVAL '90 days';

-- Set threshold as: typical ± 3*stddev
```

### 8.4 Sample Collection

**Collect enough samples for debugging:**

```yaml
validity:
  - failed rows:
      name: invalid_emails
      fail query: |
        SELECT user_id, email, created_at
        FROM users
        WHERE email NOT LIKE '%@%'
      samples limit: 20  # Enough to see patterns
```

**Don't collect too many:**
- Storage cost increases
- API response size grows
- Usually 10-20 samples is enough

### 8.5 Check Cadence

**Match check frequency to data freshness:**

```yaml
# Real-time data (runs every hour)
checks:
  analytics.orders:
    timeliness:
      - change for row_count >= -30%:
          name: hourly_order_count_check

# Daily batch data (runs once per day)
checks:
  analytics.daily_revenue:
    completeness:
      - row_count = 1:
          name: one_row_per_day
```

**Schedule checks appropriately:**
- High-frequency models → more frequent checks
- Daily batch models → daily checks
- Historical tables → weekly checks

### 8.6 Avoiding Check Fatigue

**Don't create too many checks:**

```yaml
# ❌ Too many (alert fatigue)
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0
      - missing_count(first_name) = 0
      - missing_count(last_name) = 0
      - missing_count(phone) = 0
      - missing_count(address) = 0
      # ... 20 more columns

# ✅ Focus on critical fields
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: email_required
      - missing_count(customer_id) = 0:
          name: customer_id_required
```

**Prioritize:**
1. Critical business fields
2. Fields used in downstream analysis
3. Fields affecting revenue/compliance
4. Skip: internal metadata, optional fields

### 8.7 Documentation

**Add context to every check:**

```yaml
checks:
  analytics.revenue:
    accuracy:
      - avg(revenue) between 50000 and 80000:
          name: revenue_within_expected_range
          attributes:
            description: |
              Based on 90-day historical analysis (Dec 2023 - Feb 2024).
              Alert data team if fails - may indicate:
              - Missing data load
              - Pricing change
              - Seasonal anomaly
            owner: data-team
            slack: #data-quality-alerts
            runbook: https://wiki.company.com/data/revenue-checks
```

### 8.8 Integration Strategy

**Layer validation:**

```sql
-- LAYER 1: Audits (critical - blocks)
MODEL (
  name analytics.orders,
  assertions (
    not_null(columns := (order_id, customer_id)),
    unique_values(columns := (order_id))
  )
);
```

```yaml
# LAYER 2: Checks (monitoring - warns)
checks:
  analytics.orders:
    completeness:
      - row_count between 5000 and 15000:
          name: order_count_in_range
    
    timeliness:
      - change for row_count >= -30%:
          name: order_count_stable
```

```sql
-- LAYER 3: Profiles (observe - tracks)
MODEL (
  name analytics.orders,
  profiles (order_count, revenue, customer_tier)
);
```

[↑ Back to Top](#chapter-05-quality-checks)

---

## 9. Troubleshooting

### 9.1 Check Failures

#### Investigate failed check

```bash
# Run specific check with verbose output
vulcan check --select analytics.customers.invalid_emails --verbose
```

#### Query failed samples

```sql
-- Get samples from last failed run
SELECT *
FROM check_samples
WHERE check_name = 'invalid_emails'
  AND status = 'failed'
ORDER BY executed_at DESC
LIMIT 10;
```

#### Compare to previous runs

```sql
-- Compare current vs previous
WITH current_run AS (
  SELECT metric_value
  FROM check_results
  WHERE check_name = 'row_count'
  ORDER BY executed_at DESC
  LIMIT 1
),
previous_run AS (
  SELECT metric_value
  FROM check_results
  WHERE check_name = 'row_count'
  ORDER BY executed_at DESC
  LIMIT 1 OFFSET 1
)
SELECT
  c.metric_value as current_value,
  p.metric_value as previous_value,
  (c.metric_value - p.metric_value) / p.metric_value * 100 as change_pct
FROM current_run c, previous_run p;
```

### 9.2 Performance Issues

#### Slow check queries

**Problem:** Check takes too long to run

**Solution 1: Add filters**

```yaml
# ❌ Slow - scans entire table
checks:
  analytics.orders:
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders
            WHERE email NOT LIKE '%@%'

# ✅ Fast - filters to recent data
checks:
  analytics.orders:
    filter: "order_date >= CURRENT_DATE - INTERVAL '30 days'"
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders
            WHERE email NOT LIKE '%@%'
```

**Solution 2: Add indexes**

```sql
-- Add index on frequently checked columns
CREATE INDEX idx_orders_email ON analytics.orders(email);
CREATE INDEX idx_orders_order_date ON analytics.orders(order_date);
```

**Solution 3: Sample data**

```yaml
# Check sample instead of full table
checks:
  analytics.orders:
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders TABLESAMPLE (10 PERCENT)
            WHERE email NOT LIKE '%@%'
```

### 9.3 False Positives

#### Threshold too strict

**Problem:** Check fails during normal variance

```yaml
# ❌ Too strict
checks:
  analytics.orders:
    completeness:
      - row_count = 10000  # Exact match

# ✅ Allow variance
checks:
  analytics.orders:
    completeness:
      - row_count between 9000 and 11000  # ±10% variance
```

#### Use anomaly detection instead

```yaml
# Replace strict threshold with ML-based detection
checks:
  analytics.orders:
    accuracy:
      - anomaly detection for row_count:
          name: row_count_anomaly
```

### 9.4 Missing Historical Data

**Problem:** Anomaly detection or change checks fail due to lack of history

**Solution:** Wait for historical data to accumulate

```yaml
# Temporarily disable until enough history
checks:
  analytics.new_table:
    accuracy:
      # - anomaly detection for row_count  # Commented until 30 days of data
      - row_count > 100  # Use simple threshold initially
```

### 9.5 Check Configuration Errors

#### YAML syntax errors

```bash
# Validate YAML syntax
vulcan check --dry-run

# Error output:
# ERROR: Invalid YAML in checks/customers.yml
#   Line 15: unexpected character
```

#### Invalid SQL in fail query

```bash
# Test SQL query directly
vulcan run -c "
  SELECT * FROM analytics.orders
  WHERE email NOT LIKE '%@%'
  LIMIT 5
"
```

### 9.6 Common Errors

**ERROR: Table not found**

```yaml
# ❌ Wrong table name
checks:
  analytics.customer:  # Should be 'customers'
    completeness:
      - row_count > 100
```

**ERROR: Column not found**

```yaml
# ❌ Typo in column name
checks:
  analytics.customers:
    completeness:
      - missing_count(emial) = 0  # Should be 'email'
```

**ERROR: Check always fails**

```yaml
# ❌ Logic error
checks:
  analytics.orders:
    completeness:
      - row_count = 10000  # Exact match rarely works

# ✅ Use range
checks:
  analytics.orders:
    completeness:
      - row_count between 9000 and 11000
```

[↑ Back to Top](#chapter-05-quality-checks)

---

## Summary

You've learned the complete quality checks workflow in Vulcan:

### Core Concepts

**1. Quality Checks**
- YAML-configured validation rules
- Non-blocking (don't stop pipelines)
- Track trends over time
- Integrate with Activity API

**2. Check Types**
- Missing data checks (`missing_count`, `missing_percent`)
- Row count checks (`row_count`)
- Duplicate checks (`duplicate_count`)
- Failed rows (SQL-based)
- Anomaly detection (ML-based)
- Change monitoring (compare to previous)

**3. Data Profiling**
- Automatic statistical metric collection
- Stored in `_check_profiles` table
- Observe patterns without validation
- Inform check threshold selection

**4. Data Quality Strategy**
- **Audits** - Critical, blocking
- **Checks** - Monitoring, non-blocking
- **Profiles** - Observation, tracking

### Next Steps

**Continue to Chapter 6: APIs**

Learn how to:
- Query check results via Activity API
- Build data quality dashboards
- Integrate checks with monitoring systems
- Use Meta Graph API for lineage

**Additional Resources**

- **SodaCL Documentation** - Full language reference
- **Activity API Reference** (Chapter 6) - REST endpoints
- **Examples** - `examples/b2b_saas/checks/` in your Vulcan installation


[↑ Back to Top](#chapter-05-quality-checks)

