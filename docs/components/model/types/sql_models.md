# SQL

SQL models are Vulcan's bread and butter, they're the most common type of model you'll write. You can define them using SQL directly, or use Python to generate SQL dynamically.

**Why SQL models?** They're simple, powerful, and work with any SQL database. Most of your data transformations will probably be SQL models.

## SQL-Based Definition

SQL-based models are the most common type. They're designed to feel like regular SQL, but with superpowers.

**Structure:** A SQL model file has these parts (in order):

1. The `MODEL` DDL (metadata and configuration)
2. Optional pre-statements (setup SQL)
3. A single query (your transformation logic)
4. Optional post-statements (cleanup/optimization SQL)
5. Optional on-virtual-update statements (view permissions, etc.)

**Creating a SQL model:** Add a `.sql` file to your `models/` directory (or a subdirectory). The filename doesn't matter to Vulcan, but it's conventional to name it after your model. For example, `sales.daily_sales` → `daily_sales.sql`.

### Example

Here's a simple SQL model to get you started:

```sql linenums="1"
-- This is the MODEL DDL, where you specify model metadata and configuration information.
MODEL (
  name sales.daily_sales,
  kind FULL,
  cron '@daily',
  grain order_date
);

/*
  This is the single query that defines the model's logic.
  Although it is not required, it is considered best practice to explicitly
  specify the type for each one of the model's columns through casting.
*/
SELECT
  CAST(order_date AS TIMESTAMP)::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue,
  MAX(order_id)::VARCHAR AS last_order_id
FROM raw.raw_orders
GROUP BY order_date
ORDER BY order_date
```

### `MODEL` DDL

The `MODEL` DDL is where you define your model's metadata, name, kind, schedule, owner, and more. It must be the first statement in your SQL file.

Think of it as the "header" that tells Vulcan everything it needs to know about your model. For a complete list of all available properties, check out the [Model Properties](../overview.md#model-properties) documentation.

### Optional Pre/Post-Statements

Pre-statements run before your query, post-statements run after. They're perfect for setup, cleanup, and optimization tasks.

**Common use cases:**

- Pre-statements: Set session parameters, load UDFs, cache tables
- Post-statements: Create indexes, run data quality checks, set retention policies

**Important:** Pre/post-statements must end with semicolons. If you have post-statements, your main query must also end with a semicolon (so Vulcan knows where the query ends).

!!! warning "Concurrency"

    Be careful with pre-statements that create or alter physical tables, if multiple models run concurrently, you could get conflicts. Stick to session settings and temporary objects.

```sql linenums="1"
MODEL (
  name sales.daily_sales,
  kind FULL
);

-- Pre-statement: Cache a table for use in the query
CACHE TABLE countries AS SELECT * FROM raw.countries;

-- The model query (must end with semi-colon when post-statements are present)
SELECT
  order_date::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders,
  SUM(total_amount)::FLOAT AS total_revenue
FROM raw.raw_orders
GROUP BY order_date;

-- Post-statement: Clean up the cached table
UNCACHE TABLE countries;
```

**Project-level defaults:** You can define pre/post-statements in `model_defaults` for consistent behavior across all models. Default statements run first, then model-specific ones. Learn more in the [model configuration reference](../../../references/model_configuration.md#model-defaults).

!!! warning "Statements Run Twice"

Pre/post-statements are evaluated twice: when a model's table is created and when its query logic is evaluated. Executing statements more than once can have unintended side-effects, so you can [conditionally execute](../../advanced-features/macros/built_in.md#prepost-statements) them based on Vulcan's [runtime stage](../../advanced-features/macros/variables.md#runtime-variables).

    **Solution:** Use conditional execution with `@IF` and `@runtime_stage` to control when statements run. For example, only run a post-statement when the query is actually being evaluated:

We can condition the post-statement to only run after the model query is evaluated using the [`@IF` macro operator](../../advanced-features/macros/built_in.md#if) and [`@runtime_stage` macro variable](../../advanced-features/macros/variables.md#runtime-variables) like this:

```sql linenums="1" hl_lines="14-17"
MODEL (
  name sales.daily_sales,
  kind FULL
);

CACHE TABLE countries AS SELECT * FROM raw.countries;

SELECT
  order_date::TIMESTAMP AS order_date,
  COUNT(order_id)::INTEGER AS total_orders
FROM raw.raw_orders
GROUP BY order_date;

@IF(
  @runtime_stage = 'evaluating',
  UNCACHE TABLE countries
);
```

**Important:** The SQL command inside `@IF()` doesn't end with a semicolon. The semicolon goes after the `@IF()` macro's closing parenthesis.

### Optional On-Virtual-Update Statements

On-virtual-update statements run when views are created or updated in the virtual layer. This happens after your model's physical table is created and the view is set up.

**Common use case:** Granting permissions on views so users can query them.

**Project-level defaults:** You can also define on-virtual-update statements at the project level using `model_defaults` in your configuration. These will be applied to all models in your project and merged with any model-specific statements. Default statements are executed first, followed by model-specific statements. Learn more about this in the [model configuration reference](../../../references/model_configuration.md#model-defaults).

**Syntax:** Wrap these statements in `ON_VIRTUAL_UPDATE_BEGIN;` ... `ON_VIRTUAL_UPDATE_END;` blocks:

```sql linenums="1" hl_lines="10-15"
MODEL (
  name sales.daily_sales,
  kind FULL
);

SELECT
  order_date::TIMESTAMP,
  COUNT(order_id)::INTEGER AS total_orders
FROM raw.raw_orders
GROUP BY order_date;

ON_VIRTUAL_UPDATE_BEGIN;
GRANT SELECT ON VIEW @this_model TO ROLE role_name;
JINJA_STATEMENT_BEGIN;
GRANT SELECT ON VIEW {{ this_model }} TO ROLE admin;
JINJA_END;
ON_VIRTUAL_UPDATE_END;
```

**Jinja support:** You can use [Jinja expressions](../../advanced-features/macros/jinja.md) in these statements. Just wrap them in `JINJA_STATEMENT_BEGIN;` ... `JINJA_END;` blocks (as shown in the example above).

!!! note "Virtual Layer Resolution"

    These statements run at the virtual layer, so table names resolve to view names, not physical table names. In a `dev` environment, `sales.daily_sales` and `@this_model` resolve to `sales__dev.daily_sales` (the view), not the physical table.

### The Model Query

Your model must contain a standalone query. This can be:

- A single `SELECT` statement
- Multiple `SELECT` statements combined with `UNION`, `INTERSECT`, or `EXCEPT`

The result of this query becomes your model's table or view data. Pretty straightforward!

### SQL Model Blueprinting

SQL models can serve as templates for creating multiple models. This is called "blueprinting", define one template, get multiple models.

**How it works:** Parameterize your model name with a variable (using `@{variable}` syntax) and provide a list of mappings in `blueprints`. Vulcan creates one model for each mapping.

**Use case:** When you have similar models that differ only by parameters (like different regions, schemas, or customers).

Here's an example that creates four models from one template:

```sql linenums="1"
MODEL (
  name vulcan_demo.fct_daily_sales__@{region},
  kind VIEW,
  blueprints (
    (region := 'north'),
    (region := 'south'),
    (region := 'east'),
    (region := 'west')
  ),
  grains region_id
);

SELECT
  *
FROM vulcan_demo.fct_daily_sales
@WHERE(TRUE)
  LOWER(region_name) = LOWER(@region)
```

Vulcan creates these four models from that template:

```sql linenums="1"
-- This uses the first variable mapping
MODEL (
  name vulcan_demo.fct_daily_sales__north,
  kind VIEW
);

SELECT
  *
FROM vulcan_demo.fct_daily_sales
WHERE
  LOWER(region_name) = LOWER('north')

-- This uses the second variable mapping
MODEL (
  name vulcan_demo.fct_daily_sales__south,
  kind VIEW
);

SELECT
  *
FROM vulcan_demo.fct_daily_sales
WHERE
  LOWER(region_name) = LOWER('south')
```

**Important syntax:** Notice `@{region}` in the model name. The curly braces tell Vulcan to treat the variable value as a SQL identifier (not a string literal).

You can see the different behavior in the WHERE clause. `@region` (without braces) is resolved to the string literal `'north'` (with single quotes) because the blueprint value is quoted. Learn more about the curly brace syntax [here](../../advanced-features/macros/built_in.md#embedding-variables-in-strings).


**Dynamic blueprints:** You can generate blueprints using macros. This is handy when your blueprint list comes from external sources (CSV files, APIs, etc.):

```sql
MODEL (
  name vulcan_demo.fct_daily_sales__@{region},
  blueprints @gen_blueprints(),  -- Macro generates the list
  ...
);
```

Here's how you might define the macro:

```python linenums="1"
from vulcan import macro

@macro()
def gen_blueprints(evaluator):
    return (
        "((region := 'north'),"
        " (region := 'south'),"
        " (region := 'east'),"
        " (region := 'west'))"
    )
```

You can also use the `@EACH` macro with a global list variable:

```sql linenums="1"
MODEL (
  name vulcan_demo.fct_daily_sales__@{region},
  kind VIEW,
  blueprints @EACH(@values, x -> (region := @x)),
);

SELECT
  *
FROM vulcan_demo.fct_daily_sales
@WHERE(TRUE)
  LOWER(region_name) = LOWER(@region)
```

## Python-Based Definition

You can also define SQL models using Python! This is useful when:

- Your query is too complex for clean SQL
- You need heavy dynamic logic (would require lots of macros)
- You want to generate SQL programmatically

**How it works:** You write Python code that generates SQL, and Vulcan executes it. You still get SQL models (they run SQL queries), but you write them in Python.

For the complete guide on Python-based SQL models, including the `@model` decorator, execution context, and examples, see the [Python Models](python_models.md) page.

## Automatic Dependencies

One of Vulcan's superpowers: it parses your SQL and automatically figures out dependencies. No need to manually specify what your model depends on, Vulcan just knows!

**How it works:** Vulcan analyzes your `FROM` and `JOIN` clauses and builds a dependency graph. When you run `vulcan plan`, it ensures upstream models run first.

**Example:** This query automatically depends on `raw.raw_orders`:

```sql
SELECT order_date, COUNT(order_id) AS total_orders
FROM raw.raw_orders
GROUP BY order_date
```

Vulcan will make sure `raw.raw_orders` runs before this model. Pretty neat!

**External dependencies:** If you reference tables that aren't Vulcan models, Vulcan can handle them too, either implicitly (through execution order) or via [signals](../../advanced-features/signals.md).

**Manual dependencies:** Sometimes you need to add extra dependencies manually (maybe a hidden dependency or a macro that references another model). Use the `depends_on` property in your `MODEL` DDL for that.

## Conventions

Vulcan follows some conventions to keep things consistent and reliable. Here are the key ones:

### Explicit Type Casting

Vulcan encourages explicit type casting for all columns. This helps Vulcan understand your data types and prevents incorrect inference.

**Format:** Use `column_name::data_type` syntax (works in any SQL dialect):

```sql
SELECT
  order_date::DATE AS order_date,
  total_orders::INTEGER AS total_orders,
  revenue::DECIMAL(10,2) AS revenue
```

**Why this matters:** Explicit types make your models more predictable and help Vulcan optimize queries better.

### Explicit SELECTs

Avoid `SELECT *` when possible. It's convenient, but dangerous, if an upstream source adds or removes columns, your model's output changes unexpectedly.

**Best practice:** List every column you need explicitly. If you're querying external sources, use [`create_external_models`](../../../getting_started/cli.md#create_external_models) to capture their schema, or define them as [external models](../model_kinds.md#external).

**Why avoid `SELECT *` on external sources:** It prevents Vulcan from optimizing queries and determining column-level lineage. Define external models instead!

### Encoding

SQL model files must be UTF-8 encoded. Using other encodings can cause parsing errors or unexpected behavior.

## Transpilation

Vulcan uses [SQLGlot](https://github.com/tobymao/sqlglot) to parse and transpile SQL. This gives you some superpowers:

**Write in any dialect, run on any engine:** Write PostgreSQL-style SQL, and Vulcan converts it to BigQuery. Or write Snowflake SQL and run it on Spark. Pretty cool!

**Use advanced syntax:** You can use features from one dialect even if your engine doesn't support them. For example, `x::int` (PostgreSQL syntax) works even on engines that only support `CAST(x AS INT)`. SQLGlot handles the conversion.

**Formatting flexibility:** Trailing commas, extra whitespace, minor formatting differences, SQLGlot normalizes them all. Write SQL however you like, and Vulcan makes it consistent.

## Macros

<<<<<<< Updated upstream
Standard SQL is powerful, but real-world data modelss need dynamic components. Date filters that change each run, conditional logic, reusable query patterns—macros give you all of this.
=======
Standard SQL is powerful, but real-world data pipelines need dynamic components. Date filters that change each run, conditional logic, reusable query patterns, macros give you all of this.
>>>>>>> Stashed changes

**Macro variables:** Vulcan provides automatic date/time variables for incremental models. Use `@start_date`, `@end_date`, `@start_ds`, `@end_ds` and Vulcan fills them in with the current time range. No more hardcoding dates!

**Custom macros:** For complex logic or reusable patterns, Vulcan supports a powerful [macro syntax](../../advanced-features/macros/overview.md) and [Jinja templates](https://jinja.palletsprojects.com/en/3.1.x/). Write macros once, use them everywhere.

**Why macros matter:** They make your SQL more maintainable. Instead of copy-pasting complex logic, define it once as a macro and reuse it. Your queries stay clean and readable.

Learn more about macros in the [Macros documentation](../../advanced-features/macros/overview.md).
