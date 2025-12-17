# Transpiling Semantics

The `vulcan transpile` command converts semantic queries into executable SQL, allowing you to preview, debug, and validate semantic logic before execution.

## What is Transpilation?

Transpilation transforms semantic layer queries into database-specific SQL:

- **Semantic SQL → Native SQL**: Converts semantic SQL queries with `MEASURE()` functions into standard SQL
- **REST API Payload → Native SQL**: Converts JSON query payloads into executable SQL statements
- **Validation**: Catches errors before query execution
- **Debugging**: Inspect the generated SQL to understand query behavior

## Basic Structure

### Semantic SQL Query Structure

Semantic SQL queries follow standard SQL syntax with semantic layer extensions:

```sql
SELECT 
  alias.dimension_name,           # Dimensions: attributes for grouping and filtering
  MEASURE(alias.measure_name)  # Measures: aggregated calculations (required wrapper)
FROM alias                        # Semantic model alias (business-friendly name)
CROSS JOIN other_alias            # Optional: join multiple models
WHERE 
  alias.dimension_name = 'value'  # Optional: filter on dimensions
  AND segment_name = true         # Optional: use segments (only = true supported)
GROUP BY alias.dimension_name     # Required: all non-aggregated columns
ORDER BY MEASURE(alias.measure_name)    # Optional: sort results
LIMIT 100                         # Optional: limit result set
OFFSET 0                          # Optional: pagination offset
```

**Key Components:**
- `alias.dimension_name` — Reference dimensions using semantic model alias
- `MEASURE(measure_name)` — Required wrapper for measures to apply aggregation
- `FROM alias` — Use semantic model alias, not physical model name
- `CROSS JOIN` — Join syntax (join conditions automatically inferred)
- `segment_name = true` — Segments only support `= true`, not `= false`

### REST API Payload Structure

REST API queries use JSON payloads with semantic query definitions:

```json
{
  "query": {
    "measures": ["alias.measure_name"],              # Required: array of measure names
    "dimensions": ["alias.dimension_name"],         # Optional: array of dimension names
    "segments": ["segment_name"],                    # Optional: array of segment names
    "timeDimensions": [{                             # Optional: array of time dimension objects
      "dimension": "alias.time_dimension",           # Required: time dimension member
      "dateRange": ["2024-01-01", "2024-12-31"],    # Optional: date range array or string
      "granularity": "month"                         # Optional: hour, day, week, month, quarter, year
    }],
    "filters": [{                                    # Optional: array of filter objects
      "member": "alias.dimension_name",              # Required: fully qualified member name
      "operator": "equals",                          # Required: filter operator
      "values": ["value1", "value2"]                 # Optional: array of filter values
    }],
    "order": {                                       # Optional: sort order object
      "alias.measure_name": "desc",                  # Member name: "asc" or "desc"
      "alias.dimension_name": "asc"
    },
    "limit": 100,                                    # Optional: maximum rows to return
    "offset": 0,                                     # Optional: rows to skip
    "timezone": "UTC",                               # Optional: timezone for date parsing
    "renewQuery": false                              # Optional: bypass cache if true
  },
  "ttl_minutes": 60                                  # Optional: cache duration in minutes
}
```

**Key Components:**
- `measures` — Array of fully qualified measure names: `"alias.measure_name"`
- `dimensions` — Array of fully qualified dimension names: `"alias.dimension_name"`
- `segments` — Array of segment names (no alias prefix needed)
- `timeDimensions` — Array of objects with `dimension`, `dateRange`, and `granularity`
- `filters` — Array of filter objects with `member`, `operator`, and `values`
- `order` — Object mapping member names to sort direction (`"asc"` or `"desc"`)

## Basic Usage

### Transpiling Semantic SQL Queries

Convert semantic SQL queries to native SQL:

```bash
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

**Output:** Generated SQL that can be executed directly against your database.

### Transpiling REST API Payloads

Convert JSON query payloads to native SQL:

```bash
vulcan transpile --format json '{"query": {"measures": ["users.total_users"]}}'
```

**Output:** Generated SQL from the REST-style query definition.

## Command Syntax

### Basic Format

```bash
vulcan transpile --format <format> "<query>"
```

**Parameters:**

- `--format` (required) — Output format: `sql` or `json`
- `"<query>"` (required) — The semantic query to transpile
  - For SQL format: Semantic SQL query string
  - For JSON format: JSON query payload string

### Advanced Options

```bash
vulcan transpile --format sql "<query>" [--disable-post-processing]
```

**Options:**

- `--disable-post-processing` — Enable pushdown mode for CTE support and advanced SQL features
  - **Default**: Post-processing enabled (CTEs not supported)
  - **With flag**: Pushdown enabled (CTEs supported, no pre-aggregations)

## Transpiling Semantic SQL

### Basic Query

Transpile a simple semantic SQL query:

```bash
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

**Generated SQL:**
```sql
SELECT sum("users".user_id) AS total_users
FROM analytics.users AS "users"
```

### Query with Dimensions

Transpile queries with dimensions and grouping:

```bash
vulcan transpile --format sql "SELECT users.plan_type, MEASURE(total_users) FROM users GROUP BY users.plan_type"
```

**Generated SQL:**
```sql
SELECT "users".plan_type, sum("users".user_id) AS total_users
FROM analytics.users AS "users"
GROUP BY "users".plan_type
```

### Query with Filters

Transpile queries with WHERE conditions:

```bash
vulcan transpile --format sql "SELECT MEASURE(total_arr) FROM subscriptions WHERE subscriptions.status = 'active'"
```

**Generated SQL:**
```sql
SELECT sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
WHERE "subscriptions".status = 'active'
```

### Query with Time Grouping

Transpile time-based queries:

```bash
vulcan transpile --format sql "SELECT DATE_TRUNC('month', subscriptions.start_date) as month, MEASURE(total_arr) FROM subscriptions GROUP BY month"
```

**Generated SQL:**
```sql
SELECT DATE_TRUNC('month', "subscriptions".start_date) AS month,
       sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
GROUP BY DATE_TRUNC('month', "subscriptions".start_date)
```

### Query with Joins

Transpile queries joining multiple models:

```bash
vulcan transpile --format sql "SELECT users.industry, MEASURE(total_arr) FROM subscriptions CROSS JOIN users GROUP BY users.industry"
```

**Generated SQL:**
```sql
SELECT "users".industry, sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
CROSS JOIN analytics.users AS "users"
WHERE "subscriptions".user_id = "users".user_id
GROUP BY "users".industry
```

## Transpiling REST API Payloads

### Minimal Query

Transpile a basic REST API query:

```bash
vulcan transpile --format json '{"query": {"measures": ["users.total_users"]}}'
```

**Generated SQL:**
```sql
SELECT sum("users".user_id) AS total_users
FROM analytics.users AS "users"
```

### Query with Dimensions

Transpile queries with dimensions:

```bash
vulcan transpile --format json '{"query": {"measures": ["subscriptions.total_arr"], "dimensions": ["subscriptions.plan_type"]}}'
```

**Generated SQL:**
```sql
SELECT "subscriptions".plan_type, sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
GROUP BY "subscriptions".plan_type
```

### Query with Time Dimensions

Transpile time-based queries:

```bash
vulcan transpile --format json '{"query": {"measures": ["orders.total_revenue"], "timeDimensions": [{"dimension": "orders.order_date", "dateRange": ["2024-01-01", "2024-12-31"], "granularity": "month"}]}}'
```

**Generated SQL:**
```sql
SELECT DATE_TRUNC('month', "orders".order_date) AS orders_order_date_month,
       sum("orders".amount) AS total_revenue
FROM analytics.orders AS "orders"
WHERE "orders".order_date >= '2024-01-01T00:00:00.000'
  AND "orders".order_date <= '2024-12-31T23:59:59.999'
GROUP BY DATE_TRUNC('month', "orders".order_date)
```

### Query with Filters

Transpile queries with filters:

```bash
vulcan transpile --format json '{"query": {"measures": ["subscriptions.total_arr"], "filters": [{"member": "subscriptions.status", "operator": "equals", "values": ["active"]}]}}'
```

**Generated SQL:**
```sql
SELECT sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
WHERE "subscriptions".status = 'active'
```

### Query with Segments

Transpile queries using segments:

```bash
vulcan transpile --format json '{"query": {"measures": ["subscriptions.total_arr"], "segments": ["subscriptions.active_subscriptions"]}}'
```

**Generated SQL:**
```sql
SELECT sum("subscriptions".arr) AS total_arr
FROM analytics.subscriptions AS "subscriptions"
WHERE "subscriptions".status = 'active'
  AND "subscriptions".end_date IS NULL
```

### Complex Query

Transpile complex queries with multiple components:

```bash
vulcan transpile --format json '{"query": {"measures": ["subscriptions.total_arr", "subscriptions.total_seats"], "dimensions": ["subscriptions.plan_type", "users.industry"], "filters": [{"member": "subscriptions.status", "operator": "equals", "values": ["active"]}], "timeDimensions": [{"dimension": "subscriptions.start_date", "dateRange": ["2024-01-01", "2024-12-31"], "granularity": "month"}], "order": {"subscriptions.total_arr": "desc"}, "limit": 100}}'
```

**Generated SQL:**
```sql
SELECT DATE_TRUNC('month', "subscriptions".start_date) AS subscriptions_start_date_month,
       "subscriptions".plan_type,
       "users".industry,
       sum("subscriptions".arr) AS total_arr,
       sum("subscriptions".seats) AS total_seats
FROM analytics.subscriptions AS "subscriptions"
CROSS JOIN analytics.users AS "users"
WHERE "subscriptions".status = 'active'
  AND "subscriptions".start_date >= '2024-01-01T00:00:00.000'
  AND "subscriptions".start_date <= '2024-12-31T23:59:59.999'
  AND "subscriptions".user_id = "users".user_id
GROUP BY DATE_TRUNC('month', "subscriptions".start_date),
         "subscriptions".plan_type,
         "users".industry
ORDER BY sum("subscriptions".arr) DESC
LIMIT 100
```

## Use Cases

### Query Validation

Validate semantic queries before execution:

```bash
# Check if query syntax is correct
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

If the query is invalid, you'll get an error message indicating the issue.

### Debugging Query Behavior

Inspect generated SQL to understand how semantic queries are translated:

```bash
# See how measures are aggregated
vulcan transpile --format sql "SELECT users.plan_type, MEASURE(total_users) FROM users GROUP BY users.plan_type"
```

### Performance Analysis

Review generated SQL to identify optimization opportunities:

```bash
# Check join conditions and filter placement
vulcan transpile --format sql "SELECT users.industry, MEASURE(total_arr) FROM subscriptions CROSS JOIN users WHERE subscriptions.status = 'active' GROUP BY users.industry"
```

### Documentation

Generate SQL examples for documentation or training:

```bash
# Create SQL reference from semantic queries
vulcan transpile --format sql "SELECT MEASURE(total_arr) FROM subscriptions WHERE subscriptions.status = 'active'"
```

## Common Errors and Solutions

### Error: "Unknown member: X"

**Cause:** Member doesn't exist in semantic model or is misspelled.

**Solution:**
- Verify member exists in your semantic model
- Check spelling and casing (case-sensitive)
- Use fully qualified format: `alias.member_name`

### Error: "Measure not found: X"

**Cause:** Measure referenced without proper qualification or doesn't exist.

**Solution:**
- Use `MEASURE(measure_name)` wrapper for SQL format
- Use fully qualified format: `alias.measure_name` for JSON format
- Verify measure is defined in semantic model

### Error: "Model not found: X"

**Cause:** Alias doesn't match any semantic model.

**Solution:**
- Check semantic model aliases in your `semantics/` directory
- Verify alias spelling and casing
- Ensure semantic models are properly defined


### Error: "Invalid JSON format"

**Cause:** JSON payload is malformed.

**Solution:**
- Validate JSON syntax
- Ensure proper quoting of strings
- Check array and object structure

### Error: "Projection references non-aggregate values"

**Cause:** Non-aggregated columns not in GROUP BY, or measures missing MEASURE() wrapper.

**Solution:**
- Add all non-aggregated columns to GROUP BY
- Use MEASURE() wrapper for all measures in SQL format

## Best Practices

### Validate Before Execution

Always transpile queries before running them in production:

```bash
# ✅ Good: Validate first
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
# Review output, then execute

# ❌ Bad: Execute without validation
# Direct execution without checking generated SQL
```

### Use Transpilation for Debugging

When queries return unexpected results, transpile to inspect generated SQL:

```bash
# Debug query behavior
vulcan transpile --format sql "SELECT users.plan_type, MEASURE(total_users) FROM users GROUP BY users.plan_type"
# Compare generated SQL with expected behavior
```

### Document Query Patterns

Use transpilation output to document common query patterns:

```bash
# Generate SQL examples for documentation
vulcan transpile --format sql "SELECT MEASURE(total_arr) FROM subscriptions WHERE subscriptions.status = 'active'"
```

### Test Both Formats

When building applications, test both SQL and JSON formats:

```bash
# Test SQL format
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"

# Test equivalent JSON format
vulcan transpile --format json '{"query": {"measures": ["users.total_users"]}}'
```

### Choose Appropriate Mode

Select post-processing or pushdown mode based on needs:

- **Post-processing (default)**: Use for queries that benefit from pre-aggregations and caching
- **Pushdown (`--disable-post-processing`)**: Use when you need CTEs or complex SQL structures

## Integration with Development Workflow

### Pre-commit Validation

Add transpilation checks to your development workflow:

```bash
# Validate semantic queries in CI/CD
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

### Query Testing

Use transpilation to generate test SQL:

```bash
# Generate SQL for testing
vulcan transpile --format sql "SELECT users.plan_type, MEASURE(total_users) FROM users GROUP BY users.plan_type"
# Use output in test assertions
```

### Performance Tuning

Analyze generated SQL for optimization:

```bash
# Review join conditions and filter placement
vulcan transpile --format sql "SELECT users.industry, MEASURE(total_arr) FROM subscriptions CROSS JOIN users WHERE subscriptions.status = 'active' GROUP BY users.industry"
```

## Next Steps

- Learn about [Semantic Models](../../semantics/models.md) that define the queryable members
- Explore [Business Metrics](../../semantics/business_metrics.md) for time-series analysis
- See the [Semantics Overview](components/semantics/index.md) for the complete picture

