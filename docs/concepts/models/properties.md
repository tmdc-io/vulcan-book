# Properties

The `MODEL` DDL statement accepts various properties that control model metadata and behavior. This page provides a complete reference for all available model properties.

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

The model name, representing the production view/table name. Must include at least a qualifying schema (`schema.model`) and may include a catalog (`catalog.schema.model`).

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
    In non-production environments, Vulcan automatically prefixes names. For example, `sales.daily_sales` becomes `sales__dev.daily_sales` in dev.

### project

Specifies the project name for multi-repo Vulcan deployments.

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

Determines how the model is computed and stored. See [Model Kinds](model_kinds.md) for details.

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

Schedules when the model processes or refreshes data. Accepts [cron expressions](https://en.wikipedia.org/wiki/Cron) or shortcuts.

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

**Cron shortcuts:** `@hourly`, `@daily`, `@weekly`, `@monthly`

### cron_tz

Specifies the timezone for the cron schedule. Only affects scheduling, not the interval boundaries passed to incremental models.

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

Determines the temporal granularity for calculating time intervals. By default, inferred from the `cron` expression.

**Supported values:** `year`, `month`, `day`, `hour`, `half_hour`, `quarter_hour`, `five_minute`

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

The earliest date/time for processing. Accepts absolute dates, epoch milliseconds, or relative expressions.

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

The latest date/time for processing. Same format as `start`.

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

Defines the column(s) that uniquely identify each row. Used by tools like `table_diff`.

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

Specifies the main point of contact for governance and notifications.

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

Model description automatically registered as a table comment in the SQL engine (if supported).

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

Explicit column descriptions registered as column comments.

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

Explicitly specifies column names and data types, disabling automatic inference.

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
    Required for [Python models](./python_models.md) that return DataFrames.

### dialect

The SQL dialect of the model. Defaults to the project's `model_defaults` dialect. Supports all [SQLGlot dialects](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/__init__.py).

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

Attaching [audits](../audits.md) to the model, declaring that these validations should pass after each model evaluation.

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

Specifies columns for which statistical metrics should be tracked over time. Profiles provide observational data about your columns—tracking distributions, null percentages, and patterns—without blocking pipeline execution.
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

Profile results are stored in the `_check_profiles` table and can be used to:

- Detect data drift over time
- Understand column distributions
- Inform which audits or checks to add
- Build data quality dashboards

### depends_on

Explicitly declares dependencies in addition to those inferred from the query.

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
    Python models **require** `depends_on` since dependencies cannot be automatically inferred from the code.

### references

Non-unique columns that define join relationships to other models.

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

### partitioned_by

Defines partition key for engines supporting table partitioning (Spark, BigQuery, etc.).

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

Clustering column(s) for engines supporting clustering (BigQuery, etc.).

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

Table format for engines supporting multiple formats: `iceberg`, `hive`, `delta`.

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

Physical file format: `parquet`, `orc`, etc.

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

### physical_properties

Engine-specific properties applied to the physical table/view.

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

Engine-specific properties applied to the virtual layer view.

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

Engine-specific session properties applied during execution.

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

Specifies a specific gateway for model execution (when not using the default).

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

### stamp

Arbitrary string to create a new model version without changing the definition.

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

Whether the model is active. Set to `false` to ignore during project loading. (Default: `true`)

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

Allows processing of incomplete data intervals. (Default: `false`)

=== "SQL"

    ```sql
    MODEL (
      name sales.realtime_events,
      cron '@hourly',
      allow_partials true,  -- Process incomplete intervals
    );
    ```

=== "Python"

    ```python
    @model(
        "sales.realtime_events",
        cron="@hourly",
        allow_partials=True,
    )
    ```

!!! warning "Use with caution"
    When enabled, you cannot distinguish between missing data due to pipeline issues vs. partial backfills.

### optimize_query

Whether to optimize the model's query. (Default: `true`)

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

Whether the model is formatted during `vulcan format`. (Default: `true`)

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

Linter rules to ignore for this model.

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

Properties specified within the `kind` definition for incremental models. See [Model Kinds](model_kinds.md) for detailed documentation.

### Common Incremental Properties

These properties apply to all incremental model kinds.

| Property | Description | Type | Default |
|----------|-------------|:----:|:-------:|
| `forward_only` | All changes should be [forward-only](../plans.md#forward-only-plans) | `bool` | `false` |
| `on_destructive_change` | Behavior for destructive schema changes | `str` | `error` |
| `on_additive_change` | Behavior for additive schema changes | `str` | `allow` |
| `disable_restatement` | Disable [data restatement](../plans.md#restatement-plans) | `bool` | `false` |
| `auto_restatement_cron` | Cron expression for automatic restatement | `str` | - |

**Values for `on_destructive_change` / `on_additive_change`:** `allow`, `warn`, `error`, `ignore`

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

Incrementally updates data based on a time column. See [INCREMENTAL_BY_TIME_RANGE](model_kinds.md#incremental_by_time_range).

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

!!! info "Important"
    The `time_column` should be in UTC timezone.

---

### INCREMENTAL_BY_UNIQUE_KEY

Incrementally updates data based on a unique key using MERGE operations. See [INCREMENTAL_BY_UNIQUE_KEY](model_kinds.md#incremental_by_unique_key).

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
    `batch_concurrency` cannot be set for this kind because these models cannot safely run in parallel.

---

### INCREMENTAL_BY_PARTITION

Incrementally updates data based on partition key. See [INCREMENTAL_BY_PARTITION](model_kinds.md#incremental_by_partition).

This kind uses the `partitioned_by` general property as its partition key and does not have additional kind-specific properties.

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

Slowly Changing Dimension Type 2 models track historical changes. See [SCD_TYPE_2](model_kinds.md#scd-type-2).

#### Common SCD Type 2 Properties

| Property | Description | Type | Required |
|----------|-------------|:----:|:--------:|
| **`unique_key`** | Column(s) containing each row's unique key | `array` | **Y** |
| `valid_from_name` | Column for valid from date | `str` | N (default: `valid_from`) |
| `valid_to_name` | Column for valid to date | `str` | N (default: `valid_to`) |
| `invalidate_hard_deletes` | Mark missing records as invalid | `bool` | N (default: `true`) |

#### SCD_TYPE_2_BY_TIME

Tracks changes based on an `updated_at` timestamp column.

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

Tracks changes by comparing column values (no `updated_at` column needed).

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

Enable automatic name inference from directory structure:

```yaml
model_defaults:
  dialect: snowflake
  
# Enable name inference
infer_names: true
```

With `infer_names: true`, a model at `models/sales/daily_sales.sql` automatically gets the name `sales.daily_sales`.

Learn more in the [configuration guide](../../guides/configuration.md#model-naming).
