# Models

This guide walks you through working with models in Vulcan using the Orders360 example project. You'll learn how to add, edit, evaluate, and manage models with practical examples.

Models are the heart of Vulcan, they define your data transformations. Once you understand how to work with them, you'll be able to build powerful data pipelines!

## Prerequisites

Before adding a model, ensure that you have:

- [Created your project](../guides/get-started/docker.md) 
- [Applied your first plan](./plan.md#scenario-1-first-plan-initializing-production)
- Working in a [dev environment](../references/environments.md) for testing changes

---

## Understanding Models

Models in Vulcan consist of two core components:

1. **DDL (Data Definition Language)**: The `MODEL` block that defines structure, metadata, and behavior - this is where you configure how the model works
2. **DML (Data Manipulation Language)**: The `SELECT` query that contains transformation logic - this is where you write your SQL

Think of the MODEL block as the configuration and the SELECT as the actual work. Together, they define what your model does and how it does it.

### Example: Daily Sales Model

Here's a real example from Orders360:

```sql
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date,
  description 'Daily sales summary with order counts and revenue',
  column_descriptions (
    order_date = 'Date of the sales',
    total_orders = 'Total number of orders for the day',
    total_revenue = 'Total revenue for the day',
    last_order_id = 'Last order ID processed for the day'
  ),
  assertions (
    unique_values(columns := (order_date)),
    not_null(columns := (order_date, total_orders, total_revenue)),
    positive_values(column := total_orders),
    positive_values(column := total_revenue)
  )
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

*[Screenshot: daily_sales.sql file in editor showing the complete model definition]*

---

## Adding a Model

To add a new model to your Orders360 project:

### Step 1: Create Model File

Create a new file in your `models` directory. For example, let's add a weekly sales aggregation:

```bash
touch models/sales/weekly_sales.sql
```

*[Screenshot: File explorer showing models/sales directory structure]*

### Step 2: Define the Model

Edit the file and add your model definition:

```sql
MODEL (
  name sales.weekly_sales,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date,
    batch_size 1
  ),
  start '2025-01-01',
  cron '@weekly',
  grain [order_date],
  description 'Weekly aggregated sales metrics'
);

SELECT
  DATE_TRUNC('week', order_date) AS order_date,
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(total_amount) AS total_revenue,
  AVG(total_amount) AS avg_order_value
FROM sales.daily_sales
WHERE order_date BETWEEN @start_ds AND @end_ds
GROUP BY DATE_TRUNC('week', order_date)
```

*[Screenshot: weekly_sales.sql file in editor with model definition]*

### Step 3: Check Model Status

Verify your model is detected:

```bash
vulcan info
```

**Expected Output:**
```
Connection: ✅ Connected
Models: 5
  - raw.raw_customers
  - raw.raw_orders
  - raw.raw_products
  - sales.daily_sales
  - sales.weekly_sales  ← NEW MODEL
...
```

*[Screenshot: `vulcan info` output showing the new weekly_sales model]*

### Step 4: Apply the Model

Use `vulcan plan` to apply your new model:

```bash
vulcan plan
```

**Expected Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------

Differences from the `prod` environment:

Models:
└── Added:
    └── sales.weekly_sales

Models needing backfill (missing dates):
└── sales.weekly_sales: 2025-01-01 - 2025-01-15

Apply - Backfill Tables [y/n]:
```

*[Screenshot: Plan output showing new weekly_sales model to be added]*

Type `y` to apply and backfill the model.

---

## Editing an Existing Model

To edit an existing model, modify the model file and use Vulcan's tools to preview and apply changes.

### Step 1: Edit the Model File

Let's modify `sales.daily_sales` to add a new column. Open `models/sales/daily_sales.sql`:

```sql
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date,
  description 'Daily sales summary with order counts and revenue',
  column_descriptions (
    order_date = 'Date of the sales',
    total_orders = 'Total number of orders for the day',
    total_revenue = 'Total revenue for the day',
    last_order_id = 'Last order ID processed for the day',
    avg_order_value = 'Average order value for the day'  -- NEW COLUMN DESCRIPTION
  ),
  assertions (
    unique_values(columns := (order_date)),
    not_null(columns := (order_date, total_orders, total_revenue)),
    positive_values(column := total_orders),
    positive_values(column := total_revenue)
  )
);

SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  AVG(total_amount)::FLOAT AS avg_order_value,  -- NEW COLUMN
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
GROUP BY order_date
ORDER BY order_date
```

*[Screenshot: daily_sales.sql file showing the added avg_order_value column]*

### Step 2: Evaluate the Model (Optional)

Preview the model output without materializing it:

```bash
vulcan evaluate sales.daily_sales --start=2025-01-15 --end=2025-01-15
```

**Expected Output:**
```
order_date          total_orders  total_revenue  avg_order_value  last_order_id
2025-01-15 00:00:00           42         1250.50           29.77        ORD-00142
```

*[Screenshot: Evaluate command output showing the new avg_order_value column]*

**What Happened?**
- The `evaluate` command runs the model query without creating tables - it's like a dry run
- Shows you the output with the new column - you can see what the data will look like
- Useful for testing changes before applying them - catch issues before they hit production

This is super useful for iteration! You can test your changes quickly without waiting for full materialization.

### Step 3: Preview Changes with Plan

See what will change and how it affects downstream models:

```bash
vulcan plan dev
```

**Expected Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------

Differences from the `prod` environment:

Models:
└── Directly Modified:
    └── sales.daily_sales

Directly Modified: sales.daily_sales (Non-breaking)
└── Diff:
    @@ -22,6 +22,7 @@
      SELECT
        CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
        COUNT(order_id)::INTEGER AS total_orders,
        SUM(total_amount)::FLOAT AS total_revenue,
    +   AVG(total_amount)::FLOAT AS avg_order_value,
        MAX(order_id)::VARCHAR AS last_order_id
      FROM raw.raw_orders

Models needing backfill (missing dates):
└── sales.daily_sales: 2025-01-01 - 2025-01-15

Apply - Backfill Tables [y/n]:
```

*[Screenshot: Plan output showing non-breaking change with diff highlighting the new column]*

**Understanding the Output:**
- **Non-breaking**: Vulcan detected this as non-breaking (adding a column) - adding columns is safe, existing queries still work
- **Diff**: Shows exactly what changed (green `+` indicates added line) - you can see exactly what you modified
- **No downstream impact**: `sales.weekly_sales` is not listed because it doesn't use this column yet - downstream models don't need to be reprocessed

This is why non-breaking changes are great, they don't cascade. You can add columns without forcing downstream models to reprocess.

### Step 4: Apply the Changes

Type `y` to apply the plan:

```
Apply - Backfill Tables [y/n]: y
```

**Expected Output:**
```
[1/1] sales.daily_sales          [insert 2025-01-01 - 2025-01-15] 5.2s

Executing model batches ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 1/1 • 0:00:05

✔ Model batches executed
✔ Plan applied successfully
```

*[Screenshot: Plan application showing daily_sales being backfilled]*

---

## Making a Breaking Change

Breaking changes affect downstream models. Let's see how Vulcan handles this.

### Step 1: Add a Filter to Daily Sales

Edit `models/sales/daily_sales.sql` to add a WHERE clause:

```sql
SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  AVG(total_amount)::FLOAT AS avg_order_value,
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
WHERE total_amount > 10  -- NEW FILTER: Only orders > $10
GROUP BY order_date
ORDER BY order_date
```

*[Screenshot: daily_sales.sql showing the WHERE clause filter]*

### Step 2: Create Plan

```bash
vulcan plan dev
```

**Expected Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------

Differences from the `prod` environment:

Models:
├── Directly Modified:
│   └── sales.daily_sales
└── Indirectly Modified:
    └── sales.weekly_sales

Directly Modified: sales.daily_sales (Breaking)
└── Diff:
    @@ -26,6 +26,7 @@
      FROM raw.raw_orders
    + WHERE total_amount > 10
      GROUP BY order_date

└── Indirectly Modified Children:
    └── sales.weekly_sales (Indirect Breaking)

Models needing backfill (missing dates):
├── sales.daily_sales: 2025-01-01 - 2025-01-15
└── sales.weekly_sales: 2025-01-01 - 2025-01-15

Apply - Backfill Tables [y/n]:
```

*[Screenshot: Plan output showing breaking change with downstream impact on weekly_sales]*

**Understanding Breaking Changes:**
- **Breaking**: Adding a WHERE clause filters data, making existing data invalid - rows that should be filtered out might still be in the table
- **Indirectly Modified**: `sales.weekly_sales` depends on `daily_sales`, so it's affected - it needs to be reprocessed with the new filtered data
- **Cascading backfill**: Both models need to be reprocessed - Vulcan handles this automatically, processing upstream first

Breaking changes are more expensive because they cascade. Make sure you really need to make a breaking change before you do it!

---

## Evaluating a Model

The `evaluate` command lets you test models without materializing data. Perfect for iteration and debugging. It's like a preview mode, you can see what your model will produce without actually creating tables.

### Basic Evaluation

```bash
vulcan evaluate sales.daily_sales --start=2025-01-15 --end=2025-01-15
```

**Expected Output:**
```
order_date          total_orders  total_revenue  avg_order_value  last_order_id
2025-01-15 00:00:00           42         1250.50           29.77        ORD-00142
```

*[Screenshot: Evaluate output showing single day results]*

### Evaluate Multiple Days

```bash
vulcan evaluate sales.daily_sales --start=2025-01-10 --end=2025-01-15
```

**Expected Output:**
```
order_date          total_orders  total_revenue  avg_order_value  last_order_id
2025-01-10 00:00:00           38         1120.25           29.48        ORD-00110
2025-01-11 00:00:00           45         1350.75           30.02        ORD-00111
2025-01-12 00:00:00           41         1225.50           29.89        ORD-00112
2025-01-13 00:00:00           39         1180.00           30.26        ORD-00113
2025-01-14 00:00:00           44         1320.50           30.01        ORD-00114
2025-01-15 00:00:00           42         1250.50           29.77        ORD-00142
```

*[Screenshot: Evaluate output showing multiple days of data]*

### Evaluate with Filters

Test your model logic with different conditions:

```bash
vulcan evaluate sales.daily_sales --start=2025-01-15 --end=2025-01-15 --where "total_amount > 50"
```

*[Screenshot: Evaluate command with WHERE clause filter]*

**Use Cases for Evaluate:**
- ✅ Test model logic before applying changes - make sure your SQL does what you think it does
- ✅ Debug query issues - see what's actually happening with your data
- ✅ Verify data transformations - check that aggregations, joins, etc. are working correctly
- ✅ Check data quality - spot issues before they make it to production
- ✅ Iterate quickly without materialization costs - test changes fast without waiting for full backfills

Evaluate is your best friend during development. Use it liberally!

---

## Reverting a Change

Vulcan makes it easy to revert model changes using Virtual Updates. Made a mistake? No problem! You can revert quickly without reprocessing all your data.

### Step 1: Revert the Change

Edit `models/sales/daily_sales.sql` to remove the WHERE clause we added:

```sql
SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  AVG(total_amount)::FLOAT AS avg_order_value,
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
-- WHERE total_amount > 10  -- REMOVED FILTER
GROUP BY order_date
ORDER BY order_date
```

*[Screenshot: daily_sales.sql with WHERE clause removed/commented out]*

### Step 2: Apply Reverted Plan

```bash
vulcan plan dev
```

**Expected Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------

Differences from the `dev` environment:

Models:
├── Directly Modified:
│   └── sales.daily_sales
└── Indirectly Modified:
    └── sales.weekly_sales

Directly Modified: sales.daily_sales (Breaking)
└── Diff:
    @@ -26,7 +26,6 @@
      FROM raw.raw_orders
    - WHERE total_amount > 10
      GROUP BY order_date

Apply - Virtual Update [y/n]: y
```

*[Screenshot: Plan showing reverted change with diff]*

**Virtual Update:**
- No backfill required - just updates references - Vulcan just changes which physical table the view points to
- Fast operation - completes in seconds - way faster than a full backfill
- Previous data remains available - the old data is still there, you're just not using it anymore

Virtual updates are great for reverting changes. They're fast and don't require reprocessing data.

---

## Validating Models

Vulcan provides multiple ways to validate your models. You don't have to guess if your models are working, Vulcan checks them for you!

### Automatic Validation

Vulcan automatically validates models when you run `plan`:

1. **Unit Tests**: Run automatically to validate logic
2. **Audits**: Execute when data is loaded to tables
3. **Assertions**: Check data quality constraints

**Example Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------
```

*[Screenshot: Plan output showing tests passed]*

### Manual Validation Options

1. **Evaluate**: Test model output without materialization
   ```bash
   vulcan evaluate sales.daily_sales --start=2025-01-15 --end=2025-01-15
   ```

2. **Unit Tests**: Write tests in `tests/` directory
   ```bash
   vulcan test
   ```

3. **Plan Preview**: See changes before applying
   ```bash
   vulcan plan dev
   ```

*[Screenshot: Test execution showing all tests passing]*

---

## Deleting a Model

To remove a model from your project:

### Step 1: Delete Model File

```bash
rm models/sales/weekly_sales.sql
```

*[Screenshot: File explorer showing weekly_sales.sql deleted]*

### Step 2: Delete Associated Tests (if any)

```bash
rm tests/test_weekly_sales.yaml
```

### Step 3: Apply Deletion Plan

```bash
vulcan plan dev
```

**Expected Output:**
```
======================================================================
Successfully Ran 1 tests against postgres
----------------------------------------------------------------------

Differences from the `dev` environment:

Models:
└── Removed Models:
    └── sales.weekly_sales

Apply - Virtual Update [y/n]: y
```

*[Screenshot: Plan output showing weekly_sales as removed]*

Type `y` to apply the deletion.

**Expected Output:**
```
Virtually Updating 'dev' ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 0:00:00

The target environment has been updated successfully
Virtual Update executed successfully
```

*[Screenshot: Virtual update completing successfully]*

### Step 4: Apply to Production

```bash
vulcan plan
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
└── Removed Models:
    └── sales.weekly_sales

Apply - Virtual Update [y/n]: y
```

*[Screenshot: Production plan showing model removal]*

---

## Model Examples from Orders360

### Seed Model: Raw Orders

```sql
MODEL (
  name raw.raw_orders,
  kind SEED (
    path '../../seeds/raw_orders.csv'
  ),
  description 'Seed model loading raw order data from CSV file',
  columns (
    order_id VARCHAR,
    order_date DATE,
    customer_id VARCHAR,
    product_id VARCHAR,
    total_amount FLOAT
  ),
  column_descriptions (
    order_id = 'Unique identifier for each order',
    order_date = 'Date when the order was placed',
    customer_id = 'Reference to customer who placed the order',
    product_id = 'Reference to product that was ordered',
    total_amount = 'Total order amount in dollars'
  ),
  assertions (
    unique_values(columns := (order_id)),
    not_null(columns := (order_id, order_date, customer_id, product_id)),
    positive_values(column := total_amount)
  ),
  grain order_id
);
```

*[Screenshot: raw_orders.sql seed model file]*

### Transformation Model: Daily Sales

```sql
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date,
  description 'Daily sales summary with order counts and revenue',
  column_descriptions (
    order_date = 'Date of the sales',
    total_orders = 'Total number of orders for the day',
    total_revenue = 'Total revenue for the day',
    last_order_id = 'Last order ID processed for the day'
  ),
  assertions (
    unique_values(columns := (order_date)),
    not_null(columns := (order_date, total_orders, total_revenue)),
    positive_values(column := total_orders),
    positive_values(column := total_revenue)
  )
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

*[Screenshot: daily_sales.sql transformation model file]*

---

## Best Practices

Here are some tips to help you work effectively with models:

1. **Use descriptive names**: `sales.daily_sales` is clearer than `sales.ds` - future you will thank present you
2. **Add column descriptions**: Document what each column represents - helps others (and you) understand the data
3. **Use assertions**: Validate data quality at the model level - catch issues automatically
4. **Test before applying**: Use `evaluate` to preview changes - catch bugs before they hit production
5. **Review plans carefully**: Check diffs and downstream impacts - make sure you understand what will change
6. **Use dev environments**: Test changes before production - don't test in prod!

Following these practices will make your life easier and your data pipelines more reliable.

---

## Next Steps

- Learn about [Model Kinds](../components/model/model_kinds.md) for different model types
- Explore [Model Properties](../components/model/properties.md) for advanced configuration
- Read about [Plan Guide](./plan.md) for applying model changes
