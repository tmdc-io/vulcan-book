# Checks

Quality checks are validation rules that monitor your data quality over time without blocking your models. They warn you when something looks off, but they don't stop execution.

Unlike [audits](../audits/audits.md) (which block models execution when they fail), checks run separately or alongside your models and provide non-blocking validation. They're perfect for tracking trends, detecting anomalies, and building up a historical picture of your data quality.

**What makes checks special:**

- Configured in simple YAML files in the `checks/` directory

- Don't block models (your models keep running even if checks fail)

- Track historical patterns and trends

- Support complex statistical analysis

- Integrate with Activity API for monitoring and alerting

## Checks vs Audits vs Profiles

Before we dive in, let's clear up the confusion around these three data quality mechanisms. They all serve different purposes, and understanding when to use each one will save you headaches later.

| Feature | Audits | Checks | Profiles |
|---------|--------|--------|----------|
| **Purpose** | Critical validation | Monitoring & analysis | Observation & tracking |
| **When runs** | With model (inline) | Separately or with models | With model |
| **Blocks models?** | Yes (always) | No | No |
| **Configuration** | In MODEL DDL or .sql files | YAML files (`checks/`) | In MODEL DDL |
| **Output** | Pass/fail | Pass/fail + samples | Statistical metrics |
| **Best for** | Business rules, data integrity | Trend monitoring, anomalies | Understanding data |
| **Historical tracking** | No | Yes (Activity API) | Yes (`_check_profiles`) |

**The Three-Layer Strategy:**

A layered approach to data quality:

```
┌─────────────────────────────────────────┐
│  AUDITS (Critical - Blocks models)   │
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

Audits stop bad data at the door. Checks watch for problems but don't interfere. Profiles observe patterns and help you understand what's normal.

## When to Use Checks

**Use Quality Checks for:**

- Monitoring data quality trends over time (is completeness getting worse?)

- Statistical anomaly detection (did revenue suddenly spike?)

- Cross-model validation (do orders match customers?)

- Non-critical validation (warnings, not blockers)

- Complex validation requiring historical context

- Building data quality dashboards

**Use Audits Instead for:**

- Critical business rules that must pass (revenue can't be negative)

- Model-specific validation (runs inline with the model)

- Simple SQL assertions

- Blocking invalid data from flowing downstream

**Use Profiles Instead for:**

- Understanding data characteristics (what does this column look like?)

- Discovering patterns (not validation)

- Detecting data drift over time

- Informing which checks/audits to add

**Example: Revenue validation strategy**

Here's how you'd layer all three for a revenue table:

```sql
-- AUDIT (Critical - blocks if fails)

-- This stops the models if revenue is invalid
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
# This watches for anomalies but doesn't block
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

-- This just watches and records what it sees
MODEL (
  name analytics.revenue,
  profiles (revenue, order_count, customer_tier)
);
```

## Quick Start

### Your First Check

Let's create your first check. It's simpler than you might think!

Create a file `checks/customers.yml`:

```yaml
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_emails
          attributes:
            description: "All customers must have an email address"
```

That's it! This check ensures that every customer has an email address. When you run your models, this check will run automatically and warn you if any emails are missing.

**What happens when it runs:**

Checks and profiles run automatically when models are executed, either through a **plan** or **run** command. Here's what the execution output looks like:

```bash
Check Executions (1 Models)
└── hello.subscriptions
    ├── completeness (4/4)
    ├── uniqueness (1/1)
    └── validity (3/3)

Profiled 1 model (3 columns):
  warehouse.hello.subscriptions: 3 columns
```

Here are common patterns you'll use:

### Common Check Patterns

Here are the patterns you'll use most often. Copy these, tweak them for your tables, and you're good to go!

#### Pattern 1: Completeness Checks

Make sure required data is present:

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

The first check ensures every order has a customer ID (zero tolerance). The second allows up to 5% missing emails (sometimes that's okay). The third makes sure you have enough data to work with.

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

The `failed rows` check type is flexible. You can write any SQL query. If it returns rows, the check fails and captures those rows as samples.

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

The second example shows composite keys, maybe a customer can have multiple orders, but only one per day.

#### Pattern 4: Anomaly Detection

Detect unusual patterns automatically:

```yaml
checks:
  analytics.daily_revenue:
    accuracy:
      - anomaly detection for row_count:
          name: row_count_anomaly
      
      - anomaly detection for avg(revenue):
          name: revenue_anomaly
```

Anomaly detection learns from historical data and flags when something looks unusual. It needs to run a few times first to build up a baseline, then it detects problems.

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

This compares the current value to the previous run and alerts you if it changes too much. Perfect for catching sudden drops or spikes.

## Check Configuration

### File Structure

Checks live in YAML files in the `checks/` directory. You can organize them however makes sense for your project:

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

- The name doesn't matter (Vulcan reads all files in the directory)

- Organize by domain or table for clarity, whatever helps you find things

### Basic Check Syntax

Here's the basic structure of a check:

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

The `name` field is required and should be descriptive. The `attributes` section is optional but useful for documentation and filtering.

### Data Quality Dimensions

Checks are organized by **8 standard dimensions** (based on ODPS v3.1). Each dimension focuses on a different aspect of data quality:

#### 1. Completeness

No missing required data. This is probably the most common dimension you'll use.

```yaml
completeness:
  - missing_count(customer_id) = 0

  - missing_percent(email) < 5

  - row_count > 1000
```

#### 2. Validity

Data conforms to format/syntax. Is that email actually an email? Is that date in the right format?

```yaml
validity:
  - failed rows:
      fail query: |
        SELECT * FROM table
        WHERE email NOT LIKE '%@%'
```

#### 3. Accuracy

Data matches reality. Is the average age reasonable? Is revenue in the expected range?

```yaml
accuracy:
  - anomaly detection for avg(revenue)

  - avg(age) between 18 and 65
```

#### 4. Consistency

Data agrees across sources. Do orders match customers? Are totals consistent?

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

No duplicates. Is that email really unique? Can customers have multiple orders per day?

```yaml
uniqueness:
  - duplicate_count(email) = 0

  - duplicate_count(order_id) = 0
```

#### 6. Timeliness

Data is current. Is the data fresh? Are updates happening on time?

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

Follows standards. Does the zip code have the right format? Are codes valid?

```yaml
conformity:
  - failed rows:
      fail query: |
        SELECT *
        FROM addresses
        WHERE LENGTH(zip_code) != 5
```

#### 8. Coverage

All records are present. Did we get all the data we expected?

```yaml
coverage:
  - row_count >= 95% of historical_avg(row_count)
```

### Filtering Checks

Sometimes you want to apply checks to a subset of your data. Maybe you only care about completed orders, or US customers. That's where filters come in:

```yaml
checks:
  analytics.orders:
    filter: "status = 'completed' AND order_date >= CURRENT_DATE - INTERVAL '30 days'"
    
    completeness:
      - missing_count(customer_id) = 0:
          name: completed_orders_have_customers
```

**Multiple filters:**

You can define the same table multiple times with different filters:

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

This lets you have different expectations for different regions.

### Check Attributes

Add metadata to your checks to make them easier to manage and understand:

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

- `severity` - `error` (default) or `warning` (warnings are less urgent)

- `tags` - List of tags for filtering/organization (find all "critical" checks easily)

- `owner` - Team or person responsible (who do I call when this fails?)

- Custom attributes - Any key-value pairs (add whatever metadata you need)

## Built-in Check Types

Vulcan provides several built-in check types that cover most common scenarios. Let's walk through them:

### Missing Data Checks

#### `missing_count(column)`

Count of NULL values. Simple and straightforward:

```yaml
completeness:
  - missing_count(email) = 0:
      name: no_missing_emails
  
  - missing_count(phone) <= 100:
      name: phone_mostly_complete
```

The first ensures zero missing emails (strict). The second allows up to 100 missing phone numbers (maybe phones are optional for some customers).

#### `missing_percent(column)`

Percentage of NULL values. Useful when you care about proportions rather than absolute counts:

```yaml
completeness:
  - missing_percent(email) < 5:
      name: email_95_percent_complete
  
  - missing_percent(optional_field) < 50:
      name: optional_field_half_complete
```

This is useful when table sizes vary. 5% missing might be fine for a million-row table but concerning for a hundred-row table.

### Row Count Checks

#### `row_count`

Total rows in table. Use this to ensure you have enough data:

```yaml
completeness:
  - row_count > 1000:
      name: sufficient_data
  
  - row_count between 1000 and 100000:
      name: expected_row_range
```

The second example shows a range check, maybe you know your table should be between 1K and 100K rows, and anything outside that range is suspicious.

#### `row_count` with filter

You can also check row counts on filtered data:

```yaml
completeness:
  - row_count > 500:
      name: sufficient_active_users
      filter: "status = 'active'"
```

This checks that you have at least 500 active users, regardless of how many total users you have.

### Duplicate Count Checks

#### `duplicate_count(column)`

Count of duplicate values. Perfect for ensuring uniqueness:

```yaml
uniqueness:
  - duplicate_count(email) = 0:
      name: unique_emails
  
  - duplicate_count(customer_id) = 0:
      name: unique_customer_ids
```

If this returns anything greater than zero, you've got duplicates. The check fails and you can investigate.

#### `duplicate_count(column1, column2)`

Composite key duplicates. Check combinations of columns:

```yaml
uniqueness:
  - duplicate_count(customer_id, order_date) = 0:
      name: unique_customer_date
      attributes:
        description: "Each customer can have at most one order per day"
```

Maybe customers can have multiple orders, but only one per day. This check enforces that business rule.

### Failed Rows Checks

#### SQL-based validation with samples

This is the most flexible check type, you can write any SQL query you want:

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

**How it works:**

- `fail query` - A SELECT statement that returns invalid rows

- `samples limit` - How many example rows to capture when the check fails (default: 5)

- Returns empty = check passes (no invalid rows found)

- Returns rows = check fails (captures samples so you can see what's wrong)

**Complex validation:**

You can get fancy with joins and CTEs:

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

This finds orders that reference customers that don't exist, a classic referential integrity check.

### Threshold Checks

#### Numeric aggregations

Check aggregated values against thresholds:

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

You can use any aggregation function: `avg`, `sum`, `min`, `max`, `count`, `distinct_count`, etc.

#### Statistical checks

Get fancy with statistical functions:

```yaml
accuracy:
  - stddev(revenue) < 5000:
      name: revenue_low_variance
  
  - percentile(revenue, 95) < 50000:
      name: revenue_95th_percentile_check
```

These detect when your data distribution changes unexpectedly.

### Anomaly Detection

#### ML-based anomaly detection

This is where checks get really powerful. Anomaly detection uses historical check results to learn what's normal and flag unusual patterns:

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
1. Collects historical metric values over time (every time the check runs)
2. Builds a statistical model (mean, standard deviation, trends)
3. Compares current value to expected range
4. Flags significant deviations (typically > 3 standard deviations)

**Requirements:**

- Needs historical data (runs multiple times to build a baseline)

- Works best with regular schedules (daily, hourly)

- More accurate after 30+ data points (the more history, the better)

So if you're setting up anomaly detection, be patient, it needs to run a few times before it's useful. But once it has enough data, it's really good at spotting problems you might not think to check for.

### Change Over Time Checks

#### Monitor changes compared to previous run

Track how metrics change between runs:

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

- `change >= -30%` - Alert if metric drops more than 30% (negative change)

- `change >= 10%` - Alert if metric grows more than 10% (positive change)

- `change between -10% and 10%` - Alert if metric changes more than 10% either way

This catches sudden changes that might indicate a problem or an opportunity.

## Data Profiling

### What is Profiling?

**Profiles automatically collect statistical metrics about your data over time.**

Unlike checks (which validate), profiles **observe and track** data characteristics. They're like a data scientist watching your tables and taking notes:

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

Profiles track how things change over time so you can spot trends and drift.

### Profile Configuration

Enable profiling in your MODEL definition:

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

Just list the columns you want to profile. Vulcan will automatically collect metrics for them every time the model runs.

### Profile Storage

Profiles are stored in the `_check_profiles` table, which you can query like any other table:

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
| `profiled_at` | When the profiling was performed (epoch ms) |
| `created_ts` | When the row was inserted |

### Querying Profiles

#### Track missing count over time

See how null percentages change:

```sql
SELECT
  to_timestamp(profiled_at/1000)::date AS date,
  value_number AS missing_count
FROM _check_profiles
WHERE table_name = 'warehouse.hello.subscriptions'
  AND column_name = 'mrr'
  AND profile_type = 'missing_count'
ORDER BY profiled_at DESC
LIMIT 30;  -- Last 30 days
```

This shows you a time series of missing values for spotting trends.

#### Monitor data drift

Compare current values to historical averages:

```sql
WITH latest_profile AS (
  -- Pick the most recent profiling timestamp for that table/column
  SELECT profiled_at
  FROM _check_profiles
  WHERE table_name = 'warehouse.hello.subscriptions'
    AND column_name = 'mrr'
  ORDER BY profiled_at DESC
  LIMIT 1
),

current AS (
  -- Get the most recent distinct count and average value from that profiling run
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

This query compares current metrics to 30-day historical averages and calculates percentage changes. Perfect for detecting drift!

### Using Profiles to Inform Checks

**Workflow:**

1. **Enable profiling** on new models (just add `profiles (...)` to your MODEL)
2. **Observe patterns** for 30+ days (let profiles collect data)
3. **Identify anomalies** in profile data (query `_check_profiles` and look for trends)
4. **Create checks** based on observed patterns (now you know what's normal)

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

Now your checks are informed by actual data patterns, not guesses. Much better!

### Profile Best Practices

**DO:**

- Profile high-value production tables (the ones that matter)

- Profile columns used in downstream analysis (if it's important, profile it)

- Use profiles to understand new data sources (what does this data look like?)

- Query profiles to detect data drift (is something changing?)

- Use profiles to inform check thresholds (data-driven thresholds are better)

**DON'T:**

- Profile sensitive/PII columns (privacy risk, be careful)

- Profile every column (performance overhead, pick what matters)

- Profile temporary/experimental models (waste of resources)

- Use profiles as a replacement for checks (they serve different purposes)

- Profile very high-frequency models (storage cost adds up)

**When to use profiles:**

- Building new models (understand the data first)

- Monitoring production tables (watch for changes)

- Detecting data drift (is the data changing?)

- Informing audit/check strategy (what should we check?)

- Debugging data quality issues (what's normal vs abnormal?)

**When to skip profiles:**

- Temporary models (they won't be around long)

- Models with sensitive data (privacy concerns)

- Very high-frequency models (> 100 runs/day, storage costs)

- Models where you only need pass/fail validation (profiles are overkill)

## Advanced Patterns

### Cross-Model Validation

Validate relationships between models. This ensures referential integrity:

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

The first check finds orders without valid customers (orphaned records). The second ensures revenue matches across tables (consistency check).

### Time-Based Validation

Ensure data timeliness. Is your data fresh? Are updates happening on schedule?

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

The first check finds stale pending orders (maybe something's stuck). The second catches future dates (data entry errors).

### Statistical Outlier Detection

Custom outlier detection using SQL. Sometimes you need more control than anomaly detection provides:

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

This finds rows where revenue is more than 3 standard deviations from the mean (classic outlier detection). The z-score tells you how extreme each outlier is.

## Best Practices

### Check Organization

Organize your checks in a way that makes sense for your team. Here are two common approaches:

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

Pick whatever works for your team. The important thing is consistency, if everyone knows where to find things, life is easier.

### Naming Conventions

**Use descriptive names:**

```yaml
# Bad - what does "check1" tell you?
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: check1

# Good - clear and descriptive
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_customer_emails
          attributes:
            description: "All customers must have an email for marketing"
```

**Naming pattern:**

- `<dimension>_<what>_<constraint>` or `<what>_<constraint>`

- Examples:

  - `completeness_email_required` or `no_missing_emails`

  - `validity_email_format` or `valid_email_format`

  - `uniqueness_email_no_duplicates` or `unique_emails`

  - `timeliness_order_within_24hrs` or `orders_update_daily`

The key is that someone reading the name should understand what it checks without looking at the code.

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

Don't set thresholds based on guesses, let the data tell you what's normal. Use profiles to understand your data first, then set checks based on what you learn.

**Use profiles to inform thresholds:**

```sql
-- Query profiles to understand your data
SELECT
  MIN(value_number) as min_observed,
  MAX(value_number) as max_observed,
  AVG(value_number) as typical,
  STDDEV(value_number) as stddev
FROM check_results
WHERE check_name = 'row_count'
  AND executed_at >= CURRENT_DATE - INTERVAL '90 days';

-- Set threshold as: typical ± 3*stddev
```

This gives you data-driven thresholds instead of wild guesses. Much better!

### Integration Strategy

**Layer validation:**

```sql
-- LAYER 1: Audits (critical - blocks)

-- Stop bad data at the door
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
# Watch for problems but don't block
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

-- Just watch and learn
MODEL (
  name analytics.orders,
  profiles (order_count, revenue, customer_tier)
);
```

This three-layer approach gives you comprehensive data quality coverage: audits stop problems, checks warn about issues, and profiles help you understand what's normal.

## Troubleshooting

### Check Failures

#### Investigate failed check

When a check fails, you'll want to dig into why:

```bash
# Run specific check with verbose output
vulcan check --select analytics.customers.invalid_emails --verbose
```

This gives you more details about what went wrong.

#### Query failed samples

If your check captures samples (like `failed rows` checks do), you can query them:

```sql
-- Get samples from last failed run
SELECT *
FROM check_samples
WHERE check_name = 'invalid_emails'
  AND status = 'failed'
ORDER BY executed_at DESC
LIMIT 10;
```

This shows you actual rows that failed for debugging.

### Performance Issues

#### Slow check queries

**Problem:** Check takes too long to run

**Solution 1: Add filters**

```yaml
# Slow - scans entire table
checks:
  analytics.orders:
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders
            WHERE email NOT LIKE '%@%'

# Fast - filters to recent data
checks:
  analytics.orders:
    filter: "order_date >= CURRENT_DATE - INTERVAL '30 days'"
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders
            WHERE email NOT LIKE '%@%'
```

Filtering reduces the amount of data the check needs to scan, which makes it faster.

**Solution 2: Add indexes**

```sql
-- Add index on frequently checked columns
CREATE INDEX idx_orders_email ON analytics.orders(email);
CREATE INDEX idx_orders_order_date ON analytics.orders(order_date);
```

Indexes help queries run faster, especially for `failed rows` checks that filter on specific columns.

### False Positives

#### Threshold too strict

**Problem:** Check fails during normal variance

```yaml
# Too strict - exact match is unrealistic
checks:
  analytics.orders:
    completeness:
      - row_count = 10000  # Exact match

# Allow variance - more realistic
checks:
  analytics.orders:
    completeness:
      - row_count between 9000 and 11000  # ±10% variance
```

Real data has variance. Don't set thresholds that are too strict, you'll just get false positives.

#### Use anomaly detection instead

Sometimes strict thresholds aren't the right approach:

```yaml
# Replace strict threshold with ML-based detection
checks:
  analytics.orders:
    accuracy:
      - anomaly detection for row_count:
          name: row_count_anomaly
```

Anomaly detection learns what's normal and adapts to variance, which reduces false positives.

## Summary

Quality checks provide a comprehensive way to monitor data quality over time without blocking your models. Here's what we covered:

### Core Concepts

**1. Quality Checks**
- YAML-configured validation rules

- Non-blocking (don't stop models)

- Track trends over time

- Integrate with Activity API

**2. Check Types**
- Missing data checks (`missing_count`, `missing_percent`)

- Row count checks (`row_count`)

- Duplicate checks (`duplicate_count`)

- Failed rows (SQL-based, flexible)

- Anomaly detection (ML-based, learns from history)

- Change monitoring (compare to previous runs)

**3. Data Profiling**
- Automatic statistical metric collection

- Stored in `_check_profiles` table

- Observe patterns without validation

- Inform check threshold selection

**4. Data Quality Strategy**
- **Audits** - Critical, blocking (stop bad data)

- **Checks** - Monitoring, non-blocking (watch for problems)

- **Profiles** - Observation, tracking (understand what's normal)

Remember: start simple, use profiles to understand your data, then create checks based on what you learn. And don't forget, checks are there to help you, not stress you out. If a check is giving you too many false positives, adjust the threshold or switch to anomaly detection. The goal is better data quality, not perfect check scores.
