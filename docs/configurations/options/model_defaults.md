# Model defaults

<<<<<<< Updated upstream
The `model_defaults` key is **required** and must contain a value for the `dialect` key. 
=======
The `model_defaults` section is **required**, you can't skip it! At minimum, you need to specify the `dialect` key, which tells Vulcan what SQL dialect your models use. You can use any dialect that [SQLGlot supports](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/dialect.py), which covers most major databases.
>>>>>>> Stashed changes

The other defaults are optional, but they're super helpful because they apply to all your models automatically. This means you don't have to repeat the same settings in every model file. If a model needs something different, you can override it in that specific model's definition.

For a complete list of all the options you can set in `model_defaults`, check out the [models configuration reference](../../references/model_configuration.md#model-defaults).

## Basic configuration

Example configuration:

=== "YAML"

    ```yaml linenums="1"
    model_defaults:
      dialect: snowflake
      owner: jen
      start: 2022-01-01
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, ModelDefaultsConfig

    config = Config(
        model_defaults=ModelDefaultsConfig(
            dialect="snowflake",
            owner="jen",
            start="2022-01-01",
        ),
    )
    ```

<<<<<<< Updated upstream
The default model kind is `VIEW` unless overridden with the `kind` key. For more information on model kinds, refer to [model concepts page](../../components/model/model_kinds.md).
=======
By default, models are created as `VIEW` unless you specify otherwise with the `kind` key. Views are great for most use cases because they're always up-to-date and don't store duplicate data. But if you need tables or other materialization strategies, you can override this per-model. Learn more about model kinds in the [model concepts page](configurations/components/model/model_kinds.md).
>>>>>>> Stashed changes

## Identifier resolution

Here's something that trips people up: different SQL engines handle identifier names differently. When you write `SELECT id FROM "some_table"`, the engine needs to figure out what `id` and `"some_table"` actually refer to. This is called "identifier resolution," and each dialect has its own rules.

For example, some engines treat quoted identifiers as case-sensitive while unquoted ones get normalized (usually to lowercase or uppercase). This can cause issues if you're not careful.

Vulcan needs to analyze your queries to do things like compute column-level lineage. To make this work reliably, it normalizes and quotes identifiers according to each dialect's rules. You can read more about how SQLGlot handles this [here](https://sqlglot.com/sqlglot/dialects/dialect.html#Dialect.normalize_identifier).

The normalization strategy (whether identifiers get lowercased or uppercased) is configurable. For example, if you're using BigQuery and want everything to be case-sensitive, you can do this:

=== "YAML"

    ```yaml linenums="1"
    model_defaults:
      dialect: "bigquery,normalization_strategy=case_sensitive"
    ```

This is useful when you need to preserve exact casing (maybe for compatibility with other tools or systems). When you use `case_sensitive`, Vulcan won't normalize identifiers, so they'll keep whatever casing you use.

Check out the [SQLGlot normalization strategies documentation](https://sqlglot.com/sqlglot/dialects/dialect.html#NormalizationStrategy) to see all your options.

## Gateway-specific model defaults

Sometimes you need different defaults for different gateways. Maybe you're using multiple engines and they have different requirements. You can override the global `model_defaults` for a specific gateway by adding `model_defaults` to that gateway's configuration.

Here's an example where we have different normalization strategies for different engines:

```yaml linenums="1" hl_lines="6 14"
gateways:
  redshift:
    connection:
      type: redshift
    model_defaults:
      dialect: "snowflake,normalization_strategy=case_insensitive"
  snowflake:
    connection:
      type: snowflake

default_gateway: snowflake

model_defaults:
  dialect: snowflake
  start: 2025-02-05
```

This is super useful when you're working with multiple engines that have different identifier handling rules. For example, some engines are case-sensitive while others aren't. Without gateway-specific defaults, you'd have to make sure every model aligns with each engine's behavior, which gets messy fast.

Gateway-specific `model_defaults` let you configure identifier normalization per engine, so you can write models in one style and have Vulcan handle the differences automatically.

In the example above, the global default is `snowflake` (line 14), but the `redshift` gateway overrides it with `"snowflake,normalization_strategy=case_insensitive"` (line 6). This tells Vulcan: "Write the SQL in Snowflake dialect (which will get transpiled to Redshift), but normalize identifiers as case-insensitive to match Snowflake's behavior." This way, your models work consistently across both engines.

