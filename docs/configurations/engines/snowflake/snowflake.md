# Snowflake

<<<<<<< Updated upstream
Snowflake is a cloud-based data warehouse that provides scalable storage and compute resources. It's ideal for enterprise workloads, large-scale analytics, and data sharing across organizations. Vulcan integrates seamlessly with Snowflake to manage your data transformations with version control and safe deployments.
=======
This page provides information about how to use Vulcan with the Snowflake SQL engine.

It begins with a [Connection Quickstart](#connection-quickstart) that demonstrates how to connect to Snowflake, or you can skip directly to information about using Snowflake with the [built-in](#localbuilt-in-scheduler).

## Connection quickstart

Connecting to cloud warehouses involves a few steps, so this connection quickstart provides the info you need to get up and running with Snowflake.

It demonstrates connecting to Snowflake with the `snowflake-connector-python` library bundled with Vulcan.

Snowflake provides multiple methods of authorizing a connection (e.g., password, SSO, etc.). This quickstart demonstrates authorizing with a password, but configurations for other methods are [described below](#snowflake-authorization-methods).

!!! tip
    This quickstart assumes you are familiar with basic Vulcan commands and functionality.

    If you're not, work through the [Vulcan Quickstart](../../../guides/get-started/docker.md) before continuing!

### Prerequisites

Before working through this connection quickstart, ensure that:

1. You have a Snowflake account and know your username and password
2. Your Snowflake account has at least one [warehouse](https://docs.snowflake.com/en/user-guide/warehouses-overview) available for running computations
3. Your computer has Vulcan installed with the Snowflake extra available
    - Install from the command line with the command `pip install "vulcan[snowflake]"`
4. You have initialized a Vulcan example project on your computer
    - Open a command line interface and navigate to the directory where the project files should go

    - Initialize the project with the command `vulcan init snowflake`

### Access control permissions

Vulcan must have sufficient permissions to create and access different types of database objects.

Vulcan's core functionality requires relatively broad permissions, including:

1. Ability to create and delete schemas in a database
2. Ability to create, modify, delete, and query tables and views in the schemas it creates

If your project uses materialized views or dynamic tables, Vulcan will also need permissions to create, modify, delete, and query those object types.

We now describe how to grant Vulcan appropriate permissions.

#### Snowflake roles

Snowflake allows you to grant permissions directly to a user, or you can create and assign permissions to a "role" that you then grant to the user.

Roles provide a convenient way to bundle sets of permissions and provide them to multiple users. We create and use a role to grant our user permissions in this quickstart.

The role must be granted `USAGE` on a warehouse so it can execute computations. We describe other permissions below.

#### Database permissions
The top-level object container in Snowflake is a "database" (often called a "catalog" in other engines). Vulcan does not need permission to create databases; it may use an existing one.

The simplest way to grant Vulcan sufficient permissions for a database is to give it `OWNERSHIP` of the database, which includes all the necessary permissions.

Alternatively, you may grant Vulcan granular permissions for all the actions and objects it will work with in the database.

#### Granting the permissions

This section provides example code for creating a `vulcan` role, granting it sufficient permissions, and granting it to a user.

The code must be executed by a user with `USERADMIN` level permissions or higher. We provide two versions of the code, one that grants database `OWNERSHIP` to the role and another that does not.

Both examples create a role named `vulcan`, grant it usage of the warehouse `compute_wh`, create a database named `demo_db`, and assign the role to the user `demo_user`. The step that creates the database can be omitted if the database already exists.

=== "With database ownership"

    ```sql linenums="1"
    USE ROLE useradmin; -- This code requires USERADMIN privileges or higher

    CREATE ROLE vulcan; -- Create role for permissions
    GRANT USAGE ON WAREHOUSE compute_wh TO ROLE vulcan; -- Can use warehouse

    CREATE DATABASE demo_db; -- Create database for Vulcan to use (omit if database already exists)
    GRANT OWNERSHIP ON DATABASE demo_db TO ROLE vulcan; -- Role owns database

    GRANT ROLE vulcan TO USER demo_user; -- Grant role to user
    ALTER USER demo_user SET DEFAULT ROLE = vulcan; -- Make role user's default role
    ```

=== "Without database ownership"

    ```sql linenums="1"
    USE ROLE useradmin; -- This code requires USERADMIN privileges or higher

    CREATE ROLE vulcan; -- Create role for permissions
    CREATE DATABASE demo_db; -- Create database for Vulcan to use (omit if database already exists)

    GRANT USAGE ON WAREHOUSE compute_wh TO ROLE vulcan; -- Can use warehouse
    GRANT USAGE ON DATABASE demo_db TO ROLE vulcan; -- Can use database

    GRANT CREATE SCHEMA ON DATABASE demo_db TO ROLE vulcan; -- Can create SCHEMAs in database
    GRANT USAGE ON FUTURE SCHEMAS IN DATABASE demo_db TO ROLE vulcan; -- Can use schemas it creates
    GRANT CREATE TABLE ON FUTURE SCHEMAS IN DATABASE demo_db TO ROLE vulcan; -- Can create TABLEs in schemas
    GRANT CREATE VIEW ON FUTURE SCHEMAS IN DATABASE demo_db TO ROLE vulcan; -- Can create VIEWs in schemas
    GRANT SELECT, INSERT, TRUNCATE, UPDATE, DELETE ON FUTURE TABLES IN DATABASE demo_db TO ROLE vulcan; -- Can SELECT and modify TABLEs in schemas
    GRANT REFERENCES, SELECT ON FUTURE VIEWS IN DATABASE demo_db TO ROLE vulcan; -- Can SELECT and modify VIEWs in schemas

    GRANT ROLE vulcan TO USER demo_user; -- Grant role to user
    ALTER USER demo_user SET DEFAULT ROLE = vulcan; -- Make role user's default role
    ```

### Get connection info

Now that our user has sufficient access permissions, we're ready to gather the information needed to configure the Vulcan connection.

#### Account name

Snowflake connection configurations require the `account` parameter that identifies the Snowflake account Vulcan should connect to.

Snowflake account identifiers have two components: your organization name and your account name. Both are embedded in your Snowflake web interface URL, separated by a `/`.

This shows the default view when you log in to your Snowflake account, where we can see the two components of the account identifier:

![Snowflake account info in web URL](./images/snowflake_db-guide_account-url.png){ loading=lazy }

In this example, our organization name is `idapznw`, and our account name is `wq29399`.

We concatenate the two components, separated by a `-`, for the Vulcan `account` parameter: `idapznw-wq29399`.

#### Warehouse name

Your Snowflake account may have more than one warehouse available - any will work for this quickstart, which runs very few computations.

Some Snowflake user accounts may have a default warehouse they automatically use when connecting.

The connection configuration's `warehouse` parameter is not required, but we recommend specifying the warehouse explicitly in the configuration to ensure Vulcan's behavior doesn't change if the user's default warehouse changes.

#### Database name

Snowflake user accounts may have a "Default Namespace" that includes a default database they automatically use when connecting.

The connection configuration's `database` parameter is not required, but we recommend specifying the database explicitly in the configuration to ensure Vulcan's behavior doesn't change if the user's default namespace changes.

### Configure the connection

We now have the information we need to configure Vulcan's connection to Snowflake.

We start the configuration by adding a gateway named `snowflake` to our example project's config.yaml file and making it our `default_gateway`:

```yaml linenums="1" hl_lines="2-6"
gateways:
  snowflake:
    connection:
      type: snowflake

default_gateway: snowflake

model_defaults:
  dialect: snowflake
  start: 2024-07-24
```

And we specify the `account`, `user`, `password`, `database`, and `warehouse` connection parameters using the information from above:

```yaml linenums="1" hl_lines="5-9"
gateways:
  snowflake:
    connection:
      type: snowflake
      account: idapznw-wq29399
      user: DEMO_USER
      password: << password here >>
      database: DEMO_DB
      warehouse: COMPUTE_WH

default_gateway: snowflake

model_defaults:
  dialect: snowflake
  start: 2024-07-24
```

!!! warning
    Best practice for storing secrets like passwords is placing them in [environment variables that the configuration file loads dynamically](../../../references/configuration.md#variables). For simplicity, this guide instead places the value directly in the configuration file.

    This code demonstrates how to use the environment variable `SNOWFLAKE_PASSWORD` for the configuration's `password` parameter:

    ```yaml linenums="1" hl_lines="5"
    gateways:
      snowflake:
        connection:
          type: snowflake
          password: {{ env_var('SNOWFLAKE_PASSWORD') }}
    ```

### Check connection

We have now specified the `snowflake` gateway connection information, so we can confirm that Vulcan is able to successfully connect to Snowflake. We will test the connection with the `vulcan info` command.

First, open a command line terminal. Now enter the command `vulcan info`:

![Run vulcan info command in CLI](./images/snowflake_db-guide_sqlmesh-info.png){ loading=lazy }

The output shows that our data warehouse connection succeeded:

![Successful data warehouse connection](./images/snowflake_db-guide_sqlmesh-info-succeeded.png){ loading=lazy }

However, the output includes a `WARNING` about using the Snowflake SQL engine for storing Vulcan state:

![Snowflake state connection warning](./images/snowflake_db-guide_sqlmesh-info-warning.png){ loading=lazy }

!!! warning
    Snowflake is not designed for transactional workloads and should not be used to store Vulcan state even in testing deployments.

    Learn more about storing Vulcan state [here](../../../references/configuration.md#gateways).

### Specify state connection

We can store Vulcan state in a different SQL engine by specifying a `state_connection` in our `snowflake` gateway.

This example uses the DuckDB engine to store state in the local `snowflake_state.db` file:

```yaml linenums="1" hl_lines="10-12"
gateways:
  snowflake:
    connection:
      type: snowflake
      account: idapznw-wq29399
      user: DEMO_USER
      password: << your password here >>
      database: DEMO_DB
      warehouse: COMPUTE_WH
    state_connection:
      type: duckdb
      database: snowflake_state.db

default_gateway: snowflake

model_defaults:
  dialect: snowflake
  start: 2024-07-24
```

Now we no longer see the warning when running `vulcan info`, and we see a new entry `State backend connection succeeded`:

![No state connection warning](./images/snowflake_db-guide_sqlmesh-info-no-warning.png){ loading=lazy }

### Run a `vulcan plan`

Now we're ready to run a `vulcan plan` in Snowflake:

![Run vulcan plan in snowflake](./images/snowflake_db-guide_sqlmesh-plan.png){ loading=lazy }

And confirm that our schemas and objects exist in the Snowflake catalog:

![Vulcan plan objects in snowflake](./images/snowflake_db-guide_sqlmesh-plan-objects.png){ loading=lazy }

Congratulations - your Vulcan project is up and running on Snowflake!

### Where are the row counts?

Vulcan reports the number of rows processed by each model in its `plan` and `run` terminal output.

However, due to limitations in the Snowflake Python connector, row counts cannot be determined for `CREATE TABLE AS` statements. Therefore, Vulcan does not report row counts for certain model kinds, such as `FULL` models.

Learn more about the connector limitation [on Github](https://github.com/snowflakedb/snowflake-connector-python/issues/645).
>>>>>>> Stashed changes

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

## Authentication Methods

### SSO Authorization

Use the `externalbrowser` authenticator for Single Sign-On:

```yaml
gateways:
  snowflake:
    connection:
      type: snowflake
      account: your-account-id
      user: your-username
      authenticator: externalbrowser
      warehouse: COMPUTE_WH
      database: DEMO
```

### OAuth Authorization

Use the `oauth` authenticator with an access token:

```yaml
gateways:
  snowflake:
    connection:
      type: snowflake
      account: your-account-id
      user: your-username
      authenticator: oauth
      token: {{ env_var('SNOWFLAKE_OAUTH_TOKEN') }}
```

### Private Key Authorization

Use a private key file for authentication:

```yaml
gateways:
  snowflake:
    connection:
      type: snowflake
      account: your-account-id
      user: your-username
      private_key_path: /path/to/private_key.p8
      private_key_passphrase: {{ env_var('SNOWFLAKE_KEY_PASSPHRASE') }}
```

<<<<<<< Updated upstream
!!! note
    The `private_key_passphrase` is only required if your private key was encrypted with a passphrase.
=======
### Transient Tables

A model can use a `TRANSIENT` table in the physical layer by specifying the `creatable_type` property and setting it to `TRANSIENT`:

```sql linenums="1"
MODEL (
  name schema_name.model_name,
  physical_properties (
      creatable_type = TRANSIENT
  )
);

SELECT a FROM schema_name.model_b;
```

### Iceberg Tables

In order for Snowflake to be able to create an Iceberg table, there must be an [External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume) configured to store the Iceberg table data on.

Once that is configured, you can create a model backed by an Iceberg table by using `table_format iceberg` like so:

```sql linenums="1" hl_lines="4 6-7"
MODEL (
  name schema_name.model_name,
  kind FULL,
  table_format iceberg,
  physical_properties (
    catalog = 'snowflake',
    external_volume = '<external volume name>'
  )
);
```

To prevent having to specify `catalog = 'snowflake'` and `external_volume = '<external volume name>'` on every model, see the Snowflake documentation for:

  - [Configuring a default Catalog](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration#set-a-default-catalog-at-the-account-database-or-schema-level)

  - [Configuring a default External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume#set-a-default-external-volume-at-the-account-database-or-schema-level)

Alternatively you can also use [model defaults](../../../references/model_configuration.md#model-defaults) to set defaults at the Vulcan level instead.

To utilize the wide variety of [optional properties](https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-snowflake#optional-parameters) that Snowflake makes available for Iceberg tables, simply specify them as `physical_properties`:

```sql linenums="1" hl_lines="8"
MODEL (
  name schema_name.model_name,
  kind FULL,
  table_format iceberg,
  physical_properties (
    catalog = 'snowflake',
    external_volume = 'my_external_volume',
    base_location = 'my/product_reviews/'
  )
);
```

!!! warning "External catalogs"

    Setting `catalog = 'snowflake'` to use Snowflake's internal catalog is a good default because Vulcan needs to be able to write to the tables it's managing and Snowflake [does not support](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-options) writing to Iceberg tables configured under external catalogs.

    You can however still reference a table from an external catalog in your model as a normal [external table](../../../components/model/types/external_models.md).

## Troubleshooting

### Frequent Authentication Prompts

When using Snowflake with security features like Multi-Factor Authentication (MFA), you may experience repeated prompts for authentication while running Vulcan commands. This typically occurs when your Snowflake account isn't configured to issue short-lived tokens.

To reduce authentication prompts, you can enable token caching in your Snowflake connection configuration:

- For general authentication, see [Connection Caching Documentation](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-use#using-connection-caching-to-minimize-the-number-of-prompts-for-authentication-optional)

- For MFA specifically, see [MFA Token Caching Documentation](https://docs.snowflake.com/en/user-guide/security-mfa#using-mfa-token-caching-to-minimize-the-number-of-prompts-during-authentication-optional).
>>>>>>> Stashed changes
