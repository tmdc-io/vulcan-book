# Overview

The semantic layer is an abstraction that sits between your raw data and the people who consume it. It maps technical database objects — tables, columns, joins — to business concepts like "revenue," "active users," or "churn rate," giving everyone in your organization a shared vocabulary to query data without needing to understand the underlying schema.

---

## What is the Semantic Layer?

The semantic layer bridges the gap between "here's a table with columns" and "here's what this means for the business." It provides a consistent, business-friendly interface to your data that enables self-service analytics while keeping a single source of truth for your business logic.

Without a semantic layer, every time someone wants to analyze revenue, they have to remember which table has it, what the column is called, how to join it with other tables, and how to calculate it correctly. With a semantic layer, they ask for "revenue" and it works.

### Key Benefits

The semantic layer helps everyone in your organization work with data more effectively:

**For Developers:**

- **Define metrics once, use everywhere** — Write the calculation once, use it in dashboards, APIs, and reports
- **Version-controlled business logic** — Your metric definitions live in code, so changes are tracked and reviewable
- **Consistent calculations** — No more "which revenue calculation should I use?", there's one definition

**For Business Users:**

- **Self-service analytics** — Query data without writing SQL (or even knowing what SQL is)
- **Consistent metric definitions** — Everyone uses the same definition of "revenue" or "active users"
- **Trusted, validated data** — Metrics are defined by the data team, so you know they're correct
- **Works everywhere** — Use the same metrics in Tableau, Power BI, Python, or APIs

**For Organizations:**

- **Single source of truth** — One place where "revenue" is defined, not scattered across 20 different dashboards
- **Faster time to insights** — Business users can answer questions themselves instead of waiting for the data team
- **Reduced data team bottleneck** — Less "can you build me a dashboard?" requests
- **Better data governance** — Centralized definitions make it easier to audit and maintain data quality

---

## Core Components

The semantic layer has two main pieces that work together. Think of them as building blocks — you start with semantic models, then build metrics on top.

### Semantic Models

Semantic models are wrappers around your Vulcan models. They take your technical tables and expose them in a business-friendly way. For detailed information, check out the [Semantic Models](models.md) documentation.

Here's what semantic models do:

- **Map physical models** — Reference your Vulcan models from the `models/` directory
- **Expose dimensions** — Specify which model columns become dimensions (things you can filter and group by)
- **Define measures** — Typed aggregation calculations like `count`, `sum`, or `avg` with optional filters
- **Create segments** — Reusable filter conditions (like "high-value customers" or "active users")
- **Establish joins** — Relationships between models so you can analyze across tables

Here's a simple example:

```yaml
semantic_models:
  analytics.customers:
    alias: customers

    measures:
      total_customers:
        type: count
        expression: "{customers.CUSTOMER_ID}"
        description: "Total registered customers"

    dimensions:
      includes:
        - CUSTOMER_ID
        - CUSTOMER_TIER
        - SIGNUP_DATE
```

This takes your `analytics.customers` model and exposes a `total_customers` measure that anyone can use. Business users can query "total customers" without knowing which table it comes from or how to write the SQL.

A more complete example with measures, segments, and joins:

```yaml
semantic_models:
  analytics.customers:
    alias: customers

    measures:
      total_customers:
        type: count
        expression: "{customers.CUSTOMER_ID}"
        description: "Total registered customers"
        tags:
          - customer
          - count

      active_customers:
        type: count
        expression: "*"
        filters:
          - "{customers.STATUS} = 'active'"
        description: "Currently active customers"

    segments:
      high_value_accounts:
        expression: "{customers.PLAN_TYPE} IN ('pro', 'enterprise')"
        description: "Paid plan customers"
        tags:
          - customer
          - segment

    joins:
      orders:
        type: one_to_many
        expression: "{customers.CUSTOMER_ID} = {orders.CUSTOMER_ID}"

    dimensions:
      includes:
        - CUSTOMER_ID
        - CUSTOMER_TIER
        - SIGNUP_DATE
        - STATUS
        - PLAN_TYPE
```

### Business Metrics

Business metrics combine measures with dimensions and time to create complete analytical definitions. They're like pre-built queries that are ready to use. Learn more in the [Business Metrics](./business_metrics.md) guide.

Here's what makes metrics powerful:

- **Time-series analysis** — Metrics include time dimensions so you can see trends over time
- **Flexible granularity** — Query the same metric at different time intervals (day, week, month, etc.)
- **Multi-dimensional** — Slice and dice by business attributes (customer tier, region, product category, etc.)
- **Ready for dashboards** — Pre-configured for visualization tools

Here's what a metric looks like:

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.ORDER_DATE
    default_granularity: month
    slices:
      customer_tier: customers.CUSTOMER_TIER
      region: orders.REGION
    description: "Monthly revenue by customer tier and region"
    tags:
      - revenue
      - financial
```

This creates a `monthly_revenue` metric that:

- Uses the `total_revenue` measure from the orders model
- Groups by `ORDER_DATE` (time dimension) at monthly granularity by default
- Can be sliced by `CUSTOMER_TIER` and `REGION` (business dimensions)
- Includes descriptive metadata via `description` and `tags`

Anyone can query "monthly revenue by customer tier" without writing SQL. They reference the metric name, and Vulcan handles the complexity.

---

## How It Works

Setting up your semantic layer is straightforward. Here's the workflow:

1. **Define semantic models** — Create YAML files that reference your Vulcan models
2. **Add measures and dimensions** — Define what can be calculated and filtered
3. **Create joins** — Connect models so you can analyze across tables
4. **Define metrics** — Combine measures with time and dimensions for analysis
5. **Validate** — Vulcan automatically validates your semantic definitions when you create a plan
6. **Query** — Use the semantic layer via APIs or export to BI tools

The validation step is important — Vulcan checks that your measures reference real columns, joins are valid, and metrics make sense. It'll catch errors before you try to use them, which saves you from debugging issues later.

---

## File Organization

Semantic layer definitions are YAML files in the `semantics/` directory. You can organize them however makes sense for your team:

```
project/
├── models/           # Vulcan data models (.sql files)
│   ├── customers.sql
│   ├── orders.sql
│   └── events.sql
│
├── semantics/        # Semantic layer definitions (YAML)
│   ├── customers.yml
│   ├── orders.yml
│   └── metrics.yml
│
└── config.yaml
```

**File naming:** The filename doesn't matter — Vulcan automatically merges all YAML files in the `semantics/` directory. Organize by domain (like `customers.yml`, `orders.yml`) or by function (like `revenue_metrics.yml`), whatever makes sense for your team.

---

## Integration with Models

Here's the key insight: **the semantic layer builds on your existing models.** You select which columns to expose as dimensions, then layer on measures, segments, joins, and metrics. It doesn't replace anything — it makes your models more accessible.

When you're designing Vulcan models, keep the semantic layer in mind:

```sql
-- Clean column names, business-friendly
MODEL (name analytics.customers);
SELECT
  customer_id,
  customer_tier,      -- Good dimension name (can filter/group by this)
  signup_date,        -- Good time dimension (can analyze trends)
  total_spent         -- Good for measures and segments
FROM raw.customers;
```

Then in your semantic definition, expose those columns and build on them:

```yaml
semantic_models:
  analytics.customers:
    alias: customers

    measures:
      high_spenders:
        type: count
        expression: "*"
        filters:
          - "{customers.TOTAL_SPENT} > 10000"
        description: "Customers who have spent over $10,000"

    segments:
      enterprise_tier:
        expression: "{customers.CUSTOMER_TIER} = 'enterprise'"
        description: "Enterprise-tier customers"

    dimensions:
      includes:
        - CUSTOMER_ID
        - CUSTOMER_TIER
        - SIGNUP_DATE
        - TOTAL_SPENT
```

Your models stay exactly as they are; the semantic layer just makes them more accessible.

---

## Next Steps

- **[Semantic Models](models.md)** — Map physical models to business concepts with measures, segments, and joins
- **[Business Metrics](./business_metrics.md)** — Create time-series analytical definitions with slices and granularity
- **[Transpiling Semantic Queries](../../guides/transpiling_semantics.md)** — See how semantic queries get converted to SQL
- **Check your project** — Look at the `semantics/` directory in your Vulcan project for examples

The semantic layer makes your data accessible to everyone, not just SQL experts. Start with semantic models, add measures, then build metrics.
