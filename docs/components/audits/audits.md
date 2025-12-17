# Audits

Audits are your data quality bouncers—they stop bad data at the door before it can cause problems downstream. Think of them as strict validators that run after every model execution and halt your pipeline if something's wrong.

Unlike [tests](../tests/tests.md) (which you run manually to verify logic), audits run automatically whenever you apply a [plan](./plans.md). They're perfect for catching data quality issues early, whether they come from external vendors, upstream teams, or your own model changes.

**Here's the key thing:** All audits in Vulcan are blocking. When an audit fails, Vulcan stops everything—no plan application, no run execution, nothing. This might sound strict, but it's actually a good thing. It prevents bad data from propagating through your entire pipeline and causing headaches later.

A comprehensive suite of audits helps you catch problems upstream, builds trust in your data across the organization, and lets your team work with confidence knowing that invalid data won't slip through.

> **Note:** For incremental by time range models, audits only run on the intervals being processed, not the entire table. This keeps things fast and focused on what actually changed.

## Terminology: Audits and Assertions

Before we dive in, let's clear up some terminology. Vulcan uses two related but distinct concepts:

- **AUDIT** - The validation rule itself (the SQL query that checks for problems)
- **ASSERTION** - Attaching an audit to a model (claiming it should pass)

Think of it this way: an audit is the rule ("prices must be positive"), and an assertion is you saying "this model follows that rule."

**In MODEL definitions:**

```sql
-- Define the AUDIT (the rule)
AUDIT (name check_positive_price);
SELECT * FROM @this_model WHERE price <= 0;

-- Make ASSERTIONS about your model (attach the audit)
MODEL (
  name products,
  assertions (check_positive_price)  -- Declaring this audit should pass
);
```

> **Note:** You might see older code using `audits` instead of `assertions` in MODEL definitions. Both work identically, but `assertions` is clearer—you're asserting that your model passes these audits. This documentation uses `assertions` throughout.

## How Audits Work

When an audit fails, Vulcan stops everything. No ifs, ands, or buts. This is by design—it's better to catch problems early than to let bad data flow downstream and cause bigger issues.

Here's what happens when you run a model:

1. **Evaluate the model** - Vulcan runs your model SQL (inserts new data, rebuilds the table, etc.)
2. **Run the audit query** - Vulcan executes your audit SQL against the newly updated table. For incremental models, this only checks the intervals you're processing (keeps things fast!)
3. **Check the results** - If the query returns any rows, the audit fails and everything stops

**Why this matters:** Audits query for bad data. If your audit finds bad data (returns rows), that's a problem. If it finds nothing (returns zero rows), you're good to go.

### Plan vs. Run

The difference between `plan` and `run` matters a lot when it comes to audits:

**`plan`** - The safe way:
- Vulcan evaluates and audits all modified models *before* promoting them to production
- If an audit fails, the plan stops and your production table is untouched
- Invalid data stays in an isolated table and never reaches production
- This is like testing in a sandbox before deploying

**`run`** - The direct way:
- Vulcan evaluates and audits models directly against the production environment
- If an audit fails, the run stops, but the invalid data *is already in production*
- The blocking prevents this bad data from being used to build downstream models
- This is like deploying directly—faster, but riskier

**Which should you use?** For production changes, use `plan`. It's safer and gives you a chance to fix issues before they hit production. Use `run` when you're confident or doing quick iterations.

### Fixing a Failed Audit

So an audit failed. Don't panic! Here's how to fix it:

1. **Find the root cause** - Look at the audit query results. What data failed? Check upstream models and data sources.

2. **Fix the source** - This depends on where the problem came from:
   - **External data source?** Fix it at the source, then run a [restatement plan](./plans.md#restatement-plans) on the first Vulcan model that ingests it. This will restate all downstream models automatically.
   - **Vulcan model?** Update the model's logic, then apply the change with a `plan`. Vulcan will automatically re-evaluate all downstream models.

The key is fixing the root cause, not just the symptom. If bad data is coming from upstream, fixing it downstream won't help long-term.

## User-Defined Audits

You can write your own audits! They're just SQL queries that should return zero rows. If they return rows, that means they found bad data and the audit fails.

Audits live in `.sql` files in an `audits` directory in your project. You can put multiple audits in one file (organize them however makes sense) or define them inline in your model files.

### Your First Audit

Let's create a simple audit. Here's the basic structure:

```sql linenums="1"
AUDIT (
  name assert_item_price_is_not_null,
  dialect spark
);
SELECT * from sushi.items
WHERE
  ds BETWEEN @start_ds AND @end_ds
  AND price IS NULL;
```

This audit checks that every sushi item has a price. If any items are missing prices (the query returns rows), the audit fails.

**A few things to note:**
- The `name` is what you'll reference when attaching it to a model
- If your query uses a different SQL dialect than your project, specify it with `dialect` (like `spark` in the example)
- The `@start_ds` and `@end_ds` macros are automatically filled in for incremental models

To actually use this audit, attach it to a model:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (assert_item_price_is_not_null)
);
```

Now this audit runs every time the `sushi.items` model runs. Pretty straightforward!

### Generic Audits

Here's where audits get really powerful. You can create parameterized audits that work across multiple models. This saves you from writing the same audit over and over.

Consider this audit that checks if a column exceeds a threshold:

```sql linenums="1"
AUDIT (
  name does_not_exceed_threshold
);
SELECT * FROM @this_model
WHERE @column >= @threshold;
```

This uses [macros](./macros/overview.md) to make it flexible:
- `@this_model` is a special macro that refers to the model being audited (and handles incremental models correctly)
- `@column` and `@threshold` are parameters you'll specify when you use the audit

Now you can use this same audit for different columns and thresholds:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    does_not_exceed_threshold(column := id, threshold := 1000),
    does_not_exceed_threshold(column := price, threshold := 100)
  )
);
```

See how we're using the same audit twice with different parameters? That's the power of generic audits. You can even use the same audit multiple times on the same model with different parameters.

**Default values:**

You can set default values for parameters:

```sql linenums="1"
AUDIT (
  name does_not_exceed_threshold,
  defaults (
    threshold = 10,
    column = id
  )
);
SELECT * FROM @this_model
WHERE @column >= @threshold;
```

Now if someone uses the audit without specifying parameters, it'll use these defaults. Handy for common cases!

**Global audits:**

You can also apply audits globally using model defaults:

```sql linenums="1"
model_defaults:
  assertions:
    - assert_positive_order_ids
    - does_not_exceed_threshold(column := id, threshold := 1000)
```

This applies these audits to all models by default. Useful for organization-wide rules!

> **Note:** In `model_defaults`, you can use either `audits` or `assertions`—both work for backward compatibility.

### Naming

**Avoid SQL keywords** when naming audit parameters. If you must use a keyword, quote it.

For example, if your audit uses a `values` parameter (which is a SQL keyword), you'll need quotes:

```sql linenums="1" hl_lines="4"
MODEL (
  name sushi.items,
  assertions (
    my_audit(column := a, "values" := (1,2,3))
  )
)
```

It's easier to just avoid keywords in the first place, but if you need them, quotes work fine.

### Inline Audits

You can also define audits right in your model file. This is handy when an audit is specific to one model:

```sql linenums="1"
MODEL (
    name sushi.items,
    assertions(does_not_exceed_threshold(column := id, threshold := 1000), price_is_not_null)
);
SELECT id, price
FROM sushi.seed;

AUDIT (name does_not_exceed_threshold);
SELECT * FROM @this_model
WHERE @column >= @threshold;

AUDIT (name price_is_not_null);
SELECT * FROM @this_model
WHERE price IS NULL;
```

You can define multiple audits in the same file. Just make sure they're defined before (or alongside) the MODEL that uses them.

## Built-in Audits

Vulcan comes with a whole suite of built-in audits that cover most common use cases. These are ready to use—no need to write SQL yourself for these scenarios.

All built-in audits are blocking (they stop execution when they fail), and they're grouped by what they check. Let's walk through them:

### Generic Assertion Audit

#### `forall`

The most flexible built-in audit. It lets you write arbitrary boolean SQL expressions:

```sql linenums="1" hl_lines="4-7"
MODEL (
  name sushi.items,
  assertions (
    forall(criteria := (
      price > 0,
      LENGTH(name) > 0
    ))
  )
);
```

This checks that all rows have a `price` greater than 0 AND a `name` with at least one character. You can add as many criteria as you want—they all need to pass.

### Row Counts and NULL Value Audits

These audits check that you have enough data and that required fields aren't missing.

#### `number_of_rows`

Make sure you have enough rows. Useful for catching cases where a model didn't run properly or data didn't load:

```sql linenums="1"
MODEL (
  name sushi.orders,
  assertions (
    number_of_rows(threshold := 10)
  )
);
```

This ensures your model has more than 10 rows. If you have 10 or fewer, something's probably wrong.

#### `not_null`

The classic "required field" check. Ensures specified columns don't have NULL values:

```sql linenums="1"
MODEL (
  name sushi.orders,
  assertions (
    not_null(columns := (id, customer_id, waiter_id))
  )
);
```

This checks that `id`, `customer_id`, and `waiter_id` are never NULL. If any of them are NULL, the audit fails.

#### `at_least_one`

Sometimes you just need at least one non-NULL value, not all of them. This is useful for optional fields that should have some data:

```sql linenums="1"
MODEL (
  name sushi.customers,
  assertions (
    at_least_one(column := zip)
    )
);
```

This ensures the `zip` column has at least one non-NULL value. Maybe most customers don't have zip codes, but at least some should.

#### `not_null_proportion`

Check that NULL values don't exceed a certain percentage. Useful when some NULLs are okay, but too many is a problem:

```sql linenums="1"
MODEL (
  name sushi.customers,
  assertions (
    not_null_proportion(column := zip, threshold := 0.8)
    )
);
```

This ensures that at least 80% of rows have a zip code. The other 20% can be NULL, but if more than 20% are missing, that's a problem.

### Specific Data Values Audits

These audits check the actual values in your data, not just whether they exist.

#### `not_constant`

Make sure a column has variety. If every row has the same value, something might be wrong:

```sql linenums="1"
MODEL (
  name sushi.customer_revenue_by_day,
  assertions (
    not_constant(column := customer_id)
    )
);
```

This ensures `customer_id` has at least two different non-NULL values. If every row has the same customer ID, that's suspicious.

#### `unique_values`

The classic uniqueness check. Ensures no duplicate values:

```sql linenums="1"
MODEL (
  name sushi.orders,
  assertions (
    unique_values(columns := (id, item_id))
  )
);
```

This checks that `id` and `item_id` each have unique values. No duplicates allowed!

#### `unique_combination_of_columns`

Check uniqueness across multiple columns. Maybe individual columns can repeat, but combinations must be unique:

```sql linenums="1"
MODEL (
  name sushi.orders,
  assertions (
    unique_combination_of_columns(columns := (id, ds))
  )
);
```

This ensures that the combination of `id` and `ds` is unique. So `id` can repeat across different dates, but the same `id` can't appear twice on the same date.

#### `accepted_values`

Make sure values are in an allowed set. Like an enum check:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    accepted_values(column := name, is_in := ('Hamachi', 'Unagi', 'Sake'))
  )
);
```

This ensures that `name` is one of the three allowed values. Anything else fails the audit.

!!! note
    Rows with `NULL` values will pass this audit in most databases. If you want to reject NULLs, combine this with a `not_null` audit.

#### `not_accepted_values`

The opposite—make sure certain values are NOT present:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    not_accepted_values(column := name, is_in := ('Hamburger', 'French fries'))
  )
);
```

This ensures that `name` is never 'Hamburger' or 'French fries'. Useful for catching data that shouldn't be there.

!!! note
    This audit doesn't support rejecting `NULL` values. Use `not_null` if you need to ensure no NULLs.

### Numeric Data Audits

These audits check numeric ranges and distributions.

#### `sequential_values`

Check that values are sequential. Useful for IDs or sequence numbers:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    sequential_values(column := item_id, interval := 1)
  )
);
```

This ensures that `item_id` values are sequential (1, 2, 3, 4...). If you have gaps or duplicates, the audit fails.

#### `accepted_range`

Check that values are within a numeric range:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    accepted_range(column := price, min_v := 1, max_v := 100)
  )
);
```

This ensures all prices are between 1 and 100 (inclusive). Values outside this range fail the audit.

**Exclusive ranges:**

You can make the range exclusive (not including the boundaries):

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    accepted_range(column := price, min_v := 0, max_v := 100, inclusive := false)
  )
);
```

Now prices must be greater than 0 and less than 100 (not equal to the boundaries).

#### `mutually_exclusive_ranges`

Check that ranges don't overlap. Useful for pricing tiers or time slots:

```sql linenums="1"
MODEL (
  name pricing.tier_ranges,
  assertions (
    mutually_exclusive_ranges(lower_bound_column := min_price, upper_bound_column := max_price)
  )
);
```

This ensures that each row's price range [min_price, max_price] doesn't overlap with any other row's range. Perfect for ensuring pricing tiers don't conflict.

### Character Data Audits

These audits check string formats and patterns.

!!! warning
    Different databases may behave differently with character sets or languages. Test your audits!

#### `not_empty_string`

Make sure strings aren't empty. NULL is okay, but empty strings `''` are not:

```sql linenums="1"
MODEL (
  name sushi.items,
  assertions (
    not_empty_string(column := name)
  )
);
```

This ensures no `name` is an empty string. NULL values pass, but `''` fails.

#### `string_length_equal`

Check that all strings have the exact same length:

```sql linenums="1"
MODEL (
  name sushi.customers,
  assertions (
    string_length_equal(column := zip, v := 5)
    )
);
```

This ensures all `zip` values are exactly 5 characters. Useful for fixed-length codes.

#### `string_length_between`

Check that string lengths are within a range:

```sql linenums="1"
MODEL (
  name sushi.customers,
  assertions (
    string_length_between(column := name, min_v := 5, max_v := 50)
    )
);
```

This ensures all `name` values are between 5 and 50 characters (inclusive).

**Exclusive ranges:**

You can make the range exclusive:

```sql linenums="1"
MODEL (
  name sushi.customers,
  assertions (
    string_length_between(column := zip, min_v := 4, max_v := 60, inclusive := false)
    )
);
```

Now names must be longer than 4 characters and shorter than 60 (not equal to the boundaries).

#### `valid_uuid`

Check that values match UUID format:

```sql linenums="1"
MODEL (
  name events.user_sessions,
  assertions (
    valid_uuid(column := uuid)
    )
);
```

This ensures all `uuid` values match the UUID structure (like `550e8400-e29b-41d4-a716-446655440000`).

#### `valid_email`

Check email format:

```sql linenums="1"
MODEL (
  name dim.users,
  assertions (
    valid_email(column := email)
    )
);
```

This ensures all `email` values look like valid email addresses (has `@`, has domain, etc.).

#### `valid_url`

Check URL format:

```sql linenums="1"
MODEL (
  name dim.products,
  assertions (
    valid_url(column := url)
    )
);
```

This ensures all `url` values are valid URLs (starts with `http://`, `https://`, or `ftp://`, etc.).

#### `valid_http_method`

Check that values are valid HTTP methods:

```sql linenums="1"
MODEL (
  name logs.api_requests,
  assertions (
    valid_http_method(column := http_method)
  )
);
```

This ensures `http_method` is one of: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`, `TRACE`, `CONNECT`.

#### `match_regex_pattern_list`

Check that values match at least one regex pattern:

```sql linenums="1"
MODEL (
  name products.inventory,
  assertions (
    match_regex_pattern_list(column := todo, patterns := ('^\d.*', '.*!$'))
  )
);
```

This ensures all `todo` values match at least one pattern: either start with a digit (`^\d.*`) or end with an exclamation mark (`.*!$`).

#### `not_match_regex_pattern_list`

The opposite—make sure values don't match any pattern:

```sql linenums="1"
MODEL (
  name products.inventory,
  assertions (
    not_match_regex_pattern_list(column := todo, patterns := ('^!.*', '.*\d$'))
  )
);
```

This ensures no `todo` values start with `!` or end with a digit.

#### `match_like_pattern_list`

Check that values match at least one SQL LIKE pattern:

```sql linenums="1"
MODEL (
  name sales.customers,
  assertions (
    match_like_pattern_list(column := name, patterns := ('jim%', 'pam%'))
  )
);
```

This ensures all `name` values start with 'jim' or 'pam'. Uses SQL LIKE syntax, so `%` matches any characters.

#### `not_match_like_pattern_list`

Make sure values don't match any LIKE pattern:

```sql linenums="1"
MODEL (
  name products.catalog,
  assertions (
    not_match_like_pattern_list(column := name, patterns := ('%doe', '%smith'))
  )
);
```

This ensures no `name` values end with 'doe' or 'smith'.

### Statistical Audits

These audits check statistical properties of your data. They're powerful but require some tuning to get the thresholds right.

!!! note
    Statistical audit thresholds usually need fine-tuning through trial and error. Start with wide ranges and tighten them as you learn what's normal for your data.

#### `mean_in_range`

Check that a column's average is within a range:

```sql linenums="1"
MODEL (
  name analytics.customer_metrics,
  assertions (
    mean_in_range(column := age, min_v := 21, max_v := 50)
    )
);
```

This ensures the average `age` is between 21 and 50. Useful for catching when your data distribution shifts unexpectedly.

**Exclusive ranges:**

```sql linenums="1"
MODEL (
  name analytics.customer_metrics,
  assertions (
    mean_in_range(column := age, min_v := 18, max_v := 65, inclusive := false)
    )
);
```

Now the mean must be greater than 18 and less than 65 (not equal to the boundaries).

#### `stddev_in_range`

Check that standard deviation is within a range:

```sql linenums="1"
MODEL (
  name analytics.customer_metrics,
  assertions (
    stddev_in_range(column := age, min_v := 2, max_v := 5)
  )
);
```

This ensures the standard deviation of `age` is between 2 and 5. Useful for detecting when your data becomes more or less spread out than expected.

**Exclusive ranges:**

```sql linenums="1"
MODEL (
  name analytics.customer_metrics,
  assertions (
    stddev_in_range(column := age, min_v := 3, max_v := 6, inclusive := false)
  )
);
```

Now the standard deviation must be greater than 3 and less than 6.

#### `z_score`

Check for statistical outliers. Values with high z-scores are far from the mean:

```sql linenums="1"
MODEL (
  name sales.transactions,
  assertions (
    z_score(column := age, threshold := 3)
    )
);
```

This ensures no `age` values have a z-score greater than 3 (meaning they're more than 3 standard deviations from the mean). Useful for catching outliers that might indicate data quality issues.

The z-score is calculated as: `ABS(([row value] - [column mean]) / NULLIF([column standard deviation], 0))`

#### `kl_divergence`

Check how different two distributions are. Useful for comparing current data to a reference:

```sql linenums="1"
MODEL (
  name analytics.cohort_comparison,
  assertions (
    kl_divergence(column := age, target_column := reference_age, threshold := 0.1)
    )
);
```

This ensures the [symmetrised Kullback-Leibler divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence#Symmetrised_divergence) (also called "Jeffreys divergence" or "Population Stability Index") between `age` and `reference_age` is less than or equal to 0.1.

Lower values mean the distributions are more similar. This is great for detecting when your data distribution has shifted significantly from a known good reference.

#### `chi_square`

Check the relationship between two categorical columns:

```sql linenums="1"
MODEL (
  name analytics.user_segments,
  assertions (
    chi_square(column := user_state, target_column := user_type, critical_value := 6.635)
    )
);
```

This ensures the [chi-square statistic](https://en.wikipedia.org/wiki/Chi-squared_test) for `user_state` and `user_type` doesn't exceed 6.635.

**Finding critical values:**

You can look up critical values in a [chi-square table](https://www.medcalc.org/manual/chi-square-table.php) or calculate them with Python:

```python linenums="1"
from scipy.stats import chi2

# critical value for p-value := 0.95 and degrees of freedom := 1
chi2.ppf(0.95, 1)
```

This is useful for detecting when the relationship between two categorical variables has changed unexpectedly.

## Running Audits

### The CLI Audit Command

You can run audits manually with the `vulcan audit` command:

```bash
$ vulcan -p project audit --start 2022-01-01 --end 2022-01-02
Found 1 audit(s).
assert_item_price_is_not_null FAIL.

Finished with 1 audit error(s).

Failure in audit assert_item_price_is_not_null for model sushi.items (audits/items.sql).
Got 3 results, expected 0.
SELECT * FROM vulcan.sushi__items__1836721418_83893210 WHERE ds BETWEEN '2022-01-01' AND '2022-01-02' AND price IS NULL
Done.
```

This is useful for testing audits before running a full plan, or for debugging why an audit is failing. The output shows you exactly what query failed and how many rows it found.

### Automated Auditing

When you apply a plan, Vulcan automatically runs all audits for models being evaluated. You don't need to do anything special—just run your plan and audits happen automatically.

If any audit fails, Vulcan halts the pipeline immediately. This prevents bad data from propagating downstream and causing bigger problems. It might be annoying when it happens, but trust us—it's better than finding out later that bad data made it into production.

## Advanced Usage

### Skipping Audits

Sometimes you need to temporarily disable an audit. Maybe you're debugging, or you know there's a temporary data issue you're working on fixing. You can skip audits by setting `skip` to `true`:

```sql linenums="1" hl_lines="3"
AUDIT (
  name assert_item_price_is_not_null,
  skip true
);
SELECT * from sushi.items
WHERE ds BETWEEN @start_ds AND @end_ds AND
   price IS NULL;
```

**Use this sparingly!** Skipped audits won't run, which means they won't catch problems. It's better to fix the underlying issue than to skip the audit. But sometimes you need it for debugging or temporary situations.

## Troubleshooting

### Audit Fails Unexpectedly

**Problem:** Your audit is failing, but you're not sure why.

**Solution:** Run the audit query manually to see what it's finding:

```bash
vulcan -p project audit --start 2022-01-01 --end 2022-01-02 --verbose
```

This will show you the exact query and the rows that failed. Once you see what data is causing the failure, you can either fix the data or adjust the audit.

### Audit Too Strict

**Problem:** Your audit is failing during normal operation, even though the data is actually fine.

**Solution:** Review your thresholds. Maybe your `accepted_range` is too narrow, or your `number_of_rows` threshold is too high. Statistical audits especially need tuning—start with wide ranges and tighten them as you learn what's normal.

### Performance Issues

**Problem:** Audits are slowing down your plan execution.

**Solution:** 
- Make sure your audit queries use indexes on the columns they're checking
- For incremental models, audits only run on processed intervals (which helps), but you can also add date filters to your audit queries
- Consider if you really need all those audits—sometimes less is more

### Understanding Audit Results

When an audit fails, Vulcan shows you:
- Which audit failed
- Which model it was attached to
- The exact query that was run
- How many rows were returned (when it expected 0)

Use this information to understand what went wrong. The query results tell you exactly what data failed the check.
