# Business Metrics

Business metrics are where your semantic layer really shines. They combine measures (the calculations) with dimensions (the attributes) and time (the when) to create complete analytical definitions that are ready for time-series analysis.

Semantic models provide the building blocks (measures, dimensions, joins), and business metrics combine those blocks into something you can analyze over time. They're pre-configured for dashboards, reports, and APIs, no SQL required.

## What are business metrics?

Business metrics are complete analytical definitions that:

- **Combine measures with time**: Let you analyze trends at different time granularities (daily, weekly, monthly, etc.)

- **Include dimensions**: Enable slicing and dicing by business attributes (customer tier, region, product category, etc.)

- **Ready for analysis**: Pre-configured so they can power dashboards, reports, and APIs directly

- **Examples**: `monthly_revenue_by_tier`, `daily_active_users`, `customer_acquisition_trend`

They're the bridge between your technical data models and the business questions people actually want to answer.

## Basic structure

A business metric brings together three things:

- **Measure**: The calculation you want to perform (like `orders.total_revenue`)

- **Time**: The time dimension for your analysis (like `orders.order_date`)

- **Dimensions**: Optional attributes for grouping and filtering (like `customers.customer_tier`)

Here's the simplest possible metric:

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue      # Which measure to calculate
    time: orders.order_date            # Time dimension for analysis
    description: "Monthly revenue trends"
```

That's it! This metric is now ready to be queried at any time granularity you want.

## Simple metric

Let's start with the basics, a metric that just has a measure and time:

```yaml
metrics:
  daily_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Daily revenue trends"
```

Even though it's called `daily_revenue`, you're not locked into daily granularity. You can query this same metric at different time intervals (day, week, month, quarter, year) without redefining it. The metric definition stays the same; you just change the granularity when you query it.

## Metric with dimensions

Add dimensions to enable slicing and grouping:

```yaml
metrics:
  revenue_by_tier:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier      # Group by tier

      - customers.country            # And country
    description: "Revenue trends by customer tier and country"
```

Now you can answer questions like:

- What's our revenue by tier over time?

- How does revenue vary by country?

- What's the revenue breakdown by tier and country together?

The dimensions give you flexibility to analyze the metric from different angles.

## Cross-model metrics

You're not limited to one model. Combine measures and dimensions from multiple models:

```yaml
metrics:
  product_revenue_by_customer_segment:
    measure: orders.total_revenue      # From orders
    time: orders.order_date            # From orders
    dimensions:
      - products.category              # From products

      - products.brand

      - customers.customer_tier        # From customers

      - customers.region
    description: "Product revenue segmented by customer demographics"
```

This metric pulls the measure from `orders`, time from `orders`, product dimensions from `products`, and customer dimensions from `customers`. As long as you've defined the proper joins between these semantic models, Vulcan will handle the cross-model logic for you.

**Important:** Make sure your semantic models have the right joins defined, or cross-model metrics won't work.

## Reference format

Always use **dot notation** with semantic model aliases when referencing measures, dimensions, and time:

```yaml
# Good: Use aliases
measure: orders.total_revenue     # alias.measure_name
time: orders.order_date           # alias.column_name
dimensions:
  - customers.customer_tier       # alias.column_name

# Bad: Don't use physical names
measure: analytics.fact_orders.revenue
time: order_date  # Missing alias
```

The dot notation (`orders.total_revenue`) tells Vulcan which semantic model to look in and what to reference. Physical table names won't work here, you need the semantic aliases.

## Time granularity

Define metrics once, then query them at any time granularity:

```yaml
metrics:
  revenue_trends:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Revenue at any time granularity"
```

The same metric can be queried with different granularities:

- Daily: `granularity=day`

- Weekly: `granularity=week`

- Monthly: `granularity=month`

- Quarterly: `granularity=quarter`

- Yearly: `granularity=year`

You don't need separate metric definitions for each granularity, just change the query parameter.

## Complete example

Here's a more complete example showing different types of metrics:

```yaml
metrics:
  # Simple revenue metric
  daily_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Daily revenue trends"
    tags: [revenue, financial, kpi]
  
  # Customer acquisition
  customer_acquisition_trend:
    measure: customers.new_signups
    time: customers.signup_date
    dimensions:
      - customers.signup_channel

      - customers.customer_tier

      - customers.country
    description: "Customer acquisition by channel, tier, and geography"
    tags: [acquisition, growth, customer]
  
  # Cross-model metric
  product_performance:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - products.category

      - products.brand

      - customers.customer_tier
    description: "Product revenue by category, brand, and customer segment"
    tags: [revenue, products, segmentation]
```

Notice how each metric has a clear purpose, good description, and relevant tags. The tags help organize and discover metrics later.

## Benefits

### Time-series analysis

Metrics are built for analyzing trends over time:

- **Flexible granularity**: Query the same metric at different time intervals without redefinition

- **Consistent definitions**: Same calculation logic applies across all time periods

- **Trend analysis**: Built-in support for comparing periods (month-over-month, year-over-year, etc.)

### Self-service analytics

Business users can query metrics without writing SQL:

- **Simple API**: Query metrics by name with a time range and dimensions

- **Consistent results**: Same metric definition is used everywhere, so everyone gets the same answer

- **No SQL required**: Complex joins and aggregations are abstracted away

### Single source of truth

Centralized metric definitions mean:

- **Define once**: Create metric definitions in YAML files

- **Use everywhere**: Same metrics power dashboards, reports, and APIs

- **Version controlled**: Metric definitions live alongside your code, so changes are tracked

## Best practices

### Descriptive names

Make your metric names self-explanatory:

```yaml
# Good: Self-explanatory
metrics:
  monthly_revenue_by_tier: ...
  daily_active_users: ...

# Bad: Vague
metrics:
  metric_1: ...
  rev: ...
```

Good names make it obvious what the metric measures and how it's broken down.

### Include essential dimensions

Think about what business questions people will want to answer, and include those dimensions:

```yaml
# Good: Key business dimensions
metrics:
  revenue_analysis:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier

      - customers.region

      - products.category

# Too few: Limited analysis
metrics:
  revenue:
    measure: orders.total_revenue
    time: orders.order_date
    # Missing dimensions - can't slice and dice!
```

Dimensions are what make metrics useful. Without them, you can only see the overall trend, not the breakdowns that drive business decisions.

### Document business context

Add descriptions and metadata to help people understand what the metric means:

```yaml
metrics:
  net_revenue_retention:
    measure: subscriptions.nrr
    time: subscriptions.cohort_month
    description: "Net Revenue Retention: expansion minus churn"
    meta:
      business_owner: "Finance Team"
      calculation: "(Starting MRR + Expansion - Churn) / Starting MRR"
      benchmark: ">110% is good for SaaS"
```

The `meta` section is perfect for business context, calculation details, benchmarks, and ownership information. This helps people understand not just what the metric is, but what it means and how to interpret it.

## Integration with semantic models

Metrics build on top of semantic models:

1. **Semantic models** define measures, dimensions, and joins
2. **Metrics** combine these components with time for analysis
3. **APIs** expose metrics for querying and visualization

The semantic layer provides the foundation (the building blocks), and metrics add the time-series analytical capabilities (the finished product).

## Next steps

- Learn about [Semantic Models](models.md) that provide the foundation for metrics

- See the [Semantics Overview](overview.md) for the complete picture

- Explore metric definitions in your project's `semantics/` directory
