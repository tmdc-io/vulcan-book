# Scheduling guide

Vulcan offers a built-in scheduler for scheduling model evaluation:

* Using [Vulcan's built-in scheduler](#built-in-scheduler)

## Built-in scheduler

Vulcan includes a built-in scheduler that schedules model evaluation without any additional tools or dependencies. It provides all the functionality needed to use Vulcan in production.

By default, the scheduler stores your Vulcan project's state (information about models, data, and run history) in the SQL engine used to execute your models. Some engines, such as BigQuery, are not optimized for the transactions the scheduler executes to store state, which may degrade the scheduler's performance.

When running the scheduler in production, we recommend evaluating its performance with your SQL engine. If you observe degraded performance, consider providing the scheduler its own transactional database such as PostgreSQL to improve performance. See the [connections guide](./connections.md#state-connection) for more information on providing a separate database/engine for the scheduler.

To perform model evaluation using the built-in scheduler, run the following command:
```bash
vulcan run
```

The command above will automatically detect missing intervals for all models in the current project and then evaluate them:
```bash
$ vulcan run

All model batches have been executed successfully

vulcan_example.example_incremental_model ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 1/1 • 0:00:00
       vulcan_example.example_full_model ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 1/1 • 0:00:00
```

**Note:** The `vulcan run` command performs model evaluation based on the missing data intervals identified at the time of running. It does not run continuously, and will exit once evaluation is complete. You must run this command periodically with a cron job, a CI/CD tool like Jenkins, or in a similar fashion.
