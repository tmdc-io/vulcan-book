# Notifications

Want to know when your pipeline finishes? Or when something goes wrong? Vulcan can send notifications via Slack or email so you don't have to constantly check on things. This page shows you how to set it all up.

## Notification targets

Notifications are configured using "notification targets." You define these in your project's [configuration](../../references/configuration.md) file, and you can set up multiple targets if you want different people or channels to get different notifications.

You can configure both global notifications (that go to everyone) and user-specific notifications (that only go to specific people). By default, notifications are sent for all environments, but you can override this for development work (more on that [below](#notifications-during-development)).

<<<<<<< Updated upstream
[Audit](../../components/audits/audits.md) failure notifications can be sent for specific models if five conditions are met:
=======
There's one special case: audit failure notifications can be targeted to specific model owners. This is super useful because the person who owns a model probably wants to know if their audits are failing. For this to work, five things need to be true:
>>>>>>> Stashed changes

1. The model has an `owner` field set
2. The model has one or more audits defined
3. The owner has a user-specific notification target configured
4. The owner's notification target includes audit failure events in `notify_on`
5. The audit fails in the `prod` environment

When all of these are true, the model owner gets notified about the failure. Pretty neat, right?

There are three types of notification target, corresponding to the two [Slack notification methods](#slack-notifications) and [email notification](#email-notifications). They are specified in either a specific user's `notification_targets` key or the top-level `notification_targets` configuration key.

This example shows the location of both user-specific and global notification targets:

=== "YAML"

    ```yaml linenums="1"
    # User notification targets
    users:
      - username: User1
        ...
        notification_targets:
          - notification_target_1
            ...
          - notification_target_2
            ...
      - username: User2
        ...
        notification_targets:
          - notification_target_1
            ...
          - notification_target_2
            ...

    # Global notification targets
    notification_targets:
      - notification_target_1
        ...
      - notification_target_2
        ...
    ```

=== "Python"

    ```python linenums="1"
    config = Config(
        ...,
        # User notification targets
        users=[
            User(
                username="User1",
                notification_targets=[
                    notification_target_1(...),
                    notification_target_2(...),
                ],
            ),
            User(
                username="User2",
                notification_targets=[
                    notification_target_1(...),
                    notification_target_2(...),
                ],
            )
        ],

        # Global notification targets
        notification_targets=[
            notification_target_1(...),
            notification_target_2(...),
        ],
        ...
    )
    ```

### Notifications During Development

Here's a problem: when you're developing and testing, you might run plans and runs over and over again. If notifications are enabled, you (and your team) will get bombarded with notifications for every test run. That gets annoying fast!

Vulcan can help with this. If you set the top-level `username` configuration key, only that user's notification targets will receive notifications. Everyone else's targets will be silenced. This is perfect for development work.

You can set `username` in either your project's config file or in a machine-specific config file at `~/.vulcan`. The machine-specific file is handy if you have a dedicated development machine and want to automatically silence notifications there without affecting your project config.

This example stops all notifications other than those for `User1`:

=== "YAML"

    ```yaml linenums="1" hl_lines="1-2"
    # Top-level `username` key: only notify User1
    username: User1
    # User1 notification targets
    users:
      - username: User1
        ...
        notification_targets:
          - notification_target_1
            ...
          - notification_target_2
            ...
    ```

=== "Python"

    ```python linenums="1" hl_lines="3-4"
    config = Config(
        ...,
        # Top-level `username` key: only notify User1
        username="User1",
        users=[
            User(
                # User1 notification targets
                username="User1",
                notification_targets=[
                    notification_target_1(...),
                    notification_target_2(...),
                ],
            ),
        ]
    )
    ```

## Vulcan Event Types

Vulcan can notify you about several different events. You choose which ones you care about by listing them in the notification target's `notify_on` field.

<<<<<<< Updated upstream
Notifications are supported for [`plan` application](../../guides/plan.md) start/end/failure, [`run`](../../getting_started/cli.md#run) start/end/failure, and [`audit`](../../components/audits/audits.md) failures.
=======
Here are the events you can get notified about:
>>>>>>> Stashed changes

- **Plan events**: When a [`plan`](configurations/guides/plan.md) starts, finishes, or fails
- **Run events**: When a [`run`](configurations/getting_started/cli.md#run) starts, finishes, or fails  
- **Audit failures**: When an [`audit`](configurations/components/audits/audits.md) fails

For start/end events, the notification includes the target environment name so you know which environment the event happened in. For failure events, you'll get the actual error message or exception, which helps with debugging.

This table lists each event, its associated `notify_on` value, and its notification message:

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

## Slack Notifications

Vulcan supports two ways to send Slack notifications:

1. **Slack Webhooks** - Simple and easy to set up. Can send messages to channels, but can't message individual users directly.
2. **Slack Web API** - More flexible. Can send to channels or direct message specific users. Requires an API token.

Let's look at both options:

### Webhook Configuration

Slack webhooks are the simplest way to get started. When you [create an incoming webhook](https://api.slack.com/messaging/webhooks) in Slack, you get a unique URL that's tied to a specific channel. Vulcan just sends a JSON payload to that URL, and Slack posts it to the channel.

Here's an example configuration. Notice we're using an environment variable for the webhook URL, this keeps secrets out of your config file:

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
    notification_targets=[
        SlackWebhookNotificationTarget(
            notify_on=["apply_start", "apply_failure", "run_start"],
            url=os.getenv("SLACK_WEBHOOK_URL"),
        )
    ]
    ```

### API Configuration

If you need to message individual users (not just channels), you'll need to use the Slack Web API. This requires an API token, but the good news is that one token can be used for multiple notification targets, so you can set up different channels or users without creating multiple tokens.

To get a token, check out [Slack's official documentation](https://api.slack.com/tutorials/tracks/getting-a-token). Once you have it, configure it like this (again, using an environment variable to keep it secure):

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
    notification_targets=[
        SlackApiNotificationTarget(
            notify_on=["apply_start", "apply_end", "audit_failure"],
            token=os.getenv("SLACK_API_TOKEN"),
            channel="UXXXXXXXXX",  # Channel or a user's Slack member ID
        )
    ]
    ```

## Email Notifications

If Slack isn't your thing, Vulcan can also send email notifications. You'll need to configure SMTP settings (host, user, password) and specify who should receive the emails. One notification target can send to multiple recipients, which is handy for team-wide notifications.

Here's an example that sends an email to the data team whenever a run fails. As always, we're using environment variables for sensitive information:

=== "YAML"

    ```yaml linenums="1"
    notification_targets:
      - type: smtp
        notify_on:
          - run_failure
        host: "{{ env_var('SMTP_HOST') }}"
        user: "{{ env_var('SMTP_USER') }}"
        password: "{{ env_var('SMTP_PASSWORD') }}"
        sender: sushi@example.com
        recipients:
          - data-team@example.com
    ```

=== "Python"

    ```python linenums="1"
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

## Advanced Usage

### Overriding Notification Targets

If you're using a Python configuration file, you can create custom notification targets that send exactly the messages you want. This is useful if you need to format messages differently, add extra context, or integrate with other systems.

To create a custom notification target, subclass one of the built-in target classes (`SlackWebhookNotificationTarget`, `SlackApiNotificationTarget`, or `BasicSMTPNotificationTarget`). You can see the full class definitions [on Github](https://github.com/TobikoData/vulcan/blob/main/vulcan/core/notification_target.py).

Each notification target class inherits from `BaseNotificationTarget`, which provides a `notify` function for each event type. Here's what information is available to each function:

| Function name        | Contextual information           |
| -------------------- | -------------------------------- |
| notify_apply_start   | Environment name: `env`          |
| notify_apply_end     | Environment name: `env`          |
| notify_apply_failure | Exception stack trace: `exc`     |
| notify_run_start     | Environment name: `env`          |
| notify_run_end       | Environment name: `env`          |
| notify_run_failure   | Exception stack trace: `exc`     |
| notify_audit_failure | Audit error trace: `audit_error` |

Here's a practical example. Let's say you want to include log file contents in failure notifications to make debugging easier. You can create a custom notification target that reads the log file and appends it to the error message:

=== "Python"

```python
from vulcan.core.notification_target import BasicSMTPNotificationTarget

class CustomSMTPNotificationTarget(BasicSMTPNotificationTarget):
    def notify_run_failure(self, exc: str) -> None:
        with open("/home/vulcan/vulcan.log", "r", encoding="utf-8") as f:
            msg = f"{exc}\n\nLogs:\n{f.read()}"
        super().notify_run_failure(msg)
```

Use this new class by specifying it as a notification target in the configuration file:

=== "Python"

    ```python linenums="1" hl_lines="2"
    notification_targets=[
        CustomSMTPNotificationTarget(
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