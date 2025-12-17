# Managed

Most Vulcan models manage their own data—you run `vulcan run`, and Vulcan updates the tables. Managed models are different: the database engine handles data updates automatically in the background.

**How it works:** You define a query, and the engine monitors upstream tables. When source data changes, the engine automatically refreshes your managed table. No manual `REFRESH` commands needed—it just happens.

**Why use this?** Perfect for scenarios where you need always-fresh data without managing refresh schedules yourself. The engine handles the complexity of incremental updates, change detection, and refresh timing.

**Best use case:** Managed models are typically built on [External Models](components/model/types/external_models.md) rather than other Vulcan models. Since Vulcan already keeps its models up to date, the main benefit comes when you're reading from external tables that aren't tracked by Vulcan. The engine keeps your managed table in sync with those external sources automatically.

!!! warning "Python Models Not Supported"

    Python models don't support the `MANAGED` [model kind](components/model/types/model_kinds.md). You'll need to use a SQL model instead.

## Difference from Materialized Views

You might be wondering: "What's the difference between a managed model and a materialized view?" Good question!

Vulcan already supports [materialized views](components/model/types/model_kinds.md#materialized-views), but they have limitations:
- Some engines only allow materialized views from a single base table
- Materialized views aren't automatically refreshed—you need to run `REFRESH MATERIALIZED VIEW` manually
- You're responsible for scheduling refreshes

**Managed models are different:**
- ✅ **Automatic updates** - The engine refreshes data when source tables change
- ✅ **Smart refresh** - The engine understands your query and can do incremental or full refreshes as needed
- ✅ **No manual commands** - Everything happens in the background

**In some engines, there's no difference** (they're the same thing). In others, managed models give you more automation and flexibility.

## Lifecycle in Vulcan

Managed models follow the same lifecycle as other Vulcan models:
- Virtual environments create pointers to model snapshots
- Model changes create new snapshots
- Upstream changes trigger new snapshots
- You can deploy and rollback like any other model
- Snapshots get cleaned up when TTL expires

**Cost consideration:** Managed models usually cost more than regular tables. For example, Snowflake charges extra for Dynamic Tables. To save money, Vulcan uses regular tables for dev previews (in forward-only plans) and only creates managed tables when deploying to production.

!!! warning "Dev vs Prod Differences"

    Since dev uses regular tables and prod uses managed tables, it's possible to write a query that works in dev but fails in prod. This happens if you use features available to regular tables but not managed tables.

    We think the cost savings are worth it, but if this causes issues, [let us know](https://tobikodata.com/slack)!

## Supported Engines

Currently, Vulcan supports managed models on:

| Engine | Implementation |
|--------|----------------|
| [Snowflake](../../configurations/engines/snowflake.md) | [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro) |

To create a managed model, use the [`MANAGED`](components/model/types/model_kinds.md#managed) model kind. More engines are coming soon!

### Snowflake

On Snowflake, managed models are implemented as [Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables-intro). Dynamic Tables automatically refresh when their source data changes, which is exactly what managed models need.

Here's how you'd create one:

```sql linenums="1"
MODEL (
  name db.events,
  kind MANAGED,
  physical_properties (
    warehouse = datalake,
    target_lag = '2 minutes',
    data_retention_time_in_days = 2
  )
);

SELECT
  event_date::DATE as event_date,
  event_payload::TEXT as payload
FROM raw_events
```

results in:

```sql linenums="1"
CREATE OR REPLACE DYNAMIC TABLE db.events
  WAREHOUSE = "datalake",
  TARGET_LAG = '2 minutes'
  DATA_RETENTION_TIME_IN_DAYS = 2
AS SELECT
  event_date::DATE as event_date,
  event_payload::TEXT as payload
FROM raw_events
```

!!! note "No Intervals"

    Vulcan doesn't create intervals or run this model on a schedule. You don't need `WHERE` clauses with date filters like you would for incremental models. Snowflake handles all the refreshing automatically—you just define the query and let Snowflake do its thing.

#### Table Properties

Dynamic Tables have properties that control refresh frequency, initial data population, retention, and more. You can find the complete list in the [Snowflake documentation](https://docs.snowflake.com/sql-reference/sql/create-dynamic-table).

In Vulcan, you set these properties using [`physical_properties`](components/model/overview.md#physical_properties) in your model definition. Here are the key ones:

| Snowflake Property              | Required | Notes
| ------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| target_lag                      | Y        |                                                                                                                                         |
| warehouse                       | N        | In Snowflake, this is a required property. However, if not specified, then Vulcan will use the result of `select current_warehouse()`. |
| refresh_mode                    | N        |                                                                                                                                         |
| initialize                      | N        |                                                                                                                                         |
| data_retention_time_in_days     | N        |                                                                                                                                         |
| max_data_extension_time_in_days | N        |                                                                                                                                         |

The following Dynamic Table properties can be set directly on the model:

| Snowflake Property | Required   | Notes                                                                                                                                                                   |
| ------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| cluster by         | N          | `clustered_by` is a [standard model property](../overview.md#clustered_by), so set `clustered_by` on the model to add a `CLUSTER BY` clause to the Dynamic Table |