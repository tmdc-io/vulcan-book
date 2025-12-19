# Snowflake

Snowflake is a cloud data warehouse that scales automatically and works seamlessly with Vulcan. It's perfect for teams that need elastic compute and don't want to manage infrastructure. This guide will walk you through everything you need to know to get Vulcan working with Snowflake.

We'll start with a [Connection Quickstart](#connection-quickstart) that shows you how to connect to Snowflake step-by-step. If you're already familiar with Snowflake connections, you can jump straight to the [built-in scheduler](#localbuilt-in-scheduler) details.

## Connection quickstart

Connecting to Snowflake involves a few steps, but don't worry, we'll walk you through it. This quickstart will get you up and running in no time.

We'll be using the `snowflake-connector-python` library that comes bundled with Vulcan, so you don't need to install anything extra.

Snowflake supports several authentication methods (password, SSO, OAuth, private key, etc.). This quickstart uses password authentication because it's the simplest to get started with. If you need a different method, we cover all the options [below](#snowflake-authorization-methods).

!!! tip
    This quickstart assumes you're already familiar with basic Vulcan commands and functionality.

<<<<<<< Updated upstream
    If you're not, work through the [Vulcan Quickstart](../../../guides/get-started/docker.md) before continuing!
=======
    If you're new to Vulcan, we recommend working through the [Vulcan Quickstart](configurations/guides/get-started/docker.md) first. It'll give you a solid foundation before diving into Snowflake-specific setup!
>>>>>>> Stashed changes

### Prerequisites

Before we get started, make sure you have everything you need:

1. **A Snowflake account** with your username and password handy. If you don't have one yet, you can sign up for a free trial.

2. **At least one warehouse** in your Snowflake account. Warehouses are what Snowflake uses to run queries, think of them as compute clusters. If you're not sure what this means, check out [Snowflake's warehouse documentation](https://docs.snowflake.com/en/user-guide/warehouses-overview).

3. **Vulcan installed with Snowflake support**. You'll need to install the Snowflake extra:
    ```bash
    pip install "vulcan[snowflake]"
    ```

4. **A Vulcan project initialized**. If you haven't created one yet:
    ```bash
    vulcan init snowflake
    ```
    This sets up a basic project structure with Snowflake as the default engine.

### Access control permissions

Vulcan needs certain permissions to do its job. It has to create schemas, tables, and views, and manage them over time. Let's make sure your Snowflake user has everything it needs.

Vulcan's core functionality requires these permissions:

1. **Create and delete schemas** in a database
2. **Create, modify, delete, and query** tables and views in the schemas it creates

If you're using materialized views or dynamic tables, Vulcan will need permissions for those too.

Here's how to set up the right permissions:

#### Snowflake roles

In Snowflake, you can grant permissions directly to a user, but it's usually better to create a role and grant permissions to that role instead. Then you grant the role to the user. This makes it easier to manage permissions, especially if you have multiple users who need the same access.

We'll create a `vulcan` role and grant it all the permissions Vulcan needs. The role must have `USAGE` on a warehouse so it can actually run queries. We'll cover all the other permissions below.

#### Database permissions

In Snowflake, databases are the top-level containers (other engines sometimes call them "catalogs"). Vulcan doesn't need to create databases, it can use an existing one.

You've got two options for granting permissions:

1. **Give Vulcan `OWNERSHIP` of the database** - This is the simplest approach. Ownership includes all the permissions Vulcan needs, so you don't have to worry about missing something.

2. **Grant granular permissions** - If you prefer more control, you can grant specific permissions for each action and object type. This is more work but gives you finer-grained control.

We'll show you both approaches below, so you can pick whichever fits your security requirements better.

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

Now that your user has the right permissions, let's gather the connection information you'll need. Don't worry, most of this is easy to find in your Snowflake account.

#### Account name

You'll need your Snowflake account identifier for the connection. Here's the thing, Snowflake account identifiers have two parts: your organization name and your account name. Both are right there in your Snowflake web interface URL.

When you log into Snowflake, look at the URL. You'll see something like `https://idapznw.snowflakecomputing.com/console#/internal/org/Wq29399`. The organization name (`idapznw`) and account name (`wq29399`) are separated by a `/` in the URL path.

To use them in Vulcan, you'll combine them with a hyphen. So if your organization is `idapznw` and your account is `wq29399`, your Vulcan `account` parameter would be `idapznw-wq29399`.

![Snowflake account info in web URL](./images/snowflake_db-guide_account-url.png){ loading=lazy }

#### Warehouse name

Your Snowflake account might have multiple warehouses, and any of them will work for this quickstart. Since we're just getting set up, we won't be running heavy workloads.

Some Snowflake users have a default warehouse that gets used automatically, but we recommend specifying the warehouse explicitly in your Vulcan config. Why? Because if someone changes the user's default warehouse later, your Vulcan configuration won't suddenly start using a different warehouse. It's better to be explicit about these things.

#### Database name

Similar to warehouses, Snowflake users can have a "Default Namespace" that includes a default database. While you *can* rely on that default, we strongly recommend specifying the database explicitly in your Vulcan config. This way, your configuration won't break if someone changes the user's default namespace later. Explicit is better than implicit!

### Configure the connection

Perfect! Now you have everything you need. Let's put it all together in your Vulcan configuration.

We'll add a gateway named `snowflake` to your `config.yaml` file and make it the default gateway:

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

<<<<<<< Updated upstream
!!! warning
    Best practice for storing secrets like passwords is placing them in [environment variables that the configuration file loads dynamically](../../../../references/configuration.md#variables). For simplicity, this guide instead places the value directly in the configuration file.
=======
!!! warning "Security Best Practice"
    We're showing the password directly in the config file for simplicity, but **don't do this in production!** Instead, use environment variables to keep secrets out of your config files.
>>>>>>> Stashed changes

    Here's how you'd use an environment variable for the password:

    ```yaml linenums="1" hl_lines="5"
    gateways:
      snowflake:
        connection:
          type: snowflake
          password: {{ env_var('SNOWFLAKE_PASSWORD') }}
    ```

    This way, your password stays secure and you can use different values for different environments. Check out our [Variables documentation](../../options/variables.md) for more details.

### Check connection

Great! Now let's make sure everything works. We'll test the connection using the `vulcan info` command, which checks both your data warehouse connection and your state backend connection.

Open a terminal in your project directory and run:

![Run vulcan info command in CLI](./images/snowflake_db-guide_sqlmesh-info.png){ loading=lazy }

The output shows that our data warehouse connection succeeded:

![Successful data warehouse connection](./images/snowflake_db-guide_sqlmesh-info-succeeded.png){ loading=lazy }

You might see a warning about using Snowflake for storing Vulcan state. That's because Snowflake isn't designed for transactional workloads, and Vulcan's state needs frequent small writes. Even for testing, it's better to use a different database for state.

![Snowflake state connection warning](./images/snowflake_db-guide_sqlmesh-info-warning.png){ loading=lazy }

!!! warning
    **Don't use Snowflake for state storage.** Snowflake is optimized for analytical workloads, not transactional ones. Vulcan's state backend needs to handle frequent small writes, which isn't what Snowflake is built for.

<<<<<<< Updated upstream
    Learn more about storing Vulcan state [here](../../../../references/configuration.md#gateways).
=======
    Use a separate database (like PostgreSQL or DuckDB) for your state connection. Learn more about state connections [here](../../guides-old/configuration.md#state-connection).
>>>>>>> Stashed changes

### Specify state connection

Good news, you can use a different database for state storage! Just add a `state_connection` to your gateway configuration. This way, Snowflake handles your data processing, and a more appropriate database handles Vulcan's state.

Here's an example using DuckDB (a lightweight local database) to store state in a local file:

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

Now when you run `vulcan info` again, the warning should be gone, and you'll see `State backend connection succeeded`:

![No state connection warning](./images/snowflake_db-guide_sqlmesh-info-no-warning.png){ loading=lazy }

Perfect! Your state is now stored separately from your data warehouse, which is exactly what you want.

### Run a `vulcan plan`

You're all set! Let's create your first plan. Run:

```bash
vulcan plan
```

![Run vulcan plan in snowflake](./images/snowflake_db-guide_sqlmesh-plan.png){ loading=lazy }

This will create the schemas and objects Vulcan needs in your Snowflake account. You can verify everything was created correctly by checking the Snowflake catalog:

![Vulcan plan objects in snowflake](./images/snowflake_db-guide_sqlmesh-plan-objects.png){ loading=lazy }

🎉 **Congratulations!** Your Vulcan project is now up and running on Snowflake. You're ready to start building your data pipeline!

### Where are the row counts?

You might notice that Vulcan doesn't always show row counts for your models when running plans or runs. That's because of a limitation in the Snowflake Python connector, it can't determine row counts for `CREATE TABLE AS` statements.

So if you're using `FULL` model kinds (which use `CREATE TABLE AS`), you won't see row counts in the output. This is a known limitation, and there's not much we can do about it until the connector adds support. You can read more about it [on Github](https://github.com/snowflakedb/snowflake-connector-python/issues/645) if you're curious about the technical details.

## Local/Built-in Scheduler
**Engine Adapter Type**: `snowflake`

### Installation
```
pip install "vulcan[snowflake]"
```

### Connection options

| Option                   | Description                                                                                                                                                                    |  Type  | Required |
|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------:|:--------:|
| `type`                   | Engine type name - must be `snowflake`                                                                                                                                         | string |    Y     |
| `account`                | The Snowflake account name                                                                                                                                                     | string |    Y     |
| `user`                   | The Snowflake username                                                                                                                                                         | string |    N     |
| `password`               | The Snowflake password                                                                                                                                                         | string |    N     |
| `authenticator`          | The Snowflake authenticator method                                                                                                                                             | string |    N     |
| `warehouse`              | The Snowflake warehouse name                                                                                                                                                   | string |    N     |
| `database`               | The Snowflake database name                                                                                                                                                    | string |    N     |
| `role`                   | The Snowflake role name                                                                                                                                                        | string |    N     |
| `token`                  | The Snowflake OAuth 2.0 access token                                                                                                                                           | string |    N     |
| `private_key`            | The optional private key to use for authentication. Key can be Base64-encoded DER format (representing the key bytes), a plain-text PEM format, or bytes (Python config only). | string |    N     |
| `private_key_path`       | The optional path to the private key to use for authentication. This would be used instead of `private_key`.                                                                   | string |    N     |
| `private_key_passphrase` | The optional passphrase to use to decrypt `private_key` (if in PEM format) or `private_key_path`. Keys can be created without encryption so only provide this if needed.       | string |    N     |
| `session_parameters`     | The optional session parameters to set for the connection.                                                                                                                     | dict   |    N     |


### Lowercase object names

Here's something to be aware of: Snowflake object names are case-insensitive by default, and Snowflake automatically converts them to uppercase. So if you write `CREATE SCHEMA vulcan`, Snowflake will actually create a schema named `VULCAN`.

If you really need a case-sensitive lowercase name (maybe for compatibility with other tools), you'll need to double-quote it in SQL. In your Vulcan config file, you'll also need to wrap it in single quotes. Here's how:

``` yaml
connection:
  type: snowflake
  <other connection options>
  database: '"my_db"' # outer single and inner double quotes
```

### Snowflake authorization methods

Password authentication is the simplest way to get started, but Snowflake supports several other methods that might be better for your security requirements. Let's look at your options:

#### Snowflake SSO Authorization

If your organization uses Single Sign-On (SSO) with Snowflake, you can configure Vulcan to use it. This uses the `externalbrowser` authenticator, which will open your browser for authentication. Here's how to set it up:

```yaml
gateways:
  snowflake:
    connection:
      type: snowflake
      account: ************
      user: ************
      authenticator: externalbrowser
      warehouse: ************
      database: ************
      role: ************
```

#### Snowflake OAuth Authorization

OAuth is another secure authentication option. You'll need an OAuth token from Snowflake, and then you can use it like this:

=== "YAML"

    ```yaml linenums="1"
    gateways:
      snowflake:
        connection:
          type: snowflake
          account: account
          user: user
          authenticator: oauth
          token: eyJhbGciOiJSUzI1NiIsImtpZCI6ImFmZmM...
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="snowflake"),
        gateways={
           "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="user",
                    account="account",
                    authenticator="oauth",
                    token="eyJhbGciOiJSUzI1NiIsImtpZCI6ImFmZmM...",
                ),
            ),
        }
    )
    ```

#### Snowflake Private Key Authorization

Private key authentication is great for automated systems and CI/CD pipelines. Vulcan supports several ways to provide the private key:

- **File path** - Point to a file containing the key
- **Base64-encoded DER format** - The key bytes encoded as Base64
- **Plain-text PEM format** - The standard PEM format you're probably familiar with
- **Bytes** - Raw bytes (Python config only)

For all of these methods, you'll need to provide both the `account` and `user` parameters. Let's look at each option:

__Private Key Path__

This is probably the simplest approach if you have the key stored in a file. Just point Vulcan to the file path. If your key is encrypted with a passphrase, you'll need to provide that too.

=== "YAML"

    ```yaml linenums="1"
    gateways:
      snowflake:
        connection:
          type: snowflake
          account: account
          user: user
          private_key_path: '/path/to/key.key'
          private_key_passphrase: supersecret
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="snowflake"),
        gateways={
           "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="user",
                    account="account",
                    private_key_path="/path/to/key.key",
                    private_key_passphrase="supersecret",
                ),
            ),
        }
    )
    ```


__Private Key PEM__

If you have the key in PEM format (the standard format that starts with `-----BEGIN PRIVATE KEY-----`), you can paste it directly into your config. Again, only provide the passphrase if your key is encrypted.

=== "YAML"

    ```yaml linenums="1"
    gateways:
      snowflake:
        connection:
          type: snowflake
          account: account
          user: user
          private_key: |
            -----BEGIN PRIVATE KEY-----
            ...
            -----END PRIVATE KEY-----
          private_key_passphrase: supersecret
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="snowflake"),
        gateways={
           "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="user",
                    account="account",
                    private_key="""
                    -----BEGIN PRIVATE KEY-----
                    ...
                    -----END PRIVATE KEY-----""",
                    private_key_passphrase="supersecret",
                ),
            ),
        }
    )
    ```


#### Private Key Base64

This option lets you provide the key as Base64-encoded bytes. **Important:** This is the Base64 encoding of the key bytes themselves, not the PEM file contents. So if you have a PEM file, you'll need to extract and encode the key bytes, not just encode the whole file.

=== "YAML"

    ```yaml linenums="1"
    gateways:
      snowflake:
        connection:
          type: snowflake
          account: account
          user: user
          private_key: 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCvMKgsYzoDMnl7QW9nWTzAMMQToyUTslgKlH9MezcEYUvvCv+hYEsY9YGQ5dhI5MSY1vkQ+Wtqc6KsvJQzMaHDA1W+Z5R/yA/IY+Mp2KqJijQxnp8XjZs1t6Unr0ssL2yBjlk2pNOZX3w4A6B6iwpkqUi/HtqI5t2M15FrUMF3rNcH68XMcDa1gAasGuBpzJtBM0bp4/cHa18xWZZfu3d2d+4CCfYUvE3OYXQXMjJunidnU56NZtYlJcKT8Fmlw16fSFsPAG01JOIWBLJmSMi5qhhB2w90AAq5URuupCbwBKB6KvwzPRWn+fZKGAvvlR7P3CGebwBJEJxnq85MljzRAgMBAAECggEAKXaTpwXJGi6dD+35xvUY6sff8GHhiZrhOYfR5TEYYWIBzc7Fl9UpkPuyMbAkk4QJf78JbdoKcURzEP0E+mTZy0UDyy/Ktr+L9LqnbiUIn8rk9YV8U9/BB2KypQTY/tkuji85sDQsnJU72ioJlldIG3DxdcKAqHwznXz7vvF7CK6rcsz37hC5w7MTtguvtzNyHGkvJ1ZBTHI1vvGR/VQJoSSFkv6nLFs2xl197kuM2x+Ss539Xbg7GGXX90/sgJP+QLyNk6kYezekRt5iCK6n3UxNfEqd0GX03AJ1oVtFM9SLx0RMHiLuXVCKlQLJ1LYf8zOT31yOun6hhowNmHvpLQKBgQDzXGQqBLvVNi9gQzQhG6oWXxdtoBILnGnd8DFsb0YZIe4PbiyoFb8b4tJuGz4GVfugeZYL07I8TsQbPKFH3tqFbx69hENMUOo06PZ4H7phucKk8Er/JHW8dhkVQVg1ttTK8J5kOm+uKjirqN5OkLlUNSSJMblaEr9AHGPmTu21MwKBgQC4SeYzJDvq/RTQk5d7AwVEokgFk95aeyv77edFAhnrD3cPIAQnPlfVyG7RgPA94HrSAQ5Hr0PL2hiQ7OxX1HfP+66FMcTVbZwktYULZuj4NMxJqwxKbCmmzzACiPF0sibg8efGMY9sAmcQRw5JRS2s6FQns1MqeksnjzyMf3196wKBgFf8zJ5AjeT9rU1hnuRliy6BfQf+uueFyuUaZdQtuyt1EAx2KiEvk6QycyCqKtfBmLOhojVued/CHrc2SZ2hnmJmFbgxrN9X1gYBQLOXzRxuPEjENGlhNkxIarM7p/frva4OJ0ZXtm9DBrBR4uaG/urKOAZ+euRtKMa2PQxU9y7vAoGAeZWX4MnZFjIe13VojWnywdNnPPbPzlZRMIdG+8plGyY64Km408NX492271XoKoq9vWug5j6FtiqP5p3JWDD/UyKzg4DQYhdM2xM/UcR1k7wRw9Cr7TXrTPiIrkN3OgyHhgVTavkrrJDxOlYG4ORZPCiTzRWMmwvQJatkwTUjsD0CgYEA8nAWBSis9H8n9aCEW30pGHT8LwqlH0XfXwOTPmkxHXOIIkhNFiZRAzc4NKaefyhzdNlc7diSMFVXpyLZ4K0l5dY1Ou2xRh0W+xkRjjKsMib/s9g/crtam+tXddADJDokLELn5PAMhaHBpti+PpOMGqdI3Wub+5yT1XCXT9aj6yU='
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="snowflake"),
        gateways={
           "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="user",
                    account="account",
                    private_key="MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCvMKgsYzoDMnl7QW9nWTzAMMQToyUTslgKlH9MezcEYUvvCv+hYEsY9YGQ5dhI5MSY1vkQ+Wtqc6KsvJQzMaHDA1W+Z5R/yA/IY+Mp2KqJijQxnp8XjZs1t6Unr0ssL2yBjlk2pNOZX3w4A6B6iwpkqUi/HtqI5t2M15FrUMF3rNcH68XMcDa1gAasGuBpzJtBM0bp4/cHa18xWZZfu3d2d+4CCfYUvE3OYXQXMjJunidnU56NZtYlJcKT8Fmlw16fSFsPAG01JOIWBLJmSMi5qhhB2w90AAq5URuupCbwBKB6KvwzPRWn+fZKGAvvlR7P3CGebwBJEJxnq85MljzRAgMBAAECggEAKXaTpwXJGi6dD+35xvUY6sff8GHhiZrhOYfR5TEYYWIBzc7Fl9UpkPuyMbAkk4QJf78JbdoKcURzEP0E+mTZy0UDyy/Ktr+L9LqnbiUIn8rk9YV8U9/BB2KypQTY/tkuji85sDQsnJU72ioJlldIG3DxdcKAqHwznXz7vvF7CK6rcsz37hC5w7MTtguvtzNyHGkvJ1ZBTHI1vvGR/VQJoSSFkv6nLFs2xl197kuM2x+Ss539Xbg7GGXX90/sgJP+QLyNk6kYezekRt5iCK6n3UxNfEqd0GX03AJ1oVtFM9SLx0RMHiLuXVCKlQLJ1LYf8zOT31yOun6hhowNmHvpLQKBgQDzXGQqBLvVNi9gQzQhG6oWXxdtoBILnGnd8DFsb0YZIe4PbiyoFb8b4tJuGz4GVfugeZYL07I8TsQbPKFH3tqFbx69hENMUOo06PZ4H7phucKk8Er/JHW8dhkVQVg1ttTK8J5kOm+uKjirqN5OkLlUNSSJMblaEr9AHGPmTu21MwKBgQC4SeYzJDvq/RTQk5d7AwVEokgFk95aeyv77edFAhnrD3cPIAQnPlfVyG7RgPA94HrSAQ5Hr0PL2hiQ7OxX1HfP+66FMcTVbZwktYULZuj4NMxJqwxKbCmmzzACiPF0sibg8efGMY9sAmcQRw5JRS2s6FQns1MqeksnjzyMf3196wKBgFf8zJ5AjeT9rU1hnuRliy6BfQf+uueFyuUaZdQtuyt1EAx2KiEvk6QycyCqKtfBmLOhojVued/CHrc2SZ2hnmJmFbgxrN9X1gYBQLOXzRxuPEjENGlhNkxIarM7p/frva4OJ0ZXtm9DBrBR4uaG/urKOAZ+euRtKMa2PQxU9y7vAoGAeZWX4MnZFjIe13VojWnywdNnPPbPzlZRMIdG+8plGyY64Km408NX492271XoKoq9vWug5j6FtiqP5p3JWDD/UyKzg4DQYhdM2xM/UcR1k7wRw9Cr7TXrTPiIrkN3OgyHhgVTavkrrJDxOlYG4ORZPCiTzRWMmwvQJatkwTUjsD0CgYEA8nAWBSis9H8n9aCEW30pGHT8LwqlH0XfXwOTPmkxHXOIIkhNFiZRAzc4NKaefyhzdNlc7diSMFVXpyLZ4K0l5dY1Ou2xRh0W+xkRjjKsMib/s9g/crtam+tXddADJDokLELn5PAMhaHBpti+PpOMGqdI3Wub+5yT1XCXT9aj6yU=",
                ),
            ),
        }
    )
    ```

__Private Key Bytes__

=== "YAML"

    Base64 encode the bytes and follow [Private Key Base64](#private-key-base64) instructions.

=== "Python"

    ```python
    from vulcan.core.config import (
        Config,
        GatewayConfig,
        ModelDefaultsConfig,
        SnowflakeConnectionConfig,
    )

    from cryptography.hazmat.primitives import serialization

    key = """-----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----""".encode()

    p_key= serialization.load_pem_private_key(key, password=None)

    pkb = p_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )

    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="snowflake"),
        gateways={
           "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="user",
                    account="account",
                    private_key=pkb,
                ),
            ),
        }
    )
    ```

When you provide a `private_key`, Vulcan automatically assumes you want to use the `snowflake_jwt` authenticator method. If you need to use a different authenticator, you can specify it explicitly in your connection configuration.

## Configuring Virtual Warehouses

By default, Vulcan uses the warehouse you specified in your gateway connection. But sometimes you might want different models to use different warehouses (maybe some models need more compute power than others). You can override the warehouse for a specific model using `session_properties`:

```sql linenums="1"
MODEL (
  name schema_name.model_name,
  session_properties (
    'warehouse' = TEST_WAREHOUSE,
  ),
);
```

## Custom View and Table types

Snowflake supports several special table and view types that have different characteristics. Vulcan lets you use these by specifying them in your model definition. You can apply these to either the physical layer (the actual table) or the virtual layer (the view that exposes it) using `physical_properties` and `virtual_properties`. Here are the options:

### Secure Views

Secure views in Snowflake hide the underlying query logic from users who don't have access. This is useful for protecting sensitive business logic. To create a secure view, set `creatable_type` to `SECURE` in the `virtual_properties`:

```sql linenums="1"
MODEL (
  name schema_name.model_name,
  virtual_properties (
      creatable_type = SECURE
  )
);

SELECT a FROM schema_name.model_b;
```

### Transient Tables

Transient tables don't have the same data retention guarantees as regular tables, but they're cheaper and perfect for temporary or intermediate data. To use a transient table, set `creatable_type` to `TRANSIENT` in the `physical_properties`:

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

Iceberg tables are great for data lake architectures. They store data in an open format that multiple systems can read, which is perfect if you're using other tools alongside Snowflake.

Before you can create Iceberg tables, you'll need to set up an [External Volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume) in Snowflake to store the table data.

Once that's done, you can create an Iceberg-backed model like this:

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

If you're creating lots of Iceberg tables, you probably don't want to repeat `catalog` and `external_volume` on every model. You've got a couple of options:

1. **Set defaults in Snowflake** - Configure default catalog and external volume at the account, database, or schema level. Check out Snowflake's docs on [configuring a default catalog](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-catalog-integration#set-a-default-catalog-at-the-account-database-or-schema-level) and [configuring a default external volume](https://docs.snowflake.com/en/user-guide/tables-iceberg-configure-external-volume#set-a-default-external-volume-at-the-account-database-or-schema-level).

<<<<<<< Updated upstream
Alternatively you can also use [model defaults](../../../../references/model_configuration.md#model-defaults) to set defaults at the Vulcan level instead.
=======
2. **Set defaults in Vulcan** - Use [model defaults](../../guides-old/configuration.md#model-defaults) to set these values once and have them apply to all your models automatically.
>>>>>>> Stashed changes

Snowflake supports a bunch of [optional properties](https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-snowflake#optional-parameters) for Iceberg tables. You can use any of them by adding them to `physical_properties`. For example:

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

    We recommend using `catalog = 'snowflake'` (Snowflake's internal catalog) as your default. Here's why: Vulcan needs to write to the tables it manages, and Snowflake [doesn't support writing](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-options) to Iceberg tables that are configured under external catalogs.

<<<<<<< Updated upstream
    You can however still reference a table from an external catalog in your model as a normal [external table](../../../../components/model/types/external_models.md).
=======
    That said, you can still *read* from tables in external catalogs by referencing them as [external models](configurations/components/model/types/external_models.md). You just can't use Vulcan to manage them.
>>>>>>> Stashed changes

## Troubleshooting

### Frequent Authentication Prompts

If you're using Multi-Factor Authentication (MFA) or other security features with Snowflake, you might find yourself getting prompted for authentication over and over again when running Vulcan commands. This usually happens when your Snowflake account isn't configured to issue short-lived tokens that can be cached.

The good news is that Snowflake supports token caching, which can dramatically reduce the number of prompts you see. Here's where to learn more:

- **General authentication caching**: Check out Snowflake's [Connection Caching Documentation](https://docs.snowflake.com/en/user-guide/admin-security-fed-auth-use#using-connection-caching-to-minimize-the-number-of-prompts-for-authentication-optional)
- **MFA-specific caching**: See the [MFA Token Caching Documentation](https://docs.snowflake.com/en/user-guide/security-mfa#using-mfa-token-caching-to-minimize-the-number-of-prompts-during-authentication-optional)

Once you enable token caching in your Snowflake account, Vulcan will be able to reuse tokens and you won't be prompted as often.
