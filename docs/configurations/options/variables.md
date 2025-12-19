# Variables

This page covers environment variables and configuration overrides for your Vulcan project.

## Environment Variables

Vulcan can access environment variables during configuration, enabling you to store secrets outside configuration files and dynamically change settings based on the user running Vulcan.

### Using .env Files

Vulcan automatically loads environment variables from a `.env` file in your project directory:

```bash
# .env file
SNOWFLAKE_PW=my_secret_password
S3_BUCKET=s3://my-data-bucket/warehouse
DATABASE_URL=postgresql://user:pass@localhost/db

# Override Vulcan configuration values
VULCAN__DEFAULT_GATEWAY=production
VULCAN__MODEL_DEFAULTS__DIALECT=snowflake
```

!!! warning "Security"
    Add `.env` to your `.gitignore` file to avoid committing sensitive information.

### Custom .env File Location

Specify a custom path using the `--dotenv` CLI flag:

```bash
vulcan --dotenv /path/to/custom/.env plan
```

Or set the `VULCAN_DOTENV_PATH` environment variable:

```bash
export VULCAN_DOTENV_PATH=/path/to/custom/.custom_env
vulcan plan
```

!!! note
    The `--dotenv` flag must be placed **before** the subcommand (e.g., `plan`, `run`).

### Accessing Variables in Configuration

=== "YAML"

    Use `{{ env_var('VARIABLE_NAME') }}` syntax:

    ```yaml linenums="1"
    gateways:
      my_gateway:
        connection:
          type: snowflake
          user: admin
          password: "{{ env_var('SNOWFLAKE_PW') }}"
          account: my_account
    ```

=== "Python"

    Use `os.environ`:

    ```python linenums="1"
    import os
    from vulcan.core.config import Config, GatewayConfig, SnowflakeConnectionConfig

    config = Config(
        gateways={
            "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    user="admin",
                    password=os.environ['SNOWFLAKE_PW'],
                    account="my_account",
                ),
            ),
        }
    )
    ```

## Configuration Overrides

Environment variables have the **highest precedence** and will override configuration file values if they follow the `VULCAN__` naming convention.

### Override Naming Structure

Use double underscores `__` to navigate the configuration hierarchy:

```
VULCAN__<ROOT_KEY>__<NESTED_KEY>__<FIELD>=value
```

**Example:** Override a gateway connection password:

```yaml linenums="1"
# config.yaml
gateways:
  my_gateway:
    connection:
      type: snowflake
      password: dummy_pw  # This will be overridden
```

```bash
# Override with environment variable
export VULCAN__GATEWAYS__MY_GATEWAY__CONNECTION__PASSWORD="real_pw"
```

## Dynamic Configuration

### User-based Target Environment

Use the `{{ user() }}` function to dynamically set configuration based on the current user:

=== "YAML"

    ```yaml
    # Each user gets their own dev environment
    default_target_environment: dev_{{ user() }}
    ```

=== "Python"

    ```python linenums="1"
    import getpass
    from vulcan.core.config import Config

    config = Config(
        default_target_environment=f"dev_{getpass.getuser()}",
    )
    ```

This allows running `vulcan plan` instead of `vulcan plan dev_username`.
