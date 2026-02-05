# Databricks

Databricks is a unified analytics platform built on Apache Spark that provides collaborative notebooks, automated cluster management, and a powerful SQL engine. It's ideal for large-scale data engineering, machine learning, and collaborative analytics. Vulcan integrates with Databricks to manage your data transformations using Unity Catalog and Delta Lake.

## Local/Built-in Scheduler
**Engine Adapter Type**: `databricks`

### Prerequisites

1. A Databricks workspace with SQL warehouse or cluster access
2. A personal access token or service principal credentials
3. The HTTP path to your SQL warehouse or cluster

### Permissions

Vulcan requires the following Databricks permissions:

- `USE CATALOG` on the target catalog
- `USE SCHEMA` and `CREATE SCHEMA` on the target schemas
- `CREATE TABLE` and `CREATE VIEW` on schemas
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables

### Connection Options

Here are all the connection parameters you can use when setting up a Databricks gateway:

| Option            | Description                                                                     | Type   | Required |
|-------------------|---------------------------------------------------------------------------------|:------:|:--------:|
| `type`            | Engine type name - must be `databricks`                                         | string | Y        |
| `server_hostname` | The Databricks workspace hostname (e.g., `adb-xxxxx.azuredatabricks.net`)       | string | Y        |
| `http_path`       | The HTTP path to the SQL warehouse or cluster                                   | string | Y        |
| `access_token`    | Personal access token or service principal token for authentication             | string | Y        |
| `catalog`         | The Unity Catalog name to use as the default catalog                            | string | Y        |

### Docker Images

The following Docker images are available for running Vulcan with Databricks:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-databricks:0.228.1.6` | Main Vulcan API service for Databricks |
| `tmdcio/vulcan-transpiler:0.228.1.8` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-databricks:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.8
```

!!! note
    The `http_path` can be found in your Databricks workspace under **SQL Warehouses → [Your Warehouse] → Connection Details**.

!!! warning
    Never commit your access token to version control. Use environment variables: `access_token: {{ env_var('DATABRICKS_TOKEN') }}`