# Semantic Models

Semantic models map physical Vulcan models to business concepts, providing business-friendly names and exposing analytical capabilities through dimensions, measures, segments, and joins.

## What are Semantic Models?

Semantic models bridge the gap between technical table structures and business understanding:

- **Reference physical models**: Each semantic model references a Vulcan model defined in your `models/` directory
- **Provide business aliases**: Hide technical naming (like `dim_customers` or `fact_orders`) behind consumer-friendly names
- **Expose analytical capabilities**: Define dimensions, measures, segments, and joins for each model

## Basic Structure

A semantic model maps a physical Vulcan model to a semantic representation:

```yaml
models:
  analytics.customers:  # Physical model name (dictionary key)
    alias: customers     # Business-friendly semantic alias
    description: "Customer master data"
    dimensions: {...}    # Optional: control which columns are exposed
    measures: {...}      # Optional: aggregated calculations
    segments: {...}      # Optional: reusable filter conditions
    joins: {...}         # Optional: relationships to other models
```

## Dimensions

Dimensions are attributes for grouping and filtering:

- **Automatically exposed**: All columns from your Vulcan model become dimensions automatically
- **Answer "by what?" questions**: Use dimensions to slice and dice your data
- **Examples**: `customer_tier`, `country`, `order_date`, `product_category`

```yaml
# All columns from analytics.customers automatically become dimensions:
# - customers.customer_id
# - customers.customer_tier
# - customers.signup_date
# - customers.country

# You can control which columns are exposed:
dimensions:
  excludes:
    - password_hash       # Hide sensitive data
    - internal_notes
  overrides:
    customer_tier:
      tags: [segmentation, revenue]
      meta:
        business_owner: "Marketing Team"
```

## Measures

Measures are aggregated calculations:

- **Answer "how much?" or "how many?" questions**: Calculate totals, averages, counts, etc.
- **SQL expressions**: Use aggregations like `SUM(amount)`, `COUNT(*)`, `AVG(value)`
- **Examples**: `total_revenue`, `customer_count`, `avg_order_value`

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Total revenue from all orders"
    format: currency
  
  avg_order_value:
    type: expression
    expression: "SUM(amount) / NULLIF(COUNT(*), 0)"
    format: currency
    description: "Average order value"
  
  active_customers:
    type: count_distinct
    expression: "COUNT(DISTINCT customer_id)"
    filters:
      - "status = 'active'"
    description: "Number of active customers"
```

## Segments

Segments are reusable filter conditions:

- **Answer "which ones?" questions**: Define meaningful subsets of data
- **Reusable filters**: Use segments across multiple queries and metrics
- **Examples**: `active_customers`, `high_value`, `recent_signups`

```yaml
segments:
  active_customers:
    expression: "status = 'active'"
    description: "Customers with active subscriptions"
  
  high_value:
    expression: "total_spent > 10000"
    description: "Customers who spent over $10K"
  
  recent_signups:
    expression: "signup_date >= CURRENT_DATE - INTERVAL '30 days'"
    description: "Customers who signed up in last 30 days"
```

## Joins

Joins define relationships between semantic models:

- **Connect models**: Enable cross-model analysis
- **Relationship types**: `one_to_one`, `one_to_many`, `many_to_one`
- **Examples**: `orders → customers`, `subscriptions → customers`

```yaml
joins:
  customers:
    type: many_to_one
    expression: "orders.customer_id = customers.customer_id"
    description: "Order's customer"
  
  products:
    type: many_to_one
    expression: "orders.product_id = products.product_id"
    description: "Ordered product"
```

Once joined, you can reference other model's columns in measures:

```yaml
measures:
  enterprise_revenue:
    type: sum
    expression: "SUM(orders.amount)"
    filters:
      - "customers.customer_tier = 'Enterprise'"
    description: "Revenue from Enterprise customers"
```

## Complete Example

```yaml
models:
  analytics.customers:
    alias: customers
    
    dimensions:
      excludes:
        - password_hash
        - internal_notes
      overrides:
        customer_tier:
          tags: [segmentation, revenue]
          meta:
            business_owner: "Marketing Team"
    
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
        description: "Total number of customers"
      
      active_customers:
        type: count_distinct
        expression: "COUNT(DISTINCT customer_id)"
        filters:
          - "status = 'active'"
        description: "Number of active customers"
    
    segments:
      active:
        expression: "status = 'active'"
        description: "Active customers"
      
      high_value:
        expression: "total_spent > 10000"
        description: "High-value customers"
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
        description: "Customer's orders"
```

## Best Practices

### Use Business-Friendly Aliases

```yaml
# ✅ Good: Consumer-friendly
alias: customers
alias: orders
alias: subscriptions

# ❌ Bad: Technical naming
alias: dim_customers
alias: fact_orders
```

### Design Models with Semantics in Mind

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

### Document Business Logic

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Total revenue from all completed orders"
    meta:
      business_owner: "Finance Team"
      calculation_method: "Sum of order amounts excluding refunds"
```

## Validation

Vulcan automatically validates semantic model definitions during `plan` creation:

- ✅ All column references in measures exist
- ✅ All column references in segments exist
- ✅ Join expressions reference valid columns
- ✅ Cross-model references have valid join paths
- ✅ Semantic aliases are properly defined

## Next Steps

- Learn about [Business Metrics](metrics.md) that combine measures with time and dimensions
- Explore semantic model examples in your project's `semantics/` directory
- See the [Semantics Overview](index.md) for the complete picture

