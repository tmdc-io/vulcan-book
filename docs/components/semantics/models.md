# Semantic Models

Semantic models map your physical Vulcan models to business-friendly representations. They define what consumers can do with each model: which columns are exposed as dimensions, what aggregations are available as measures, which reusable filters exist as segments, and how models relate to each other through joins.

---

## Structure

A semantic model wraps a single Vulcan model. Use `kind: semantic` and put **one model per file** in `models/semantics/`:

```yaml
kind: semantic
name: users                  # Business-friendly name used in queries
depends_on: b2b_saas.users   # Fully qualified Vulcan model this wraps
description: Core user dimension (semantic layer)

dimensions: [...]            # Columns consumers can group by and filter on
measures: [...]              # Aggregated calculations
segments: [...]              # Reusable filter conditions
joins: [...]                 # Relationships to other semantic models
```

**Top-level fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `kind: semantic` | Yes | Declares the file as a semantic model. |
| `name` | Yes | Business-friendly identifier consumers reference (e.g. `users`). Lowercase identifier — see [Naming rules](#naming-rules). This is the identifier you use in `{name.column}` references everywhere else. |
| `depends_on` | Yes | The fully qualified Vulcan model this wraps (e.g. `b2b_saas.users`). Must match a model defined in your `models/` directory. |
| `dimensions` | **Yes** | List of dimensions. Must be non-empty. See [Dimensions](#dimensions). |
| `description` | No | Human-readable explanation of the semantic model. |
| `owner` | No | Team or person responsible. Free-form string. |
| `tags` | No | List of tags. See [Naming rules](#naming-rules) for the allowed pattern. |
| `terms` | No | List of business glossary references (e.g. `revenue.subscription`). See [Naming rules](#naming-rules). |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |
| `measures` | No | List of named aggregations. |
| `segments` | No | List of reusable filter conditions. |
| `joins` | No | List of relationships to other semantic models. |

!!! tip "Snowflake and other case-sensitive engines"
    Snowflake stores unquoted identifiers in uppercase by default. When targeting Snowflake, use uppercase column names in your dimension lists, expressions, and filters to match the warehouse schema. Lowercase examples in this guide assume a case-insensitive engine like DuckDB or Postgres.

---

## Naming rules

Vulcan validates every identifier in a semantic model. Use this section as a quick reference if validation fails:

| Identifier | Pattern | Notes |
|------------|---------|-------|
| Semantic model `name`, measure `name`, segment `name`, join `name`, granularity `name`, metric `name` | `^[a-z][a-z0-9_]{0,63}$` | Lowercase, starts with a letter, underscores allowed, max 64 chars. |
| Dimension `name` (i.e. a column reference) | `^[a-zA-Z_][a-zA-Z0-9_]{0,63}$` | Mixed case allowed so warehouse identifiers like `CUSTKEY` survive. |
| `tags[*]` | `^[a-zA-Z0-9.:_-]+$` | Supports `key:value` patterns, e.g. `classification:PII`. |
| `terms[*]` | `^[a-zA-Z0-9._-]+$` | Typically dotted FQNs, e.g. `revenue.subscription`. |

!!! warning "Unknown keys fail validation"
    The wire-level schemas (`ai_context`, `rolling_window`, `granularities`) use Pydantic's `extra="forbid"`. Any unknown key inside these blocks will cause validation to fail. Stick to the documented fields.

---

## Dimensions

`dimensions:` is a **required, non-empty list**. Each item can be either a bare column name (shorthand) or a full dictionary with metadata, granularities, and formatting.

### Shorthand: a bare column name

If you only need to expose a column, write it as a string:

```yaml
dimensions:
  - plan_type
  - status
  - email
  - industry
  - user_id
```

Each string is the name of a column in the underlying Vulcan model.

### Full form: a dict with metadata

When you want to add documentation, tags, glossary terms, granularities, or a display format, write the dimension as a dict:

```yaml
dimensions:
  - name: signup_date
    description: When the user signed up (used for cohort time axis)
    tags:
      - temporal
      - acquisition
      - cohort
    terms:
      - customer.signup_date
      - temporal.signup_timestamp

  - name: signup_channel
    description: How the user signed up (organic, paid, referral, etc.)
    tags:
      - acquisition
      - channel
    terms:
      - customer.signup_channel
```

You can freely mix shorthand and full-form entries in the same list.

### Granularities

For time-like dimensions, attach a `granularities:` list inline on the dimension. Each granularity has a `name` and an `interval`:

```yaml
dimensions:
  - name: session_start
    granularities:
      - name: hour
        interval: 1 hour
      - name: day
        interval: 1 day
      - name: week
        interval: 1 week
      - name: month
        interval: 1 month
```

**Interval grammar:** any positive quantity of `minute`, `hour`, `day`, `week`, `month`, or `year` (e.g. `15 minutes`, `3 months`, `1 year`).

**Granularity fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase identifier — see [Naming rules](#naming-rules). Must be unique within the dimension. |
| `interval` | Yes | Duration string like `1 hour`, `30 minutes`, `1 month`. |
| `description` | No | Human-readable explanation. |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |

### Display format

For dimensions whose values benefit from a presentation hint, set `format:` inline:

```yaml
dimensions:
  - name: pages_viewed
    format: percent
  - name: avg_order_value
    format: currency
```

**`format`** is a free-form string passed through to downstream consumers (BI tools, APIs). Vulcan does not validate the value against a fixed list. Common values include `percent` and `currency`; use whatever the consumer at the other end understands.

### Dimension properties (full form)

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Column name in the underlying Vulcan model. Mixed case allowed — see [Naming rules](#naming-rules). |
| `description` | No | Human-readable explanation. |
| `tags` | No | List of categorization labels. |
| `terms` | No | List of business glossary references. |
| `granularities` | No | List of time buckets — only meaningful on `TIMESTAMP`/`DATETIME` columns. Granularity names must be unique within the dimension. |
| `format` | No | Free-form display hint (e.g. `percent`, `currency`). |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |
| `public` | No | Whether the dimension is visible to consumers (default: `true`). |

---

## Measures

`measures:` is a **list**. Each item is a dict that defines a named aggregation. Reference columns from the underlying model using `{name.column}` syntax, where `name` is the semantic model's `name:`.

```yaml
measures:
  - name: total_users
    type: count
    expression: "{users.user_id}"
    description: Total registered users
    tags:
      - user
      - count
      - metric
    terms:
      - customer.total_users
      - metric.user_count

  - name: active_users
    type: count
    filters:
      - "{users.status} = 'active'"
    description: Currently active users
    tags:
      - user
      - active
    terms:
      - customer.active_users

  - name: avg_mrr_per_account
    type: avg
    expression: "{subscriptions.mrr}"
    filters:
      - "{subscriptions.status} = 'active'"
    description: Average MRR per active subscription
    tags:
      - revenue
      - financial
    terms:
      - revenue.avg_mrr
```

### Measure types

| Type | Description | Expression required? |
|------|-------------|---------------------|
| `count` | Row count | No (see below) |
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

### `count` measures and `expression`

`count` is the only type where `expression:` is optional. Three forms all work:

```yaml
measures:
  - name: row_count
    type: count
    # No expression: counts every row (equivalent to COUNT(*))

  - name: total_users
    type: count
    expression: "*"
    # Same as above, written explicitly

  - name: users_with_email
    type: count
    expression: "{users.email}"
    # Counts non-NULL values of users.email
```

Pick the form that best describes intent: omit or `"*"` for "count rows", a `{name.column}` reference for "count non-null values in this column".

### Measure properties

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Lowercase identifier — see [Naming rules](#naming-rules). Must be unique among measures and segments in this semantic model. |
| `type` | Yes | Aggregation type (see table above). Normalized to lowercase. |
| `expression` | Conditionally | Column reference (`{name.column}`) or SQL expression. Required for every type except `count`. |
| `filters` | No | List of SQL conditions that restrict which rows are aggregated. **Only allowed on** `count`, `count_distinct`, `count_distinct_approx`, `sum`, `avg`, `min`, `max`. **Never allowed on** `number`. Use `{name.column}` references. |
| `description` | No | Human-readable explanation. |
| `tags` | No | List of categorization labels. |
| `terms` | No | List of business glossary references. |
| `rolling_window` | No | Window configuration. See [Rolling windows](#rolling-windows). |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |
| `public` | No | Whether the measure is visible to consumers (default: `true`). |

!!! warning "Reserved name"
    `count` is a reserved measure name — Vulcan adds an implicit `count` measure automatically. Use a different name like `total_users`, `row_count`, or `subscription_count`.

### Rolling windows

Attach a `rolling_window:` to a measure to compute it over a sliding time window relative to the query period.

```yaml
measures:
  - name: trailing_7d_revenue
    type: sum
    expression: "{subscriptions.mrr}"
    rolling_window:
      trailing: 7 days
      offset: end
```

| Field | Required | Allowed values |
|-------|----------|----------------|
| `trailing` | No | `unbounded`, or a signed duration like `1 day`, `30 days`, `-7 days`. Same grammar as granularity intervals. |
| `leading` | No | Same grammar as `trailing`. |
| `offset` | No | `start` or `end` (default `end`). Controls whether the window is anchored to the start or end of the bucket. |

Use `trailing` for look-backs (rolling averages, trailing totals), `leading` for look-aheads, and combine them for centered windows. `unbounded` removes the bound on that side.

!!! note "Pydantic `extra=\"forbid\"`"
    Any key other than `trailing`, `leading`, `offset` inside `rolling_window:` will fail validation.

---

## Segments

Segments are reusable filter conditions that define meaningful subsets of your data. Instead of writing `WHERE status = 'active'` in every query, define it once as a segment.

`segments:` is a **list** of dicts:

```yaml
segments:
  - name: high_value_accounts
    expression: "{users.plan_type} IN ('pro', 'enterprise')"
    description: Paid plan users
    tags:
      - customer
      - segment
      - revenue
    terms:
      - customer.high_value
      - segment.premium

  - name: recent_signups
    expression: "{users.signup_date} >= CURRENT_DATE - INTERVAL '7 days'"
    description: Users signed up in last 7 days
    tags:
      - acquisition
      - temporal
      - growth

  - name: at_risk_users
    expression: "{users.status} = 'active' AND {users.plan_type} = 'free'"
    description: Free users who might churn
    tags:
      - churn
      - risk
```

### Segment properties

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Lowercase identifier — see [Naming rules](#naming-rules). |
| `expression` | Yes | SQL boolean condition. **Must reference columns of the current semantic model only** (e.g. `{usage_sessions.device_type} = 'mobile'`). Cross-model filters belong on a metric or a measure. |
| `description` | No | Human-readable explanation. |
| `tags` | No | List of categorization labels. |
| `terms` | No | List of business glossary references. |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |
| `public` | No | Visibility to consumers (default: `true`). |

!!! info "Uniqueness constraint"
    Measure and segment names must be unique within a single semantic model. You cannot have a measure and a segment with the same name.

---

## Joins

Joins define relationships between semantic models so you can analyze across tables. `joins:` is a **list** of dicts. The `name:` of each join entry must match the `name:` of another semantic model in the project.

```yaml
joins:
  - name: subscriptions
    type: one_to_many
    expression: "{users.user_id} = {subscriptions.user_id}"

  - name: usage_events
    type: one_to_many
    expression: "{users.user_id} = {usage_events.user_id}"
```

### Join properties

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Lowercase identifier — see [Naming rules](#naming-rules). **Must match the `name:` of an existing semantic model** in the project. **Must not equal the current model's own `name`.** |
| `type` | Yes | One of `one_to_one`, `one_to_many`, `many_to_one`. Normalized to lowercase. |
| `expression` | Yes | SQL-like join predicate referencing both sides as `{model_a.col} = {model_b.col}`. |
| `ai_context` | No | Hints for AI/LLM consumers. See [AI context](#ai-context). |
| `fqn` | No | Fully-qualified name of the join target. Engine-set; rarely authored by hand. |

!!! warning "Joins do not accept metadata"
    Joins do **not** support `description`, `tags`, `terms`, or `public`. Only the fields above are allowed — extra keys fail validation.

### Join types

| Type | Cardinality | Example |
|------|-------------|---------|
| `one_to_one` | One row matches one row | user to user_profile |
| `one_to_many` | One row matches many rows | user to subscriptions |
| `many_to_one` | Many rows match one row | subscriptions to subscription_plans |

`many_to_many` is **not supported**. Model many-to-many relationships through an intermediate join model (a semantic model wrapping the bridge table) and chain two joins.

The join `expression:` uses `{name.column}` syntax on both sides. The cardinality helps Vulcan handle aggregations correctly and prevent double-counting.

### Cross-model references

Once joins are defined, you can reference columns from joined models in measure filters:

```yaml
measures:
  - name: enterprise_revenue
    type: sum
    expression: "{subscriptions.arr}"
    filters:
      - "{users.plan_type} = 'enterprise'"
    description: ARR from enterprise plan users
```

Here `enterprise_revenue` is defined on the subscriptions semantic model but filters by `users.plan_type` from the joined users model. Vulcan resolves the join path automatically.

---

## Complete example

A B2B SaaS subscriptions semantic model with dimensions, measures, segments, and joins:

```yaml
kind: semantic
name: subscriptions
depends_on: hello.subscriptions
description: Subscription lifecycle and revenue (semantic layer)

dimensions:
  - subscription_id
  - user_id
  - plan_id
  - start_date
  - end_date
  - name: plan_type
    description: Subscription plan tier (free, pro, enterprise, etc.)
    tags:
      - product
      - pricing
      - segment
    terms:
      - subscription.plan_type
      - product.plan_tier
  - status
  - billing_cycle
  - revenue_category
  - mrr
  - seats
  - arr

measures:
  - name: total_arr
    type: sum
    expression: "{subscriptions.arr}"
    filters:
      - "{subscriptions.status} = 'active'"
    description: Total Annual Recurring Revenue
    tags:
      - revenue
      - financial
      - arr
    terms:
      - revenue.total_arr
      - finance.annual_recurring_revenue

  - name: subscription_count
    type: count
    filters:
      - "{subscriptions.status} = 'active'"
    description: Total active subscriptions
    tags:
      - subscription
      - count
      - metric

  - name: churn_count
    type: count
    filters:
      - "{subscriptions.status} = 'cancelled'"
      - "{subscriptions.end_date} >= CURRENT_DATE - INTERVAL '30 days'"
    description: Subscriptions churned in last 30 days
    tags:
      - churn
      - retention

segments:
  - name: active_subscriptions
    expression: "{subscriptions.status} = 'active'"
    description: Currently active subscriptions

  - name: high_value_accounts
    expression: "{subscriptions.mrr} >= 1000"
    description: High-value accounts (>= $1000 MRR)
    tags:
      - revenue
      - high_value

  - name: enterprise_subscriptions
    expression: "{subscriptions.plan_type} = 'enterprise'"
    description: Enterprise plan subscriptions

joins:
  - name: subscription_plans
    type: many_to_one
    expression: "{subscriptions.plan_id} = {subscription_plans.plan_id}"

  - name: usage_sessions
    type: one_to_many
    expression: "{subscriptions.subscription_id} = {usage_sessions.subscription_id}"
```

---

## AI context

Most spec objects (the semantic model itself, dimensions, granularities, measures, segments, joins) accept an optional `ai_context:` block to help AI/LLM consumers understand the object. All three fields are optional, and unknown keys fail validation.

```yaml
kind: semantic
name: subscriptions
depends_on: hello.subscriptions

ai_context:
  instructions: |
    Subscription rows represent the contract lifecycle, not invoice events.
    Use `total_arr` for steady-state ARR and `churn_count` for retention questions.
  synonyms:
    - "contracts"
    - "subscriptions"
    - "accounts"
  examples:
    - "How many active enterprise subscriptions exist this month?"
    - "What is ARR by plan_type for the last quarter?"

dimensions:
  - name: plan_type
    ai_context:
      synonyms:
        - "plan"
        - "tier"
        - "subscription_level"
```

| Field | Type | Description |
|-------|------|-------------|
| `instructions` | String | Free-form guidance for how to think about this object. |
| `synonyms` | List of strings | Alternate names consumers/LLMs might use. |
| `examples` | List of strings | Example questions, queries, or values that illustrate intent. |

---

## Validation

Vulcan validates semantic model definitions automatically when you create a plan. It checks that:

- `depends_on` references an existing Vulcan model
- All identifier names match the patterns in [Naming rules](#naming-rules)
- `dimensions` is non-empty
- Column references in measures and segments point to real columns
- Segment expressions reference only columns of the current semantic model
- Filters on measures are only used with allowed measure types
- Join `name`s reference existing semantic models and are not equal to the current model's `name`
- Join `type` is one of `one_to_one`, `one_to_many`, `many_to_one`
- Cross-model references have valid join paths
- No duplicate names exist among measures, among segments, among joins, or among granularities within a single dimension
- `count` is not used as an explicit measure name
- No unknown keys appear inside `ai_context`, `rolling_window`, or `granularities` (Pydantic `extra="forbid"`)

Validation runs before anything is materialized, so errors are caught early.

---

## Next steps

- Learn about [Business Metrics](business_metrics.md) that combine measures with time and dimensions
- Explore working examples in your project's `models/semantics/` directory
- See the [Semantics Overview](overview.md) for the complete picture
