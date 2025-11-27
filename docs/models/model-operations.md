# Chapter 2C: Model Operations

> **Advanced patterns and operations for building sophisticated models** - Blueprinting, dynamic SQL generation, advanced signals and macros, dependency management, and more.

---

## Prerequisites

Before reading this chapter, you should be familiar with:

- [Chapter 2: Models](02-models.md) - Foundation concepts
- Basic SQL and Python
- Understanding of model kinds and properties

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Advanced SQL Patterns](#2-advanced-sql-patterns)
3. [Advanced Python Patterns](#3-advanced-python-patterns)
4. [Signals (Detailed)](#4-signals-detailed)
5. [Macros (Detailed)](#5-macros-detailed)
6. [Model Dependencies](#6-model-dependencies)
7. [Model Blueprinting](#7-model-blueprinting)
8. [Summary and Next Steps](#8-summary-and-next-steps)

---

## 1. Introduction

This chapter covers advanced patterns and operations for building sophisticated models in Vulcan. While [Chapter 2: Models](02-models.md) covers the fundamentals, this chapter dives deep into:

- **Advanced SQL Patterns**: Blueprinting, Python-based SQL models, dynamic SQL generation
- **Advanced Python Patterns**: Blueprinting, serialization, DataFrame APIs
- **Signals**: Advanced scheduling patterns and best practices
- **Macros**: Complex macro patterns and debugging
- **Dependencies**: Managing model relationships
- **Blueprinting**: Creating model templates

**When to use this chapter:**

- You need to create multiple similar models (blueprinting)
- You want dynamic SQL generation based on runtime conditions
- You need advanced scheduling logic (signals)
- You're building complex reusable logic (macros)
- You need fine-grained control over model dependencies

**For basics, see [Chapter 2: Models](02-models.md)**

[↑ Back to Top](#chapter-2c-model-operations)

---

## 2. Advanced SQL Patterns

### 2.1 Python-Based SQL Models

Python-based SQL models allow you to generate SQL dynamically using Python code, while still benefiting from SQLMesh's semantic understanding and column-level lineage.

**Key Characteristics:**

- Use `@model(..., is_sql=True)` decorator
- Function returns SQL string or SQLGlot expression
- Supports all SQL model features (lineage, macros, etc.)
- Useful for complex dynamic SQL generation

**Basic Example:**

```python
from sqlglot import exp
from vulcan import model
from vulcan.core.macros import MacroEvaluator

@model(
    "analytics.customers",
    is_sql=True,
    kind="FULL",
    pre_statements=["CACHE TABLE countries AS SELECT * FROM raw.countries"],
    post_statements=["UNCACHE TABLE countries"],
    on_virtual_update=["GRANT SELECT ON VIEW @this_model TO ROLE dev_role"],
)
def entrypoint(evaluator: MacroEvaluator) -> str | exp.Expression:
    return (
        exp.select("r.id::int", "r.name::text", "c.country::text")
        .from_("raw.restaurants as r")
        .join("countries as c", on="r.id = c.restaurant_id")
    )
```

**Dynamic SQL Generation:**

```python
from sqlglot import exp
from vulcan import model
from vulcan.core.macros import MacroEvaluator

@model(
    "analytics.dynamic_metrics",
    is_sql=True,
    kind="FULL",
)
def entrypoint(evaluator: MacroEvaluator) -> str | exp.Expression:
    # Get blueprint variables or global variables
    metrics = evaluator.var("metrics", ["revenue", "orders", "customers"])
    
    # Build dynamic SELECT clause
    select_clauses = []
    for metric in metrics:
        if metric == "revenue":
            select_clauses.append(exp.alias_("SUM(amount)", "revenue"))
        elif metric == "orders":
            select_clauses.append(exp.alias_("COUNT(*)", "orders"))
        elif metric == "customers":
            select_clauses.append(exp.alias_("COUNT(DISTINCT customer_id)", "customers"))
    
    return (
        exp.select(*select_clauses)
        .from_("raw.transactions")
        .group_by("date")
    )
```

**Accessing Model Schemas:**

```python
from sqlglot import exp
from vulcan import model
from vulcan.core.macros import MacroEvaluator

@model(
    "analytics.schema_aware_transform",
    is_sql=True,
    kind="FULL",
)
def entrypoint(evaluator: MacroEvaluator) -> str | exp.Expression:
    # Access upstream model schema
    upstream_columns = evaluator.columns_to_types("raw.transactions")
    
    # Build query based on available columns
    select_clauses = []
    for col_name, col_type in upstream_columns.items():
        if col_type.this == exp.DataType.Type.INT:
            select_clauses.append(exp.alias_(f"SUM({col_name})", f"total_{col_name}"))
    
    return (
        exp.select(*select_clauses)
        .from_("raw.transactions")
        .group_by("date")
    )
```

**When to Use:**

- ✅ Complex conditional SQL logic
- ✅ Dynamic column selection
- ✅ Schema-aware transformations
- ✅ Reusable SQL templates

- ❌ Simple static queries (use regular SQL models)
- ❌ Data transformations (use Python models returning DataFrames)

### 2.2 Complex CTEs and Subqueries

**Multiple CTEs:**

```sql
MODEL (
  name analytics.complex_aggregation,
  kind FULL
);

WITH 
  filtered_orders AS (
    SELECT * FROM raw.orders
    WHERE order_date >= @start_ds
      AND status = 'completed'
  ),
  customer_totals AS (
    SELECT 
      customer_id,
      SUM(amount) AS total_spent,
      COUNT(*) AS order_count
    FROM filtered_orders
    GROUP BY customer_id
  ),
  customer_segments AS (
    SELECT 
      customer_id,
      total_spent,
      order_count,
      CASE 
        WHEN total_spent > 1000 THEN 'high_value'
        WHEN total_spent > 500 THEN 'medium_value'
        ELSE 'low_value'
      END AS segment
    FROM customer_totals
  )
SELECT * FROM customer_segments;
```

**Recursive CTEs:**

```sql
MODEL (
  name analytics.hierarchical_data,
  kind FULL
);

WITH RECURSIVE org_hierarchy AS (
  -- Base case
  SELECT 
    employee_id,
    manager_id,
    name,
    1 AS level
  FROM raw.employees
  WHERE manager_id IS NULL
  
  UNION ALL
  
  -- Recursive case
  SELECT 
    e.employee_id,
    e.manager_id,
    e.name,
    oh.level + 1
  FROM raw.employees e
  INNER JOIN org_hierarchy oh ON e.manager_id = oh.employee_id
)
SELECT * FROM org_hierarchy;
```

### 2.3 Advanced Pre/Post Statements

**Conditional Execution:**

```sql
MODEL (
  name analytics.orders,
  kind FULL
);

SELECT * FROM raw.orders;

-- Only create indexes after table creation
@IF(@runtime_stage = 'creating',
  CREATE INDEX idx_customer_id ON analytics.orders(customer_id);
  CREATE INDEX idx_order_date ON analytics.orders(order_date);
);

-- Only analyze after evaluation
@IF(@runtime_stage = 'evaluating',
  ANALYZE TABLE analytics.orders;
);
```

**Multiple Statements:**

```sql
MODEL (
  name analytics.partitioned_table,
  kind FULL
);

SELECT * FROM raw.events;

-- Pre-statements: Set up partitioning
@IF(@runtime_stage = 'creating',
  ALTER TABLE analytics.partitioned_table 
    SET PARTITION BY (event_date);
  
  CREATE INDEX idx_event_type 
    ON analytics.partitioned_table(event_type);
);

-- Post-statements: Optimize and grant access
@IF(@runtime_stage = 'evaluating',
  OPTIMIZE TABLE analytics.partitioned_table;
  
  GRANT SELECT ON TABLE analytics.partitioned_table 
    TO ROLE analyst_role;
);
```

**Using Macros in Statements:**

```sql
MODEL (
  name analytics.customers,
  kind FULL
);

SELECT * FROM raw.customers;

-- Use macro to generate index creation
@IF(@runtime_stage = 'creating',
  @CREATE_INDEXES(@this_model, customer_id, email, created_at);
);
```

### 2.4 On-Virtual-Update Statements

On-virtual-update statements run after views are swapped in development environments (virtual updates). They're useful for:

- Granting permissions
- Updating metadata
- Refreshing caches

**Basic Example:**

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

**Multiple Statements:**

```sql
MODEL (
  name analytics.sensitive_data,
  kind FULL
);

SELECT * FROM raw.sensitive_data;

ON_VIRTUAL_UPDATE_BEGIN;
-- Grant role-based access
GRANT SELECT ON VIEW @this_model TO ROLE analyst_role;
GRANT SELECT ON VIEW @this_model TO ROLE admin_role;

-- Update metadata
COMMENT ON VIEW @this_model IS 'Updated via virtual update';

-- Refresh materialized view cache
REFRESH MATERIALIZED VIEW analytics.cache_view;
ON_VIRTUAL_UPDATE_END;
```

**Conditional Virtual Updates:**

```sql
MODEL (
  name analytics.environment_specific,
  kind FULL
);

SELECT * FROM raw.data;

ON_VIRTUAL_UPDATE_BEGIN;
@IF(@environment = 'dev',
  GRANT SELECT ON VIEW @this_model TO ROLE dev_role;
);

@IF(@environment = 'prod',
  GRANT SELECT ON VIEW @this_model TO ROLE prod_role;
);
ON_VIRTUAL_UPDATE_END;
```

**Note:** Table resolution occurs at the virtual layer. `@this_model` resolves to the view name (e.g., `analytics__dev.customers`), not the physical table.

[↑ Back to Top](#chapter-2c-model-operations)

---

## 3. Advanced Python Patterns

### 3.1 Python Model Blueprinting

Python models can serve as templates for creating multiple models using blueprinting.

**Basic Blueprinting:**

```python
import typing as t
from datetime import datetime
import pandas as pd
from vulcan import ExecutionContext, model

@model(
    "@{customer}.revenue_metrics",
    kind="FULL",
    blueprints=[
        {"customer": "customer1", "currency": "USD", "region": "US"},
        {"customer": "customer2", "currency": "EUR", "region": "EU"},
        {"customer": "customer3", "currency": "GBP", "region": "UK"},
    ],
    columns={
        "date": "date",
        "revenue": "decimal(10,2)",
        "currency": "text",
        "region": "text",
    },
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    customer = context.blueprint_var("customer")
    currency = context.blueprint_var("currency")
    region = context.blueprint_var("region")
    
    # Fetch customer-specific data
    table = context.resolve_table(f"raw.{customer}_transactions")
    df = context.fetchdf(f"""
        SELECT 
            transaction_date AS date,
            SUM(amount) AS revenue,
            '{currency}' AS currency,
            '{region}' AS region
        FROM {table}
        WHERE transaction_date BETWEEN '{start}' AND '{end}'
        GROUP BY transaction_date
    """)
    
    return df
```

**Dynamic Blueprint Generation:**

```python
from vulcan import macro

@macro()
def gen_customer_blueprints(evaluator):
    """Generate blueprints from external source."""
    import csv
    
    blueprints = []
    with open('customers.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            blueprints.append({
                "customer": row['customer_id'],
                "currency": row['currency'],
                "region": row['region'],
            })
    
    return blueprints
```

**Using EACH Macro:**

```python
@model(
    "@{schema}.metrics",
    blueprints="@EACH(@customer_list, x -> (schema := @x))",
    kind="FULL",
    columns={"metric": "text", "value": "int"},
)
def execute(context, **kwargs):
    schema = context.blueprint_var("schema")
    table = context.resolve_table(f"{schema}.raw_data")
    return context.fetchdf(f"SELECT * FROM {table}")
```

### 3.2 Returning Empty DataFrames

Python models cannot return empty DataFrames directly. Use generators instead:

```python
@model(
    "analytics.conditional_output",
    columns={"id": "int", "value": "text"},
)
def execute(
    context: ExecutionContext,
    **kwargs: t.Any,
) -> pd.DataFrame:
    df = context.fetchdf("SELECT * FROM raw.data WHERE condition = true")
    
    if df.empty:
        # Return empty generator instead of empty DataFrame
        yield from ()
    else:
        yield df
```

### 3.3 User-Defined Variables

**Accessing Variables:**

```python
@model(
    "analytics.configurable_model",
    columns={"id": "int"},
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    threshold: int = 100,  # Variable as function argument
    **kwargs: t.Any,
) -> pd.DataFrame:
    # Access via context.var()
    batch_size = context.var("batch_size", 1000)
    
    # Access via function argument (preferred)
    # threshold is already available as argument
    
    table = context.resolve_table("raw.data")
    df = context.fetchdf(f"""
        SELECT * FROM {table}
        WHERE value > {threshold}
        LIMIT {batch_size}
    """)
    
    return df
```

**Variable Precedence:**

1. Blueprint variables (highest)
2. Gateway-specific variables
3. Global variables
4. Function argument defaults (lowest)

### 3.4 DataFrame APIs

**PySpark:**

```python
from pyspark.sql import DataFrame, functions as F
from vulcan import ExecutionContext, model

@model(
    "analytics.spark_transform",
    columns={"id": "int", "category": "text", "amount": "decimal(10,2)"},
)
def execute(
    context: ExecutionContext,
    **kwargs: t.Any,
) -> DataFrame:
    table = context.resolve_table("raw.transactions")
    
    # Use Spark DataFrame API
    df = context.spark.table(table)
    
    df = (
        df
        .withColumn("category", F.upper(F.col("category")))
        .filter(F.col("amount") > 100)
        .groupBy("category")
        .agg(F.sum("amount").alias("total"))
    )
    
    return df  # Returns Spark DataFrame, computation happens in Spark
```

**Snowpark:**

```python
from snowflake.snowpark.dataframe import DataFrame
from vulcan import ExecutionContext, model

@model(
    "analytics.snowpark_transform",
    columns={"id": "int", "value": "decimal(10,2)"},
)
def execute(
    context: ExecutionContext,
    **kwargs: t.Any,
) -> DataFrame:
    # Create Snowpark DataFrame
    df = context.snowpark.create_dataframe(
        [[1, 100.0], [2, 200.0]], 
        schema=["id", "value"]
    )
    
    # Use Snowpark DataFrame API
    df = df.filter(df.id > 1)
    
    return df  # Returns Snowpark DataFrame, computation happens in Snowflake
```

**Bigframe:**

```python
from bigframes.pandas import DataFrame
from vulcan import ExecutionContext, model

@model(
    "analytics.bigframe_transform",
    columns={"title": "text", "views": "int", "bucket": "text"},
)
def execute(
    context: ExecutionContext,
    **kwargs: t.Any,
) -> DataFrame:
    # Read from BigQuery
    df = context.bigframe.read_gbq("project.dataset.table")
    
    # Use Bigframe API (lazy evaluation)
    df = (
        df[df.title.str.contains("Google")]
        .groupby(["title"], as_index=False)["views"]
        .sum(numeric_only=True)
        .sort_values("views", ascending=False)
    )
    
    return df  # Returns Bigframe DataFrame, computation happens in BigQuery
```

### 3.5 Batching Large Outputs

For large outputs, use generators to batch data:

```python
@model(
    "analytics.batched_output",
    columns={"id": "int", "value": "text"},
)
def execute(
    context: ExecutionContext,
    **kwargs: t.Any,
) -> pd.DataFrame:
    table = context.resolve_table("raw.large_table")
    batch_size = 10000
    
    # Process in batches
    offset = 0
    while True:
        df = context.fetchdf(f"""
            SELECT * FROM {table}
            ORDER BY id
            LIMIT {batch_size} OFFSET {offset}
        """)
        
        if df.empty:
            break
        
        yield df
        offset += batch_size
```

### 3.6 Serialization

Vulcan uses a custom serialization framework to execute Python models. Key points:

- Models are serialized and executed where Vulcan runs
- Dependencies are captured automatically
- Python environment is isolated per model
- Supports custom Python environments

**Best Practices:**

- Keep model code focused and minimal
- Avoid heavy imports in model files
- Use project-level Python environment configuration
- Test serialization in development environments

[↑ Back to Top](#chapter-2c-model-operations)

---

## 4. Signals (Detailed)

Signals provide advanced scheduling logic beyond simple `cron` expressions. For basics, see [Chapter 2: Models](02-models.md#10-signals).

### 4.1 Multiple Signals

A model can have multiple signals - **ALL must pass** for the model to run:

```python
# signals/__init__.py
from vulcan import signal, DatetimeRanges
import typing as t

@signal()
def s3_file_exists(batch: DatetimeRanges, bucket: str, key_pattern: str) -> bool:
    """Check if S3 file exists."""
    import boto3
    s3 = boto3.client('s3')
    # Check file existence logic
    return True

@signal()
def api_healthy(batch: DatetimeRanges, api_url: str) -> bool:
    """Check if API is healthy."""
    import requests
    try:
        response = requests.get(api_url, timeout=5)
        return response.status_code == 200
    except:
        return False

@signal()
def business_hours_only(batch: DatetimeRanges) -> bool:
    """Only run during business hours."""
    from datetime import datetime
    now = datetime.now()
    return 9 <= now.hour < 17
```

**Model Usage:**

```sql
MODEL (
  name analytics.critical_data,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  signals (
    s3_file_exists(bucket := 'data-lake', key_pattern := 'events.parquet'),
    api_healthy(api_url := 'https://api.example.com'),
    business_hours_only()
  )
);

SELECT * FROM raw.events
WHERE event_date BETWEEN @start_date AND @end_date;
```

**Model runs only when:**
1. ✅ S3 file exists
2. ✅ API is healthy
3. ✅ During business hours

### 4.2 Returning Specific Intervals

Signals can return specific intervals from a batch instead of `True`/`False`:

```python
from vulcan import signal, DatetimeRanges
from vulcan.utils.date import to_datetime
import typing as t

@signal()
def one_week_ago(batch: DatetimeRanges) -> t.Union[bool, DatetimeRanges]:
    """Only process intervals older than 1 week."""
    cutoff = to_datetime("1 week ago")
    
    return [
        (start, end)
        for start, end in batch
        if start <= cutoff
    ]
```

**Use Case:**

```sql
MODEL (
  name analytics.historical_backfill,
  kind INCREMENTAL_BY_TIME_RANGE (time_column event_date),
  signals (one_week_ago())
);

SELECT * FROM raw.events
WHERE event_date BETWEEN @start_date AND @end_date;
```

This ensures only data older than 1 week is processed, preventing premature processing of recent data.

### 4.3 Advanced Signal Patterns

**File Arrival Detection:**

```python
@signal()
def file_arrived(
    batch: DatetimeRanges, 
    file_path: str,
    expected_size: int = None
) -> bool:
    """Check if file exists and optionally verify size."""
    import os
    
    if not os.path.exists(file_path):
        return False
    
    if expected_size:
        actual_size = os.path.getsize(file_path)
        return actual_size >= expected_size
    
    return True
```

**Late-Arriving Data:**

```python
@signal()
def upstream_freshness(
    batch: DatetimeRanges,
    upstream_model: str,
    max_age_hours: int = 24
) -> t.Union[bool, DatetimeRanges]:
    """Wait for upstream model to be fresh."""
    from datetime import datetime, timedelta
    
    # Check upstream model's last update time
    # (Implementation depends on your tracking system)
    last_update = get_model_last_update(upstream_model)
    cutoff = datetime.now() - timedelta(hours=max_age_hours)
    
    if last_update < cutoff:
        return False
    
    # Return intervals that are ready
    return [
        (start, end)
        for start, end in batch
        if end <= last_update
    ]
```

**External API Dependency:**

```python
@signal()
def external_api_ready(
    batch: DatetimeRanges,
    api_url: str,
    endpoint: str,
    timeout: int = 30
) -> bool:
    """Wait for external API to be ready."""
    import requests
    
    try:
        response = requests.get(
            f"{api_url}/{endpoint}",
            timeout=timeout
        )
        return response.status_code == 200
    except requests.RequestException:
        return False
```

### 4.4 Testing Signals

**Manual Testing:**

```bash
# Check intervals with signals
vulcan check_intervals dev --select analytics.critical_data

# Check intervals without signals
vulcan check_intervals dev --select analytics.critical_data --no-signals

# Run scheduler (evaluates signals automatically)
vulcan run dev
```

**Unit Testing Signals:**

```python
# tests/test_signals.py
from vulcan import DatetimeRanges
from signals import s3_file_exists

def test_s3_file_exists():
    batch = [
        (datetime(2024, 1, 1), datetime(2024, 1, 2)),
        (datetime(2024, 1, 2), datetime(2024, 1, 3)),
    ]
    
    result = s3_file_exists(
        batch=DatetimeRanges(batch),
        bucket="test-bucket",
        key_pattern="data.parquet"
    )
    
    assert isinstance(result, bool)
```

### 4.5 Signal Best Practices

**✅ DO:**

- Handle exceptions gracefully
- Use timeouts for external calls
- Log signal decisions for debugging
- Return specific intervals when possible
- Test signals in development environments
- Make signals idempotent

**❌ DON'T:**

- Make expensive computations in signals
- Depend on unreliable external services without retries
- Use signals for simple scheduling (use `cron`)
- Forget to handle edge cases
- Block signals indefinitely

**Performance Considerations:**

- Signals are evaluated frequently (every scheduler run)
- Keep signal logic lightweight
- Cache expensive checks when possible
- Use timeouts to prevent hanging

[↑ Back to Top](#chapter-2c-model-operations)

---

## 5. Macros (Detailed)

Macros enable reusable SQL logic and parameterized queries. For basics, see [Chapter 2: Models](02-models.md#11-macros).

### 5.1 Advanced Macro Operators

**EACH Macro:**

```sql
MODEL (
  name analytics.multi_customer,
  kind FULL
);

-- Generate multiple columns using EACH
SELECT
  @EACH(@customer_list, x -> SUM(CASE WHEN customer_id = @x THEN amount ELSE 0 END) AS revenue_@x)
FROM raw.transactions
GROUP BY date;
```

**IF Macro:**

```sql
MODEL (
  name analytics.conditional_logic,
  kind FULL
);

SELECT
  *,
  @IF(@environment = 'prod', 
    'production',
    'development'
  ) AS environment_type
FROM raw.data;
```

**VAR Macro with Defaults:**

```sql
MODEL (
  name analytics.configurable,
  kind FULL
);

SELECT *
FROM raw.data
WHERE value > @VAR(threshold, 100);  -- Use 100 if threshold not defined
```

### 5.2 Complex Macro Patterns

**Nested Macros:**

```sql
MODEL (
  name analytics.nested_logic,
  kind FULL
);

SELECT
  @IF(@VAR(use_aggregation, false),
    SUM(amount) AS total,
    amount AS value
  )
FROM raw.transactions
GROUP BY @IF(@VAR(use_aggregation, false), date, NULL);
```

**Macro Functions:**

```python
# macros/__init__.py
from vulcan import macro

@macro()
def fiscal_quarter(evaluator, date_col: str, fiscal_start_month: int = 1) -> str:
    """Calculate fiscal quarter."""
    return f"""
        CASE 
            WHEN MONTH({date_col}) >= {fiscal_start_month} 
                AND MONTH({date_col}) < {fiscal_start_month + 3}
            THEN 1
            WHEN MONTH({date_col}) >= {fiscal_start_month + 3}
                AND MONTH({date_col}) < {fiscal_start_month + 6}
            THEN 2
            WHEN MONTH({date_col}) >= {fiscal_start_month + 6}
                AND MONTH({date_col}) < {fiscal_start_month + 9}
            THEN 3
            ELSE 4
        END
    """
```

**Usage:**

```sql
MODEL (
  name analytics.fiscal_reporting,
  kind FULL
);

SELECT
  order_date,
  @fiscal_quarter(order_date, 4) AS fiscal_qtr  -- Fiscal year starts in April
FROM raw.orders;
```

**Dynamic Column Generation:**

```python
@macro()
def generate_metrics(evaluator, base_table: str, metrics: list) -> str:
    """Generate metric columns dynamically."""
    selects = []
    for metric in metrics:
        if metric == "revenue":
            selects.append(f"SUM(amount) AS revenue")
        elif metric == "orders":
            selects.append(f"COUNT(*) AS orders")
        elif metric == "customers":
            selects.append(f"COUNT(DISTINCT customer_id) AS customers")
    
    return ", ".join(selects)
```

**Usage:**

```sql
MODEL (
  name analytics.dynamic_metrics,
  kind FULL
);

SELECT
  date,
  @generate_metrics(raw.transactions, @metric_list)
FROM raw.transactions
GROUP BY date;
```

### 5.3 Macro Debugging

**Rendering Macros:**

```bash
# Render model with macros expanded
vulcan render analytics.my_model

# Render specific environment
vulcan render analytics.my_model --environment dev
```

**Debugging Tips:**

1. **Check Macro Syntax:**
   ```sql
   -- Correct: @DEF(var, value);
   @DEF(size, 1);

   -- Incorrect: Missing semicolon
   @DEF(size, 1)  -- ERROR
   ```

2. **Verify Variable Scope:**
   - Local variables (`@DEF`) take precedence
   - Blueprint variables override global variables
   - Gateway variables override root variables

3. **Test Macro Functions:**
   ```python
   # Test macro function independently
   from macros import fiscal_quarter
   result = fiscal_quarter(evaluator, "order_date", 4)
   print(result)  # Check output
   ```

4. **Use Rendering:**
   ```bash
   # See rendered SQL
   vulcan render analytics.my_model > rendered.sql
   ```

### 5.4 Macro Best Practices

**✅ DO:**

- Use macros for reusable logic
- Document macro functions
- Use type hints in Python macros
- Test macros independently
- Keep macro logic simple

**❌ DON'T:**

- Overuse macros (prefer CTEs for complex logic)
- Create circular macro dependencies
- Use macros for simple string substitution
- Forget to handle edge cases
- Make macros too complex

**Performance Considerations:**

- Macros are evaluated at render time (not runtime)
- Complex macros can slow down rendering
- Cache macro results when possible
- Avoid expensive computations in macros

[↑ Back to Top](#chapter-2c-model-operations)

---

## 6. Model Dependencies

Vulcan automatically detects model dependencies by analyzing SQL queries and Python model code. However, you can also manage dependencies explicitly.

### 6.1 Automatic Detection

**SQL Models:**

Dependencies are detected from:
- `FROM` clauses
- `JOIN` clauses
- CTE references
- Subquery references

```sql
MODEL (
  name analytics.dependent_model,
  kind FULL
);

-- Vulcan automatically detects dependency on raw.orders
SELECT * FROM raw.orders;
```

**Python Models:**

Dependencies are detected from:
- `context.resolve_table()` calls
- `context.fetchdf()` queries
- `context.spark.table()` calls

```python
@model("analytics.python_dependent", columns={"id": "int"})
def execute(context, **kwargs):
    # Vulcan automatically detects dependency on raw.orders
    table = context.resolve_table("raw.orders")
    return context.fetchdf(f"SELECT * FROM {table}")
```

### 6.2 Explicit Dependencies

**SQL Models:**

```sql
MODEL (
  name analytics.explicit_deps,
  kind FULL,
  depends_on (raw.orders, raw.customers)  -- Explicit dependencies
);

-- Even if not referenced in query, these are tracked
SELECT 1;
```

**Python Models:**

```python
@model(
    "analytics.explicit_python_deps",
    depends_on=["raw.orders", "raw.customers"],  -- Explicit dependencies
    columns={"id": "int"},
)
def execute(context, **kwargs):
    # Only explicit dependencies are tracked
    # Dynamic references are ignored
    return pd.DataFrame([{"id": 1}])
```

**When to Use Explicit Dependencies:**

- Dynamic table references (string interpolation)
- Conditional dependencies
- External dependencies not in queries
- Documentation purposes

### 6.3 Circular Dependencies

Vulcan detects circular dependencies and prevents them:

```sql
-- Model A depends on Model B
MODEL (name analytics.model_a, kind FULL);
SELECT * FROM analytics.model_b;

-- Model B depends on Model A (CIRCULAR!)
MODEL (name analytics.model_b, kind FULL);
SELECT * FROM analytics.model_a;
```

**Error:**
```
Circular dependency detected: analytics.model_a -> analytics.model_b -> analytics.model_a
```

**Solutions:**

1. **Refactor to remove circular dependency:**
   ```sql
   -- Create intermediate model
   MODEL (name analytics.base_data, kind FULL);
   SELECT * FROM raw.source;
   
   MODEL (name analytics.model_a, kind FULL);
   SELECT * FROM analytics.base_data;
   
   MODEL (name analytics.model_b, kind FULL);
   SELECT * FROM analytics.base_data;
   ```

2. **Use VIEW models for read-only dependencies:**
   ```sql
   MODEL (name analytics.view_a, kind VIEW);
   SELECT * FROM analytics.model_b;
   
   MODEL (name analytics.model_b, kind FULL);
   SELECT * FROM analytics.view_a;  -- VIEW doesn't create circular dependency
   ```

### 6.4 Dependency Visualization

**View DAG:**

```bash
# View dependency graph
vulcan dag

# View specific model dependencies
vulcan dag --select analytics.my_model

# Export to file
vulcan dag --select analytics.my_model > dag.dot
```

**Understanding Dependencies:**

- Upstream: Models that this model depends on
- Downstream: Models that depend on this model
- Direct: Explicitly referenced in query
- Indirect: Dependencies of dependencies

[↑ Back to Top](#chapter-2c-model-operations)

---

## 7. Model Blueprinting

Blueprinting allows you to create multiple models from a single template by parameterizing model names and properties.

### 7.1 SQL Model Blueprinting

**Basic Example:**

```sql
MODEL (
  name @customer.some_table,
  kind FULL,
  blueprints (
    (customer := customer1, field_a := x, field_b := y),
    (customer := customer2, field_a := z, field_b := w)
  )
);

SELECT
  @field_a,
  @{field_b} AS field_b
FROM @customer.some_source
```

**Generated Models:**

```sql
-- customer1.some_table
MODEL (name customer1.some_table, kind FULL);
SELECT 'x', y AS field_b FROM customer1.some_source;

-- customer2.some_table
MODEL (name customer2.some_table, kind FULL);
SELECT 'z', w AS field_b FROM customer2.some_source;
```

**Variable Syntax:**

- `@field_a` → String literal (`'x'`)
- `@{field_b}` → SQL identifier (`y`)
- `@customer` → Used in model name and table references

### 7.2 Python Model Blueprinting

**Basic Example:**

```python
@model(
    "@{customer}.some_table",
    is_sql=True,
    kind="FULL",
    blueprints=[
        {"customer": "customer1", "field_a": "x", "field_b": "y"},
        {"customer": "customer2", "field_a": "z", "field_b": "w"},
    ],
)
def entrypoint(evaluator: MacroEvaluator) -> str | exp.Expression:
    field_a = evaluator.blueprint_var("field_a")
    field_b = evaluator.blueprint_var("field_b")
    customer = evaluator.blueprint_var("customer")
    
    return exp.select(field_a, field_b).from_(f"{customer}.some_source")
```

**Python DataFrame Models:**

```python
@model(
    "@{customer}.metrics",
    kind="FULL",
    blueprints=[
        {"customer": "customer1", "region": "US"},
        {"customer": "customer2", "region": "EU"},
    ],
    columns={"date": "date", "revenue": "decimal(10,2)", "region": "text"},
)
def execute(context, **kwargs):
    customer = context.blueprint_var("customer")
    region = context.blueprint_var("region")
    
    table = context.resolve_table(f"raw.{customer}_transactions")
    df = context.fetchdf(f"SELECT * FROM {table}")
    df['region'] = region
    return df
```

### 7.3 Dynamic Blueprint Generation

**Using Macros:**

```python
# macros/__init__.py
from vulcan import macro

@macro()
def gen_blueprints(evaluator):
    """Generate blueprints from external source."""
    import csv
    
    blueprints = []
    with open('customers.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            blueprints.append({
                "customer": row['customer_id'],
                "region": row['region'],
            })
    
    return str(blueprints).replace("'", "")  # Convert to SQL format
```

**SQL Usage:**

```sql
MODEL (
  name @customer.metrics,
  kind FULL,
  blueprints @gen_blueprints()
);

SELECT * FROM @customer.source;
```

**Using EACH:**

```sql
MODEL (
  name @customer.some_table,
  kind FULL,
  blueprints @EACH(@customer_list, x -> (customer := @x))
);

SELECT * FROM @customer.source;
```

### 7.4 Blueprint Best Practices

**✅ DO:**

- Use blueprints for similar models
- Document blueprint variables
- Test blueprints with sample data
- Use meaningful variable names
- Keep blueprint logic simple

**❌ DON'T:**

- Overuse blueprints (prefer separate models when logic differs significantly)
- Create too many blueprints (hard to maintain)
- Use blueprints for completely different models
- Forget to update all blueprints when changing template

**When to Use:**

- ✅ Multiple customers/tenants with same logic
- ✅ Multiple regions with same structure
- ✅ Multiple environments with same schema
- ✅ Repeated patterns across models

- ❌ Models with significantly different logic
- ❌ One-off models
- ❌ Models that will diverge over time

[↑ Back to Top](#chapter-2c-model-operations)

---

## 8. Summary and Next Steps

### What You've Learned

This chapter covered advanced patterns and operations for building sophisticated models:

1. **Advanced SQL Patterns**: Python-based SQL models, complex CTEs, advanced pre/post statements
2. **Advanced Python Patterns**: Blueprinting, DataFrame APIs, batching, serialization
3. **Signals**: Multiple signals, interval filtering, advanced patterns, testing
4. **Macros**: Advanced operators, complex patterns, debugging, best practices
5. **Dependencies**: Automatic detection, explicit dependencies, circular dependency handling
6. **Blueprinting**: SQL and Python blueprinting, dynamic generation

### Next Steps

- **[Chapter 2D: Model Optimization](02d-model-optimization.md)** - Performance optimization and warehouse-specific tuning
- **[Chapter 2A: Model Properties](02a-model-properties.md)** - Complete reference for all model properties
- **[Chapter 2B: Model Testing](02b-model-testing.md)** - Comprehensive testing guide

### Related Chapters

- **[Chapter 2: Models](02-models.md)** - Foundation concepts
- **[Chapter 4: Audits](04-audits.md)** - Data quality checks
- **[Chapter 5: Quality Checks](05-quality-checks.md)** - Comprehensive validation

---

**Ready to optimize your models?** Continue to [Chapter 2D: Model Optimization](02d-model-optimization.md)

[↑ Back to Top](#chapter-2c-model-operations)
