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
| `tmdcio/vulcan-databricks:0.228.1.10` | Main Vulcan API service for Databricks |
| `tmdcio/vulcan-transpiler:0.228.1.10` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-databricks:0.228.1.10
docker pull tmdcio/vulcan-transpiler:0.228.1.10
```

### Materialization Strategy

Databricks uses the following materialization strategies depending on the model kind:

| Model Kind | Strategy | Description |
|------------|----------|-------------|
| `INCREMENTAL_BY_TIME_RANGE` | INSERT OVERWRITE by time column partition | Vulcan will overwrite the entire partition that corresponds to the time column, rather than deleting and inserting individual records. This approach is more efficient for partitioned data and leverages Databricks' native partitioning capabilities with Delta Lake. |
| `INCREMENTAL_BY_UNIQUE_KEY` | MERGE ON unique key | Vulcan uses Databricks' MERGE statement (with Delta Lake) to update existing records based on the unique key or insert new ones if they don't exist. This provides ACID transactions and efficient upserts. |
| `INCREMENTAL_BY_PARTITION` | REPLACE WHERE by partitioning key | Vulcan uses Databricks' `REPLACE WHERE` clause to efficiently replace data within specific partitions based on the partitioning key, leveraging Delta Lake's capabilities. |
| `FULL` | INSERT OVERWRITE | Vulcan uses Databricks' `INSERT OVERWRITE` statement to completely replace the table contents each time, working seamlessly with Delta Lake. |

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    The `http_path` can be found in your Databricks workspace under **SQL Warehouses → [Your Warehouse] → Connection Details**.

!!! warning
    Never commit your access token to version control. Use environment variables: `access_token: {{ env_var('DATABRICKS_TOKEN') }}`