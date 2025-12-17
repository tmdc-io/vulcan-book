# Overview

The semantic layer adds **business context** to your Vulcan data models, transforming technical table structures into business-friendly definitions that can be queried without SQL knowledge.

## What is the Semantic Layer?

The semantic layer bridges the gap between physical tables and business understanding. It provides a consistent, business-friendly interface to your data that enables self-service analytics while maintaining a single source of truth for business logic.

### Key Benefits

**For Developers:**

- ✅ Define metrics once, use everywhere
<!-- - ✅ Automatic validation catches errors early -->
- ✅ Version-controlled business logic
- ✅ Consistent calculations across tools

**For Business Users:**

- ✅ Self-service analytics without SQL
- ✅ Consistent metric definitions
- ✅ Trusted, validated data
- ✅ Works across BI tools and APIs

**For Organizations:**

- ✅ Single source of truth for metrics
- ✅ Faster time to insights
- ✅ Reduced data team bottleneck
- ✅ Better data governance

## Core Components

The semantic layer consists of two main components:

### [Semantic Models](models.md)

Semantic models map physical Vulcan models to business concepts:

- **Map physical models**: Reference your Vulcan models defined in `models/` directory
- **Expose dimensions**: All model columns automatically become dimensions for filtering and grouping
- **Define measures**: Aggregated calculations like `SUM(amount)`, `COUNT(*)`
- **Create segments**: Reusable filter conditions for meaningful data subsets
- **Establish joins**: Relationships between models for cross-model analysis

```yaml
models:
  analytics.customers:
    alias: customers
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
```

### [Business Metrics](business_metrics.md)

Business metrics combine measures with dimensions and time to create complete analytical definitions:

- **Time-series analysis**: Metrics include time dimensions for trend analysis
- **Flexible granularity**: Query the same metric at different time intervals (day, week, month, etc.)
- **Multi-dimensional**: Slice and dice by business attributes
- **Ready for dashboards**: Pre-configured for visualization tools

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
```

## How It Works

1. **Define semantic models**: Create YAML files that reference your Vulcan models
2. **Add measures and dimensions**: Define what can be calculated and filtered
3. **Create joins**: Connect models for cross-model analysis
4. **Define metrics**: Combine measures with time and dimensions for analysis
5. **Validate**: Vulcan automatically validates semantic definitions during `plan` creation
6. **Query**: Use the semantic layer via APIs or export to BI tools

## File Organization

Semantic layer definitions are YAML files in the `semantics/` directory:

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

Vulcan automatically merges all YAML files in the `semantics/` directory. File naming doesn't matter - organize by domain or model for clarity.

## Integration with Models

**Key Insight:** Model columns automatically become dimensions. The semantic layer adds measures, segments, joins, and metrics on top.

When designing Vulcan models, keep the semantic layer in mind:

```sql
-- ✅ Good: Clean column names, business-friendly
MODEL (name analytics.customers);
SELECT
  customer_id,
  customer_tier,      -- Good dimension name
  signup_date,        -- Good time dimension
  total_spent         -- Good for segments
FROM raw.customers;
```

## Next Steps

- Learn about [Semantic Models](models.md) - mapping physical models to business concepts
- Explore [Business Metrics](metrics.md) - time-series analytical definitions
- Learn about [Transpiling Semantic Queries](../../guides/transpiling_semantics.md) - converting semantic queries to SQL
- See examples in your Vulcan project's `semantics/` directory

