# Notifications Configuration

Vulcan can send notifications via Slack or email when certain events occur. Notifications are configured in your project's configuration file (`config.yml` or `config.py`).

## Notification Targets

Notifications are configured with `notification targets`. Targets are specified in a project's configuration file, and multiple targets can be specified for a project.

A project may specify both global and user-specific notifications. Each target's notifications will be sent for all instances of each event type (e.g., notifications for `run` will be sent for *all* of the project's environments), with exceptions for audit failures and when an override is configured for development.

### User-specific and Global Targets

There are three types of notification target, corresponding to the two Slack notification methods and email notification. They are specified in either a specific user's `notification_targets` key or the top-level `notification_targets` configuration key.

=== "YAML"

    ```yaml linenums="1"
    # User notification targets
    users:
      - username: User1
        notification_targets:
          - type: slack_webhook
            notify_on:
              - apply_start
              - apply_failure
            url: "{{ env_var('SLACK_WEBHOOK_URL') }}"
      - username: User2
        notification_targets:
          - type: slack_api
            notify_on:
              - audit_failure
            token: "{{ env_var('SLACK_API_TOKEN') }}"
            channel: "UXXXXXXXXX"

    # Global notification targets
    notification_targets:
      - type: smtp
        notify_on:
          - run_failure
        host: "{{ env_var('SMTP_HOST') }}"
        user: "{{ env_var('SMTP_USER') }}"
        password: "{{ env_var('SMTP_PASSWORD') }}"
        sender: notifications@example.com
        recipients:
          - data-team@example.com
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.config import Config, User
    from vulcan.core.notification_target import (
        SlackWebhookNotificationTarget,
        SlackApiNotificationTarget,
        BasicSMTPNotificationTarget
    )
    import os

    config = Config(
        # User notification targets
        users=[
            User(
                username="User1",
                notification_targets=[
                    SlackWebhookNotificationTarget(
                        notify_on=["apply_start", "apply_failure"],
                        url=os.getenv("SLACK_WEBHOOK_URL"),
                    )
                ],
            ),
            User(
                username="User2",
                notification_targets=[
                    SlackApiNotificationTarget(
                        notify_on=["audit_failure"],
                        token=os.getenv("SLACK_API_TOKEN"),
                        channel="UXXXXXXXXX",
                    )
                ],
            )
        ],
        # Global notification targets
        notification_targets=[
            BasicSMTPNotificationTarget(
                notify_on=["run_failure"],
                host=os.getenv("SMTP_HOST"),
                user=os.getenv("SMTP_USER"),
                password=os.getenv("SMTP_PASSWORD"),
                sender="notifications@example.com",
                recipients=["data-team@example.com"],
            )
        ],
    )
    ```

## Notifications During Development

Events triggering notifications may be executed repeatedly during code development. To prevent excessive notification, Vulcan can stop all but one user's notification targets.

Specify the top-level `username` configuration key with a value also present in a user-specific notification target's `username` key to only notify that user. This key can be specified in either the project configuration file or a machine-specific configuration file located in `~/.vulcan`.

=== "YAML"

    ```yaml linenums="1"
    # Top-level `username` key: only notify User1
    username: User1
    users:
      - username: User1
        notification_targets:
          - type: slack_webhook
            notify_on:
              - apply_start
            url: "{{ env_var('SLACK_WEBHOOK_URL') }}"
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        username="User1",
        users=[
            User(
                username="User1",
                notification_targets=[
                    SlackWebhookNotificationTarget(
                        notify_on=["apply_start"],
                        url=os.getenv("SLACK_WEBHOOK_URL"),
                    )
                ],
            ),
        ]
    )
    ```

## Event Types

Vulcan notifications are triggered by events. The events that should trigger a notification are specified in the notification target's `notify_on` field.

Notifications are supported for plan application start/end/failure, run start/end/failure, and audit failures.

| Event                         | `notify_on` Key Value  | Notification message                                     |
| ----------------------------- | ---------------------- | -------------------------------------------------------- |
| Plan application start        | apply_start            | "Plan apply started for environment `{environment}`."    |
| Plan application end          | apply_end              | "Plan apply finished for environment `{environment}`."   |
| Plan application failure      | apply_failure          | "Failed to apply plan.\n{exception}"                     |
| Vulcan run start             | run_start              | "Vulcan run started for environment `{environment}`."   |
| Vulcan run end               | run_end                | "Vulcan run finished for environment `{environment}`."  |
| Vulcan run failure           | run_failure            | "Failed to run Vulcan.\n{exception}"                    |
| Audit failure                 | audit_failure          | "{audit_error}"                                          |

Any combination of these events can be specified in a notification target's `notify_on` field.

## Slack Webhook Configuration

Vulcan uses Slack's "Incoming Webhooks" for webhook notifications. When you [create an incoming webhook](https://api.slack.com/messaging/webhooks) in Slack, you will receive a unique URL associated with a specific Slack channel.

=== "YAML"

    ```yaml linenums="1"
    notification_targets:
      - type: slack_webhook
        notify_on:
          - apply_start
          - apply_failure
          - run_start
        url: "{{ env_var('SLACK_WEBHOOK_URL') }}"
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.notification_target import SlackWebhookNotificationTarget
    import os

    notification_targets=[
        SlackWebhookNotificationTarget(
            notify_on=["apply_start", "apply_failure", "run_start"],
            url=os.getenv("SLACK_WEBHOOK_URL"),
        )
    ]
    ```

## Slack API Configuration

If you want to notify users, you can use the Slack API notification target. This requires a Slack API token, which can be used for multiple notification targets with different channels or users. See [Slack's official documentation](https://api.slack.com/tutorials/tracks/getting-a-token) for information on getting an API token.

=== "YAML"

    ```yaml linenums="1"
    notification_targets:
      - type: slack_api
        notify_on:
          - apply_start
          - apply_end
          - audit_failure
        token: "{{ env_var('SLACK_API_TOKEN') }}"
        channel: "UXXXXXXXXX"  # Channel or a user's Slack member ID
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.notification_target import SlackApiNotificationTarget
    import os

    notification_targets=[
        SlackApiNotificationTarget(
            notify_on=["apply_start", "apply_end", "audit_failure"],
            token=os.getenv("SLACK_API_TOKEN"),
            channel="UXXXXXXXXX",  # Channel or a user's Slack member ID
        )
    ]
    ```

## Email Configuration

Vulcan supports notifications via email. The notification target specifies the SMTP host, user, password, and sender address. A target may notify multiple recipient email addresses.

=== "YAML"

    ```yaml linenums="1"
    notification_targets:
      - type: smtp
        notify_on:
          - run_failure
        host: "{{ env_var('SMTP_HOST') }}"
        user: "{{ env_var('SMTP_USER') }}"
        password: "{{ env_var('SMTP_PASSWORD') }}"
        sender: notifications@example.com
        recipients:
          - data-team@example.com
    ```

=== "Python"

    ```python linenums="1"
    from vulcan.core.notification_target import BasicSMTPNotificationTarget
    import os

    notification_targets=[
        BasicSMTPNotificationTarget(
            notify_on=["run_failure"],
            host=os.getenv("SMTP_HOST"),
            user=os.getenv("SMTP_USER"),
            password=os.getenv("SMTP_PASSWORD"),
            sender="notifications@example.com",
            recipients=[
                "data-team@example.com",
            ],
        )
    ]
    ```

## Audit Failure Notifications

Audit failure notifications can be sent for specific models if five conditions are met:

1. A model's `owner` field is populated
2. The model executes one or more audits
3. The owner has a user-specific notification target configured
4. The owner's notification target `notify_on` key includes audit failure events
5. The audit fails in the `prod` environment

When those conditions are met, the audit owner will be notified if their audit failed in the `prod` environment.

