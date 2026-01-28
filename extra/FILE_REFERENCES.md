# Documentation File References and Hyperlinks

This document provides a comprehensive catalog of all hyperlinks and file references in the Vulcan documentation, organized for easy navigation and link management.

## Quick Statistics

- **Total files scanned**: 83
- **Files with links**: 71
- **Total links**: 992
- **Internal links**: 752
- **External links**: 240
- **Potentially broken links**: 383

## Navigation

- [Broken Links by Pattern](#broken-links-by-pattern) - Grouped broken links for easier fixing
- [Link Relationships](#link-relationships) - See what links to what
- [Most Linked Pages](#most-linked-pages) - Popular internal pages
- [External Resources](#external-resources) - External domains and links
- [Links by File](#links-by-file) - Complete listing organized by file
- [Link Index](#link-index) - Quick reference index

## Broken Links by Pattern

Broken links grouped by common patterns to help identify systematic issues:

### Pattern: `relative_paths` (349 links)

- **comparisons.md** (Line 65): `[Virtual Environments](./concepts/plans.md#plan-application)`
- **comparisons.md** (Line 164): `[Unit and integration tests](./concepts/tests.md)`
- **configurations/overview.md** (Line 98): `[Configuration Reference](./configuration.md#gateways)`
- **configurations/overview.md** (Line 112): `[Model Defaults](./model_defaults.md)`
- **configurations/overview.md** (Line 118): `[Variables](./variables.md)`
- **configurations/overview.md** (Line 124): `[Execution Hooks](./hooks.md)`
- **configurations/overview.md** (Line 130): `[Linter](./linter.md)`
- **configurations/overview.md** (Line 136): `[Notifications](./notifications.md)`
- **configurations/overview.md** (Line 142): `[PostgreSQL](./integrations/engines/postgres.md)`
- **configurations/overview.md** (Line 143): `[Snowflake](./integrations/engines/snowflake.md)`
- **configurations/overview.md** (Line 149): `[Configuration Reference](./configuration.md)`
- **configurations/overview.md** (Line 150): `[Variables](./variables.md)`
- **configurations/overview.md** (Line 151): `[Model Defaults](./model_defaults.md)`
- **configurations/overview.md** (Line 152): `[Execution Hooks](./hooks.md)`
- **configurations/overview.md** (Line 153): `[Linter](./linter.md)`
- **configurations/overview.md** (Line 154): `[Notifications](./notifications.md)`
- **configurations/options/notifications.md** (Line 11): `[Audit](../concepts/audits.md)`
- **configurations/options/notifications.md** (Line 133): `[`plan` application](../concepts/plans.md)`
- **configurations/options/notifications.md** (Line 133): `[`run`](../reference/cli.md#run)`
- **configurations/options/notifications.md** (Line 133): `[`audit`](../concepts/audits.md)`

*... and 329 more links with this pattern*

### Pattern: `concepts/` (15 links)

- **comparisons.md** (Line 24): `[✅](concepts/models/overview.md)`
- **comparisons.md** (Line 25): `[✅✅](concepts/models/python_models.md)`
- **comparisons.md** (Line 27): `[✅](concepts/macros/jinja_macros.md)`
- **comparisons.md** (Line 28): `[✅](concepts/macros/vulcan_macros.md)`
- **comparisons.md** (Line 30): `[✅](concepts/glossary.md#semantic-understanding)`
- **comparisons.md** (Line 31): `[✅](concepts/tests.md)`
- **comparisons.md** (Line 33): `[✅](concepts/audits.md)`
- **comparisons.md** (Line 34): `[✅](concepts/plans.md)`
- **comparisons.md** (Line 35): `[✅](concepts/plans.md)`
- **comparisons.md** (Line 37): `[✅](concepts/environments.md)`
- **comparisons.md** (Line 51): `[✅](concepts/models/sql_models.md#transpilation)`
- **comparisons.md** (Line 152): `[batch](concepts/models/overview.md#batch_size)`
- **comparisons.md** (Line 169): `[Python models](concepts/models/python_models.md)`
- **comparisons.md** (Line 174): `[`vulcan plan`](concepts/plans.md)`
- **comparisons.md** (Line 176): `[Virtual Preview](concepts/glossary.md#virtual-preview)`

### Pattern: `other` (8 links)

- **configurations/options/model_defaults.md** (Line 5): `[models configuration reference page](model_configuration.md#model-defaults)`
- **components/checks/checks.md** (Line 5): `[audits](audits.md)`
- **components/tests/tests.md** (Line 17): `[plan](plans.md)`
- **components/semantics/overview.md** (Line 69): `[Business Metrics](metrics.md)`
- **components/semantics/overview.md** (Line 159): `[Business Metrics](metrics.md)`
- **concepts-old/glossary.md** (Line 13): `[tests](tests.md)`
- **concepts-old/glossary.md** (Line 13): `[audits](audits.md)`
- **concepts-old/glossary.md** (Line 16): `[tests](tests.md)`

### Pattern: `models/` (8 links)

- **concepts-old/environments.md** (Line 6): `[Models](models/overview.md)`
- **concepts-old/plans.md** (Line 336): `[INCREMENTAL_BY_UNIQUE_KEY](models/model_kinds.md#incremental_by_unique_key)`
- **concepts-old/plans.md** (Line 337): `[INCREMENTAL_BY_PARTITION](models/model_kinds.md#incremental_by_partition)`
- **concepts-old/plans.md** (Line 338): `[SCD_TYPE_2_BY_TIME](models/model_kinds.md#scd-type-2-by-time-recommended)`
- **concepts-old/plans.md** (Line 339): `[SCD_TYPE_2_BY_COLUMN](models/model_kinds.md#scd-type-2-by-column)`
- **concepts-old/plans.md** (Line 562): `[forward-only](models/overview.md#forward_only)`
- **concepts-old/plans.md** (Line 633): `[disable_restatement](models/overview.md#disable_restatement)`
- **concepts-old/glossary.md** (Line 49): `[Model Kinds](models/model_kinds.md)`

### Pattern: `reference/` (1 links)

- **comparisons.md** (Line 41): `[✅](reference/cli.md)`

### Pattern: `getting_started/` (1 links)

- **index.md** (Line 104): `[quickstart guide](getting_started/docker.md)`

### Pattern: `plans/` (1 links)

- **concepts-old/plans.md** (Line 286): `[Each model variant gets its own physical table, while environments only contain references to these tables](plans/model_versioning.png)`

## Link Relationships

See which files link to each target page:

### `concepts/plans.md`

Linked from 18 file(s):

- **comparisons.md** (Line 34): `✅`
- **comparisons.md** (Line 35): `✅`
- **comparisons.md** (Line 65): `Virtual Environments`
- **comparisons.md** (Line 174): ``vulcan plan``
- **guides-old/notifications.md** (Line 133): ``plan` application`
- **guides-old/configuration.md** (Line 573): `preview`
- **guides-old/configuration.md** (Line 647): `categorize`
- **guides-old/configuration.md** (Line 651): `breaking`
- **guides-old/configuration.md** (Line 1102): `plans`
- **configurations-old/configuration.md** (Line 90): `categorize`

*... and 8 more references*

### `reference/configuration.md`

Linked from 18 file(s):

- **guides-old/configuration.md** (Line 7): `configuration reference page`
- **guides-old/configuration.md** (Line 281): `Vulcan configuration reference page`
- **guides-old/configuration.md** (Line 283): `Project`
- **guides-old/configuration.md** (Line 284): `Environment`
- **guides-old/configuration.md** (Line 285): `Gateways`
- **guides-old/configuration.md** (Line 286): `Gateway/connection defaults`
- **guides-old/configuration.md** (Line 288): `Debug mode`
- **guides-old/configuration.md** (Line 292): `configuration reference page`
- **guides-old/configuration.md** (Line 328): `environments`
- **guides-old/configuration.md** (Line 412): `environment_suffix_target`

*... and 8 more references*

### `guides/configuration.md`

Linked from 16 file(s):

- **configurations-old/configuration.md** (Line 3): `configuration guide`
- **configurations-old/configuration.md** (Line 34): `will be placed`
- **configurations-old/configuration.md** (Line 35): `additional details`
- **configurations-old/configuration.md** (Line 46): `additional details`
- **configurations-old/configuration.md** (Line 77): `the configuration guide`
- **configurations-old/configuration.md** (Line 90): `additional details`
- **configurations-old/configuration.md** (Line 158): `gateways section`
- **configurations-old/configuration.md** (Line 214): `configuration overview scheduler section`
- **configurations-old/configuration.md** (Line 224): `gateway/connection defaults section`
- **components/model/properties.md** (Line 1666): `configuration guide`

*... and 6 more references*

### `reference/cli.md`

Linked from 12 file(s):

- **comparisons.md** (Line 41): `✅`
- **guides-old/notifications.md** (Line 133): ``run``
- **guides-old/projects.md** (Line 69): `CLI`
- **guides-old/configuration.md** (Line 1148): `accept a gateway option`
- **guides/run_and_scheduling.md** (Line 646): `Run Command`
- **concepts-old/overview.md** (Line 10): `CLI`
- **concepts-old/overview.md** (Line 21): ``plan` command`
- **concepts-old/overview.md** (Line 28): ``plan``
- **concepts-old/overview.md** (Line 55): ``test` command`
- **concepts-old/overview.md** (Line 66): ``audit` command`

*... and 2 more references*

### `concepts/models/model_kinds.md`

Linked from 12 file(s):

- **guides-old/configuration.md** (Line 1269): `model concepts page`
- **guides-old/table_migration.md** (Line 9): `external models`
- **guides-old/table_migration.md** (Line 42): ``EXTERNAL` model`
- **guides-old/table_migration.md** (Line 44): ``VIEW` model`
- **guides/models.md** (Line 677): `Model Kinds`
- **guides/incremental_by_time.md** (Line 5): `model kinds page`
- **guides/incremental_by_time.md** (Line 1155): `Model Kinds`
- **guides/plan.md** (Line 932): `Model Kinds`
- **getting_started/cli.md** (Line 418): `kinds`
- **getting_started/cli.md** (Line 420): ``SEED` models`

*... and 2 more references*

### `guides/reference/cli.md`

Linked from 11 file(s):

- **guides/get-started/docker.md** (Line 106): `*Click here*`
- **guides/get-started/docker.md** (Line 114): `*Click here*`
- **guides/get-started/docker.md** (Line 121): `*Click here*`
- **guides/get-started/docker.md** (Line 133): `*Click here*`
- **guides/get-started/docker.md** (Line 139): `*Click here*`
- **guides/get-started/docker.md** (Line 147): `*Click here*`
- **guides/get-started/docker.md** (Line 155): `*Click here*`
- **guides/get-started/docker.md** (Line 161): `*Click here*`
- **guides/get-started/docker.md** (Line 173): `*Click here*`
- **guides/get-started/docker.md** (Line 179): `*Click here*`

*... and 1 more references*

### `concepts-old/plans.md`

Linked from 10 file(s):

- **concepts-old/environments.md** (Line 14): `plan`
- **concepts-old/environments.md** (Line 16): ``vulcan plan``
- **concepts-old/environments.md** (Line 29): `plans`
- **concepts-old/environments.md** (Line 32): `plan`
- **concepts-old/overview.md** (Line 25): `plans`
- **concepts-old/overview.md** (Line 28): ``apply``
- **concepts-old/glossary.md** (Line 82): `plan application`
- **concepts-old/glossary.md** (Line 88): `Virtual Update`
- **concepts-old/state.md** (Line 9): `promoted`
- **concepts-old/architecture/snapshots.md** (Line 10): `change categories`

### `concepts-old/macros/macro_variables.md`

Linked from 10 file(s):

- **concepts-old/macros/overview.md** (Line 11): `Pre-defined macro variables`
- **concepts-old/macros/jinja_macros.md** (Line 55): `predefined macro variables`
- **concepts-old/macros/jinja_macros.md** (Line 57): ``runtime_stage``
- **concepts-old/macros/jinja_macros.md** (Line 57): ``this_model``
- **concepts-old/macros/jinja_macros.md** (Line 59): `temporal`
- **concepts-old/macros/jinja_macros.md** (Line 326): `Predefined Vulcan macro variables`
- **concepts-old/macros/vulcan_macros.md** (Line 32): `Vulcan pre-defined`
- **concepts-old/macros/vulcan_macros.md** (Line 617): `runtime stage`
- **concepts-old/macros/vulcan_macros.md** (Line 1155): `runtime stages`
- **concepts-old/macros/vulcan_macros.md** (Line 1692): `Pre-defined variables`

### `concepts/glossary.md`

Linked from 9 file(s):

- **comparisons.md** (Line 30): `✅`
- **comparisons.md** (Line 176): `Virtual Preview`
- **guides-old/configuration.md** (Line 582): `catalog`
- **guides-old/configuration.md** (Line 589): `virtual layer`
- **guides-old/configuration.md** (Line 589): `physical layer`
- **configurations-old/configuration.md** (Line 28): `physical layer`
- **configurations-old/configuration.md** (Line 39): `virtual layer`
- **concepts-old/macros/macro_variables.md** (Line 160): `virtual layer`
- **concepts-old/macros/macro_variables.md** (Line 161): `virtual layer`

### `reference/model_configuration.md`

Linked from 9 file(s):

- **guides-old/configuration.md** (Line 287): `Model defaults`
- **guides-old/configuration.md** (Line 1242): `models configuration reference page`
- **guides-old/configuration.md** (Line 1329): `models configuration reference page`
- **guides-old/configuration.md** (Line 1355): `models configuration reference page`
- **components/model/model_kinds.md** (Line 7): `model configuration reference page`
- **guides/model_selection.md** (Line 625): `Model Configuration`
- **concepts-old/plans.md** (Line 574): `model defaults`
- **concepts-old/plans.md** (Line 575): `model defaults`
- **concepts-old/macros/macro_variables.md** (Line 141): `physical properties in model defaults`

### `configurations-old/guides/configuration.md`

Linked from 9 file(s):

- **configurations-old/integrations/engines/snowflake.md** (Line 177): `environment variables that the configuration file loads dynamically`
- **configurations-old/integrations/engines/snowflake.md** (Line 208): `here`
- **configurations-old/integrations/engines/snowflake.md** (Line 594): `model defaults`
- **configurations-old/integrations/engines/motherduck.md** (Line 57): `environment variables that the configuration file loads dynamically`
- **configurations-old/integrations/engines/databricks.md** (Line 109): `environment variables that the configuration file loads dynamically`
- **configurations-old/integrations/engines/databricks.md** (Line 149): `environment variables that the configuration file loads dynamically`
- **configurations-old/integrations/engines/databricks.md** (Line 182): `here`
- **configurations-old/integrations/engines/clickhouse.md** (Line 70): ``environment_suffix_target` key in your project configuration`
- **configurations-old/integrations/engines/clickhouse.md** (Line 78): ``physical_schema_mapping` key in your project configuration`

### `getting_started/docker.md`

Linked from 7 file(s):

- **index.md** (Line 104): `quickstart guide`
- **guides/models.md** (Line 9): `Created your project`
- **guides/plan.md** (Line 131): `Docker Quickstart`
- **concepts-old/macros/vulcan_macros.md** (Line 267): `Vulcan quickstart guide`
- **getting_started/cli.md** (Line 26): `Docker Quickstart`
- **getting_started/cli.md** (Line 64): `Docker Quickstart`
- **getting_started/index.md** (Line 15): `Start with Docker Quickstart`

### `configurations-old/concepts/models/model_kinds.md`

Linked from 7 file(s):

- **configurations-old/integrations/engines/athena.md** (Line 69): ``INCREMENTAL_BY_UNIQUE_KEY``
- **configurations-old/integrations/engines/athena.md** (Line 69): ``SCD_TYPE_2``
- **configurations-old/integrations/engines/mssql.md** (Line 16): `incremental by unique key`
- **configurations-old/integrations/engines/clickhouse.md** (Line 341): ``FULL` models`
- **configurations-old/integrations/engines/clickhouse.md** (Line 342): ``INCREMENTAL_BY_TIME_RANGE` models`
- **configurations-old/integrations/engines/clickhouse.md** (Line 343): ``INCREMENTAL_BY_UNIQUE_KEY` models`
- **configurations-old/integrations/engines/clickhouse.md** (Line 344): ``INCREMENTAL_BY_PARTITION` models`

### `concepts-old/glossary.md`

Linked from 7 file(s):

- **concepts-old/plans.md** (Line 206): `Direct`
- **concepts-old/plans.md** (Line 206): `Indirect`
- **concepts-old/plans.md** (Line 206): `Backfill`
- **concepts-old/plans.md** (Line 207): `Direct`
- **concepts-old/plans.md** (Line 207): `Backfill`
- **concepts-old/plans.md** (Line 208): `Indirect`
- **concepts-old/plans.md** (Line 208): `No Backfill`

### `concepts-old/models/model_kinds.md`

Linked from 7 file(s):

- **concepts-old/plans.md** (Line 336): `INCREMENTAL_BY_UNIQUE_KEY`
- **concepts-old/plans.md** (Line 337): `INCREMENTAL_BY_PARTITION`
- **concepts-old/plans.md** (Line 338): `SCD_TYPE_2_BY_TIME`
- **concepts-old/plans.md** (Line 339): `SCD_TYPE_2_BY_COLUMN`
- **concepts-old/glossary.md** (Line 49): `Model Kinds`
- **concepts-old/state.md** (Line 13): `incremental models`
- **concepts-old/macros/macro_variables.md** (Line 60): `here`

### `concepts-old/macros/vulcan_macros.md`

Linked from 7 file(s):

- **concepts-old/macros/macro_variables.md** (Line 9): `Vulcan macros page`
- **concepts-old/macros/macro_variables.md** (Line 45): `Vulcan macros`
- **concepts-old/macros/macro_variables.md** (Line 153): `Vulcan macros documentation`
- **concepts-old/macros/overview.md** (Line 12): `Vulcan macros`
- **concepts-old/macros/jinja_macros.md** (Line 87): `Vulcan macros documentation`
- **concepts-old/macros/jinja_macros.md** (Line 119): `Vulcan macros documentation`
- **concepts-old/macros/jinja_macros.md** (Line 324): `Vulcan`

### `concepts/macros/vulcan_macros.md`

Linked from 6 file(s):

- **comparisons.md** (Line 28): `✅`
- **guides-old/isolated_systems.md** (Line 65): ``@IF` macro operator`
- **guides-old/isolated_systems.md** (Line 81): `here`
- **configurations-old/configuration.md** (Line 65): ``@VAR` macro function`
- **configurations-old/configuration.md** (Line 65): ``evaluator.var` method`
- **configurations-old/configuration.md** (Line 67): `Vulcan macros concepts page`

### `concepts/audits.md`

Linked from 6 file(s):

- **comparisons.md** (Line 33): `✅`
- **guides-old/notifications.md** (Line 11): `Audit`
- **guides-old/notifications.md** (Line 133): ``audit``
- **guides/data_quality.md** (Line 580): `Built-in Audits`
- **getting_started/cli.md** (Line 254): `here`
- **getting_started/cli.md** (Line 472): ``audits``

### `concepts/environments.md`

Linked from 6 file(s):

- **comparisons.md** (Line 37): `✅`
- **guides-old/isolated_systems.md** (Line 19): `Vulcan environments`
- **guides/run_and_scheduling.md** (Line 648): `Environments`
- **guides/models.md** (Line 11): `dev environment`
- **guides/plan.md** (Line 931): `Environments`
- **getting_started/cli.md** (Line 300): `Vulcan environment`

### `components/model/model_kinds.md`

Linked from 6 file(s):

- **components/model/properties.md** (Line 120): `Model Kinds`
- **components/model/properties.md** (Line 1200): `Model Kinds`
- **components/model/properties.md** (Line 1259): `Model Kinds documentation`
- **components/model/properties.md** (Line 1334): `Model Kinds documentation`
- **components/model/properties.md** (Line 1416): `Model Kinds documentation`
- **components/model/properties.md** (Line 1457): `Model Kinds documentation`

### `components/advanced-features/macros/built_in.md`

Linked from 6 file(s):

- **components/advanced-features/macros/overview.md** (Line 19): `Vulcan macros`
- **components/advanced-features/macros/jinja.md** (Line 78): `Vulcan macros documentation`
- **components/advanced-features/macros/jinja.md** (Line 108): `Vulcan macros documentation`
- **components/advanced-features/macros/jinja.md** (Line 326): `Vulcan macros`
- **components/advanced-features/macros/variables.md** (Line 8): `Vulcan macros page`
- **components/advanced-features/macros/variables.md** (Line 154): `Vulcan macros documentation`

### `concepts-old/models/overview.md`

Linked from 6 file(s):

- **concepts-old/environments.md** (Line 6): `Models`
- **concepts-old/plans.md** (Line 322): `the model definition`
- **concepts-old/plans.md** (Line 562): `forward-only`
- **concepts-old/plans.md** (Line 633): `disable_restatement`
- **concepts-old/state.md** (Line 7): `Model Version`
- **concepts-old/state.md** (Line 10): `auto restatements`

### `concepts-old/architecture/snapshots.md`

Linked from 6 file(s):

- **concepts-old/environments.md** (Line 27): `fingerprint`
- **concepts-old/environments.md** (Line 27): `snapshots`
- **concepts-old/plans.md** (Line 224): `snapshot`
- **concepts-old/plans.md** (Line 224): `fingerprint`
- **concepts-old/architecture/serialization.md** (Line 3): `snapshot`
- **concepts-old/architecture/serialization.md** (Line 9): `snapshot fingerprinting`

### `concepts-old/environments.md`

Linked from 6 file(s):

- **concepts-old/plans.md** (Line 3): `environment`
- **concepts-old/plans.md** (Line 222): `environment`
- **concepts-old/plans.md** (Line 671): `development environment`
- **concepts-old/state.md** (Line 8): `Virtual Data Environment`
- **concepts-old/state.md** (Line 9): `Virtual Data Environment`
- **concepts-old/macros/macro_variables.md** (Line 159): `environment`

### `concepts/models/python_models.md`

Linked from 5 file(s):

- **comparisons.md** (Line 25): `✅✅`
- **comparisons.md** (Line 169): `Python models`
- **guides-old/configuration.md** (Line 1374): `Python models concepts page`
- **configurations-old/configuration.md** (Line 65): ``context.var` method`
- **concepts-old/architecture/serialization.md** (Line 3): `Python models`

### `concepts/tests.md`

Linked from 5 file(s):

- **comparisons.md** (Line 31): `✅`
- **comparisons.md** (Line 164): `Unit and integration tests`
- **guides-old/connections.md** (Line 52): `tests`
- **guides/data_quality.md** (Line 582): `Testing`
- **getting_started/cli.md** (Line 256): `here`

### `integrations/engines/postgres.md`

Linked from 5 file(s):

- **guides-old/configuration.md** (Line 633): `Postgres`
- **guides-old/configuration.md** (Line 917): `Postgres`
- **guides-old/configuration.md** (Line 939): `Postgres`
- **guides-old/connections.md** (Line 88): `Postgres`
- **concepts-old/state.md** (Line 19): `PostgreSQL`

### `configurations-old/getting_started/docker.md`

Linked from 5 file(s):

- **configurations-old/integrations/engines/snowflake.md** (Line 18): `Vulcan Quickstart`
- **configurations-old/integrations/engines/motherduck.md** (Line 18): `Vulcan Quickstart`
- **configurations-old/integrations/engines/databricks.md** (Line 44): `Vulcan Quickstart`
- **configurations-old/integrations/engines/bigquery.md** (Line 7): `quickstart project`
- **configurations-old/integrations/engines/bigquery.md** (Line 20): `quickstart guide`

### `configurations-old/concepts/models/overview.md`

Linked from 5 file(s):

- **configurations-old/integrations/engines/athena.md** (Line 39): `properties`
- **configurations-old/integrations/engines/athena.md** (Line 46): `physical_properties`
- **configurations-old/integrations/engines/athena.md** (Line 71): `properties`
- **configurations-old/integrations/engines/mssql.md** (Line 22): ``physical_properties``
- **configurations-old/integrations/engines/clickhouse.md** (Line 390): ``partitioned_by``

### `components/model/types/model_kinds.md`

Linked from 5 file(s):

- **components/model/types/managed_models.md** (Line 13): `model kind`
- **components/model/types/managed_models.md** (Line 19): `materialized views`
- **components/model/types/managed_models.md** (Line 56): ``MANAGED``
- **components/model/types/python_models.md** (Line 16): `model kinds`
- **components/model/types/sql_models.md** (Line 324): `external models`

## Most Linked Pages

Internal pages sorted by number of incoming links:

- **`concepts/plans.md`** - 18 incoming links
- **`reference/configuration.md`** - 18 incoming links
- **`guides/configuration.md`** - 16 incoming links
- **`reference/cli.md`** - 12 incoming links
- **`concepts/models/model_kinds.md`** - 12 incoming links
- **`guides/reference/cli.md`** - 11 incoming links
- **`concepts-old/plans.md`** - 10 incoming links
- **`concepts-old/macros/macro_variables.md`** - 10 incoming links
- **`concepts/glossary.md`** - 9 incoming links
- **`reference/model_configuration.md`** - 9 incoming links
- **`configurations-old/guides/configuration.md`** - 9 incoming links
- **`getting_started/docker.md`** - 7 incoming links
- **`configurations-old/concepts/models/model_kinds.md`** - 7 incoming links
- **`concepts-old/glossary.md`** - 7 incoming links
- **`concepts-old/models/model_kinds.md`** - 7 incoming links
- **`concepts-old/macros/vulcan_macros.md`** - 7 incoming links
- **`concepts/macros/vulcan_macros.md`** - 6 incoming links
- **`concepts/audits.md`** - 6 incoming links
- **`concepts/environments.md`** - 6 incoming links
- **`components/model/model_kinds.md`** - 6 incoming links

## External Resources

### External Domains

- `github.com` - 35 references
- `sqlglot.com` - 21 references
- `en.wikipedia.org` - 20 references
- `docs.snowflake.com` - 19 references
- `docs.databricks.com` - 18 references
- `trino.io` - 15 references
- `vulcan.readthedocs.io` - 12 references
- `clickhouse.com` - 12 references
- `duckdb.org` - 11 references
- `cloud.google.com` - 9 references
- `jinja.palletsprojects.com` - 8 references
- `tobikodata.com` - 7 references
- `docs.aws.amazon.com` - 6 references
- `api.slack.com` - 4 references
- `docs.python.org` - 4 references
- `learn.microsoft.com` - 4 references
- `google-auth.readthedocs.io` - 4 references
- `www.docker.com` - 4 references
- `docs.docker.com` - 3 references
- `dateparser.readthedocs.io` - 2 references
- `boto3.amazonaws.com` - 2 references
- `aws.amazon.com` - 2 references
- `docs.risingwave.com` - 2 references
- `www.getdbt.com` - 1 references
- `www.postgresql.org` - 1 references
- `regex101.com` - 1 references
- `chat.openai.com` - 1 references
- `en.m.wikipedia.org` - 1 references
- `filesystem-spec.readthedocs.io` - 1 references
- `fsspec.github.io` - 1 references
- `projectnessie.org` - 1 references
- `zookeeper.apache.org` - 1 references
- `azure.microsoft.com` - 1 references
- `pypi.org` - 1 references
- `googleapis.dev` - 1 references
- `risingwave.com` - 1 references
- `www.medcalc.org` - 1 references
- `pandas.pydata.org` - 1 references
- `packaging.python.org` - 1 references

### External Links by Category

- **GitHub**: 16 links
- **Documentation sites**: 54 links
- **Wikipedia**: 12 links

## Links by File

### Table of Contents

- **Root files**
  - [comparisons.md](#comparisons) (23 links)
  - [index.md](#index) (1 links)
- **components/advanced-features/**
  - [components/advanced-features/custom_materializations.md](#components-advanced-features-custom_materializations) (6 links)
  - [components/advanced-features/signals.md](#components-advanced-features-signals) (2 links)
- **components/advanced-features/macros/**
  - [components/advanced-features/macros/built_in.md](#components-advanced-features-macros-built_in) (69 links)
  - [components/advanced-features/macros/jinja.md](#components-advanced-features-macros-jinja) (6 links)
  - [components/advanced-features/macros/overview.md](#components-advanced-features-macros-overview) (5 links)
  - [components/advanced-features/macros/variables.md](#components-advanced-features-macros-variables) (16 links)
- **components/audits/**
  - [components/audits/audits.md](#components-audits-audits) (7 links)
- **components/checks/**
  - [components/checks/checks.md](#components-checks-checks) (1 links)
- **components/model/**
  - [components/model/model_kinds.md](#components-model-model_kinds) (12 links)
  - [components/model/overview.md](#components-model-overview) (3 links)
  - [components/model/properties.md](#components-model-properties) (14 links)
  - [components/model/statements.md](#components-model-statements) (1 links)
- **components/model/types/**
  - [components/model/types/external_models.md](#components-model-types-external_models) (2 links)
  - [components/model/types/managed_models.md](#components-model-types-managed_models) (11 links)
  - [components/model/types/python_models.md](#components-model-types-python_models) (13 links)
  - [components/model/types/sql_models.md](#components-model-types-sql_models) (12 links)
- **components/semantics/**
  - [components/semantics/business_metrics.md](#components-semantics-business_metrics) (2 links)
  - [components/semantics/models.md](#components-semantics-models) (2 links)
  - [components/semantics/overview.md](#components-semantics-overview) (5 links)
- **components/tests/**
  - [components/tests/tests.md](#components-tests-tests) (3 links)
- **concepts-old/**
  - [concepts-old/environments.md](#concepts-old-environments) (7 links)
  - [concepts-old/glossary.md](#concepts-old-glossary) (11 links)
  - [concepts-old/overview.md](#concepts-old-overview) (10 links)
  - [concepts-old/plans.md](#concepts-old-plans) (50 links)
  - [concepts-old/state.md](#concepts-old-state) (10 links)
- **concepts-old/architecture/**
  - [concepts-old/architecture/serialization.md](#concepts-old-architecture-serialization) (4 links)
  - [concepts-old/architecture/snapshots.md](#concepts-old-architecture-snapshots) (1 links)
- **concepts-old/macros/**
  - [concepts-old/macros/jinja_macros.md](#concepts-old-macros-jinja_macros) (12 links)
  - [concepts-old/macros/macro_variables.md](#concepts-old-macros-macro_variables) (18 links)
  - [concepts-old/macros/overview.md](#concepts-old-macros-overview) (5 links)
  - [concepts-old/macros/vulcan_macros.md](#concepts-old-macros-vulcan_macros) (69 links)
- **configurations/**
  - [configurations/overview.md](#configurations-overview) (14 links)
- **configurations-old/**
  - [configurations-old/configuration.md](#configurations-old-configuration) (39 links)
- **configurations-old/integrations/engines/**
  - [configurations-old/integrations/engines/athena.md](#configurations-old-integrations-engines-athena) (15 links)
  - [configurations-old/integrations/engines/azuresql.md](#configurations-old-integrations-engines-azuresql) (2 links)
  - [configurations-old/integrations/engines/bigquery.md](#configurations-old-integrations-engines-bigquery) (31 links)
  - [configurations-old/integrations/engines/clickhouse.md](#configurations-old-integrations-engines-clickhouse) (31 links)
  - [configurations-old/integrations/engines/databricks.md](#configurations-old-integrations-engines-databricks) (74 links)
  - [configurations-old/integrations/engines/duckdb.md](#configurations-old-integrations-engines-duckdb) (15 links)
  - [configurations-old/integrations/engines/fabric.md](#configurations-old-integrations-engines-fabric) (2 links)
  - [configurations-old/integrations/engines/motherduck.md](#configurations-old-integrations-engines-motherduck) (8 links)
  - [configurations-old/integrations/engines/mssql.md](#configurations-old-integrations-engines-mssql) (4 links)
  - [configurations-old/integrations/engines/redshift.md](#configurations-old-integrations-engines-redshift) (1 links)
  - [configurations-old/integrations/engines/risingwave.md](#configurations-old-integrations-engines-risingwave) (6 links)
  - [configurations-old/integrations/engines/snowflake.md](#configurations-old-integrations-engines-snowflake) (32 links)
  - [configurations-old/integrations/engines/spark.md](#configurations-old-integrations-engines-spark) (2 links)
  - [configurations-old/integrations/engines/trino.md](#configurations-old-integrations-engines-trino) (28 links)
- **configurations/engines/snowflake/**
  - [configurations/engines/snowflake/snowflake.md](#configurations-engines-snowflake-snowflake) (32 links)
- **configurations/options/**
  - [configurations/options/linter.md](#configurations-options-linter) (3 links)
  - [configurations/options/model_defaults.md](#configurations-options-model_defaults) (5 links)
  - [configurations/options/notifications.md](#configurations-options-notifications) (12 links)
- **getting_started/**
  - [getting_started/cli.md](#getting_started-cli) (28 links)
  - [getting_started/index.md](#getting_started-index) (2 links)
  - [getting_started/prerequisites.md](#getting_started-prerequisites) (4 links)
- **guides/**
  - [guides/data_quality.md](#guides-data_quality) (4 links)
  - [guides/incremental_by_time.md](#guides-incremental_by_time) (7 links)
  - [guides/model_selection.md](#guides-model_selection) (6 links)
  - [guides/models.md](#guides-models) (8 links)
  - [guides/plan.md](#guides-plan) (7 links)
  - [guides/run_and_scheduling.md](#guides-run_and_scheduling) (7 links)
  - [guides/transpiling_semantics.md](#guides-transpiling_semantics) (3 links)
- **guides-old/**
  - [guides-old/configuration.md](#guides-old-configuration) (85 links)
  - [guides-old/connections.md](#guides-old-connections) (13 links)
  - [guides-old/customizing_vulcan.md](#guides-old-customizing_vulcan) (1 links)
  - [guides-old/isolated_systems.md](#guides-old-isolated_systems) (10 links)
  - [guides-old/notifications.md](#guides-old-notifications) (12 links)
  - [guides-old/projects.md](#guides-old-projects) (3 links)
  - [guides-old/table_migration.md](#guides-old-table_migration) (5 links)
- **guides/get-started/**
  - [guides/get-started/docker.md](#guides-get-started-docker) (18 links)

### Root Files

#### comparisons.md {#comparisons}

**Internal Links** (20):

- Line 7: `[Why Vulcan](index.md#why-vulcan)`
- Line 7: `[What is Vulcan](index.md#what-is-vulcan)`
- Line 24: `[✅](concepts/models/overview.md)` ⚠️
- Line 25: `[✅✅](concepts/models/python_models.md)` ⚠️
- Line 27: `[✅](concepts/macros/jinja_macros.md)` ⚠️
- Line 28: `[✅](concepts/macros/vulcan_macros.md)` ⚠️
- Line 30: `[✅](concepts/glossary.md#semantic-understanding)` ⚠️
- Line 31: `[✅](concepts/tests.md)` ⚠️
- Line 33: `[✅](concepts/audits.md)` ⚠️
- Line 34: `[✅](concepts/plans.md)` ⚠️
- Line 35: `[✅](concepts/plans.md)` ⚠️
- Line 37: `[✅](concepts/environments.md)` ⚠️
- Line 41: `[✅](reference/cli.md)` ⚠️
- Line 51: `[✅](concepts/models/sql_models.md#transpilation)` ⚠️
- Line 65: `[Virtual Environments](./concepts/plans.md#plan-application)` ⚠️
- Line 152: `[batch](concepts/models/overview.md#batch_size)` ⚠️
- Line 164: `[Unit and integration tests](./concepts/tests.md)` ⚠️
- Line 169: `[Python models](concepts/models/python_models.md)` ⚠️
- Line 174: `[`vulcan plan`](concepts/plans.md)` ⚠️
- Line 176: `[Virtual Preview](concepts/glossary.md#virtual-preview)` ⚠️

**External Links** (3):

- Line 10: `[dbt](https://www.getdbt.com/)`
- Line 155: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`
- Line 157: `[SQLGlot](https://github.com/tobymao/sqlglot)`

---

#### index.md {#index}

**Internal Links** (1):

- Line 104: `[quickstart guide](getting_started/docker.md)` ⚠️

---

### components/advanced-features/

#### components/advanced-features/custom_materializations.md {#components-advanced-features-custom_materializations}

**Internal Links** (3):

- Line 3: `[model kinds](../concepts/models/model_kinds.md)` ⚠️
- Line 35: `[Python model](../concepts/models/python_models.md)` ⚠️
- Line 37: `[Python package](#python-packaging)`

**External Links** (3):

- Line 8: `[community slack](https://tobikodata.com/community.html)`
- Line 400: `[setuptools entrypoints](https://packaging.python.org/en/latest/guides/creating-and-discovering-plugins/#using-package-metadata)`
- Line 424: `[custom_materializations](https://github.com/TobikoData/vulcan/tree/main/examples/custom_materializations)`

---

#### components/advanced-features/signals.md {#components-advanced-features-signals}

**Internal Links** (2):

- Line 3: `[built-in scheduler](./scheduling.md#built-in-scheduler)` ⚠️
- Line 55: `[Vulcan macros](../concepts/macros/vulcan_macros.md#typed-macros)` ⚠️

---

### components/advanced-features/macros/

#### components/advanced-features/macros/built_in.md {#components-advanced-features-macros-built_in}

**Internal Links** (46):

- Line 29: `[user-defined macro variables](#user-defined-variables)`
- Line 30: `[Vulcan pre-defined](./macro_variables.md)` ⚠️
- Line 30: `[user-defined local](#local-variables)` ⚠️
- Line 30: `[user-defined global](#global-variables)` ⚠️
- Line 31: `[Vulcan's](#macro-operators)`
- Line 31: `[user-defined](#user-defined-macro-functions)`
- Line 51: `[gateway variable](#gateway-variables)`
- Line 95: `[global](#global-variables)`
- Line 95: `[gateway](#gateway-variables)`
- Line 95: `[blueprint](#blueprint-variables)`
- Line 95: `[local](#local-variables)`
- Line 105: `[`variables` key](../../reference/configuration.md#variables)` ⚠️
- Line 171: `[Python macro functions](#accessing-global-variable-values)` ⚠️
- Line 171: `[Python models](../models/python_models.md#user-defined-variables)` ⚠️
- Line 204: `[global variables](#global-variables)`
- Line 210: `[global](#global-variables)`
- Line 210: `[gateway-specific](#gateway-variables)`
- Line 212: `[creating model templates](../models/sql_models.md)` ⚠️
- Line 247: `[above](#embedding-variables-in-strings)`
- Line 253: `[global](#global-variables)`
- Line 253: `[blueprint](#blueprint-variables)`
- Line 253: `[gateway-specific](#gateway-variables)`
- Line 267: `[Vulcan quickstart guide](../../getting_started/docker.md)` ⚠️
- Line 527: `[above](#embedding-variables-in-strings)`
- Line 601: `[Macro rendering](#vulcan-macro-approach)`
- Line 615: `[runtime stage](./macro_variables.md#predefined-variables)` ⚠️
- Line 646: `[`@IF` operator](#if)`
- Line 672: `[`@EACH`](#each)`
- Line 672: `[`@REDUCE`](#reduce)`
- Line 676: `[`@IF`](#if)`
- Line 753: `[below](#positional-and-keyword-arguments)`
- Line 1052: `[below](#positional-and-keyword-arguments)`
- Line 1153: `[runtime stages](./macro_variables.md#runtime-variables)` ⚠️
- Line 1166: `[above](#embedding-variables-in-strings)`
- Line 1243: `[User-defined Variables](#user-defined-variables)`
- Line 1475: `[Jinja templating system](./jinja.md#user-defined-macro-functions)`
- Line 1492: `[argument type annotations are provided](#argument-data-types)`
- Line 1496: `[return a list of strings or expressions](#returning-more-than-one-value)`
- Line 1548: `[below](#typed-macros)`
- Line 1550: `[mentioned above](#inputs-and-outputs)`
- Line 1617: `[previous section](#positional-and-keyword-arguments)`
- Line 1690: `[Pre-defined variables](./macro_variables.md#predefined-variables)` ⚠️
- Line 1690: `[user-defined local variables](#local-variables)` ⚠️
- Line 1746: `[User-defined global variables](#global-variables)`
- Line 1831: `[external model](../models/external_models.md)` ⚠️
- Line 2120: `[Jinja macros](./jinja.md)`

**External Links** (23):

- Line 5: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`
- Line 9: `[sqlglot](https://github.com/tobymao/sqlglot)`
- Line 547: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 676: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 817: `[`MD5`](https://en.wikipedia.org/wiki/MD5)`
- Line 823: `[`MD5()` hash function](https://en.wikipedia.org/wiki/MD5)`
- Line 1006: `[haversine distance](https://en.wikipedia.org/wiki/Haversine_formula)`
- Line 1111: `[`date_spine`](https://github.com/dbt-labs/dbt-utils?tab=readme-ov-file#date_spine-source)`
- Line 1151: `[`<table>$properties`](https://trino.io/docs/current/connector/iceberg.html#metadata-tables)`
- Line 1239: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 1343: `[common table expressions](https://en.wikipedia.org/wiki/Hierarchical_and_recursive_queries_in_SQL#Common_table_expression)`
- Line 1646: `[`Literal` expressions](https://sqlglot.com/sqlglot/expressions.html#Literal)`
- Line 1647: `[`Literal` expressions](https://sqlglot.com/sqlglot/expressions.html#Literal)`
- Line 1648: `[`Column` expressions](https://sqlglot.com/sqlglot/expressions.html#Column)`
- Line 1650: `[`Array` expression](https://sqlglot.com/sqlglot/expressions.html#Array)`
- Line 1878: `[DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)`
- Line 1902: `[SQLGlot](https://github.com/tobymao/sqlglot)`
- Line 1932: `[SQLGLot expression](https://github.com/tobymao/sqlglot/blob/main/sqlglot/expressions.py)`
- Line 1942: `[Column expression](https://sqlglot.com/sqlglot/expressions.html#Column)`
- Line 1944: `[Condition class](https://sqlglot.com/sqlglot/expressions.html#Condition)`
- Line 1944: `[`between`](https://sqlglot.com/sqlglot/expressions.html#Condition.between)`
- Line 1944: `[`like`](https://sqlglot.com/sqlglot/expressions.html#Condition.like)`
- Line 2112: `[here](https://github.com/TobikoData/vulcan/blob/main/tests/core/test_macros.py)`

---

#### components/advanced-features/macros/jinja.md {#components-advanced-features-macros-jinja}

**Internal Links** (5):

- Line 54: `[predefined macro variables](./variables.md)`
- Line 78: `[Vulcan macros documentation](./built_in.md#global-variables)`
- Line 108: `[Vulcan macros documentation](./built_in.md#gateway-variables)`
- Line 326: `[Vulcan macros](./built_in.md)`
- Line 328: `[predefined Vulcan macro variables](./variables.md)`

**External Links** (1):

- Line 3: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`

---

#### components/advanced-features/macros/overview.md {#components-advanced-features-macros-overview}

**Internal Links** (4):

- Line 14: `[pre-defined variables](./variables.md)`
- Line 18: `[Pre-defined macro variables](./variables.md)`
- Line 19: `[Vulcan macros](./built_in.md)`
- Line 20: `[Jinja macros](./jinja.md)`

**External Links** (1):

- Line 3: `[declarative language](https://en.wikipedia.org/wiki/Declarative_programming)`

---

#### components/advanced-features/macros/variables.md {#components-advanced-features-macros-variables}

**Internal Links** (13):

- Line 8: `[Vulcan macros page](./built_in.md#user-defined-variables)`
- Line 8: `[Jinja macros page](./jinja.md#user-defined-variables)`
- Line 57: `[here](../model/model_kinds.md#timezones)` ⚠️
- Line 137: `[pre/post-statements](../model/sql_models.md#optional-prepost-statements)` ⚠️
- Line 139: `[gateway](../../guides/connections.md)` ⚠️
- Line 141: `[generic audits](../audits.md#generic-audits)` ⚠️
- Line 141: `[on_virtual_update statements](../model/sql_models.md#optional-on-virtual-update-statements)` ⚠️
- Line 143: `[physical properties in model defaults](../../reference/model_configuration.md#model-defaults)` ⚠️
- Line 154: `[Vulcan macros documentation](./built_in.md#embedding-variables-in-strings)`
- Line 158: `[`before_all` and `after_all` statements](../../guides/configuration.md#before_all-and-after_all-statements)` ⚠️
- Line 160: `[environment](../environments.md)` ⚠️
- Line 161: `[virtual layer](../../concepts/glossary.md#virtual-layer)` ⚠️
- Line 162: `[virtual layer](../../concepts/glossary.md#virtual-layer)` ⚠️

**External Links** (3):

- Line 52: `[datetime module](https://docs.python.org/3/library/datetime.html)`
- Line 52: `[Unix epoch](https://en.wikipedia.org/wiki/Unix_time)`
- Line 55: `[UTC time zone](https://en.wikipedia.org/wiki/Coordinated_Universal_Time)`

---

### components/audits/

#### components/audits/audits.md {#components-audits-audits}

**Internal Links** (4):

- Line 5: `[tests](../tests/tests.md)` ⚠️
- Line 5: `[plan](./plans.md)` ⚠️
- Line 75: `[restatement plan](./plans.md#restatement-plans)` ⚠️
- Line 133: `[macros](./macros/overview.md)` ⚠️

**External Links** (3):

- Line 743: `[symmetrised Kullback-Leibler divergence](https://en.wikipedia.org/wiki/Kullback%E2%80%93Leibler_divergence#Symmetrised_divergence)`
- Line 760: `[chi-square statistic](https://en.wikipedia.org/wiki/Chi-squared_test)`
- Line 764: `[chi-square table](https://www.medcalc.org/manual/chi-square-table.php)`

---

### components/checks/

#### components/checks/checks.md {#components-checks-checks}

**Internal Links** (1):

- Line 5: `[audits](audits.md)` ⚠️

---

### components/model/

#### components/model/model_kinds.md {#components-model-model_kinds}

**Internal Links** (11):

- Line 7: `[model configuration reference page](../../reference/model_configuration.md)` ⚠️
- Line 33: `[Macros documentation](../macros/macro_variables.md)` ⚠️
- Line 408: `[above](#timezones)`
- Line 505: `[idempotent](../glossary.md#idempotency)` ⚠️
- Line 535: `[SCD Type 2](#scd-type-2)`
- Line 696: `[non-idempotent](../glossary.md#idempotency)` ⚠️
- Line 1627: `[Processing Source Table with Historical Data](#processing-source-table-with-historical-data)`
- Line 1658: `[Processing Source Table with Historical Data](#processing-source-table-with-historical-data)`
- Line 1858: `[External Models documentation](./external_models.md)` ⚠️
- Line 1886: `[Managed Models documentation](./managed_models.md)` ⚠️
- Line 1903: `[non-idempotent](../glossary.md#idempotency)` ⚠️

**External Links** (1):

- Line 767: `[Redshift documentation](https://docs.aws.amazon.com/redshift/latest/dg/r_MERGE.html#r_MERGE-parameters)`

---

#### components/model/overview.md {#components-model-overview}

**Internal Links** (3):

- Line 129: `[Model Properties](./properties.md)`
- Line 343: `[Python Models](./python_models.md)` ⚠️
- Line 401: `[macros documentation](../macros/overview.md)` ⚠️

---

#### components/model/properties.md {#components-model-properties}

**Internal Links** (13):

- Line 48: `[name inference](#model-naming)`
- Line 120: `[Model Kinds](model_kinds.md)`
- Line 505: `[inline column comments](./overview.md#inline-column-comments)`
- Line 547: `[Python models](./python_models.md)` ⚠️
- Line 599: `[audits](../audits.md)` ⚠️
- Line 1200: `[Model Kinds](model_kinds.md)`
- Line 1208: `[forward-only](../plans.md#forward-only-plans)` ⚠️
- Line 1211: `[data restatement](../plans.md#restatement-plans)` ⚠️
- Line 1259: `[Model Kinds documentation](model_kinds.md#incremental_by_time_range)`
- Line 1334: `[Model Kinds documentation](model_kinds.md#incremental_by_unique_key)`
- Line 1416: `[Model Kinds documentation](model_kinds.md#incremental_by_partition)`
- Line 1457: `[Model Kinds documentation](model_kinds.md#scd-type-2)`
- Line 1666: `[configuration guide](../../guides/configuration.md#model-naming)` ⚠️

**External Links** (1):

- Line 555: `[SQLGlot dialects](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/__init__.py)`

---

#### components/model/statements.md {#components-model-statements}

**Internal Links** (1):

- Line 504: `[Macro Variables](../macros/macro_variables.md)` ⚠️

---

### components/model/types/

#### components/model/types/external_models.md {#components-model-types-external_models}

**Internal Links** (2):

- Line 79: `[isolated systems with multiple gateways](../../guides/isolated_systems.md#multiple-gateways)` ⚠️
- Line 158: `[assertions](../audits.md)` ⚠️

---

#### components/model/types/managed_models.md {#components-model-types-managed_models}

**Internal Links** (7):

- Line 9: `[External Models](./external_models.md)`
- Line 13: `[model kind](./model_kinds.md)` ⚠️
- Line 19: `[materialized views](./model_kinds.md#materialized-views)` ⚠️
- Line 54: `[Snowflake](../../configurations/engines/snowflake.md)` ⚠️
- Line 56: `[`MANAGED`](./model_kinds.md#managed)` ⚠️
- Line 102: `[`physical_properties`](../overview.md#physical_properties)`
- Line 117: `[standard model property](../models/overview.md#clustered_by)` ⚠️

**External Links** (4):

- Line 46: `[let us know](https://tobikodata.com/slack)`
- Line 54: `[Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)`
- Line 60: `[Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro)`
- Line 100: `[Snowflake documentation](https://docs.snowflake.com/sql-reference/sql/create-dynamic-table)`

---

#### components/model/types/python_models.md {#components-model-types-python_models}

**Internal Links** (12):

- Line 16: `[model kinds](./model_kinds.md)` ⚠️
- Line 105: `[model configuration reference](../../reference/model_configuration.md#model-kind-properties)` ⚠️
- Line 139: `[idempotent](../glossary.md#idempotency)` ⚠️
- Line 158: `[model configuration reference](../../reference/model_configuration.md#model-defaults)` ⚠️
- Line 238: `[model configuration reference](../../reference/model_configuration.md#model-defaults)` ⚠️
- Line 269: `[environment](../environments.md)` ⚠️
- Line 319: `[global variables](../../reference/configuration.md#variables)` ⚠️
- Line 319: `[blueprint variables](#python-model-blueprinting)` ⚠️
- Line 357: `[User-defined global variables](../../reference/configuration.md#variables)` ⚠️
- Line 447: `[here](../../concepts/macros/vulcan_macros.md#embedding-variables-in-strings)` ⚠️
- Line 521: `[metadata properties](./overview.md#model-properties)` ⚠️
- Line 772: `[serialization framework](../architecture/serialization.md)` ⚠️

**External Links** (1):

- Line 685: `[Bigframe](https://cloud.google.com/bigquery/docs/use-bigquery-dataframes#pandas-examples)`

---

#### components/model/types/sql_models.md {#components-model-types-sql_models}

**Internal Links** (10):

- Line 52: `[Model Properties](./overview.md#model-properties)` ⚠️
- Line 89: `[model configuration reference](../../reference/model_configuration.md#model-defaults)` ⚠️
- Line 151: `[Jinja expressions](../macros/jinja_macros.md)` ⚠️
- Line 227: `[here](../../concepts/macros/vulcan_macros.md#embedding-variables-in-strings)` ⚠️
- Line 279: `[Python Models](./python_models.md)`
- Line 297: `[signals](../../guides/signals.md)` ⚠️
- Line 324: `[`create_external_models`](../../reference/cli.md#create_external_models)` ⚠️
- Line 324: `[external models](./model_kinds.md#external)` ⚠️
- Line 348: `[macro syntax](../macros/overview.md)` ⚠️
- Line 352: `[Macros documentation](../macros/overview.md)` ⚠️

**External Links** (2):

- Line 334: `[SQLGlot](https://github.com/tobymao/sqlglot)`
- Line 348: `[Jinja templates](https://jinja.palletsprojects.com/en/3.1.x/)`

---

### components/semantics/

#### components/semantics/business_metrics.md {#components-semantics-business_metrics}

**Internal Links** (2):

- Line 273: `[Semantic Models](models.md)`
- Line 274: `[Semantics Overview](overview.md)`

---

#### components/semantics/models.md {#components-semantics-models}

**Internal Links** (2):

- Line 346: `[Business Metrics](business_metrics.md)`
- Line 348: `[Semantics Overview](overview.md)`

---

#### components/semantics/overview.md {#components-semantics-overview}

**Internal Links** (5):

- Line 43: `[Semantic Models](models.md)`
- Line 69: `[Business Metrics](metrics.md)` ⚠️
- Line 158: `[Semantic Models](models.md)`
- Line 159: `[Business Metrics](metrics.md)` ⚠️
- Line 160: `[Transpiling Semantic Queries](../../guides/transpiling_semantics.md)`

---

### components/tests/

#### components/tests/tests.md {#components-tests-tests}

**Internal Links** (2):

- Line 5: `[audits](../audits/audits.md)`
- Line 17: `[plan](plans.md)` ⚠️

**External Links** (1):

- Line 635: `[pandas read_csv documentation](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html)`

---

### concepts-old/

#### concepts-old/environments.md {#concepts-old-environments}

**Internal Links** (7):

- Line 6: `[Models](models/overview.md)` ⚠️
- Line 14: `[plan](plans.md)`
- Line 16: `[`vulcan plan`](plans.md)`
- Line 27: `[fingerprint](architecture/snapshots.md#fingerprinting)`
- Line 27: `[snapshots](architecture/snapshots.md)`
- Line 29: `[plans](plans.md#plan-application)`
- Line 32: `[plan](plans.md)`

---

#### concepts-old/glossary.md {#concepts-old-glossary}

**Internal Links** (10):

- Line 13: `[tests](tests.md)` ⚠️
- Line 13: `[audits](audits.md)` ⚠️
- Line 16: `[tests](tests.md)` ⚠️
- Line 34: `[Indirect Modification](#indirect-modification)`
- Line 49: `[Model Kinds](models/model_kinds.md)` ⚠️
- Line 52: `[Direct Modification](#direct-modification)`
- Line 61: `[Vulcan virtual layer's](#virtual-layer)`
- Line 82: `[plan application](plans.md#plan-application)`
- Line 85: `[physical layer and physical data storage](#physical-layer)`
- Line 88: `[Virtual Update](plans.md#virtual-update)`

**External Links** (1):

- Line 67: `[SQLGlot](https://github.com/tobymao/sqlglot)`

---

#### concepts-old/overview.md {#concepts-old-overview}

**Internal Links** (10):

- Line 10: `[CLI](../reference/cli.md)` ⚠️
- Line 21: `[`plan` command](../reference/cli.md#plan)` ⚠️
- Line 25: `[plans](./plans.md)`
- Line 28: `[`plan`](../reference/cli.md#plan)` ⚠️
- Line 28: `[`apply`](./plans.md#plan-application)` ⚠️
- Line 52: `[Tests](./tests.md)` ⚠️
- Line 55: `[`test` command](../reference/cli.md#test)` ⚠️
- Line 57: `[Audits](./audits.md)` ⚠️
- Line 62: `[macros](./macros/overview.md)`
- Line 66: `[`audit` command](../reference/cli.md#audit)` ⚠️

---

#### concepts-old/plans.md {#concepts-old-plans}

**Internal Links** (50):

- Line 3: `[environment](environments.md)`
- Line 107: `[categorize changes](#change-categories)` ⚠️
- Line 107: `[configuration](../reference/configuration.md#plan)` ⚠️
- Line 191: `[backfilling](#backfilling)`
- Line 206: `[Breaking](#breaking-change)`
- Line 206: `[Direct](glossary.md#direct-modification)`
- Line 206: `[Indirect](glossary.md#indirect-modification)`
- Line 206: `[Backfill](glossary.md#backfill)`
- Line 207: `[Non-breaking](#non-breaking-change)`
- Line 207: `[Direct](glossary.md#direct-modification)`
- Line 207: `[Backfill](glossary.md#backfill)`
- Line 208: `[Non-breaking](#non-breaking-change)`
- Line 208: `[Indirect](glossary.md#indirect-modification)`
- Line 208: `[No Backfill](glossary.md#backfill)`
- Line 217: `[Forward-only Plans](#forward-only-plans)`
- Line 219: `[forward-only plan](#forward-only-plans)`
- Line 222: `[environment](environments.md)`
- Line 224: `[snapshot](architecture/snapshots.md)`
- Line 224: `[fingerprint](architecture/snapshots.md#fingerprinting)`
- Line 224: `[forward-only](#forward-only-plans)`
- Line 286: `[Each model variant gets its own physical table, while environments only contain references to these tables](plans/model_versioning.png)` ⚠️
- Line 286: `[Each model variant gets its own physical table, while environments only contain references to these tables](plans/model_versioning.png)` ⚠️
- Line 292: `[Virtual Update](#virtual-update)`
- Line 309: `[forward-only plan](#forward-only-plans)`
- Line 322: `[the model definition](./models/overview.md#start)` ⚠️
- Line 322: `[project configuration's `model_defaults`](../guides/configuration.md#model-defaults)` ⚠️
- Line 324: `[restatement plans](#restatement-plans)`
- Line 336: `[INCREMENTAL_BY_UNIQUE_KEY](models/model_kinds.md#incremental_by_unique_key)` ⚠️
- Line 337: `[INCREMENTAL_BY_PARTITION](models/model_kinds.md#incremental_by_partition)` ⚠️
- Line 338: `[SCD_TYPE_2_BY_TIME](models/model_kinds.md#scd-type-2-by-time-recommended)` ⚠️
- Line 339: `[SCD_TYPE_2_BY_COLUMN](models/model_kinds.md#scd-type-2-by-column)` ⚠️
- Line 522: `[forward-only changes](#forward-only-change)`
- Line 540: `[restatements](#restatement-plans)`
- Line 554: `[breaking and non-breaking changes](#change-categories)`
- Line 562: `[forward-only](models/overview.md#forward_only)` ⚠️
- Line 564: `[effective date](#effective-date)`
- Line 568: `[forward-only models](../guides/incremental_time.md#forward-only-models)` ⚠️
- Line 568: `[here](../guides/incremental_time.md#destructive-changes)` ⚠️
- Line 574: `[model's `on_destructive_change` value](../guides/incremental_time.md#schema-changes)` ⚠️
- Line 574: `[model defaults](../reference/model_configuration.md#model-defaults)` ⚠️
- Line 575: `[model's `on_additive_change` value](../guides/incremental_time.md#schema-changes)` ⚠️
- Line 575: `[model defaults](../reference/model_configuration.md#model-defaults)` ⚠️
- Line 590: `[here](../guides/model_selection.md)`
- Line 608: `[forward-only plan](#forward-only-plans)`
- Line 613: `[selector](../guides/model_selection.md)`
- Line 613: `[below](#restatement-examples)`
- Line 623: `[external model](./models/external_models.md)` ⚠️
- Line 625: `[below](#model-kind-limitations)`
- Line 633: `[disable_restatement](models/overview.md#disable_restatement)` ⚠️
- Line 671: `[development environment](./environments.md#how-to-use-environments)`

**Images** (1):

- Line 286: `![Each model variant gets its own physical table, while environments only contain references to these tables](plans/model_versioning.png)`

---

#### concepts-old/state.md {#concepts-old-state}

**Internal Links** (10):

- Line 7: `[Model Version](./models/overview.md)` ⚠️
- Line 8: `[Virtual Data Environment](./environments.md)`
- Line 9: `[promoted](./plans.md#plan-application)`
- Line 9: `[Virtual Data Environment](./environments.md)`
- Line 10: `[auto restatements](./models/overview.md#auto_restatement_cron)` ⚠️
- Line 13: `[incremental models](./models/model_kinds.md#incremental_by_time_range)` ⚠️
- Line 19: `[PostgreSQL](../integrations/engines/postgres.md)` ⚠️
- Line 23: `[configuration guide](../guides/configuration.md#state-connection)` ⚠️
- Line 173: `[multiple gateways](../guides/configuration.md#gateways)` ⚠️
- Line 173: `[state_connection](../guides/configuration.md#state-connection)` ⚠️

---

### concepts-old/architecture/

#### concepts-old/architecture/serialization.md {#concepts-old-architecture-serialization}

**Internal Links** (4):

- Line 3: `[macros](../macros/overview.md)` ⚠️
- Line 3: `[Python models](../../concepts/models/python_models.md)` ⚠️
- Line 3: `[snapshot](../architecture/snapshots.md)` ⚠️
- Line 9: `[snapshot fingerprinting](../architecture/snapshots.md#fingerprinting)`

---

#### concepts-old/architecture/snapshots.md {#concepts-old-architecture-snapshots}

**Internal Links** (1):

- Line 10: `[change categories](../plans.md#change-categories)`

---

### concepts-old/macros/

#### concepts-old/macros/jinja_macros.md {#concepts-old-macros-jinja_macros}

**Internal Links** (10):

- Line 55: `[predefined macro variables](./macro_variables.md)`
- Line 57: `[`runtime_stage`](./macro_variables.md#runtime-variables)`
- Line 57: `[`this_model`](./macro_variables.md#runtime-variables)`
- Line 59: `[temporal](./macro_variables.md#temporal-variables)`
- Line 87: `[Vulcan macros documentation](./vulcan_macros.md#global-variables)`
- Line 119: `[Vulcan macros documentation](./vulcan_macros.md#gateway-variables)`
- Line 121: `[global variables](#global-variables)`
- Line 127: `[creating model templates](../models/sql_models.md)` ⚠️
- Line 324: `[Vulcan](./vulcan_macros.md)`
- Line 326: `[Predefined Vulcan macro variables](./macro_variables.md)`

**External Links** (2):

- Line 3: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`
- Line 178: `[Python methods](https://jinja.palletsprojects.com/en/3.1.x/templates/#python-methods)`

---

#### concepts-old/macros/macro_variables.md {#concepts-old-macros-macro_variables}

**Internal Links** (15):

- Line 9: `[Vulcan macros page](./vulcan_macros.md#user-defined-variables)`
- Line 45: `[Vulcan macros](./vulcan_macros.md#user-defined-variables)`
- Line 45: `[Jinja macros](./jinja_macros.md#user-defined-variables)`
- Line 50: `[other predefined variables](#runtime-variables)`
- Line 60: `[here](../models/model_kinds.md#timezones)` ⚠️
- Line 131: `[here](../models/sql_models.md#optional-prepost-statements)` ⚠️
- Line 139: `[gateway](../../guides/connections.md)` ⚠️
- Line 140: `[generic audits](../audits.md#generic-audits)` ⚠️
- Line 140: `[on_virtual_update statements](../models/sql_models.md#optional-on-virtual-update-statements)` ⚠️
- Line 141: `[physical properties in model defaults](../../reference/model_configuration.md#model-defaults)` ⚠️
- Line 153: `[Vulcan macros documentation](./vulcan_macros.md#embedding-variables-in-strings)`
- Line 157: `[`before_all` and `after_all` statements](../../guides/configuration.md#before_all-and-after_all-statements)` ⚠️
- Line 159: `[environment](../environments.md)`
- Line 160: `[virtual layer](../../concepts/glossary.md#virtual-layer)` ⚠️
- Line 161: `[virtual layer](../../concepts/glossary.md#virtual-layer)` ⚠️

**External Links** (3):

- Line 54: `[datetime module](https://docs.python.org/3/library/datetime.html)`
- Line 54: `[Unix epoch](https://en.wikipedia.org/wiki/Unix_time)`
- Line 58: `[UTC time zone](https://en.wikipedia.org/wiki/Coordinated_Universal_Time)`

---

#### concepts-old/macros/overview.md {#concepts-old-macros-overview}

**Internal Links** (3):

- Line 11: `[Pre-defined macro variables](./macro_variables.md)`
- Line 12: `[Vulcan macros](./vulcan_macros.md)`
- Line 13: `[Jinja macros](./jinja_macros.md)`

**External Links** (2):

- Line 3: `[declarative language](https://en.wikipedia.org/wiki/Declarative_programming)`
- Line 7: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`

---

#### concepts-old/macros/vulcan_macros.md {#concepts-old-macros-vulcan_macros}

**Internal Links** (46):

- Line 31: `[user-defined macro variables](#user-defined-variables)`
- Line 32: `[Vulcan pre-defined](./macro_variables.md)`
- Line 32: `[user-defined local](#local-variables)`
- Line 32: `[user-defined global](#global-variables)`
- Line 33: `[Vulcan's](#macro-operators)`
- Line 33: `[user-defined](#user-defined-macro-functions)`
- Line 53: `[gateway variable](#gateway-variables)`
- Line 97: `[global](#global-variables)`
- Line 97: `[gateway](#gateway-variables)`
- Line 97: `[blueprint](#blueprint-variables)`
- Line 97: `[local](#local-variables)`
- Line 105: `[`variables` key](../../reference/configuration.md#variables)` ⚠️
- Line 171: `[Python macro functions](#accessing-global-variable-values)` ⚠️
- Line 171: `[Python models](../models/python_models.md#user-defined-variables)` ⚠️
- Line 204: `[global variables](#global-variables)`
- Line 210: `[global](#global-variables)`
- Line 210: `[gateway-specific](#gateway-variables)`
- Line 212: `[creating model templates](../models/sql_models.md)` ⚠️
- Line 247: `[above](#embedding-variables-in-strings)`
- Line 253: `[global](#global-variables)`
- Line 253: `[blueprint](#blueprint-variables)`
- Line 253: `[gateway-specific](#gateway-variables)`
- Line 267: `[Vulcan quickstart guide](../../getting_started/docker.md)` ⚠️
- Line 529: `[above](#embedding-variables-in-strings)`
- Line 603: `[Macro rendering](#vulcan-macro-approach)`
- Line 617: `[runtime stage](./macro_variables.md#predefined-variables)`
- Line 648: `[`@IF` operator](#if)`
- Line 674: `[`@EACH`](#each)`
- Line 674: `[`@REDUCE`](#reduce)`
- Line 678: `[`@IF`](#if)`
- Line 755: `[below](#positional-and-keyword-arguments)`
- Line 1054: `[below](#positional-and-keyword-arguments)`
- Line 1155: `[runtime stages](./macro_variables.md#runtime-variables)`
- Line 1168: `[above](#embedding-variables-in-strings)`
- Line 1245: `[User-defined Variables](#user-defined-variables)`
- Line 1477: `[Jinja templating system](./jinja_macros.md#user-defined-macro-functions)`
- Line 1494: `[argument type annotations are provided](#argument-data-types)`
- Line 1498: `[return a list of strings or expressions](#returning-more-than-one-value)`
- Line 1550: `[below](#typed-macros)`
- Line 1552: `[mentioned above](#inputs-and-outputs)`
- Line 1619: `[previous section](#positional-and-keyword-arguments)`
- Line 1692: `[Pre-defined variables](./macro_variables.md#predefined-variables)`
- Line 1692: `[user-defined local variables](#local-variables)`
- Line 1748: `[User-defined global variables](#global-variables)`
- Line 1833: `[external model](../models/external_models.md)` ⚠️
- Line 2122: `[Jinja](./jinja_macros.md)`

**External Links** (23):

- Line 5: `[Jinja](https://jinja.palletsprojects.com/en/3.1.x/)`
- Line 13: `[sqlglot](https://github.com/tobymao/sqlglot)`
- Line 549: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 678: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 819: `[`MD5`](https://en.wikipedia.org/wiki/MD5)`
- Line 825: `[`MD5()` hash function](https://en.wikipedia.org/wiki/MD5)`
- Line 1008: `[haversine distance](https://en.wikipedia.org/wiki/Haversine_formula)`
- Line 1113: `[`date_spine`](https://github.com/dbt-labs/dbt-utils?tab=readme-ov-file#date_spine-source)`
- Line 1153: `[`<table>$properties`](https://trino.io/docs/current/connector/iceberg.html#metadata-tables)`
- Line 1241: `[SQLGlot's](https://github.com/tobymao/sqlglot)`
- Line 1345: `[common table expressions](https://en.wikipedia.org/wiki/Hierarchical_and_recursive_queries_in_SQL#Common_table_expression)`
- Line 1648: `[`Literal` expressions](https://sqlglot.com/sqlglot/expressions.html#Literal)`
- Line 1649: `[`Literal` expressions](https://sqlglot.com/sqlglot/expressions.html#Literal)`
- Line 1650: `[`Column` expressions](https://sqlglot.com/sqlglot/expressions.html#Column)`
- Line 1652: `[`Array` expression](https://sqlglot.com/sqlglot/expressions.html#Array)`
- Line 1880: `[DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)`
- Line 1904: `[SQLGlot](https://github.com/tobymao/sqlglot)`
- Line 1934: `[SQLGLot expression](https://github.com/tobymao/sqlglot/blob/main/sqlglot/expressions.py)`
- Line 1944: `[Column expression](https://sqlglot.com/sqlglot/expressions.html#Column)`
- Line 1946: `[Condition class](https://sqlglot.com/sqlglot/expressions.html#Condition)`
- Line 1946: `[`between`](https://sqlglot.com/sqlglot/expressions.html#Condition.between)`
- Line 1946: `[`like`](https://sqlglot.com/sqlglot/expressions.html#Condition.like)`
- Line 2114: `[here](https://github.com/TobikoData/vulcan/blob/main/tests/core/test_macros.py)`

---

### configurations/

#### configurations/overview.md {#configurations-overview}

**Internal Links** (14):

- Line 98: `[Configuration Reference](./configuration.md#gateways)` ⚠️
- Line 112: `[Model Defaults](./model_defaults.md)` ⚠️
- Line 118: `[Variables](./variables.md)` ⚠️
- Line 124: `[Execution Hooks](./hooks.md)` ⚠️
- Line 130: `[Linter](./linter.md)` ⚠️
- Line 136: `[Notifications](./notifications.md)` ⚠️
- Line 142: `[PostgreSQL](./integrations/engines/postgres.md)` ⚠️
- Line 143: `[Snowflake](./integrations/engines/snowflake.md)` ⚠️
- Line 149: `[Configuration Reference](./configuration.md)` ⚠️
- Line 150: `[Variables](./variables.md)` ⚠️
- Line 151: `[Model Defaults](./model_defaults.md)` ⚠️
- Line 152: `[Execution Hooks](./hooks.md)` ⚠️
- Line 153: `[Linter](./linter.md)` ⚠️
- Line 154: `[Notifications](./notifications.md)` ⚠️

---

### configurations-old/

#### configurations-old/configuration.md {#configurations-old-configuration}

**Internal Links** (36):

- Line 3: `[configuration guide](../guides/configuration.md)` ⚠️
- Line 5: `[model configuration reference page](./model_configuration.md)` ⚠️
- Line 11: `[`gateways`](#gateways)`
- Line 11: `[gateway/connection defaults](#gatewayconnection-defaults)`
- Line 28: `[physical layer](../concepts/glossary.md#physical-layer)` ⚠️
- Line 34: `[will be placed](../guides/configuration.md#physical-table-schemas)` ⚠️
- Line 35: `[additional details](../guides/configuration.md#physical-table-naming-convention)` ⚠️
- Line 39: `[virtual layer](../concepts/glossary.md#virtual-layer)` ⚠️
- Line 46: `[additional details](../guides/configuration.md#disable-environment-specific-schemas)` ⚠️
- Line 57: `[properties](./model_configuration.md#model-defaults)` ⚠️
- Line 61: `[model configuration reference page](./model_configuration.md#model-defaults)` ⚠️
- Line 65: `[`@VAR` macro function](../concepts/macros/vulcan_macros.md#global-variables)` ⚠️
- Line 65: `[`context.var` method](../concepts/models/python_models.md#user-defined-variables)` ⚠️
- Line 65: `[`evaluator.var` method](../concepts/macros/vulcan_macros.md#accessing-global-variable-values)` ⚠️
- Line 67: `[Vulcan macros concepts page](../concepts/macros/vulcan_macros.md#global-variables)` ⚠️
- Line 77: `[the configuration guide](../guides/configuration.md#before_all-and-after_all-statements)` ⚠️
- Line 90: `[categorize](../concepts/plans.md#change-categories)` ⚠️
- Line 90: `[additional details](../guides/configuration.md#auto-categorize-model-changes)` ⚠️
- Line 93: `[forward-only](../concepts/plans.md#forward-only-plans)` ⚠️
- Line 94: `[data preview](../concepts/plans.md#data-preview-for-forward-only-changes)` ⚠️
- Line 101: `[builtin](#builtin)`
- Line 138: `[gateway defaults](#gatewayconnection-defaults)`
- Line 158: `[gateways section](../guides/configuration.md#gateways)` ⚠️
- Line 170: `[`default_connection`](#default-connectionsscheduler)`
- Line 178: `[connection configuration](#connection)`
- Line 178: `[`default_connection`](#default-connectionsscheduler)`
- Line 179: `[connection configuration](#connection)`
- Line 181: `[connection configuration](#connection)`
- Line 182: `[scheduler configuration](#scheduler)`
- Line 183: `[variables](#variables)`
- Line 189: `[below](#engine-specific)`
- Line 205: `[Postgres](./integrations/engines/postgres.md)`
- Line 206: `[Snowflake](./integrations/engines/snowflake.md)`
- Line 210: `[plans](../concepts/plans.md)` ⚠️
- Line 214: `[configuration overview scheduler section](../guides/configuration.md#scheduler)` ⚠️
- Line 224: `[gateway/connection defaults section](../guides/configuration.md#gatewayconnection-defaults)` ⚠️

**External Links** (3):

- Line 32: `[relative dates](https://dateparser.readthedocs.io/en/latest/)`
- Line 43: `[relative dates](https://dateparser.readthedocs.io/en/latest/)`
- Line 55: `[python format codes](https://docs.python.org/3/library/datetime.html#strftime-and-strptime-format-codes)`

---

### configurations-old/integrations/engines/

#### configurations-old/integrations/engines/athena.md {#configurations-old-integrations-engines-athena}

**Internal Links** (7):

- Line 35: `[S3 Locations](#s3-locations)`
- Line 39: `[properties](../../concepts/models/overview.md#model-properties)` ⚠️
- Line 46: `[physical_properties](../../concepts/models/overview.md#physical_properties)` ⚠️
- Line 67: `[forward only changes](../../concepts/plans.md#forward-only-change)` ⚠️
- Line 69: `[`INCREMENTAL_BY_UNIQUE_KEY`](../../concepts/models/model_kinds.md#incremental_by_unique_key)` ⚠️
- Line 69: `[`SCD_TYPE_2`](../../concepts/models/model_kinds.md#scd-type-2)` ⚠️
- Line 71: `[properties](../../concepts/models/overview.md#model-properties)` ⚠️

**External Links** (8):

- Line 13: `[PyAthena](https://github.com/laughingman7743/PyAthena)`
- Line 14: `[boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)`
- Line 14: `[boto3 environment variables](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html#using-environment-variables)`
- Line 24: `[workgroup](https://docs.aws.amazon.com/athena/latest/ug/workgroups-manage-queries-control-costs.html)`
- Line 43: `[table_type](https://docs.aws.amazon.com/athena/latest/ug/create-table-as.html#ctas-table-properties)`
- Line 44: `[STORED AS](https://docs.aws.amazon.com/athena/latest/ug/create-table.html#parameters)`
- Line 44: `[format](https://docs.aws.amazon.com/athena/latest/ug/create-table-as.html#ctas-table-properties)`
- Line 69: `[Apache Iceberg](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg.html)`

---

#### configurations-old/integrations/engines/azuresql.md {#configurations-old-integrations-engines-azuresql}

**External Links** (2):

- Line 3: `[Azure SQL](https://azure.microsoft.com/en-us/products/azure-sql)`
- Line 36: `[here](https://learn.microsoft.com/en-us/sql/connect/odbc/dsn-connection-string-attribute?view=sql-server-ver16)`

---

#### configurations-old/integrations/engines/bigquery.md {#configurations-old-integrations-engines-bigquery}

**Internal Links** (17):

- Line 7: `[quickstart project](../../getting_started/docker.md)` ⚠️
- Line 20: `[quickstart guide](../../getting_started/docker.md)` ⚠️
- Line 72: `[`oauth` authentication method](#authentication-methods)`
- Line 72: `[described below](#authentication-methods)`
- Line 76: `[BigQuery Dashboard](./bigquery/bigquery-1.png)`
- Line 76: `[BigQuery Dashboard](./bigquery/bigquery-1.png)`
- Line 80: `[BigQuery Dashboard: selecting your project](./bigquery/bigquery-2.png)`
- Line 80: `[BigQuery Dashboard: selecting your project](./bigquery/bigquery-2.png)`
- Line 96: `[Terminal Output](./bigquery/bigquery-3.png)`
- Line 96: `[Terminal Output](./bigquery/bigquery-3.png)`
- Line 102: `[Terminal Output with warnings](./bigquery/bigquery-4.png)`
- Line 102: `[Terminal Output with warnings](./bigquery/bigquery-4.png)`
- Line 126: `[Steps to the Studio](./bigquery/bigquery-5.png)`
- Line 126: `[Steps to the Studio](./bigquery/bigquery-5.png)`
- Line 130: `[New Models](./bigquery/bigquery-6.png)`
- Line 130: `[New Models](./bigquery/bigquery-6.png)`
- Line 148: `[allowed values below](#authentication-methods)`

**External Links** (14):

- Line 14: `[CLI/API access is enabled](https://cloud.google.com/endpoints/docs/openapi/enable-api)`
- Line 15: `[billing is configured](https://cloud.google.com/billing/docs/how-to/manage-billing-account)`
- Line 30: `[`google-cloud-bigquery` library](https://pypi.org/project/google-cloud-bigquery/)`
- Line 30: `[Google Cloud SDK `gcloud` tool](https://cloud.google.com/sdk/docs)`
- Line 30: `[authenticating with BigQuery](https://googleapis.dev/python/google-api-core/latest/auth.html)`
- Line 34: `[Google Cloud installation guide](https://cloud.google.com/sdk/docs/install)`
- Line 53: `[`gcloud init` to setup authentication](https://cloud.google.com/sdk/gcloud/reference/init)`
- Line 169: `[oauth](https://google-auth.readthedocs.io/en/master/reference/google.auth.html#google.auth.default)`
- Line 172: `[oauth-secrets](https://google-auth.readthedocs.io/en/stable/reference/google.oauth2.credentials.html)`
- Line 180: `[service-account](https://google-auth.readthedocs.io/en/master/reference/google.oauth2.service_account.html#google.oauth2.service_account.IDTokenCredentials.from_service_account_file)`
- Line 184: `[service-account-json](https://google-auth.readthedocs.io/en/master/reference/google.oauth2.service_account.html#google.oauth2.service_account.IDTokenCredentials.from_service_account_info)`
- Line 194: `[sufficient permissions to impersonate the service account](https://cloud.google.com/docs/authentication/use-service-account-impersonation)`
- Line 199: `[`BigQuery Data Owner`](https://cloud.google.com/bigquery/docs/access-control#bigquery.dataOwner)`
- Line 200: `[`BigQuery User`](https://cloud.google.com/bigquery/docs/access-control#bigquery.user)`

**Images** (6):

- Line 76: `![BigQuery Dashboard](./bigquery/bigquery-1.png)`
- Line 80: `![BigQuery Dashboard: selecting your project](./bigquery/bigquery-2.png)`
- Line 96: `![Terminal Output](./bigquery/bigquery-3.png)`
- Line 102: `![Terminal Output with warnings](./bigquery/bigquery-4.png)`
- Line 126: `![Steps to the Studio](./bigquery/bigquery-5.png)`
- Line 130: `![New Models](./bigquery/bigquery-6.png)`

---

#### configurations-old/integrations/engines/clickhouse.md {#configurations-old-integrations-engines-clickhouse}

**Internal Links** (17):

- Line 6: `[state connection](../../reference/configuration.md#connections)` ⚠️
- Line 52: `[below](#cluster-specification)`
- Line 70: `[`environment_suffix_target` key in your project configuration](../../guides/configuration.md#disable-environment-specific-schemas)` ⚠️
- Line 78: `[`physical_schema_mapping` key in your project configuration](../../guides/configuration.md#physical-table-schemas)` ⚠️
- Line 97: `[below](#localbuilt-in-scheduler)`
- Line 228: `[partitioned tables to improve performance](#performance-considerations)`
- Line 260: `[`order_by`](#order-by)`
- Line 260: `[`primary_key`](#primary-key)`
- Line 341: `[`FULL` models](../../concepts/models/model_kinds.md#full)` ⚠️
- Line 342: `[`INCREMENTAL_BY_TIME_RANGE` models](../../concepts/models/model_kinds.md#incremental_by_time_range)` ⚠️
- Line 343: `[`INCREMENTAL_BY_UNIQUE_KEY` models](../../concepts/models/model_kinds.md#incremental_by_unique_key)` ⚠️
- Line 344: `[`INCREMENTAL_BY_PARTITION` models](../../concepts/models/model_kinds.md#incremental_by_partition)` ⚠️
- Line 358: `[for partitioned tables](#partition-swap)`
- Line 370: `[ClickHouse table swap steps](./clickhouse/clickhouse_table-swap-steps.png)`
- Line 370: `[ClickHouse table swap steps](./clickhouse/clickhouse_table-swap-steps.png)`
- Line 390: `[`partitioned_by`](../../concepts/models/overview.md#partitioned_by)` ⚠️
- Line 414: `[`ORDER_BY` expression](#order-by)`

**External Links** (14):

- Line 10: `[ClickHouse](https://clickhouse.com/)`
- Line 26: `["table engine" that controls how the table's data is stored and queried](https://clickhouse.com/docs/en/engines/table-engines)`
- Line 28: `[`MergeTree` engine family](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/mergetree)`
- Line 44: `[ClickHouse Keeper](https://clickhouse.com/docs/en/architecture/horizontal-scaling)`
- Line 44: `[Apache ZooKeeper](https://zookeeper.apache.org/)`
- Line 56: `[ClickHouse Cloud](https://clickhouse.com/cloud)`
- Line 58: `[occur in two steps on ClickHouse Cloud](https://clickhouse.com/docs/en/sql-reference/statements/create/table#from-select-query)`
- Line 188: `[TTL expression that triggers actions](https://clickhouse.com/docs/en/guides/developer/ttl)`
- Line 232: `[immense number of settings](https://clickhouse.com/docs/en/operations/settings)`
- Line 238: `[`clickhouse-connect` library](https://clickhouse.com/docs/en/integrations/python)`
- Line 260: `[`physical_properties` key](https://vulcan.readthedocs.io/en/stable/concepts/models/overview/?h=physical#physical_properties)`
- Line 400: `[specifically warns against tables having too many partitions](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/custom-partitioning-key)`
- Line 448: `[connection settings](https://clickhouse.com/docs/integrations/python#settings-argument)`
- Line 449: `[options](https://clickhouse.com/docs/integrations/python#customizing-the-http-connection-pool)`

**Images** (1):

- Line 370: `![ClickHouse table swap steps](./clickhouse/clickhouse_table-swap-steps.png)`

---

#### configurations-old/integrations/engines/databricks.md {#configurations-old-integrations-engines-databricks}

**Internal Links** (56):

- Line 5: `[Connection Quickstart](#connection-quickstart)`
- Line 5: `[built-in](#localbuilt-in-scheduler)`
- Line 19: `[Databricks Connect](#databricks-connect)`
- Line 27: `[more configuration details below](#databricks-connect)`
- Line 33: `[more configuration details below](#databricks-notebook-interface)`
- Line 44: `[Vulcan Quickstart](../../getting_started/docker.md)` ⚠️
- Line 70: `[next section](#get-jdbcodbc-info)`
- Line 74: `[Databricks Workspace default view](./databricks/db-guide_workspace.png)`
- Line 74: `[Databricks Workspace default view](./databricks/db-guide_workspace.png)`
- Line 78: `[Databricks Compute default view](./databricks/db-guide_compute.png)`
- Line 78: `[Databricks Compute default view](./databricks/db-guide_compute.png)`
- Line 82: `[Databricks Create Compute view](./databricks/db-guide_compute-create.png)`
- Line 82: `[Databricks Create Compute view](./databricks/db-guide_compute-create.png)`
- Line 88: `[Databricks Compute Advanced Options link](./databricks/db-guide_compute-advanced-options-link.png)`
- Line 88: `[Databricks Compute Advanced Options link](./databricks/db-guide_compute-advanced-options-link.png)`
- Line 92: `[Databricks Compute Advanced Options JDBC/ODBC tab](./databricks/db-guide_advanced-options.png)`
- Line 92: `[Databricks Compute Advanced Options JDBC/ODBC tab](./databricks/db-guide_advanced-options.png)`
- Line 96: `[Project config.yaml databricks gateway](./databricks/db-guide_config-yaml.png)`
- Line 96: `[Project config.yaml databricks gateway](./databricks/db-guide_config-yaml.png)`
- Line 100: `[Copy server_hostname and http_path to config.yaml](./databricks/db-guide_copy-server-http.png)`
- Line 100: `[Copy server_hostname and http_path to config.yaml](./databricks/db-guide_copy-server-http.png)`
- Line 109: `[environment variables that the configuration file loads dynamically](../../guides/configuration.md#environment-variables)` ⚠️
- Line 124: `[Navigate to profile Settings page](./databricks/db-guide_profile-settings-link.png)`
- Line 124: `[Navigate to profile Settings page](./databricks/db-guide_profile-settings-link.png)`
- Line 128: `[Navigate to User Developer view](./databricks/db-guide_profile-settings-developer.png)`
- Line 128: `[Navigate to User Developer view](./databricks/db-guide_profile-settings-developer.png)`
- Line 132: `[Navigate to Access Tokens management](./databricks/db-guide_access-tokens-link.png)`
- Line 132: `[Navigate to Access Tokens management](./databricks/db-guide_access-tokens-link.png)`
- Line 136: `[Open the token generation menu](./databricks/db-guide_access-tokens-generate-button.png)`
- Line 136: `[Open the token generation menu](./databricks/db-guide_access-tokens-generate-button.png)`
- Line 140: `[Generate a new token](./databricks/db-guide_access-tokens-generate.png)`
- Line 140: `[Generate a new token](./databricks/db-guide_access-tokens-generate.png)`
- Line 144: `[Copy token to config.yaml access_token key](./databricks/db-guide_copy-token.png)`
- Line 144: `[Copy token to config.yaml access_token key](./databricks/db-guide_copy-token.png)`
- Line 149: `[environment variables that the configuration file loads dynamically](../../guides/configuration.md#environment-variables)` ⚠️
- Line 169: `[Run vulcan info command in CLI](./databricks/db-guide_sqlmesh-info.png)`
- Line 169: `[Run vulcan info command in CLI](./databricks/db-guide_sqlmesh-info.png)`
- Line 173: `[Successful data warehouse connection](./databricks/db-guide_sqlmesh-info-succeeded.png)`
- Line 173: `[Successful data warehouse connection](./databricks/db-guide_sqlmesh-info-succeeded.png)`
- Line 177: `[Databricks state connection warning](./databricks/db-guide_sqlmesh-info-warning.png)`
- Line 177: `[Databricks state connection warning](./databricks/db-guide_sqlmesh-info-warning.png)`
- Line 182: `[here](../../guides/configuration.md#state-connection)` ⚠️
- Line 190: `[Specify DuckDB state connection](./databricks/db-guide_state-connection.png)`
- Line 190: `[Specify DuckDB state connection](./databricks/db-guide_state-connection.png)`
- Line 194: `[No state connection warning](./databricks/db-guide_sqlmesh-info-no-warning.png)`
- Line 194: `[No state connection warning](./databricks/db-guide_sqlmesh-info-no-warning.png)`
- Line 200: `[Specify databricks as default gateway](./databricks/db-guide_default-gateway.png)`
- Line 200: `[Specify databricks as default gateway](./databricks/db-guide_default-gateway.png)`
- Line 204: `[Run vulcan plan in databricks](./databricks/db-guide_sqlmesh-plan.png)`
- Line 204: `[Run vulcan plan in databricks](./databricks/db-guide_sqlmesh-plan.png)`
- Line 208: `[Vulcan plan objects in databricks](./databricks/db-guide_sqlmesh-plan-objects.png)`
- Line 208: `[Vulcan plan objects in databricks](./databricks/db-guide_sqlmesh-plan-objects.png)`
- Line 213: `[`catalog` parameter](#connection-options)`
- Line 225: `[section above](#databricks-connection-methods)`
- Line 229: `[more above](#databricks-sql-connector)`
- Line 276: `[forward only](../../guides/incremental_time.md#forward-only-models)` ⚠️

**External Links** (18):

- Line 13: `[Databricks SQL Connector](https://docs.databricks.com/dev-tools/python-sql-connector.html)`
- Line 23: `[Databricks Connect](https://docs.databricks.com/dev-tools/databricks-connect.html)`
- Line 25: `[install the version of Databricks Connect](https://docs.databricks.com/en/dev-tools/databricks-connect/python/install.html)`
- Line 39: `[All-Purpose Compute](https://docs.databricks.com/en/compute/index.html)`
- Line 51: `[personal access tokens](https://docs.databricks.com/en/dev-tools/auth/pat.html)`
- Line 51: `[Community Edition workspaces do not](https://docs.databricks.com/en/admin/access-control/tokens.html)`
- Line 53: `[Unity Catalog](https://docs.databricks.com/aws/en/data-governance/unity-catalog/)`
- Line 62: `[Unity Catalog](https://docs.databricks.com/aws/en/data-governance/unity-catalog/)`
- Line 229: `[Databricks SQL Connector](https://docs.databricks.com/dev-tools/python-sql-connector.html)`
- Line 233: `[Databricks Connect](https://docs.databricks.com/dev-tools/databricks-connect.html)`
- Line 235: `[install the version of Databricks Connect](https://docs.databricks.com/en/dev-tools/databricks-connect/python/install.html)`
- Line 241: `[Databricks SQL Warehouse](https://docs.databricks.com/sql/admin/create-sql-warehouse.html)`
- Line 244: `[requirements](https://docs.databricks.com/dev-tools/databricks-connect.html#requirements)`
- Line 244: `[limitations](https://docs.databricks.com/dev-tools/databricks-connect.html#limitations)`
- Line 260: `[Defaults to use Databricks cluster default](https://docs.databricks.com/en/data-governance/unity-catalog/create-catalogs.html#the-default-catalog-configuration-when-unity-catalog-is-enabled)`
- Line 262: `[M2M](https://docs.databricks.com/en/dev-tools/python-sql-connector.html#oauth-machine-to-machine-m2m-authentication)`
- Line 263: `[M2M](https://docs.databricks.com/en/dev-tools/python-sql-connector.html#oauth-machine-to-machine-m2m-authentication)`
- Line 290: `[Databricks Documentation for more details](https://docs.databricks.com/en/delta/column-mapping.html#requirements)`

**Images** (21):

- Line 74: `![Databricks Workspace default view](./databricks/db-guide_workspace.png)`
- Line 78: `![Databricks Compute default view](./databricks/db-guide_compute.png)`
- Line 82: `![Databricks Create Compute view](./databricks/db-guide_compute-create.png)`
- Line 88: `![Databricks Compute Advanced Options link](./databricks/db-guide_compute-advanced-options-link.png)`
- Line 92: `![Databricks Compute Advanced Options JDBC/ODBC tab](./databricks/db-guide_advanced-options.png)`
- Line 96: `![Project config.yaml databricks gateway](./databricks/db-guide_config-yaml.png)`
- Line 100: `![Copy server_hostname and http_path to config.yaml](./databricks/db-guide_copy-server-http.png)`
- Line 124: `![Navigate to profile Settings page](./databricks/db-guide_profile-settings-link.png)`
- Line 128: `![Navigate to User Developer view](./databricks/db-guide_profile-settings-developer.png)`
- Line 132: `![Navigate to Access Tokens management](./databricks/db-guide_access-tokens-link.png)`
- Line 136: `![Open the token generation menu](./databricks/db-guide_access-tokens-generate-button.png)`
- Line 140: `![Generate a new token](./databricks/db-guide_access-tokens-generate.png)`
- Line 144: `![Copy token to config.yaml access_token key](./databricks/db-guide_copy-token.png)`
- Line 169: `![Run vulcan info command in CLI](./databricks/db-guide_sqlmesh-info.png)`
- Line 173: `![Successful data warehouse connection](./databricks/db-guide_sqlmesh-info-succeeded.png)`
- Line 177: `![Databricks state connection warning](./databricks/db-guide_sqlmesh-info-warning.png)`
- Line 190: `![Specify DuckDB state connection](./databricks/db-guide_state-connection.png)`
- Line 194: `![No state connection warning](./databricks/db-guide_sqlmesh-info-no-warning.png)`
- Line 200: `![Specify databricks as default gateway](./databricks/db-guide_default-gateway.png)`
- Line 204: `![Run vulcan plan in databricks](./databricks/db-guide_sqlmesh-plan.png)`
- Line 208: `![Vulcan plan objects in databricks](./databricks/db-guide_sqlmesh-plan-objects.png)`

---

#### configurations-old/integrations/engines/duckdb.md {#configurations-old-integrations-engines-duckdb}

**Internal Links** (3):

- Line 6: `[Postgres](./postgres.md)`
- Line 17: `[attach DuckDB catalogs](#duckdb-catalogs-example)`
- Line 17: `[catalogs for other connections](#other-connection-catalogs-example)`

**External Links** (12):

- Line 4: `[single user](https://duckdb.org/docs/connect/concurrency.html#writing-to-duckdb-from-multiple-processes)`
- Line 6: `[Tobiko Cloud](https://tobikodata.com/product.html)`
- Line 119: `[DuckDB can be attached to](https://duckdb.org/docs/sql/statements/attach.html)`
- Line 189: `[See DuckDB Documentation for more information](https://duckdb.org/docs/extensions/postgres#configuring-via-environment-variables)`
- Line 193: `[httpfs](https://duckdb.org/docs/extensions/httpfs/s3api)`
- Line 193: `[azure](https://duckdb.org/docs/extensions/azure)`
- Line 195: `[Secrets Manager](https://duckdb.org/docs/configuration/secrets_manager.html)`
- Line 195: `[legacy authentication method](https://duckdb.org/docs/stable/extensions/httpfs/s3api_legacy_authentication.html)`
- Line 336: `[supported S3 secret parameters](https://duckdb.org/docs/stable/extensions/httpfs/s3api.html#overview-of-s3-secret-parameters)`
- Line 336: `[Secrets Manager configuration](https://duckdb.org/docs/configuration/secrets_manager.html)`
- Line 370: `[fsspec.filesystem](https://filesystem-spec.readthedocs.io/en/latest/api.html#fsspec.filesystem)`
- Line 370: `[adlfs.AzureBlobFileSystem](https://fsspec.github.io/adlfs/api/#api-reference)`

---

#### configurations-old/integrations/engines/fabric.md {#configurations-old-integrations-engines-fabric}

**Internal Links** (1):

- Line 9: `[state connection](../../reference/configuration.md#connections)` ⚠️

**External Links** (1):

- Line 37: `[here](https://learn.microsoft.com/en-us/sql/connect/odbc/dsn-connection-string-attribute?view=sql-server-ver16)`

---

#### configurations-old/integrations/engines/motherduck.md {#configurations-old-integrations-engines-motherduck}

**Internal Links** (8):

- Line 5: `[Connection Quickstart](#connection-quickstart)`
- Line 18: `[Vulcan Quickstart](../../getting_started/docker.md)` ⚠️
- Line 54: `[DuckDB can be attached to](./duckdb.md#other-connection-catalogs-example)`
- Line 57: `[environment variables that the configuration file loads dynamically](../../guides/configuration.md#environment-variables)` ⚠️
- Line 75: `[](./motherduck/sqlmesh_info.png)`
- Line 79: `[](./motherduck/info_output.png)`
- Line 85: `[](./motherduck/sqlmesh_plan.png)`
- Line 89: `[](./motherduck/motherduck_ui.png)`

**Images** (4):

- Line 75: `![](./motherduck/sqlmesh_info.png)`
- Line 79: `![](./motherduck/info_output.png)`
- Line 85: `![](./motherduck/sqlmesh_plan.png)`
- Line 89: `![](./motherduck/motherduck_ui.png)`

---

#### configurations-old/integrations/engines/mssql.md {#configurations-old-integrations-engines-mssql}

**Internal Links** (2):

- Line 16: `[incremental by unique key](../../concepts/models/model_kinds.md#incremental_by_unique_key)` ⚠️
- Line 22: `[`physical_properties`](../../concepts/models/overview.md#physical_properties)` ⚠️

**External Links** (2):

- Line 42: `[MSSQL `EXCEPT` statement documentation](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/set-operators-except-and-intersect-transact-sql?view=sql-server-ver17#arguments)`
- Line 65: `[here](https://learn.microsoft.com/en-us/sql/connect/odbc/dsn-connection-string-attribute?view=sql-server-ver16)`

---

#### configurations-old/integrations/engines/redshift.md {#configurations-old-integrations-engines-redshift}

**External Links** (1):

- Line 24: `[TCP keepalive](https://en.wikipedia.org/wiki/Keepalive#TCP_keepalive)`

---

#### configurations-old/integrations/engines/risingwave.md {#configurations-old-integrations-engines-risingwave}

**Internal Links** (3):

- Line 20: `[Postgres](./postgres.md)`
- Line 41: `[pre / post statements](../../concepts/models/sql_models.md#optional-prepost-statements)` ⚠️
- Line 74: `[here](../../concepts/macros/macro_variables.md#runtime-variables)` ⚠️

**External Links** (3):

- Line 3: `[RisingWave](https://risingwave.com/)`
- Line 38: `[Sources](https://docs.risingwave.com/sql/commands/sql-create-source)`
- Line 39: `[Sinks](https://docs.risingwave.com/sql/commands/sql-create-sink)`

---

#### configurations-old/integrations/engines/snowflake.md {#configurations-old-integrations-engines-snowflake}

**Internal Links** (23):

- Line 5: `[Connection Quickstart](#connection-quickstart)`
- Line 5: `[built-in](#localbuilt-in-scheduler)`
- Line 13: `[described below](#snowflake-authorization-methods)`
- Line 18: `[Vulcan Quickstart](../../getting_started/docker.md)` ⚠️
- Line 117: `[Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)`
- Line 117: `[Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)`
- Line 177: `[environment variables that the configuration file loads dynamically](../../guides/configuration.md#environment-variables)` ⚠️
- Line 195: `[Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)`
- Line 195: `[Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)`
- Line 199: `[Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)`
- Line 199: `[Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)`
- Line 203: `[Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)`
- Line 203: `[Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)`
- Line 208: `[here](../../guides/configuration.md#state-connection)` ⚠️
- Line 239: `[No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)`
- Line 239: `[No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)`
- Line 245: `[Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)`
- Line 245: `[Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)`
- Line 249: `[Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)`
- Line 249: `[Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)`
- Line 482: `[Private Key Base64](#private-key-base64)`
- Line 594: `[model defaults](../../guides/configuration.md#model-defaults)` ⚠️
- Line 615: `[external table](../../concepts/models/external_models.md)` ⚠️

**External Links** (9):

- Line 25: `[warehouse](https://docs.snowflake.com/en/user-guide/warehouses-overview)`
- Line 259: `[on Github](https://github.com/snowflakedb/snowflake-connector-python/issues/645)`
- Line 573: `[External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume)`
- Line 591: `[Configuring a default Catalog](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration#set-a-default-catalog-at-the-account-database-or-schema-level)`
- Line 592: `[Configuring a default External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume#set-a-default-external-volume-at-the-account-database-or-schema-level)`
- Line 596: `[optional properties](https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-snowflake#optional-parameters)`
- Line 613: `[does not support](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-options)`
- Line 625: `[Connection Caching Documentation](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-use#using-connection-caching-to-minimize-the-number-of-prompts-for-authentication-optional)`
- Line 626: `[MFA Token Caching Documentation](https://docs.snowflake.com/en/user-guide/security-mfa#using-mfa-token-caching-to-minimize-the-number-of-prompts-during-authentication-optional)`

**Images** (7):

- Line 117: `![Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)`
- Line 195: `![Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)`
- Line 199: `![Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)`
- Line 203: `![Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)`
- Line 239: `![No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)`
- Line 245: `![Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)`
- Line 249: `![Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)`

---

#### configurations-old/integrations/engines/spark.md {#configurations-old-integrations-engines-spark}

**Internal Links** (2):

- Line 6: `[state connection](../../reference/configuration.md#connections)` ⚠️
- Line 14: `[Catalog Support](#catalog-support)`

---

#### configurations-old/integrations/engines/trino.md {#configurations-old-integrations-engines-trino}

**Internal Links** (5):

- Line 6: `[state connection](../../reference/configuration.md#connections)` ⚠️
- Line 97: `[Table and Schema locations](#table-and-schema-locations)`
- Line 98: `[Catalog Type Overrides](#catalog-type-overrides)`
- Line 185: `[here](../../concepts/macros/vulcan_macros.md#embedding-variables-in-strings)` ⚠️
- Line 193: `[@resolve_template](../../concepts/macros/vulcan_macros.md#resolve_template)` ⚠️

**External Links** (23):

- Line 20: `[Hive Connector](https://trino.io/docs/current/connector/hive.html)`
- Line 20: `[Iceberg Connector](https://trino.io/docs/current/connector/iceberg.html)`
- Line 20: `[Delta Lake Connector](https://trino.io/docs/current/connector/delta-lake.html)`
- Line 22: `[Slack](https://tobikodata.com/slack)`
- Line 41: `[properties](https://trino.io/docs/current/connector/metastores.html#general-metastore-configuration-properties)`
- Line 54: `[Nessie documentation](https://projectnessie.org/nessie-latest/trino/)`
- Line 60: `[properties file](https://trino.io/docs/current/connector/delta-lake.html#general-configuration)`
- Line 60: `[general properties](https://trino.io/docs/current/object-storage/metastores.html#general-metastore-properties)`
- Line 69: `[AWS Glue](https://aws.amazon.com/glue/)`
- Line 71: `[AWS S3](https://aws.amazon.com/s3/)`
- Line 73: `[`hive.metastore.glue.default-warehouse-dir` parameter](https://trino.io/docs/current/object-storage/metastores.html#aws-glue-catalog-configuration-properties)`
- Line 108: `[Metastore](https://trino.io/docs/current/object-storage/metastores.html)`
- Line 253: `[trinodb Python client](https://github.com/trinodb/trino-python-client)`
- Line 267: `[Trino Documentation on Basic Authentication](https://trino.io/docs/current/security/password-file.html)`
- Line 268: `[Python Client Basic Authentication](https://github.com/trinodb/trino-python-client#basic-authentication)`
- Line 289: `[Trino Documentation on LDAP Authentication](https://trino.io/docs/current/security/ldap.html)`
- Line 290: `[Python Client LDAP Authentication](https://github.com/trinodb/trino-python-client#basic-authentication)`
- Line 320: `[Trino Documentation on Kerberos Authentication](https://trino.io/docs/current/security/kerberos.html)`
- Line 321: `[Python Client Kerberos Authentication](https://github.com/trinodb/trino-python-client#kerberos-authentication)`
- Line 341: `[Trino Documentation on JWT Authentication](https://trino.io/docs/current/security/jwt.html)`
- Line 342: `[Python Client JWT Authentication](https://github.com/trinodb/trino-python-client#jwt-authentication)`
- Line 383: `[Trino Documentation on Oauth Authentication](https://trino.io/docs/current/security/oauth2.html)`
- Line 384: `[Python Client Oauth Authentication](https://github.com/trinodb/trino-python-client#oauth2-authentication)`

---

### configurations/engines/snowflake/

#### configurations/engines/snowflake/snowflake.md {#configurations-engines-snowflake-snowflake}

**Internal Links** (23):

- Line 5: `[Connection Quickstart](#connection-quickstart)`
- Line 5: `[built-in](#localbuilt-in-scheduler)`
- Line 13: `[described below](#snowflake-authorization-methods)`
- Line 18: `[Vulcan Quickstart](../../getting_started/docker.md)` ⚠️
- Line 117: `[Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)` ⚠️
- Line 117: `[Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)` ⚠️
- Line 177: `[environment variables that the configuration file loads dynamically](../../guides/configuration.md#environment-variables)` ⚠️
- Line 195: `[Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)` ⚠️
- Line 195: `[Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)` ⚠️
- Line 199: `[Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)` ⚠️
- Line 199: `[Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)` ⚠️
- Line 203: `[Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)` ⚠️
- Line 203: `[Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)` ⚠️
- Line 208: `[here](../../guides/configuration.md#state-connection)` ⚠️
- Line 239: `[No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)` ⚠️
- Line 239: `[No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)` ⚠️
- Line 245: `[Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)` ⚠️
- Line 245: `[Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)` ⚠️
- Line 249: `[Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)` ⚠️
- Line 249: `[Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)` ⚠️
- Line 482: `[Private Key Base64](#private-key-base64)`
- Line 594: `[model defaults](../../guides/configuration.md#model-defaults)` ⚠️
- Line 615: `[external table](../../concepts/models/external_models.md)` ⚠️

**External Links** (9):

- Line 25: `[warehouse](https://docs.snowflake.com/en/user-guide/warehouses-overview)`
- Line 259: `[on Github](https://github.com/snowflakedb/snowflake-connector-python/issues/645)`
- Line 573: `[External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume)`
- Line 591: `[Configuring a default Catalog](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration#set-a-default-catalog-at-the-account-database-or-schema-level)`
- Line 592: `[Configuring a default External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume#set-a-default-external-volume-at-the-account-database-or-schema-level)`
- Line 596: `[optional properties](https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-snowflake#optional-parameters)`
- Line 613: `[does not support](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-options)`
- Line 625: `[Connection Caching Documentation](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-use#using-connection-caching-to-minimize-the-number-of-prompts-for-authentication-optional)`
- Line 626: `[MFA Token Caching Documentation](https://docs.snowflake.com/en/user-guide/security-mfa#using-mfa-token-caching-to-minimize-the-number-of-prompts-during-authentication-optional)`

**Images** (7):

- Line 117: `![Snowflake account info in web URL](./snowflake/snowflake_db-guide_account-url.png)`
- Line 195: `![Run vulcan info command in CLI](./snowflake/snowflake_db-guide_sqlmesh-info.png)`
- Line 199: `![Successful data warehouse connection](./snowflake/snowflake_db-guide_sqlmesh-info-succeeded.png)`
- Line 203: `![Snowflake state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-warning.png)`
- Line 239: `![No state connection warning](./snowflake/snowflake_db-guide_sqlmesh-info-no-warning.png)`
- Line 245: `![Run vulcan plan in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan.png)`
- Line 249: `![Vulcan plan objects in snowflake](./snowflake/snowflake_db-guide_sqlmesh-plan-objects.png)`

---

### configurations/options/

#### configurations/options/linter.md {#configurations-options-linter}

**Internal Links** (2):

- Line 99: `[configuration file](#applying-linting-rules)`
- Line 130: `[configuration file](./configuration.md)` ⚠️

**External Links** (1):

- Line 17: `[full source code](https://github.com/TobikoData/vulcan/blob/main/vulcan/core/linter/rule.py)`

---

#### configurations/options/model_defaults.md {#configurations-options-model_defaults}

**Internal Links** (2):

- Line 5: `[models configuration reference page](model_configuration.md#model-defaults)` ⚠️
- Line 34: `[model concepts page](../concepts/models/model_kinds.md)` ⚠️

**External Links** (3):

- Line 3: `[supported by the SQLGlot library](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/dialect.py)`
- Line 42: `[respecting each dialect's resolution rules](https://sqlglot.com/sqlglot/dialects/dialect.html#Dialect.normalize_identifier)`
- Line 55: `[here](https://sqlglot.com/sqlglot/dialects/dialect.html#NormalizationStrategy)`

---

#### configurations/options/notifications.md {#configurations-options-notifications}

**Internal Links** (8):

- Line 9: `[event type](#vulcan-event-types)`
- Line 9: `[override is configured for development](#notifications-during-development)`
- Line 11: `[Audit](../concepts/audits.md)` ⚠️
- Line 21: `[Slack notification methods](#slack-notifications)`
- Line 21: `[email notification](#email-notifications)`
- Line 133: `[`plan` application](../concepts/plans.md)` ⚠️
- Line 133: `[`run`](../reference/cli.md#run)` ⚠️
- Line 133: `[`audit`](../concepts/audits.md)` ⚠️

**External Links** (4):

- Line 7: `[configuration](https://vulcan.readthedocs.io/en/stable/reference/configuration/)`
- Line 157: `[create an incoming webhook](https://api.slack.com/messaging/webhooks)`
- Line 186: `[Slack's official documentation](https://api.slack.com/tutorials/tracks/getting-a-token)`
- Line 259: `[here](https://github.com/TobikoData/vulcan/blob/main/vulcan/core/notification_target.py)`

---

### getting_started/

#### getting_started/cli.md {#getting_started-cli}

**Internal Links** (26):

- Line 7: `[prerequisites](./prerequisites.md)`
- Line 26: `[Docker Quickstart](./docker.md)` ⚠️
- Line 64: `[Docker Quickstart](./docker.md)` ⚠️
- Line 85: `[`vulcan init` command](../reference/cli.md#init)` ⚠️
- Line 95: `[below](#2-create-a-prod-environment)`
- Line 238: `[here](../reference/configuration.md)` ⚠️
- Line 248: `[here](../guides/configuration.md)` ⚠️
- Line 250: `[here](../concepts/models/overview.md)` ⚠️
- Line 252: `[here](../concepts/models/seed_models.md)` ⚠️
- Line 254: `[here](../concepts/audits.md)` ⚠️
- Line 256: `[here](../concepts/tests.md)` ⚠️
- Line 258: `[here](../concepts/macros/overview.md)` ⚠️
- Line 300: `[Vulcan environment](../concepts/environments.md)` ⚠️
- Line 304: `[Vulcan plan](../concepts/plans.md)` ⚠️
- Line 418: `[kinds](../concepts/models/model_kinds.md)` ⚠️
- Line 420: `[`SEED` models](../concepts/models/model_kinds.md#seed)` ⚠️
- Line 421: `[`FULL` models](../concepts/models/model_kinds.md#full)` ⚠️
- Line 422: `[`INCREMENTAL_BY_TIME_RANGE` models](../concepts/models/model_kinds.md#incremental_by_time_range)` ⚠️
- Line 472: `[`audits`](../concepts/audits.md)` ⚠️
- Line 530: `[Example project physical layer tables in the DuckDB CLI](./cli/cli-quickstart_duckdb-tables.png)`
- Line 530: `[Example project physical layer tables in the DuckDB CLI](./cli/cli-quickstart_duckdb-tables.png)`
- Line 534: `[Example project virtual layer views in the DuckDB CLI](./cli/cli-quickstart_duckdb-views.png)`
- Line 534: `[Example project virtual layer views in the DuckDB CLI](./cli/cli-quickstart_duckdb-views.png)`
- Line 758: `[Learn more about Vulcan CLI commands](../reference/cli.md)` ⚠️
- Line 759: `[Set up a connection to a database or SQL engine](../guides/connections.md)` ⚠️
- Line 760: `[Learn more about Vulcan concepts](../concepts/overview.md)` ⚠️

**External Links** (2):

- Line 5: `[DuckDB](https://duckdb.org/)`
- Line 761: `[Join our Slack community](https://tobikodata.com/slack)`

**Images** (2):

- Line 530: `![Example project physical layer tables in the DuckDB CLI](./cli/cli-quickstart_duckdb-tables.png)`
- Line 534: `![Example project virtual layer views in the DuckDB CLI](./cli/cli-quickstart_duckdb-views.png)`

---

#### getting_started/index.md {#getting_started-index}

**Internal Links** (2):

- Line 15: `[Start with Docker Quickstart](./docker.md)` ⚠️
- Line 19: `[prerequisites](./prerequisites.md)`

---

#### getting_started/prerequisites.md {#getting_started-prerequisites}

**External Links** (4):

- Line 13: `[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)`
- Line 14: `[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)`
- Line 15: `[official Docker installation guide](https://docs.docker.com/engine/install/)`
- Line 40: `[Docker Compose installation guide](https://docs.docker.com/compose/install/)`

---

### guides/

#### guides/data_quality.md {#guides-data_quality}

**Internal Links** (4):

- Line 580: `[Built-in Audits](../concepts/audits.md#built-in-audits)` ⚠️
- Line 581: `[Check Dimensions](../concepts/checks.md#data-quality-dimensions)` ⚠️
- Line 582: `[Testing](../concepts/tests.md)` ⚠️
- Line 583: `[Orders360 Example](../examples/overview.md)`

---

#### guides/incremental_by_time.md {#guides-incremental_by_time}

**Internal Links** (7):

- Line 5: `[models guide](./models.md)` ⚠️
- Line 5: `[model kinds page](../concepts/models/model_kinds.md)` ⚠️
- Line 1155: `[Model Kinds](../concepts/models/model_kinds.md)` ⚠️
- Line 1156: `[Models Guide](./models.md)`
- Line 1157: `[Plan Guide](./plan.md)`
- Line 1158: `[Run Guide](./run.md)` ⚠️
- Line 1159: `[Orders360 Example](../examples/overview.md)`

---

#### guides/model_selection.md {#guides-model_selection}

**Internal Links** (6):

- Line 5: `[`--allow-destructive-model` and `--allow-additive-model` selectors](../concepts/plans.md#destructive-changes)` ⚠️
- Line 11: `[plan](../concepts/plans.md)` ⚠️
- Line 623: `[Plans](../concepts/plans.md)` ⚠️
- Line 624: `[Plan Guide](./plan.md)`
- Line 625: `[Model Configuration](../reference/model_configuration.md)` ⚠️
- Line 626: `[Orders360 Example](../examples/overview.md)`

---

#### guides/models.md {#guides-models}

**Internal Links** (8):

- Line 9: `[Created your project](../getting_started/docker.md)` ⚠️
- Line 10: `[Applied your first plan](./plan.md#scenario-1-first-plan-initializing-production)`
- Line 11: `[dev environment](../concepts/environments.md)` ⚠️
- Line 677: `[Model Kinds](../concepts/models/model_kinds.md)` ⚠️
- Line 678: `[Model Properties](../concepts/models/properties.md)` ⚠️
- Line 679: `[Plan Guide](./plan.md)`
- Line 680: `[Testing Guide](./testing.md)` ⚠️
- Line 681: `[Orders360 Example](../examples/overview.md)`

---

#### guides/plan.md {#guides-plan}

**Internal Links** (7):

- Line 130: `[Examples Overview](../examples/overview.md)`
- Line 131: `[Docker Quickstart](../getting_started/docker.md)` ⚠️
- Line 930: `[Plans Concepts](../concepts/plans.md)` ⚠️
- Line 931: `[Environments](../concepts/environments.md)` ⚠️
- Line 932: `[Model Kinds](../concepts/models/model_kinds.md)` ⚠️
- Line 933: `[Run Guide](./run.md)` ⚠️
- Line 934: `[Notifications](./notifications.md)` ⚠️

---

#### guides/run_and_scheduling.md {#guides-run_and_scheduling}

**Internal Links** (7):

- Line 616: `[Connections Guide](./connections.md#state-connection)` ⚠️
- Line 627: `[notifications](./notifications.md)` ⚠️
- Line 645: `[Plan Guide](./plan.md)`
- Line 646: `[Run Command](../reference/cli.md#run)` ⚠️
- Line 647: `[Notifications](./notifications.md)` ⚠️
- Line 648: `[Environments](../concepts/environments.md)` ⚠️
- Line 649: `[Connections](./connections.md)` ⚠️

---

#### guides/transpiling_semantics.md {#guides-transpiling_semantics}

**Internal Links** (3):

- Line 491: `[Semantic Models](../concepts/semantics/models.md)` ⚠️
- Line 492: `[Business Metrics](../concepts/semantics/metrics.md)` ⚠️
- Line 493: `[Semantics Overview](../concepts/semantics/index.md)` ⚠️

---

### guides-old/

#### guides-old/configuration.md {#guides-old-configuration}

**Internal Links** (66):

- Line 7: `[configuration reference page](../reference/configuration.md)` ⚠️
- Line 14: `[`model_defaults` `dialect` key](#models)`
- Line 59: `[gateways section](#gateways)`
- Line 96: `[notifications guide](../guides/notifications.md)` ⚠️
- Line 123: `[overrides](#overrides)`
- Line 253: `[noted above](#configuration-files)`
- Line 281: `[Vulcan configuration reference page](../reference/configuration.md)` ⚠️
- Line 283: `[Project](../reference/configuration.md#projects)` ⚠️
- Line 284: `[Environment](../reference/configuration.md#environments-virtual-layer)` ⚠️
- Line 285: `[Gateways](../reference/configuration.md#gateways)` ⚠️
- Line 286: `[Gateway/connection defaults](../reference/configuration.md#gatewayconnection-defaults)` ⚠️
- Line 287: `[Model defaults](../reference/model_configuration.md)` ⚠️
- Line 288: `[Debug mode](../reference/configuration.md#debug-mode)` ⚠️
- Line 292: `[configuration reference page](../reference/configuration.md)` ⚠️
- Line 328: `[environments](../reference/configuration.md#environments-virtual-layer)` ⚠️
- Line 412: `[environment_suffix_target](../reference/configuration.md#environments-virtual-layer)` ⚠️
- Line 573: `[preview](../concepts/plans.md#data-preview-for-forward-only-changes)` ⚠️
- Line 577: `[Table Migration Guide](./table_migration.md)`
- Line 582: `[catalog](../concepts/glossary.md#catalog)` ⚠️
- Line 589: `[virtual layer](../concepts/glossary.md#virtual-layer)` ⚠️
- Line 589: `[physical layer](../concepts/glossary.md#physical-layer)` ⚠️
- Line 589: `[Isolated Systems Guide](../guides/isolated_systems.md)` ⚠️
- Line 632: `[MySQL](../integrations/engines/mysql.md)` ⚠️
- Line 633: `[Postgres](../integrations/engines/postgres.md)` ⚠️
- Line 634: `[GCP Postgres](../integrations/engines/gcp-postgres.md)` ⚠️
- Line 647: `[categorize](../concepts/plans.md#change-categories)` ⚠️
- Line 647: `[plan](../reference/configuration.md#plan)` ⚠️
- Line 651: `[breaking](../concepts/plans.md#breaking-change)` ⚠️
- Line 807: `[gateway](../reference/configuration.md#gateway)` ⚠️
- Line 830: `[engine-specific connection config](#engine-connection-configuration)`
- Line 830: `[scheduler config](#scheduler)`
- Line 854: `[gateway defaults below](#gatewayconnection-defaults)`
- Line 858: `[connection](../reference/configuration.md#connection)` ⚠️
- Line 863: `[below](#engine-connection-configuration)`
- Line 909: `[Athena](../integrations/engines/athena.md)` ⚠️
- Line 910: `[BigQuery](../integrations/engines/bigquery.md)` ⚠️
- Line 911: `[Databricks](../integrations/engines/databricks.md)` ⚠️
- Line 912: `[DuckDB](../integrations/engines/duckdb.md)` ⚠️
- Line 913: `[Fabric](../integrations/engines/fabric.md)` ⚠️
- Line 914: `[MotherDuck](../integrations/engines/motherduck.md)` ⚠️
- Line 915: `[MySQL](../integrations/engines/mysql.md)` ⚠️
- Line 916: `[MSSQL](../integrations/engines/mssql.md)` ⚠️
- Line 917: `[Postgres](../integrations/engines/postgres.md)` ⚠️
- Line 918: `[GCP Postgres](../integrations/engines/gcp-postgres.md)` ⚠️
- Line 919: `[Redshift](../integrations/engines/redshift.md)` ⚠️
- Line 920: `[Snowflake](../integrations/engines/snowflake.md)` ⚠️
- Line 921: `[Spark](../integrations/engines/spark.md)` ⚠️
- Line 922: `[Trino](../integrations/engines/trino.md)` ⚠️
- Line 939: `[Postgres](../integrations/engines/postgres.md)` ⚠️
- Line 940: `[GCP Postgres](../integrations/engines/gcp-postgres.md)` ⚠️
- Line 944: `[DuckDB](../integrations/engines/duckdb.md)` ⚠️
- Line 946: `[MySQL](../integrations/engines/mysql.md)` ⚠️
- Line 947: `[MSSQL](../integrations/engines/mssql.md)` ⚠️
- Line 951: `[ClickHouse](../integrations/engines/clickhouse.md)` ⚠️
- Line 952: `[Spark](../integrations/engines/spark.md)` ⚠️
- Line 953: `[Trino](../integrations/engines/trino.md)` ⚠️
- Line 1102: `[plans](../concepts/plans.md)` ⚠️
- Line 1104: `[scheduler](../reference/configuration.md#scheduler)` ⚠️
- Line 1146: `[gateway/connection defaults](../reference/configuration.md#gatewayconnection-defaults)` ⚠️
- Line 1148: `[accept a gateway option](../reference/cli.md#cli)` ⚠️
- Line 1242: `[models configuration reference page](../reference/model_configuration.md#model-defaults)` ⚠️
- Line 1269: `[model concepts page](../concepts/models/model_kinds.md)` ⚠️
- Line 1329: `[models configuration reference page](../reference/model_configuration.md#model-kind-properties)` ⚠️
- Line 1355: `[models configuration reference page](../reference/model_configuration.md#model-kind-properties)` ⚠️
- Line 1374: `[Python models concepts page](../concepts/models/python_models.md#model-specification)` ⚠️
- Line 1480: `[linting guide](./linter.md)` ⚠️

**External Links** (19):

- Line 84: `[API documentation](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config.html)`
- Line 88: `[Model defaults configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config/model.html)`
- Line 89: `[Gateway configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config/gateway.html)`
- Line 90: `[Connection configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config/connection.html)`
- Line 91: `[Scheduler configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config/scheduler.html)`
- Line 92: `[Plan change categorization configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/config/categorizer.html#CategorizerConfig)`
- Line 93: `[User configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/user.html#User)`
- Line 94: `[Notification configuration](https://vulcan.readthedocs.io/en/latest/_readthedocs/html/vulcan/core/notification_target.html)`
- Line 333: `[regex pattern](https://docs.python.org/3/library/re.html#regular-expression-syntax)`
- Line 466: `[silently truncate](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS)`
- Line 591: `[regex patterns](https://en.wikipedia.org/wiki/Regular_expression)`
- Line 637: `[regex101](https://regex101.com/)`
- Line 638: `[ChatGPT](https://chat.openai.com)`
- Line 935: `[Tobiko Cloud](https://tobikodata.com/product.html)`
- Line 945: `[single user](https://duckdb.org/docs/connect/concurrency.html#writing-to-duckdb-from-multiple-processes)`
- Line 1240: `[supported by the SQLGlot library](https://github.com/tobymao/sqlglot/blob/main/sqlglot/dialects/dialect.py)`
- Line 1277: `[respecting each dialect's resolution rules](https://sqlglot.com/sqlglot/dialects/dialect.html#Dialect.normalize_identifier)`
- Line 1290: `[here](https://sqlglot.com/sqlglot/dialects/dialect.html#NormalizationStrategy)`
- Line 1523: `[Tobiko Cloud](https://tobikodata.com/product.html)`

---

#### guides-old/connections.md {#guides-old-connections}

**Internal Links** (13):

- Line 52: `[tests](../concepts/tests.md)` ⚠️
- Line 82: `[BigQuery](../integrations/engines/bigquery.md)` ⚠️
- Line 83: `[Databricks](../integrations/engines/databricks.md)` ⚠️
- Line 84: `[DuckDB](../integrations/engines/duckdb.md)` ⚠️
- Line 85: `[MotherDuck](../integrations/engines/motherduck.md)` ⚠️
- Line 86: `[MySQL](../integrations/engines/mysql.md)` ⚠️
- Line 87: `[MSSQL](../integrations/engines/mssql.md)` ⚠️
- Line 88: `[Postgres](../integrations/engines/postgres.md)` ⚠️
- Line 89: `[GCP Postgres](../integrations/engines/gcp-postgres.md)` ⚠️
- Line 90: `[Redshift](../integrations/engines/redshift.md)` ⚠️
- Line 91: `[Snowflake](../integrations/engines/snowflake.md)` ⚠️
- Line 92: `[Spark](../integrations/engines/spark.md)` ⚠️
- Line 93: `[Trino](../integrations/engines/trino.md)` ⚠️

---

#### guides-old/customizing_vulcan.md {#guides-old-customizing_vulcan}

**Internal Links** (1):

- Line 23: `[Python configuration format](./configuration.md#python)`

---

#### guides-old/isolated_systems.md {#guides-old-isolated_systems}

**Internal Links** (9):

- Line 19: `[Vulcan environments](../concepts/environments.md)` ⚠️
- Line 27: `[separate database](./configuration.md#state-connection)`
- Line 33: `[gateways](./configuration.md#gateways)`
- Line 33: `[connections](./connections.md)`
- Line 63: `[`@gateway` macro variable](../concepts/macros/macro_variables.md#runtime-variables)` ⚠️
- Line 65: `[`@IF` macro operator](../concepts/macros/vulcan_macros.md#if)` ⚠️
- Line 81: `[here](../concepts/macros/vulcan_macros.md#embedding-variables-in-strings)` ⚠️
- Line 91: `[Vulcan project files link systems](./isolated_systems/isolated-systems_linkage.png)` ⚠️
- Line 91: `[Vulcan project files link systems](./isolated_systems/isolated-systems_linkage.png)` ⚠️

**External Links** (1):

- Line 144: `[blue-green deployment](https://en.m.wikipedia.org/wiki/Blue%E2%80%93green_deployment)`

**Images** (1):

- Line 91: `![Vulcan project files link systems](./isolated_systems/isolated-systems_linkage.png)`

---

#### guides-old/notifications.md {#guides-old-notifications}

**Internal Links** (8):

- Line 9: `[event type](#vulcan-event-types)`
- Line 9: `[override is configured for development](#notifications-during-development)`
- Line 11: `[Audit](../concepts/audits.md)` ⚠️
- Line 21: `[Slack notification methods](#slack-notifications)`
- Line 21: `[email notification](#email-notifications)`
- Line 133: `[`plan` application](../concepts/plans.md)` ⚠️
- Line 133: `[`run`](../reference/cli.md#run)` ⚠️
- Line 133: `[`audit`](../concepts/audits.md)` ⚠️

**External Links** (4):

- Line 7: `[configuration](https://vulcan.readthedocs.io/en/stable/reference/configuration/)`
- Line 157: `[create an incoming webhook](https://api.slack.com/messaging/webhooks)`
- Line 186: `[Slack's official documentation](https://api.slack.com/tutorials/tracks/getting-a-token)`
- Line 259: `[here](https://github.com/TobikoData/vulcan/blob/main/vulcan/core/notification_target.py)`

---

#### guides-old/projects.md {#guides-old-projects}

**Internal Links** (2):

- Line 7: `[prerequisites](../getting_started/prerequisites.md)`
- Line 69: `[CLI](../reference/cli.md)` ⚠️

**External Links** (1):

- Line 49: `[SQL dialect supported by sqlglot](https://sqlglot.com/sqlglot/dialects.html)`

---

#### guides-old/table_migration.md {#guides-old-table_migration}

**Internal Links** (4):

- Line 9: `[external models](../concepts/models/model_kinds.md#external)` ⚠️
- Line 42: `[`EXTERNAL` model](../concepts/models/model_kinds.md#external)` ⚠️
- Line 44: `[`VIEW` model](../concepts/models/model_kinds.md#view)` ⚠️
- Line 128: `[forward only](./incremental_time.md#forward-only-models)` ⚠️

**External Links** (1):

- Line 114: `[interval approach](https://vulcan.readthedocs.io/en/stable/guides/incremental_time/#counting-time)`

---

### guides/get-started/

#### guides/get-started/docker.md {#guides-get-started-docker}

**Internal Links** (15):

- Line 34: `[:material-download: Download for Mac/Linux](zip-mac/vulcan-project.zip)`
- Line 68: `[:material-download: Download for Windows](zip-window/vulcan-project.zip)`
- Line 106: `[*Click here*](../reference/cli.md#init)` ⚠️
- Line 114: `[*Click here*](../reference/cli.md#info)` ⚠️
- Line 121: `[*Click here*](../reference/cli.md#plan)` ⚠️
- Line 133: `[*Click here*](../reference/cli.md#fetchdf)` ⚠️
- Line 139: `[*Click here*](../reference/cli.md#transpile)` ⚠️
- Line 147: `[*Click here*](../reference/cli.md#init)` ⚠️
- Line 155: `[*Click here*](../reference/cli.md#info)` ⚠️
- Line 161: `[*Click here*](../reference/cli.md#plan)` ⚠️
- Line 173: `[*Click here*](../reference/cli.md#fetchdf)` ⚠️
- Line 179: `[*Click here*](../reference/cli.md#transpile)` ⚠️
- Line 251: `[Learn more about Vulcan CLI commands](../reference/cli.md)` ⚠️
- Line 252: `[Explore Vulcan concepts](../concepts/overview.md)` ⚠️
- Line 253: `[Set up connections to different warehouses](../guides/connections.md)` ⚠️

**External Links** (3):

- Line 16: `[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)`
- Line 18: `[Docker for Linux](https://docs.docker.com/engine/install/)`
- Line 28: `[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)`

---

## Link Index

Quick reference for finding specific links:

### C

- [comparisons.md](#comparisons) (23)
- [components/advanced-features/custom_materializations.md](#components-advanced-features-custom_materializations) (6)
- [components/advanced-features/macros/built_in.md](#components-advanced-features-macros-built_in) (69)
- [components/advanced-features/macros/jinja.md](#components-advanced-features-macros-jinja) (6)
- [components/advanced-features/macros/overview.md](#components-advanced-features-macros-overview) (5)
- [components/advanced-features/macros/variables.md](#components-advanced-features-macros-variables) (16)
- [components/advanced-features/signals.md](#components-advanced-features-signals) (2)
- [components/audits/audits.md](#components-audits-audits) (7)
- [components/checks/checks.md](#components-checks-checks) (1)
- [components/model/model_kinds.md](#components-model-model_kinds) (12)
- [components/model/overview.md](#components-model-overview) (3)
- [components/model/properties.md](#components-model-properties) (14)
- [components/model/statements.md](#components-model-statements) (1)
- [components/model/types/external_models.md](#components-model-types-external_models) (2)
- [components/model/types/managed_models.md](#components-model-types-managed_models) (11)
- [components/model/types/python_models.md](#components-model-types-python_models) (13)
- [components/model/types/sql_models.md](#components-model-types-sql_models) (12)
- [components/semantics/business_metrics.md](#components-semantics-business_metrics) (2)
- [components/semantics/models.md](#components-semantics-models) (2)
- [components/semantics/overview.md](#components-semantics-overview) (5)
- [components/tests/tests.md](#components-tests-tests) (3)
- [concepts-old/architecture/serialization.md](#concepts-old-architecture-serialization) (4)
- [concepts-old/architecture/snapshots.md](#concepts-old-architecture-snapshots) (1)
- [concepts-old/environments.md](#concepts-old-environments) (7)
- [concepts-old/glossary.md](#concepts-old-glossary) (11)
- [concepts-old/macros/jinja_macros.md](#concepts-old-macros-jinja_macros) (12)
- [concepts-old/macros/macro_variables.md](#concepts-old-macros-macro_variables) (18)
- [concepts-old/macros/overview.md](#concepts-old-macros-overview) (5)
- [concepts-old/macros/vulcan_macros.md](#concepts-old-macros-vulcan_macros) (69)
- [concepts-old/overview.md](#concepts-old-overview) (10)
- [concepts-old/plans.md](#concepts-old-plans) (50)
- [concepts-old/state.md](#concepts-old-state) (10)
- [configurations-old/configuration.md](#configurations-old-configuration) (39)
- [configurations-old/integrations/engines/athena.md](#configurations-old-integrations-engines-athena) (15)
- [configurations-old/integrations/engines/azuresql.md](#configurations-old-integrations-engines-azuresql) (2)
- [configurations-old/integrations/engines/bigquery.md](#configurations-old-integrations-engines-bigquery) (31)
- [configurations-old/integrations/engines/clickhouse.md](#configurations-old-integrations-engines-clickhouse) (31)
- [configurations-old/integrations/engines/databricks.md](#configurations-old-integrations-engines-databricks) (74)
- [configurations-old/integrations/engines/duckdb.md](#configurations-old-integrations-engines-duckdb) (15)
- [configurations-old/integrations/engines/fabric.md](#configurations-old-integrations-engines-fabric) (2)
- [configurations-old/integrations/engines/motherduck.md](#configurations-old-integrations-engines-motherduck) (8)
- [configurations-old/integrations/engines/mssql.md](#configurations-old-integrations-engines-mssql) (4)
- [configurations-old/integrations/engines/redshift.md](#configurations-old-integrations-engines-redshift) (1)
- [configurations-old/integrations/engines/risingwave.md](#configurations-old-integrations-engines-risingwave) (6)
- [configurations-old/integrations/engines/snowflake.md](#configurations-old-integrations-engines-snowflake) (32)
- [configurations-old/integrations/engines/spark.md](#configurations-old-integrations-engines-spark) (2)
- [configurations-old/integrations/engines/trino.md](#configurations-old-integrations-engines-trino) (28)
- [configurations/engines/snowflake/snowflake.md](#configurations-engines-snowflake-snowflake) (32)
- [configurations/options/linter.md](#configurations-options-linter) (3)
- [configurations/options/model_defaults.md](#configurations-options-model_defaults) (5)
- [configurations/options/notifications.md](#configurations-options-notifications) (12)
- [configurations/overview.md](#configurations-overview) (14)

### G

- [getting_started/cli.md](#getting_started-cli) (28)
- [getting_started/index.md](#getting_started-index) (2)
- [getting_started/prerequisites.md](#getting_started-prerequisites) (4)
- [guides-old/configuration.md](#guides-old-configuration) (85)
- [guides-old/connections.md](#guides-old-connections) (13)
- [guides-old/customizing_vulcan.md](#guides-old-customizing_vulcan) (1)
- [guides-old/isolated_systems.md](#guides-old-isolated_systems) (10)
- [guides-old/notifications.md](#guides-old-notifications) (12)
- [guides-old/projects.md](#guides-old-projects) (3)
- [guides-old/table_migration.md](#guides-old-table_migration) (5)
- [guides/data_quality.md](#guides-data_quality) (4)
- [guides/get-started/docker.md](#guides-get-started-docker) (18)
- [guides/incremental_by_time.md](#guides-incremental_by_time) (7)
- [guides/model_selection.md](#guides-model_selection) (6)
- [guides/models.md](#guides-models) (8)
- [guides/plan.md](#guides-plan) (7)
- [guides/run_and_scheduling.md](#guides-run_and_scheduling) (7)
- [guides/transpiling_semantics.md](#guides-transpiling_semantics) (3)

### I

- [index.md](#index) (1)

