# Kinds

Model kinds determine how Vulcan loads and processes your data. Each kind is optimized for different use cases. Some rebuild everything from scratch, others update incrementally, and some create views that compute on-demand.


## INCREMENTAL_BY_TIME_RANGE

`INCREMENTAL_BY_TIME_RANGE` models are perfect for time-series data, things like events, logs, transactions, or any data that arrives over time. Instead of rebuilding everything each run (like FULL models do), these models only process the time intervals that are missing or need updating.

If you're processing daily sales data, you don't want to reprocess all of 2023 just to add today's data. With `INCREMENTAL_BY_TIME_RANGE`, Vulcan only processes the new intervals, which saves time and money.

To use this kind, you need to tell Vulcan two things:

1. **Which column has your time data** - So Vulcan knows how to partition and filter
2. **A WHERE clause** - That filters your upstream data by time range using Vulcan's time macros

You specify the time column in your `MODEL` DDL using the `time_column` key. Here's a simple example:

```sql linenums="1"
MODEL (
  name vulcan_demo.daily_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date -- This model's time information is stored in the `order_date` column
  )
);
```

<a id="timezones"></a>
In addition to specifying a time column in the `MODEL` DDL, the model's query must contain a `WHERE` clause that filters the upstream records by time range. Vulcan provides special macros that represent the start and end of the time range being processed: `@start_date` / `@end_date` and `@start_ds` / `@end_ds`. See [Macros](../advanced-features/macros/variables.md) for more information.

??? "Example SQL sequence when applying this model kind (ex: BigQuery)"
    This example demonstrates incremental by time range models.

    Create a model with the following definition and run `vulcan plan dev`:

    ```sql
    MODEL (
      name demo.incrementals_demo,
      kind INCREMENTAL_BY_TIME_RANGE (
        -- How does this model kind behave?

        --   DELETE by time range, then INSERT
        time_column transaction_date,

        -- How do I handle late-arriving data?

        --   Handle late-arriving events for the past 2 (2*1) days based on cron

        --   interval. Each time it runs, it will process today, yesterday, and

        --   the day before yesterday.
        lookback 2,
      ),

      -- Don't backfill data before this date
      start '2024-10-25',

      -- What schedule should I run these at?

      --   Daily at Midnight UTC
      cron '@daily',

      -- Good documentation for the primary key
      grains (transaction_id),

      -- How do I test this data?

      --   Validate that the `transaction_id` primary key values are both unique

      --   and non-null. Data audit tests only run for the processed intervals,

      --   not for the entire table.

      -- audits (

      --   UNIQUE_VALUES(columns = (transaction_id)),

      --   NOT_NULL(columns = (transaction_id))

      -- )
    );

    WITH sales_data AS (
      SELECT
        transaction_id,
        product_id,
        customer_id,
        transaction_amount,
        -- How do I account for UTC vs. PST (California baby) timestamps?

        --   Make sure all time columns are in UTC and convert them to PST in the

        --   presentation layer downstream.
        transaction_timestamp,
        payment_method,
        currency
      FROM vulcan-public-demo.tcloud_raw_data.sales  -- Source A: sales data
      -- How do I make this run fast and only process the necessary intervals?

      --   Use our date macros that will automatically run the necessary intervals.

      --   Because Vulcan manages state, it will know what needs to run each time

      --   you invoke `vulcan run`.
      WHERE transaction_timestamp BETWEEN @start_dt AND @end_dt
    ),

    product_usage AS (
      SELECT
        product_id,
        customer_id,
        last_usage_date,
        usage_count,
        feature_utilization_score,
        user_segment
      FROM vulcan-public-demo.tcloud_raw_data.product_usage  -- Source B
      -- Include usage data from the 30 days before the interval
      WHERE last_usage_date BETWEEN DATE_SUB(@start_dt, INTERVAL 30 DAY) AND @end_dt
    )

    SELECT
      s.transaction_id,
      s.product_id,
      s.customer_id,
      s.transaction_amount,
      -- Extract the date from the timestamp to partition by day
      DATE(s.transaction_timestamp) as transaction_date,
      -- Convert timestamp to PST using a SQL function in the presentation layer for end users
      DATETIME(s.transaction_timestamp, 'America/Los_Angeles') as transaction_timestamp_pst,
      s.payment_method,
      s.currency,
      -- Product usage metrics
      p.last_usage_date,
      p.usage_count,
      p.feature_utilization_score,
      p.user_segment,
      -- Derived metrics
      CASE
        WHEN p.usage_count > 100 AND p.feature_utilization_score > 0.8 THEN 'Power User'
        WHEN p.usage_count > 50 THEN 'Regular User'
        WHEN p.usage_count IS NULL THEN 'New User'
        ELSE 'Light User'
      END as user_type,
      -- Time since last usage
      DATE_DIFF(s.transaction_timestamp, p.last_usage_date, DAY) as days_since_last_usage
    FROM sales_data s
    LEFT JOIN product_usage p
      ON s.product_id = p.product_id
      AND s.customer_id = p.customer_id
    ```

    Vulcan will execute this SQL to create a versioned table in the physical layer. Note that the table's version fingerprint, `50975949`, is part of the table name.

    ```sql
    CREATE TABLE IF NOT EXISTS `vulcan-public-demo`.`vulcan__demo`.`demo__incrementals_demo__50975949` (
      `transaction_id` STRING,
      `product_id` STRING,
      `customer_id` STRING,
      `transaction_amount` NUMERIC,
      `transaction_date` DATE OPTIONS (description='We extract the date from the timestamp to partition by day'),
      `transaction_timestamp_pst` DATETIME OPTIONS (description='Convert this to PST using a SQL function'),
      `payment_method` STRING,
      `currency` STRING,
      `last_usage_date` TIMESTAMP,
      `usage_count` INT64,
      `feature_utilization_score` FLOAT64,
      `user_segment` STRING,
      `user_type` STRING OPTIONS (description='Derived metrics'),
      `days_since_last_usage` INT64 OPTIONS (description='Time since last usage')
      )
      PARTITION BY `transaction_date`
    ```

    Vulcan will validate the SQL before processing data (note the `WHERE FALSE LIMIT 0` and the placeholder timestamps).

    ```sql
    WITH `sales_data` AS (
      SELECT
        `sales`.`transaction_id` AS `transaction_id`,
        `sales`.`product_id` AS `product_id`,
        `sales`.`customer_id` AS `customer_id`,
        `sales`.`transaction_amount` AS `transaction_amount`,
        `sales`.`transaction_timestamp` AS `transaction_timestamp`,
        `sales`.`payment_method` AS `payment_method`,
        `sales`.`currency` AS `currency`
      FROM `vulcan-public-demo`.`tcloud_raw_data`.`sales` AS `sales`
      WHERE (
        `sales`.`transaction_timestamp` <= CAST('1970-01-01 23:59:59.999999+00:00' AS TIMESTAMP) AND
        `sales`.`transaction_timestamp` >= CAST('1970-01-01 00:00:00+00:00' AS TIMESTAMP)) AND
        FALSE
    ),
    `product_usage` AS (
      SELECT
        `product_usage`.`product_id` AS `product_id`,
        `product_usage`.`customer_id` AS `customer_id`,
        `product_usage`.`last_usage_date` AS `last_usage_date`,
        `product_usage`.`usage_count` AS `usage_count`,
        `product_usage`.`feature_utilization_score` AS `feature_utilization_score`,
        `product_usage`.`user_segment` AS `user_segment`
      FROM `vulcan-public-demo`.`tcloud_raw_data`.`product_usage` AS `product_usage`
      WHERE (
        `product_usage`.`last_usage_date` <= CAST('1970-01-01 23:59:59.999999+00:00' AS TIMESTAMP) AND
        `product_usage`.`last_usage_date` >= CAST('1969-12-02 00:00:00+00:00' AS TIMESTAMP)
        ) AND
        FALSE
    )

    SELECT
      `s`.`transaction_id` AS `transaction_id`,
      `s`.`product_id` AS `product_id`,
      `s`.`customer_id` AS `customer_id`,
      CAST(`s`.`transaction_amount` AS NUMERIC) AS `transaction_amount`,
      DATE(`s`.`transaction_timestamp`) AS `transaction_date`,
      DATETIME(`s`.`transaction_timestamp`, 'America/Los_Angeles') AS `transaction_timestamp_pst`,
      `s`.`payment_method` AS `payment_method`,
      `s`.`currency` AS `currency`,
      `p`.`last_usage_date` AS `last_usage_date`,
      `p`.`usage_count` AS `usage_count`,
      `p`.`feature_utilization_score` AS `feature_utilization_score`,
      `p`.`user_segment` AS `user_segment`,
      CASE
        WHEN `p`.`feature_utilization_score` > 0.8 AND `p`.`usage_count` > 100 THEN 'Power User'
        WHEN `p`.`usage_count` > 50 THEN 'Regular User'
        WHEN `p`.`usage_count` IS NULL THEN 'New User'
        ELSE 'Light User'
      END AS `user_type`,
      DATE_DIFF(`s`.`transaction_timestamp`, `p`.`last_usage_date`, DAY) AS `days_since_last_usage`
    FROM `sales_data` AS `s`
    LEFT JOIN `product_usage` AS `p`
      ON `p`.`customer_id` = `s`.`customer_id` AND
      `p`.`product_id` = `s`.`product_id`
    WHERE FALSE
    LIMIT 0
    ```

    Vulcan will merge data into the empty table.

    ```sql
    MERGE INTO `vulcan-public-demo`.`vulcan__demo`.`demo__incrementals_demo__50975949` AS `__MERGE_TARGET__` USING (
      WITH `sales_data` AS (
        SELECT
          `transaction_id`,
          `product_id`,
          `customer_id`,
          `transaction_amount`,
          `transaction_timestamp`,
          `payment_method`,
          `currency`
        FROM `vulcan-public-demo`.`tcloud_raw_data`.`sales` AS `sales`
        WHERE `transaction_timestamp` BETWEEN CAST('2024-10-25 00:00:00+00:00' AS TIMESTAMP) AND CAST('2024-11-04 23:59:59.999999+00:00' AS TIMESTAMP)
      ),
      `product_usage` AS (
        SELECT
          `product_id`,
          `customer_id`,
          `last_usage_date`,
          `usage_count`,
          `feature_utilization_score`,
          `user_segment`
        FROM `vulcan-public-demo`.`tcloud_raw_data`.`product_usage` AS `product_usage`
        WHERE `last_usage_date` BETWEEN DATE_SUB(CAST('2024-10-25 00:00:00+00:00' AS TIMESTAMP), INTERVAL '30' DAY) AND CAST('2024-11-04 23:59:59.999999+00:00' AS TIMESTAMP)
      )

      SELECT
        `transaction_id`,
        `product_id`,
        `customer_id`,
        `transaction_amount`,
        `transaction_date`,
        `transaction_timestamp_pst`,
        `payment_method`,
        `currency`,
        `last_usage_date`,
        `usage_count`,
        `feature_utilization_score`,
        `user_segment`,
        `user_type`,
        `days_since_last_usage`
      FROM (
        SELECT
          `s`.`transaction_id` AS `transaction_id`,
          `s`.`product_id` AS `product_id`,
          `s`.`customer_id` AS `customer_id`,
          `s`.`transaction_amount` AS `transaction_amount`,
          DATE(`s`.`transaction_timestamp`) AS `transaction_date`,
          DATETIME(`s`.`transaction_timestamp`, 'America/Los_Angeles') AS `transaction_timestamp_pst`,
          `s`.`payment_method` AS `payment_method`,
          `s`.`currency` AS `currency`,
          `p`.`last_usage_date` AS `last_usage_date`,
          `p`.`usage_count` AS `usage_count`,
          `p`.`feature_utilization_score` AS `feature_utilization_score`,
          `p`.`user_segment` AS `user_segment`,
          CASE
            WHEN `p`.`usage_count` > 100 AND `p`.`feature_utilization_score` > 0.8 THEN 'Power User'
            WHEN `p`.`usage_count` > 50 THEN 'Regular User'
            WHEN `p`.`usage_count` IS NULL THEN 'New User'
            ELSE 'Light User'
          END AS `user_type`,
          DATE_DIFF(`s`.`transaction_timestamp`, `p`.`last_usage_date`, DAY) AS `days_since_last_usage`
        FROM `sales_data` AS `s`
        LEFT JOIN `product_usage` AS `p`
          ON `s`.`product_id` = `p`.`product_id`
          AND `s`.`customer_id` = `p`.`customer_id`
      ) AS `_subquery`
      WHERE `transaction_date` BETWEEN CAST('2024-10-25' AS DATE) AND CAST('2024-11-04' AS DATE)
    ) AS `__MERGE_SOURCE__`
    ON FALSE
    WHEN NOT MATCHED BY SOURCE AND `transaction_date` BETWEEN CAST('2024-10-25' AS DATE) AND CAST('2024-11-04' AS DATE) THEN DELETE
    WHEN NOT MATCHED THEN
      INSERT (
        `transaction_id`, `product_id`, `customer_id`, `transaction_amount`, `transaction_date`, `transaction_timestamp_pst`,
        `payment_method`, `currency`, `last_usage_date`, `usage_count`, `feature_utilization_score`, `user_segment`, `user_type`,
        `days_since_last_usage`
      )
      VALUES (
        `transaction_id`, `product_id`, `customer_id`, `transaction_amount`, `transaction_date`, `transaction_timestamp_pst`,
        `payment_method`, `currency`, `last_usage_date`, `usage_count`, `feature_utilization_score`, `user_segment`, `user_type`,
        `days_since_last_usage`
      )
    ```

    Vulcan will create a suffixed `__dev` schema based on the name of the plan environment.

    ```sql
    CREATE SCHEMA IF NOT EXISTS `vulcan-public-demo`.`demo__dev`
    ```

    Vulcan will create a view in the virtual layer to pointing to the versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`demo__dev`.`incrementals_demo` AS
    SELECT *
    FROM `vulcan-public-demo`.`vulcan__demo`.`demo__incrementals_demo__50975949`
    ```

!!! info "Important: Timezone Requirements"

    Your `time_column` should be in UTC timezone. This ensures Vulcan's scheduler and time macros work correctly.

    **Why UTC?** It's a data engineering best practice, convert everything to UTC when it enters your system, then convert to local timezones only when data leaves for end users. This prevents timezone-related bugs as data flows between models.

    **Important:** The `cron_tz` flag doesn't change this requirement, it only affects when your model runs, not how time intervals are calculated.

    If you absolutely must use a different timezone, you can try to work around it using `lookback`, `allow_partials`, or cron offsets, but UTC is strongly recommended. Trust us on this one, timezone bugs are no fun!


This example implements a complete `INCREMENTAL_BY_TIME_RANGE` model that specifies the time column name `order_date` in the `MODEL` DDL and includes a SQL `WHERE` clause to filter records by time range:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.incremental_by_time_range,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column order_date
      ),
      start '2025-01-01',
      grains (order_date, product_id),
      cron '@daily'
    );

    SELECT
      o.order_date,
      p.product_id,
      p.name AS product_name,
      p.category,
      COUNT(DISTINCT o.order_id) AS order_count,
      SUM(oi.quantity) AS total_quantity,
      SUM(oi.quantity * oi.unit_price) AS total_sales_amount
    FROM vulcan_demo.orders AS o
    JOIN vulcan_demo.order_items AS oi
      ON o.order_id = oi.order_id
    JOIN vulcan_demo.products AS p
      ON oi.product_id = p.product_id
    WHERE
      o.order_date BETWEEN @start_ds AND @end_ds
    GROUP BY
      o.order_date, p.product_id, p.name, p.category
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.incremental_by_time_range_py",
        columns={
            "order_date": "date",
            "product_id": "int",
            "product_name": "string",
            "total_sales_amount": "decimal(10,2)",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="order_date",
        ),
        grains=["order_date", "product_id"],
        depends_on=["vulcan_demo.orders", "vulcan_demo.order_items", "vulcan_demo.products"],
    )
    def execute(context: ExecutionContext, start, end, **kwargs):
        query = f"""
        SELECT o.order_date, p.product_id, p.name AS product_name,
               SUM(oi.quantity * oi.unit_price) AS total_sales_amount
        FROM vulcan_demo.orders o
        JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
        JOIN vulcan_demo.products p ON oi.product_id = p.product_id
        WHERE o.order_date BETWEEN '{start}' AND '{end}'
        GROUP BY o.order_date, p.product_id, p.name
        """
        return context.fetchdf(query)
    ```

### Time Column

Vulcan needs to know which column in your model's output represents the timestamp or date for each record. This is your `time_column`.

!!! info "Remember: UTC Timezone"

    Your `time_column` should be in UTC timezone. Learn more about why this matters [above](#timezones).

The time column is used to determine which records will be overwritten during data [restatement](../../guides/plan_guide.md#restatement-plans-restate-model) and provides a partition key for engines that support partitioning (such as Apache Spark). The name of the time column is specified in the `MODEL` DDL `kind` specification:

```sql linenums="1"
MODEL (
  name vulcan_demo.daily_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date -- This model's time information is stored in the `order_date` column
  )
);
```

By default, Vulcan assumes your time column is in `%Y-%m-%d` format (like `2025-01-15`). If your dates are in a different format, you can specify it:

```sql linenums="1"
MODEL (
  name vulcan_demo.daily_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column (order_date, '%Y-%m-%d')
  )
);
```

!!! note "Format String Dialect"

    Use the same SQL dialect for your format string as the one used in your model's query.

**Safety feature:** Vulcan automatically adds a time range filter to your query's output to prevent data leakage. This means even if your `WHERE` clause has a bug, Vulcan won't accidentally store records outside the target interval.

Here's how it works:

- **Your WHERE clause** filters the **input** data as it's read from upstream tables (makes queries faster)

- **Vulcan's automatic filter** filters the **output** data before it's stored (prevents data leakage)

This is especially important when handling late-arriving data, you don't want to accidentally overwrite unrelated records!

Example: sometimes your upstream data uses a different time column than your model. In this case, you filter on the upstream column (`shipped_date`), but Vulcan still adds a filter on your model's time column (`order_date`):

```sql linenums="1"
MODEL (
  name vulcan_demo.shipment_events,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date -- `order_date` is model's time column
  )
);

SELECT
  o.order_date,
  s.shipped_date,
  s.carrier
FROM vulcan_demo.orders AS o
JOIN vulcan_demo.shipments AS s ON o.order_id = s.order_id
WHERE
  s.shipped_date BETWEEN @start_ds AND @end_ds; -- Filter is based on the user-supplied `shipped_date` column
```

At runtime, Vulcan will automatically modify the model's query to look like this:

```sql linenums="1"
SELECT
  o.order_date,
  s.shipped_date,
  s.carrier
FROM vulcan_demo.orders AS o
JOIN vulcan_demo.shipments AS s ON o.order_id = s.order_id
WHERE
  s.shipped_date BETWEEN @start_ds AND @end_ds
  AND o.order_date BETWEEN @start_ds AND @end_ds; -- `order_date` time column filter automatically added by Vulcan
```

### Partitioning

By default, Vulcan automatically adds your `time_column` to the partition key. This lets database engines do partition pruning (skipping partitions that don't match your query), which makes queries faster.

**Why this matters:** If you're querying data from the last 7 days, the engine can skip scanning all the old partitions. That's a huge performance win!

Sometimes you might not want this though, maybe you want to partition exclusively on another column, or you want to partition on `month(time_column)` but your engine doesn't support expression-based partitioning.

To disable automatic time column partitioning, set `partition_by_time_column false`:

```sql linenums="1"
MODEL (
  name vulcan_demo.daily_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date,
    partition_by_time_column false
  ),
  partitioned_by (warehouse_id) -- order_date will no longer be automatically added here and the partition key will just be 'warehouse_id'
);
```

### Idempotency
Make incremental by time range model queries [idempotent](../../glossary.md#execution-terms) to prevent unexpected results during data [restatement](../../guides/plan_guide.md#restatement-plans-restate-model).

Make your incremental by time range queries idempotent. This means running the same query multiple times produces the same result, which prevents surprises during data restatement.

**Watch out:** Your upstream models can affect idempotency. If you reference a FULL model (which rebuilds everything each run), your incremental model becomes non-idempotent because that upstream data changes every time. This is usually fine, but it's good to be aware of.

### Materialization strategy
Depending on the target engine, models of the `INCREMENTAL_BY_TIME_RANGE` kind are materialized using the following strategies:

| Engine     | Strategy                                  |
|------------|-------------------------------------------|
| Spark      | INSERT OVERWRITE by time column partition |
| Databricks | INSERT OVERWRITE by time column partition |
| Snowflake  | DELETE by time range, then INSERT         |
| BigQuery   | DELETE by time range, then INSERT         |
| Redshift   | DELETE by time range, then INSERT         |
| Postgres   | DELETE by time range, then INSERT         |
| DuckDB     | DELETE by time range, then INSERT         |

## INCREMENTAL_BY_UNIQUE_KEY

`INCREMENTAL_BY_UNIQUE_KEY` models update data based on a unique key. It works like an upsert operation: if a key exists, update it; if it doesn't, insert it.

Here's how it works:

- **New key?** → Insert the row

- **Existing key?** → Update the row with new data

- **Key missing from new data?** → Leave the existing row alone

**Why use this?** Perfect for dimension tables, customer records, or any data where you want to keep the latest version of each record without rebuilding everything. It's like updating a contact list, you update existing contacts and add new ones, but you don't delete contacts that aren't in your latest import.

This kind is a good fit for datasets that have the following traits:

* Each record has a unique key associated with it.
* There is at most one record associated with each unique key.
* It is appropriate to upsert records, so existing records can be overwritten by new arrivals when their keys match.

A [Slowly Changing Dimension](../../glossary.md#model-terms) (SCD) is one approach that fits this description well. See the [SCD Type 2](#scd-type-2) model kind for SCD Type 2 models.

The name of the unique key column must be provided as part of the `MODEL` DDL, as in this example:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.incremental_by_unique_key,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key customer_id
      ),
      start '2025-01-01',
      cron '@daily',
      grains (customer_id)
    );

    SELECT
      c.customer_id,
      c.name AS customer_name,
      c.email,
      COUNT(DISTINCT o.order_id) AS total_orders,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent,
      MAX(o.order_date) AS last_order_date
    FROM vulcan_demo.customers AS c
    LEFT JOIN vulcan_demo.orders AS o
      ON c.customer_id = o.customer_id
    LEFT JOIN vulcan_demo.order_items AS oi
      ON o.order_id = oi.order_id
    WHERE
      o.order_date IS NULL OR o.order_date BETWEEN @start_date AND @end_date
    GROUP BY c.customer_id, c.name, c.email
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.incremental_by_unique_key_py",
        columns={
            "customer_id": "int",
            "total_spent": "decimal(10,2)",
            "last_order_date": "date",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_UNIQUE_KEY,
            unique_key=["customer_id"],
        ),
        grains=["customer_id"],
        depends_on=["vulcan_demo.customers", "vulcan_demo.orders", "vulcan_demo.order_items"],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT c.customer_id,
               SUM(oi.quantity * oi.unit_price) as total_spent,
               MAX(o.order_date) as last_order_date
        FROM vulcan_demo.customers c
        LEFT JOIN vulcan_demo.orders o ON c.customer_id = o.customer_id
        LEFT JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
        GROUP BY c.customer_id
        """
        return context.fetchdf(query)
    ```

You can use composite keys (multiple columns) too:

```sql linenums="1"
MODEL (
  name vulcan_demo.order_items_agg,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key (order_id, product_id)
  )
);
```

You can also filter upstream records by time range using `@start_date`, `@end_date`, or other time macros (just like `INCREMENTAL_BY_TIME_RANGE`). This is useful when you only want to process records from a specific time period.

**Note:** Vulcan's time macros are always in UTC timezone.

```sql linenums="1"
SELECT
  c.customer_id,
  c.name AS customer_name,
  COUNT(o.order_id) AS total_orders
FROM vulcan_demo.customers AS c
LEFT JOIN vulcan_demo.orders AS o ON c.customer_id = o.customer_id
WHERE
  o.order_date BETWEEN @start_date AND @end_date
GROUP BY c.customer_id, c.name
```

??? "Example SQL sequence when applying this model kind (ex: BigQuery)"

    Create a model with the following definition and run `vulcan plan dev`:

    ```sql
    MODEL (
      name demo.incremental_by_unique_key_example,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key id
      ),
      start '2020-01-01',
      cron '@daily',
    );

    SELECT
      id,
      item_id,
      event_date
    FROM demo.seed_model
    WHERE
      event_date BETWEEN @start_date AND @end_date
    ```

    Vulcan will execute this SQL to create a versioned table in the physical layer. Note that the table's version fingerprint, `1161945221`, is part of the table name.

    ```sql
    CREATE TABLE IF NOT EXISTS `vulcan-public-demo`.`vulcan__demo`.`demo__incremental_by_unique_key_example__1161945221` (`id` INT64, `item_id` INT64, `event_date` DATE)
    ```

    Vulcan will validate the model's query before processing data (note the `FALSE LIMIT 0` in the `WHERE` statement and the placeholder dates).

    ```sql
    SELECT `seed_model`.`id` AS `id`, `seed_model`.`item_id` AS `item_id`, `seed_model`.`event_date` AS `event_date`
    FROM `vulcan-public-demo`.`vulcan__demo`.`demo__seed_model__2834544882` AS `seed_model`
    WHERE (`seed_model`.`event_date` <= CAST('1970-01-01' AS DATE) AND `seed_model`.`event_date` >= CAST('1970-01-01' AS DATE)) AND FALSE LIMIT 0
    ```

    Vulcan will create a versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE TABLE `vulcan-public-demo`.`vulcan__demo`.`demo__incremental_by_unique_key_example__1161945221` AS
    SELECT CAST(`id` AS INT64) AS `id`, CAST(`item_id` AS INT64) AS `item_id`, CAST(`event_date` AS DATE) AS `event_date`
    FROM (SELECT `seed_model`.`id` AS `id`, `seed_model`.`item_id` AS `item_id`, `seed_model`.`event_date` AS `event_date`
    FROM `vulcan-public-demo`.`vulcan__demo`.`demo__seed_model__2834544882` AS `seed_model`
    WHERE `seed_model`.`event_date` <= CAST('2024-10-30' AS DATE) AND `seed_model`.`event_date` >= CAST('2020-01-01' AS DATE)) AS `_subquery`
    ```

    Vulcan will create a suffixed `__dev` schema based on the name of the plan environment.

    ```sql
    CREATE SCHEMA IF NOT EXISTS `vulcan-public-demo`.`demo__dev`
    ```

    Vulcan will create a view in the virtual layer pointing to the versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`demo__dev`.`incremental_by_unique_key_example` AS
    SELECT * FROM `vulcan-public-demo`.`vulcan__demo`.`demo__incremental_by_unique_key_example__1161945221`
    ```

**Note:** Models of the `INCREMENTAL_BY_UNIQUE_KEY` kind are inherently [non-idempotent](../../glossary.md#execution-terms), which should be taken into consideration during data [restatement](../../guides/plan_guide.md#restatement-plans-restate-model). As a result, partial data restatement is not supported for this model kind, which means that the entire table will be recreated from scratch if restated.

### Unique Key Expressions

You're not limited to column names. You can use SQL expressions when you need to create a key from multiple columns or transform values. Example using `COALESCE`:

```sql linenums="1"
MODEL (
  name vulcan_demo.customers_unique,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key COALESCE("email", '')
  )
);
```

### When Matched Expression

By default, when a key matches (source and target have the same key), Vulcan updates all columns. But sometimes you want more control, maybe you want to preserve certain values, or only update specific columns.

You can customize this behavior with `when_matched` expressions:

```sql linenums="1"
MODEL (
  name vulcan_demo.customers_update,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id,
    when_matched (
      WHEN MATCHED THEN UPDATE SET target.email = COALESCE(source.email, target.email)
    )
  )
);
```

**Important:** You must use `source` and `target` aliases to distinguish between the source (new data) and target (existing table) columns.

You can also provide multiple `WHEN MATCHED` expressions for more complex logic:

```sql linenums="1"
MODEL (
  name vulcan_demo.products_update,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key product_id,
    when_matched (
      WHEN MATCHED AND source.price IS NULL THEN UPDATE SET target.price = target.price
      WHEN MATCHED THEN UPDATE SET target.category = COALESCE(source.category, target.category)
    )
  )
);
```

!!! note "Engine Support"

    `when_matched` only works on engines that support the `MERGE` statement. Supported engines include:
    
    - BigQuery

    - Databricks

    - Postgres

    - Redshift (requires `enable_merge: true` in connection config)

    - Snowflake

    - Spark

    **Redshift users:** You need to enable MERGE support by setting `enable_merge: true` in your connection config. It's disabled by default.

```yaml linenums="1"
gateways:
  redshift:
    connection:
      type: redshift
      enable_merge: true
```

Redshift supports only the `UPDATE` or `DELETE` actions for the `WHEN MATCHED` clause and does not allow multiple `WHEN MATCHED` expressions. For further information, refer to the [Redshift documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_MERGE.html#r_MERGE-parameters).

### Merge Filter Expression

MERGE operations can be slow on large tables because they typically scan the entire existing table. If you're only updating a small subset of records, this is wasteful.

**Solution:** Use `merge_filter` to add conditions to the MERGE's `ON` clause. This limits the scan to only the rows that might match, making things much faster.

The `merge_filter` accepts predicates (single or combined with AND) that get added to the MERGE operation:

```sql linenums="1"
MODEL (
  name vulcan_demo.orders_recent,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key order_id,
    merge_filter source._operation IS NULL AND target.order_date > dateadd(day, -7, current_date)
  )
);
```

Just like `when_matched`, use `source` and `target` aliases to reference the source and target tables.

If your dbt project uses `incremental_predicates`, Vulcan automatically converts them to `merge_filter`.

### Materialization strategy
Depending on the target engine, models of the `INCREMENTAL_BY_UNIQUE_KEY` kind are materialized using the following strategies:

| Engine     | Strategy                            |
|------------|-------------------------------------|
| Spark      | not supported                       |
| Databricks | MERGE ON unique key                 |
| Snowflake  | MERGE ON unique key                 |
| BigQuery   | MERGE ON unique key                 |
| Redshift   | MERGE ON unique key                 |
| Postgres   | MERGE ON unique key                 |
| DuckDB     | DELETE ON matched + INSERT new rows |

## FULL

`FULL` models are the simplest kind, they rebuild everything from scratch every time they run. No incremental logic, no time columns, no unique keys. Just run the query and replace the entire table.

**When to use FULL:**

- Small datasets where rebuilding is fast and cheap

- Aggregate tables without a time dimension

- Tables that change completely each run (like a "current state" snapshot)

- Development and testing (simpler is better when you're iterating)

**When NOT to use FULL:**

- Large datasets (you'll wait forever and pay a lot)

- Time-series data (use `INCREMENTAL_BY_TIME_RANGE` instead)

- Tables that only change partially (use incremental kinds)

The trade-off is simplicity vs. performance. For small tables, FULL is perfect. For large tables, incremental kinds will save you time and money.

This example specifies a `FULL` model kind:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.full_model,
      kind FULL,
      start '2025-01-01',
      grains (customer_id)
    );

    SELECT
      c.customer_id,
      c.name AS customer_name,
      c.email,
      COUNT(DISTINCT o.order_id) AS total_orders,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent,
      COALESCE(SUM(oi.quantity * oi.unit_price), 0) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS avg_order_value
    FROM vulcan_demo.customers AS c
    LEFT JOIN vulcan_demo.orders AS o
      ON c.customer_id = o.customer_id
    LEFT JOIN vulcan_demo.order_items AS oi
      ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.name, c.email
    ORDER BY total_spent DESC
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.full_model_py",
        columns={
            "product_id": "int",
            "product_name": "string",
            "category": "string",
            "total_sales": "decimal(10,2)",
        },
        kind=dict(
            name=ModelKindName.FULL,
        ),
        grains=["product_id"],
        depends_on=["vulcan_demo.products", "vulcan_demo.order_items", "vulcan_demo.orders"],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT p.product_id, p.name AS product_name, p.category,
               COALESCE(SUM(oi.quantity * oi.unit_price), 0) as total_sales
        FROM vulcan_demo.products p
        LEFT JOIN vulcan_demo.order_items oi ON p.product_id = oi.product_id
        LEFT JOIN vulcan_demo.orders o ON oi.order_id = o.order_id
        GROUP BY p.product_id, p.name, p.category
        ORDER BY total_sales DESC
        """
        return context.fetchdf(query)
    ```

??? "Example SQL sequence when applying this model kind (ex: BigQuery)"

    Create a model with the following definition and run `vulcan plan dev`:

    ```sql
    MODEL (
      name demo.full_model_example,
      kind FULL,
      cron '@daily',
      grains (item_id),
    );

    SELECT
      item_id,
      COUNT(DISTINCT id) AS num_orders
    FROM demo.incremental_model
    GROUP BY
      item_id
    ```

    Vulcan will execute this SQL to create a versioned table in the physical layer. Note that the table's version fingerprint, `2345651858`, is part of the table name.

    ```sql
    CREATE TABLE IF NOT EXISTS `vulcan-public-demo`.`vulcan__demo`.`demo__full_model_example__2345651858` (`item_id` INT64, `num_orders` INT64)
    ```

    Vulcan will validate the model's query before processing data (note the `WHERE FALSE` and `LIMIT 0`).

    ```sql
    SELECT `incremental_model`.`item_id` AS `item_id`, COUNT(DISTINCT `incremental_model`.`id`) AS `num_orders`
    FROM `vulcan-public-demo`.`vulcan__demo`.`demo__incremental_model__89556012` AS `incremental_model`
    WHERE FALSE
    GROUP BY `incremental_model`.`item_id` LIMIT 0
    ```

    Vulcan will create a versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE TABLE `vulcan-public-demo`.`vulcan__demo`.`demo__full_model_example__2345651858` AS
    SELECT CAST(`item_id` AS INT64) AS `item_id`, CAST(`num_orders` AS INT64) AS `num_orders`
    FROM (SELECT `incremental_model`.`item_id` AS `item_id`, COUNT(DISTINCT `incremental_model`.`id`) AS `num_orders`
    FROM `vulcan-public-demo`.`vulcan__demo`.`demo__incremental_model__89556012` AS `incremental_model`
    GROUP BY `incremental_model`.`item_id`) AS `_subquery`
    ```

    Vulcan will create a suffixed `__dev` schema based on the name of the plan environment.

    ```sql
    CREATE SCHEMA IF NOT EXISTS `vulcan-public-demo`.`demo__dev`
    ```

    Vulcan will create a view in the virtual layer pointing to the versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`demo__dev`.`full_model_example` AS
    SELECT * FROM `vulcan-public-demo`.`vulcan__demo`.`demo__full_model_example__2345651858`
    ```

### Materialization strategy
Depending on the target engine, models of the `FULL` kind are materialized using the following strategies:

| Engine     | Strategy                         |
|------------|----------------------------------|
| Spark      | INSERT OVERWRITE                 |
| Databricks | INSERT OVERWRITE                 |
| Snowflake  | CREATE OR REPLACE TABLE          |
| BigQuery   | CREATE OR REPLACE TABLE          |
| Redshift   | DROP TABLE, CREATE TABLE, INSERT |
| Postgres   | DROP TABLE, CREATE TABLE, INSERT |
| DuckDB     | CREATE OR REPLACE TABLE          |

## VIEW

Unlike the other kinds, `VIEW` models don't store any data. Instead, they create a virtual table (a view) that runs your query every time someone queries it.

**How it works:** When a downstream model or user queries your VIEW model, the database executes your query on-the-fly. No data is pre-computed or stored.

**When to use VIEW:**

- Simple transformations that are fast to compute

- When you want always-fresh data (no caching)

- When storage is expensive but compute is cheap

- For lightweight transformations that don't need materialization

**When NOT to use VIEW:**

- Expensive queries that run frequently (you'll pay the compute cost every time)

- Complex aggregations or joins (materialize these instead)

- Python models (VIEW isn't supported for Python, use SQL)

!!! note "Default Kind"

    `VIEW` is the default model kind if you don't specify one. So if you write a model without a `kind`, it becomes a VIEW automatically.

!!! warning "Performance Consideration"

    Since VIEW queries run every time they're referenced, expensive queries can get costly fast. If your view is referenced by many downstream models, you might be running that expensive query dozens of times. Consider materializing expensive views as FULL or incremental models instead.


This example specifies a `VIEW` model kind:

```sql linenums="1"
MODEL (
  name vulcan_demo.view_model,
  kind VIEW,
  grains (warehouse_performance_key)
);

SELECT
  w.warehouse_id,
  w.name AS warehouse_name,
  r.region_name,
  o.order_date,
  CONCAT(w.warehouse_id::TEXT, '_', o.order_date::TEXT) AS warehouse_performance_key,
  COUNT(DISTINCT o.order_id) AS total_transactions,
  SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
  COUNT(DISTINCT o.customer_id) AS unique_customers
FROM vulcan_demo.warehouses AS w
LEFT JOIN vulcan_demo.regions AS r
  ON w.region_id = r.region_id
LEFT JOIN vulcan_demo.orders AS o
  ON w.warehouse_id = o.warehouse_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
GROUP BY w.warehouse_id, w.name, r.region_name, o.order_date
```

??? "Example SQL sequence when applying this model kind (ex: BigQuery)"

    Create a model with the following definition and run `vulcan plan dev`:

    ```sql
    MODEL (
      name demo.example_view,
      kind VIEW,
      cron '@daily',
    );

    SELECT
      'hello there' as a_column
    ```

    Vulcan will execute this SQL to create a versioned view in the physical layer. Note that the view's version fingerprint, `1024042926`, is part of the view name.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`vulcan__demo`.`demo__example_view__1024042926`
    (`a_column`) AS SELECT 'hello there' AS `a_column`
    ```

    Vulcan will create a suffixed `__dev` schema based on the name of the plan environment.

    ```sql
    CREATE SCHEMA IF NOT EXISTS `vulcan-public-demo`.`demo__dev`
    ```

    Vulcan will create a view in the virtual layer pointing to the versioned view in the physical layer.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`demo__dev`.`example_view` AS
    SELECT * FROM `vulcan-public-demo`.`vulcan__demo`.`demo__example_view__1024042926`
    ```


### Materialized Views

Want the best of both worlds? You can turn a VIEW into a materialized view by setting `materialized: true`. Materialized views store the query results (like a table) but automatically refresh when the underlying data changes (like a view).

Set it up like this:

```sql linenums="1"
MODEL (
  name vulcan_demo.sales_summary,
  kind VIEW (
    materialized true
  )
);
```

!!! note "Engine Support"

    Materialized views are only supported on:
    
    - BigQuery

    - Databricks

    - Snowflake
    
    On other engines, this flag is ignored and you'll get a regular VIEW.

Vulcan only recreates the materialized view when your query changes or the view doesn't exist. This provides the performance benefits of materialized views without unnecessary refreshes.

## EMBEDDED

`EMBEDDED` models are like reusable SQL snippets. They don't create tables or views, instead, their query gets injected directly into any downstream model that references them, as a subquery.

**Why use this?** If you have common logic that multiple models need (like a CTE that filters active customers), you can define it once in an EMBEDDED model and reuse it everywhere. It's like a macro, but for SQL.

**Perfect for:**

- Common CTEs used across multiple models

- Reusable business logic (like "active customers" or "valid orders")

- Avoiding code duplication

!!! note "Python Models"

    Python models don't support the `EMBEDDED` kind, use a SQL model instead.

This example specifies an `EMBEDDED` model kind:

```sql linenums="1"
MODEL (
  name vulcan_demo.unique_customers,
  kind EMBEDDED
);

SELECT DISTINCT
  customer_id,
  name AS customer_name,
  email
FROM vulcan_demo.customers
```

## SEED
The `SEED` model kind is used to specify seed models for using static CSV datasets in your Vulcan project.

**How it works:** You point to a CSV file, define the schema, and Vulcan loads it into a table. The data only gets reloaded if you change the model definition or update the CSV file.

**Use cases:**

- Reference data (countries, states, categories)

- Lookup tables

- Static configuration data

- Test data

!!! note "Python Models"

    Python models don't support the `SEED` kind, use a SQL model instead.

!!! note "When Data Reloads"

    Seed models are loaded once and stay loaded unless you update the model definition or change the CSV file. This keeps things efficient, no point reloading static data every run!

This example specifies a `SEED` model kind:

```sql linenums="1"
MODEL (
  name vulcan_demo.seed_model,
  kind SEED (
    path '../seeds/seed_data.csv'
  ),
  columns (
    id INT,
    item_id INT,
    event_date DATE
  ),
  grains (id),
  assertions (
    UNIQUE_COMBINATION_OF_COLUMNS(columns := (id, event_date)),
    NOT_NULL(columns := (id, item_id, event_date))
  )
)
```

??? "Example SQL sequence when applying this model kind (ex: BigQuery)"

    Create a model with the following definition and run `vulcan plan dev`:

    ```sql
    MODEL (
      name demo.seed_example,
      kind SEED (
        path '../../seeds/seed_example.csv'
      ),
      columns (
        id INT64,
        item_id INT64,
        event_date DATE
      ),
      grains (id, event_date)
    )
    ```

    Vulcan will execute this SQL to create a versioned table in the physical layer. Note that the table's version fingerprint, `3038173937`, is part of the table name.

    ```sql
    CREATE TABLE IF NOT EXISTS `vulcan-public-demo`.`vulcan__demo`.`demo__seed_example__3038173937` (`id` INT64, `item_id` INT64, `event_date` DATE)
    ```

    Vulcan will upload the seed as a temp table in the physical layer.

    ```sql
    vulcan-public-demo.vulcan__demo.__temp_demo__seed_example__3038173937_9kzbpld7
    ```

    Vulcan will create a versioned table in the physical layer from the temp table.

    ```sql
    CREATE OR REPLACE TABLE `vulcan-public-demo`.`vulcan__demo`.`demo__seed_example__3038173937` AS
    SELECT CAST(`id` AS INT64) AS `id`, CAST(`item_id` AS INT64) AS `item_id`, CAST(`event_date` AS DATE) AS `event_date`
    FROM (SELECT `id`, `item_id`, `event_date`
    FROM `vulcan-public-demo`.`vulcan__demo`.`__temp_demo__seed_example__3038173937_9kzbpld7`) AS `_subquery`
    ```

    Vulcan will drop the temp table in the physical layer.

    ```sql
    DROP TABLE IF EXISTS `vulcan-public-demo`.`vulcan__demo`.`__temp_demo__seed_example__3038173937_9kzbpld7`
    ```

    Vulcan will create a suffixed `__dev` schema based on the name of the plan environment.

    ```sql
    CREATE SCHEMA IF NOT EXISTS `vulcan-public-demo`.`demo__dev`
    ```

    Vulcan will create a view in the virtual layer pointing to the versioned table in the physical layer.

    ```sql
    CREATE OR REPLACE VIEW `vulcan-public-demo`.`demo__dev`.`seed_example` AS
    SELECT * FROM `vulcan-public-demo`.`vulcan__demo`.`demo__seed_example__3038173937`
    ```

## SCD Type 2

SCD Type 2 is a model kind that supports [slowly changing dimensions](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Type_2:_add_new_row) (SCDs) in your Vulcan project. SCDs are a common pattern in data warehousing that allow you to track changes to records over time.

Vulcan achieves this by adding a `valid_from` and `valid_to` column to your model. The `valid_from` column is the timestamp that the record became valid (inclusive) and the `valid_to` column is the timestamp that the record became invalid (exclusive). The `valid_to` column is set to `NULL` for the latest record.

Therefore, you can use these models to not only tell you what the latest value is for a given record but also what the values were anytime in the past. Note that maintaining this history does come at a cost of increased storage and compute and this may not be a good fit for sources that change frequently since the history could get very large.

**Note**: Partial data [restatement](../../guides/plan_guide.md#restatement-plans-restate-model) is not supported for this model kind, which means that the entire table will be recreated from scratch if restated. This may lead to data loss, so data restatement is disabled for models of this kind by default.

Vulcan supports two ways to detect changes: **By Time** (recommended) or **By Column**. Let's look at both:

### SCD Type 2 By Time (Recommended)

**By Time** is the recommended approach. It works with source tables that have an "Updated At" timestamp column (like `updated_at`, `modified_at`, `last_changed`).

**Why it's recommended:** The timestamp tells you exactly when a record changed, which makes your SCD Type 2 table more accurate. You get precise `valid_from` times based on when the source system actually updated the record.

If your source table has an `updated_at` column, use this approach!

This example specifies a `SCD_TYPE_2_BY_TIME` model kind:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.scd_type2_by_time,
      kind SCD_TYPE_2_BY_TIME (
        unique_key dt
      ),
      grains (dt)
    );

    SELECT
      dd.dt,
      dd.year,
      dd.month,
      dd.day_of_week,
      COUNT(DISTINCT o.order_id) AS total_transactions,
      SUM(oi.quantity) AS total_quantity_sold,
      SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
      CURRENT_TIMESTAMP AS updated_at
    FROM vulcan_demo.dim_dates AS dd
    LEFT JOIN vulcan_demo.orders AS o
      ON dd.dt = o.order_date
    LEFT JOIN vulcan_demo.order_items AS oi
      ON o.order_id = oi.order_id
    GROUP BY dd.dt, dd.year, dd.month, dd.day_of_week
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.scd_type2_by_time_py",
        columns={
            "customer_id": "int",
            "customer_name": "string",
            "email": "string",
            "region_name": "string"
        },
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_TIME,
            unique_key=["customer_id"],
        ),
        grains=["customer_id"],
        depends_on=["vulcan_demo.customers", "vulcan_demo.regions"],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT c.customer_id, c.name as customer_name, c.email, r.region_name
        FROM vulcan_demo.customers c
        LEFT JOIN vulcan_demo.regions r ON c.region_id = r.region_id
        """
        return context.fetchdf(query)
    ```

Vulcan will materialize this table with the following structure:
```sql linenums="1"
TABLE db.menu_items (
  id INT,
  name STRING,
  price DOUBLE,
  updated_at TIMESTAMP,
  valid_from TIMESTAMP,
  valid_to TIMESTAMP
);
```

The `updated_at` column name can also be changed by adding the following to your model definition:
```sql linenums="1" hl_lines="5"
MODEL (
  name db.menu_items,
  kind SCD_TYPE_2_BY_TIME (
    unique_key id,
    updated_at_name my_updated_at -- Name for `updated_at` column
  )
);

SELECT
  id,
  name,
  price,
  my_updated_at
FROM
  stg.current_menu_items;
```

Vulcan will materialize this table with the following structure:
```sql linenums="1"
TABLE db.menu_items (
  id INT,
  name STRING,
  price DOUBLE,
  my_updated_at TIMESTAMP,
  valid_from TIMESTAMP,
  valid_to TIMESTAMP
);
```

### SCD Type 2 By Column

**By Column** works when your source table doesn't have an "Updated At" timestamp. Instead, Vulcan compares the values in specific columns between runs and detects changes.

**How it works:** You specify which columns to watch (or use `*` to watch all columns). When Vulcan detects a change in any of those columns, it records `valid_from` as the execution time when the change was detected.

**Use this when:** Your source system doesn't track update timestamps, but you still want to maintain history. The trade-off is that `valid_from` times are based on when Vulcan detected the change, not when the source system actually changed it.

This example specifies a `SCD_TYPE_2_BY_COLUMN` model kind:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.scd_type2_by_column,
      kind SCD_TYPE_2_BY_COLUMN (
        unique_key ARRAY[product_id],
        columns ARRAY[product_name, category, price]
      ),
      grains (product_id)
    );

    SELECT
      p.product_id,
      p.name AS product_name,
      p.category,
      p.price,
      s.name AS supplier_name,
      r.region_name
    FROM vulcan_demo.products AS p
    LEFT JOIN vulcan_demo.suppliers AS s
      ON p.supplier_id = s.supplier_id
    LEFT JOIN vulcan_demo.regions AS r
      ON s.region_id = r.region_id
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.scd_type2_by_column_py",
        columns={
            "product_id": "int",
            "product_name": "string",
            "category": "string",
            "price": "decimal(10,2)"
        },
        kind=dict(
            name=ModelKindName.SCD_TYPE_2_BY_COLUMN,
            unique_key=["product_id"],
            columns=["product_name", "category", "price"],
        ),
        grains=["product_id"],
        depends_on=["vulcan_demo.products"],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT product_id, name as product_name, category, price
        FROM vulcan_demo.products
        """
        return context.fetchdf(query)
    ```

Vulcan will materialize this table with the following structure:
```sql linenums="1"
TABLE db.menu_items (
  id INT,
  name STRING,
  price DOUBLE,
  valid_from TIMESTAMP,
  valid_to TIMESTAMP
);
```

### Change Column Names

Vulcan automatically adds `valid_from` and `valid_to` columns to your table. If you want different names (maybe to match your existing schema conventions), you can customize them:
```sql linenums="1" hl_lines="5-6"
MODEL (
  name db.menu_items,
  kind SCD_TYPE_2_BY_TIME (
    unique_key id,
    valid_from_name my_valid_from, -- Name for `valid_from` column
    valid_to_name my_valid_to -- Name for `valid_to` column
  )
);
```

Vulcan will materialize this table with the following structure:
```sql linenums="1"
TABLE db.menu_items (
  id INT,
  name STRING,
  price DOUBLE,
  updated_at TIMESTAMP,
  my_valid_from TIMESTAMP,
  my_valid_to TIMESTAMP
);
```

### Deletes

A "hard delete" is when a record disappears from your source table entirely. How should SCD Type 2 handle this?

**Default behavior (`invalidate_hard_deletes: false`):**

* `valid_to` column will continue to be set to `NULL` (therefore still considered "valid")
* If the record is added back, then the `valid_to` column will be set to the `valid_from` of the new record.

When a record is added back, the new record will be inserted into the table with `valid_from` set to:

* SCD_TYPE_2_BY_TIME: the largest of either the `updated_at` timestamp of the new record or the `valid_from` timestamp of the deleted record in the SCD Type 2 table
* SCD_TYPE_2_BY_COLUMN: the `execution_time` when the record was detected again

**With `invalidate_hard_deletes: true`:**

* `valid_to` is set to the execution time when Vulcan detected the missing record
* If the record comes back later, `valid_to` stays unchanged (you'll have a gap in history)

**Which should you use?**

- **`false` (default):** Missing records are still considered "valid" (no gaps in history). Use this if you think missing records might be temporary or if you prefer continuous history.

- **`true`:** Deletes are accurately tracked with precise timestamps. Use this if you want to know exactly when records were deleted, even if it creates gaps in history.

With `false`, missing records are still considered valid. With `true`, missing records are treated as deleted at that time.

### Example of SCD Type 2 By Time in Action

Let's walk through a real example. Say you're tracking a restaurant menu, and you start with this source data (with `invalidate_hard_deletes: true`):

| ID | Name             | Price |     Updated At      |
|----|------------------|:-----:|:-------------------:|
| 1  | Chicken Sandwich | 10.99 | 2020-01-01 00:00:00 |
| 2  | Cheeseburger     | 8.99  | 2020-01-01 00:00:00 |
| 3  | French Fries     | 4.99  | 2020-01-01 00:00:00 |

The target table, which is currently empty, will be materialized with the following data:

| ID | Name             | Price |     Updated At      |     Valid From      | Valid To |
|----|------------------|:-----:|:-------------------:|:-------------------:|:--------:|
| 1  | Chicken Sandwich | 10.99 | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 |   NULL   |
| 2  | Cheeseburger     | 8.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 |   NULL   |
| 3  | French Fries     | 4.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 |   NULL   |

Now lets say that you update the source table with the following data:

| ID | Name             | Price |     Updated At      |
|----|------------------|:-----:|:-------------------:|
| 1  | Chicken Sandwich | 12.99 | 2020-01-02 00:00:00 |
| 3  | French Fries     | 4.99  | 2020-01-01 00:00:00 |
| 4  | Milkshake        | 3.99  | 2020-01-02 00:00:00 |

Summary of Changes:

* The price of the Chicken Sandwich was increased from $10.99 to $12.99.
* Cheeseburger was removed from the menu.
* Milkshakes were added to the menu.

Assuming your models ran at `2020-01-02 11:00:00`, target table will be updated with the following data:

| ID | Name             | Price |     Updated At      |     Valid From      |      Valid To       |
|----|------------------|:-----:|:-------------------:|:-------------------:|:-------------------:|
| 1  | Chicken Sandwich | 10.99 | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 | 2020-01-02 00:00:00 |
| 1  | Chicken Sandwich | 12.99 | 2020-01-02 00:00:00 | 2020-01-02 00:00:00 |        NULL         |
| 2  | Cheeseburger     | 8.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 3  | French Fries     | 4.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 |        NULL         |
| 4  | Milkshake        | 3.99  | 2020-01-02 00:00:00 | 2020-01-02 00:00:00 |        NULL         |

For our final pass, lets say that you update the source table with the following data:

| ID | Name                | Price |     Updated At      |
|----|---------------------|:-----:|:-------------------:|
| 1  | Chicken Sandwich    | 14.99 | 2020-01-03 00:00:00 |
| 2  | Cheeseburger        | 8.99  | 2020-01-03 00:00:00 |
| 3  | French Fries        | 4.99  | 2020-01-01 00:00:00 |
| 4  | Chocolate Milkshake | 3.99  | 2020-01-02 00:00:00 |

Summary of changes:

* The price of the Chicken Sandwich was increased from $12.99 to $14.99 (must be good!)
* Cheeseburger was added back to the menu with original name and price.
* Milkshake name was updated to be "Chocolate Milkshake".

Target table will be updated with the following data:

| ID | Name                | Price |     Updated At      |     Valid From      |      Valid To       |
|----|---------------------|:-----:|:-------------------:|:-------------------:|:-------------------:|
| 1  | Chicken Sandwich    | 10.99 | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 | 2020-01-02 00:00:00 |
| 1  | Chicken Sandwich    | 12.99 | 2020-01-02 00:00:00 | 2020-01-02 00:00:00 | 2020-01-03 00:00:00 |
| 1  | Chicken Sandwich    | 14.99 | 2020-01-03 00:00:00 | 2020-01-03 00:00:00 |        NULL         |
| 2  | Cheeseburger        | 8.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 2  | Cheeseburger        | 8.99  | 2020-01-03 00:00:00 | 2020-01-03 00:00:00 |        NULL         |
| 3  | French Fries        | 4.99  | 2020-01-01 00:00:00 | 1970-01-01 00:00:00 |        NULL         |
| 4  | Milkshake           | 3.99  | 2020-01-02 00:00:00 | 2020-01-02 00:00:00 | 2020-01-03 00:00:00 |
| 4  | Chocolate Milkshake | 3.99  | 2020-01-03 00:00:00 | 2020-01-03 00:00:00 |        NULL         |

**Notice:** `Cheeseburger` was deleted from `2020-01-02 11:00:00` to `2020-01-03 00:00:00`. If you query the table for that time range, you won't see it, which accurately reflects that it wasn't on the menu during that period.

This is the most accurate representation based on your source data. If `Cheeseburger` had been added back with its original `updated_at` timestamp (`2020-01-01`), Vulcan would have set the new record's `valid_from` to `2020-01-02 11:00:00` (when it was detected again), filling the gap. But since the timestamp didn't change, it's likely the item was removed in error, and the gap accurately represents that.


### Example of SCD Type 2 By Column in Action

Now let's see how **By Column** works. Same restaurant menu example, but this time the source table doesn't have an `updated_at` column. We'll configure the model to watch `Name` and `Price` for changes.

Starting data:

| ID | Name             | Price |
|----|------------------|:-----:|
| 1  | Chicken Sandwich | 10.99 |
| 2  | Cheeseburger     | 8.99  |
| 3  | French Fries     | 4.99  |

After the first run, your SCD Type 2 table looks like this:

| ID | Name             | Price |     Valid From      | Valid To |
|----|------------------|:-----:|:-------------------:|:--------:|
| 1  | Chicken Sandwich | 10.99 | 1970-01-01 00:00:00 |   NULL   |
| 2  | Cheeseburger     | 8.99  | 1970-01-01 00:00:00 |   NULL   |
| 3  | French Fries     | 4.99  | 1970-01-01 00:00:00 |   NULL   |

Now lets say that you update the source table with the following data:

| ID | Name             | Price |
|----|------------------|:-----:|
| 1  | Chicken Sandwich | 12.99 |
| 3  | French Fries     | 4.99  |
| 4  | Milkshake        | 3.99  |

Summary of Changes:

* The price of the Chicken Sandwich was increased from $10.99 to $12.99.
* Cheeseburger was removed from the menu.
* Milkshakes were added to the menu.

Assuming your models ran at `2020-01-02 11:00:00`, target table will be updated with the following data:

| ID | Name             | Price |     Valid From      |      Valid To       |
|----|------------------|:-----:|:-------------------:|:-------------------:|
| 1  | Chicken Sandwich | 10.99 | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 1  | Chicken Sandwich | 12.99 | 2020-01-02 11:00:00 |        NULL         |
| 2  | Cheeseburger     | 8.99  | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 3  | French Fries     | 4.99  | 1970-01-01 00:00:00 |        NULL         |
| 4  | Milkshake        | 3.99  | 2020-01-02 11:00:00 |        NULL         |

For our final pass, lets say that you update the source table with the following data:

| ID | Name                | Price |
|----|---------------------|:-----:|
| 1  | Chicken Sandwich    | 14.99 |
| 2  | Cheeseburger        | 8.99  |
| 3  | French Fries        | 4.99  |
| 4  | Chocolate Milkshake | 3.99  |

Summary of changes:

* The price of the Chicken Sandwich was increased from $12.99 to $14.99 (must be good!)
* Cheeseburger was added back to the menu with original name and price.
* Milkshake name was updated to be "Chocolate Milkshake".

After running at `2020-01-03 11:00:00`, your final SCD Type 2 table:

| ID | Name                | Price |     Valid From      |      Valid To       |
|----|---------------------|:-----:|:-------------------:|:-------------------:|
| 1  | Chicken Sandwich    | 10.99 | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 1  | Chicken Sandwich    | 12.99 | 2020-01-02 11:00:00 | 2020-01-03 11:00:00 |
| 1  | Chicken Sandwich    | 14.99 | 2020-01-03 11:00:00 |        NULL         |
| 2  | Cheeseburger        | 8.99  | 1970-01-01 00:00:00 | 2020-01-02 11:00:00 |
| 2  | Cheeseburger        | 8.99  | 2020-01-03 11:00:00 |        NULL         |
| 3  | French Fries        | 4.99  | 1970-01-01 00:00:00 |        NULL         |
| 4  | Milkshake           | 3.99  | 2020-01-02 11:00:00 | 2020-01-03 11:00:00 |
| 4  | Chocolate Milkshake | 3.99  | 2020-01-03 11:00:00 |        NULL         |

**Notice:** `Cheeseburger` was deleted from `2020-01-02 11:00:00` to `2020-01-03 11:00:00`. Query the table for that time range, and you won't see it, which accurately reflects that it wasn't on the menu during that period.

### Shared Configuration Options

| Name                    | Description                                                                                                                                                                                                                                                                                                       | Type                      |
|-------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| unique_key              | Unique key used for identifying rows between source and target                                                                                                                                                                                                                                                    | List of strings or string |
| valid_from_name         | The name of the `valid_from` column to create in the target table. Default: `valid_from`                                                                                                                                                                                                                          | string                    |
| valid_to_name           | The name of the `valid_to` column to create in the target table. Default: `valid_to`                                                                                                                                                                                                                              | string                    |
| invalidate_hard_deletes | If set to `true`, when a record is missing from the source table it will be marked as invalid. Default: `false`                                                                                                                                                                                                   | bool                      |
| batch_size              | The maximum number of intervals that can be evaluated in a single backfill task. If this is `None`, all intervals will be processed as part of a single task. See [Processing Source Table with Historical Data](#processing-source-table-with-historical-data) for more info on this use case. (Default: `None`) | int                       |

!!! info "BigQuery Data Types"

    On BigQuery, `valid_from` and `valid_to` columns default to `DATETIME`. If you want `TIMESTAMP` instead, specify it in your model definition:

    ```sql linenums="1" hl_lines="5"
    MODEL (
      name db.menu_items,
      kind SCD_TYPE_2_BY_TIME (
        unique_key id,
        time_data_type TIMESTAMP
      )
    );
    ```

    This might work on other engines too, but it's only been tested on BigQuery.

### SCD Type 2 By Time Configuration Options

| Name                     | Description                                                                                                                                                                        | Type                      |
|--------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| updated_at_name          | The name of the column containing a timestamp to check for new or updated records. Default: `updated_at`                                                                           | string                    |
| updated_at_as_valid_from | By default, for new rows `valid_from` is set to `1970-01-01 00:00:00`. This changes the behavior to set it to the valid of `updated_at` when the row is inserted. Default: `false` | bool                      |

### SCD Type 2 By Column Configuration Options

| Name                         | Description                                                                                                                                                                                                                                                                                                                                  | Type                      |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| columns                      | The name of the columns to check for changes. `*` to represent that all columns should be checked.                                                                                                                                                                                                                                           | List of strings or string |
| execution_time_as_valid_from | By default, when the model is first loaded `valid_from` is set to `1970-01-01 00:00:00` and future new rows will have `execution_time` of when the models ran. This changes the behavior to always use `execution_time`. Default: `false`                                                                                                  | bool                      |
| updated_at_name              | If sourcing from a table that includes as timestamp to use as valid_from, set this property to that column. See [Processing Source Table with Historical Data](#processing-source-table-with-historical-data) for more info on this use case. (Default: `None`) | int                       |


### Processing Source Table with Historical Data

Most of the time, you're creating history for a table that doesn't have it. Like the restaurant menu, it just shows what's available now, but you want to track what was available over time. For this use case, leave `batch_size` as `None` (the default).

**But what if your source already has history?** Some systems create "daily snapshot" tables that contain historical records. If you're sourcing from one of these, set `batch_size` to `1` to process each interval sequentially (one day at a time if you're using `@daily` cron).

**Why sequential?** SCD Type 2 needs to compare each day's snapshot to the previous day to detect changes. Processing them in order ensures the history is captured correctly.

#### Example - Source from Daily Snapshot Table

```sql linenums="1"
MODEL (
    name db.table,
    kind SCD_TYPE_2_BY_COLUMN (
        unique_key id,
        columns [some_value],
        updated_at_name ds,
        batch_size 1
    ),
    start '2025-01-01',
    cron '@daily'
);
SELECT
    id,
    some_value,
    ds
FROM
    source_table
WHERE
    ds between @start_ds and @end_ds
```

This processes each day sequentially, checking if `some_value` changed. When a change is detected, `valid_from` is set to match the `ds` column value (except for the very first record, which gets `1970-01-01 00:00:00`).

If the source data was the following:

| id | some_value |     ds      |
|----|------------|:-----------:|
| 1  | 1          | 2025-01-01  |
| 1  | 2          | 2025-01-02  |
| 1  | 3          | 2025-01-03  |
| 1  | 3          | 2025-01-04  |

Then the resulting SCD Type 2 table would be:

| id | some_value |     ds      |     valid_from      |      valid_to       |
|----|------------|:-----------:|:-------------------:|:-------------------:|
| 1  | 1          | 2025-01-01  | 1970-01-01 00:00:00 | 2025-01-02 00:00:00 |
| 1  | 2          | 2025-01-02  | 2025-01-02 00:00:00 | 2025-01-03 00:00:00 |
| 1  | 3          | 2025-01-03  | 2025-01-03 00:00:00 |        NULL         |

### Querying SCD Type 2 Models

Even though SCD Type 2 models track history, querying the current version is still simple. Here are some common patterns:

#### Querying the Current Version

Want just the latest version of each record? Filter for `valid_to IS NULL`:

```sql linenums="1"
SELECT
  *
FROM
  menu_items
WHERE
  valid_to IS NULL;
```

You can also create a view that adds an `is_current` flag to make it even easier for downstream consumers:

```sql linenums="1"
SELECT
  *,
  valid_to IS NULL AS is_current
FROM
  menu_items;
```

#### Querying for a Specific Point in Time

Want to see what the menu looked like on a specific date? Filter by `valid_from` and `valid_to`:

```sql linenums="1"
SELECT
  *
FROM
  menu_items
WHERE
  id = 1
  AND '2020-01-02 01:00:00' >= valid_from
  AND '2020-01-02 01:00:00' < COALESCE(valid_to, CAST('2199-12-31 23:59:59+00:00' AS TIMESTAMP));
```

Here's how you'd use it in a join (to get the menu item price that was valid when an order was placed):

```sql linenums="1"
SELECT
  *
FROM
  orders
INNER JOIN
  menu_items
  ON orders.menu_item_id = menu_items.id
  AND orders.created_at >= menu_items.valid_from
  AND orders.created_at < COALESCE(menu_items.valid_to, CAST('2199-12-31 23:59:59+00:00' AS TIMESTAMP));
```

You can create a view that handles the `COALESCE` automatically, making point-in-time queries even easier:

```sql linenums="1"
SELECT
  id,
  name,
  price,
  updated_at,
  valid_from,
  COALESCE(valid_to, CAST('2199-12-31 23:59:59+00:00' AS TIMESTAMP)) AS valid_to
  valid_to IS NULL AS is_current,
FROM
  menu_items;
```

Want to make `valid_to` inclusive so users can use `BETWEEN`? Adjust it like this:
```sql linenums="1"
SELECT
  id,
  name,
  price,
  updated_at,
  valid_from,
  COALESCE(valid_to, CAST('2200-01-01 00:00:00+00:00' AS TIMESTAMP)) - INTERVAL 1 SECOND AS valid_to
  valid_to IS NULL AS is_current,
```

!!! note "Timestamp Precision"

    This example uses second precision, so we subtract 1 second. Adjust the subtraction based on your timestamp precision (milliseconds, microseconds, etc.).

#### Querying for Deleted Records

To find records that were deleted, query for IDs that don't have a current version (`valid_to IS NULL`). Here's how:

```sql linenums="1"
SELECT
  id,
  MAX(CASE WHEN valid_to IS NULL THEN 0 ELSE 1 END) AS is_deleted
FROM
  menu_items
GROUP BY
  id
```

### Reset SCD Type 2 Model (Clearing History)

By default, SCD Type 2 models protect your history, once it's gone, you can't recreate it. But sometimes you need to start fresh (maybe you're fixing a bug, or the history got corrupted).

**Warning:** This will delete all historical data. Make sure you really want to do this!

To reset history, follow these steps:

```sql linenums="1" hl_lines="5"
MODEL (
  name db.menu_items,
  kind SCD_TYPE_2_BY_TIME (
    unique_key id,
    disable_restatement false
  )
);
```

Plan/apply this change to production.
Then you will want to [restate the model](../../guides/plan_guide.md#restatement-plans-restate-model).

!!! warning "Data Loss Warning"

    This will permanently remove all historical data. In most cases, you cannot recover it. Make absolutely sure this is what you want!

4. Once complete, remove `disable_restatement` from your model definition (sets it back to `true`) to prevent accidental data loss in the future

```sql linenums="1"
MODEL (
  name db.menu_items,
  kind SCD_TYPE_2_BY_TIME (
    unique_key id,
  )
);
```

5. Plan and apply this change to production

## EXTERNAL

The EXTERNAL model kind is used to specify [external models](./types/external_models.md) that store metadata about external tables. External models are special; they are not specified in .sql files like the other model kinds. They are optional but useful for propagating column and type information for external tables queried in your Vulcan project.

## MANAGED

!!! warning

    Managed models are still under development and the API / semantics may change as support for more engines is added

**Note:** Python models do not support the `MANAGED` model kind - use a SQL model instead.

The `MANAGED` model kind is used to create models where the underlying database engine manages the data lifecycle.

These models don't get updated with new intervals or refreshed when `vulcan run` is called. Responsibility for keeping the *data* up to date falls on the engine.

You can control how the engine creates the managed model by using the [`physical_properties`](./properties.md#physical_properties) to pass engine-specific parameters for adapter to use when issuing commands to the underlying database.

Due to there being no standard, each vendor has a different implementation with different semantics and different configuration parameters. Therefore, `MANAGED` models are not as portable between database engines as other Vulcan model types. In addition, due to their black-box nature, Vulcan has limited visibility into the integrity and state of the model.

We would recommend using standard Vulcan model types in the first instance. However, if you do need to use Managed models, you still gain other Vulcan benefits like the ability to use them in [virtual environments](../../guides/plan_guide.md#physical-tables-virtual-layer-and-environments).

See [Managed Models](./types/managed_models.md) for more information on which engines are supported and which properties are available.

## INCREMENTAL_BY_PARTITION

Models of the `INCREMENTAL_BY_PARTITION` kind are computed incrementally based on partition. A set of columns defines the model's partitioning key, and a partition is the group of rows with the same partitioning key value.

!!! question "Should you use this model kind?"

    Any model kind can use a partitioned **table** by specifying the [`partitioned_by` key](./properties.md#partitioned_by) in the `MODEL` DDL.

    The "partition" in `INCREMENTAL_BY_PARTITION` is about how the data is **loaded** when the model runs.

    `INCREMENTAL_BY_PARTITION` models are inherently [non-idempotent](../../glossary.md#execution-terms), so restatements and other actions can cause data loss. This makes them more complex to manage than other model kinds.

    In most scenarios, an `INCREMENTAL_BY_TIME_RANGE` model can meet your needs and will be easier to manage. The `INCREMENTAL_BY_PARTITION` model kind should only be used when the data must be loaded by partition (usually for performance reasons).

This model kind is designed for the scenario where data rows should be loaded and updated as a group based on their shared value for the partitioning key.

It may be used with any SQL engine. Vulcan will automatically create partitioned tables on engines that support explicit table partitioning (e.g., [BigQuery](https://cloud.google.com/bigquery/docs/creating-partitioned-tables), [Databricks](https://docs.databricks.com/en/sql/language-manual/sql-ref-partition.html)).

New rows are loaded based on their partitioning key value:

- If a partitioning key in newly loaded data is not present in the model table, the new partitioning key and its data rows are inserted.

- If a partitioning key in newly loaded data is already present in the model table, **all the partitioning key's existing data rows in the model table are replaced** with the partitioning key's data rows in the newly loaded data.

- If a partitioning key is present in the model table but not present in the newly loaded data, the partitioning key's existing data rows are not modified and remain in the model table.

This kind should only be used for datasets that have the following traits:

* The dataset's records can be grouped by a partitioning key.
* Each record has a partitioning key associated with it.
* It is appropriate to upsert records, so existing records can be overwritten by new arrivals when their partitioning keys match.
* All existing records associated with a given partitioning key can be removed or overwritten when any new record has the partitioning key value.

The column defining the partitioning key is specified in the model's `MODEL` DDL `partitioned_by` key. This example shows the `MODEL` DDL for an `INCREMENTAL_BY_PARTITION` model:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name vulcan_demo.partition,
      kind INCREMENTAL_BY_PARTITION,
      partitioned_by ARRAY[warehouse_id, category],
      grains (partitioned_analysis_key)
    );

    SELECT
      w.warehouse_id,
      w.name AS warehouse_name,
      p.category,
      o.order_date,
      CONCAT(w.warehouse_id::TEXT, '_', p.category, '_', o.order_date::TEXT) AS partitioned_analysis_key,
      COUNT(DISTINCT o.order_id) AS total_transactions,
      SUM(oi.quantity * oi.unit_price) AS total_sales_amount,
      COUNT(DISTINCT o.customer_id) AS unique_customers
    FROM vulcan_demo.orders AS o
    JOIN vulcan_demo.order_items AS oi ON o.order_id = oi.order_id
    JOIN vulcan_demo.products AS p ON oi.product_id = p.product_id
    JOIN vulcan_demo.warehouses AS w ON o.warehouse_id = w.warehouse_id
    GROUP BY w.warehouse_id, w.name, p.category, o.order_date
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "vulcan_demo.partition_py",
        columns={
            "warehouse_id": "int",
            "order_date": "date",
            "daily_revenue": "decimal(10,2)",
        },
        partitioned_by=["warehouse_id"],
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_PARTITION,
        ),
        grains=["warehouse_id", "order_date"],
        depends_on=["vulcan_demo.orders", "vulcan_demo.order_items"],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT o.warehouse_id, o.order_date,
               SUM(oi.quantity * oi.unit_price) as daily_revenue
        FROM vulcan_demo.orders o
        JOIN vulcan_demo.order_items oi ON o.order_id = oi.order_id
        GROUP BY o.warehouse_id, o.order_date
        """
        return context.fetchdf(query)
    ```

You can use multiple columns for composite partition keys:

```sql linenums="1"
MODEL (
  name vulcan_demo.events,
  kind INCREMENTAL_BY_PARTITION,
  partitioned_by (warehouse_id, category)
);
```

Some engines support expression-based partitioning. Here's a BigQuery example that partitions by month:

```sql linenums="1"
MODEL (
  name vulcan_demo.events,
  kind INCREMENTAL_BY_PARTITION,
  partitioned_by DATETIME_TRUNC(order_date, MONTH)
);
```

!!! warning "Only Full Restatements Supported"

    Partial data [restatements](../../guides/plan_guide.md#restatement-plans) are used to reprocess part of a table's data (usually a limited time range).

    Partial data restatement is not supported for `INCREMENTAL_BY_PARTITION` models. If you restate an `INCREMENTAL_BY_PARTITION` model, its entire table will be recreated from scratch.

    Restating `INCREMENTAL_BY_PARTITION` models may lead to data loss and should be performed with care.

### Example

Here's a practical example that shows how to limit which partitions get updated using a CTE. This is a common pattern to avoid full restatements:

```sql linenums="1"
MODEL (
  name demo.incremental_by_partition_demo,
  kind INCREMENTAL_BY_PARTITION,
  partitioned_by user_segment,
);

-- This is the source of truth for what partitions need to be updated and will join to the product usage data

-- This could be an INCREMENTAL_BY_TIME_RANGE model that reads in the user_segment values last updated in the past 30 days to reduce scope

-- Use this strategy to reduce full restatements
WITH partitions_to_update AS (
  SELECT DISTINCT
    user_segment
  FROM demo.incremental_by_time_range_demo  -- upstream table tracking which user segments to update
  WHERE last_updated_at BETWEEN DATE_SUB(@start_dt, INTERVAL 30 DAY) AND @end_dt
),

product_usage AS (
  SELECT
    product_id,
    customer_id,
    last_usage_date,
    usage_count,
    feature_utilization_score,
    user_segment
  FROM vulcan-public-demo.tcloud_raw_data.product_usage
  WHERE user_segment IN (SELECT user_segment FROM partitions_to_update) -- partition filter applied here
)

SELECT
  product_id,
  customer_id,
  last_usage_date,
  usage_count,
  feature_utilization_score,
  user_segment,
  CASE
    WHEN usage_count > 100 AND feature_utilization_score > 0.7 THEN 'Power User'
    WHEN usage_count > 50 THEN 'Regular User'
    WHEN usage_count IS NULL THEN 'New User'
    ELSE 'Light User'
  END as user_type
FROM product_usage
```

**Note**: Partial data [restatement](../../guides/plan_guide.md#restatement-plans-restate-model) is not supported for this model kind, which means that the entire table will be recreated from scratch if restated. This may lead to data loss.

### Materialization strategy
Depending on the target engine, models of the `INCREMENTAL_BY_PARTITION` kind are materialized using the following strategies:

| Engine     | Strategy                                |
|------------|-----------------------------------------|
| Databricks | REPLACE WHERE by partitioning key       |
| Spark      | INSERT OVERWRITE by partitioning key    |
| Snowflake  | DELETE by partitioning key, then INSERT |
| BigQuery   | DELETE by partitioning key, then INSERT |
| Redshift   | DELETE by partitioning key, then INSERT |
| Postgres   | DELETE by partitioning key, then INSERT |
| DuckDB     | DELETE by partitioning key, then INSERT |

## INCREMENTAL_UNMANAGED

`INCREMENTAL_UNMANAGED` models are for append-only tables. They're "unmanaged" because Vulcan doesn't try to deduplicate or manage the data, it just runs your query and appends whatever it gets to the table.

**How it works:** Every time the model runs, Vulcan executes your query and appends the results to the table. No deduplication, no updates, no deletes, just append, append, append.

!!! question "Should You Use This?"

    **Use it for:** Data Vault patterns, event logs, audit trails, or any scenario where you need true append-only behavior.

    **Don't use it for:** Most other cases. `INCREMENTAL_BY_TIME_RANGE` or `INCREMENTAL_BY_UNIQUE_KEY` give you much more control and are usually better choices.

**When to use:**

- Data Vault hubs, links, or satellites

- Event logs where every event should be preserved

- Audit trails

- Any pattern that requires true append-only semantics

Here's how you'd set one up:

```sql linenums="1"
MODEL (
  name vulcan_demo.incremental_unmanaged,
  kind INCREMENTAL_UNMANAGED,
  cron '@daily',
  start '2025-01-01',
  grains (shipment_id)
);

/* Append-only shipment event log */
SELECT
  s.shipment_id,
  s.order_id,
  s.shipped_date,
  s.carrier,
  o.customer_id,
  c.name AS customer_name,
  o.order_date,
  (s.shipped_date - o.order_date::DATE)::INT AS days_to_ship,
  CURRENT_TIMESTAMP AS shipment_event_timestamp
FROM vulcan_demo.shipments AS s
JOIN vulcan_demo.orders AS o ON s.order_id = o.order_id
JOIN vulcan_demo.customers AS c ON o.customer_id = c.customer_id
ORDER BY s.shipped_date DESC
```

**Note:** Since it's unmanaged, `INCREMENTAL_UNMANAGED` doesn't support `batch_size` or `batch_concurrency` properties. Vulcan just runs your query and appends the results, no batching or concurrency control.

!!! warning "Only Full Restatements Supported"

    Similar to `INCREMENTAL_BY_PARTITION`, attempting to [restate](../../guides/plan_guide.md#restatement-plans) an `INCREMENTAL_UNMANAGED` model will trigger a full restatement. That is, the model will be rebuilt from scratch rather than from a time slice you specify.

    Be very careful when restating these models!
