# Properties

The `MODEL` DDL statement has a bunch of properties you can use to control how your model behaves. Think of them as knobs and switches—you can configure scheduling, storage, validation, and more.

This page is your complete reference for all available properties. We'll cover what each one does, when to use it, and show you examples.

---

## Quick Reference

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| `name` | Fully qualified model name (`schema.model` or `catalog.schema.model`) | `str` | N* |
| `project` | Project name for multi-repo deployments | `str` | N |
| `kind` | Model kind (VIEW, FULL, INCREMENTAL, etc.) | `str` \| `dict` | N |
| `cron` | Schedule expression for model refresh | `str` | N |
| `cron_tz` | Timezone for the cron schedule | `str` | N |
| `interval_unit` | Temporal granularity of data intervals | `str` | N |
| `start` | Earliest date/time to process | `str` \| `int` | N |
| `end` | Latest date/time to process | `str` \| `int` | N |
| `grain` | Column(s) defining row uniqueness | `str` \| `array` | N |
| `grains` | Multiple unique key definitions | `array` | N |
| `owner` | Model owner for governance | `str` | N |
| `description` | Model description (registered as table comment) | `str` | N |
| `column_descriptions` | Column-level comments | `dict` | N |
| `columns` | Explicit column names and types | `array` | N |
| `dialect` | SQL dialect of the model | `str` | N |
| `tags` | Labels for organizing models | `array[str]` | N |
| `assertions`  | Audits to run after model evaluation | `array` | N |
| `profiles` | Columns to track statistical metrics over time | `array` | N |
| `depends_on` | Explicit model dependencies | `array[str]` | N |
| `references` | Non-unique join relationship columns | `array` | N |
| `partitioned_by` | Partition key column(s) | `str` \| `array` | N |
| `clustered_by` | Clustering column(s) | `str` | N |
| `table_format` | Table format (iceberg, hive, delta) | `str` | N |
| `storage_format` | Storage format (parquet, orc) | `str` | N |
| `physical_properties` | Engine-specific table/view properties | `dict` | N |
| `virtual_properties` | Engine-specific view layer properties | `dict` | N |
| `session_properties` | Engine session properties | `dict` | N |
| `stamp` | Arbitrary version string | `str` | N |
| `enabled` | Whether model is enabled | `bool` | N |
| `allow_partials` | Allow partial data intervals | `bool` | N |
| `gateway` | Specific gateway for execution | `str` | N |
| `optimize_query` | Enable query optimization | `bool` | N |
| `formatting` | Enable model formatting | `bool` | N |
| `ignored_rules` | Linter rules to ignore | `str` \| `array` | N |

*Required unless [name inference](#model-naming) is enabled.

---

## General Properties

### name

Your model's name is how it's identified in the data warehouse. It needs at least a schema (`schema.model`), and you can optionally include a catalog (`catalog.schema.model`).

**Format:** `schema.model` or `catalog.schema.model`

This becomes the production table/view name that other models and users will reference.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,        -- schema.model format
    );
    
    -- Or with catalog
    MODEL (
      name catalog.sales.daily_sales -- catalog.schema.model format
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",  # schema.model format
    )
    def execute(context, **kwargs):
        ...
    
    # Or with catalog
    @model(
        "catalog.sales.daily_sales",  # catalog.schema.model format
    )
    ```

!!! note "Environment Prefixing"

    In non-production environments, Vulcan automatically prefixes your model names. So `sales.daily_sales` becomes `sales__dev.daily_sales` in the dev environment. This keeps your dev and prod data separate without you having to think about it.

### project

If you're running multiple Vulcan projects in the same repository (multi-repo setup), use `project` to specify which project this model belongs to. This helps Vulcan organize and isolate models from different projects.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      project 'analytics_project',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        project="analytics_project",
    )
    ```

### kind

The `kind` property determines how your model is computed and stored. Do you want to rebuild everything each run? Update incrementally? Create a view? This is where you decide.

For all the details on each kind and when to use them, check out the [Model Kinds](model_kinds.md) documentation.

=== "SQL"

    ```sql
    -- VIEW (default for SQL)
    MODEL (
      name sales.daily_sales,
      kind VIEW,
    );
    
    -- FULL
    MODEL (
      name sales.daily_sales,
      kind FULL,
    );
    
    -- Incremental with properties
    MODEL (
      name sales.events,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column event_ts,
      ),
    );
    
    -- SEED
    MODEL (
      name raw.holidays,
      kind SEED (
        path 'seeds/holidays.csv',
      ),
    );
    ```

=== "Python"

    ```python
    from vulcan import ModelKindName
    
    # FULL (default for Python)
    @model(
        "sales.daily_sales",
        kind=dict(name=ModelKindName.FULL),
    )
    
    # Incremental
    @model(
        "sales.events",
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="event_ts",
        ),
    )
    
    # SCD Type 2
    @model(
        "dim.customers",
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_TIME,
            unique_key=["customer_id"],
        ),
    )
    ```

### cron

Controls when your model runs. You can use standard cron expressions or Vulcan's shortcuts for common schedules.

**Why this matters:** Without a schedule, your model only runs when you manually trigger it. Set a cron, and Vulcan will automatically process new data on schedule.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      cron '@daily',          -- Daily at midnight UTC
    );
    
    MODEL (
      name sales.hourly_metrics,
      cron '@hourly',         -- Every hour
    );
    
    MODEL (
      name sales.custom_schedule,
      cron '0 6 * * *',       -- Custom: every day at 6 AM UTC
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        cron="@daily",
    )
    
    @model(
        "sales.hourly_metrics",
        cron="@hourly",
    )
    
    @model(
        "sales.custom_schedule",
        cron="0 6 * * *",  # Every day at 6 AM UTC
    )
    ```

**Cron shortcuts:** Vulcan provides convenient shortcuts:
- `@hourly` - Every hour
- `@daily` - Every day at midnight UTC
- `@weekly` - Once per week
- `@monthly` - Once per month

These are much easier than writing `0 * * * *`!

### cron_tz

Sets the timezone for your cron schedule. This only affects **when** the model runs, not how time intervals are calculated (those are always UTC).

**Example:** If you set `cron '@daily'` and `cron_tz 'America/Los_Angeles'`, your model runs at midnight Pacific time, but the time intervals it processes are still in UTC.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      cron '@daily',
      cron_tz 'America/Los_Angeles',  -- Runs at midnight Pacific time
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        cron="@daily",
        cron_tz="America/Los_Angeles",
    )
    ```

### interval_unit

Controls the granularity of time intervals for incremental models. By default, Vulcan figures this out from your `cron` expression, but you can override it if needed.

**Supported values:** `year`, `month`, `day`, `hour`, `half_hour`, `quarter_hour`, `five_minute`

**When to override:** If your cron runs daily but you want to process hourly intervals, set `interval_unit 'hour'`. This is useful when you want finer-grained control over incremental processing.

=== "SQL"

    ```sql
    MODEL (
      name sales.hourly_metrics,
      cron '30 7 * * *',      -- Run daily at 7:30 AM
      interval_unit 'hour',   -- Process hourly intervals (not daily)
      );
    ```

=== "Python"

    ```python
    from vulcan import IntervalUnit
    
    @model(
        "sales.hourly_metrics",
        cron="30 7 * * *",
        interval_unit=IntervalUnit.HOUR,
    )
    ```

### start

Sets the earliest date/time your model should process. This is useful for limiting backfills or defining when your model's data begins.

You can use:
- **Absolute dates:** `'2024-01-01'`
- **Relative expressions:** `'1 year ago'`
- **Epoch milliseconds:** `1704067200000`

=== "SQL"

    ```sql
    -- Absolute date
    MODEL (
      name sales.daily_sales,
      start '2024-01-01',
    );
    
    -- Relative expression
    MODEL (
      name sales.recent_sales,
      start '1 year ago',
    );
    
    -- Epoch milliseconds
    MODEL (
      name sales.events,
      start 1704067200000,
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        start="2024-01-01",
    )
    
    @model(
        "sales.recent_sales",
        start="1 year ago",
    )
    ```

### end

Sets the latest date/time your model should process. Uses the same format as `start`. This is handy for historical models or limiting processing to a specific time range.

=== "SQL"

    ```sql
    MODEL (
      name sales.historical_sales,
      start '2020-01-01',
      end '2023-12-31',
      );
    ```

=== "Python"

    ```python
    @model(
        "sales.historical_sales",
        start="2020-01-01",
        end="2023-12-31",
    )
    ```

### grain / grains

Defines the column(s) that make each row unique. This is like a primary key—it tells Vulcan what identifies a single row in your table.

**Why this matters:** Tools like `table_diff` use grains to compare tables. It also helps Vulcan understand your data structure for better optimization and validation.

You can specify a single grain (`grain order_id`) or multiple grains (`grains (order_id, (customer_id, order_date))`).

=== "SQL"

    ```sql
    -- Single column grain
    MODEL (
      name sales.daily_sales,
      grain order_date,
    );
    
    -- Composite grain
    MODEL (
      name sales.customer_daily,
      grain (customer_id, order_date),
    );
    
    -- Multiple grains
    MODEL (
      name sales.orders,
      grains (
        order_id,
        (customer_id, order_date)
      ),
    );
    ```

=== "Python"

    ```python
    # Single grain
    @model(
        "sales.daily_sales",
        grains=["order_date"],
    )
    
    # Composite grain
    @model(
        "sales.customer_daily",
        grains=[("customer_id", "order_date")],
    )
    
    # Multiple grains
    @model(
        "sales.orders",
        grains=[
            "order_id",
            ("customer_id", "order_date"),
        ],
    )
    ```

### owner

Sets the owner of the model—usually a team name or individual. This is used for governance, notifications, and knowing who to contact when something breaks.

**Example:** `owner 'analytics_team'` or `owner 'data_engineers'`

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      owner 'analytics_team',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        owner="analytics_team",
    )
    ```

### description

A human-readable description of what your model does. Vulcan automatically registers this as a table comment in your SQL engine (if it supports comments), so it shows up in your BI tools and data catalogs.

**Pro tip:** Write descriptions that explain the business purpose, not just the technical details. Future you (and your teammates) will thank you!

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      description 'Aggregated daily sales metrics including total orders and revenue',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        description="Aggregated daily sales metrics including total orders and revenue",
    )
    ```

### column_descriptions

Document your columns! This property lets you add descriptions for each column, which get registered as column comments in your database.

**Why document columns?** When someone queries your table in a BI tool, they'll see what each column means. It's like inline documentation that travels with your data.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      column_descriptions (
        order_date = 'The date of sales transactions',
        total_orders = 'Count of orders placed on this date',
        total_revenue = 'Sum of all order amounts',
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        columns={
            "order_date": "timestamp",
            "total_orders": "int",
            "total_revenue": "decimal(18,2)",
        },
        column_descriptions={
            "order_date": "The date of sales transactions",
            "total_orders": "Count of orders placed on this date",
            "total_revenue": "Sum of all order amounts",
        },
    )
    ```

!!! warning "Priority"
    If `column_descriptions` is present, [inline column comments](./overview.md#inline-column-comments) will not be registered.

### columns

Explicitly defines your model's column names and data types. When you use this, Vulcan won't try to infer types from your query—it'll use exactly what you specify.

**When to use:**
- Python models (required—Vulcan can't infer types from Python code)
- Seed models (you need to define the CSV schema)
- When you want strict type control

=== "SQL"

    ```sql
    MODEL (
      name sales.national_holidays,
      kind SEED (path 'holidays.csv'),
      columns (
        holiday_name VARCHAR,
        holiday_date DATE
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        columns={
            "order_date": "timestamp",
            "total_orders": "int",
            "total_revenue": "decimal(18,2)",
            "last_order_id": "string",
        },
    )
    def execute(context, **kwargs) -> pd.DataFrame:
        ...
    ```

!!! note "Python Models"

    This is required for [Python models](./python_models.md) since Vulcan can't infer column types from Python code. You must explicitly define your schema.

### dialect

Specifies the SQL dialect your model uses. Defaults to whatever you set in `model_defaults`, but you can override it per-model if needed.

**Why this matters:** Vulcan uses SQLGlot to parse and transpile SQL. You can write in one dialect (like PostgreSQL) and Vulcan will convert it to whatever your engine needs (like BigQuery). Pretty neat!

Supports all [SQLGlot dialects](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/__init__.py).

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      dialect 'snowflake',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        dialect="snowflake",
    )
    ```

### tags

Labels for organizing and filtering models.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      tags ['sales', 'daily', 'core'],
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        tags=["sales", "daily", "core"],
    )
    ```

### assertions

Attach [audits](../audits.md) directly to your model. These validations run after each model evaluation and will block the pipeline if they fail.

**Why use assertions?** They're your safety net—they catch bad data before it flows downstream. If revenue can't be negative, assert it. If customer IDs must be unique, assert it. Fail fast, fix fast.

Think of assertions as "this data must be true" validations that run automatically.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      assertions (
        not_null(columns := (order_date, customer_id)),
        unique_values(columns := (order_id)),
        accepted_range(column := price, min_v := 0, max_v := 1000),
        forall(criteria := (price > 0, quantity >= 1))
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        assertions=[
            ("not_null", {"columns": ["order_date", "customer_id"]}),
            ("unique_values", {"columns": ["order_id"]}),
            ("accepted_range", {"column": "price", "min_v": 0, "max_v": 1000}),
        ],
    )
    ```

### profiles

Enable automatic data profiling for specific columns. Profiles track statistical metrics over time (like null percentages, distinct counts, distributions) without blocking your pipeline.

**How it works:** Vulcan collects metrics each run and stores them in the `_check_profiles` table. You can query this to see how your data changes over time—detect data drift, understand patterns, and decide which checks or audits to add.

**Use cases:**
- Track null percentages over time
- Monitor distinct value counts
- Detect data drift
- Understand column distributions
- Inform which checks/audits to create

Think of profiles as your data observability layer—they watch and learn, but don't block.
=== "SQL"

    ```sql
    MODEL (
      name vulcan_demo.full_model,
      kind FULL,
      grains (customer_id),
      profiles (customer_id, customer_name, email, total_orders, total_spent, avg_order_value)
    );

    SELECT
      c.customer_id,
      c.name AS customer_name,
      c.email,
      COUNT(DISTINCT o.order_id) AS total_orders,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS avg_order_value
    FROM vulcan_demo.customers AS c
    LEFT JOIN vulcan_demo.orders AS o ON c.customer_id = o.customer_id
    LEFT JOIN vulcan_demo.order_items AS oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.name, c.email
    ```

=== "Python"

    ```python
    @model(
        "vulcan_demo.full_model_py",
        columns={
            "customer_id": "int",
            "customer_name": "string",
            "email": "string",
            "total_orders": "int",
            "total_spent": "decimal(10,2)",
            "avg_order_value": "decimal(10,2)",
        },
        kind="full",
        grains=["customer_id"],
        profiles=["customer_id", "customer_name", "email", "total_orders", "total_spent", "avg_order_value"],
    )
    def execute(context, **kwargs):
        ...
    ```


### depends_on

Explicitly declare model dependencies. Vulcan automatically infers dependencies from SQL queries, but sometimes you need to add extra ones.

**When to use:**
- Python models (required—Vulcan can't parse Python to find dependencies)
- Hidden dependencies (like a macro that references another model)
- External dependencies that aren't in your SQL

**Note:** Dependencies you declare here are added to the ones Vulcan infers—they don't replace them.

=== "SQL"

    ```sql
    MODEL (
      name sales.summary,
      depends_on ['sales.daily_sales', 'sales.products'],
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.summary",
        depends_on=["sales.daily_sales", "sales.products"],
    )
    ```

!!! note "Python Models"

    Python models **require** `depends_on` since Vulcan can't automatically infer dependencies from Python code. You need to tell it explicitly what your model depends on.

### references

Declare non-unique join relationships to other models. These help Vulcan understand how models relate to each other for better lineage and optimization.

**Example:** If your `orders` table has a `customer_id` that joins to `customers.customer_id`, you'd add `customer_id` to references. This tells Vulcan about the relationship even though `customer_id` isn't unique in the orders table.

=== "SQL"

    ```sql
    MODEL (
      name sales.orders,
      references (
        customer_id,
        guest_id AS account_id,  -- Alias for joining to account_id grain
      ),
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.orders",
        references=[
            "customer_id",
            ("guest_id", "account_id"),  # Alias
        ],
    )
    ```

---

## Storage Properties

These properties control how your data is physically stored in the database. They're engine-specific, so check your engine's documentation for what's supported.

### partitioned_by

Defines the partition key for your table. Partitioning splits your table into chunks based on column values, which makes queries faster (the engine can skip irrelevant partitions).

**Supported engines:** Spark, BigQuery, Databricks, and others that support table partitioning.

**Why partition?** If you're querying data from the last 7 days and your table is partitioned by date, the engine only scans 7 partitions instead of scanning the entire table. That's a huge performance win!

=== "SQL"

    ```sql
    -- Single column partition
    MODEL (
      name sales.events,
      partitioned_by event_date,
    );
    
    -- Partition with transformation (BigQuery)
    MODEL (
      name sales.events,
      partitioned_by TIMESTAMP_TRUNC(event_ts, DAY),
    );
    
    -- Multi-column partition
    MODEL (
      name sales.events,
      partitioned_by (year, month, day),
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        partitioned_by=["event_date"],
    )
    
    # Multi-column
    @model(
        "sales.events",
        partitioned_by=["year", "month", "day"],
    )
    ```

### clustered_by

Sets clustering columns for engines that support it (like BigQuery). Clustering organizes data within partitions based on column values, which makes range queries and filters faster.

**How it works:** Data is physically stored sorted by the clustering columns. When you filter on those columns, the engine can skip reading irrelevant data blocks.

**Example:** If you cluster by `customer_id`, queries filtering by customer will be faster because related data is stored together.

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      partitioned_by event_date,
      clustered_by (customer_id, product_id),
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        partitioned_by=["event_date"],
        clustered_by=["customer_id", "product_id"],
    )
    ```

### table_format

Specifies the table format for engines that support multiple formats. Different formats have different features and performance characteristics.

**Supported formats:** `iceberg`, `hive`, `delta`

**When to use:** If your engine supports multiple formats, choose based on your needs:
- **Iceberg:** Great for time travel and schema evolution
- **Delta:** Good for ACID transactions and time travel
- **Hive:** Traditional format, widely supported

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      table_format 'iceberg',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        table_format="iceberg",
    )
    ```

### storage_format

Sets the physical file format for your table's data files. This affects compression, query performance, and storage costs.

**Common formats:** `parquet`, `orc`

**Parquet** is usually the best choice—it's columnar (great for analytics), has good compression, and is widely supported. **ORC** is another option, especially if you're using Hive.

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      storage_format 'parquet',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        storage_format="parquet",
    )
    ```

---

## Engine Properties

These properties let you pass engine-specific settings to Vulcan. Each engine has different capabilities, so these properties vary by engine.

### physical_properties

Pass engine-specific properties directly to the physical table/view creation. This is where you set things like retention policies, labels, or other engine-specific features.

**Use cases:**
- Set table retention (BigQuery: `partition_expiration_days`)
- Add labels or tags (BigQuery, Snowflake)
- Configure table type (Snowflake: `TRANSIENT` tables)
- Any other engine-specific table settings

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      physical_properties (
        partition_expiration_days = 7,
        require_partition_filter = true,
        creatable_type = TRANSIENT,  -- Creates TRANSIENT TABLE
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        physical_properties={
            "partition_expiration_days": 7,
            "require_partition_filter": True,
            "creatable_type": "TRANSIENT",
        },
    )
    ```

### virtual_properties

Pass engine-specific properties to the virtual layer view. This is useful for things like view-level security, labels, or other view-specific settings.

**Use cases:**
- Create secure views (Snowflake: `SECURE` views)
- Add labels to views
- Set view-level permissions
- Configure view-specific engine features

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      virtual_properties (
        creatable_type = SECURE,  -- Creates SECURE VIEW
        labels = [('team', 'analytics')]
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        virtual_properties={
            "creatable_type": "SECURE",
            "labels": [("team", "analytics")],
        },
    )
    ```

### session_properties

Set session-level properties that apply when Vulcan executes your model. These affect how queries run but don't change the table structure.

**Use cases:**
- Set query timeouts
- Configure parallelism
- Adjust memory limits
- Set engine-specific session variables

**Example:** If you have a large query that needs more time, set `query_timeout: 3600` to give it an hour instead of the default timeout.

=== "SQL"

    ```sql
    MODEL (
      name sales.large_query,
      session_properties (
        query_timeout = 3600,
        max_parallel_workers = 8,
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.large_query",
        session_properties={
            "query_timeout": 3600,
            "max_parallel_workers": 8,
        },
    )
    ```

### gateway

Specifies which gateway to use for executing this model. Useful when you have multiple database connections and want to route specific models to specific databases.

**When to use:** Multi-warehouse setups, isolated environments, or when you need to run certain models on a different database than the default.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      gateway 'warehouse_gateway',
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        gateway="warehouse_gateway",
    )
    ```

---

## Behavior Properties

These properties control how Vulcan behaves when processing your model.

### stamp

Force a new model version without changing the definition. This is like a version tag—useful for tracking deployments or forcing a refresh.

**When to use:** When you want to create a new version for tracking purposes, or when you need to force downstream models to rebuild even though this model's definition hasn't changed.

=== "SQL"

    ```sql
    MODEL (
      name sales.daily_sales,
      stamp 'v2.1.0',  -- Force new version
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.daily_sales",
        stamp="v2.1.0",
    )
    ```

### enabled

Control whether the model is active. Set to `false` to disable a model without deleting it.

**When to use:**
- Temporarily disable a model while debugging
- Deprecate a model but keep it for reference
- Skip models during development

**Default:** `true` (models are enabled by default)

=== "SQL"

    ```sql
    MODEL (
      name sales.deprecated_model,
      enabled false,  -- Model will be ignored
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.deprecated_model",
        enabled=False,
    )
    ```

### allow_partials

Allow processing of incomplete data intervals. By default, Vulcan waits for complete intervals before processing (keeps data quality high). Set this to `true` if you need to process partial intervals.

**When to use:**
- Real-time or near-real-time pipelines
- When you need data ASAP, even if it's incomplete
- Streaming data scenarios

**Trade-off:** You lose the ability to distinguish between "missing data" (pipeline issue) and "partial interval" (expected). Use with caution!

**Default:** `false` (wait for complete intervals)

### optimize_query

Enable or disable query optimization. Vulcan optimizes queries by default (rewrites them for better performance), but sometimes you want to disable this.

**When to disable:**
- The optimizer is breaking your query
- You have engine-specific optimizations you want to preserve
- Debugging query issues

**Default:** `true` (optimize queries)

=== "SQL"

    ```sql
    MODEL (
      name sales.complex_query,
      optimize_query false,  -- Disable optimization
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.complex_query",
        optimize_query=False,
    )
    ```

### formatting

Control whether Vulcan formats this model when you run `vulcan format`. Set to `false` if you want to preserve custom formatting.

**When to disable:**
- Legacy models with specific formatting requirements
- Models where formatting breaks something
- When you prefer manual formatting control

**Default:** `true` (format models automatically)

=== "SQL"

    ```sql
    MODEL (
      name sales.legacy_model,
      formatting false,  -- Skip formatting
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.legacy_model",
        formatting=False,
    )
    ```

### ignored_rules

Tell Vulcan's linter to ignore specific rules for this model. Useful when you have a legitimate reason to break a rule, or when a rule doesn't apply to your use case.

You can ignore specific rules (`['rule_name', 'another_rule']`) or all rules (`'ALL'`).

**Use sparingly:** If you're ignoring lots of rules, maybe the rules need updating, or maybe the model needs refactoring.

=== "SQL"

    ```sql
    -- Ignore specific rules
    MODEL (
      name sales.legacy_model,
      ignored_rules ['rule_name', 'another_rule'],
    );
    
    -- Ignore all rules
    MODEL (
      name sales.legacy_model,
      ignored_rules 'ALL',
    );
    ```

=== "Python"

    ```python
    # Ignore specific rules
    @model(
        "sales.legacy_model",
        ignored_rules=["rule_name", "another_rule"],
    )
    
    # Ignore all rules
    @model(
        "sales.legacy_model",
        ignored_rules="ALL",
    )
    ```

---

## Incremental Model Properties

These properties are specified inside the `kind` definition for incremental models. They control how incremental models behave—things like handling schema changes, restatements, and batch processing.

For the full picture on incremental models, check out the [Model Kinds](model_kinds.md) documentation.

### Common Incremental Properties

These properties work with all incremental model kinds. They're your toolkit for controlling incremental behavior:

| Property | Description | Type | Default |
|----------|-------------|:----:|:-------:|
| `forward_only` | All changes should be [forward-only](../plans.md#forward-only-plans) | `bool` | `false` |
| `on_destructive_change` | Behavior for destructive schema changes | `str` | `error` |
| `on_additive_change` | Behavior for additive schema changes | `str` | `allow` |
| `disable_restatement` | Disable [data restatement](../plans.md#restatement-plans) | `bool` | `false` |
| `auto_restatement_cron` | Cron expression for automatic restatement | `str` | - |

**Values for `on_destructive_change` / `on_additive_change`:**
- `allow` - Let the change happen (default for additive)
- `warn` - Allow but warn about it
- `error` - Block the change (default for destructive)
- `ignore` - Pretend it didn't happen

**Why this matters:** Schema changes can break downstream models. These settings let you control how strict Vulcan should be when your schema evolves.

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column event_ts,
        forward_only true,
        on_destructive_change 'warn',
        on_additive_change 'allow',
        disable_restatement false,
      )
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="event_ts",
            forward_only=True,
            on_destructive_change="warn",
            on_additive_change="allow",
            disable_restatement=False,
        ),
    )
    ```

---

### INCREMENTAL_BY_TIME_RANGE

Properties for models that update incrementally based on a time column. These control how time-based incremental processing works.

For the full guide on `INCREMENTAL_BY_TIME_RANGE` models, see the [Model Kinds documentation](model_kinds.md#incremental_by_time_range).

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| **`time_column`** | Column containing each row's timestamp (should be UTC) | `str` | **Y** |
| `format` | Format of the time column's data | `str` | N |
| `batch_size` | Maximum intervals per backfill task | `int` | N |
| `batch_concurrency` | Maximum concurrent batches | `int` | N |
| `lookback` | Prior intervals to include for late-arriving data | `int` | N |
| `auto_restatement_intervals` | Number of last intervals to auto-restate | `int` | N |

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column event_ts,
        time_column (event_ts, '%Y-%m-%d'),  -- With format
        batch_size 12,
        batch_concurrency 4,
        lookback 7,
        auto_restatement_cron '@weekly',
        auto_restatement_intervals 7,
      )
    );
    
    SELECT
      event_ts::TIMESTAMP AS event_ts,
      event_type::VARCHAR AS event_type,
      user_id::INTEGER AS user_id
    FROM raw.events
    WHERE event_ts BETWEEN @start_ts AND @end_ts;
    ```

=== "Python"

    ```python
    from vulcan import ModelKindName
    
    @model(
        "sales.events",
        columns={
            "event_ts": "timestamp",
            "event_type": "varchar",
            "user_id": "int",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="event_ts",
            batch_size=12,
            batch_concurrency=4,
            lookback=7,
        ),
        depends_on=["raw.events"],
    )
    def execute(context, start, end, **kwargs) -> pd.DataFrame:
        query = f"""
        SELECT event_ts, event_type, user_id
        FROM raw.events
        WHERE event_ts BETWEEN '{start}' AND '{end}'
        """
        return context.fetchdf(query)
    ```

!!! info "Important: UTC Timezone"

    Your `time_column` should be in UTC timezone. This ensures Vulcan's scheduler and time macros work correctly.

---

### INCREMENTAL_BY_UNIQUE_KEY

Properties for models that update based on unique keys (upsert operations). These control MERGE behavior and key handling.

For details on `INCREMENTAL_BY_UNIQUE_KEY` models, see the [Model Kinds documentation](model_kinds.md#incremental_by_unique_key).

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| **`unique_key`** | Column(s) containing each row's unique key | `str` \| `array` | **Y** |
| `when_matched` | SQL logic to update columns on match (MERGE engines only) | `str` | N |
| `merge_filter` | Predicates for ON clause of MERGE operation | `str` | N |
| `batch_size` | Maximum intervals per backfill task | `int` | N |
| `lookback` | Prior intervals to include for late-arriving data | `int` | N |

=== "SQL"

    ```sql
    -- Single unique key
    MODEL (
      name sales.customers,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key customer_id,
      )
    );
    
    -- Composite unique key
    MODEL (
      name sales.order_items,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key (order_id, item_id),
      )
    );
    
    -- With MERGE options
    MODEL (
      name sales.customers,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key customer_id,
        when_matched WHEN MATCHED THEN UPDATE SET 
          name = source.name,
          updated_at = source.updated_at,
        auto_restatement_cron '@weekly',
      )
    );
    ```

=== "Python"

    ```python
    # Single unique key
    @model(
        "sales.customers",
        columns={
            "customer_id": "int",
            "name": "varchar",
            "email": "varchar",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_UNIQUE_KEY,
            unique_key="customer_id",
        ),
        depends_on=["raw.customers"],
    )
    
    # Composite unique key
    @model(
        "sales.order_items",
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_UNIQUE_KEY,
            unique_key=["order_id", "item_id"],
        ),
    )
    ```

!!! note "Batch Concurrency"

    `batch_concurrency` isn't supported for this kind because MERGE operations can't safely run in parallel. Vulcan processes these models sequentially to avoid conflicts.

---

### INCREMENTAL_BY_PARTITION

Properties for models that update by partition. This kind uses the `partitioned_by` property (from the General Properties section) as its partition key.

**Note:** There are no additional kind-specific properties—just use `partitioned_by` to define your partition columns.

For details on `INCREMENTAL_BY_PARTITION` models, see the [Model Kinds documentation](model_kinds.md#incremental_by_partition).

=== "SQL"

    ```sql
    MODEL (
      name sales.events,
      kind INCREMENTAL_BY_PARTITION,
      partitioned_by event_date,
    );
    
    SELECT
      event_date::DATE AS event_date,
      event_type::VARCHAR AS event_type,
      COUNT(*)::INTEGER AS event_count
    FROM raw.events
    GROUP BY event_date, event_type;
    ```

=== "Python"

    ```python
    @model(
        "sales.events",
        columns={
            "event_date": "date",
            "event_type": "varchar",
            "event_count": "int",
        },
        kind=dict(name=ModelKindName.INCREMENTAL_BY_PARTITION),
        partitioned_by=["event_date"],
        depends_on=["raw.events"],
    )
    ```

---

### SCD_TYPE_2

Properties for Slowly Changing Dimension Type 2 models, which track historical changes to your data.

For the complete guide on SCD Type 2 models, see the [Model Kinds documentation](model_kinds.md#scd-type-2).

#### Common SCD Type 2 Properties

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| **`unique_key`** | Column(s) containing each row's unique key | `array` | **Y** |
| `valid_from_name` | Column for valid from date | `str` | N (default: `valid_from`) |
| `valid_to_name` | Column for valid to date | `str` | N (default: `valid_to`) |
| `invalidate_hard_deletes` | Mark missing records as invalid | `bool` | N (default: `true`) |

#### SCD_TYPE_2_BY_TIME

Properties for SCD Type 2 models that detect changes using an `updated_at` timestamp column. This is the recommended approach when your source table has update timestamps.

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| `updated_at_name` | Column containing updated at date | `str` | N (default: `updated_at`) |
| `updated_at_as_valid_from` | Use `updated_at` value as `valid_from` for new rows | `bool` | N (default: `false`) |

=== "SQL"

    ```sql
    MODEL (
      name dim.customers,
      kind SCD_TYPE_2_BY_TIME (
        unique_key customer_id,
        updated_at_name last_modified,
        valid_from_name effective_from,
        valid_to_name effective_to,
        invalidate_hard_deletes true,
        updated_at_as_valid_from true,
      )
    );
    
    SELECT
      customer_id::INTEGER AS customer_id,
      name::VARCHAR AS name,
      email::VARCHAR AS email,
      last_modified::TIMESTAMP AS last_modified
    FROM raw.customers;
    ```

=== "Python"

    ```python
    @model(
        "dim.customers",
        columns={
            "customer_id": "int",
            "name": "varchar",
            "email": "varchar",
            "last_modified": "timestamp",
        },
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_TIME,
            unique_key=["customer_id"],
            updated_at_name="last_modified",
            valid_from_name="effective_from",
            valid_to_name="effective_to",
            invalidate_hard_deletes=True,
        ),
        depends_on=["raw.customers"],
    )
    ```

#### SCD_TYPE_2_BY_COLUMN

Properties for SCD Type 2 models that detect changes by comparing column values. Use this when your source table doesn't have an `updated_at` column.

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| **`columns`** | Columns to check for changes (`*` for all) | `str` \| `array` | **Y** |
| `execution_time_as_valid_from` | Use execution time as `valid_from` for new rows | `bool` | N (default: `false`) |

=== "SQL"

    ```sql
    -- Track specific columns
    MODEL (
      name dim.products,
      kind SCD_TYPE_2_BY_COLUMN (
        unique_key product_id,
        columns (name, price, category),
        execution_time_as_valid_from true,
      )
    );
    
    -- Track all columns
    MODEL (
      name dim.products,
      kind SCD_TYPE_2_BY_COLUMN (
        unique_key product_id,
        columns '*',
      )
    );
    ```

=== "Python"

    ```python
    # Track specific columns
    @model(
        "dim.products",
        columns={
            "product_id": "int",
            "name": "varchar",
            "price": "decimal(10,2)",
            "category": "varchar",
        },
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_COLUMN,
            unique_key=["product_id"],
            columns=["name", "price", "category"],
            execution_time_as_valid_from=True,
        ),
        depends_on=["raw.products"],
    )
    
    # Track all columns
    @model(
        "dim.products",
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_COLUMN,
            unique_key=["product_id"],
            columns="*",
        ),
    )
    ```

---
<!-- 
## Model Defaults

Configure default values for all models in your project's `config.yaml`:

=== "YAML"

    ```yaml linenums="1"
    model_defaults:
      dialect: snowflake
      start: 2024-01-01
      cron: '@daily'
      owner: data_team
      physical_properties:
        partition_expiration_days: 7
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, ModelDefaultsConfig

    config = Config(
      model_defaults=ModelDefaultsConfig(
        dialect="snowflake",
        start="2024-01-01",
        cron="@daily",
        owner="data_team",
        physical_properties={
          "partition_expiration_days": 7,
        },
      ),
    )
    ```

**Supported default properties:**

- `kind`, `dialect`, `cron`, `owner`, `start`
- `table_format`, `storage_format`
- `physical_properties`, `virtual_properties`, `session_properties`
- `on_destructive_change`, `on_additive_change`
- `assertions`, `optimize_query`, `allow_partials`, `enabled`, `interval_unit`
- `pre_statements`, `post_statements`, `on_virtual_update`

### Overriding Defaults

Model-specific properties override defaults. To unset a default, use `None`:

```sql
MODEL (
  name sales.daily_sales,
  physical_properties (
    partition_expiration_days = 14,      -- Override
    project_level_property = None,       -- Unset
  )
);
```

--- -->

## Model Naming

By default, you need to specify the `name` property in every model. But if you organize your models in a directory structure that matches your schema names, you can enable automatic name inference.

**How it works:** With `infer_names: true`, a model at `models/sales/daily_sales.sql` automatically gets the name `sales.daily_sales`. The directory structure becomes your schema, and the filename becomes your model name.

Enable it in your config:

```yaml
model_defaults:
  dialect: snowflake
  
# Enable name inference
infer_names: true
```

**When to use:** If your project structure matches your schema structure, this saves you from typing `name` in every model. Pretty convenient!

Learn more in the [configuration guide](../../guides/configuration.md#model-naming).
