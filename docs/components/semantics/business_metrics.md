# Business Metrics

Business metrics are where your semantic layer really shines. They combine measures (the calculations) with slices (the attributes for grouping) and time (the when) to create complete analytical definitions that are ready for time-series analysis.

Semantic models provide the building blocks (measures, dimensions, joins), and business metrics combine those blocks into something you can analyze over time. They're pre-configured for dashboards, reports, and APIs, no SQL required.

## What are business metrics?

Business metrics are complete analytical definitions that:

- **Combine measures with time**: Let you analyze trends at different time granularities (daily, weekly, monthly, etc.)

- **Include slices**: Enable slicing and dicing by business attributes (customer segment, region, product category, etc.)

- **Ready for analysis**: Pre-configured so they can power dashboards, reports, and APIs directly

- **Examples**: `monthly_sales_performance`, `avg_order_value_trend`, `customer_balance_by_segment`

They're the bridge between your technical data models and the business questions people actually want to answer.

## Basic structure

A business metric brings together three things:

- **Measure**: The calculation you want to perform (like `orders.total_sales`)

- **Time**: The time dimension for your analysis (like `orders.ORDERDATE`)

- **Slices**: Named attributes for grouping and filtering (like `market_segment: customers.MKTSEGMENT`)

Here's the simplest possible metric:

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_sales        # Which measure to calculate
    time: orders.ORDERDATE             # Time dimension for analysis
```

That's it! This metric is now ready to be queried at any time granularity you want.

## Simple metric

Let's start with the basics, a metric that just has a measure and time:

```yaml
metrics:
  gross_revenue_trend:
    measure: lineitems.gross_revenue
    time: lineitems.SHIPDATE
    slices:
      line_status: lineitems.LINESTATUS
    tags:
      - tpch
      - lineitem
      - revenue
```

Even though you define time with a specific column, you're not locked into one granularity. You can query this same metric at different time intervals (day, week, month, quarter, year) without redefining it. The metric definition stays the same; you just change the granularity when you query it.

## Metric with slices

Add slices to enable grouping and filtering. Slices are named key-value pairs that map a friendly name to a dimension:

```yaml
metrics:
  monthly_sales_performance:
    measure: orders.total_sales
    time: orders.ORDERDATE
    slices:
      order_status: orders.ORDERSTATUS
      market_segment: customers.MKTSEGMENT
    tags:
      - tpch
      - sales
      - revenue
      - monthly
    terms:
      - glossary.total_sales
      - glossary.revenue_metric
```

Now you can answer questions like:

- What's our sales by order status over time?

- How does revenue vary by market segment?

- What's the sales breakdown by status and segment together?

The slices give you flexibility to analyze the metric from different angles. The named keys (`order_status`, `market_segment`) make queries more readable than anonymous dimension lists.

## Cross-model metrics

You're not limited to one model. Combine measures and slices from multiple models:

```yaml
metrics:
  customer_balance_by_segment:
    measure: customers.avg_acctbal
    time: orders.ORDERDATE
    slices:
      market_segment: customers.MKTSEGMENT
      nation: nations.NAME
    tags:
      - tpch
      - customer
      - balance
    terms:
      - glossary.customer_balance
      - glossary.account_metric
```

This metric pulls the measure from `customers`, time from `orders`, and slices from both `customers` and `nations`. As long as you've defined the proper joins between these semantic models, Vulcan will handle the cross-model logic for you.

**Important:** Make sure your semantic models have the right joins defined, or cross-model metrics won't work.

## Reference format

Always use **dot notation** with semantic model aliases when referencing measures, slices, and time:

```yaml
# Good: Use aliases
measure: orders.total_sales       # alias.measure_name
time: orders.ORDERDATE            # alias.column_name
slices:
  market_segment: customers.MKTSEGMENT   # key: alias.column_name

# Bad: Don't use physical names
measure: analytics.fact_orders.revenue
time: order_date  # Missing alias
```

The dot notation (`orders.total_sales`) tells Vulcan which semantic model to look in and what to reference. Physical table names won't work here, you need the semantic aliases.

## Time granularity

Define metrics once, then query them at any time granularity:

```yaml
metrics:
  revenue_trends:
    measure: orders.total_sales
    time: orders.ORDERDATE
```

The same metric can be queried with different granularities:

- Daily: `granularity=day`

- Weekly: `granularity=week`

- Monthly: `granularity=month`

- Quarterly: `granularity=quarter`

- Yearly: `granularity=year`

You don't need separate metric definitions for each granularity, just change the query parameter.

## Complete example

Here's a comprehensive example showing different types of metrics with the full syntax:

```yaml
metrics:
  # ============================================================================
  # ORDER REVENUE METRICS
  # ============================================================================
  monthly_sales_performance:
    measure: orders.total_sales
    time: orders.ORDERDATE
    slices:
      order_status: orders.ORDERSTATUS
      market_segment: customers.MKTSEGMENT
    tags:
      - tpch
      - sales
      - revenue
      - monthly
    terms:
      - glossary.total_sales
      - glossary.revenue_metric

  avg_order_value_trend:
    measure: orders.avg_order_value
    time: orders.ORDERDATE
    slices:
      market_segment: customers.MKTSEGMENT
      order_priority: orders.ORDERPRIORITY
    tags:
      - tpch
      - orders
      - aov
    terms:
      - glossary.average_order_value

  order_volume_by_priority:
    measure: orders.total_orders
    time: orders.ORDERDATE
    slices:
      order_priority: orders.ORDERPRIORITY
      order_status: orders.ORDERSTATUS
    tags:
      - tpch
      - orders
      - volume

  # ============================================================================
  # LINE ITEM REVENUE METRICS
  # ============================================================================
  net_revenue_by_ship_mode:
    measure: lineitems.net_revenue
    time: lineitems.SHIPDATE
    slices:
      ship_mode: lineitems.SHIPMODE
      return_flag: lineitems.RETURNFLAG
    tags:
      - tpch
      - lineitem
      - revenue
      - shipping
    terms:
      - glossary.net_revenue
      - glossary.shipping_metric

  gross_revenue_trend:
    measure: lineitems.gross_revenue
    time: lineitems.SHIPDATE
    slices:
      line_status: lineitems.LINESTATUS
    tags:
      - tpch
      - lineitem
      - revenue

  avg_discount_trend:
    measure: lineitems.avg_discount
    time: lineitems.SHIPDATE
    slices:
      ship_mode: lineitems.SHIPMODE
    tags:
      - tpch
      - lineitem
      - discount

  # ============================================================================
  # CUSTOMER METRICS
  # ============================================================================
  customer_balance_by_segment:
    measure: customers.avg_acctbal
    time: orders.ORDERDATE
    slices:
      market_segment: customers.MKTSEGMENT
      nation: nations.NAME
    tags:
      - tpch
      - customer
      - balance
    terms:
      - glossary.customer_balance
      - glossary.account_metric
```

Notice how each metric has:
- A clear, descriptive name
- A measure and time reference
- Named slices for grouping dimensions
- Tags for organization and discovery
- Terms linking to business glossary definitions (optional)

## Benefits

### Time-series analysis

Metrics are built for analyzing trends over time:

- **Flexible granularity**: Query the same metric at different time intervals without redefinition

- **Consistent definitions**: Same calculation logic applies across all time periods

- **Trend analysis**: Built-in support for comparing periods (month-over-month, year-over-year, etc.)

### Self-service analytics

Business users can query metrics without writing SQL:

- **Simple API**: Query metrics by name with a time range and slices

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
  monthly_sales_performance: ...
  avg_order_value_trend: ...
  customer_balance_by_segment: ...

# Bad: Vague
metrics:
  metric_1: ...
  rev: ...
```

Good names make it obvious what the metric measures and how it's broken down.

### Include essential slices

Think about what business questions people will want to answer, and include those slices:

```yaml
# Good: Key business slices with named keys
metrics:
  revenue_analysis:
    measure: orders.total_sales
    time: orders.ORDERDATE
    slices:
      order_status: orders.ORDERSTATUS
      market_segment: customers.MKTSEGMENT
      order_priority: orders.ORDERPRIORITY
    tags:
      - revenue
      - analysis

# Too few: Limited analysis
metrics:
  revenue:
    measure: orders.total_sales
    time: orders.ORDERDATE
    # Missing slices - can't group or filter!
```

Slices are what make metrics useful. Without them, you can only see the overall trend, not the breakdowns that drive business decisions. Named slice keys also make queries more readable.

### Document business context

Add tags and terms to help people understand what the metric means:

```yaml
metrics:
  net_revenue_by_ship_mode:
    measure: lineitems.net_revenue
    time: lineitems.SHIPDATE
    slices:
      ship_mode: lineitems.SHIPMODE
      return_flag: lineitems.RETURNFLAG
    tags:
      - tpch
      - lineitem
      - revenue
      - shipping
    terms:
      - glossary.net_revenue
      - glossary.shipping_metric
```

Tags help organize and discover metrics, while terms link to your business glossary for consistent definitions. This helps people understand not just what the metric is, but what it means and how to interpret it.

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
