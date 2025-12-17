# Testing

Testing is a critical practice in data engineering that ensures your data transformations produce correct, reliable results. Just as software engineers write unit tests to verify code behavior, data practitioners use tests to validate that models transform data as expected—catching bugs before they reach production and preventing costly data quality issues.

## Why testing matters

Data pipelines are complex systems where small errors can cascade into significant business impacts. Testing provides several key benefits:

- **Regression prevention**: Catch breaking changes before they affect downstream consumers
- **Confidence in changes**: Refactor models knowing that tests will flag unintended behavior changes
- **Documentation**: Tests serve as executable specifications of expected model behavior
- **Faster debugging**: When something breaks, tests help pinpoint the exact transformation that failed
- **Data quality assurance**: Verify that aggregations, joins, and calculations produce correct results

Unlike [audits](audits.md) which validate data quality at runtime, tests verify the *logic* of your models against predefined inputs and expected outputs. Tests run either on demand (e.g., in CI/CD pipelines) or automatically when creating a new [plan](plans.md).

## Creating tests

A test suite is a [YAML file](https://learnxinyminutes.com/docs/yaml/) in the `tests/` folder of your Vulcan project. The filename must begin with `test` and end with `.yaml` or `.yml`. Each file can contain multiple uniquely named unit tests.

At minimum, a unit test must specify:

- **model**: The model being tested
- **inputs**: Mock data for upstream dependencies
- **outputs**: Expected results from the model's query

### Basic example

Consider this `sales.daily_sales` model that aggregates orders by date:

```sql linenums="1"
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date
);

SELECT
  CAST(order_date AS TIMESTAMP) AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
GROUP BY order_date
ORDER BY order_date
```

Here's a test that verifies the aggregation logic:

```yaml linenums="1"
test_daily_sales_aggregation:
  model: sales.daily_sales
  description: >
    Test that daily_sales correctly aggregates orders by date.

  inputs:
    raw.raw_orders:
      rows:
        - order_id: O001
          order_date: '2024-03-15'
          customer_id: C001
          product_id: P001
          total_amount: 50.00
        - order_id: O002
          order_date: '2024-03-15'
          customer_id: C002
          product_id: P002
          total_amount: 75.00
        - order_id: O003
          order_date: '2024-03-16'
          customer_id: C001
          product_id: P003
          total_amount: 100.00

  outputs:
    query:
      rows:
        - order_date: "2024-03-15"
          total_orders: 2
          total_revenue: 125.00
          last_order_id: "O002"
        - order_date: "2024-03-16"
          total_orders: 1
          total_revenue: 100.00
          last_order_id: "O003"
```

This test provides three input orders (two on March 15, one on March 16) and verifies that:

- Orders are correctly grouped by date
- `total_orders` counts distinct orders per day
- `total_revenue` sums the amounts correctly
- `last_order_id` returns the maximum order ID per day

### Testing models with multiple dependencies

Real-world models often join multiple tables. Here's a test for a customer summary model that joins customers, orders, and order items:

```yaml linenums="1"
test_full_model_basic:
  model: vulcan_demo.full_model
  description: |
    Validates aggregates and averages:
    - DISTINCT order counting
    - SUM(quantity * unit_price)
    - avg_order_value = total_spent / total_orders, or NULL when total_orders = 0

  inputs:
    vulcan_demo.customers:
      - customer_id: 1
        name: Alice
        email: alice@example.com
      - customer_id: 2
        name: Bob
        email: bob@example.com
      - customer_id: 3
        name: Charlie
        email: charlie@example.com

    vulcan_demo.orders:
      # Alice has 2 orders
      - order_id: 1001
        customer_id: 1
      - order_id: 1002
        customer_id: 1
      # Bob has 1 order
      - order_id: 2001
        customer_id: 2
      # Charlie has 0 orders (no rows)

    vulcan_demo.order_items:
      # Order 1001: 2*50 + 1*25 = 125
      - order_id: 1001
        product_id: 501
        quantity: 2
        unit_price: 50
      - order_id: 1001
        product_id: 502
        quantity: 1
        unit_price: 25
      # Order 1002: 1*200 = 200 → Alice total = 325
      - order_id: 1002
        product_id: 503
        quantity: 1
        unit_price: 200
      # Order 2001: 2*5 = 10 → Bob total = 10
      - order_id: 2001
        product_id: 504
        quantity: 2
        unit_price: 5

  outputs:
    query:
      rows:
        - customer_id: 1
          customer_name: Alice
          email: alice@example.com
          total_orders: 2
          total_spent: 325
          avg_order_value: 162.5
        - customer_id: 2
          customer_name: Bob
          email: bob@example.com
          total_orders: 1
          total_spent: 10
          avg_order_value: 10.0
        - customer_id: 3
          customer_name: Charlie
          email: charlie@example.com
          total_orders: 0
          total_spent: 0
          avg_order_value: null  # Division by zero handled
```

### Testing incremental models

Incremental models require special attention because they filter data by time range. Use the `vars` attribute to set `start` and `end` dates:

```yaml linenums="1"
test_incremental_by_time_range_basic:
  model: vulcan_demo.incremental_by_time_range
  description: |
    Validates per-(order_date, product_id) aggregates over a fixed two-day window.
    Checks DISTINCT order counts, quantity and revenue sums, and AVG(unit_price).
  vars:
    start: '2025-01-01'
    end: '2025-01-02'

  inputs:
    vulcan_demo.products:
      - product_id: 10
        name: Widget
        category: Electronics
      - product_id: 20
        name: Gizmo
        category: Home

    vulcan_demo.orders:
      - order_id: 1001
        customer_id: 9001
        warehouse_id: 1
        order_date: '2025-01-01'
      - order_id: 1002
        customer_id: 9002
        warehouse_id: 1
        order_date: '2025-01-01'
      - order_id: 1003
        customer_id: 9003
        warehouse_id: 2
        order_date: '2025-01-02'

    vulcan_demo.order_items:
      # 2025-01-01
      - order_id: 1001
        product_id: 10
        quantity: 2
        unit_price: 50
      - order_id: 1001
        product_id: 20
        quantity: 1
        unit_price: 200
      - order_id: 1002
        product_id: 10
        quantity: 1
        unit_price: 60
      # 2025-01-02
      - order_id: 1003
        product_id: 10
        quantity: 5
        unit_price: 40

  outputs:
    query:
      rows:
        - order_date: '2025-01-01'
          product_id: 20
          product_name: Gizmo
          category: Home
          order_count: 1
          total_quantity: 1
          total_sales_amount: 200
          avg_unit_price: 200
        - order_date: '2025-01-01'
          product_id: 10
          product_name: Widget
          category: Electronics
          order_count: 2
          total_quantity: 3
          total_sales_amount: 160
          avg_unit_price: 55
        - order_date: '2025-01-02'
          product_id: 10
          product_name: Widget
          category: Electronics
          order_count: 1
          total_quantity: 5
          total_sales_amount: 200
          avg_unit_price: 40
```

### Testing CTEs

Individual CTEs within the model's query can also be tested. Given a model with a CTE:

```sql linenums="1"
WITH filtered_orders_cte AS (
  SELECT id, item_id
  FROM vulcan_demo.incremental_model
  WHERE item_id = 1
)
SELECT
  item_id,
  COUNT(DISTINCT id) AS num_orders
FROM filtered_orders_cte
GROUP BY item_id
```

Test both the CTE and final query:

```yaml linenums="1"
test_model_with_cte:
  model: vulcan_demo.full_model
  inputs:
    vulcan_demo.incremental_model:
      rows:
        - id: 1
          item_id: 1
        - id: 2
          item_id: 1
        - id: 3
          item_id: 2
  outputs:
    ctes:
      filtered_orders_cte:
        rows:
          - id: 1
            item_id: 1
          - id: 2
            item_id: 1
    query:
      rows:
        - item_id: 1
          num_orders: 2
```

## Supported data formats

Vulcan supports multiple ways to define input and output data:

### YAML dictionaries (default)

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    rows:
      - order_id: 1001
        customer_id: 1
        order_date: '2025-01-01'
```

### CSV format

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    format: csv
    rows: |
      order_id,customer_id,order_date
      1001,1,2025-01-01
      1002,2,2025-01-01
```

### SQL queries

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    query: |
      SELECT 1001 AS order_id, 1 AS customer_id, '2025-01-01' AS order_date
      UNION ALL
      SELECT 1002 AS order_id, 2 AS customer_id, '2025-01-01' AS order_date
```

### External files

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    format: csv
    path: fixtures/orders_test_data.csv
```

## Omitting columns

For wide tables, you can omit columns (treated as `NULL`) or use partial matching:

```yaml linenums="1"
outputs:
  query:
    partial: true  # Only test specified columns
    rows:
      - customer_id: 1
        total_spent: 325
```

To apply partial matching to all outputs:

```yaml linenums="1"
outputs:
  partial: true
  query:
    rows:
      - customer_id: 1
        total_spent: 325
```

## Freezing time

For models using `CURRENT_TIMESTAMP` or similar functions, set `execution_time` to make tests deterministic:

```yaml linenums="1"
test_with_timestamp:
  model: vulcan_demo.audit_log
  outputs:
    query:
      - event: "login"
        created_at: "2023-01-01 12:05:03"
  vars:
    execution_time: "2023-01-01 12:05:03"
```

## Running tests

### Command line

```bash
# Run all tests
vulcan test

# Run specific test file
vulcan test tests/test_daily_sales.yaml

# Run specific test
vulcan test tests/test_daily_sales.yaml::test_daily_sales_aggregation

# Run tests matching a pattern
vulcan test tests/test_*
```

### Example output

```
$ vulcan test
..
----------------------------------------------------------------------
Ran 2 tests in 0.024s

OK
```

When tests fail:

```
$ vulcan test
F
======================================================================
FAIL: test_daily_sales_aggregation (tests/test_daily_sales.yaml)
----------------------------------------------------------------------
AssertionError: Data mismatch (exp: expected, act: actual)

  total_orders
         exp  act
0        3.0  2.0

----------------------------------------------------------------------
Ran 1 test in 0.012s

FAILED (failures=1)
```

<!-- ### Notebook magic

```python
import vulcan
%run_test
``` -->

## Automatic test generation

Generate tests automatically using the `create_test` command:

```bash
vulcan create_test vulcan_demo.daily_sales \
  --query raw.raw_orders "SELECT * FROM raw.raw_orders WHERE order_date BETWEEN '2025-01-01' AND '2025-01-02' LIMIT 10" 
```

This creates a test file with actual data from your warehouse, making it easy to bootstrap your test suite.

<!-- ## Using a different testing connection

Override the testing connection for specific tests:

```yaml linenums="1"
test_with_spark:
  gateway: spark_testing
  model: vulcan_demo.complex_model
  # ... rest of test
```

Configure the gateway in `config.yaml`:

```yaml linenums="1"
gateways:
  spark_testing:
    test_connection:
      type: spark
      config:
        "spark.master": "local"
``` -->

## Troubleshooting

### Preserving fixtures

Use `--preserve-fixtures` to keep test fixtures for debugging:

```bash
vulcan test --preserve-fixtures
```

Fixtures are created as views in a schema named `vulcan_test_<random_ID>`.

### Type mismatches

If Vulcan can't infer column types correctly, specify them explicitly:

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    columns:
      order_id: INT
      order_date: DATE
      total_amount: DECIMAL(10,2)
    rows:
      - order_id: 1001
        order_date: '2025-01-01'
        total_amount: 99.99
```

## Unit test structure

### `<test_name>`

The unique name of the test.

### `<test_name>.model`

The name of the model being tested. This model must be defined in the project's `models/` folder.

### `<test_name>.description`

An optional description of the test, which can be used to provide additional context.

### `<test_name>.schema`

The name of the schema that will contain the views that are necessary to run this unit test.

### `<test_name>.gateway`

The gateway whose `test_connection` will be used to run this test. If not specified, the default gateway is used.

### `<test_name>.inputs`

The inputs that will be used to test the target model. If the model has no dependencies, this can be omitted.

### `<test_name>.inputs.<upstream_model>`

A model that the target model depends on.

### `<test_name>.inputs.<upstream_model>.rows`

The rows of the upstream model, defined as an array of dictionaries that map columns to their values:

```yaml linenums="1"
    <upstream_model>:
      rows:
        - <column_name>: <column_value>
        ...
```

If `rows` is the only key under `<upstream_model>`, then it can be omitted:

```yaml linenums="1"
    <upstream_model>:
      - <column_name>: <column_value>
      ...
```

When the input format is `csv`, the data can be specified inline under `rows` :

```yaml linenums="1"
    <upstream_model>:
      rows: |
        <column1_name>,<column2_name>
        <row1_value>,<row1_value>
        <row2_value>,<row2_value>
```

### `<test_name>.inputs.<upstream_model>.format`
  
The optional `format` key allows for control over how the input data is loaded.

```yaml linenums="1"
    <upstream_model>:
      format: csv
```

Currently, the following formats are supported: `yaml` (default), `csv`.

### `<test_name>.inputs.<upstream_model>.csv_settings`
  
When the`format` is CSV, you can control the behaviour of data loading under `csv_settings`:

```yaml linenums="1"
    <upstream_model>:
      format: csv
      csv_settings: 
        sep: "#"
        skip_blank_lines: true
      rows: |
        <column1_name>#<column2_name>
        <row1_value>#<row1_value>
        <row2_value>#<row2_value>
```

Learn more about the [supported CSV settings](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html).
  
### `<test_name>.inputs.<upstream_model>.path`

The optional `path` key specifies the pathname of the data to be loaded.
  
```yaml linenums="1"
    <upstream_model>:
      path: filepath/test_data.yaml
```

### `<test_name>.inputs.<upstream_model>.columns`

An optional dictionary that maps columns to their types:

```yaml linenums="1"
    <upstream_model>:
      columns:
        <column_name>: <column_type>
        ...
```

This can be used to help Vulcan interpret the row values correctly in the context of SQL.

Any number of columns may be omitted from this mapping, in which case their types will be inferred on a best-effort basis. Explicitly casting the corresponding columns in the model's query will enable Vulcan to infer their types more accurately.

### `<test_name>.inputs.<upstream_model>.query`

An optional SQL query that will be executed against the testing connection to generate the input rows:

```yaml linenums="1"
    <upstream_model>:
      query: <sql_query>
```

This provides more control over how the input data must be interpreted.

The `query` key can't be used together with the `rows` key.

### `<test_name>.outputs`

The target model's expected outputs.

Note: the columns in each row of an expected output must appear in the same relative order as they are selected in the corresponding query.

### `<test_name>.outputs.partial`

A boolean flag that indicates whether only a subset of the output columns will be tested. When set to `true`, only the columns referenced in the corresponding expected rows will be tested.

See also: [Omitting columns](#omitting-columns).

### `<test_name>.outputs.query`

The expected output of the target model's query. This is optional, as long as [`<test_name>.outputs.ctes`](#test_nameoutputsctes) is present.

### `<test_name>.outputs.query.partial`

Same as [`<test_name>.outputs.partial`](#test_nameoutputspartial), but applies only to the output of the target model's query.

### `<test_name>.outputs.query.rows`

The expected rows of the target model's query.

See also: [`<test_name>.inputs.<upstream_model>.rows`](#test_nameinputsupstream_modelrows).

### `<test_name>.outputs.query.query`

An optional SQL query that will be executed against the testing connection to generate the expected rows for the target model's query.

See also: [`<test_name>.inputs.<upstream_model>.query`](#test_nameinputsupstream_modelquery).

### `<test_name>.outputs.ctes`

The expected output per each individual top-level [Common Table Expression](glossary.md#cte) (CTE) defined in the target model's query. This is optional, as long as [`<test_name>.outputs.query`](#test_nameoutputsquery) is present.

### `<test_name>.outputs.ctes.<cte_name>`

The expected output of the CTE with name `<cte_name>`.

### `<test_name>.outputs.ctes.<cte_name>.partial`

Same as [`<test_name>.outputs.partial`](#test_nameoutputspartial), but applies only to the output of the CTE with name `<cte_name>`.

### `<test_name>.outputs.ctes.<cte_name>.rows`

The expected rows of the CTE with name `<cte_name>`.

See also: [`<test_name>.inputs.<upstream_model>.rows`](#test_nameinputsupstream_modelrows).

### `<test_name>.outputs.ctes.<cte_name>.query`

An optional SQL query that will be executed against the testing connection to generate the expected rows for the CTE with name `<cte_name>`.

See also: [`<test_name>.inputs.<upstream_model>.query`](#test_nameinputsupstream_modelquery).

### `<test_name>.vars`

An optional dictionary that assigns values to macro variables:

```yaml linenums="1"
  vars:
    start: 2022-01-01
    end: 2022-01-01
    execution_time: 2022-01-01
    <macro_variable_name>: <macro_variable_value>
```

There are three special macro variables: `start`, `end`, and `execution_time`. If these are set, they will override the corresponding date macros of the target model. For example, `@execution_ds` will render to `2022-01-01` if `execution_time` is set to this value.

Additionally, SQL expressions like `CURRENT_DATE` and `CURRENT_TIMESTAMP` will produce the same datetime value as `execution_time`, when it is set.
