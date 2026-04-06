# Semantic Models

Semantic models map your physical Vulcan models to business-friendly representations. They define what consumers can do with each model: which columns are exposed as dimensions, what aggregations are available as measures, which reusable filters exist as segments, and how models relate to each other through joins.

---

## Structure

A semantic model wraps a single Vulcan model. Use either `semantic_models:` or `models:` as the top-level key — both are valid and produce the same result.

```yaml
semantic_models:
  b2b_saas.users:          # Fully qualified Vulcan model name
    alias: users            # Business-friendly name used in queries

    dimensions: {...}       # Control which columns are queryable
    measures: {...}         # Aggregated calculations
    segments: {...}         # Reusable filter conditions
    joins: {...}            # Relationships to other semantic models
```

The YAML key (`b2b_saas.users`) must match an existing Vulcan model defined in your `models/` directory. The `alias` is the name consumers use when querying — it must start with a letter and contain only letters, numbers, and underscores. If omitted, it defaults to the model name.

!!! info "No description at the model level"
    Semantic models do not support a top-level `description` field. Descriptions belong in the Vulcan model file itself (the `MODEL()` DDL), not in the semantic YAML.

---

## Dimensions

Dimensions are columns consumers can group by and filter on. By default, all columns from the underlying Vulcan model are exposed. You can narrow that down with `includes` or `excludes`, and add capabilities with `enhancements`.

### Controlling visibility

Use `includes` to expose only specific columns, or `excludes` to hide specific ones. You cannot use both at the same time.

```yaml
dimensions:
  includes:
    - user_id
    - signup_date
    - plan_type
    - status
    - company_size
    - industry
```

```yaml
dimensions:
  excludes:
    - password_hash
    - internal_notes
```

If you omit `dimensions` entirely (or leave both `includes` and `excludes` empty), every column in the model is exposed.

!!! tip "Snowflake and other case-sensitive engines"
    Snowflake stores unquoted identifiers in uppercase by default. When targeting Snowflake, use uppercase column names in your dimension lists, expressions, and filters to match the warehouse schema:

    ```yaml
    dimensions:
      includes:
        - USER_ID
        - SIGNUP_DATE
        - PLAN_TYPE
    ```

    ```yaml
    measures:
      active_users:
        type: count
        expression: "*"
        filters:
          - "{users.STATUS} = 'active'"
    ```

    Always match the casing your warehouse actually uses. Lowercase examples in this guide assume a case-insensitive engine like DuckDB or Postgres.

### Enhancements

Enhancements add time granularities or display formatting to a dimension. Each enhancement must specify at least one of `format` or `granularities`.

```yaml
dimensions:
  includes:
    - signup_date
    - plan_type
  enhancements:
    - name: signup_date
      granularities:
        - name: monthly
          interval: "1 month"
        - name: quarterly
          interval: "3 months"
    - name: mrr
      format: currency
```

**Granularity options** for `interval`: any positive quantity of `minute`, `hour`, `day`, `week`, `month`, or `year` (e.g. `"15 minutes"`, `"1 week"`).

**Format options**: `currency`, `percent`, `imageUrl`, `link`, `id`.

---

## Measures

Measures are named aggregations that answer "how much?" or "how many?" questions. Each measure requires a `type` and, for most types, an `expression`.

### Measure types

| Type | Description | Expression required? |
|------|-------------|---------------------|
| `count` | Row count (`COUNT(*)`) | No |
| `count_distinct` | Distinct count | Yes |
| `count_distinct_approx` | Approximate distinct count | Yes |
| `sum` | Sum aggregation | Yes |
| `avg` | Average aggregation | Yes |
| `min` | Minimum value | Yes |
| `max` | Maximum value | Yes |
| `number` | Custom numeric expression | Yes |
| `string` | Custom string expression | Yes |
| `time` | Custom time expression | Yes |
| `boolean` | Custom boolean expression | Yes |

### Defining measures

Reference columns using curly-brace syntax: `{alias.column_name}`.

```yaml
measures:
  total_users:
    type: count
    expression: "{users.user_id}"
    description: "Total registered users"
    tags:
      - user
      - count

  active_users:
    type: count
    expression: "*"
    filters:
      - "{users.status} = 'active'"
    description: "Currently active users"

  avg_mrr_per_account:
    type: avg
    expression: "{subscriptions.mrr}"
    filters:
      - "{subscriptions.status} = 'active'"
    format: currency
    description: "Average MRR per active subscription"
    tags:
      - revenue
      - financial
    terms:
      - revenue.avg_mrr
```

### Measure properties

| Property | Required | Description |
|----------|----------|-------------|
| `type` | Yes | Aggregation type (see table above) |
| `expression` | Depends | Column reference or SQL expression. Not required for `count`. |
| `description` | No | Human-readable explanation of the measure |
| `filters` | No | List of SQL conditions that restrict which rows are aggregated |
| `format` | No | Display hint: `currency` or `percent` |
| `tags` | No | List of categorization labels |
| `terms` | No | List of business glossary references (e.g. `glossary.revenue`) |
| `rolling_window` | No | Window configuration with `trailing`, `leading`, and `offset` |
| `public` | No | Whether the measure is visible to consumers (default: `true`) |

!!! warning "Reserved name"
    `count` is a reserved measure name — Vulcan adds it automatically. Use a different name like `total_users` or `row_count`.

---

## Segments

Segments are reusable filter conditions that define meaningful subsets of your data. Instead of writing `WHERE status = 'active'` in every query, define it once as a segment.

```yaml
segments:
  high_value_accounts:
    expression: "{users.plan_type} IN ('pro', 'enterprise')"
    description: "Paid plan users"
    tags:
      - customer
      - segment
      - revenue
    terms:
      - customer.high_value

  recent_signups:
    expression: |
      {users.signup_date} >= DATEADD(DAY, -7, CURRENT_DATE)
    description: "Users signed up in last 7 days"

  at_risk_users:
    expression: |
      {users.status} = 'active' AND {users.plan_type} = 'free'
    description: "Free users who might churn"
```

### Segment properties

| Property | Required | Description |
|----------|----------|-------------|
| `expression` | Yes | SQL boolean condition using `{alias.column}` references |
| `description` | No | Human-readable explanation |
| `tags` | No | Categorization labels |
| `terms` | No | Business glossary references |
| `public` | No | Visibility to consumers (default: `true`) |

!!! info "Uniqueness constraint"
    Measure and segment names must be unique within a single semantic model. You cannot have a measure and a segment with the same name.

---

## Joins

Joins define relationships between semantic models so you can analyze across tables. The join key is the alias of the target model, and the expression is the SQL join condition.

```yaml
joins:
  subscriptions:
    type: one_to_many
    expression: "{users.user_id} = {subscriptions.user_id}"

  usage_events:
    type: one_to_many
    expression: "{users.user_id} = {usage_events.user_id}"
```

### Join types

| Type | Cardinality | Example |
|------|-------------|---------|
| `one_to_one` | One row matches one row | user to user_profile |
| `one_to_many` | One row matches many rows | customer to orders |
| `many_to_one` | Many rows match one row | orders to customer |

The join `expression` uses `{alias.column}` syntax on both sides. The cardinality helps Vulcan handle aggregations correctly and prevent double-counting.

### Cross-model references

Once joins are defined, you can reference columns from joined models in measure filters:

```yaml
measures:
  enterprise_revenue:
    type: sum
    expression: "{subscriptions.arr}"
    filters:
      - "{users.plan_type} = 'enterprise'"
    description: "ARR from enterprise plan users"
```

Here `enterprise_revenue` is defined on the subscriptions model but filters by `users.plan_type` from the joined users model. Vulcan resolves the join path automatically.

---

## Complete example

A full semantic model definition from a B2B SaaS project:

```yaml
semantic_models:
  b2b_saas.subscriptions:
    alias: subscriptions

    measures:
      total_arr:
        type: sum
        expression: "{subscriptions.arr}"
        filters:
          - "{subscriptions.status} = 'active'"
        format: currency
        description: "Total Annual Recurring Revenue"
        tags:
          - revenue
          - financial
        terms:
          - revenue.total_arr

      churn_count:
        type: count
        expression: "*"
        filters:
          - "{subscriptions.status} = 'cancelled'"
          - |
            {subscriptions.end_date} >= DATEADD(DAY, -30, CURRENT_DATE)
        description: "Subscriptions churned in last 30 days"
        tags:
          - churn
          - retention

      subscription_count:
        type: count
        expression: "*"
        filters:
          - "{subscriptions.status} = 'active'"
        description: "Total active subscriptions"

    segments:
      active_subscriptions:
        expression: "{subscriptions.status} = 'active'"
        description: "Currently active subscriptions"

      high_value_accounts:
        expression: "{subscriptions.mrr} >= 1000"
        description: "High-value accounts (>= $1000 MRR)"
        tags:
          - revenue
          - high_value

      enterprise_subscriptions:
        expression: "{subscriptions.plan_type} = 'enterprise'"
        description: "Enterprise plan subscriptions"

    joins:
      subscription_plans:
        type: many_to_one
        expression: "{subscriptions.plan_id} = {subscription_plans.plan_id}"

    dimensions:
      includes:
        - plan_id
        - start_date
        - end_date
        - plan_type
        - status
        - billing_cycle
        - mrr
        - arr
```

---

## Validation

Vulcan validates semantic model definitions automatically when you create a plan. It checks that:

- Column references in measures and segments point to real columns
- Join expressions reference valid columns on both sides
- Join targets reference existing semantic model aliases
- Cross-model references have valid join paths
- Aliases follow naming rules (letters, numbers, underscores; starts with a letter)
- No duplicate names exist across measures and segments

Validation runs before anything is materialized, so errors are caught early.

---

## Next steps

- Learn about [Business Metrics](business_metrics.md) that combine measures with time and dimensions
- Explore working examples in your project's `semantics/` directory
- See the [Semantics Overview](overview.md) for the complete picture
