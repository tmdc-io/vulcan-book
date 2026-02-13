# Overview

Your Vulcan project needs a configuration file. It tells Vulcan how to connect to your data warehouse, where to store state, and what defaults to use for your models. Without it, Vulcan doesn't know where your data lives or how to run your transformations.

## Configuration File

Create a configuration file in your project root. Choose one:

- `config.yaml`: YAML format. Use this for most projects. Simple and readable.

- `config.py`: Python format. Use this if you need dynamic configuration or want to generate settings programmatically.

## Example Configuration

Here's what a typical configuration file looks like:

```yaml linenums="1"
# Project identity
name: orders-analytics
display_name: Orders Analytics Platform
tenant: engineering
description: Orders Analytics is a centralized data product delivering clean, trusted insights across the full order lifecycle.

# Classification
tags:
  - e-commerce
  - retail
  - sales_analytics
  - customer_analytics
  - postgres

terms:
  - glossary.data_product
  - glossary.analytics_platform
  - glossary.sales_operations

# Metadata
metadata:
  domain: sales_operations
  use_cases:
    - Daily and weekly sales reporting
    - Customer segmentation and RFM analysis
    - Sales funnel conversion tracking
    - Product performance analytics
  limitations:
    - Demo dataset with synthetic data (100 customers, 1000 orders)
    - Historical data from November 2025 onwards

# Gateway Connection
gateways:
  default:
    connection:
      type: postgres
      host: warehouse
      port: 5432
      database: warehouse
      user: vulcan
      password: "{{ env_var('DB_PASSWORD') }}"
    state_connection:
      type: postgres
      host: statestore
      port: 5432
      database: statestore
      user: vulcan
      password: "{{ env_var('STATE_DB_PASSWORD') }}"

default_gateway: default

# Model Defaults (required)
model_defaults:
  dialect: postgres
  start: 2024-01-01
  cron: '@daily'

# Linting Rules
linter:
  enabled: true
  rules:
    - ambiguousorinvalidcolumn
    - invalidselectstarexpansion
```

## Configuration Structure

```mermaid
graph TB
    Config[config.yaml]
    Config --> Project[Project Settings]
    Config --> Metadata[Metadata]
    Config --> Gateways[Gateways]
    Config --> ModelDefaults[Model Defaults]
    Config --> Options[Optional Features]
    Project --> Name[name, display_name, tenant]
    Project --> Desc[description]
    Project --> Tags[tags, terms]
    Metadata --> Domain[domain]
    Metadata --> UseCases[use_cases]
    Metadata --> Limitations[limitations]
    Gateways --> Connection[connection]
    Gateways --> StateConn[state_connection]
    Gateways --> TestConn[test_connection]
    Options --> Linter[linter]
    Options --> Notifications[notifications]
    Options --> Variables[variables]
```

## Configuration Sections

### Project Settings

Metadata fields that identify your project. They don't affect how Vulcan runs, but they're useful for organization and discovery.

| Option | Description | Type | Required |
|--------|-------------|:----:|:--------:|
| `name` | Project identifier (used internally) | string | Yes |
| `tenant` | Tenant or organization name | string | Yes |
| `description` | Project description | string | No |
| `display_name` | Human-readable project name for UI/docs | string | No |
| `tags` | Labels for categorization and filtering | array of string | No |
| `terms` | Business glossary terms using dot notation (e.g., `glossary.data_product`) | array of string | No |

```yaml
# Project identity
name: orders-analytics
display_name: Orders Analytics Platform
tenant: engineering
description: Orders Analytics delivers insights across the full order lifecycle.

# Classification
tags:
  - e-commerce
  - retail
  - sales_analytics

terms:
  - glossary.data_product
  - glossary.analytics_platform
  - glossary.sales_operations
```

### Metadata

Metadata fields provide additional context about your project's purpose and scope. Use these to document what your project does, where it applies, and any known constraints.

| Option | Description | Type | Required |
|--------|-------------|:----:|:--------:|
| `domain` | Business domain or data area (e.g., sales_operations, marketing, finance) | string | No |
| `use_cases` | List of primary use cases or business problems this project addresses | array of string | No |
| `limitations` | List of known constraints, caveats, or edge cases to be aware of | array of string | No |

```yaml
# Metadata
metadata:
  domain: sales_operations
  use_cases:
    - Daily and weekly sales reporting
    - Customer segmentation and RFM analysis
    - Sales funnel conversion tracking
  limitations:
    - Demo dataset with synthetic data (100 customers, 1000 orders)
    - Historical data from November 2025 onwards
```

### Gateways

Gateways define how Vulcan connects to your data warehouse and state backend. Define multiple gateways for different environments: dev, staging, prod. Each gateway has its own connection settings.

| Component | Description | Default |
|-----------|-------------|---------|
| `connection` | Primary data warehouse connection | Required |
| `state_connection` | Where Vulcan stores internal state | Uses `connection` |
| `test_connection` | Connection for running tests | Uses `connection` |
| `scheduler` | Scheduler configuration | `builtin` |
| `state_schema` | Schema name for state tables | `vulcan` |

```yaml
# Gateway Connection
gateways:
  default:
    connection:
      type: postgres
      host: warehouse
      port: 5432
      database: warehouse
      user: vulcan
      password: "{{ env_var('DB_PASSWORD') }}"
    state_connection:
      type: postgres
      host: statestore
      port: 5432
      database: statestore
      user: vulcan
      password: "{{ env_var('STATE_DB_PASSWORD') }}"

default_gateway: default
```

<!-- See [Configuration Reference](./overview.md#gateways) for detailed gateway options. -->

### Model Defaults

The `model_defaults` section is required. At minimum, specify `dialect` to tell Vulcan what SQL dialect your models use. Other defaults are optional but apply to all models automatically, so you don't repeat the same settings in every model file.

```yaml
model_defaults:
  dialect: postgres     # Required
  owner: data-team
  start: 2024-01-01
  cron: '@daily'
```

See [Model Defaults](./options/model_defaults.md) for all available options.

### Variables

Store sensitive information like passwords and API keys without hardcoding them. Use environment variables, `.env` files, or configuration overrides. Variables also let you override configuration values dynamically.

See [Variables](./options/variables.md) for details.

### Execution Hooks

Run SQL statements automatically at the start and end of `vulcan plan` and `vulcan run` commands. Use `before_all` for setup tasks like creating temporary tables or granting permissions. Use `after_all` for cleanup or post-processing.

See [Execution Hooks](./options/execution_hooks.md) for detailed examples and use cases.

### Linter

Automatic code quality checks that run when you create a plan or run the lint command. Catches common mistakes and enforces coding standards. Use built-in rules or create custom ones.

See [Linter](./options/linter.md) for rules and custom linter configuration.

### Notifications

Set up alerts via Slack or email. Get notified when plans start or finish, when runs complete, or when audits fail.

See [Notifications](./options/notifications.md) for Slack webhooks, API, and email setup.

## Supported Engines

Vulcan works with these data warehouses and compute engines:

| Engine | Status |
|--------|:------:|
| [PostgreSQL](./engines/postgres/postgres.md) | Available |
| [Snowflake](./engines/snowflake/snowflake.md) | Available |
| [BigQuery](./engines/bigquery/bigquery.md) | Available |
| [Databricks](./engines/databricks/databricks.md) | WIP |
| [Redshift](./engines/redshift/redshift.md) | WIP |
| [Spark](./engines/spark/spark.md) | WIP |
| [Trino](./engines/trino/trino.md) | WIP |
| [Microsoft Fabric](./engines/fabric/fabric.md) | WIP |
| [SQL Server](./engines/mssql/mssql.md) | WIP |
| [MySQL](./engines/mysql/mysql.md) | WIP |
| [Lakehouse](./engines/) | Coming Soon |

<!-- ## Configuration Reference

| Topic | Description |
|-------|-------------|
| [Configuration Reference](./overview.md) | Complete list of all configuration parameters |
| [Variables](./options/variables.md) | Environment variables and `.env` files |
| [Model Defaults](./options/model_defaults.md) | Default settings for all models |
| [Execution Hooks](./options/execution_hooks.md) | `before_all` and `after_all` statements |
| [Linter](./options/linter.md) | Code quality rules and custom linters |
| [Notifications](./options/notifications.md) | Slack and email notification setup | -->

## Best Practices

Use environment variables for sensitive data like passwords and API keys. Keeps secrets out of your config files and makes it easier to manage different environments.

Set meaningful defaults in `model_defaults` to reduce boilerplate. If most of your models use the same dialect, start date, or cron schedule, set it once here instead of repeating it everywhere.

Enable linting to catch common errors early in development. Fix issues before they make it to production.

Separate state connection from your data warehouse for better isolation. Prevents state operations from interfering with your data processing.

Use multiple gateways for different environments: dev, staging, prod. Test changes safely before deploying to production. Use different database configurations for each environment.
