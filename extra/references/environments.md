# Environments

Environments are isolated namespaces for testing and previewing changes.

Vulcan distinguishes between production and development environments. Only the environment named `prod` is treated as production. All other environments are development environments.

[Models](../../components/model/overview.md) in development environments get a suffix appended to the schema portion of their names. For example, to access data for a model named `db.model_a` in the `my_dev` environment, use `db__my_dev.model_a` in queries. Models in production use their original names.

## Why use environments

Data pipelines grow more complex over time. Assessing the impact of local changes becomes difficult. You may not know all downstream consumers or may underestimate a change's impact.

You need to test model changes using production dependencies and data without affecting existing production datasets or pipelines. Recreating the entire data warehouse would show the full impact, but it's expensive and time-consuming.

Vulcan environments create lightweight clones of the data warehouse. Vulcan identifies which models changed compared to the target environment and only computes data gaps caused by those changes. Changes or backfills in one environment don't affect other environments. Computations done in one environment can be reused in others.

## How to use environments

When running [`vulcan plan`](./plans.md), provide the environment name as the first argument. You can use any string as an environment name. The only special name is `prod`, which refers to production. All other names create development environments.

By default, `vulcan plan` targets the `prod` environment.

### Example

Create or update a development environment by providing a custom name:

```bash
vulcan plan my_dev
```

Vulcan creates the environment automatically the first time you apply a plan to it.

## How environments work

When a model definition changes, Vulcan creates a new model snapshot with a unique fingerprint. The fingerprint identifies whether a model variant exists in other environments or is new. Because models depend on other models, the fingerprint includes fingerprints of upstream dependencies. If a fingerprint already exists, Vulcan reuses the existing physical table for that model variant. The logic that populates the table is identical.

An environment is a collection of references to model snapshots.

For more details, see [plan application](./plans.md#plan-application).

## Date range

A development environment includes a start date and end date. When creating a development environment, you usually test changes on a subset of data. The subset size is determined by the time range defined by the start and end dates. You provide both dates during [plan](./plans.md) creation.
