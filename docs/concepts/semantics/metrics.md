# Business Metrics

Business metrics combine measures with dimensions and time to create complete analytical definitions ready for time-series analysis.

## What are Business Metrics?

Business metrics are complete analytical definitions that:

- **Combine measures with time**: Enable time-series analysis at different granularities
- **Include dimensions**: Allow slicing and dicing by business attributes
- **Ready for analysis**: Pre-configured for dashboards, reports, and APIs
- **Examples**: `monthly_revenue_by_tier`, `daily_active_users`, `customer_acquisition_trend`

## Basic Structure

A business metric combines:

- **Measure**: The calculation to perform (e.g., `orders.total_revenue`)
- **Time**: The time dimension for analysis (e.g., `orders.order_date`)
- **Dimensions**: Optional attributes for grouping (e.g., `customers.customer_tier`)

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue      # Which measure to calculate
    time: orders.order_date            # Time dimension for analysis
    description: "Monthly revenue trends"
```

## Simple Metric

A basic metric with just a measure and time:

```yaml
metrics:
  daily_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Daily revenue trends"
```

This metric can be queried at different time granularities (day, week, month, quarter, year) without redefinition.

## Metric with Dimensions

Add dimensions for slicing and grouping:

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

This enables queries like:
- Revenue by tier over time
- Revenue by country over time
- Revenue by tier and country over time

## Cross-Model Metrics

Combine measures and dimensions from multiple models:

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

**Requirement:** Proper joins must be defined between models for cross-model metrics to work.

## Reference Format

Always use **dot notation** with semantic model aliases:

```yaml
# ✅ Good: Use aliases
measure: orders.total_revenue     # alias.measure_name
time: orders.order_date           # alias.column_name
dimensions:
  - customers.customer_tier       # alias.column_name

# ❌ Bad: Don't use physical names
measure: analytics.fact_orders.revenue
time: order_date  # Missing alias
```

## Time Granularity

Metrics support different time granularities at query time:

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

## Complete Example

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

## Benefits

### Time-Series Analysis

Metrics are designed for time-series analysis:

- **Flexible granularity**: Query the same metric at different time intervals
- **Consistent definitions**: Same calculation logic across all time periods
- **Trend analysis**: Built-in support for comparing periods

### Self-Service Analytics

Business users can query metrics without SQL:

- **Simple API**: Query metrics by name with time range and dimensions
- **Consistent results**: Same metric definition used everywhere
- **No SQL required**: Abstract away complex joins and aggregations

### Single Source of Truth

Centralized metric definitions:

- **Define once**: Create metric definitions in YAML files
- **Use everywhere**: Same metrics power dashboards, reports, and APIs
- **Version controlled**: Metric definitions live alongside your code

## Best Practices

### Descriptive Names

```yaml
# ✅ Good: Self-explanatory
metrics:
  monthly_revenue_by_tier: ...
  daily_active_users: ...

# ❌ Bad: Vague
metrics:
  metric_1: ...
  rev: ...
```

### Include Essential Dimensions

```yaml
# ✅ Good: Key business dimensions
metrics:
  revenue_analysis:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.region
      - products.category

# ❌ Too few: Limited analysis
metrics:
  revenue:
    measure: orders.total_revenue
    time: orders.order_date
    # Missing dimensions
```

### Document Business Context

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

## Integration with Semantic Models

Metrics build on semantic models:

1. **Semantic models** define measures, dimensions, and joins
2. **Metrics** combine these components with time for analysis
3. **APIs** expose metrics for querying and visualization

The semantic layer provides the foundation, and metrics add the time-series analytical capabilities.

## Next Steps

- Learn about [Semantic Models](models.md) that provide the foundation for metrics
- See the [Semantics Overview](index.md) for the complete picture
- Explore metric definitions in your project's `semantics/` directory

