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
| `tmdcio/vulcan-transpiler:0.228.1.1` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-redshift:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.1
```

!!! note
    Use `sslmode: require` or higher for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('REDSHIFT_PASSWORD') }}`
