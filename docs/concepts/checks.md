# Checks

Quality checks are comprehensive validation rules configured in YAML files that monitor data quality over time. Unlike [audits](audits.md) (which block pipeline execution), checks:

- Run separately from model execution (or alongside it)
- Don't block pipelines (non-blocking validation)
- Track trends and historical patterns
- Support complex statistical analysis
- Integrate with Activity API for monitoring

**Key characteristics:**
- Configured in `checks/` directory
- Use declarative YAML syntax
- Organized by data quality dimensions
- Results stored for historical analysis
- Integrated with Activity API

## Checks vs Audits vs Profiles

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

## When to Use Checks

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

## Quick Start

### Your First Check

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

<!-- **Run the check:**

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
-->

### Check and Profile Execution

Checks and profiles run automatically when models are executed, either through a **plan** or **run** command. Here's what the execution output looks like:

```bash
Check Executions (1 Models)
└── hello.subscriptions
    ├── ✓ completeness (4/4)
    ├── ✓ uniqueness (1/1)
    └── ✓ validity (3/3)

Profiled 1 model (3 columns):
  ✓ warehouse.hello.subscriptions: 3 columns
```


### Common Check Patterns

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

## Check Configuration

### File Structure

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

### Basic Check Syntax

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

### Data Quality Dimensions

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

### Filtering Checks

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

### Check Attributes

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

## Built-in Check Types

### Missing Data Checks

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

### Row Count Checks

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

### Duplicate Count Checks

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

### Failed Rows Checks

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

### Threshold Checks

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

### Anomaly Detection

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

### Change Over Time Checks

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

## Data Profiling

### What is Profiling?

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

### Profile Configuration

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

### Profile Storage

Profiles are stored in the `_check_profiles` table:

| Column | Meaning |
|--------|---------|
| `id` | Unique identifier for this metric row |
| `run_id` | Identifies which profiling run this metric belongs to |
| `table_name` | Name of the table being profiled |
| `column_name` | Name of the column being profiled (NULL for table-level metrics like row_count) |
| `profile_type` | The type of metric, e.g., row_count, distinct, missing_count, frequent_values, min, max, avg_length, etc. |
| `value_number` | Numeric metric value (for metrics like row_count, distinct, min, max, avg, etc.) |
| `value_text` | Used for text values (rare) |
| `value_json` | JSON-encoded metric (for histograms, frequent values, etc.) |
| `value_type` | Type of value stored (number, json, etc.) |
| `profiled_at` | When the profiling was performed (epoch ms in your sample) |
| `created_ts` | When the row was inserted |

### Querying Profiles

#### Track missing count over time

```sql
SELECT
to_timestamp(profiled_at/1000)::date AS date,
value_number AS missing_count
FROM _check_profiles
WHERE table_name = 'warehouse.hello.subscriptions'
AND column_name = 'mrr'
and profile_type = 'missing_count'
ORDER BY profiled_at DESC
LIMIT 30;  -- Last 30 days
```

#### Monitor data drift

```sql
WITH latest_profile AS (
  -- pick the most recent profiling timestamp for that table/column
  SELECT profiled_at
  FROM _check_profiles
  WHERE table_name = 'warehouse.hello.subscriptions'
    AND column_name = 'mrr'
  ORDER BY profiled_at DESC
  LIMIT 1
),

current AS (
  -- get the most recent distinct count and average value from that profiling run
  SELECT
    MAX(CASE WHEN profile_type = 'distinct' THEN value_number END)     AS distinct_count,
    MAX(CASE WHEN profile_type IN ('avg', 'mean', 'average', 'avg_value') THEN value_number END) AS avg_value
  FROM _check_profiles p
  JOIN latest_profile l ON p.profiled_at = l.profiled_at
  WHERE p.table_name = 'warehouse.hello.subscriptions'
    AND p.column_name = 'mrr'
),

historical AS (
  -- 30-day historical averages (profiled_at stored as epoch ms → convert to timestamp)
  SELECT
    AVG(CASE WHEN profile_type = 'distinct' THEN value_number END)      AS avg_distinct,
    AVG(CASE WHEN profile_type IN ('avg', 'mean', 'average', 'avg_value') THEN value_number END) AS avg_mrr
  FROM _check_profiles
  WHERE table_name = 'warehouse.hello.subscriptions'
    AND column_name = 'mrr'
    AND to_timestamp(profiled_at/1000) >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT
  c.distinct_count,
  h.avg_distinct,
  CASE
    WHEN h.avg_distinct IS NULL THEN NULL
    ELSE (c.distinct_count - h.avg_distinct) / NULLIF(h.avg_distinct, 0) * 100
  END AS distinct_change_pct,
  c.avg_value,
  h.avg_mrr,
  CASE
    WHEN h.avg_mrr IS NULL THEN NULL
    ELSE (c.avg_value - h.avg_mrr) / NULLIF(h.avg_mrr, 0) * 100
  END AS mrr_change_pct
FROM current c, historical h;

```

### Using Profiles to Inform Checks

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
    MIN(value_number) AS min_revenue,
    MAX(value_number) AS max_revenue,
    AVG(value_number) AS typical_revenue,
    STDDEV(value_number) AS revenue_stddev
FROM _check_profiles
WHERE table_name = 'warehouse.hello.subscriptions'
  AND column_name = 'mrr'
  AND profile_type IN ('avg', 'mean', 'average', 'avg_value')
  AND to_timestamp(profiled_at/1000) >= CURRENT_DATE - INTERVAL '30 days';


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

### Profile Best Practices

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

## Advanced Patterns

### Cross-Model Validation

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

### Time-Based Validation

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

### Statistical Outlier Detection

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

## Best Practices

### Check Organization

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

### Naming Conventions

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

### Threshold Selection

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

### Integration Strategy

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

## Troubleshooting

### Check Failures

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

### Performance Issues

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

### False Positives

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

## Summary

Quality checks provide a comprehensive way to monitor data quality over time:

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

