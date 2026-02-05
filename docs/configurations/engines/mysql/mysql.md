# MySQL

MySQL is one of the world's most popular open-source relational databases, known for its reliability, ease of use, and strong community support. It's widely used for web applications, content management systems, and data warehousing. Vulcan integrates with MySQL to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `mysql`

### Prerequisites

1. A MySQL server instance (version 5.7 or higher recommended)
2. A database user with appropriate permissions
3. Network connectivity to the MySQL server

### Permissions

Vulcan requires the following MySQL permissions:

- `CREATE` on the target database for creating schemas and tables
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `ALTER` for schema modifications
- `DROP` for table cleanup during development

### Connection Options

Here are all the connection parameters you can use when setting up a MySQL gateway:

| Option     | Description                                                     | Type   | Required |
|------------|-----------------------------------------------------------------|:------:|:--------:|
| `type`     | Engine type name - must be `mysql`                              | string | Y        |
| `host`     | The hostname or IP address of the MySQL server                  | string | Y        |
| `port`     | The port number of the MySQL server (default: `3306`)           | int    | Y        |
| `user`     | The username for MySQL authentication                           | string | Y        |
| `password` | The password for MySQL authentication                           | string | Y        |
| `database` | The name of the database to connect to                          | string | Y        |
| `charset`  | The character set for the connection (default: `utf8mb4`)       | string | N        |
| `ssl`      | SSL configuration options for secure connections                | dict   | N        |

### Docker Images

The following Docker images are available for running Vulcan with MySQL:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-mysql:0.228.1.6` | Main Vulcan API service for MySQL |
| `tmdcio/vulcan-transpiler:0.228.1.8` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-mysql:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.8
```

!!! note
    MySQL 5.7 or higher is recommended. Use the `ssl` option for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('MYSQL_PASSWORD') }}`
