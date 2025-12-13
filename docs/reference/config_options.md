# Configuration Options

This page provides detailed configuration options for specific Vulcan features. For a complete list of all configuration parameters, see the [configuration reference](./configuration.md). For guidance on how to configure Vulcan, see the [configuration guide](../guides/configuration.md).

## Available Configuration Options

Vulcan provides specialized configuration options for various features. Each option can be configured in your project's `config.yaml` or `config.py` file.

### Notifications

Configure how Vulcan sends notifications via Slack or email when certain events occur. Notifications can be set up globally or per-user, and support multiple notification targets.

**Configuration options:**
- User-specific and global notification targets
- Slack webhook and API configurations
- Email (SMTP) configuration
- Event types and triggers
- Development mode overrides

See the [notifications configuration reference](./config_options/notifications.md) for detailed configuration syntax and examples.

### Linters

Configure Vulcan's linting system to automatically validate model definitions and enforce code quality standards. Linting rules can be enabled globally or per-model, with options for warnings vs errors.

**Configuration options:**
- Enable/disable linting
- Specify which rules to apply
- Configure rule violation behavior (error vs warning)
- Ignore specific rules globally or per-model
- Built-in and custom rules

See the [linter configuration reference](./config_options/linters.md) for detailed configuration syntax and examples.

## Related Configuration

For other configuration topics, see:

- **[Variables](./variables.md)** - Environment variables and configuration overrides
- **[Model Defaults](./model_defaults.md)** - Default settings for all models
- **[Before_all and After_all](./before_all_and_after_all.md)** - Pre/post execution statements
- **[Configuration Reference](./configuration.md)** - Complete list of all configuration parameters
- **[Model Configuration](./model_configuration.md)** - Model-specific configuration options

## Configuration File Structure

Configuration options are specified in your project's `config.yaml` or `config.py` file. Here's a basic structure showing where these options fit:

=== "YAML"

    ```yaml linenums="1"
    # Project-level configuration
    project: my_project
    cache_dir: .cache

    # Model defaults
    model_defaults:
      dialect: snowflake
      owner: data-team

    # Notification configuration
    notification_targets:
      - type: slack_webhook
        notify_on:
          - apply_failure
        url: "{{ env_var('SLACK_WEBHOOK_URL') }}"

    # Linter configuration
    linter:
      enabled: true
      rules: ["noselectstar", "nomissingaudits"]

    # Gateway configuration
    gateways:
      my_gateway:
        connection:
          type: snowflake
          # ... connection details
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, ModelDefaultsConfig, LinterConfig
    from vulcan.core.notification_target import SlackWebhookNotificationTarget
    import os

    config = Config(
        project="my_project",
        cache_dir=".cache",
        model_defaults=ModelDefaultsConfig(
            dialect="snowflake",
            owner="data-team",
        ),
        notification_targets=[
            SlackWebhookNotificationTarget(
                notify_on=["apply_failure"],
                url=os.getenv("SLACK_WEBHOOK_URL"),
            )
        ],
        linter=LinterConfig(
            enabled=True,
            rules=["noselectstar", "nomissingaudits"],
        ),
        gateways={
            "my_gateway": GatewayConfig(
                connection=SnowflakeConnectionConfig(
                    # ... connection details
                ),
            ),
        },
    )
    ```

## Configuration Precedence

Configuration values are resolved in the following order (highest to lowest precedence):

1. **Environment variables** - Variables following the `VULCAN__` naming convention
2. **User configuration** - `~/.vulcan/config.yaml` or `~/.vulcan/config.py`
3. **Project configuration** - `config.yaml` or `config.py` in your project directory

For more information about configuration precedence and environment variables, see the [variables reference](./variables.md).

