# Migrating Flare Programs to Vulcan Models

A practical guide to converting your Flare data pipeline programs into Vulcan models. This one-pager covers the essential patterns and steps for a smooth migration.

---

## 🎯 Migration Overview

**Flare → Vulcan Migration Path:**
```
Flare Program → Vulcan Model → Plan → Run → Production
```

**Key Differences:**
- **Flare:** Program-based execution with custom orchestration
- **Vulcan:** Model-based with built-in state management, incremental processing, and CI/CD

---

## 📋 Step-by-Step Migration Process

### Step 1: Understand Your Flare Program Structure

**Identify:**
- Input sources (tables, files, APIs)
- Transformation logic (SQL or Python)
- Output destination
- Incremental logic (if any)
- Dependencies between programs

### Step 2: Create Vulcan Project Structure

```bash
# Initialize Vulcan project
vulcan init

# Project structure created:
# ├── models/      # Your Flare programs → Vulcan models
# ├── audits/      # Data quality checks
# ├── tests/       # Unit tests
# └── config.yaml  # Configuration
```

### Step 3: Convert Flare Programs to Vulcan Models

---

## 🔄 Common Migration Patterns

### Pattern 1: SQL Transformation Programs

**Flare Program (Example):**
```python
# flare_program.py
def transform():
    sql = """
    SELECT 
        user_id,
        email,
        created_at,
        status
    FROM raw.users
    WHERE status = 'active'
    """
    execute_sql(sql, target_table='warehouse.active_users')
```

**Vulcan Model:**
```sql
-- models/active_users.sql
MODEL (
  name warehouse.active_users,
  kind FULL,
  start '2024-01-01',
  cron '@daily'
);

SELECT 
  user_id,
  email,
  created_at,
  status
FROM raw.users
WHERE status = 'active';
```

**Key Changes:**
- ✅ Move SQL to `.sql` file in `models/` directory
- ✅ Add `MODEL()` declaration with metadata
- ✅ Remove program wrapper code
- ✅ Specify `kind` (FULL, INCREMENTAL_BY_TIME_RANGE, etc.)

---

### Pattern 2: Incremental Programs

**Flare Program:**
```python
# flare_incremental.py
def transform_incremental():
    last_run = get_last_run_time()
    sql = f"""
    SELECT *
    FROM raw.events
    WHERE event_time > '{last_run}'
    """
    execute_sql(sql, target_table='warehouse.events', mode='append')
```

**Vulcan Model:**
```sql
-- models/events.sql
MODEL (
  name warehouse.events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column event_time
  ),
  start '2024-01-01',
  cron '@hourly'
);

SELECT 
  event_id,
  user_id,
  event_time,
  event_type,
  properties
FROM raw.events
WHERE event_time BETWEEN @start_ds AND @end_ds;
```

**Key Changes:**
- ✅ Use `INCREMENTAL_BY_TIME_RANGE` kind
- ✅ Specify `time_column` in MODEL declaration
- ✅ Use `@start_ds` and `@end_ds` variables (Vulcan provides these)
- ✅ Set `cron` schedule for automatic execution
- ✅ Vulcan handles state management automatically

---

### Pattern 3: Python Transformation Programs

**Flare Program:**
```python
# flare_python.py
import pandas as pd

def transform():
    # Read data
    df = read_table('raw.users')
    
    # Transform
    df['full_name'] = df['first_name'] + ' ' + df['last_name']
    df['is_premium'] = df['plan_type'] == 'premium'
    
    # Write
    write_table(df, 'warehouse.users_enriched')
```

**Vulcan Model:**
```python
# models/users_enriched.py
import pandas as pd

MODEL (
  name warehouse.users_enriched,
  kind FULL,
  start '2024-01-01',
  cron '@daily'
);

def execute(context, start, end):
    # Read data
    df = context.table('raw.users')
    
    # Transform
    df['full_name'] = df['first_name'] + ' ' + df['last_name']
    df['is_premium'] = df['plan_type'] == 'premium'
    
    # Return DataFrame (Vulcan handles writing)
    return df
```

**Key Changes:**
- ✅ Use `MODEL()` declaration (same as SQL)
- ✅ Function signature: `execute(context, start, end)`
- ✅ Use `context.table()` to read data
- ✅ Return DataFrame (Vulcan writes it automatically)
- ✅ No explicit write operations needed

---

### Pattern 4: Programs with Dependencies

**Flare Program:**
```python
# flare_dependent.py
def transform():
    # Step 1: Process users
    process_users()
    
    # Step 2: Process orders (depends on users)
    process_orders()
    
    # Step 3: Aggregate (depends on orders)
    aggregate_sales()
```

**Vulcan Models:**
```sql
-- models/users.sql
MODEL (name warehouse.users, ...);
SELECT ... FROM raw.users;

-- models/orders.sql
MODEL (name warehouse.orders, ...);
SELECT ... FROM raw.orders
JOIN warehouse.users ON ...;

-- models/sales_aggregated.sql
MODEL (name warehouse.sales_aggregated, ...);
SELECT ... FROM warehouse.orders
GROUP BY ...;
```

**Key Changes:**
- ✅ Split into separate model files
- ✅ Vulcan automatically resolves dependencies from SQL `FROM`/`JOIN` clauses
- ✅ No explicit dependency management needed
- ✅ Models execute in correct order automatically

---

### Pattern 5: Data Quality Checks

**Flare Program:**
```python
# flare_quality_check.py
def check_quality():
    result = execute_sql("""
        SELECT COUNT(*) as null_count
        FROM warehouse.users
        WHERE email IS NULL
    """)
    if result['null_count'] > 0:
        raise Exception("Quality check failed!")
```

**Vulcan Audit:**
```sql
-- audits/users_email_not_null.sql
SELECT 
  user_id,
  email
FROM warehouse.users
WHERE email IS NULL;
```

**Key Changes:**
- ✅ Move to `audits/` directory
- ✅ Query returns rows = failure (no rows = pass)
- ✅ Vulcan automatically blocks execution if audit fails
- ✅ No custom exception handling needed

---

## 🔧 Configuration Migration

### Flare Configuration → Vulcan config.yaml

**Flare Config:**
```yaml
# flare_config.yaml
database:
  host: warehouse.example.com
  port: 5432
  database: analytics
schedules:
  daily: "0 2 * * *"
  hourly: "0 * * * *"
```

**Vulcan Config:**
```yaml
# config.yaml
gateways:
  default:
    connection:
      type: postgres
      host: warehouse.example.com
      port: 5432
      database: analytics
      user: ${DB_USER}
      password: ${DB_PASSWORD}

model_defaults:
  dialect: postgres
  start: 2024-01-01
  cron: '@daily'  # Can be overridden per model
```

---

## 📊 Migration Checklist

### Pre-Migration
- [ ] Inventory all Flare programs
- [ ] Document dependencies between programs
- [ ] Identify incremental vs full refresh patterns
- [ ] List all data sources and destinations
- [ ] Document any custom orchestration logic

### Migration Steps
- [ ] Create Vulcan project: `vulcan init`
- [ ] Convert each Flare program to Vulcan model
- [ ] Migrate data quality checks to audits
- [ ] Update configuration in `config.yaml`
- [ ] Convert tests to Vulcan test format
- [ ] Set up semantic layer (if needed)

### Post-Migration
- [ ] Run `vulcan lint` to validate models
- [ ] Run `vulcan test` to verify logic
- [ ] Create plan: `vulcan plan`
- [ ] Review plan output
- [ ] Apply plan: `vulcan plan` (then 'y')
- [ ] Set up scheduling: `vulcan run` (via cron/CI/CD)
- [ ] Monitor execution and logs

---

## 🎯 Key Migration Benefits

**After Migration, You Get:**

1. **Automatic State Management**
   - No manual tracking of last run times
   - Vulcan handles incremental processing automatically

2. **Built-in CI/CD**
   - `vulcan plan` shows impact before deployment
   - Test changes in isolated environments
   - Rollback capability

3. **Dependency Resolution**
   - Automatic dependency detection from SQL
   - Correct execution order guaranteed
   - No manual orchestration needed

4. **Data Quality**
   - Audits block bad data automatically
   - Checks monitor quality over time
   - Tests validate logic before execution

5. **Semantic Layer**
   - Define metrics once, use everywhere
   - Automatic API generation
   - Business-friendly query interface

---

## 🔄 Execution Model Comparison

| Aspect | Flare | Vulcan |
|--------|-------|--------|
| **Execution** | Program-based | Model-based |
| **State Management** | Manual | Automatic |
| **Dependencies** | Explicit | Auto-detected |
| **Incremental Logic** | Custom code | Built-in (`@start_ds`, `@end_ds`) |
| **Scheduling** | External (cron/airflow) | Built-in (`cron` in model) |
| **Testing** | Custom framework | Built-in (`vulcan test`) |
| **Data Quality** | Custom checks | Built-in (audits, checks) |
| **CI/CD** | Custom setup | Built-in (`vulcan plan`) |

---

## 💡 Common Migration Scenarios

### Scenario 1: Simple ETL Pipeline

**Before (Flare):**
```
raw_data → transform → output_table
```

**After (Vulcan):**
```sql
-- models/output_table.sql
MODEL (name warehouse.output_table, ...);
SELECT ... FROM raw.raw_data;
```

### Scenario 2: Multi-Step Pipeline

**Before (Flare):**
```
raw → stage → clean → aggregate → final
```

**After (Vulcan):**
```sql
-- models/stage.sql
MODEL (name warehouse.stage, ...);
SELECT ... FROM raw.raw;

-- models/clean.sql  
MODEL (name warehouse.clean, ...);
SELECT ... FROM warehouse.stage;

-- models/aggregate.sql
MODEL (name warehouse.aggregate, ...);
SELECT ... FROM warehouse.clean GROUP BY ...;

-- models/final.sql
MODEL (name warehouse.final, ...);
SELECT ... FROM warehouse.aggregate;
```

**Vulcan automatically:**
- Detects dependencies
- Executes in correct order
- Handles failures gracefully

### Scenario 3: Incremental Updates

**Before (Flare):**
```python
last_run = get_last_run()
process_since(last_run)
update_last_run()
```

**After (Vulcan):**
```sql
MODEL (
  name warehouse.events,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_time),
  cron '@hourly'
);
SELECT ... FROM raw.events
WHERE event_time BETWEEN @start_ds AND @end_ds;
```

**Vulcan handles:**
- State tracking
- Interval calculation
- Incremental execution

---

## 🚀 Quick Start Migration

**1. Convert one program at a time:**
```bash
# Start with simplest program
# Convert to Vulcan model
# Test: vulcan lint && vulcan test
# Plan: vulcan plan
# Apply: vulcan plan (then 'y')
```

**2. Migrate incrementally:**
- Keep Flare running for production
- Migrate one model at a time
- Test thoroughly before switching
- Gradually move all models

**3. Parallel run period:**
- Run both Flare and Vulcan
- Compare outputs
- Validate data consistency
- Switch over when confident

---

## 📝 Migration Template

**Use this template for each Flare program:**

```sql
-- models/[your_model_name].sql
MODEL (
  name [schema].[table_name],
  kind [FULL | INCREMENTAL_BY_TIME_RANGE | INCREMENTAL_BY_UNIQUE_KEY],
  start 'YYYY-MM-DD',  -- Historical data start date
  cron '@[schedule]'   -- '@daily', '@hourly', etc.
);

-- Your Flare transformation SQL here
SELECT 
  column1,
  column2,
  ...
FROM [source_table]
WHERE [conditions];
```

---

## 🎓 Summary

**Migration Path:**
1. **Analyze** → Understand Flare program structure
2. **Convert** → Transform to Vulcan model format
3. **Configure** → Set up `config.yaml`
4. **Test** → Validate with `vulcan lint` and `vulcan test`
5. **Plan** → Review changes with `vulcan plan`
6. **Apply** → Deploy with `vulcan plan` (then 'y')
7. **Schedule** → Automate with `vulcan run`

**Key Takeaway:** Vulcan eliminates the need for custom orchestration, state management, and dependency tracking. Your Flare programs become simpler, more maintainable Vulcan models with built-in CI/CD, testing, and data quality.

---

*Migrate incrementally, test thoroughly, and leverage Vulcan's built-in features to simplify your data pipeline.*
