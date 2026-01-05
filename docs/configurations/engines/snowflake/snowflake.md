# Snowflake

Snowflake is a cloud-based data warehouse that provides scalable storage and compute resources. It's ideal for enterprise workloads, large-scale analytics, and data sharing across organizations. Vulcan integrates seamlessly with Snowflake to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `snowflake`

### Prerequisites

1. A Snowflake account with valid credentials
2. A warehouse available for running computations

### Permissions

Vulcan requires the following Snowflake permissions:

- `USAGE` on a warehouse to execute computations
- `CREATE SCHEMA` on the target database
- `CREATE TABLE` and `CREATE VIEW` on schemas
- `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` on tables

### Connection Options

Here are all the connection parameters you can use when setting up a Snowflake gateway:

| Option                   | Description                                                                     | Type   | Required |
|--------------------------|---------------------------------------------------------------------------------|:------:|:--------:|
| `type`                   | Engine type name - must be `snowflake`                                          | string | Y        |
| `account`                | The Snowflake account identifier (e.g., `org-name-account-name`)                | string | Y        |
| `user`                   | The username to use for authentication with the Snowflake server                | string | Y        |
| `password`               | The password to use for authentication with the Snowflake server                | string | Y        |
| `warehouse`              | The name of the Snowflake warehouse to use for running computations             | string | Y        |
| `database`               | The name of the Snowflake database instance to connect to                       | string | Y        |
| `role`                   | The role to use for authentication with the Snowflake server                    | string | N        |
| `authenticator`          | The Snowflake authenticator method (e.g., `externalbrowser`, `oauth`)           | string | N        |
| `token`                  | The Snowflake OAuth 2.0 access token for authentication                         | string | N        |
| `private_key_path`       | The path to the private key file to use for authentication                      | string | N        |
| `private_key_passphrase` | The passphrase to decrypt the private key (if encrypted)                        | string | N        |

!!! note
    The `account` identifier format is `<org-name>-<account-name>` (e.g., `myorg-myaccount`). Find it in your Snowflake URL.

!!! warning
    Always use environment variables for sensitive credentials: `password: {{ env_var('SNOWFLAKE_PASSWORD') }}`