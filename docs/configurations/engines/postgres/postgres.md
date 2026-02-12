# Postgres

PostgreSQL is a powerful, open-source relational database that works great with Vulcan. It's perfect for smaller projects, development environments, or when you want full control over your database infrastructure.

## Local/Built-in Scheduler
**Engine Adapter Type**: `postgres`

### Prerequisites

1. A PostgreSQL server instance (version 12 or higher recommended)
2. A database user with appropriate permissions
3. Network connectivity to the PostgreSQL server

### Permissions

Vulcan requires the following PostgreSQL permissions:

- `CREATE` on the target database for creating schemas
- `CREATE` on schemas for creating tables and views
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `USAGE` on schemas

### Connection Options

Here are all the connection parameters you can use when setting up a PostgreSQL gateway:

| Option             | Description                                                                     | Type   | Required |
|--------------------|---------------------------------------------------------------------------------|:------:|:--------:|
| `type`             | Engine type name - must be `postgres`                                           | string | Y        |
| `host`             | The hostname of the Postgres server                                             | string | Y        |
| `user`             | The username to use for authentication with the Postgres server                 | string | Y        |
| `password`         | The password to use for authentication with the Postgres server                 | string | Y        |
| `port`             | The port number of the Postgres server                                          | int    | Y        |
| `database`         | The name of the database instance to connect to                                 | string | Y        |
| `keepalives_idle`  | The number of seconds between each keepalive packet sent to the server.         | int    | N        |
| `connect_timeout`  | The number of seconds to wait for the connection to the server. (Default: `10`) | int    | N        |
| `role`             | The role to use for authentication with the Postgres server                     | string | N        |
| `sslmode`          | The security of the connection to the Postgres server                           | string | N        |
| `application_name` | The name of the application to use for the connection                           | string | N        |

### Docker Images

The following Docker images are available for running Vulcan with PostgreSQL:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-postgres:0.228.1.10` | Main Vulcan API service for PostgreSQL |
| `tmdcio/vulcan-transpiler:0.228.1.10` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-postgres:0.228.1.10
docker pull tmdcio/vulcan-transpiler:0.228.1.10
```

### Materialization Strategy

PostgreSQL uses the following materialization strategies depending on the model kind:

| Model Kind | Strategy | Description |
|------------|----------|-------------|
| `INCREMENTAL_BY_TIME_RANGE` | DELETE by time range, then INSERT | Vulcan will first delete existing records within the target time range, then insert the new data. This ensures data consistency and prevents duplicates when reprocessing time intervals. |
| `INCREMENTAL_BY_UNIQUE_KEY` | MERGE ON unique key | Vulcan uses PostgreSQL's MERGE (UPSERT) functionality to update existing records based on the unique key or insert new ones if they don't exist. |
| `INCREMENTAL_BY_PARTITION` | DELETE by partitioning key, then INSERT | Vulcan will delete existing records matching the partitioning key, then insert the new data. This ensures partition-level consistency when reprocessing data. |
| `FULL` | DROP TABLE, CREATE TABLE, INSERT | Vulcan drops the existing table, creates a new one, and inserts all data. This completely rebuilds the table from scratch each time. |

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    Use `sslmode: require` for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('POSTGRES_PASSWORD') }}`
