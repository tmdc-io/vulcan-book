# Trino

Trino (formerly PrestoSQL) is a distributed SQL query engine designed for fast, interactive analytics across large datasets. It excels at querying data from multiple sources including data lakes, databases, and object storage. Vulcan integrates with Trino to manage your data transformations using catalogs like Iceberg, Hive, and Delta Lake.

## Local/Built-in Scheduler
**Engine Adapter Type**: `trino`

### Prerequisites

1. A Trino cluster with coordinator and worker nodes
2. A catalog configured (e.g., Iceberg, Hive, or Delta Lake)
3. Network connectivity to the Trino coordinator

### Permissions

Vulcan requires the following Trino permissions (depending on your security configuration):

- `CREATE SCHEMA` on the target catalog
- `CREATE TABLE` and `CREATE VIEW` on schemas
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `DROP TABLE` for table cleanup during development

### Connection Options

Here are all the connection parameters you can use when setting up a Trino gateway:

| Option        | Description                                                              | Type   | Required |
|---------------|--------------------------------------------------------------------------|:------:|:--------:|
| `type`        | Engine type name - must be `trino`                                       | string | Y        |
| `host`        | The hostname of the Trino coordinator                                    | string | Y        |
| `port`        | The port number of the Trino coordinator (default: `8080`)               | int    | Y        |
| `user`        | The username for Trino authentication                                    | string | Y        |
| `catalog`     | The default catalog to use for queries                                   | string | Y        |
| `http_scheme` | The HTTP scheme (`http` or `https`)                                      | string | N        |
| `password`    | The password for Trino authentication (if password authentication is enabled) | string | N        |
| `roles`       | Role to use for queries (if role-based access control is enabled)        | dict   | N        |

### Docker Images

The following Docker images are available for running Vulcan with Trino:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-trino:0.228.1.6` | Main Vulcan API service for Trino |
| `tmdcio/vulcan-transpiler:0.228.1.1` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-trino:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.1
```

!!! note
    Use `http_scheme: https` for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('TRINO_PASSWORD') }}`
