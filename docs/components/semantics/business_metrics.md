# Business Metrics

Business metrics are time-series analytical definitions that combine a measure, a time dimension, and optional slices into a single queryable unit. They sit on top of [semantic models](models.md) and are the primary interface for dashboards, reports, and APIs.

---

## Structure

Use either `metrics:` or `semantic_metrics:` as the top-level key — both are valid and produce the same result.

```yaml
metrics:
  <metric_name>:                              # Metric name (must be unique)
    measure: <alias>.<measure_name>           # Which measure to calculate
    time: <alias>.<column_name>               # Time dimension for analysis
    default_granularity: <granularity>        # Default time bucket
    slices:                                   # Optional grouping dimensions
      <slice_key>: <alias>.<column_name>
    segments:                                 # Optional predefined filters
      - <alias>.<segment_name>
    description: "..."                        # Optional description
    owner: "..."                              # Optional owner
    tags: [...]                               # Optional tags
    terms: [...]                              # Optional glossary references
```

All references use **dot notation** with the semantic model alias: `alias.measure_name` for measures, `alias.column_name` for time and slices.

---

## Required properties

Every metric must define these three fields:

### measure

A reference to a measure defined in a semantic model, in the format `alias.measure_name`.

```yaml
measure: subscriptions.total_arr
```

### time

A reference to a time/date column on a semantic model, in the format `alias.column_name`. This is the dimension used for time-series aggregation.

```yaml
time: subscriptions.start_date
```

!!! info "measure and time cannot be the same"
    Vulcan rejects metrics where `measure` and `time` point to the same reference.

### default_granularity

The default time bucket for aggregation. Must be one of:

| Value | Bucket |
|-------|--------|
| `second` | Per-second |
| `minute` | Per-minute |
| `hour` | Hourly |
| `day` | Daily |
| `week` | Weekly |
| `month` | Monthly |
| `quarter` | Quarterly |
| `year` | Yearly |

```yaml
default_granularity: month
```

The default granularity is what's used when a consumer queries the metric without specifying one. Consumers can always override it at query time.

---

## Optional properties

| Property | Type | Description |
|----------|------|-------------|
| `slices` | Map of `name: alias.column` | Named dimensions for grouping and filtering |
| `segments` | List of `alias.segment_name` | Predefined filters from semantic models |
| `description` | String | Human-readable explanation of the metric |
| `owner` | String | Team or person responsible for the metric |
| `tags` | List of strings | Categorization labels for discovery |
| `terms` | List of strings | Business glossary references (e.g. `glossary.revenue`) |

---

## Slices

Slices are named key-value pairs that map a friendly label to a dimension column. They define how consumers can group and filter a metric.

```yaml
metrics:
  arr_growth:
    measure: subscriptions.total_arr
    time: subscriptions.start_date
    default_granularity: month
    slices:
      plan_type: subscriptions.plan_type
      industry: users.industry
      billing_cycle: subscriptions.billing_cycle
    description: "Annual Recurring Revenue growth by plan and industry"
```

The slice key (`plan_type`) is the name consumers use in queries. The value (`subscriptions.plan_type`) is the semantic reference to the actual column. Slice values must be unique within a metric — you cannot map two slice keys to the same column.

Slices can reference columns from any semantic model, as long as the models are connected through joins.

---

## Segments

Segments apply predefined filters from semantic models to a metric. Reference them using `alias.segment_name`:

```yaml
metrics:
  active_user_engagement:
    measure: usage_events.daily_active_users
    time: usage_events.event_date
    default_granularity: day
    segments:
      - users.high_value_accounts
      - usage_events.recent_activity
```

The segments `high_value_accounts` and `recent_activity` must be defined in their respective semantic models. When the metric is queried, these filters are applied automatically.

---

## Cross-model metrics

Metrics can pull their measure, time, and slices from different semantic models. Vulcan resolves the join paths automatically based on the joins defined in your semantic models.

```yaml
metrics:
  cohort_retention:
    measure: users.active_users
    time: users.signup_date
    default_granularity: month
    slices:
      signup_channel: users.signup_channel
      plan_type: subscriptions.plan_type
    description: "User retention by signup cohort and plan type"
```

This metric uses the `active_users` measure and `signup_date` time from the `users` model, but slices by `plan_type` from the `subscriptions` model. The `users` model must have a join defined to `subscriptions` for this to work.

!!! warning "Joins are required for cross-model references"
    If a metric references multiple semantic models, those models must be connected through joins. Vulcan validates this and will raise an error if a join path doesn't exist.

---

## Time granularity

Define a metric once, query it at any granularity. The `default_granularity` sets the default, but consumers can override it:

- `granularity=day`
- `granularity=week`
- `granularity=month`
- `granularity=quarter`
- `granularity=year`

You don't need separate metric definitions for daily, weekly, and monthly views of the same data.

---

## Complete example

A full metrics file from a B2B SaaS project:

```yaml
metrics:
  product_engagement:
    measure: usage_events.daily_active_users
    time: usage_events.event_date
    default_granularity: day
    slices:
      feature_name: usage_events.feature_name
      plan_type: users.plan_type
    description: "Daily active users by feature and subscription plan"
    tags:
      - engagement
      - dau
    terms:
      - glossary.user_engagement
      - glossary.daily_active_users

  churn_analysis:
    measure: subscriptions.churn_count
    time: subscriptions.end_date
    default_granularity: month
    slices:
      plan_type: subscriptions.plan_type
      company_size: users.company_size
      signup_channel: users.signup_channel
    description: "Churn patterns by plan, company size, and acquisition channel"

  cohort_retention:
    measure: users.active_users
    time: users.signup_date
    default_granularity: month
    slices:
      signup_channel: users.signup_channel
      plan_type: subscriptions.plan_type
    description: "User retention by signup cohort and plan type"

  arr_growth:
    measure: subscriptions.total_arr
    time: subscriptions.start_date
    default_granularity: month
    slices:
      plan_type: subscriptions.plan_type
      industry: users.industry
      billing_cycle: subscriptions.billing_cycle
    description: "Annual Recurring Revenue growth by plan and industry"
    tags:
      - revenue
      - arr
    terms:
      - glossary.annual_recurring_revenue
```

---

## Validation

Vulcan validates metric definitions automatically when you create a plan. It checks that:

- `measure` references a valid measure on a semantic model
- `time` references a valid time/date column
- `default_granularity` is a recognized granularity value
- `measure` and `time` do not point to the same reference
- Slice values are unique (no two slice keys map to the same column)
- Slice and segment references use valid `alias.name` format
- Cross-model references have valid join paths between the involved models

---

## Next steps

- Learn about [Semantic Models](models.md) that provide the measures, segments, and joins metrics build on
- See the [Semantics Overview](overview.md) for the complete picture
- Explore metric definitions in your project's `semantics/` directory
