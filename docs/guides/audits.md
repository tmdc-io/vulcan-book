# Audits guide

Audits validate your model's data after execution. When an audit fails, Vulcan halts the pipeline to prevent invalid data from flowing downstream.

## Quick start

### Running audits manually

Run audits for your models using the `vulcan audit` command:

```bash
$ vulcan audit
Found 1 audit(s).
assert_positive_order_ids PASS.

Finished with 0 audit error(s).
Done.
```

**Note:** Ensure that you have already planned and applied your changes before running an audit manually.

### Automatic audit execution

Audits run automatically when you apply a plan. If any audit fails, Vulcan halts plan application to prevent invalid data from reaching production.

```bash
$ vulcan plan dev
...
Audit assert_positive_order_ids FAILED for model sushi.orders
Got 3 results, expected 0.
SELECT * FROM vulcan.sushi__orders__1836721418 WHERE order_id <= 0

Error: Audit failed. Plan application halted.
```

## Adding audits to models

### Using built-in audits

Attach built-in audits directly in your model definition:

```sql
MODEL (
  name sushi.orders,
  assertions (
    not_null(columns := (order_id, customer_id)),
    unique_values(columns := (order_id)),
    accepted_range(column := total_amount, min_v := 0, max_v := 100000)
  )
);

SELECT order_id, customer_id, total_amount
FROM sushi.raw_orders;
```

### Creating custom audits

Define custom audits in `.sql` files in your `audits/` directory:

```sql
-- audits/positive_amounts.sql
AUDIT (name assert_positive_amounts);
SELECT * FROM @this_model WHERE amount <= 0;
```

Then attach it to your model:

```sql
MODEL (
  name sushi.orders,
  assertions (assert_positive_amounts)
);
```

### Generic audits with parameters

Create reusable audits that work across multiple models:

```sql
-- audits/threshold_check.sql
AUDIT (name does_not_exceed_threshold);
SELECT * FROM @this_model
WHERE @column >= @threshold;
```

Use it with different parameters:

```sql
MODEL (
  name sushi.items,
  assertions (
    does_not_exceed_threshold(column := price, threshold := 1000),
    does_not_exceed_threshold(column := quantity, threshold := 10000)
  )
);
```

### Inline audits

Define audits directly in your model file:

```sql
MODEL (
  name sushi.items,
  assertions (price_is_not_null, positive_price)
);

SELECT id, price
FROM sushi.raw_items;

AUDIT (name price_is_not_null);
SELECT * FROM @this_model WHERE price IS NULL;

AUDIT (name positive_price);
SELECT * FROM @this_model WHERE price <= 0;
```

## Common audit patterns

### Primary key validation

Ensure primary keys are unique and not null:

```sql
MODEL (
  name analytics.customers,
  assertions (
    not_null(columns := (customer_id)),
    unique_values(columns := (customer_id))
  )
);
```

### Business rule validation

Validate business rules using the `forall` audit:

```sql
MODEL (
  name analytics.orders,
  assertions (
    forall(criteria := (
      total_amount >= 0,
      discount_amount <= total_amount,
      order_date <= CURRENT_DATE
    ))
  )
);
```

### Referential integrity

Check foreign key relationships:

```sql
-- Custom audit for orphaned records
AUDIT (name no_orphaned_order_items);
SELECT oi.*
FROM @this_model oi
LEFT JOIN sushi.orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
```

### Value range validation

Ensure values fall within expected ranges:

```sql
MODEL (
  name analytics.revenue,
  assertions (
    accepted_range(column := revenue, min_v := 0, max_v := 100000000),
    accepted_values(column := status, is_in := ('active', 'churned', 'suspended'))
  )
);
```

## Working with incremental models

For incremental by time range models, audits only run on the intervals being processed:

```sql
MODEL (
  name analytics.daily_metrics,
  kind INCREMENTAL_BY_TIME_RANGE (time_column metric_date),
  assertions (
    not_null(columns := (metric_date, metric_value)),
    number_of_rows(threshold := 1)
  )
);
```

The audit validates only the data for the current processing window, not the entire table.

## Debugging failed audits

When an audit fails, Vulcan shows you which rows caused the failure:

```bash
$ vulcan audit
Found 1 audit(s).
assert_positive_order_ids FAIL.

Failure in audit assert_positive_order_ids for model sushi.orders (audits/orders.sql).
Got 3 results, expected 0.
SELECT * FROM vulcan.sushi__orders__1836721418 WHERE order_id <= 0

Done.
```

### Investigating failures

1. **Check the audit query** - Review what data the audit is checking
2. **Query the model directly** - Run the audit query manually to see failing rows
3. **Check upstream models** - The issue might be in source data or upstream transformations
4. **Review recent changes** - Model changes might have introduced the issue

### Fixing audit failures

**If the issue is in source data:**
1. Fix the source data
2. Run a restatement plan on the first Vulcan model that ingests the data
3. This restates all downstream models automatically

**If the issue is in model logic:**
1. Update the model's SQL logic
2. Apply the change with `vulcan plan`
3. Vulcan automatically re-evaluates downstream models

## Best practices

### ✅ DO:

- **Use audits for critical validations** - Rules that must never fail
- **Start with built-in audits** - They cover most common cases
- **Use descriptive audit names** - Makes debugging easier
- **Group related audits** - Keep audits for the same model together
- **Test audits incrementally** - Add audits gradually as you understand your data

### ❌ DON'T:

- Don't use audits for warnings - Use checks instead for non-blocking validation
- Don't skip audit failures - Fix the root cause, don't disable audits
- Don't create overly complex audits - Keep them simple and focused
- Don't audit every column - Focus on critical business rules

## Plan vs Run behavior

**Plan:**
- Audits run before promoting changes to production
- If an audit fails, production tables are untouched
- Invalid data stays in isolated tables

**Run:**
- Audits run directly against production
- If an audit fails, invalid data may already be in production
- Execution stops to prevent downstream models from using bad data

## Skipping audits

You can temporarily skip an audit by setting `skip` to `true`:

```sql
AUDIT (
  name assert_item_price_is_not_null,
  skip true
);
SELECT * FROM sushi.items WHERE price IS NULL;
```

Use this sparingly - prefer fixing the underlying issue instead.

## Next steps

- Learn about [built-in audits](../concepts/audits.md#built-in-audits) - Comprehensive reference
- Set up [quality checks](./checks.md) - Non-blocking monitoring
- Read the [audits concepts](../concepts/audits.md) - Deep dive into how audits work

