# Variables

Macro variables are placeholders that get replaced with actual values when Vulcan renders your SQL. They're what make your queries dynamic, instead of hardcoding values, you use variables that change based on context.

Instead of writing `WHERE date > '2023-01-01'` and manually updating it every day, you write `WHERE date > @execution_ds` and it automatically uses today's date.

!!! note
    This page covers Vulcan's built-in macro variables, the ones that come pre-configured and ready to use. If you want to create your own custom variables, check out the [Vulcan macros page](./built_in.md#user-defined-variables) or [Jinja macros page](./jinja.md#user-defined-variables).

## A quick example

Let's say you have a query that filters by date. Without macros, you'd write something like this:

```sql linenums="1"
SELECT *
FROM table
WHERE my_date > '2023-01-01'
```

Every time you want to change the date, you have to edit the query. That's tedious and error-prone.

With a macro variable, you can make it dynamic:

```sql linenums="1"
SELECT *
FROM table
WHERE my_date > @execution_ds
```

The `@` symbol tells Vulcan "this is a macro variable, replace it with a value before executing." The `@execution_ds` variable is predefined, so Vulcan automatically sets it to the date when execution started.

If you run this model on February 1, 2023, Vulcan renders it as:

```sql linenums="1"
SELECT *
FROM table
WHERE my_date > '2023-02-01'
```

The date updates automatically every time you run it. No manual editing needed!

Vulcan comes with a bunch of predefined variables like this. You can also create your own custom variables if you need something specific, we'll cover those in the macro system pages.

## Predefined variables

Vulcan provides a set of predefined variables that are automatically available in your models. Most of them are related to time (dates, timestamps, etc.), since time-based logic is common in data models.

The time variables follow a consistent naming pattern: they combine a prefix (like `start`, `end`, or `execution`) with a postfix (like `ds`, `ts`, or `epoch`) to create variables like `@start_ds` or `@execution_epoch`.

### Temporal variables

Vulcan uses Python's [datetime module](https://docs.python.org/3/library/datetime.html) under the hood and follows the standard [Unix epoch](https://en.wikipedia.org/wiki/Unix_time) (starting January 1, 1970).

!!! tip "Important"
    All time-related predefined variables use [UTC time zone](https://en.wikipedia.org/wiki/Coordinated_Universal_Time). If you need to work with other timezones, you'll handle that in your query logic.

    Learn more about timezones and incremental models [here](../../model/model_kinds.md#timezones).

**Prefixes** tell you what time period the variable represents:

- `start` - The beginning of the time interval for this model run (inclusive)

- `end` - The end of the time interval for this model run (inclusive)

- `execution` - The exact timestamp when the execution started

**Postfixes** tell you what format the value is in:

- `dt` - A Python datetime object that becomes a SQL `TIMESTAMP`

- `dtntz` - A Python datetime object that becomes a SQL `TIMESTAMP WITHOUT TIME ZONE`

- `date` - A Python date object that becomes a SQL `DATE`

- `ds` - A date string formatted as `'YYYY-MM-DD'` (like `'2023-02-01'`)

- `ts` - An ISO 8601 datetime string: `'YYYY-MM-DD HH:MM:SS'`

- `tstz` - An ISO 8601 datetime string with timezone: `'YYYY-MM-DD HH:MM:SS+00:00'`

- `hour` - An integer from 0-23 representing the hour of the day

- `epoch` - An integer representing seconds since Unix epoch

- `millis` - An integer representing milliseconds since Unix epoch

Here are all the temporal variables you can use:

**dt (datetime objects):**

- `@start_dt`

- `@end_dt`

- `@execution_dt`

**dtntz (datetime without timezone):**

- `@start_dtntz`

- `@end_dtntz`

- `@execution_dtntz`

**date (date objects):**

- `@start_date`

- `@end_date`

- `@execution_date`

**ds (date strings):**

- `@start_ds`

- `@end_ds`

- `@execution_ds`

**ts (timestamp strings):**

- `@start_ts`

- `@end_ts`

- `@execution_ts`

**tstz (timestamp strings with timezone):**

- `@start_tstz`

- `@end_tstz`

- `@execution_tstz`

**hour (hour integers):**

- `@start_hour`

- `@end_hour`

- `@execution_hour`

**epoch (Unix epoch seconds):**

- `@start_epoch`

- `@end_epoch`

- `@execution_epoch`

**millis (Unix epoch milliseconds):**

- `@start_millis`

- `@end_millis`

- `@execution_millis`

### Runtime variables

Beyond time, Vulcan provides variables that give you information about the current execution context:

- **`@runtime_stage`** - A string telling you what stage Vulcan is currently in. Useful for conditionally running code based on whether you're creating tables, evaluating queries, or promoting views. Possible values:

  - `'loading'` - Project is being loaded into Vulcan's runtime

  - `'creating'` - Model tables are being created for the first time

  - `'evaluating'` - Model query is being evaluated and data inserted

  - `'promoting'` - Model is being promoted (view created in virtual layer)

  - `'demoting'` - Model is being demoted (view dropped from virtual layer)

  - `'auditing'` - Audit is being run

  - `'testing'` - Model is being evaluated in a unit test context
  
  Learn more about using this in [pre/post-statements](../../model/types/sql_models.md#optional-prepost-statements).

- **`@gateway`** - The name of the current [gateway](../../../references/configuration.md#gateways) (your database connection)

- **`@this_model`** - The physical table name that the model's view selects from. Useful for creating [generic audits](../../audits/audits.md#generic-audits). When used in [on_virtual_update statements](../../model/types/sql_models.md#optional-on-virtual-update-statements), it contains the qualified view name instead.

- **`@model_kind_name`** - The name of the current model kind (like `'FULL'` or `'INCREMENTAL_BY_TIME_RANGE'`). Useful when you need to control [physical properties in model defaults](../../../references/model_configuration.md#model-defaults) based on the model kind.

!!! note "Embedding variables in strings"
    Sometimes you'll see variables written with curly braces like `@{variable}` instead of just `@variable`. They do different things!

    The curly brace syntax tells Vulcan to treat the rendered value as a SQL identifier (like a table or column name), not a string literal. So if `variable` contains `foo.bar`, then:

    - `@variable` produces `foo.bar` (as a literal value)

    - `@{variable}` produces `"foo.bar"` (as an identifier, with quotes)

    You'll most often use `@{variable}` when you want to interpolate a value into an identifier name, like `@{schema}_table`. The regular `@variable` syntax is for plain value substitution.

    Learn more in the [Vulcan macros documentation](./built_in.md#embedding-variables-in-strings).

#### Before all and after all variables

These variables are available in [`before_all` and `after_all` statements](../../../references/configuration.md#before_all--after_all), as well as in any macros called within those statements:

- **`@this_env`** - The name of the current [environment](../../../references/environments.md)

- **`@schemas`** - A list of schema names in the [virtual layer](../../../references/glossary.md#virtual-layer) for the current environment

- **`@views`** - A list of view names in the [virtual layer](../../../references/glossary.md#virtual-layer) for the current environment

These are useful when you need to perform setup or cleanup operations that depend on the environment context.
