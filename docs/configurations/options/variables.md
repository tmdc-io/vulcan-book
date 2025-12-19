# Variables

Environment variables and configuration overrides let you keep secrets out of your config files and customize settings without editing code. This page shows you how to use them effectively.

## Environment Variables

Environment variables are the best way to handle secrets and configuration that changes between environments. Vulcan can read environment variables when it loads your configuration, so you can keep passwords, API keys, and other sensitive information out of your config files. You can also use them to change settings based on who's running Vulcan or what environment they're in.

### Using .env Files

The easiest way to manage environment variables is with a `.env` file in your project directory. Vulcan automatically loads it when it starts, so you don't have to remember to export variables manually.

Here's what a `.env` file looks like:

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
    **Important:** Make sure `.env` is in your `.gitignore` file! You don't want to accidentally commit passwords and API keys to your repository. This is a common mistake that can cause serious security issues.

### Custom .env File Location

By default, Vulcan looks for a `.env` file in your project root. But sometimes you might want to use a different file or location. You've got two options:

**Option 1: Use the `--dotenv` flag**
```bash
vulcan --dotenv /path/to/custom/.env plan
```

**Option 2: Set the `VULCAN_DOTENV_PATH` environment variable**
```bash
export VULCAN_DOTENV_PATH=/path/to/custom/.custom_env
vulcan plan
```

!!! note
    If you're using the `--dotenv` flag, make sure it comes **before** the subcommand (like `plan` or `run`). Otherwise Vulcan won't find it!

### Accessing Variables in Configuration

To use environment variables in your config, you'll use different syntax depending on whether you're using YAML or Python:

=== "YAML"

    In YAML configs, use the `{{ env_var('VARIABLE_NAME') }}` syntax. This is a Jinja2 template expression that gets evaluated when Vulcan loads your config:

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

    In Python configs, you can use `os.environ` directly. This gives you more flexibility if you need to do any processing on the variable:

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

Here's a powerful feature: environment variables can override any value in your configuration file, and they have the **highest precedence**. This means you can change settings without editing your config files at all.

To use this feature, name your environment variable using the `VULCAN__` prefix and double underscores (`__`) to navigate the configuration hierarchy.

### Override Naming Structure

The pattern is straightforward: start with `VULCAN__`, then use double underscores to go deeper into nested config:

```
VULCAN__<ROOT_KEY>__<NESTED_KEY>__<FIELD>=value
```

**Example:** Let's say you want to override a gateway password. In your config file, you might have:

```yaml linenums="1"
# config.yaml
gateways:
  my_gateway:
    connection:
      type: snowflake
      password: dummy_pw  # This will be overridden
```

But then you set an environment variable:

```bash
# Override with environment variable
export VULCAN__GATEWAYS__MY_GATEWAY__CONNECTION__PASSWORD="real_pw"
```

Now when Vulcan loads the config, it will use `real_pw` instead of `dummy_pw`. This is super useful for overriding settings in different environments without changing your config files.

## Dynamic Configuration

### User-based Target Environment

Sometimes you want each developer to have their own environment. Instead of having everyone remember to specify their environment name every time, you can make it automatic based on who's running Vulcan.

Use the `{{ user() }}` function (in YAML) or `getpass.getuser()` (in Python) to get the current system user:

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

Now when Alice runs `vulcan plan`, it automatically targets `dev_alice`. When Bob runs it, it targets `dev_bob`. No need to remember environment names, just run `vulcan plan` and it works!
