# Overview

Models are made up of metadata and queries that create tables and views, which can be used by other models or even outside of Vulcan. They are defined in the `models/` directory of your Vulcan project and live in `.sql` files.

Vulcan will automatically determine the relationships among and lineage of your models by parsing SQL, so you don't have to worry about manually configuring dependencies.

A model consists of two core components:

- **DDL (Data Definition Language)**: The `MODEL` block that defines the structure, metadata, and behavior of the model
- **DML (Data Manipulation Language)**: The `SELECT` query that contains the transformation logic

---

## Model Structure

Models can be defined in SQL or Python. Both formats follow the same DDL/DML pattern.

=== "SQL Model"

    ```sql linenums="1"
    MODEL (
      name sales.daily_sales,
      kind FULL,
      cron '@daily',
      grain order_date
    );

    SELECT
      CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
      COUNT(order_id)::INTEGER AS total_orders,
      SUM(total_amount)::FLOAT AS total_revenue,
      MAX(order_id)::VARCHAR AS last_order_id
    FROM raw.raw_orders
    GROUP BY order_date
    ORDER BY order_date
    ```

    | Component | Lines | Purpose |
    | --------- | ----- | ------- |
    | **DDL** (MODEL block) | 1-6 | Defines model name, kind, schedule, and grain |
    | **DML** (SELECT query) | 8-17 | Contains the transformation logic |

=== "Python Model"

    ```python linenums="1"
    import typing as t
    import pandas as pd
    from datetime import datetime
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
      "sales.daily_sales_py",
      columns={
        "order_date": "timestamp",
        "total_orders": "int",
        "total_revenue": "decimal(18,2)",
        "last_order_id": "string",
      },
      kind=dict(name=ModelKindName.FULL),
      grains=["order_date"],
      depends_on=["raw.raw_orders"],
      cron='@daily',
    )
    def execute(
      context: ExecutionContext,
      start: datetime,
      end: datetime,
      execution_time: datetime,
      **kwargs: t.Any,
    ) -> pd.DataFrame:

      query = """
      SELECT
        CAST(order_date AS TIMESTAMP) AS order_date,
        COUNT(order_id)::INTEGER AS total_orders,
        SUM(total_amount)::NUMERIC(18,2) AS total_revenue,
        MAX(order_id)::VARCHAR AS last_order_id
      FROM raw.raw_orders
      GROUP BY order_date
      ORDER BY order_date
      """

      return context.fetchdf(query)
    ```

    | Component | Lines | Purpose |
    | --------- | ----- | ------- |
    | **DDL** (`@model` decorator) | 7-20 | Defines model name, columns, kind, schedule, and dependencies |
    | **DML** (function body) | 21-40 | Contains the transformation logic and returns a DataFrame |

---

## DDL: The MODEL Block

The `MODEL` block is the DDL component that defines the structure and metadata of your model. It is the first non-comment statement in the file and uses a DDL-like syntax to declare model properties.

### DDL Syntax

```sql linenums="1"
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date
);
```

### Common DDL Properties

| Property | Description | Example |
| -------- | ----------- | ------- |
| `name` | Fully qualified model name (schema.table) | `sales.daily_sales` |
| `kind` | Materialization strategy (FULL, INCREMENTAL, VIEW, etc.) | `FULL` |
| `cron` | Scheduling expression | `'@daily'` |
| `grain` | Column(s) that define row uniqueness | `order_date` |
| `owner` | Model owner for governance | `analytics_team` |
| `description` | Human-readable description | `'Daily sales aggregates'` |

!!! info "More DDL Properties"
    For a complete list of all available model properties and their configurations, see the [Model Properties](./properties.md) reference .

## DML: The SELECT Query

The `SELECT` query is the DML component that contains the transformation logic. It defines what data is selected, how it's transformed, and what columns appear in the final output.

### DML Syntax

```sql linenums="1"
SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
GROUP BY order_date
ORDER BY order_date
```

---

## Conventions

Vulcan attempts to infer as much as possible about your pipelines to reduce the cognitive overhead of switching to another format such as YAML. The DML portion of a model must follow certain conventions for Vulcan to detect the necessary metadata.

### SQL Model Conventions

#### Unique Column Names

The final `SELECT` of a model's query must contain unique column names.

```sql linenums="1"
-- ✓ Good: Each column has a unique name
SELECT
  order_date::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue
FROM raw.raw_orders
GROUP BY order_date
```

#### Explicit Types

Vulcan encourages explicit type casting in the final `SELECT` of a model's query. It is considered a best practice to prevent unexpected types in the schema of a model's table.

Vulcan uses the postgres `x::int` syntax for casting; the casts are automatically transpiled to the appropriate format for the execution engine.

```sql linenums="1"
-- Explicit casting ensures consistent schema
SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,  -- explicit timestamp
  COUNT(order_id)::INTEGER AS total_orders,                 -- explicit integer
  SUM(total_amount)::FLOAT AS total_revenue,                -- explicit float
  MAX(order_id)::VARCHAR AS last_order_id                   -- explicit varchar
FROM raw.raw_orders
GROUP BY order_date
```

#### Inferrable Names

The final `SELECT` of a model's query must have inferrable names or aliases.

Explicit aliases are recommended, but not required. The Vulcan formatter will automatically add aliases to columns without them when the model SQL is rendered.

```sql linenums="1"
SELECT
  1,                              -- not inferrable
  total_amount + 1,               -- not inferrable
  SUM(total_amount),              -- not inferrable
  order_date,                     -- inferrable as order_date
  order_date::TIMESTAMP,          -- inferrable as order_date
  total_amount + 1 AS adjusted,   -- explicitly adjusted
  SUM(total_amount) AS revenue    -- explicitly revenue
```

#### Column Descriptions

You can explicitly define column descriptions in the DDL using the `column_descriptions` property. This is the recommended approach for comprehensive documentation.

```sql linenums="1" hl_lines="7-12"
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date,
  description 'Aggregated daily sales metrics',
  column_descriptions (
    order_date = 'The date of the sales transactions',
    total_orders = 'Count of orders placed on this date',
    total_revenue = 'Sum of all order amounts for this date',
    last_order_id = 'The most recent order ID for this date'
  )
);
```

!!! note "Priority"
    If `column_descriptions` is present in the DDL, Vulcan will use these descriptions and **not** detect inline comments from the query.

#### Inline Column Comments

If the `column_descriptions` key is not present in the DDL, Vulcan will automatically detect comments in a query's column selections and register each column's final comment in the underlying SQL engine.

```sql linenums="1" hl_lines="9-12"
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date
);

SELECT
  order_date::TIMESTAMP AS order_date,           -- The date of sales transactions
  COUNT(order_id)::INTEGER AS total_orders,      -- Number of orders placed
  SUM(total_amount)::FLOAT AS total_revenue,     -- Total revenue for the day
  MAX(order_id)::VARCHAR AS last_order_id        -- Most recent order ID
FROM raw.raw_orders
GROUP BY order_date
```

The physical table created would have:

1. Each inline comment registered as a column comment for the respective column
2. If a comment exists before the `MODEL` block, it will be registered as the table comment

### Python Model Conventions

#### Explicit Column Definitions

Python models require explicit column definitions in the `@model` decorator since types cannot be inferred from the code.

```python linenums="1" hl_lines="3-8"
@model(
    "sales.daily_sales_py",
    columns={
        "order_date": "timestamp",
        "total_orders": "int",
        "total_revenue": "decimal(18,2)",
        "last_order_id": "string",
    },
    kind=dict(name=ModelKindName.FULL),
)
```

#### Explicit Dependencies

Unlike SQL models where dependencies are automatically inferred, Python models must explicitly declare their dependencies using the `depends_on` parameter.

```python linenums="1" hl_lines="4"
@model(
    "sales.daily_sales_py",
    columns={...},
    depends_on=["raw.raw_orders"],  # Must explicitly list upstream models
)
```

#### Column Descriptions

Python models cannot use inline comments for column descriptions. Instead, specify them in the `@model` decorator's `column_descriptions` key.

```python linenums="1" hl_lines="8-13"
@model(
    "sales.daily_sales_py",
    columns={
        "order_date": "timestamp",
        "total_orders": "int",
        "total_revenue": "decimal(18,2)",
    },
    column_descriptions={
        "order_date": "The date of sales transactions",
        "total_orders": "Number of orders placed on this date",
        "total_revenue": "Total revenue for the day",
    },
)
```

!!! warning "Column name validation"
    Vulcan will error if a column name in `column_descriptions` is not also present in the `columns` key.

#### Return Type

The `execute` function must return a pandas DataFrame with columns matching the `columns` definition.

```python linenums="1"
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:  # Must return a DataFrame
    query = "SELECT ..."
    return context.fetchdf(query)
```

!!! info "Learn more"
    For detailed information about Python models, see [Python Models](types/python_models.md).

---

## Comment Registration

### Model Comment

Vulcan will register a comment specified before the `MODEL` DDL block as the table comment in the underlying SQL engine. If the DDL `description` field is also specified, Vulcan will register it with the engine instead.

### Comment Registration by Object Type

Only some tables/views have comments registered:

- Temporary tables are not registered
- Non-temporary tables and views in the physical layer (i.e., the schema named `vulcan__[project schema name]`) are registered
- Views in non-prod environments are not registered
- Views in the `prod` environment are registered

Some engines automatically pass comments from physical tables through to views that select from them. In those engines, views may display comments even if Vulcan did not explicitly register them.

### Engine Comment Support

Engines vary in their support for comments and their method(s) of registering comments. Engines may support one or both registration methods: in the `CREATE` command that creates the object or with specific post-creation commands.

In the former method, column comments are embedded in the `CREATE` schema definition - for example: `CREATE TABLE my_table (my_col INTEGER COMMENT 'comment on my_col') COMMENT 'comment on my_table'`. This means that all table and column comments can be registered in a single command.

In the latter method, separate commands are required for every comment. This may result in many commands: one for the table comment and one for each column comment.

| Engine        | `TABLE` comments | `VIEW` comments |
| ------------- | ---------------- | --------------- |
| Athena        | N                | N               |
| BigQuery      | Y                | Y               |
| ClickHouse    | Y                | Y               |
| Databricks    | Y                | Y               |
| DuckDB <=0.9  | N                | N               |
| DuckDB >=0.10 | Y                | Y               |
| MySQL         | Y                | Y               |
| MSSQL         | N                | N               |
| Postgres      | Y                | Y               |
| GCP Postgres  | Y                | Y               |
| Redshift      | Y                | N               |
| Snowflake     | Y                | Y               |
| Spark         | Y                | Y               |
| Trino         | Y                | Y               |

---

## Macros

Macros can be used for passing in parameterized arguments such as dates, as well as for making SQL less repetitive. By default, Vulcan provides several predefined macro variables that can be used. Macros are used by prefixing with the `@` symbol. For more information, refer to [macros](../advanced-features/macros/overview.md).
