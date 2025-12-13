# Variables

Vulcan can access environment variables during configuration, which enables approaches like storing passwords/secrets outside the configuration file and changing configuration parameters dynamically based on which user is running Vulcan.

You can specify environment variables in the configuration file or by storing them in a `.env` file.

## .env files

Vulcan automatically loads environment variables from a `.env` file in your project directory. This provides a convenient way to manage environment variables without having to set them in your shell.

Create a `.env` file in your project root with key-value pairs:

```bash
# .env file
SNOWFLAKE_PW=my_secret_password
S3_BUCKET=s3://my-data-bucket/warehouse
DATABASE_URL=postgresql://user:pass@localhost/db

# Override specific Vulcan configuration values
VULCAN__DEFAULT_GATEWAY=production
VULCAN__MODEL_DEFAULTS__DIALECT=snowflake
```

See the [overrides](#overrides) section for a detailed explanation of how these are defined.

The rest of the `.env` file variables can be used in your configuration files with `{{ env_var('VARIABLE_NAME') }}` syntax in YAML or accessed via `os.environ['VARIABLE_NAME']` in Python.

### Custom dot env file location and name

By default, Vulcan loads `.env` files from each project directory. However, you can specify a custom path using the `--dotenv` CLI flag directly when running a command:

```bash
vulcan --dotenv /path/to/custom/.env plan
```

!!! note
    The `--dotenv` flag is a global option and must be placed **before** the subcommand (e.g. `plan`, `run`), not after.

Alternatively, you can export the `VULCAN_DOTENV_PATH` environment variable once, to persist a custom path across all subsequent commands in your shell session:

```bash
export VULCAN_DOTENV_PATH=/path/to/custom/.custom_env
vulcan plan
vulcan run
```

**Important considerations:**
- Add `.env` to your `.gitignore` file to avoid committing sensitive information
- Vulcan will only load the `.env` file if it exists in the project directory (unless a custom path is specified)
- When using a custom path, that specific file takes precedence over any `.env` file in the project directory.

## Configuration file

This section demonstrates using environment variables in YAML and Python configuration files.

The examples specify a Snowflake connection whose password is stored in an environment variable `SNOWFLAKE_PW`.

=== "YAML"

    Specify environment variables in a YAML configuration with the syntax `{{ env_var('<ENVIRONMENT VARIABLE NAME>') }}`. Note that the environment variable name is contained in single quotes.

    Access the `SNOWFLAKE_PW` environment variable in a Snowflake connection configuration like this:

    ```yaml linenums="1"
    gateways:
      my_gateway:
        connection:
          type: snowflake
          user: <username>
          password: {{ env_var('SNOWFLAKE_PW') }}
          account: <account>
    ```

=== "Python"

    Python accesses environment variables via the `os` library's `environ` dictionary.

    Access the `SNOWFLAKE_PW` environment variable in a Snowflake connection configuration like this:

    ```python linenums="1"
    import os
    from vulcan.core.config import (
        Config,
        ModelDefaultsConfig,
        GatewayConfig,
        SnowflakeConnectionConfig
    )

    config = Config(
        model_defaults=ModelDefaultsConfig(dialect=<dialect>),
        gateways={
            "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user=<username>,
                    password=os.environ['SNOWFLAKE_PW'],
                    account=<account>,
                ),
            ),
        }
    )
    ```

## Default target environment

The Vulcan `plan` command acts on the `prod` environment by default (i.e., `vulcan plan` is equivalent to `vulcan plan prod`).

In some organizations, users never run plans directly against `prod` - they do all Vulcan work in a development environment unique to them. In a standard Vulcan configuration, this means they need to include their development environment name every time they issue the `plan` command (e.g., `vulcan plan dev_tony`).

If your organization works like this, it may be convenient to change the `plan` command's default environment from `prod` to each user's development environment. That way people can issue `vulcan plan` without typing the environment name every time.

The Vulcan configuration `user()` function returns the name of the user currently logged in and running Vulcan. It retrieves the username from system environment variables like `USER` on MacOS/Linux or `USERNAME` on Windows.

Call `user()` inside Jinja curly braces with the syntax `{{ user() }}`, which allows you to combine the user name with a prefix or suffix.

The example configuration below constructs the environment name by appending the username to the end of the string `dev_`. If the user running Vulcan is `tony`, the default target environment when they run Vulcan will be `dev_tony`. In other words, `vulcan plan` will be equivalent to `vulcan plan dev_tony`.

=== "YAML"

    Default target environment is `dev_` combined with the username running Vulcan.

    ```yaml
    default_target_environment: dev_{{ user() }}
    ```

=== "Python"

    Default target environment is `dev_` combined with the username running Vulcan.

    Retrieve the username with the `getpass.getuser()` function, and combine it with `dev_` in a Python f-string.

    ```python linenums="1" hl_lines="1 17"
    import getpass
    import os
    from vulcan.core.config import (
        Config,
        ModelDefaultsConfig,
        GatewayConfig,
        SnowflakeConnectionConfig
    )

    config = Config(
        model_defaults=ModelDefaultsConfig(dialect="duckdb"),
        gateways={
            "my_gateway": GatewayConfig(
                connection=DuckDBConnectionConfig(),
            ),
        },
        default_target_environment=f"dev_{getpass.getuser()}",
    )
    ```

## Overrides

Environment variables have the highest precedence among configuration methods. They will automatically override configuration file specifications if they follow a specific naming structure.

The structure is based on the names of the configuration fields, with double underscores `__` between the field names. The environment variable name must begin with `VULCAN__`, followed by the YAML field names starting at the root and moving downward in the hierarchy.

For example, we can override the password specified in a Snowflake connection. This is the YAML specification contained in our configuration file, which specifies a password `dummy_pw`:

```yaml linenums="1"
gateways:
  my_gateway:
    connection:
      type: snowflake
      user: <username>
      password: dummy_pw
      account: <account>
```

We can override the `dummy_pw` value with the true password `real_pw` by creating the environment variable. This example demonstrates creating the variable with the bash `export` function:

```bash
$ export VULCAN__GATEWAYS__MY_GATEWAY__CONNECTION__PASSWORD="real_pw"
```

After the initial string `VULCAN__`, the environment variable name components move down the key hierarchy in the YAML specification: `GATEWAYS` --> `MY_GATEWAY` --> `CONNECTION` --> `PASSWORD`.

