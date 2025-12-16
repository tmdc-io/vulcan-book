# SQL models

SQL models are the main type of models used by Vulcan. These models can be defined using either SQL or Python that generates SQL.

## SQL-based definition

The SQL-based definition of SQL models is the most common one, and consists of the following sections:

* The `MODEL` DDL
* Optional pre-statements
* A single query
* Optional post-statements
* Optional on-virtual-update-statements

These models are designed to look and feel like you're simply using SQL, but they can be customized for advanced use cases.

To create a SQL-based model, add a new file with the `.sql` suffix into the `models/` directory (or a subdirectory of `models/`) within your Vulcan project. Although the name of the file doesn't matter, it is customary to use the model's name (without the schema) as the file name. For example, the file containing the model `sales.daily_sales` would be named `daily_sales.sql`.

### Example

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

The `MODEL` DDL is used to specify metadata about the model such as its name, [kind](./model_kinds.md), owner, cron, and others. This should be the first statement in your SQL-based model's file.

Refer to `MODEL` [properties](./overview.md#model-properties) for the full list of allowed properties.

### Optional pre/post-statements

Optional pre/post-statements allow you to execute SQL commands before and after a model runs, respectively.

For example, pre/post-statements might modify settings or create a table index. However, be careful not to run any statement that could conflict with the execution of another model if they are run concurrently, such as creating a physical table.

Pre/post-statements are just standard SQL commands located before/after the model query. They must end with a semi-colon, and the model query must end with a semi-colon if a post-statement is present.

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

**Project-level defaults:** You can also define pre/post-statements at the project level using `model_defaults` in your configuration. These will be applied to all models in your project and merged with any model-specific statements. Default statements are executed first, followed by model-specific statements. Learn more about this in the [model configuration reference](../../reference/model_configuration.md#model-defaults).

!!! warning

    Pre/post-statements are evaluated twice: when a model's table is created and when its query logic is evaluated. Executing statements more than once can have unintended side-effects, so you can [conditionally execute](../macros/vulcan_macros.md#prepost-statements) them based on Vulcan's [runtime stage](../macros/macro_variables.md#runtime-variables).

The pre/post-statements in the example above will run twice because they are not conditioned on runtime stage.

We can condition the post-statement to only run after the model query is evaluated using the [`@IF` macro operator](../macros/vulcan_macros.md#if) and [`@runtime_stage` macro variable](../macros/macro_variables.md#runtime-variables) like this:

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

Note that the SQL command `UNCACHE TABLE countries` inside the `@IF()` macro does **not** end with a semi-colon. Instead, the semi-colon comes after the `@IF()` macro's closing parenthesis.

### Optional on-virtual-update statements

The optional on-virtual-update statements allow you to execute SQL commands after the completion of the [Virtual Update](../plans.md#virtual-update).

These can be used, for example, to grant privileges on views of the virtual layer.

**Project-level defaults:** You can also define on-virtual-update statements at the project level using `model_defaults` in your configuration. These will be applied to all models in your project and merged with any model-specific statements. Default statements are executed first, followed by model-specific statements. Learn more about this in the [model configuration reference](../../reference/model_configuration.md#model-defaults).

These SQL statements must be enclosed within an `ON_VIRTUAL_UPDATE_BEGIN;` ...; `ON_VIRTUAL_UPDATE_END;` block like this:

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

[Jinja expressions](../macros/jinja_macros.md) can also be used within them, as demonstrated in the example above. These expressions must be properly nested within a `JINJA_STATEMENT_BEGIN;` and `JINJA_END;` block.

!!! note

    Table resolution for these statements occurs at the virtual layer. This means that table names, including `@this_model` macro, are resolved to their qualified view names. For instance, when running the plan in an environment named `dev`, `sales.daily_sales` and `@this_model` would resolve to `sales__dev.daily_sales` and not to the physical table name.

### The model query

The model must contain a standalone query, which can be a single `SELECT` expression, or multiple `SELECT` expressions combined with the `UNION`, `INTERSECT`, or `EXCEPT` operators. The result of this query will be used to populate the model's table or view.

### SQL model blueprinting

A SQL model can also serve as a template for creating multiple models, or _blueprints_, by specifying a list of key-value mappings in the `blueprints` property. In order to achieve this, the model's name must be parameterized with a variable that exists in this mapping.

For instance, the following model will result into four new models, each using the corresponding mapping in the `blueprints` property:

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

The four models produced from this template are:

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

Note the use of curly brace syntax `@{region}` in the model name above. It is used to tell Vulcan that the rendered variable value should be treated as a SQL identifier instead of a string literal.

You can see the different behavior in the WHERE clause. `@region` (without braces) is resolved to the string literal `'north'` (with single quotes) because the blueprint value is quoted. Learn more about the curly brace syntax [here](../../concepts/macros/vulcan_macros.md#embedding-variables-in-strings).

Blueprint variable mappings can also be constructed dynamically, e.g., by using a macro: `blueprints @gen_blueprints()`. This is useful in cases where the `blueprints` list needs to be sourced from external sources, such as CSV files.

For example, the definition of the `gen_blueprints` may look like this:

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

It's also possible to use the `@EACH` macro, combined with a global list variable (`@values`):

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

## Python-based definition

SQL models can also be defined using Python. This approach is beneficial when the query is too complex to express cleanly in SQL, or when you need dynamic components that would require heavy use of macros.

For comprehensive documentation on Python-based models, including the `@model` decorator, execution context, pre/post-statements, blueprinting, and examples, see the [Python models](./python_models.md) page.

## Automatic dependencies

Vulcan parses your SQL, so it understands what the code does and how it relates to other models. There is no need for you to manually specify dependencies to other models with special tags or commands.

For example, consider a model with this query:

```sql linenums="1"
SELECT
  order_date,
  COUNT(order_id) AS total_orders,
  SUM(total_amount) AS total_revenue
FROM raw.raw_orders
GROUP BY order_date
```

Vulcan will detect that the model depends on `raw.raw_orders`. When executing this model, it will ensure that `raw.raw_orders` is executed first.

External dependencies not defined in Vulcan are also supported. Vulcan can either depend on them implicitly through the order in which they are executed, or through [signals](../../guides/signals.md).

Although automatic dependency detection works most of the time, there may be specific cases for which you want to define dependencies manually. You can do so in the `MODEL` DDL with the [dependencies property](./overview.md#model-properties).

## Conventions

Vulcan encourages explicitly specifying the data types of a model's columns through casting. This allows Vulcan to understand the data types in your models, and it prevents incorrect type inference. Vulcan supports the casting format `<column name>::<data type>` in models of any SQL dialect.

### Explicit SELECTs

Although `SELECT *` is convenient, it is dangerous because a model's results can change due to external factors (e.g., an upstream source adding or removing a column). In general, we encourage listing out every column you need or using [`create_external_models`](../../reference/cli.md#create_external_models) to capture the schema of an external data source.

If you select from an external source, `SELECT *` will prevent Vulcan from performing some optimization steps and from determining upstream column-level lineage. Use an [`external` model kind](./model_kinds.md#external) to enable optimizations and upstream column-level lineage for external sources.

### Encoding

Vulcan expects files containing SQL models to be encoded according to the [UTF-8](https://en.wikipedia.org/wiki/UTF-8) standard. Using a different encoding may lead to unexpected behavior.

## Transpilation

Vulcan leverages [SQLGlot](https://github.com/tobymao/sqlglot) to parse and transpile SQL. Therefore, you can write your SQL in any supported dialect and transpile it into another supported dialect.

You can also use advanced syntax that may not be available in your engine of choice. For example, `x::int` is equivalent to `CAST(x as INT)`, but is only supported in some dialects. SQLGlot allows you to use this feature regardless of what engine you're using.

Additionally, you won't have to worry about minor formatting differences such as trailing commas, as SQLGlot will remove them at parse time.

## Macros

Although standard SQL is very powerful, complex data systems often require running SQL queries with dynamic components such as date filters. For example, you may want to change the date ranges in a `between` statement so that you can get the latest batch of data. Vulcan provides these dates automatically through [macro variables](../macros/macro_variables.md).

Additionally, large queries can be difficult to read and maintain. In order to make queries more compact, Vulcan supports a powerful [macro syntax](../macros/overview.md) as well as [Jinja](https://jinja.palletsprojects.com/en/3.1.x/), allowing you to write macros that make your SQL queries easier to manage.
