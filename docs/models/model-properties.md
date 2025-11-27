# Chapter 2A: Model Properties

> **Complete reference for all MODEL DDL properties** - Every property explained with examples, defaults, and use cases.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 2: Models** - Understanding of:
- Basic MODEL DDL syntax
- Model kinds overview
- Essential properties (`name`, `kind`, `cron`, `grain`)

**SQL Proficiency**
- Basic SQL syntax
- Understanding of data types

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Required Properties](#2-required-properties)
3. [Scheduling & Temporal Properties](#3-scheduling--temporal-properties)
4. [Incremental Model Properties](#4-incremental-model-properties)
5. [Data Quality Properties](#5-data-quality-properties)
6. [Metadata Properties](#6-metadata-properties)
7. [Schema & Type Properties](#7-schema--type-properties)
8. [Warehouse-Specific Properties](#8-warehouse-specific-properties)
9. [Execution Control Properties](#9-execution-control-properties)
10. [Pre/Post Statements](#10-prepost-statements)
11. [Property Quick Reference](#11-property-quick-reference)
12. [Examples by Use Case](#12-examples-by-use-case)

---

## 1. Introduction

### 1.1 What Are Model Properties?

Model properties are configuration options that control how Vulcan models behave, how they're scheduled, how they're stored, and how they're validated.

**Properties are specified in the MODEL DDL:**

```sql
MODEL (
  name analytics.customers,        -- Property: name
  kind FULL,                        -- Property: kind
  cron '@daily',                    -- Property: cron
  owner 'data-team',                -- Property: owner
  description 'Customer dimension table'  -- Property: description
);

SELECT * FROM raw.customers;
```

### 1.2 Property Categories

Properties are organized into categories:

| Category | Purpose | Examples |
|----------|---------|----------|
| **Required** | Must be specified | `name`, `kind` |
| **Scheduling** | When models run | `cron`, `start`, `end`, `interval_unit` |
| **Incremental** | Incremental behavior | `time_column`, `lookback`, `batch_size` |
| **Data Quality** | Validation & relationships | `grain`, `references`, `audits` |
| **Metadata** | Documentation | `description`, `owner`, `tags` |
| **Schema** | Column definitions | `columns`, `dialect` |
| **Warehouse** | Engine-specific | `partitioned_by`, `physical_properties` |
| **Execution** | Runtime control | `enabled`, `gateway`, `optimize_query` |
| **Statements** | Pre/post hooks | `pre_statements`, `post_statements` |

### 1.3 Property Inheritance

Properties can be set at multiple levels:

**1. Project Defaults** (`config.yaml`):
```yaml
model_defaults:
  dialect: snowflake
  start: '2022-01-01'
  owner: 'data-team'
```

**2. Model-Specific** (overrides defaults):
```sql
MODEL (
  name analytics.customers,
  owner 'analytics-team',  -- Overrides project default
  dialect bigquery         -- Overrides project default
);
```

**3. Property Merging**:
- `physical_properties`, `virtual_properties`, `session_properties` are **merged** (not replaced)
- Model-level properties take precedence over project defaults
- Set to `None` to unset a project-level property

**Example:**
```yaml
# config.yaml
model_defaults:
  physical_properties:
    partition_expiration_days: 7
    require_partition_filter: true
```

```sql
-- models/customers.sql
MODEL (
  name analytics.customers,
  physical_properties (
    partition_expiration_days = 14,  -- Override: 7 → 14
    require_partition_filter = None,  -- Unset: remove from model
    creatable_type = TRANSIENT        -- Add: new property
  )
);
```

### 1.4 Property Defaults

Most properties are optional and have sensible defaults:

| Property | Default | Notes |
|----------|---------|-------|
| `kind` | `VIEW` (SQL) / `FULL` (Python) | Depends on model type |
| `cron` | `@daily` | Run once per day |
| `start` | `yesterday` | Historical backfill start |
| `enabled` | `true` | Model is active |
| `optimize_query` | `true` | SQLGlot optimization enabled |
| `formatting` | `true` | Format with `vulcan format` |
| `allow_partials` | `false` | Only process complete intervals |
| `forward_only` | `false` | Changes trigger rebuilds |
| `disable_restatement` | `false` | Restatement allowed |
| `on_destructive_change` | `error` | Block breaking changes |
| `on_additive_change` | `allow` | Allow new columns |

**For comprehensive defaults, see [Property Quick Reference](#11-property-quick-reference)**

[↑ Back to Top](#chapter-2a-model-properties)

---

## 2. Required Properties

### 2.1 `name`

**Type:** `string`  
**Required:** Yes (unless `infer_names` is enabled)  
**Default:** None

The fully qualified model name, typically `schema.table` format.

**Syntax:**
```sql
MODEL (
  name analytics.customers  -- schema.table
);
```

**Rules:**
- Must include at least schema (`schema.table`)
- Can include catalog (`catalog.schema.table`)
- Must be unique within project
- Case-sensitive

**Examples:**
```sql
-- Simple schema.table
MODEL (name analytics.customers);

-- With catalog (BigQuery, Snowflake)
MODEL (name my_project.analytics.customers);

-- Simple table name (uses default schema)
MODEL (name customers);  -- Requires infer_names or default schema
```

**Name Inference:**

If `infer_names` is enabled in `config.yaml`:
```yaml
models:
  infer_names: true
```

Model names are inferred from file path:
```
models/
├── analytics/
│   └── customers.sql  → name: analytics.customers
└── staging/
    └── orders.sql     → name: staging.orders
```

### 2.2 `kind`

**Type:** `string` or `dict`  
**Required:** Yes  
**Default:** `VIEW` (SQL models), `FULL` (Python models)

The model kind determines how data is materialized and refreshed.

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  kind FULL  -- Simple kind
);

-- Or with parameters:
MODEL (
  name analytics.daily_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    lookback 3
  )
);
```

**Supported Kinds:**

| Kind | Description | Default For |
|------|-------------|-------------|
| `VIEW` | Query-time view | SQL models |
| `FULL` | Complete refresh | Python models |
| `INCREMENTAL_BY_TIME_RANGE` | Time-partitioned incremental | - |
| `INCREMENTAL_BY_UNIQUE_KEY` | Upsert-based incremental | - |
| `INCREMENTAL_BY_PARTITION` | Partition-based incremental | - |
| `SCD_TYPE_2` | Slowly changing dimension | - |
| `SEED` | CSV file loader | - |
| `EXTERNAL` | External table metadata | - |
| `EMBEDDED` | Inline subquery | - |
| `MANAGED` | Engine-managed table | - |

**For detailed model kind documentation, see [Chapter 2: Models](02-models.md#4-model-kinds)**

**Python Models:**

```python
from vulcan import model

# Simple kind
@model("analytics.customers", kind="FULL")

# Incremental with parameters
@model(
    "analytics.daily_events",
    kind={
        "name": "INCREMENTAL_BY_TIME_RANGE",
        "time_column": "event_date",
        "lookback": 3
    }
)
```

[↑ Back to Top](#chapter-2a-model-properties)

---

## 3. Scheduling & Temporal Properties

These properties control when models run and how time intervals are calculated.

### 3.1 `cron`

**Type:** `string`  
**Required:** No  
**Default:** `@daily`

The cron expression specifying how often the model should be refreshed.

**Syntax:**
```sql
MODEL (
  name analytics.daily_metrics,
  cron '@daily'  -- Simple frequency
);

-- Or cron expression:
MODEL (
  name analytics.hourly_events,
  cron '0 * * * *'  -- Every hour at minute 0
);
```

**Supported Formats:**

**1. Simple Frequencies:**
- `@hourly` - Run every hour at minute 0
- `@daily` - Run every day at midnight UTC
- `@weekly` - Run every week on Sunday at midnight UTC
- `@monthly` - Run on the 1st of each month at midnight UTC

**2. Cron Expressions:**

Standard cron format: `minute hour day month weekday`

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

**Common Cron Examples:**

| Expression | Description |
|------------|-------------|
| `0 * * * *` | Every hour at minute 0 |
| `0 9 * * *` | Every day at 9:00 AM UTC |
| `0 9 * * 1-5` | Every weekday at 9:00 AM UTC |
| `0 0 1 * *` | First day of each month at midnight |
| `*/15 * * * *` | Every 15 minutes |
| `0 0,12 * * *` | Twice daily (midnight and noon) |

**Timezone:**

By default, all cron times are in **UTC**. Use `cron_tz` to specify a different timezone for scheduling (but data intervals remain UTC).

**Examples:**

```sql
-- Daily at midnight UTC
MODEL (
  name analytics.daily_summary,
  cron '@daily'
);

-- Daily at 9 AM Pacific Time
MODEL (
  name analytics.daily_summary_pst,
  cron '@daily',
  cron_tz 'America/Los_Angeles'
);

-- Every hour
MODEL (
  name analytics.hourly_metrics,
  cron '@hourly'
);

-- Custom: Every 6 hours
MODEL (
  name analytics.six_hourly_updates,
  cron '0 */6 * * *'
);
```

**Python Models:**

```python
@model(
    "analytics.daily_metrics",
    cron="@daily"
)

# Or with timezone
@model(
    "analytics.daily_metrics_pst",
    cron="@daily",
    cron_tz="America/Los_Angeles"
)
```

### 3.2 `cron_tz`

**Type:** `string` (timezone name)  
**Required:** No  
**Default:** `UTC`

The timezone for the cron schedule. **Important:** This only affects **when** the model runs, not the time intervals processed.

**Syntax:**
```sql
MODEL (
  name analytics.daily_summary,
  cron '@daily',
  cron_tz 'America/Los_Angeles'  -- Run at midnight Pacific Time
);
```

**Key Points:**

1. **Scheduling Only:** `cron_tz` affects when the model runs, not data intervals
2. **Data Intervals Stay UTC:** `@start_ds` and `@end_ds` variables are always UTC
3. **Timezone Names:** Use IANA timezone database names (e.g., `America/New_York`, `Europe/London`)

**Example:**

```sql
MODEL (
  name analytics.daily_summary,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',
  cron_tz 'America/Los_Angeles',  -- Runs at 12:00 AM Pacific
  start '2024-01-01'
);

SELECT *
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
-- @start_ds and @end_ds are UTC dates, regardless of cron_tz
```

**What happens:**
- Model runs at **12:00 AM Pacific Time** (8:00 AM UTC the next day)
- But `@start_ds` and `@end_ds` represent **UTC date boundaries**
- Your `time_column` should be in UTC (see [time_column](#time_column))

**Common Timezones:**

| Timezone | IANA Name |
|----------|-----------|
| Pacific Time | `America/Los_Angeles` |
| Mountain Time | `America/Denver` |
| Central Time | `America/Chicago` |
| Eastern Time | `America/New_York` |
| UTC | `UTC` (default) |
| London | `Europe/London` |
| Tokyo | `Asia/Tokyo` |

### 3.3 `interval_unit`

**Type:** `string`  
**Required:** No  
**Default:** Inferred from `cron`

The temporal granularity with which time intervals are calculated for the model.

**Supported Values:**
- `year`
- `month`
- `day`
- `hour`
- `half_hour` (30 minutes)
- `quarter_hour` (15 minutes)
- `five_minute` (5 minutes)

**Syntax:**
```sql
MODEL (
  name analytics.daily_events,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',
  interval_unit 'day'  -- Explicitly set
);
```

**How It's Determined:**

**1. From Simple Frequencies:**
- `@hourly` → `interval_unit: hour`
- `@daily` → `interval_unit: day`
- `@weekly` → `interval_unit: day` (weekly runs, but daily granularity)
- `@monthly` → `interval_unit: month`

**2. From Cron Expressions:**

Vulcan analyzes the cron expression:
1. Generates next 5 run times
2. Calculates minimum duration between runs
3. Sets `interval_unit` to largest unit ≤ minimum duration

**Example:**
- Cron: `*/43 * * * *` (every 43 minutes)
- Minimum duration: 43 minutes
- `interval_unit`: `half_hour` (30 minutes is largest unit ≤ 43 minutes)

**3. Explicit Specification:**

You can override the inferred value:

```sql
MODEL (
  name analytics.up_until_7am,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '30 7 * * *',      -- Run at 7:30 AM daily
  interval_unit 'hour',   -- Process hourly intervals, not daily
  start '2024-01-01'
);
```

**Why specify explicitly?**

**Use Case: Run daily, but process hourly data**

```sql
MODEL (
  name analytics.daily_summary,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',           -- Run once per day
  interval_unit 'hour',    -- But process hourly intervals
  start '2024-01-01'
);

SELECT *
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
-- Processes all hours from start of day to end of day
```

**Use Case: Run hourly, process daily intervals**

```sql
MODEL (
  name analytics.hourly_backfill,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@hourly',          -- Run every hour
  interval_unit 'day',     -- But process daily intervals
  allow_partials true,     -- Allow partial days
  start '2024-01-01'
);
```

**Relationship to `lookback`:**

`lookback` is calculated in `interval_unit`s:

```sql
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',
  interval_unit 'day',
  lookback 7  -- Reprocess last 7 days
);

-- If interval_unit was 'hour':
-- lookback 7 would mean last 7 hours
```

### 3.4 `start`

**Type:** `string` or `integer` (epoch milliseconds)  
**Required:** No  
**Default:** `yesterday`

The earliest date/time interval that should be processed by the model.

**Syntax:**
```sql
MODEL (
  name analytics.historical_data,
  start '2022-01-01'  -- Absolute date
);

-- Or relative:
MODEL (
  name analytics.recent_data,
  start '1 year ago'  -- Relative date
);
```

**Supported Formats:**

**1. Absolute Dates:**
- `'2022-01-01'` - Date only
- `'2022-01-01 00:00:00'` - Date and time
- `1640995200000` - Epoch milliseconds

**2. Relative Dates:**
- `'1 year ago'`
- `'6 months ago'`
- `'30 days ago'`
- `'yesterday'` (default)

**Examples:**

```sql
-- Start from specific date
MODEL (
  name analytics.customers,
  start '2020-01-01'
);

-- Start from 1 year ago
MODEL (
  name analytics.recent_customers,
  start '1 year ago'
);

-- Start from yesterday (default)
MODEL (
  name analytics.daily_metrics
  -- start defaults to 'yesterday'
);
```

**Use Cases:**

**1. Historical Backfill:**
```sql
MODEL (
  name analytics.all_time_revenue,
  start '2010-01-01'  -- Process 14+ years of data
);
```

**2. Recent Data Only:**
```sql
MODEL (
  name analytics.recent_events,
  start '30 days ago'  -- Only last 30 days
);
```

**3. Project Default:**
```yaml
# config.yaml
model_defaults:
  start: '2022-01-01'  -- All models start from this date
```

### 3.5 `end`

**Type:** `string` or `integer` (epoch milliseconds)  
**Required:** No  
**Default:** None (process indefinitely)

The latest date/time interval that should be processed by the model.

**Syntax:**
```sql
MODEL (
  name analytics.historical_snapshot,
  start '2022-01-01',
  end '2023-12-31'  -- Stop processing after this date
);
```

**Use Cases:**

**1. Historical Snapshot:**
```sql
MODEL (
  name analytics.2023_data,
  start '2023-01-01',
  end '2023-12-31'  -- Only process 2023 data
);
```

**2. Temporary Models:**
```sql
MODEL (
  name analytics.temp_analysis,
  start '2024-01-01',
  end '2024-06-30'  -- Stop after June 2024
);
```

**3. Relative End:**
```sql
MODEL (
  name analytics.past_year,
  start '1 year ago',
  end 'yesterday'  -- Up to yesterday
);
```

**Note:** Models with `end` set will stop processing new intervals after the end date. This is useful for:
- Historical snapshots
- Temporary analysis models
- Deprecated models being phased out

### 3.6 `allow_partials`

**Type:** `boolean`  
**Required:** No  
**Default:** `false`

Whether this model can process partial (incomplete) data intervals.

**Syntax:**
```sql
MODEL (
  name analytics.real_time_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@hourly',
  allow_partials true  -- Process incomplete intervals
);
```

**Default Behavior (`allow_partials: false`):**

Models only process **complete intervals**:

```sql
MODEL (
  name analytics.daily_summary,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',
  interval_unit 'day',
  -- allow_partials: false (default)
);
```

**What happens:**
- Model runs at midnight UTC
- Only processes data from **completed days** (yesterday and earlier)
- Today's data is **not** processed until tomorrow (when today is complete)

**With `allow_partials: true`:**

```sql
MODEL (
  name analytics.real_time_summary,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@hourly',        -- Run every hour
  interval_unit 'day',   -- Process daily intervals
  allow_partials true    -- But allow partial days
);
```

**What happens:**
- Model runs every hour
- Processes today's data **as it accumulates**
- Data is temporary - will be reprocessed when the day is complete

**⚠️ Warning:**

**Use `allow_partials` with caution:**

1. **Data Completeness:** Partial intervals may be incomplete
2. **Debugging Difficulty:** Hard to distinguish between:
   - Missing data (pipeline issue)
   - Partial data (expected behavior)
3. **Reprocessing:** Partial data is temporary and will be reprocessed

**Recommended Use Cases:**

✅ **Good:**
- Real-time dashboards (stale data acceptable)
- Monitoring systems (need current state)
- High-frequency models (hourly runs, daily intervals)

❌ **Avoid:**
- Financial reporting (need complete data)
- Critical business metrics (accuracy required)
- Models feeding downstream critical systems

**Example: Real-Time Dashboard**

```sql
MODEL (
  name analytics.real_time_dashboard,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@hourly',        -- Update every hour
  interval_unit 'day',   -- Daily metrics
  allow_partials true,   -- Show today's partial data
  start '2024-01-01'
);

SELECT
  DATE_TRUNC('day', event_date) as metric_date,
  COUNT(*) as event_count,
  SUM(revenue) as daily_revenue
FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds
GROUP BY 1;
-- Shows today's partial data, updates hourly
```

**Combining with `--ignore-cron`:**

To force a model to run every time (ignoring cron schedule):

```bash
vulcan run --ignore-cron
```

**Requirements:**
- `allow_partials: true` must be set
- `--ignore-cron` flag must be used
- Both are required for guaranteed execution

**Why both?**
- `allow_partials: true` allows partial intervals
- `--ignore-cron` ignores schedule timing
- Together: model runs every time, processes partial data

[↑ Back to Top](#chapter-2a-model-properties)

---

## 4. Incremental Model Properties

These properties control incremental model behavior. They are specified **within the `kind` definition** for incremental models.

### 4.1 Properties for All Incremental Models

These properties apply to all incremental model kinds (`INCREMENTAL_BY_TIME_RANGE`, `INCREMENTAL_BY_UNIQUE_KEY`, `INCREMENTAL_BY_PARTITION`, `SCD_TYPE_2`):

#### `forward_only`

**Type:** `boolean`  
**Required:** No  
**Default:** `false`

Whether all changes to this model should be forward-only (no rebuilds).

**Syntax:**
```sql
MODEL (
  name analytics.large_table,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only true  -- Changes don't trigger rebuilds
  )
);
```

**What it does:**
- Changes are classified as forward-only
- No automatic rebuilds when model changes
- Useful for very large tables where rebuilds are expensive

**⚠️ Warning:** Forward-only models can't be restated easily. Use with caution.

#### `on_destructive_change`

**Type:** `string`  
**Required:** No  
**Default:** `error`

What happens when a forward-only model has a destructive schema change (dropping columns, incompatible type changes).

**Valid Values:**
- `error` (default) - Block the change
- `warn` - Allow but warn
- `allow` - Allow silently
- `ignore` - Ignore the check

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only true,
    on_destructive_change 'error'  -- Block breaking changes
  )
);
```

**Example Destructive Changes:**
- Dropping a column
- Changing column type incompatibly (`INT` → `VARCHAR`)
- Making nullable column non-nullable

#### `on_additive_change`

**Type:** `string`  
**Required:** No  
**Default:** `allow`

What happens when a forward-only model has an additive schema change (adding columns, compatible type changes).

**Valid Values:**
- `allow` (default) - Allow silently
- `warn` - Allow but warn
- `error` - Block the change
- `ignore` - Ignore the check

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only true,
    on_additive_change 'allow'  -- Allow new columns
  )
);
```

**Example Additive Changes:**
- Adding a new column
- Making non-nullable column nullable
- Widening column types (`INT` → `BIGINT`)

#### `disable_restatement`

**Type:** `boolean`  
**Required:** No  
**Default:** `false`

Whether restatement (reprocessing historical data) is disabled for this model.

**Syntax:**
```sql
MODEL (
  name analytics.append_only_log,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key log_id,
    disable_restatement true  -- Never reprocess history
  )
);
```

**Use Cases:**
- Append-only tables (can't reprocess)
- Audit logs (must preserve history)
- Event streams (idempotency concerns)

**⚠️ Warning:** Once set, historical data cannot be reprocessed. Use with caution.

### 4.2 Properties for INCREMENTAL_BY_TIME_RANGE

#### `time_column`

**Type:** `string`  
**Required:** Yes  
**Default:** None

The column containing the timestamp/date for each row. **Must be in UTC timezone.**

**Syntax:**
```sql
MODEL (
  name analytics.daily_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date  -- Required
  )
);
```

**With Format String:**

If your time column has a non-standard format:

```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_timestamp,
    format '%Y-%m-%d %H:%M:%S'  -- Custom format
  )
);
```

**Format String Syntax:**

Uses Python `strftime` format codes:

| Code | Meaning | Example |
|------|---------|---------|
| `%Y` | 4-digit year | `2024` |
| `%m` | Month (01-12) | `01` |
| `%d` | Day (01-31) | `15` |
| `%H` | Hour (00-23) | `14` |
| `%M` | Minute (00-59) | `30` |
| `%S` | Second (00-59) | `45` |

**Default Format:** `%Y-%m-%d` (for DATE columns)

**⚠️ Important: UTC Requirement**

The `time_column` **must be in UTC timezone**. This ensures:
- Correct interval calculations
- Proper interaction with `@start_ds` and `@end_ds` macros
- Consistent behavior across timezones

**Example:**
```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_timestamp_utc  -- Must be UTC
  )
);

SELECT
  event_id,
  CONVERT_TIMEZONE('America/New_York', 'UTC', event_timestamp) as event_timestamp_utc,
  event_data
FROM raw.events
WHERE event_timestamp_utc BETWEEN @start_ds AND @end_ds;
```

#### `lookback`

**Type:** `integer`  
**Required:** No  
**Default:** `0`

The number of `interval_unit`s prior to the current interval that should be reprocessed (for late-arriving data).

**Syntax:**
```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    lookback 3  -- Reprocess last 3 days
  ),
  cron '@daily',
  interval_unit 'day'
);
```

**How It Works:**

**Without lookback (`lookback: 0`):**
- Processes only the current interval
- Late-arriving data from previous intervals is ignored

**With lookback (`lookback: 3`):**
- Processes current interval **plus** last 3 intervals
- Catches late-arriving data from previous days

**Example:**

```sql
MODEL (
  name analytics.daily_orders,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date,
    lookback 7  -- Reprocess last 7 days
  ),
  cron '@daily',
  interval_unit 'day'
);

SELECT *
FROM raw.orders
WHERE order_date BETWEEN @start_ds AND @end_ds;
-- Processes: today + last 7 days (8 days total)
```

**Lookback Calculation:**

Lookback is calculated in `interval_unit`s:

| `interval_unit` | `lookback: 3` means |
|-----------------|---------------------|
| `day` | Last 3 days |
| `hour` | Last 3 hours |
| `month` | Last 3 months |

**Use Cases:**

✅ **Good for:**
- Late-arriving data (orders arrive days after event)
- Dimension updates (customer data changes retroactively)
- Data corrections (fixing historical errors)

❌ **Avoid:**
- Real-time data (no late arrivals)
- Append-only logs (no updates)
- Very large tables (performance impact)

**Performance Impact:**

- `lookback: 0` - Processes 1 interval
- `lookback: 7` - Processes 8 intervals (7 + current)
- `lookback: 30` - Processes 31 intervals

**Recommendation:** Start with `lookback: 0`, increase if you see late-arriving data issues.

#### `batch_size`

**Type:** `integer`  
**Required:** No  
**Default:** `None` (process all intervals in one job)

The maximum number of `interval_unit`s to process in a single backfill job.

**Syntax:**
```sql
MODEL (
  name analytics.hourly_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 24  -- Process 24 hours per batch
  ),
  cron '@hourly',
  interval_unit 'hour'
);
```

**Why Use Batch Size?**

When backfilling large amounts of data, processing all intervals in one job can:
- Exceed query timeout limits
- Consume too much memory
- Fail and lose progress

**Example Calculation:**

**Scenario:** Model hasn't run in 3 days, `cron: @hourly`, `interval_unit: hour`

- Total intervals: 3 days × 24 hours = 72 intervals

**Without `batch_size`:**
- 1 job processes all 72 intervals
- Risk: Timeout or memory issues

**With `batch_size: 12`:**
- 72 intervals ÷ 12 = 6 jobs
- Each job processes 12 hours
- More reliable, can retry individual batches

**Batch Size Examples:**

```sql
-- Daily model, backfill 30 days
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@daily',
  interval_unit 'day',
  batch_size 7  -- Process 7 days per batch
);
-- 30 days ÷ 7 = ~5 batches

-- Hourly model, backfill 1 week
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  cron '@hourly',
  interval_unit 'hour',
  batch_size 24  -- Process 24 hours per batch
);
-- 168 hours ÷ 24 = 7 batches
```

**Recommendation:**
- Start without `batch_size` (let Vulcan handle it)
- Add if you see timeout/memory issues
- Typical values: 7-30 days for daily models, 12-48 hours for hourly models

#### `batch_concurrency`

**Type:** `integer`  
**Required:** No  
**Default:** Connection setting (typically 5-10)

The maximum number of batches that can run concurrently for this model.

**Syntax:**
```sql
MODEL (
  name analytics.hourly_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    batch_size 12,
    batch_concurrency 3  -- Max 3 batches in parallel
  ),
  cron '@hourly'
);
```

**How It Works:**

With `batch_size: 12` and `batch_concurrency: 3`:
- Creates batches of 12 intervals each
- Runs up to 3 batches simultaneously
- When one completes, starts the next

**Example:**

**72 intervals, `batch_size: 12`, `batch_concurrency: 3`:**

```
Batch 1: Intervals 1-12   [Running]
Batch 2: Intervals 13-24  [Running]
Batch 3: Intervals 25-36  [Running]
Batch 4: Intervals 37-48  [Waiting]
Batch 5: Intervals 49-60  [Waiting]
Batch 6: Intervals 61-72  [Waiting]

When Batch 1 completes → Batch 4 starts
```

**Tuning:**

**Higher concurrency:**
- ✅ Faster backfills
- ❌ More warehouse resources
- ❌ May hit connection limits

**Lower concurrency:**
- ✅ Less resource usage
- ❌ Slower backfills
- ✅ More reliable

**Recommendation:**
- Start with default (connection setting)
- Increase if backfills are too slow
- Decrease if hitting resource limits

**Note:** `INCREMENTAL_BY_UNIQUE_KEY` models **cannot** use `batch_concurrency` (they can't run in parallel safely).

### 4.3 Properties for INCREMENTAL_BY_UNIQUE_KEY

#### `unique_key`

**Type:** `string` or `array[string]`  
**Required:** Yes  
**Default:** None

The column(s) that uniquely identify each row (used for upsert logic).

**Syntax:**
```sql
-- Single column key
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  )
);

-- Composite key
MODEL (
  name analytics.customer_products,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key (customer_id, product_id)
  )
);
```

**How It Works:**

Vulcan uses `MERGE` (or equivalent) to:
1. Insert new rows (key doesn't exist)
2. Update existing rows (key matches)

**Example:**

```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  ),
  cron '@daily'
);

SELECT
  customer_id,
  customer_name,
  email,
  updated_at
FROM raw.customers
WHERE updated_at >= @start_ds;
-- Upserts based on customer_id
```

**Composite Keys:**

```sql
MODEL (
  name analytics.order_line_items,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key (order_id, line_item_id)
  )
);
```

**⚠️ Important:**
- `unique_key` must be unique in source data
- Use `grain` property to declare uniqueness
- Add `unique_values` audit to validate

#### `when_matched`

**Type:** `string` (SQL expression)  
**Required:** No  
**Default:** Update all columns

Custom SQL logic for updating columns when a match occurs (MERGE UPDATE clause).

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    when_matched 'UPDATE SET name = source.name, email = source.email, updated_at = source.updated_at'
  )
);
```

**Default Behavior:**

Without `when_matched`, all columns are updated:
```sql
-- Equivalent to:
UPDATE SET 
  name = source.name,
  email = source.email,
  updated_at = source.updated_at,
  -- ... all columns
```

**Custom Logic:**

**Example: Only update if source is newer:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    when_matched 'UPDATE SET 
      name = source.name,
      email = source.email,
      updated_at = source.updated_at
      WHERE target.updated_at < source.updated_at'
  )
);
```

**Example: Preserve certain columns:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    when_matched 'UPDATE SET 
      email = source.email,
      updated_at = source.updated_at
      -- name column preserved (not updated)'
  )
);
```

**⚠️ Note:** `when_matched` is only available on engines that support `MERGE` (Snowflake, BigQuery, Spark). Other engines use INSERT ... ON CONFLICT or equivalent.

#### `merge_filter`

**Type:** `string` (SQL predicate)  
**Required:** No  
**Default:** None

Additional filter condition for the MERGE ON clause (beyond key matching).

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    merge_filter 'source.status != ''deleted'''
  )
);
```

**Use Cases:**

**1. Filter Deleted Records:**
```sql
MODEL (
  name analytics.active_customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    merge_filter 'source.status != ''deleted'''
  )
);
-- Only merge if source record is not deleted
```

**2. Conditional Updates:**
```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    merge_filter 'source.updated_at > target.updated_at'
  )
);
-- Only merge if source is newer
```

**3. Status-Based Filtering:**
```sql
MODEL (
  name analytics.valid_orders,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key order_id,
    merge_filter 'source.status IN (''pending'', ''completed'')'
  )
);
-- Only merge orders in specific statuses
```

**⚠️ Note:** `merge_filter` is only available on engines that support `MERGE`.

### 4.4 Properties for SCD_TYPE_2

#### `unique_key` (SCD Type 2)

**Type:** `array[string]`  
**Required:** Yes  
**Default:** None

The column(s) that uniquely identify the business entity (not the row - rows can have same key with different validity periods).

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2 (
    unique_key (customer_id)
  )
);
```

**Note:** For SCD Type 2, `unique_key` is always an array (even for single columns).

#### `valid_from_name`

**Type:** `string`  
**Required:** No  
**Default:** `valid_from`

The name of the column storing when the row became valid.

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2 (
    unique_key (customer_id),
    valid_from_name 'effective_date'  -- Custom column name
  )
);
```

#### `valid_to_name`

**Type:** `string`  
**Required:** No  
**Default:** `valid_to`

The name of the column storing when the row became invalid (NULL for current rows).

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2 (
    unique_key (customer_id),
    valid_to_name 'expiry_date'  -- Custom column name
  )
);
```

#### `invalidate_hard_deletes`

**Type:** `boolean`  
**Required:** No  
**Default:** `true`

Whether records missing from source should be marked as invalid (soft delete).

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2 (
    unique_key (customer_id),
    invalidate_hard_deletes true  -- Mark deleted records as invalid
  )
);
```

**Behavior:**

**`invalidate_hard_deletes: true` (default):**
- Source record deleted → Set `valid_to` to current timestamp
- Preserves historical record
- Current query filters out invalid records

**`invalidate_hard_deletes: false`:**
- Source record deleted → No change
- Historical record remains valid
- Use when deletions shouldn't affect history

#### SCD_TYPE_2_BY_TIME Properties

#### `updated_at_name`

**Type:** `string`  
**Required:** No  
**Default:** `updated_at`

The column name storing when the source record was last updated.

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_TIME (
    unique_key (customer_id),
    updated_at_name 'last_modified'  -- Custom column name
  )
);
```

#### `updated_at_as_valid_from`

**Type:** `boolean`  
**Required:** No  
**Default:** `false`

Whether to use `updated_at` value as `valid_from` (instead of 1970-01-01).

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_TIME (
    unique_key (customer_id),
    updated_at_as_valid_from true  -- Use actual update time
  )
);
```

**Behavior:**

**`updated_at_as_valid_from: false` (default):**
- New rows: `valid_from = 1970-01-01 00:00:00`
- Historical rows: `valid_from = previous valid_to`

**`updated_at_as_valid_from: true`:**
- New rows: `valid_from = updated_at` value
- More accurate historical tracking

#### SCD_TYPE_2_BY_COLUMN Properties

#### `columns`

**Type:** `string` or `array[string]`  
**Required:** Yes  
**Default:** None

Columns whose changes trigger a new SCD Type 2 row. Use `*` to track all columns.

**Syntax:**
```sql
-- Track specific columns
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_COLUMN (
    unique_key (customer_id),
    columns (name, email, tier)  -- Track changes to these
  )
);

-- Track all columns
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_COLUMN (
    unique_key (customer_id),
    columns '*'  -- Track any column change
  )
);
```

#### `execution_time_as_valid_from`

**Type:** `boolean`  
**Required:** No  
**Default:** `false`

Whether to use execution time as `valid_from` (instead of 1970-01-01).

**Syntax:**
```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_COLUMN (
    unique_key (customer_id),
    columns '*',
    execution_time_as_valid_from true  -- Use pipeline execution time
  )
);
```

**Behavior:**

**`execution_time_as_valid_from: false` (default):**
- New rows: `valid_from = 1970-01-01 00:00:00`
- Historical rows: `valid_from = previous valid_to`

**`execution_time_as_valid_from: true`:**
- New rows: `valid_from = execution_time` (when pipeline ran)
- More accurate for column-based change detection

### 4.5 Auto-Restatement Properties

#### `auto_restatement_cron`

**Type:** `string` (cron expression)  
**Required:** No  
**Default:** None

Cron expression determining when to automatically restate this model.

**Syntax:**
```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    auto_restatement_cron '@weekly'  -- Restate weekly
  ),
  cron '@daily'
);
```

**How It Works:**

- Model runs on its normal `cron` schedule (`@daily`)
- Additionally, restates on `auto_restatement_cron` schedule (`@weekly`)
- Restatement reprocesses historical data (see `auto_restatement_intervals`)

**⚠️ Warning:**

**Not Recommended:** Auto-restatement often indicates:
- Data quality issues (late-arriving data)
- Model design problems (should use `lookback` instead)
- Dependency chain issues

**Prefer `lookback` Instead:**

```sql
-- ❌ Not recommended
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    auto_restatement_cron '@weekly'
  )
);

-- ✅ Better approach
MODEL (
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    lookback 7  -- Reprocess last 7 days on each run
  )
);
```

**Use Cases:**

✅ **Valid Use Cases:**
- Dimension table updates (customer data changes retroactively)
- Data corrections (fixing historical errors)
- Periodic full refresh (less frequent than model cron)

**Note:** Models with `auto_restatement_cron` can only be previewed in dev (data not reused in production).

#### `auto_restatement_intervals`

**Type:** `integer`  
**Required:** No  
**Default:** None (restate entire model)

The number of last intervals to restate (only for `INCREMENTAL_BY_TIME_RANGE`).

**Syntax:**
```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    auto_restatement_cron '@weekly',
    auto_restatement_intervals 7  -- Restate last 7 days
  ),
  cron '@daily'
);
```

**Behavior:**

**Without `auto_restatement_intervals`:**
- Restates **entire model** (all historical data)
- Expensive for large tables

**With `auto_restatement_intervals: 7`:**
- Restates only **last 7 intervals**
- More efficient, targeted restatement

**Example:**

```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    auto_restatement_cron '@weekly',  -- Every Sunday
    auto_restatement_intervals 7       -- Last 7 days
  ),
  cron '@daily'
);
```

**What happens:**
- Daily: Processes new day (normal incremental)
- Weekly: Reprocesses last 7 days (restatement)

**⚠️ Note:** Only supported for `INCREMENTAL_BY_TIME_RANGE`. Other kinds restate entire model.

[↑ Back to Top](#chapter-2a-model-properties)

---

## 5. Data Quality Properties

These properties define data relationships, uniqueness, and validation rules.

### 5.1 `grain`

**Type:** `string` or `array[string]`  
**Required:** No  
**Default:** None

The column(s) that uniquely identify each row (primary key).

**Syntax:**
```sql
-- Single column grain
MODEL (
  name analytics.customers,
  grain customer_id
);

-- Composite grain
MODEL (
  name analytics.daily_customer_metrics,
  grain (customer_id, metric_date)
);
```

**What It Does:**

1. **Declares Uniqueness:** Documents the primary key
2. **Enables Tools:** Simplifies `vulcan table_diff` and other tools
3. **Semantic Layer:** Used for joins in semantic layer
4. **Validation:** Should be paired with `unique_values` audit

**Example:**

```sql
MODEL (
  name analytics.orders,
  grain order_id,
  assertions (
    not_null(columns := (order_id)),
    unique_values(columns := (order_id))  -- Enforce grain uniqueness
  )
);

SELECT
  order_id,  -- Grain column
  customer_id,
  order_date,
  amount
FROM raw.orders;
```

**Composite Grain:**

```sql
MODEL (
  name analytics.daily_revenue,
  grain (customer_id, revenue_date),
  assertions (
    unique_combination_of_columns(columns := (customer_id, revenue_date))
  )
);
```

**Relationship to Audits:**

Always pair `grain` with uniqueness audits:

```sql
MODEL (
  name analytics.customers,
  grain customer_id,
  assertions (
    not_null(columns := (customer_id)),      -- Required
    unique_values(columns := (customer_id))   -- Unique
  )
);
```

### 5.2 `grains`

**Type:** `array[string]` or `array[array[string]]`  
**Required:** No  
**Default:** None

Multiple grains if a model has more than one unique key.

**Syntax:**
```sql
MODEL (
  name analytics.customer_products,
  grains (
    (customer_id),           -- Customer is unique
    (product_id),            -- Product is unique
    (customer_id, product_id)  -- Customer-product combination is unique
  )
);
```

**Use Cases:**

- Models with multiple natural keys
- Fact tables with multiple unique identifiers
- Bridge tables with multiple relationships

**Example:**

```sql
MODEL (
  name analytics.order_line_items,
  grains (
    (order_id, line_item_id),  -- Primary key
    (order_id),                 -- Order is unique per order_id
    (product_id)                -- Product appears in multiple orders
  )
);
```

### 5.3 `references`

**Type:** `string` or `array[string]`  
**Required:** No  
**Default:** None

Non-unique columns that identify join relationships to other models (foreign keys).

**Syntax:**
```sql
MODEL (
  name analytics.orders,
  grain order_id,
  references (customer_id)  -- Foreign key to customers table
);
```

**What It Does:**

1. **Documents Relationships:** Declares foreign key relationships
2. **Helps with Join Detection:** Assists semantic layer in detecting join relationships (but grains are required for joins)
3. **Join Safety:** Can join `references` → `grain` (many-to-one), but cannot join `references` → `references` (many-to-many, unsafe)

**Rules:**

- ✅ Can join `references` → `grain` (many-to-one)
- ❌ Cannot join `references` → `references` (many-to-many, unsafe)

**Example:**

```sql
-- Customers table (grain)
MODEL (
  name analytics.customers,
  grain customer_id
);

-- Orders table (references customer_id)
MODEL (
  name analytics.orders,
  grain order_id,
  references (customer_id)  -- Can join to customers.customer_id
);

-- Order line items (references order_id)
MODEL (
  name analytics.order_line_items,
  grain (order_id, line_item_id),
  references (order_id)  -- Can join to orders.order_id
);
```

**Column Aliasing:**

If column names differ, alias to common entity name:

```sql
MODEL (
  name analytics.guest_orders,
  grain order_id,
  references (guest_id AS customer_id)  -- Alias to match customers.grain
);
-- Can now join to analytics.customers (grain: customer_id)
```

**Multiple References:**

```sql
MODEL (
  name analytics.order_line_items,
  grain (order_id, line_item_id),
  references (order_id, product_id)  -- Multiple foreign keys
);
```

### 5.4 `assertions` (formerly `audits`)

**Type:** `array`  
**Required:** No  
**Default:** None

Audits that run after model execution to validate data quality.

**Syntax:**
```sql
MODEL (
  name analytics.orders,
  assertions (
    not_null(columns := (order_id, customer_id)),
    unique_values(columns := (order_id)),
    accepted_range(column := amount, min_v := 0, max_v := 1000000)
  )
);
```

**Built-in Audits:**

Vulcan provides 29 built-in audits. Common ones:

| Audit | Purpose | Example |
|-------|---------|---------|
| `not_null` | No NULL values | `not_null(columns := (id, email))` |
| `unique_values` | No duplicates | `unique_values(columns := (id))` |
| `accepted_values` | Enum validation | `accepted_values(column := status, is_in := ('A', 'B'))` |
| `accepted_range` | Numeric range | `accepted_range(column := age, min_v := 0, max_v := 120)` |
| `forall` | Custom logic | `forall(criteria := (amount >= 0))` |

**Complete Audit Reference:**

For comprehensive audit documentation, see [Chapter 4: Audits](../04-audits.md).

**Example:**

```sql
MODEL (
  name analytics.orders,
  grain order_id,
  references (customer_id),
  assertions (
    -- Completeness
    not_null(columns := (order_id, customer_id, order_date, amount)),
    
    -- Uniqueness
    unique_values(columns := (order_id)),
    
    -- Validity
    accepted_values(
      column := status,
      is_in := ('pending', 'completed', 'cancelled')
    ),
    accepted_range(column := amount, min_v := 0, max_v := 1000000),
    
    -- Business logic
    forall(criteria := (
      order_date <= CURRENT_DATE,
      shipped_date IS NULL OR shipped_date >= order_date
    ))
  )
);
```

**Custom Audits:**

Reference audits defined in `audits/` directory:

```sql
MODEL (
  name analytics.orders,
  assertions (
    not_null(columns := (order_id)),
    custom_revenue_check,  -- Defined in audits/revenue.sql
    valid_customer_reference  -- Defined in audits/referential.sql
  )
);
```

**For comprehensive audit documentation, see [Chapter 4: Audits](../04-audits.md)**

### 5.5 `depends_on`

**Type:** `array[string]`  
**Required:** No  
**Default:** Inferred from model code

Explicitly specify models this model depends on (in addition to auto-detected dependencies).

**Syntax:**
```sql
MODEL (
  name analytics.customer_summary,
  depends_on (analytics.customers, analytics.orders)  -- Explicit dependencies
);

SELECT
  c.customer_id,
  COUNT(o.order_id) as order_count
FROM analytics.customers c
LEFT JOIN analytics.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id;
```

**When to Use:**

**1. Dynamic Dependencies:**

When dependencies aren't visible in SQL:

```sql
MODEL (
  name analytics.dynamic_query,
  depends_on (analytics.config_table)  -- Used in macro, not visible in SQL
);

SELECT * FROM @IF(@gateway = 'prod', analytics.config_table, analytics.config_table_dev);
```

**2. Python Model Dependencies:**

Python models may have hidden dependencies:

```python
@model(
    "analytics.ml_predictions",
    depends_on=["analytics.features", "analytics.model_weights"]
)
def execute(context, ...):
    # Dependencies not visible in SQL
    features = context.fetchdf("SELECT * FROM analytics.features")
    weights = context.fetchdf("SELECT * FROM analytics.model_weights")
    # ...
```

**3. Override Auto-Detection:**

Force dependency order:

```sql
MODEL (
  name analytics.final_summary,
  depends_on (analytics.stage1, analytics.stage2)  -- Ensure order
);
```

**Note:** Dependencies are usually auto-detected from SQL. Only use `depends_on` when necessary.

[↑ Back to Top](#chapter-2a-model-properties)

---

## 6. Metadata Properties

These properties provide documentation and organization for models.

### 6.1 `description`

**Type:** `string`  
**Required:** No  
**Default:** None

Human-readable description of the model. Automatically registered as table comment in the SQL engine.

**Syntax:**
```sql
MODEL (
  name analytics.customer_metrics,
  description 'Daily aggregated customer metrics for BI dashboards'
);
```

**What It Does:**

1. **Documentation:** Describes model purpose
2. **Table Comments:** Registered in SQL engine (if supported)
3. **Semantic Layer:** Flows through to semantic layer
4. **Discovery:** Helps users understand models

**Example:**

```sql
MODEL (
  name analytics.daily_revenue,
  description 'Daily revenue aggregated by customer and product category. Includes completed orders only. Used for revenue reporting dashboards.'
);
```

**Best Practices:**

- Write clear, concise descriptions
- Include business context
- Mention key filters or assumptions
- Note downstream consumers

### 6.2 `column_descriptions`

**Type:** `dict` (key-value pairs)  
**Required:** No  
**Default:** None

Column-level descriptions. Automatically registered as column comments in SQL engine.

**Syntax:**
```sql
MODEL (
  name analytics.customer_metrics,
  column_descriptions (
    customer_id = 'Unique customer identifier (integer)',
    revenue = 'Total revenue in USD from completed orders',
    order_count = 'Number of completed orders',
    churn_risk_score = 'ML churn probability (0-1, higher = more risk)'
  )
);
```

**What It Does:**

1. **Column Documentation:** Describes each column
2. **Column Comments:** Registered in SQL engine
3. **Semantic Layer:** Flows through to semantic layer dimensions
4. **BI Tools:** Appears in BI tool metadata

**Example:**

```sql
MODEL (
  name analytics.customer_predictions,
  column_descriptions (
    customer_id = 'Foreign key to customers table',
    churn_probability = 'Probability customer will churn in next 30 days (0-1 scale)',
    predicted_ltv = 'Predicted lifetime value in USD',
    prediction_date = 'Date when prediction was generated',
    model_version = 'ML model version used (e.g., v2.3.1)'
  )
);
```

**Best Practices:**

- Explain business meaning, not just data type
- Include units (USD, percentage, etc.)
- Note calculation methods for derived columns
- Document special values (NULL meanings, etc.)

**Inline Comments Alternative:**

You can also use inline SQL comments (but `column_descriptions` takes precedence):

```sql
SELECT
  customer_id,  -- Unique customer identifier
  revenue,      -- Total revenue in USD
  order_count   -- Number of orders
FROM ...
```

### 6.3 `owner`

**Type:** `string`  
**Required:** No  
**Default:** Project default (if set)

Team or person responsible for the model.

**Syntax:**
```sql
MODEL (
  name analytics.customer_metrics,
  owner 'data-team'
);

-- Or individual
MODEL (
  name analytics.ml_predictions,
  owner 'ml-team'
);
```

**What It Does:**

1. **Ownership:** Identifies responsible team/person
2. **Notifications:** Used for alerting (if configured)
3. **Organization:** Helps organize models by team
4. **Documentation:** Makes it clear who to contact

**Example:**

```sql
MODEL (
  name analytics.revenue,
  owner 'finance-data-team'
);

MODEL (
  name analytics.customer_segments,
  owner 'analytics-team'
);

MODEL (
  name analytics.ml_churn_predictions,
  owner 'ml-team'
);
```

**Project Default:**

Set default owner in `config.yaml`:

```yaml
model_defaults:
  owner: 'data-team'
```

Override per model:

```sql
MODEL (
  name analytics.special_model,
  owner 'special-team'  -- Overrides default
);
```

### 6.4 `tags`

**Type:** `array[string]`  
**Required:** No  
**Default:** None

Labels for organizing and categorizing models.

**Syntax:**
```sql
MODEL (
  name analytics.customer_metrics,
  tags ('analytics', 'customer', 'revenue')
);
```

**What It Does:**

1. **Organization:** Group related models
2. **Filtering:** Select models by tag (`vulcan run --select tag:analytics`)
3. **Documentation:** Categorize models
4. **CI/CD:** Run specific model groups

**Common Tag Patterns:**

**By Domain:**
```sql
tags ('sales', 'revenue', 'orders')
tags ('marketing', 'campaigns', 'attribution')
tags ('finance', 'accounting', 'reconciliation')
```

**By Layer:**
```sql
tags ('staging', 'raw')
tags ('marts', 'analytics')
tags ('semantic', 'metrics')
```

**By Priority:**
```sql
tags ('critical', 'p0')
tags ('important', 'p1')
tags ('monitoring', 'p2')
```

**By Data Type:**
```sql
tags ('pii', 'sensitive')
tags ('public', 'shared')
tags ('internal', 'confidential')
```

**Example:**

```sql
MODEL (
  name analytics.daily_revenue,
  tags ('analytics', 'revenue', 'critical', 'p0')
);

MODEL (
  name analytics.customer_segments,
  tags ('analytics', 'customer', 'ml', 'p1')
);
```

**Selecting by Tags:**

```bash
# Run all models with 'analytics' tag
vulcan run --select tag:analytics

# Run critical models
vulcan run --select tag:critical

# Run multiple tags
vulcan run --select tag:analytics tag:revenue
```

### 6.5 `project`

**Type:** `string`  
**Required:** No  
**Default:** None

The project name this model belongs to (for multi-repo deployments).

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  project 'main-project'
);
```

**Use Cases:**

- Multi-repo SQLMesh deployments
- Shared models across projects
- Project isolation

**Note:** Most users don't need this property. Only use for multi-repo setups.

### 6.6 `stamp`

**Type:** `string`  
**Required:** No  
**Default:** None

Arbitrary string to force a new model version without changing functional components.

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  stamp '2024-11-14-rebuild'  -- Force new version
);
```

**Use Cases:**

**1. Force Rebuild:**

```sql
MODEL (
  name analytics.customers,
  stamp 'rebuild-2024-11-14'  -- Forces rebuild even if query unchanged
);
```

**2. Version Tracking:**

```sql
MODEL (
  name analytics.customers,
  stamp 'v2.3.1'  -- Track model version
);
```

**3. Temporary Changes:**

```sql
MODEL (
  name analytics.customers,
  stamp 'temp-fix-2024-11-14'  -- Temporary version
);
```

**⚠️ Note:** Changing `stamp` creates a new model version, triggering rebuilds. Use sparingly.

[↑ Back to Top](#chapter-2a-model-properties)

---


## 7. Schema & Type Properties

These properties control column definitions and SQL dialect.

### 7.1 `columns`

**Type:** `array[string]` (column definitions)  
**Required:** No (required for Python models)  
**Default:** Inferred from SQL query

Explicit column names and data types. Disables automatic inference.

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  columns (
    customer_id INT,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    created_at TIMESTAMP
  )
);

SELECT
  customer_id::INT,
  customer_name::VARCHAR(255),
  email::VARCHAR(255),
  created_at::TIMESTAMP
FROM raw.customers;
```

**When to Use:**

**1. Python Models (Required):**

Python models **must** specify columns (can't infer from DataFrame):

```python
@model(
    "analytics.predictions",
    columns={
        "customer_id": "INT",
        "prediction": "FLOAT",
        "prediction_date": "DATE"
    }
)
def execute(context, ...):
    # ...
    return df  # DataFrame columns must match column definitions
```

**2. Seed Models:**

```sql
MODEL (
  name analytics.national_holidays,
  kind SEED (path 'holidays.csv'),
  columns (
    holiday_name VARCHAR,
    holiday_date DATE
  )
);
```

**3. Override Inference:**

If automatic inference is wrong:

```sql
MODEL (
  name analytics.events,
  columns (
    event_id VARCHAR(36),  -- UUID as string
    event_date DATE,
    event_data JSON
  )
);
```

**⚠️ Warning:**

SQLMesh may exhibit unexpected behavior if:
- `columns` includes columns not returned by query
- `columns` omits columns returned by query
- Data types don't match query output

**Best Practice:** Let Vulcan infer columns unless you have a specific reason to override.

### 7.2 `dialect`

**Type:** `string`  
**Required:** No  
**Default:** Project default (`model_defaults.dialect`)

The SQL dialect for this model's query.

**Syntax:**
```sql
MODEL (
  name analytics.customers,
  dialect snowflake  -- Override project default
);
```

**Supported Dialects:**

Vulcan supports all SQLGlot dialects:
- `snowflake`
- `bigquery`
- `spark`
- `postgres`
- `duckdb`
- `mysql`
- `sqlite`
- `redshift`
- `databricks`
- And more...

**When to Use:**

**1. Multi-Warehouse Projects:**

```sql
-- Snowflake model
MODEL (
  name analytics.snowflake_customers,
  dialect snowflake
);

-- BigQuery model
MODEL (
  name analytics.bigquery_customers,
  dialect bigquery
);
```

**2. Override Project Default:**

```yaml
# config.yaml
model_defaults:
  dialect: snowflake
```

```sql
-- Most models use Snowflake (default)
MODEL (name analytics.customers);

-- This one uses BigQuery
MODEL (
  name analytics.bigquery_events,
  dialect bigquery  -- Override
);
```

**3. Dialect-Specific Syntax:**

```sql
MODEL (
  name analytics.events,
  dialect bigquery  -- Uses BigQuery-specific functions
);

SELECT
  event_id,
  PARSE_TIMESTAMP('%Y-%m-%d', event_date) as event_timestamp,  -- BigQuery syntax
  event_data
FROM raw.events;
```

**Project Default:**

Always set in `config.yaml`:

```yaml
model_defaults:
  dialect: snowflake  # Required
```

[↑ Back to Top](#chapter-2a-model-properties)

---

## 8. Warehouse-Specific Properties

These properties control physical table structure and engine-specific features.

### 8.1 `partitioned_by`

**Type:** `string` or `array[string]`  
**Required:** No (required for `INCREMENTAL_BY_PARTITION`)  
**Default:** None

Column(s) or expressions used for table partitioning.

**Syntax:**
```sql
-- Single column partition
MODEL (
  name analytics.events,
  partitioned_by event_date
);

-- Multi-column partition
MODEL (
  name analytics.events,
  partitioned_by (year, month, day)
);

-- Expression partition (BigQuery)
MODEL (
  name analytics.events,
  partitioned_by 'DATE_TRUNC(event_timestamp, DAY)'
);
```

**Supported Engines:**

- **BigQuery:** Partition by DATE, TIMESTAMP, INTEGER, or DATE_TRUNC expression
- **Spark/Databricks:** Partition by columns
- **Snowflake:** Clustering (not partitioning)
- **Postgres:** Partition by columns (if supported)

**Examples:**

**BigQuery Date Partitioning:**

```sql
MODEL (
  name analytics.daily_events,
  partitioned_by event_date,  -- Partition by DATE column
  physical_properties (
    partition_expiration_days = 90,
    require_partition_filter = true
  )
);
```

**BigQuery Timestamp Partitioning:**

```sql
MODEL (
  name analytics.events,
  partitioned_by 'DATE_TRUNC(event_timestamp, DAY)',  -- Partition by day
  physical_properties (
    partition_expiration_days = 365
  )
);
```

**Spark Partitioning:**

```sql
MODEL (
  name analytics.events,
  partitioned_by (year, month, day),  -- Multi-column partition
  storage_format 'parquet'
);
```

**Performance Benefits:**

- ✅ Faster queries (partition pruning)
- ✅ Lower costs (scan less data)
- ✅ Better maintenance (drop old partitions)

**For INCREMENTAL_BY_PARTITION:**

`partitioned_by` is **required** and defines the partition key:

```sql
MODEL (
  name analytics.events,
  kind INCREMENTAL_BY_PARTITION,
  partitioned_by event_date  -- Required for this kind
);
```

### 8.2 `clustered_by`

**Type:** `string` or `array[string]`  
**Required:** No  
**Default:** None

Column(s) used for table clustering (BigQuery, Snowflake).

**Syntax:**
```sql
-- Single column clustering
MODEL (
  name analytics.orders,
  clustered_by customer_id
);

-- Multi-column clustering
MODEL (
  name analytics.events,
  clustered_by (customer_id, event_type)
);
```

**Supported Engines:**

- **BigQuery:** Clustering by columns
- **Snowflake:** Clustering by columns (automatic, but can specify)

**Examples:**

**BigQuery Clustering:**

```sql
MODEL (
  name analytics.orders,
  partitioned_by order_date,
  clustered_by (customer_id, product_id),  -- Cluster by common filter columns
  physical_properties (
    require_partition_filter = true
  )
);
```

**Snowflake Clustering:**

```sql
MODEL (
  name analytics.events,
  clustered_by (customer_id, event_date)  -- Optimize for common queries
);
```

**Performance Benefits:**

- ✅ Faster queries (co-located data)
- ✅ Better compression
- ✅ Reduced scan costs

**Best Practices:**

- Cluster by columns frequently used in WHERE clauses
- Limit to 1-4 columns (more has diminishing returns)
- Combine with partitioning for best performance

### 8.3 `table_format`

**Type:** `string`  
**Required:** No  
**Default:** Engine default

Table format for engines supporting multiple formats (Spark, Athena).

**Syntax:**
```sql
MODEL (
  name analytics.events,
  table_format 'iceberg',  -- Iceberg table format
  storage_format 'parquet'  -- Parquet file format
);
```

**Supported Formats:**

- `iceberg` - Apache Iceberg
- `delta` - Delta Lake
- `hive` - Hive format

**Examples:**

**Iceberg Table:**

```sql
MODEL (
  name analytics.events,
  table_format 'iceberg',
  storage_format 'parquet',
  partitioned_by event_date
);
```

**Delta Lake:**

```sql
MODEL (
  name analytics.events,
  table_format 'delta',
  partitioned_by event_date
);
```

**Note:** Not all engines support `table_format`. For engines that don't distinguish (e.g., BigQuery, Snowflake), use `storage_format` instead.

### 8.4 `storage_format`

**Type:** `string`  
**Required:** No  
**Default:** Engine default

File storage format (Spark, Hive, Athena).

**Syntax:**
```sql
MODEL (
  name analytics.events,
  storage_format 'parquet'  -- Parquet files
);
```

**Supported Formats:**

- `parquet` - Apache Parquet (recommended)
- `orc` - Optimized Row Columnar
- `avro` - Apache Avro
- `json` - JSON files
- `csv` - CSV files

**Examples:**

**Parquet (Recommended):**

```sql
MODEL (
  name analytics.events,
  storage_format 'parquet',  -- Best compression and performance
  partitioned_by event_date
);
```

**ORC:**

```sql
MODEL (
  name analytics.events,
  storage_format 'orc',  -- Alternative to Parquet
  partitioned_by event_date
);
```

**Recommendation:** Use `parquet` for best performance and compression.

### 8.5 `physical_properties`

**Type:** `dict` (key-value pairs)  
**Required:** No  
**Default:** Project defaults (merged)

Engine-specific properties applied to the physical table/view.

**Syntax:**
```sql
MODEL (
  name analytics.events,
  physical_properties (
    partition_expiration_days = 90,
    require_partition_filter = true,
    creatable_type = TRANSIENT
  )
);
```

**Common Properties by Engine:**

**BigQuery:**

```sql
MODEL (
  name analytics.events,
  partitioned_by event_date,
  physical_properties (
    partition_expiration_days = 90,        -- Auto-delete old partitions
    require_partition_filter = true,       -- Require partition filter
    description = 'Event data table'       -- Table description
  )
);
```

**Snowflake:**

```sql
MODEL (
  name analytics.events,
  physical_properties (
    warehouse = 'COMPUTE_WH',              -- Warehouse for Dynamic Tables
    creatable_type = TRANSIENT,             -- Transient table (lower cost)
    data_retention_time_in_days = 0        -- No time travel
  )
);
```

**Spark/Databricks:**

```sql
MODEL (
  name analytics.events,
  physical_properties (
    'delta.autoOptimize.optimizeWrite' = true,
    'delta.autoOptimize.autoCompact' = true
  )
);
```

**Property Merging:**

Project defaults are merged with model-specific:

```yaml
# config.yaml
model_defaults:
  physical_properties:
    partition_expiration_days: 7
    require_partition_filter: true
```

```sql
-- Model inherits defaults, adds new property
MODEL (
  name analytics.events,
  physical_properties (
    creatable_type = TRANSIENT  -- Adds to defaults
  )
);
-- Result: partition_expiration_days=7, require_partition_filter=true, creatable_type=TRANSIENT
```

**Unsetting Properties:**

Set to `None` to remove project-level property:

```sql
MODEL (
  name analytics.events,
  physical_properties (
    partition_expiration_days = None,  -- Remove project default
    creatable_type = TRANSIENT
  )
);
```

### 8.6 `virtual_properties`

**Type:** `dict` (key-value pairs)  
**Required:** No  
**Default:** Project defaults (merged)

Engine-specific properties applied to the virtual view (development environments).

**Syntax:**
```sql
MODEL (
  name analytics.events,
  virtual_properties (
    creatable_type = SECURE,  -- Secure view
    labels = [('environment', 'dev')]
  )
);
```

**Common Use Cases:**

**Secure Views (Snowflake):**

```sql
MODEL (
  name analytics.sensitive_data,
  virtual_properties (
    creatable_type = SECURE  -- Secure view in dev
  )
);
```

**View Labels (BigQuery):**

```sql
MODEL (
  name analytics.events,
  virtual_properties (
    labels = [('environment', 'dev'), ('team', 'analytics')]
  )
);
```

**Property Merging:**

Same merging behavior as `physical_properties`:

```yaml
# config.yaml
model_defaults:
  virtual_properties:
    creatable_type: SECURE
```

```sql
MODEL (
  name analytics.events,
  virtual_properties (
    labels = [('team', 'analytics')]  -- Adds to defaults
  )
);
```

### 8.7 `session_properties`

**Type:** `dict` (key-value pairs)  
**Required:** No  
**Default:** Project defaults (merged)

Engine-specific session properties (query-level configuration).

**Syntax:**
```sql
MODEL (
  name analytics.large_query,
  session_properties (
    'spark.executor.cores' = 4,
    'spark.executor.memory' = '8G'
  )
);
```

**Common Use Cases:**

**Spark/Databricks Resource Control:**

```sql
MODEL (
  name analytics.large_aggregation,
  session_properties (
    'spark.executor.cores' = 8,
    'spark.executor.memory' = '16G',
    'spark.sql.shuffle.partitions' = 200
  )
);
```

**Snowflake Session Settings:**

```sql
MODEL (
  name analytics.complex_query,
  session_properties (
    'QUERY_TAG' = 'analytics.large_query',
    'STATEMENT_TIMEOUT_IN_SECONDS' = 3600
  )
);
```

**BigQuery Settings:**

```sql
MODEL (
  name analytics.large_query,
  session_properties (
    'maximum_bytes_billed' = '1000000000'  -- 1GB limit
  )
);
```

**Property Merging:**

Session properties are merged per-key:

```yaml
# config.yaml
model_defaults:
  session_properties:
    'spark.executor.cores': 4
    'spark.executor.memory': '8G'
```

```sql
MODEL (
  name analytics.events,
  session_properties (
    'spark.executor.cores' = 8  -- Overrides: 4 → 8
    -- 'spark.executor.memory' inherits: '8G'
  )
);
```

[↑ Back to Top](#chapter-2a-model-properties)

---

## 9. Execution Control Properties

These properties control how models are executed and optimized.

### 9.1 `enabled`

**Type:** `boolean`  
**Required:** No  
**Default:** `true`

Whether the model is enabled (loaded and executed).

**Syntax:**
```sql
MODEL (
  name analytics.experimental_model,
  enabled false  -- Disable this model
);
```

**Use Cases:**

**1. Temporary Disable:**

```sql
MODEL (
  name analytics.deprecated_model,
  enabled false  -- Don't run, but keep definition
);
```

**2. Feature Flags:**

```sql
MODEL (
  name analytics.new_feature,
  enabled false  -- Disable until ready
);
```

**3. Conditional Models:**

```sql
-- Disable in certain environments
MODEL (
  name analytics.test_model,
  enabled "@IF(@gateway = 'prod', false, true)"  -- Disable in prod
);
```

**What Happens When Disabled:**

- Model is **not loaded** by Vulcan
- Model is **not executed** in runs
- Dependencies are **not resolved** (downstream models may fail)
- Model definition is **preserved** (can re-enable later)

**⚠️ Warning:** Disabling a model can break downstream models that depend on it.

### 9.2 `gateway`

**Type:** `string`  
**Required:** No  
**Default:** Default gateway

The execution gateway/engine to use for this model.

**Syntax:**
```sql
MODEL (
  name analytics.spark_model,
  gateway 'spark'  -- Use Spark gateway
);

MODEL (
  name analytics.bigquery_model,
  gateway 'bigquery'  -- Use BigQuery gateway
);
```

**Use Cases:**

**Multi-Engine Projects:**

```sql
-- Some models on Snowflake
MODEL (
  name analytics.snowflake_customers,
  gateway 'snowflake'
);

-- Some models on BigQuery
MODEL (
  name analytics.bigquery_events,
  gateway 'bigquery'
);
```

**Engine-Specific Features:**

```sql
-- Use Spark for ML workloads
MODEL (
  name analytics.ml_features,
  gateway 'spark',
  session_properties (
    'spark.ml.feature.scaler' = 'standard'
  )
);
```

**Configuration:**

Gateways are configured in `config.yaml`:

```yaml
gateways:
  snowflake:
    type: snowflake
    connection: ...
  bigquery:
    type: bigquery
    connection: ...
```

### 9.3 `optimize_query`

**Type:** `boolean`  
**Required:** No  
**Default:** `true`

Whether to optimize the model's query using SQLGlot.

**Syntax:**
```sql
MODEL (
  name analytics.complex_query,
  optimize_query false  -- Disable optimization
);
```

**What Optimization Does:**

SQLGlot optimization includes:
- Query canonicalization
- Expression simplification
- Constant folding
- Redundant operation removal

**When to Disable:**

**1. Optimization Causes Errors:**

```sql
MODEL (
  name analytics.problematic_query,
  optimize_query false  -- Disable if optimizer breaks query
);
```

**2. Text Limit Issues:**

```sql
MODEL (
  name analytics.large_query,
  optimize_query false  -- If optimized query exceeds text limit
);
```

**⚠️ Warning:**

Disabling optimization may prevent:
- Column-level lineage from working
- Automatic `SELECT *` expansion
- Query simplification benefits

**Recommendation:** Keep enabled unless you encounter issues.

### 9.4 `ignored_rules`

**Type:** `string` or `array[string]`  
**Required:** No  
**Default:** None

Linter rules to ignore for this model.

**Syntax:**
```sql
-- Ignore specific rule
MODEL (
  name analytics.legacy_model,
  ignored_rules 'noselectstar'  -- Allow SELECT *
);

-- Ignore multiple rules
MODEL (
  name analytics.complex_model,
  ignored_rules ('noselectstar', 'noqualify')  -- Ignore multiple
);

-- Ignore all rules
MODEL (
  name analytics.experimental_model,
  ignored_rules 'ALL'  -- Ignore all linter rules
);
```

**Common Rules:**

- `noselectstar` - Allow `SELECT *`
- `noqualify` - Allow unqualified columns
- `nodistinct` - Allow `SELECT DISTINCT`
- And more...

**Use Cases:**

**1. Legacy Code:**

```sql
MODEL (
  name analytics.legacy_table,
  ignored_rules 'noselectstar'  -- Legacy code uses SELECT *
);
```

**2. Complex Queries:**

```sql
MODEL (
  name analytics.complex_aggregation,
  ignored_rules ('noselectstar', 'noqualify')  -- Complex query needs flexibility
);
```

**3. Experimental Models:**

```sql
MODEL (
  name analytics.experimental,
  ignored_rules 'ALL'  -- Disable all checks during development
);
```

**⚠️ Note:** Use sparingly. Linter rules catch real issues.

### 9.5 `formatting`

**Type:** `boolean`  
**Required:** No  
**Default:** `true`

Whether to format this model with `vulcan format`.

**Syntax:**
```sql
MODEL (
  name analytics.custom_format_model,
  formatting false  -- Don't auto-format
);
```

**Use Cases:**

**1. Preserve Custom Formatting:**

```sql
MODEL (
  name analytics.specially_formatted,
  formatting false  -- Keep custom formatting
);
```

**2. Generated Code:**

```sql
MODEL (
  name analytics.generated_query,
  formatting false  -- Don't reformat generated SQL
);
```

**Recommendation:** Keep enabled for consistency. Only disable if you have specific formatting requirements.

### 9.6 `physical_version`

**Type:** `string`  
**Required:** No  
**Default:** None

Pin the physical table version (forward-only models only).

**Syntax:**
```sql
MODEL (
  name analytics.large_table,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only true
  ),
  physical_version 'abc123'  -- Pin to specific version
);
```

**Use Cases:**

- Lock table structure
- Prevent accidental changes
- Version control for physical tables

**⚠️ Note:** Only available for forward-only models. Use with caution.

[↑ Back to Top](#chapter-2a-model-properties)

---


## 10. Pre/Post Statements

These properties allow executing SQL statements before and after model execution.

### 10.1 `pre_statements`

**Type:** `array[string]` (SQL statements)  
**Required:** No  
**Default:** Project defaults (merged)

SQL statements executed **before** the model query runs.

**Syntax (SQL Models):**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

-- Pre-statements (before query)
SET timezone = 'UTC';
CACHE TABLE countries AS SELECT * FROM raw.countries;

-- Model query
SELECT
  customer_id,
  customer_name,
  country
FROM raw.customers
JOIN countries ON ...
```

**Syntax (Python Models):**

```python
@model(
    "analytics.customers",
    pre_statements=[
        "SET timezone = 'UTC'",
        "CACHE TABLE countries AS SELECT * FROM raw.countries"
    ]
)
def execute(context, ...):
    # ...
```

**Common Use Cases:**

**1. Session Configuration:**

```sql
MODEL (
  name analytics.events,
  kind FULL
);

SET timezone = 'UTC';
SET query_timeout = 3600;

SELECT * FROM raw.events;
```

**2. Cache Temporary Tables:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

CACHE TABLE countries AS SELECT * FROM raw.countries;
CACHE TABLE regions AS SELECT * FROM raw.regions;

SELECT
  c.*,
  co.country,
  r.region
FROM raw.customers c
JOIN countries co ON ...
JOIN regions r ON ...
```

**3. Load UDFs:**

```sql
MODEL (
  name analytics.ml_predictions,
  kind FULL
);

ADD JAR s3://special_udf.jar;
CREATE TEMPORARY FUNCTION predict_churn AS 'com.example.ChurnPredictor';

SELECT
  customer_id,
  predict_churn(features) as churn_probability
FROM analytics.customer_features;
```

**⚠️ Important:**

**Pre-statements run TWICE:**
1. When table is **created**
2. When query is **evaluated**

**Conditional Execution:**

Use `@runtime_stage` to conditionally execute:

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

-- Only cache when creating table
@IF(@runtime_stage = 'creating', CACHE TABLE countries AS SELECT * FROM raw.countries);

SELECT * FROM raw.customers;
```

**Runtime Stages:**

- `creating` - Table creation time
- `evaluating` - Query evaluation time

**⚠️ Warning:**

**Don't create physical tables in pre-statements:**

```sql
-- ❌ BAD - Can conflict with concurrent model execution
CREATE TABLE temp_data AS SELECT * FROM ...;

-- ✅ GOOD - Use CACHE or temporary objects
CACHE TABLE temp_data AS SELECT * FROM ...;
```

**Project-Level Defaults:**

Set defaults in `config.yaml`:

```yaml
model_defaults:
  pre_statements:
    - "SET timezone = 'UTC'"
    - "SET query_timeout = 3600"
```

Model-specific statements are **merged** (defaults first, then model-specific).

### 10.2 `post_statements`

**Type:** `array[string]` (SQL statements)  
**Required:** No  
**Default:** Project defaults (merged)

SQL statements executed **after** the model query completes.

**Syntax (SQL Models):**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

-- Model query (must end with semicolon if post-statements exist)
SELECT * FROM raw.customers;

-- Post-statements (after query)
UNCACHE TABLE countries;
ANALYZE TABLE analytics.customers;
```

**Syntax (Python Models):**

```python
@model(
    "analytics.customers",
    post_statements=[
        "ANALYZE TABLE analytics.customers",
        "@CREATE_INDEX(@this_model, customer_id)"
    ]
)
def execute(context, ...):
    # Must use yield (not return) for post-statements
    yield df

    # Post-statements execute after yield
```

**Common Use Cases:**

**1. Table Maintenance:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

-- Post-statements
ANALYZE TABLE analytics.customers;
VACUUM TABLE analytics.customers;
```

**2. Cleanup:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

CACHE TABLE countries AS SELECT * FROM raw.countries;

SELECT * FROM raw.customers JOIN countries ...;

-- Cleanup cached tables
UNCACHE TABLE countries;
```

**3. Create Indexes:**

```sql
MODEL (
  name analytics.orders,
  kind FULL
);

SELECT * FROM raw.orders;

-- Create indexes after table is populated
@IF(@runtime_stage = 'evaluating',
  CREATE INDEX idx_customer_id ON analytics.orders(customer_id);
  CREATE INDEX idx_order_date ON analytics.orders(order_date);
);
```

**Conditional Execution:**

**Always condition post-statements on `@runtime_stage`:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

-- Only run after query evaluation
@IF(@runtime_stage = 'evaluating',
  ANALYZE TABLE analytics.customers
);
```

**Why?** Post-statements run twice (table creation + evaluation). Condition on `evaluating` to run only after query.

**Project-Level Defaults:**

```yaml
model_defaults:
  post_statements:
    - "@IF(@runtime_stage = 'evaluating', ANALYZE @this_model)"
```

### 10.3 `on_virtual_update`

**Type:** `array[string]` (SQL statements)  
**Required:** No  
**Default:** Project defaults (merged)

SQL statements executed after **virtual update** completes (when views are swapped in dev environments).

**Syntax (SQL Models):**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

ON_VIRTUAL_UPDATE_BEGIN;
GRANT SELECT ON VIEW @this_model TO ROLE analyst_role;
GRANT SELECT ON VIEW @this_model TO ROLE admin_role;
ON_VIRTUAL_UPDATE_END;
```

**Syntax (Python Models):**

```python
@model(
    "analytics.customers",
    on_virtual_update=[
        "GRANT SELECT ON VIEW @this_model TO ROLE analyst_role"
    ]
)
def execute(context, ...):
    # ...
```

**What Is Virtual Update?**

Virtual update is when Vulcan swaps view references (in dev environments) without recomputing data. `on_virtual_update` statements run after this swap.

**Use Cases:**

**1. Grant Permissions:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

ON_VIRTUAL_UPDATE_BEGIN;
GRANT SELECT ON VIEW @this_model TO ROLE analyst_role;
GRANT SELECT ON VIEW @this_model TO ROLE readonly_role;
ON_VIRTUAL_UPDATE_END;
```

**2. Set View Properties:**

```sql
MODEL (
  name analytics.sensitive_data,
  kind FULL
);

SELECT * FROM raw.customers;

ON_VIRTUAL_UPDATE_BEGIN;
ALTER VIEW @this_model SET COMMENT = 'Customer data - PII';
ON_VIRTUAL_UPDATE_END;
```

**3. With Jinja Macros:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

ON_VIRTUAL_UPDATE_BEGIN;
GRANT SELECT ON VIEW @this_model TO ROLE analyst_role;
JINJA_STATEMENT_BEGIN;
GRANT SELECT ON VIEW {{ this_model }} TO ROLE admin;
JINJA_END;
ON_VIRTUAL_UPDATE_END;
```

**⚠️ Important:**

- Table resolution occurs at **virtual layer**
- `@this_model` resolves to view name (e.g., `db__dev.customers`)
- Not physical table name

**Project-Level Defaults:**

```yaml
model_defaults:
  on_virtual_update:
    - "GRANT SELECT ON @this_model TO ROLE analyst_role"
```

[↑ Back to Top](#chapter-2a-model-properties)

---

## 11. Property Quick Reference

### 11.1 All Properties by Category

#### Required Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `name` | string | Yes* | None | Fully qualified model name |
| `kind` | string/dict | Yes | `VIEW` (SQL) / `FULL` (Python) | Model kind |

*Required unless `infer_names` is enabled

#### Scheduling & Temporal

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `cron` | string | No | `@daily` | Schedule expression |
| `cron_tz` | string | No | `UTC` | Cron timezone |
| `interval_unit` | string | No | Inferred | Temporal granularity |
| `start` | string/int | No | `yesterday` | Historical start |
| `end` | string/int | No | None | Stop processing date |
| `allow_partials` | boolean | No | `false` | Process incomplete intervals |

#### Incremental Model Properties

| Property | Type | Required | Default | Applies To |
|----------|------|----------|---------|------------|
| `time_column` | string | Yes* | None | INCREMENTAL_BY_TIME_RANGE |
| `unique_key` | string/array | Yes* | None | INCREMENTAL_BY_UNIQUE_KEY, SCD_TYPE_2 |
| `lookback` | integer | No | `0` | INCREMENTAL_BY_TIME_RANGE, INCREMENTAL_BY_UNIQUE_KEY |
| `batch_size` | integer | No | None | INCREMENTAL_BY_TIME_RANGE, INCREMENTAL_BY_UNIQUE_KEY |
| `batch_concurrency` | integer | No | Connection setting | INCREMENTAL_BY_TIME_RANGE |
| `forward_only` | boolean | No | `false` | All incremental |
| `on_destructive_change` | string | No | `error` | All incremental |
| `on_additive_change` | string | No | `allow` | All incremental |
| `disable_restatement` | boolean | No | `false` | All incremental |
| `when_matched` | string | No | Update all | INCREMENTAL_BY_UNIQUE_KEY |
| `merge_filter` | string | No | None | INCREMENTAL_BY_UNIQUE_KEY |
| `auto_restatement_cron` | string | No | None | All incremental |
| `auto_restatement_intervals` | integer | No | None | INCREMENTAL_BY_TIME_RANGE |

*Required for specific model kinds

#### Data Quality

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `grain` | string/array | No | None | Primary key column(s) |
| `grains` | array | No | None | Multiple primary keys |
| `references` | string/array | No | None | Foreign key column(s) |
| `assertions` | array | No | None | Data quality audits |
| `depends_on` | array[string] | No | Inferred | Explicit dependencies |

#### Metadata

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `description` | string | No | None | Model description |
| `column_descriptions` | dict | No | None | Column descriptions |
| `owner` | string | No | Project default | Model owner |
| `tags` | array[string] | No | None | Organization tags |
| `project` | string | No | None | Project name |
| `stamp` | string | No | None | Version stamp |

#### Schema & Type

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `columns` | array[string] | No* | Inferred | Column definitions |
| `dialect` | string | No | Project default | SQL dialect |

*Required for Python models

#### Warehouse-Specific

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `partitioned_by` | string/array | No | None | Partition columns |
| `clustered_by` | string/array | No | None | Cluster columns |
| `table_format` | string | No | Engine default | Table format |
| `storage_format` | string | No | Engine default | Storage format |
| `physical_properties` | dict | No | Merged | Physical table properties |
| `virtual_properties` | dict | No | Merged | Virtual view properties |
| `session_properties` | dict | No | Merged | Session properties |

#### Execution Control

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `enabled` | boolean | No | `true` | Enable/disable model |
| `gateway` | string | No | Default | Execution gateway |
| `optimize_query` | boolean | No | `true` | Enable query optimization |
| `ignored_rules` | string/array | No | None | Linter rules to ignore |
| `formatting` | boolean | No | `true` | Enable formatting |
| `physical_version` | string | No | None | Pin table version |

#### Statements

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `pre_statements` | array[string] | No | Merged | SQL before query |
| `post_statements` | array[string] | No | Merged | SQL after query |
| `on_virtual_update` | array[string] | No | Merged | SQL after virtual update |

### 11.2 Properties by Model Kind

#### VIEW Models

**Supported Properties:**
- All general properties
- `materialized` (kind-specific)

#### FULL Models

**Supported Properties:**
- All general properties
- No kind-specific properties

#### INCREMENTAL_BY_TIME_RANGE

**Supported Properties:**
- All general properties
- All incremental properties
- `time_column` (required)
- `lookback`, `batch_size`, `batch_concurrency`
- `auto_restatement_intervals`

#### INCREMENTAL_BY_UNIQUE_KEY

**Supported Properties:**
- All general properties
- All incremental properties
- `unique_key` (required)
- `when_matched`, `merge_filter`
- `lookback`, `batch_size`
- **No `batch_concurrency`** (can't run in parallel)

#### INCREMENTAL_BY_PARTITION

**Supported Properties:**
- All general properties
- All incremental properties
- `partitioned_by` (required)

#### SCD_TYPE_2

**Supported Properties:**
- All general properties
- All incremental properties
- `unique_key` (required, array)
- `valid_from_name`, `valid_to_name`
- `invalidate_hard_deletes`
- Plus BY_TIME or BY_COLUMN specific properties

#### SEED Models

**Supported Properties:**
- `name`, `kind` (must be SEED)
- `columns`, `audits`, `owner`, `stamp`, `tags`, `description`
- `path` (required, in kind)
- `batch_size`, `csv_settings` (in kind)

#### EXTERNAL Models

**Supported Properties:**
- Defined in YAML, not MODEL DDL
- See [Chapter 2: Models](02-models.md#external---unmanaged-tables)

#### EMBEDDED Models

**Supported Properties:**
- All general properties (except materialization-related)

#### MANAGED Models

**Supported Properties:**
- All general properties
- `physical_properties` (for engine-specific config)

### 11.3 Property Defaults Summary

| Property | Default Value |
|----------|---------------|
| `kind` | `VIEW` (SQL) / `FULL` (Python) |
| `cron` | `@daily` |
| `start` | `yesterday` |
| `enabled` | `true` |
| `optimize_query` | `true` |
| `formatting` | `true` |
| `allow_partials` | `false` |
| `forward_only` | `false` |
| `disable_restatement` | `false` |
| `on_destructive_change` | `error` |
| `on_additive_change` | `allow` |
| `lookback` | `0` |
| `invalidate_hard_deletes` | `true` (SCD Type 2) |
| `updated_at_as_valid_from` | `false` (SCD Type 2 BY_TIME) |
| `execution_time_as_valid_from` | `false` (SCD Type 2 BY_COLUMN) |

[↑ Back to Top](#chapter-2a-model-properties)

---

## 12. Examples by Use Case

### 12.1 Daily Incremental Model

**Use Case:** Process daily time-series data with late-arriving data handling.

```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    lookback 7,              -- Reprocess last 7 days
    batch_size 30            -- Process 30 days per batch
  ),
  cron '@daily',
  interval_unit 'day',
  start '2020-01-01',
  grain (customer_id, revenue_date),
  references (customer_id),
  owner 'analytics-team',
  tags ('analytics', 'revenue', 'critical'),
  description 'Daily revenue aggregated by customer',
  column_descriptions (
    customer_id = 'Foreign key to customers table',
    revenue_date = 'Date of revenue (YYYY-MM-DD)',
    revenue = 'Total revenue in USD from completed orders',
    order_count = 'Number of completed orders'
  ),
  assertions (
    not_null(columns := (customer_id, revenue_date, revenue)),
    unique_combination_of_columns(columns := (customer_id, revenue_date)),
    accepted_range(column := revenue, min_v := 0, max_v := 10000000)
  ),
  partitioned_by revenue_date,
  clustered_by (customer_id)
);

SELECT
  customer_id::INT,
  order_date::DATE as revenue_date,
  SUM(amount)::DECIMAL(10,2) as revenue,
  COUNT(*)::INT as order_count
FROM staging.orders
WHERE order_date BETWEEN @start_ds AND @end_ds
  AND status = 'completed'
GROUP BY customer_id, order_date;
```

### 12.2 Upsert-Based Incremental Model

**Use Case:** Slowly changing dimension table with upsert logic.

```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    when_matched 'UPDATE SET 
      name = source.name,
      email = source.email,
      updated_at = source.updated_at
      WHERE target.updated_at < source.updated_at',
    merge_filter 'source.status != ''deleted'''
  ),
  cron '@daily',
  grain customer_id,
  owner 'data-team',
  tags ('dimension', 'customer'),
  description 'Customer dimension table with upsert logic',
  assertions (
    not_null(columns := (customer_id, name, email)),
    unique_values(columns := (customer_id)),
    valid_email(column := email)
  )
);

SELECT
  customer_id::INT,
  customer_name::VARCHAR(255),
  email::VARCHAR(255),
  customer_tier::VARCHAR(50),
  updated_at::TIMESTAMP
FROM raw.customers
WHERE updated_at >= @start_ds;
```

### 12.3 SCD Type 2 Historical Tracking

**Use Case:** Track historical changes to customer data.

```sql
MODEL (
  name analytics.customer_history,
  kind SCD_TYPE_2_BY_TIME (
    unique_key (customer_id),
    updated_at_name 'last_modified',
    updated_at_as_valid_from true,
    invalidate_hard_deletes true
  ),
  cron '@daily',
  grain (customer_id, valid_from),
  owner 'data-team',
  tags ('scd', 'history', 'customer'),
  description 'Historical customer data with SCD Type 2 tracking',
  assertions (
    not_null(columns := (customer_id, valid_from)),
    unique_combination_of_columns(columns := (customer_id, valid_from))
  )
);

SELECT
  customer_id::INT,
  customer_name::VARCHAR(255),
  email::VARCHAR(255),
  tier::VARCHAR(50),
  last_modified::TIMESTAMP as updated_at
FROM raw.customers
WHERE last_modified >= @start_ds;
```

### 12.4 Python ML Model

**Use Case:** Machine learning predictions using Python.

```python
from vulcan import ExecutionContext, model
import pandas as pd
import typing as t
from datetime import datetime

@model(
    "analytics.customer_predictions",
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
    },
    owner="ml-team",
    tags=["ml", "predictions", "customer"],
    assertions=[
        ("not_null", {"columns": ["customer_id"]}),
        ("accepted_range", {"column": "churn_probability", "min_v": 0, "max_v": 1}),
    ]
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    """Generate customer churn predictions using ML model."""
    
    # Fetch data
    customers = context.fetchdf("""
        SELECT 
            customer_id,
            tenure_days,
            total_spent,
            engagement_score
        FROM analytics.customers
        WHERE status = 'active'
    """)
    
    # Load ML model
    import joblib
    model = joblib.load("models/churn_model.pkl")
    
    # Make predictions
    features = customers[['tenure_days', 'total_spent', 'engagement_score']]
    customers['churn_probability'] = model.predict_proba(features)[:, 1]
    customers['predicted_ltv'] = customers['total_spent'] * (1 - customers['churn_probability']) * 2
    customers['prediction_date'] = execution_time.date()
    
    return customers[['customer_id', 'churn_probability', 'predicted_ltv', 'prediction_date']]
```

### 12.5 Seed Model

**Use Case:** Load static reference data from CSV.

```sql
MODEL (
  name analytics.national_holidays,
  kind SEED (
    path 'national_holidays.csv',
    batch_size 1000
  ),
  columns (
    holiday_name VARCHAR(255),
    holiday_date DATE
  ),
  owner 'data-team',
  tags ('reference', 'static'),
  description 'National holidays reference data',
  assertions (
    not_null(columns := (holiday_name, holiday_date)),
    unique_values(columns := (holiday_date))
  )
);
```

### 12.6 Multi-Warehouse Model

**Use Case:** Model that runs on different engines.

```sql
MODEL (
  name analytics.events,
  gateway 'snowflake',  -- Use Snowflake gateway
  dialect snowflake,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date
  ),
  cron '@hourly',
  physical_properties (
    warehouse = 'COMPUTE_WH',
    creatable_type = TRANSIENT
  )
);

SELECT * FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
```

### 12.7 Forward-Only Large Table

**Use Case:** Very large table where rebuilds are expensive.

```sql
MODEL (
  name analytics.large_event_table,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_date,
    forward_only true,              -- No rebuilds
    on_destructive_change 'error',  -- Block breaking changes
    on_additive_change 'allow',     -- Allow new columns
    batch_size 7,                   -- Process 7 days per batch
    batch_concurrency 5             -- 5 batches in parallel
  ),
  cron '@daily',
  start '2020-01-01',
  partitioned_by event_date,
  clustered_by (customer_id, event_type),
  physical_properties (
    partition_expiration_days = 365,
    require_partition_filter = true
  )
);

SELECT * FROM raw.events
WHERE event_date BETWEEN @start_ds AND @end_ds;
```

### 12.8 Model with Pre/Post Statements

**Use Case:** Model requiring setup and cleanup.

```sql
MODEL (
  name analytics.customers,
  kind FULL,
  owner 'data-team'
);

-- Pre-statements
SET timezone = 'UTC';
CACHE TABLE countries AS SELECT * FROM raw.countries;

-- Model query
SELECT
  c.customer_id,
  c.customer_name,
  co.country
FROM raw.customers c
JOIN countries co ON c.country_id = co.country_id;

-- Post-statements (conditional)
@IF(@runtime_stage = 'evaluating',
  ANALYZE TABLE analytics.customers;
  UNCACHE TABLE countries;
);
```

### 12.9 Model with Virtual Update Grants

**Use Case:** Model requiring permission grants in dev environments.

```sql
MODEL (
  name analytics.sensitive_customers,
  kind FULL,
  owner 'data-team',
  tags ('pii', 'sensitive')
);

SELECT * FROM raw.customers WHERE has_pii = true;

ON_VIRTUAL_UPDATE_BEGIN;
GRANT SELECT ON VIEW @this_model TO ROLE analyst_role;
GRANT SELECT ON VIEW @this_model TO ROLE readonly_role;
ON_VIRTUAL_UPDATE_END;
```

### 12.10 Complete Production Model

**Use Case:** Production-ready model with all best practices.

```sql
MODEL (
  name analytics.daily_customer_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column metric_date,
    lookback 3,
    batch_size 30,
    batch_concurrency 3
  ),
  cron '@daily',
  cron_tz 'America/Los_Angeles',
  interval_unit 'day',
  start '2020-01-01',
  grain (customer_id, metric_date),
  references (customer_id),
  owner 'analytics-team',
  tags ('analytics', 'customer', 'metrics', 'critical', 'p0'),
  description 'Daily customer metrics including revenue, orders, and engagement. Used for customer analytics dashboards.',
  column_descriptions (
    customer_id = 'Foreign key to customers table (INT)',
    metric_date = 'Date of metrics (YYYY-MM-DD)',
    revenue = 'Total revenue in USD from completed orders',
    order_count = 'Number of completed orders',
    engagement_score = 'Customer engagement score (0-100)',
    churn_risk = 'Churn risk score from ML model (0-1)'
  ),
  assertions (
    not_null(columns := (customer_id, metric_date, revenue)),
    unique_combination_of_columns(columns := (customer_id, metric_date)),
    accepted_range(column := revenue, min_v := 0, max_v := 10000000),
    accepted_range(column := engagement_score, min_v := 0, max_v := 100),
    accepted_range(column := churn_risk, min_v := 0, max_v := 1)
  ),
  partitioned_by metric_date,
  clustered_by (customer_id),
  physical_properties (
    partition_expiration_days = 365,
    require_partition_filter = true,
    creatable_type = TRANSIENT
  ),
  optimize_query true,
  formatting true
);

SELECT
  customer_id::INT,
  order_date::DATE as metric_date,
  SUM(amount)::DECIMAL(10,2) as revenue,
  COUNT(*)::INT as order_count,
  AVG(engagement_score)::DECIMAL(5,2) as engagement_score,
  AVG(churn_probability)::DECIMAL(3,2) as churn_risk
FROM staging.orders o
JOIN analytics.customer_features cf ON o.customer_id = cf.customer_id
WHERE order_date BETWEEN @start_ds AND @end_ds
  AND status = 'completed'
GROUP BY customer_id, order_date;
```

[↑ Back to Top](#chapter-2a-model-properties)

---

## Summary

You've learned about all MODEL DDL properties in Vulcan:

### Key Takeaways

1. **Property Categories:**
   - Required: `name`, `kind`
   - Scheduling: `cron`, `start`, `end`, `interval_unit`
   - Incremental: `time_column`, `lookback`, `batch_size`
   - Data Quality: `grain`, `references`, `assertions`
   - Metadata: `description`, `owner`, `tags`
   - Warehouse: `partitioned_by`, `physical_properties`
   - Execution: `enabled`, `gateway`, `optimize_query`
   - Statements: `pre_statements`, `post_statements`

2. **Property Inheritance:**
   - Project defaults → Model-specific overrides
   - `physical_properties`, `virtual_properties`, `session_properties` are merged
   - Set to `None` to unset project-level properties

3. **Model Kind Specifics:**
   - Each model kind supports different properties
   - Incremental models have additional properties in `kind` definition
   - SEED models have limited property support

4. **Best Practices:**
   - Start with defaults, override only when needed
   - Use `grain` and `assertions` together
   - Condition `post_statements` on `@runtime_stage`
   - Document with `description` and `column_descriptions`

### Related Topics

- **[Chapter 2: Models](02-models.md)** - Model basics and kinds
- **[Chapter 4: Audits](../04-audits.md)** - Comprehensive audit reference
- **[Chapter 2C: Model Operations](../02c-model-operations.md)** - Advanced patterns using properties

### Next Steps

1. Review your existing models and add missing properties
2. Set project defaults in `config.yaml`
3. Add `grain` and `assertions` to critical models
4. Document models with `description` and `column_descriptions`

**Congratulations! You've completed the Model Properties reference chapter.**

[↑ Back to Top](#chapter-2a-model-properties)

---
