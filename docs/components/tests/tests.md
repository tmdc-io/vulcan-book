# Tests

Tests are your safety net for data transformations. Just like software engineers write unit tests to catch bugs before they ship, you can write tests to verify that your models transform data correctly—catching problems before they reach production and cause headaches.

Think of tests as executable documentation. They show exactly how your model should behave with specific inputs, and they'll yell at you if something changes unexpectedly. Unlike [audits](../audits/audits.md) (which check data quality at runtime), tests verify the *logic* of your models against predefined inputs and expected outputs.

## Why Testing Matters

Data modelss are tricky beasts. Small errors can snowball into significant business impacts. A small change in one model can cascade into big problems downstream. Here's why testing is worth your time:

- **Catch breaking changes** - Refactor with confidence knowing tests will flag unintended behavior changes
- **Document expected behavior** - Tests serve as executable specifications (better than comments that get outdated!)
- **Faster debugging** - When something breaks, tests pinpoint exactly which transformation failed
- **Data quality assurance** - Verify that aggregations, joins, and calculations produce correct results
- **Confidence in changes** - Make updates knowing you'll catch regressions before they hit production

Tests run either on demand (like in CI/CD modelss) or automatically when you create a new [plan](guides/plan.md). Either way, they're there to help you sleep better at night.

## Creating Tests

Tests live in YAML files in the `tests/` folder of your project. The filename must start with `test` and end with `.yaml` or `.yml`. You can put multiple tests in one file (organize them however makes sense).

At minimum, a test needs three things:

- **model** - Which model you're testing
- **inputs** - Mock data for upstream dependencies (what goes in)
- **outputs** - Expected results from the model's query (what should come out)

Let's start with a simple example.

### Your First Test

Here's a model that aggregates orders by date:

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

Now let's write a test to verify it works correctly:

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

This test gives the model three orders (two on March 15, one on March 16) and checks that:

- Orders are correctly grouped by date
- `total_orders` counts distinct orders per day (should be 2 for March 15, 1 for March 16)
- `total_revenue` sums the amounts correctly (50 + 75 = 125 for March 15)
- `last_order_id` returns the maximum order ID per day (O002 for March 15, O003 for March 16)

Pretty straightforward! If any of these expectations don't match, the test fails and tells you what went wrong.

### Testing Models with Multiple Dependencies

Real-world models often join multiple tables. Here's how you'd test a more complex model that joins customers, orders, and order items:

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

Notice how we're providing mock data for all three upstream tables. The test verifies that the model correctly:

- Joins customers with orders and order items
- Counts distinct orders per customer
- Calculates total spent (quantity × unit_price summed across all items)
- Handles division by zero (Charlie has no orders, so avg_order_value should be NULL)

The comments in the YAML help explain the test data, which makes it easier to understand what's being tested.

### Testing Incremental Models

Incremental models are a bit special because they filter data by time range. You'll need to set `start` and `end` dates using the `vars` attribute:

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

The `vars` section tells Vulcan what time range to use when running the model. This is important because incremental models filter by `@start_ds` and `@end_ds` macros, and you need to control those in your test.

### Testing CTEs

You can also test individual CTEs (Common Table Expressions) within your model. This is super useful for debugging complex queries step by step.

Say you have a model with a CTE:

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

You can test both the CTE and the final query:

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

This verifies that:

1. The CTE correctly filters to `item_id = 1` (should return rows with id 1 and 2)
2. The final query correctly counts distinct orders (should be 2)

Testing CTEs separately makes it easier to pinpoint where things go wrong in complex queries.

## Supported Data Formats

Vulcan gives you flexibility in how you define test data. Pick whatever format works best for your situation:

### YAML Dictionaries (Default)

The most common format, just list your rows as YAML dictionaries:

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    rows:
      - order_id: 1001
        customer_id: 1
        order_date: '2025-01-01'
```

This is great for small datasets and when you want everything in one place.

### CSV Format

If you have lots of data, CSV might be easier to read and write:

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    format: csv
    rows: |
      order_id,customer_id,order_date
      1001,1,2025-01-01
      1002,2,2025-01-01
```

You can also customize CSV parsing with `csv_settings` if you need different separators or other options.

### SQL Queries

Sometimes you want more control over how data is generated. Use a SQL query:

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    query: |
      SELECT 1001 AS order_id, 1 AS customer_id, '2025-01-01' AS order_date
      UNION ALL
      SELECT 1002 AS order_id, 2 AS customer_id, '2025-01-01' AS order_date
```

This is useful when you need to generate test data programmatically or when the data structure is complex.

### External Files

For large test datasets, store them in separate files:

```yaml linenums="1"
inputs:
  vulcan_demo.orders:
    format: csv
    path: fixtures/orders_test_data.csv
```

This keeps your test files clean and makes it easy to reuse test data across multiple tests.

## Omitting Columns

For wide tables, you don't need to specify every column. You can omit columns (they'll be treated as `NULL`) or use partial matching to only test the columns you care about:

```yaml linenums="1"
outputs:
  query:
    partial: true  # Only test specified columns
    rows:
      - customer_id: 1
        total_spent: 325
```

This is super handy when you have a table with 50 columns but only care about testing a few of them.

**Apply partial matching globally:**

```yaml linenums="1"
outputs:
  partial: true
  query:
    rows:
      - customer_id: 1
        total_spent: 325
```

This applies partial matching to all outputs in the test, which is convenient when you're only testing a subset of columns.

## Freezing Time

If your model uses `CURRENT_TIMESTAMP` or similar functions, you'll want to freeze time in your tests to make them deterministic. Otherwise, your tests will fail every time you run them because the timestamp changes!

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

Setting `execution_time` in `vars` makes `CURRENT_TIMESTAMP` and `CURRENT_DATE` return fixed values, so your tests are predictable and repeatable.

## Running Tests

### Command Line

Run tests from the command line:

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

The `::` syntax lets you run a specific test from a file, which is handy when you're debugging a single failing test.

### Example Output

When tests pass, you'll see something like:

```
$ vulcan test
..
----------------------------------------------------------------------
Ran 2 tests in 0.024s

OK
```

The dots (`.`) indicate passing tests. Simple and clean!

**When tests fail:**

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

The output shows you exactly what didn't match. In this case, `total_orders` was expected to be 3.0 but was actually 2.0. This tells you exactly what to investigate.

## Automatic Test Generation

Writing tests can be tedious, especially when you're just getting started. Vulcan can help by generating tests automatically:

```bash
vulcan create_test vulcan_demo.daily_sales \
  --query raw.raw_orders "SELECT * FROM raw.raw_orders WHERE order_date BETWEEN '2025-01-01' AND '2025-01-02' LIMIT 10" 
```

This creates a test file with actual data from your warehouse, which makes it easy to bootstrap your test suite. You can then tweak the generated test to match your needs.

**Pro tip:** Start with generated tests, then refine them to test edge cases and specific scenarios. It's much faster than writing everything from scratch!

## Troubleshooting

### Preserving Fixtures

When a test fails, you might want to inspect the actual data that was created. Use `--preserve-fixtures` to keep test fixtures around:

```bash
vulcan test --preserve-fixtures
```

Fixtures are created as views in a schema named `vulcan_test_<random_ID>`. You can query these views directly to see what data was actually produced, which is super helpful for debugging.

### Type Mismatches

Sometimes Vulcan can't figure out the correct types for your test data. If you're seeing type errors, specify them explicitly:

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

The `columns` section tells Vulcan exactly what types to use, which helps avoid type inference issues. You can also explicitly cast columns in your model's query to help Vulcan infer types more accurately.

### Test Not Finding Model

**Problem:** Test says it can't find the model.

**Solution:** Make sure the model name in your test matches exactly what's in your `models/` folder. Model names are case-sensitive and must include the schema (like `sales.daily_sales`, not just `daily_sales`).

### Output Order Matters

**Problem:** Test fails even though the data looks correct.

**Solution:** The columns in your expected output must appear in the same order as they're selected in the model's query. Check the `SELECT` statement order and make sure your test rows match.

### Partial Matching Not Working

**Problem:** Partial matching isn't ignoring extra columns.

**Solution:** Make sure you set `partial: true` at the right level. It needs to be under `outputs.query` (or `outputs.ctes.<cte_name>`) for CTE-specific partial matching, or under `outputs` for global partial matching.

## Test Structure Reference

Here's a complete reference of all the fields you can use in a test. Most tests only need `model`, `inputs`, and `outputs`, but it's good to know what else is available.

### `<test_name>`

The unique name of your test. Use descriptive names that explain what you're testing, like `test_daily_sales_aggregation` or `test_customer_revenue_calculation`.

### `<test_name>.model`

The fully qualified name of the model being tested (like `sales.daily_sales`). This model must exist in your project's `models/` folder.

### `<test_name>.description`

An optional description that explains what the test validates. This is helpful for your teammates (and future you) to understand what the test is checking.

### `<test_name>.schema`

The name of the schema that will contain the test fixtures (the views created for this test). If not specified, Vulcan creates a temporary schema.

### `<test_name>.gateway`

The gateway whose `test_connection` will be used to run this test. If not specified, the default gateway is used. Useful when you need to test against a specific database or engine.

### `<test_name>.inputs`

Mock data for upstream models that your target model depends on. If your model has no dependencies, you can omit this.

### `<test_name>.inputs.<upstream_model>`

A model that your target model depends on. Provide mock data for each upstream model.

### `<test_name>.inputs.<upstream_model>.rows`

The rows of test data, defined as an array of dictionaries:

```yaml linenums="1"
    <upstream_model>:
      rows:
        - <column_name>: <column_value>
        ...
```

**Shortcut:** If `rows` is the only key, you can omit it:

```yaml linenums="1"
    <upstream_model>:
      - <column_name>: <column_value>
      ...
```

### `<test_name>.inputs.<upstream_model>.format`

The format of the input data. Options: `yaml` (default) or `csv`.

```yaml linenums="1"
    <upstream_model>:
      format: csv
```

### `<test_name>.inputs.<upstream_model>.csv_settings`

When using CSV format, customize how the CSV is parsed:

```yaml linenums="1"
    <upstream_model>:
      format: csv
      csv_settings: 
        sep: "#"
        skip_blank_lines: true
      rows: |
        <column1_name>#<column2_name>
        <row1_value>#<row1_value>
```

See [pandas read_csv documentation](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html) for all supported settings.

### `<test_name>.inputs.<upstream_model>.path`

Load data from an external file:

```yaml linenums="1"
    <upstream_model>:
      path: filepath/test_data.yaml
```

### `<test_name>.inputs.<upstream_model>.columns`

Explicitly specify column types to help Vulcan interpret your data correctly:

```yaml linenums="1"
    <upstream_model>:
      columns:
        <column_name>: <column_type>
        ...
```

This is especially useful when Vulcan can't infer types correctly (like with dates or decimals).

### `<test_name>.inputs.<upstream_model>.query`

Generate input data using a SQL query:

```yaml linenums="1"
    <upstream_model>:
      query: <sql_query>
```

**Note:** You can't use `query` together with `rows`, pick one or the other.

### `<test_name>.outputs`

The expected outputs from your model. This is what you're asserting should be true.

**Important:** Column order matters! The columns in your expected rows must match the order they appear in the model's `SELECT` statement.

### `<test_name>.outputs.partial`

When `true`, only test the columns you specify. Extra columns in the output are ignored. Useful for wide tables where you only care about a few columns.

### `<test_name>.outputs.query`

The expected output of the model's final query. This is optional if you're testing CTEs instead.

### `<test_name>.outputs.query.partial`

Same as `outputs.partial`, but applies only to the query output (not CTEs).

### `<test_name>.outputs.query.rows`

The expected rows from the model's query. Same format as input rows.

### `<test_name>.outputs.query.query`

Generate expected output using a SQL query. Useful when the expected output is complex or when you want to compute it dynamically.

### `<test_name>.outputs.ctes`

Test individual CTEs within your model. This is optional if you're testing the final query output.

### `<test_name>.outputs.ctes.<cte_name>`

The expected output of a specific CTE. Use this to test intermediate steps in complex queries.

### `<test_name>.outputs.ctes.<cte_name>.partial`

Partial matching for a specific CTE.

### `<test_name>.outputs.ctes.<cte_name>.rows`

Expected rows for a specific CTE.

### `<test_name>.outputs.ctes.<cte_name>.query`

Generate expected CTE output using a SQL query.

### `<test_name>.vars`

Set values for macro variables used in your model:

```yaml linenums="1"
  vars:
    start: 2022-01-01
    end: 2022-01-01
    execution_time: 2022-01-01
    <macro_variable_name>: <macro_variable_value>
```

**Special variables:**
- `start` - Overrides `@start_ds` for incremental models
- `end` - Overrides `@end_ds` for incremental models  
- `execution_time` - Overrides `@execution_ds` and makes `CURRENT_TIMESTAMP`/`CURRENT_DATE` return fixed values

These are super useful for testing incremental models and making time-dependent tests deterministic.
