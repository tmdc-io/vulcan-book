# Amazon Redshift

Amazon Redshift is a fully managed, petabyte-scale data warehouse service in the cloud. Built for high-performance analytics and business intelligence workloads, it uses columnar storage and massively parallel processing (MPP) to deliver fast query performance. Vulcan integrates seamlessly with Redshift to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `redshift`

### Prerequisites

1. An Amazon Redshift cluster or Redshift Serverless endpoint
2. A database user with appropriate permissions
3. Network connectivity to the Redshift cluster (VPC configuration may be required)

### Permissions

Vulcan requires the following Redshift permissions:

- `CREATE` on the target database for creating schemas
- `CREATE` on schemas for creating tables and views
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `USAGE` on schemas

### Connection Options

Here are all the connection parameters you can use when setting up a Redshift gateway:

| Option     | Description                                                          | Type   | Required |
|------------|----------------------------------------------------------------------|:------:|:--------:|
| `type`     | Engine type name - must be `redshift`                                | string | Y        |
| `host`     | The Redshift cluster endpoint hostname                               | string | Y        |
| `port`     | The port number of the Redshift cluster (default: `5439`)            | int    | Y        |
| `user`     | The username for Redshift authentication                             | string | Y        |
| `password` | The password for Redshift authentication                             | string | Y        |
| `database` | The name of the database to connect to                               | string | Y        |
| `sslmode`  | SSL mode for the connection (`require`, `verify-ca`, `verify-full`)  | string | N        |
| `timeout`  | Connection timeout in seconds                                        | int    | N        |

### Docker Images

The following Docker images are available for running Vulcan with Redshift:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-redshift:0.228.1.6` | Main Vulcan API service for Redshift |
| `tmdcio/vulcan-transpiler:0.228.1.10` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-redshift:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.10
```

### Materialization Strategy

Redshift uses the following materialization strategies depending on the model kind:

| Model Kind | Strategy | Description |
|------------|----------|-------------|
| `INCREMENTAL_BY_TIME_RANGE` | DELETE by time range, then INSERT | Vulcan will first delete existing records within the target time range, then insert the new data. This ensures data consistency and prevents duplicates when reprocessing time intervals. |
| `INCREMENTAL_BY_UNIQUE_KEY` | MERGE ON unique key | Vulcan uses Redshift's MERGE statement to update existing records based on the unique key or insert new ones if they don't exist. |
| `INCREMENTAL_BY_PARTITION` | DELETE by partitioning key, then INSERT | Vulcan will delete existing records matching the partitioning key, then insert the new data. This ensures partition-level consistency when reprocessing data. |
| `FULL` | DROP TABLE, CREATE TABLE, INSERT | Vulcan drops the existing table, creates a new one, and inserts all data. This completely rebuilds the table from scratch each time. |

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    Use `sslmode: require` or higher for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('REDSHIFT_PASSWORD') }}`
