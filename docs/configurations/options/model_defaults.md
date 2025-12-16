# Model defaults

The `model_defaults` key is **required** and must contain a value for the `dialect` key. All SQL dialects [supported by the SQLGlot library](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/dialect.py) are allowed. Other values are set automatically unless explicitly overridden in the model definition.

All supported `model_defaults` keys are listed in the [models configuration reference page](model_configuration.md#model-defaults).

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

The default model kind is `VIEW` unless overridden with the `kind` key. For more information on model kinds, refer to [model concepts page](../concepts/models/model_kinds.md).

## Identifier resolution

When a SQL engine receives a query such as `SELECT id FROM "some_table"`, it eventually needs to understand what database objects the identifiers `id` and `"some_table"` correspond to. This process is usually referred to as identifier (or name) resolution.

Different SQL dialects implement different rules when resolving identifiers in queries. For example, certain identifiers may be treated as case-sensitive (e.g. if they're quoted), and a case-insensitive identifier is usually either lowercased or uppercased, before the engine actually looks up what object it corresponds to.

Vulcan analyzes model queries so that it can extract useful information from them, such as computing Column-Level Lineage. To facilitate this analysis, it _normalizes_ and _quotes_ all identifiers in those queries, [respecting each dialect's resolution rules](https://sqlglot.com/sqlglot/dialects/dialect.html#Dialect.normalize_identifier).

The "normalization strategy", i.e. whether case-insensitive identifiers are lowercased or uppercased, is configurable per dialect. For example, to treat all identifiers as case-sensitive in a BigQuery project, one can do:

=== "YAML"

    ```yaml linenums="1"
    model_defaults:
      dialect: "bigquery,normalization_strategy=case_sensitive"
    ```

This may be useful in cases where the name casing needs to be preserved, since then Vulcan won't be able to normalize them.

See [here](https://sqlglot.com/sqlglot/dialects/dialect.html#NormalizationStrategy) to learn more about the supported normalization strategies.

## Gateway-specific model defaults

You can also define gateway specific `model_defaults` in the `gateways` section, which override the global defaults for that gateway.

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

This allows you to tailor the behavior of models for each gateway without affecting the global `model_defaults`.

For example, in some SQL engines identifiers like table and column names are case-sensitive, but they are case-insensitive in other engines. By default, a project that uses both types of engines would need to ensure the models for each engine aligned with the engine's normalization behavior, which makes project maintenance and debugging more challenging.

Gateway-specific `model_defaults` allow you to change how Vulcan performs identifier normalization *by engine* to align the different engines' behavior.

In the example above, the project's default dialect is `snowflake` (line 14). The `redshift` gateway configuration overrides that global default dialect with `"snowflake,normalization_strategy=case_insensitive"` (line 6).

That value tells Vulcan that the `redshift` gateway's models will be written in the Snowflake SQL dialect (so need to be transpiled from Snowflake to Redshift), but that the resulting Redshift SQL should treat identifiers as case-insensitive to match Snowflake's behavior.

