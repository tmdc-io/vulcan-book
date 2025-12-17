# Statements

Statements are auxiliary SQL commands that extend a model's capabilities beyond its main query. They allow you to execute custom logic at specific points during model execution—before the query runs (pre-statements), after the query completes (post-statements), or when views are created/updated (on-virtual-update). Common use cases include setting session parameters, loading UDFs, creating indexes, enforcing data quality checks, logging anomalies, and granting access permissions. Statements can be defined at the model level for specific needs or at the project level via `model_defaults` for consistent behavior across all models.

**Statement types:**

- **Pre-statements**: Run before the main model query
- **Post-statements**: Run after the main model query
- **On-virtual-update statements**: Run when a virtual update occurs (view creation/update)

!!! warning "Concurrency considerations"

    Pre-statements should generally only be used for preparing the main query. Avoid creating or altering physical tables in pre-statements, as this could lead to unpredictable behavior if multiple models run concurrently.

## Model defaults

You can define statements at the project level using `model_defaults` in your configuration. These default statements are merged with any model-specific statements, with **default statements executing first**, followed by model-specific statements.

=== "YAML"

    ```yaml linenums="1"
    model_defaults:
      dialect: snowflake
      pre_statements:
        - "SET query_timeout = 300000"
      post_statements:
        - "@IF(@runtime_stage = 'evaluating', ANALYZE @this_model)"
      on_virtual_update:
        - "GRANT SELECT ON @this_model TO ROLE analyst_role"
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, ModelDefaultsConfig

    config = Config(
      model_defaults=ModelDefaultsConfig(
        dialect="snowflake",
        pre_statements=[
          "SET query_timeout = 300000",
        ],
        post_statements=[
          "@IF(@runtime_stage = 'evaluating', ANALYZE @this_model)",
        ],
        on_virtual_update=[
          "GRANT SELECT ON @this_model TO ROLE analyst_role",
        ],
      ),
    )
    ```

## Pre-statements

Pre-statements run before the main model query. They are useful for:

- Loading JARs or UDFs
- Creating temporary tables or caching data
- Setting session parameters
- Initializing variables

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name analytics.orders,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column order_date
      ),
      start '2020-01-01',
      cron '@daily'
    );

    /* Pre-statement: Create table for anomaly tracking */
    CREATE TABLE IF NOT EXISTS analytics._orders_anomalies (
      anomaly_id BIGINT GENERATED ALWAYS AS IDENTITY,
      order_id VARCHAR,
      anomaly_type VARCHAR,
      details VARCHAR,
      captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    /* Pre-statement: Set session variables using Jinja */
    JINJA_STATEMENT_BEGIN;
    {% if start_date is none or end_date is none %}
      SET start_date = DATE '{{ start }}';
      SET end_date = CURRENT_DATE;
    {% endif %}
    JINJA_END;

    /* Main model query */
    SELECT
      order_id::VARCHAR AS order_id,
      order_date::DATE AS order_date,
      customer_id::VARCHAR AS customer_id,
      total_amount::FLOAT AS total_amount
    FROM demo.raw_data.orders
    WHERE
      order_date BETWEEN @start_date AND @end_date;
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName
    from sqlglot import exp

    @model(
        "analytics.orders_py",
        columns={
            "order_id": "varchar",
            "order_date": "date",
            "customer_id": "varchar",
            "total_amount": "float",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="order_date",
        ),
        pre_statements=[
            "SET query_timeout = 300000",
            """CREATE TABLE IF NOT EXISTS analytics._orders_anomalies (
                anomaly_id BIGINT GENERATED ALWAYS AS IDENTITY,
                order_id VARCHAR,
                anomaly_type VARCHAR,
                details VARCHAR
            )""",
            exp.Cache(this=exp.table_("orders_cache"), expression=exp.select("*").from_("demo.raw_data.orders")),
        ],
    )
    def execute(context: ExecutionContext, start, end, **kwargs):
        query = f"""
        SELECT order_id, order_date, customer_id, total_amount
        FROM demo.raw_data.orders
        WHERE order_date BETWEEN '{start.date()}' AND '{end.date()}'
        """
        return context.fetchdf(query)
    ```

## Post-statements

Post-statements run after each evaluation of the model query. The model query **must end with a semicolon** when post-statements are present in SQL models.

Post-statements are useful for:

- Creating indexes or clustering
- Running data quality checks
- Inserting anomalies into tracking tables
- Conditional table alterations

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name analytics.orders,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column order_date
      )
    );

    SELECT
      order_id,
      order_date,
      customer_id,
      quantity,
      unit_price,
      total_amount
    FROM demo.raw_data.orders
    WHERE
      order_date BETWEEN @start_date AND @end_date;

    /* Post-statement: Conditional retention policy (only on table creation) */
    @IF(
      @runtime_stage IN ('creating'),
      ALTER TABLE @this_model SET DATA_RETENTION_TIME_IN_DAYS = 30
    );

    /* Post-statement: Add clustering for query performance */
    ALTER TABLE @this_model CLUSTER BY (order_date, customer_id);

    /* Post-statement: Capture data anomalies - negative quantities */
    INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
    SELECT
      order_id,
      'NEGATIVE_QUANTITY',
      CONCAT('Quantity=', quantity)
    FROM @this_model
    WHERE quantity < 0;

    /* Post-statement: Capture data anomalies - total mismatch */
    INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
    SELECT
      order_id,
      'TOTAL_MISMATCH',
      CONCAT(
        'calculated=', ROUND(unit_price * quantity, 2),
        '; actual=', ROUND(total_amount, 2)
      )
    FROM @this_model
    WHERE ABS((unit_price * quantity) - total_amount) > 0.01;
    ```

=== "Python"

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "analytics.orders_py",
        columns={
            "order_id": "varchar",
            "order_date": "date",
            "customer_id": "varchar",
            "total_amount": "float",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="order_date",
        ),
        post_statements=[
            "@IF(@runtime_stage = 'creating', ALTER TABLE @this_model SET DATA_RETENTION_TIME_IN_DAYS = 30)",
            "ALTER TABLE @this_model CLUSTER BY (order_date, customer_id)",
            """INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
               SELECT order_id, 'NEGATIVE_QUANTITY', CONCAT('Quantity=', quantity)
               FROM @this_model WHERE quantity < 0""",
        ],
    )
    def execute(context: ExecutionContext, start, end, **kwargs):
        query = f"""
        SELECT order_id, order_date, customer_id, total_amount
        FROM demo.raw_data.orders
        WHERE order_date BETWEEN '{start.date()}' AND '{end.date()}'
        """
        return context.fetchdf(query)
    ```

## On-virtual-update statements

On-virtual-update statements run when a virtual update occurs (when views are created or updated). They are useful for:

- Granting permissions on views
- Setting up access controls
- Applying column masking policies

=== "SQL"

    Use `ON_VIRTUAL_UPDATE_BEGIN` and `ON_VIRTUAL_UPDATE_END` to define these statements:

    ```sql linenums="1"
    MODEL (
      name analytics.customers,
      kind INCREMENTAL_BY_UNIQUE_KEY (
        unique_key customer_id
      )
    );

    SELECT
      customer_id,
      full_name,
      email,
      customer_segment
    FROM demo.raw_data.customers;

    /* Post-statement: Apply masking policy */
    JINJA_STATEMENT_BEGIN;
    ALTER TABLE {{ this_model }} MODIFY COLUMN email SET MASKING POLICY demo.security.mask_email_policy;
    JINJA_END;

    /* On-virtual-update: Grant permissions when view is created/updated */
    ON_VIRTUAL_UPDATE_BEGIN;
    JINJA_STATEMENT_BEGIN;
    GRANT SELECT ON VIEW {{ this_model }} TO ROLE view_only_role;
    JINJA_END;
    ON_VIRTUAL_UPDATE_END;
    ```

=== "Python"

    Use the `on_virtual_update` argument in the `@model` decorator:

    ```python linenums="1"
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName

    @model(
        "analytics.customers_py",
        columns={
            "customer_id": "varchar",
            "full_name": "varchar",
            "email": "varchar",
            "customer_segment": "varchar",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_UNIQUE_KEY,
            unique_key=["customer_id"],
        ),
        post_statements=[
            "@IF(@runtime_stage = 'creating', ALTER TABLE @this_model SET DATA_RETENTION_TIME_IN_DAYS = 7)",
        ],
        on_virtual_update=[
            "GRANT SELECT ON @this_model TO ROLE view_only_role",
        ],
    )
    def execute(context: ExecutionContext, **kwargs):
        query = """
        SELECT customer_id, CONCAT(first_name, ' ', last_name) AS full_name,
               email, customer_segment
        FROM demo.raw_data.customers
        """
        return context.fetchdf(query)
    ```

## Complete example

Here's a complete example showing all statement types:

=== "SQL"

    ```sql linenums="1"
    MODEL (
      name analytics.orders,
      kind INCREMENTAL_BY_TIME_RANGE (
        time_column order_date
      ),
      start '2020-01-01',
      cron '@daily',
      grains (order_id),
      description 'Orders fact table with incremental loading'
    );

    /* ============ PRE-STATEMENTS ============ */

    /* Create anomaly tracking table */
    CREATE TABLE IF NOT EXISTS analytics._orders_anomalies (
      anomaly_id BIGINT GENERATED ALWAYS AS IDENTITY,
      order_id VARCHAR,
      anomaly_type VARCHAR,
      details VARCHAR,
      captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    /* ============ MAIN QUERY ============ */

    SELECT
      order_id::VARCHAR AS order_id,
      order_date::DATE AS order_date,
      customer_id::VARCHAR AS customer_id,
      product_id::VARCHAR AS product_id,
      quantity::INT AS quantity,
      unit_price::FLOAT AS unit_price,
      discount::FLOAT AS discount,
      tax::FLOAT AS tax,
      shipping_cost::FLOAT AS shipping_cost,
      total_amount::FLOAT AS total_amount
    FROM demo.raw_data.orders
    WHERE
      order_date BETWEEN @start_date AND @end_date;

    /* ============ POST-STATEMENTS ============ */

    /* Conditional: Set retention only on table creation */
    @IF(
      @runtime_stage IN ('creating'),
      ALTER TABLE @this_model SET DATA_RETENTION_TIME_IN_DAYS = 30
    );

    /* Add clustering for performance */
    ALTER TABLE @this_model CLUSTER BY (order_date, customer_id);

    /* Data quality: Log negative quantities */
    INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
    SELECT order_id, 'NEGATIVE_QUANTITY', CONCAT('Quantity=', quantity)
    FROM @this_model
    WHERE quantity < 0;

    /* Data quality: Log total mismatches */
    INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
    SELECT
      order_id,
      'TOTAL_MISMATCH',
      CONCAT(
        'calc=', ROUND(unit_price * quantity * (1 - COALESCE(discount, 0)) + COALESCE(tax, 0) + COALESCE(shipping_cost, 0), 2),
        '; total=', ROUND(total_amount, 2)
      )
    FROM @this_model
    WHERE ABS(
      (unit_price * quantity * (1 - COALESCE(discount, 0)) + COALESCE(tax, 0) + COALESCE(shipping_cost, 0))
      - total_amount
    ) > 0.01;

    /* ============ ON-VIRTUAL-UPDATE ============ */

    ON_VIRTUAL_UPDATE_BEGIN;
    JINJA_STATEMENT_BEGIN;
    GRANT SELECT ON VIEW {{ this_model }} TO ROLE view_only_role;
    JINJA_END;
    ON_VIRTUAL_UPDATE_END;
    ```

=== "Python"

    ```python linenums="1"
    import typing as t
    import pandas as pd
    from datetime import datetime
    from vulcan import ExecutionContext, model
    from vulcan import ModelKindName
    from sqlglot import exp

    @model(
        "analytics.orders_py",
        columns={
            "order_id": "varchar",
            "order_date": "date",
            "customer_id": "varchar",
            "product_id": "varchar",
            "quantity": "int",
            "unit_price": "float",
            "discount": "float",
            "tax": "float",
            "shipping_cost": "float",
            "total_amount": "float",
        },
        kind=dict(
            name=ModelKindName.INCREMENTAL_BY_TIME_RANGE,
            time_column="order_date",
        ),
        grains=["order_id"],
        depends_on=["demo.raw_data.orders"],
        description="Orders fact table with incremental loading",
        pre_statements=[
            """CREATE TABLE IF NOT EXISTS analytics._orders_anomalies (
                anomaly_id BIGINT GENERATED ALWAYS AS IDENTITY,
                order_id VARCHAR,
                anomaly_type VARCHAR,
                details VARCHAR,
                captured_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )""",
        ],
        post_statements=[
            "@IF(@runtime_stage = 'creating', ALTER TABLE @this_model SET DATA_RETENTION_TIME_IN_DAYS = 30)",
            "ALTER TABLE @this_model CLUSTER BY (order_date, customer_id)",
            """INSERT INTO analytics._orders_anomalies (order_id, anomaly_type, details)
               SELECT order_id, 'NEGATIVE_QUANTITY', CONCAT('Quantity=', quantity)
               FROM @this_model WHERE quantity < 0""",
        ],
        on_virtual_update=[
            "GRANT SELECT ON @this_model TO ROLE view_only_role",
        ],
    )
    def execute(
        context: ExecutionContext,
        start: datetime,
        end: datetime,
        execution_time: datetime,
        **kwargs: t.Any,
    ) -> pd.DataFrame:
        query = f"""
        SELECT
            order_id, order_date, customer_id, product_id,
            quantity, unit_price, discount, tax, shipping_cost, total_amount
        FROM demo.raw_data.orders
        WHERE order_date BETWEEN '{start.date()}' AND '{end.date()}'
        """
        return context.fetchdf(query)
    ```

## Useful macros and variables

| Macro/Variable | Description |
|----------------|-------------|
| `@this_model` | References the current model's table/view |
| `@runtime_stage` | Current execution stage: `'creating'`, `'evaluating'`, or `'testing'` |
| `@IF(condition, statement)` | Conditionally execute a statement |
| `@start_date`, `@end_date` | Time range macros for incremental models |
| `{{ this_model }}` | Jinja equivalent of `@this_model` |

For more information on macros, see the [Macro Variables](../advanced-features/macros/variables.md) documentation.
