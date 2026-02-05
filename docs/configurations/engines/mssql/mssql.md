# Microsoft SQL Server

Microsoft SQL Server is a relational database management system known for its robust performance, enterprise-grade security, and comprehensive tooling. It's widely used for transactional workloads, data warehousing, and business intelligence. Vulcan integrates with SQL Server to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `mssql`

### Prerequisites

1. A SQL Server instance (on-premises, Azure SQL, or SQL Server in a container)
2. A database user with appropriate permissions
3. Network connectivity to the SQL Server instance

### Permissions

Vulcan requires the following SQL Server permissions:

- `CREATE SCHEMA` on the target database
- `CREATE TABLE` and `CREATE VIEW` on schemas
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `ALTER` on schemas for schema modifications

### Connection Options

Here are all the connection parameters you can use when setting up a SQL Server gateway:

| Option                       | Description                                                                     | Type   | Required |
|------------------------------|---------------------------------------------------------------------------------|:------:|:--------:|
| `type`                       | Engine type name - must be `mssql`                                              | string | Y        |
| `host`                       | The hostname or IP address of the SQL Server instance                           | string | Y        |
| `port`                       | The port number of the SQL Server instance (default: `1433`)                    | int    | Y        |
| `user`                       | The username for SQL Server authentication                                      | string | Y        |
| `password`                   | The password for SQL Server authentication                                      | string | Y        |
| `database`                   | The name of the database to connect to                                          | string | Y        |
| `concurrent_tasks`           | Maximum number of concurrent tasks (default: `4`)                               | int    | N        |
| `trust_server_certificate`   | Whether to trust the server certificate without validation (default: `false`)   | bool   | N        |

### Docker Images

The following Docker images are available for running Vulcan with SQL Server:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-mssql:0.228.1.6` | Main Vulcan API service for SQL Server |
| `tmdcio/vulcan-transpiler:0.228.1.8` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-mssql:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.8
```

### Materialization Strategy

Materialization strategies for Microsoft SQL Server depend on the model kind and engine capabilities. For detailed information about how different model kinds are materialized, see the [model kinds documentation](../../../components/model/model_kinds.md).

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    The `dialect` for SQL Server models should be set to `tsql` (Transact-SQL), not `mssql`.

!!! warning
    Only set `trust_server_certificate: true` in development environments. In production, configure proper SSL certificates.
