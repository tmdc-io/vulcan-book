# dbt

Vulcan has native support for running dbt projects with its dbt adapter.

!!! tip

    If you've never used Vulcan before, learn the basics of how it works in the [Vulcan Quickstart](../quick_start.md)!

## Getting started

### Installing Vulcan

Vulcan is a Python library you install with the `pip` command. We recommend running your Vulcan projects in a [Python virtual environment](../installation.md#python-virtual-environment), which must be created and activated before running any `pip` commands.

Most people do not use all of Vulcan's functionality. For example, most projects only run on one [SQL execution engine](../integrations/overview.md#execution-engines).

Therefore, Vulcan is packaged with multiple "extras," which you may optionally install based on the functionality your project needs. You may specify all your project's extras in a single `pip` call.

At minimum, using the Vulcan dbt adapter requires installing the dbt extra:

```bash
> pip install "vulcan[dbt]"
```

If your project uses any SQL execution engine other than DuckDB, you must install the extra for that engine. For example, if your project runs on the Postgres SQL engine:

```bash
> pip install "vulcan[dbt,postgres]"
```

If you would like to use the [Vulcan Browser UI](../guides/ui.md) to view column-level lineage, include the `web` extra:

```bash
> pip install "vulcan[dbt,web]"
```

Learn more about [Vulcan installation and extras here](../installation.md#install-extras).

### Reading a dbt project

Prepare an existing dbt project to be run by Vulcan by executing the `vulcan init` command *within the dbt project root directory* and with the `dbt` template option:

```bash
$ vulcan init -t dbt
```

This will create a file called `vulcan.yaml` containing the [default model start date](../reference/model_configuration.md#model-defaults). This configuration file is a minimum starting point for enabling Vulcan to work with your DBT project.

As you become more comfortable with running your project under Vulcan, you may specify additional Vulcan [configuration](../reference/configuration.md) as required to unlock more features.

!!! note "profiles.yml"

    Vulcan will use the existing data warehouse connection target from your dbt project's `profiles.yml` file so the connection configuration does not need to be duplicated in `vulcan.yaml`. You may change the target at any time in the dbt config and Vulcan will pick up the new target.

### Setting model backfill start dates

Models **require** a start date for backfilling data through use of the `start` configuration parameter. `start` can be defined individually for each model in its `config` block or globally in the `vulcan.yaml` file as follows:

=== "vulcan.yaml"

    ```yaml
    model_defaults:
      start: '2000-01-01'
    ```

=== "dbt Model"

    ```jinja
    {{
      config(
        materialized='incremental',
        start='2000-01-01',
        ...
      )
    }}
    ```

### Configuration

Vulcan derives a project's configuration from its dbt configuration files. This section outlines additional settings specific to Vulcan that can be defined.

#### Selecting a different state connection

[Certain engines](https://vulcan.readthedocs.io/en/stable/guides/configuration/?h=unsupported#state-connection), like Trino, cannot be used to store Vulcan's state.

In addition, even if your warehouse is supported for state, you may find that you get better performance by using a [traditional database](../concepts/state.md) to store state as these are a better fit for the state workload than a warehouse optimized for analytics workloads.

In these cases, we recommend specifying a [supported production state engine](../concepts/state.md#state) using the `state_connection` configuration.

This involves updating `vulcan.yaml` to add a gateway configuration for the state connection:

```yaml
gateways:
  "": # "" (empty string) is the default gateway
    state_connection:
      type: postgres
      ...

model_defaults:
  start: '2000-01-01'
```

Or, for a specific dbt profile defined in `profiles.yml`, eg `dev`:

```yaml
gateways:
  dev: # must match the target dbt profile name
    state_connection:
      type: postgres
      ...

model_defaults:
  start: '2000-01-01'
```

Learn more about how to configure state connections [here](https://vulcan.readthedocs.io/en/stable/guides/configuration/#state-connection).

#### Runtime vars

dbt supports passing variable values at runtime with its [CLI `vars` option](https://docs.getdbt.com/docs/build/project-variables#defining-variables-on-the-command-line).

In Vulcan, these variables are passed via configurations. When you initialize a dbt project with `vulcan init`, a file `vulcan.yaml` is created in your project directory.

You may define global variables in the same way as a native project by adding a `variables` section to the config.

For example, we could specify the runtime variable `is_marketing` and its value `no` as:

```yaml
variables:
  is_marketing: no

model_defaults:
  start: '2000-01-01'
```

Variables can also be set at the gateway/profile level which override variables set at the project level. See the [variables documentation](../concepts/macros/vulcan_macros.md#gateway-variables) to learn more about how to specify them at different levels.

#### Combinations

Some projects use combinations of runtime variables to control project behavior. Different combinations can be specified in different `vulcan_config` objects, with the relevant configuration passed to the Vulcan CLI command.

!!! info "Python config"

    Switching between different config objects requires the use of [Python config](../guides/configuration.md#python) instead of the default YAML config.

    You will need to create a file called `config.py` in the root of your project with the following contents:

    ```py
    from pathlib import Path
    from vulcan.dbt.loader import vulcan_config

    config = vulcan_config(Path(__file__).parent)
    ```

    Note that any config from `vulcan.yaml` will be overlayed on top of the active Python config so you dont need to remove the `vulcan.yaml` file

For example, consider a project with a special configuration for the `marketing` department. We could create separate configurations to pass at runtime like this:

```python
config = vulcan_config(
  Path(__file__).parent,
  variables={"is_marketing": "no", "include_pii": "no"}
)

marketing_config = vulcan_config(
  Path(__file__).parent,
  variables={"is_marketing": "yes", "include_pii": "yes"}
)
```

By default, Vulcan will use the configuration object named `config`. Use a different configuration by passing the object name to Vulcan CLI commands with the `--config` option. For example, we could run a `plan` with the marketing configuration like this:

```python
vulcan --config marketing_config plan
```

Note that the `--config` option is specified between the word `vulcan` and the command being executed (e.g., `plan`, `run`).

#### Registering comments

Vulcan automatically registers model descriptions and column comments with the target SQL engine, as described in the [Models Overview documentation](../concepts/models/overview#model-description-and-comments). Comment registration is on by default for all engines that support it.

dbt offers similar comment registration functionality via its [`persist_docs` model configuration parameter](https://docs.getdbt.com/reference/resource-configs/persist_docs), specified by model. Vulcan comment registration is configured at the project level, so it does not use dbt's model-specific `persist_docs` configuration.

Vulcan's project-level comment registration defaults are overridden with the `vulcan_config()` `register_comments` argument. For example, this configuration turns comment registration off:

```python
config = vulcan_config(
    Path(__file__).parent,
    register_comments=False,
    )
```

### Running Vulcan

Run Vulcan as with a Vulcan project, generating and applying [plans](../concepts/overview.md#make-a-plan), running [tests](../concepts/overview.md#tests) or [audits](../concepts/overview.md#audits), and executing models with a [scheduler](../guides/scheduling.md) if desired.

You continue to use your dbt file and project format.

## Workflow differences between Vulcan and dbt

Consider the following when using a dbt project:

* Vulcan will detect and deploy new or modified seeds as part of running the `plan` command and applying changes - there is no separate seed command. Refer to [seed models](../concepts/models/seed_models.md) for more information.
* The `plan` command dynamically creates environments, so environments do not need to be hardcoded into your `profiles.yml` file as targets. To get the most out of Vulcan, point your dbt profile target at the production target and let Vulcan handle the rest for you.
* The term "test" has a different meaning in dbt than in Vulcan:
    - dbt "tests" are [audits](../concepts/audits.md) in Vulcan.
    - Vulcan "tests" are [unit tests](../concepts/tests.md), which test query logic before applying a Vulcan plan.
* dbt's' recommended incremental logic is not compatible with Vulcan, so small tweaks to the models are required (don't worry - dbt can still use the models!).

## How to use Vulcan incremental models with dbt projects

Incremental loading is a powerful technique when datasets are large and recomputing tables is expensive. Vulcan offers first-class support for incremental models, and its approach differs from dbt's.

This section describes how to adapt dbt's incremental models to run on vulcan and maintain backwards compatibility with dbt.

### Incremental types

Vulcan supports two approaches to implement [idempotent](../concepts/glossary.md#idempotency) incremental loads:

* Using merge (with the vulcan [`INCREMENTAL_BY_UNIQUE_KEY` model kind](../concepts/models/model_kinds.md#incremental_by_unique_key))
* Using [`INCREMENTAL_BY_TIME_RANGE` model kind](../concepts/models/model_kinds.md#incremental_by_time_range)

#### Incremental by unique key

To enable incremental_by_unique_key incrementality, the model configuration should contain:

* The `unique_key` key with the model's unique key field name or names as the value
* The `materialized` key with value `'incremental'`
* Either:
    * No `incremental_strategy` key or
    * The `incremental_strategy` key with value `'merge'`

#### Incremental by time range

To enable incremental_by_time_range incrementality, the model configuration must contain:

* The `materialized` key with value `'incremental'`
* The `incremental_strategy` key with the value `incremental_by_time_range`
* The `time_column` key with the model's time column field name as the value (see [`time column`](../concepts/models/model_kinds.md#time-column) for details)

### Incremental logic

Unlike dbt incremental strategies, Vulcan does not require the use of `is_incremental` jinja blocks to implement incremental logic. 
Instead, Vulcan provides predefined time macro variables that can be used in the model's SQL to filter data based on the time column.

For example, the SQL `WHERE` clause with the "ds" column goes in a new jinja block gated by `{% if vulcan_incremental is defined %}` as follows:

```bash
>   WHERE
>     ds BETWEEN '{{ start_ds }}' AND '{{ end_ds }}'
```

`{{ start_ds }}` and `{{ end_ds }}` are the jinja equivalents of Vulcan's `@start_ds` and `@end_ds` predefined time macro variables. See all [predefined time variables](../concepts/macros/macro_variables.md) available in jinja.

### Incremental model configuration

Vulcan provides configuration parameters that enable control over how incremental computations occur. These parameters are set in the model's `config` block.

See [Incremental Model Properties](../concepts/models/overview.md#incremental-model-properties) for the full list of incremental model configuration parameters.

**Note:** By default, all incremental dbt models are configured to be [forward-only](../concepts/plans.md#forward-only-plans). However, you can change this behavior by setting the `forward_only: false` setting either in the configuration of an individual model or globally for all models in the `dbt_project.yaml` file. The [forward-only](../concepts/plans.md#forward-only-plans) mode aligns more closely with the typical operation of dbt and therefore better meets user's expectations.

Similarly, the [allow_partials](../concepts/models/overview.md#allow_partials) parameter is set to `true` by default unless the `allow_partials` parameter is explicitly set to `false` in the model configuration.

#### on_schema_change

Vulcan automatically detects both destructive and additive schema changes to [forward-only incremental models](../guides/incremental_time.md#forward-only-models) and to all incremental models in [forward-only plans](../concepts/plans.md#destructive-changes).

A model's [`on_destructive_change` and `on_additive_change` settings](../guides/incremental_time.md#schema-changes) determine whether it errors, warns, silently allows, or ignores the changes. Vulcan provides fine-grained control over both destructive changes (like dropping columns) and additive changes (like adding new columns).

`on_schema_change` configuration values are mapped to these Vulcan settings:

| `on_schema_change` | Vulcan `on_destructive_change` | Vulcan `on_additive_change` |
|--------------------|---------------------------------|------------------------------|
| ignore             | ignore                          | ignore                       |
| fail               | error                           | error                        |
| append_new_columns | ignore                          | allow                        |
| sync_all_columns   | allow                           | allow                        |


## Snapshot support

Vulcan supports both dbt snapshot strategies of either `timestamp` or `check`.
Only unsupported snapshot functionality is `invalidate_hard_deletes` which must be set to `True`.
If set to `False`, then the snapshot will be skipped and a warning will be logged indicating this happened.
Support for this will be added soon.

## Tests
Vulcan uses dbt tests to perform Vulcan [audits](../concepts/audits.md) (coming soon).

Add Vulcan [unit tests](../concepts/tests.md) to a dbt project by placing them in the "tests" directory.

## Seed column types

Vulcan parses seed CSV files using [Panda's `read_csv` utility](https://pandas.pydata.org/pandas-docs/stable/reference/api/pandas.read_csv.html) and its default column type inference.

dbt parses seed CSV files using [agate's csv reader](https://agate.readthedocs.io/en/latest/api/csv.html#csv-reader-and-writer) and [customizes agate's default type inference](https://github.com/dbt-labs/dbt-common/blob/ae8ffe082926fdb3ef2a15486588f40c7739aea9/dbt_common/clients/agate_helper.py#L59).

If Vulcan and dbt infer different column types for a seed CSV file, you may specify a [column_types](https://docs.getdbt.com/reference/resource-configs/column_types) dictionary in your `dbt_project.yml` file, where the keys define the column names and the values the data types.

``` yaml
seeds:
  <seed name>
    +column_types:
      <column name>: <SQL data type>
```

Alternatively, you can define this dictionary in the seed [seed properties configuration file](https://docs.getdbt.com/reference/seed-properties).

``` yaml
seeds:
  - name: <seed name>
    config:
      column_types:
        <column name>: <SQL data type>
```

You may also specify a column's SQL data type in its `data_type` key, as shown below. The file must list all columns present in the CSV file; Vulcan's default type inference will be used for columns that do not specify the `data_type` key.

``` yaml
seeds:
  - name: <seed name>
    columns:
      - name: <column name>
        data_type: <SQL data type>
```

## Package Management
Vulcan does not have its own package manager; however, Vulcan's dbt adapter is compatible with dbt's package manager. Continue to use [dbt deps](https://docs.getdbt.com/reference/commands/deps) and [dbt clean](https://docs.getdbt.com/reference/commands/clean) to update, add, or remove packages.

## Documentation
Model documentation is available in the [Vulcan UI](../quickstart/ui.md#2-open-the-vulcan-web-ui).

## Supported dbt jinja methods

Vulcan supports running dbt projects using the majority of dbt jinja methods, including:

| Method    | Method         | Method       | Method  |
| --------- | -------------- | ------------ | ------- |
| adapter   | env_var        | project_name | target  |
| as_bool   | exceptions     | ref          | this    |
| as_native | from_yaml      | return       | to_yaml |
| as_number | is_incremental | run_query    | var     |
| as_text   | load_result    | schema       | zip     |
| api       | log            | set          |         |
| builtins  | modules        | source       |         |
| config    | print          | statement    |         |

## Unsupported dbt jinja methods

The dbt jinja methods that are not currently supported are:

* debug
* selected_sources
* graph.nodes.values
* graph.metrics.values

## Missing something you need?

Submit an [issue](https://github.com/TobikoData/vulcan/issues), and we'll look into it!
