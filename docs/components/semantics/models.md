# Semantic Models

Semantic models are your bridge between technical data structures and business understanding. They take your physical Vulcan models (the tables and columns in your database) and map them to business concepts that make sense to analysts, product managers, and other non-technical users.

Think of semantic models as a translation layer. Your database might have tables named `dim_customers` or `fact_orders` (technical naming), but your semantic layer can expose them as `customers` and `orders` (business-friendly naming). More importantly, semantic models define what you can actually do with the data—dimensions for grouping, measures for calculations, segments for filtering, and joins for combining models.

## What are semantic models?

Semantic models bridge the gap between technical table structures and business understanding:

- **Reference physical models**: Each semantic model references a Vulcan model defined in your `models/` directory
- **Provide business aliases**: Hide technical naming (like `dim_customers` or `fact_orders`) behind consumer-friendly names
- **Expose analytical capabilities**: Define dimensions, measures, segments, and joins for each model

They're the foundation of your semantic layer, everything else (business metrics, semantic queries) builds on top of semantic models.

## Basic structure

A semantic model maps a physical Vulcan model to a semantic representation. Here's the basic structure:

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

The physical model name (`analytics.customers`) is the key, and everything else defines how it appears in the semantic layer.

## Dimensions

Dimensions are attributes you use for grouping and filtering. They answer "by what?" questions, like "revenue by customer tier" or "orders by country."

**The good news:** All columns from your Vulcan model automatically become dimensions. You don't have to define them manually unless you want to control which ones are exposed or add enhancements.

Here's how you can control dimensions:

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
  
  # Enhance dimensions with additional capabilities:
  enhancements:
    - name: start_date
      granularities:
        - name: monthly
          interval: "1 month"
          description: "Monthly subscription cohorts"
        - name: quarterly
          interval: "3 months"
          description: "Quarterly cohorts"
```

Use `excludes` to hide sensitive or internal columns. Use `enhancements` to add time granularities for cohort analysis, super useful for subscription or signup dates.

## Measures

Measures are aggregated calculations that answer "how much?" or "how many?" questions. They're what you use to calculate totals, averages, counts, and other aggregations.

You define measures using SQL expressions with aggregations like `SUM()`, `COUNT()`, `AVG()`, etc.:

```yaml
measures:
  total_revenue:
    type: sum
    expression: "{customers.amount}"
    description: "Total revenue from all orders"
    format: currency
  
  avg_order_value:
    type: number
    expression: "SUM({customers.total_revenue}) / NULLIF(COUNT(*), 0)"
    format: currency
    description: "Average order value"
  
  active_customers:
    type: count_distinct
    expression: "{customers.customer_id}"
    filters:
      - "{customers.status} = 'active'"
    description: "Number of active customers"
```

Notice the curly braces around column references like `{customers.amount}`? That's the semantic reference syntax. We'll talk more about that in the best practices section.

Measures can have filters (like `active_customers` above), which let you calculate metrics on subsets of data. They can also have formatting hints (like `currency`) to help visualization tools display them correctly.

## Segments

Segments are reusable filter conditions that answer "which ones?" questions. They define meaningful subsets of your data that you can use across multiple queries and metrics.

Think of segments as saved filters. Instead of writing `WHERE status = 'active'` every time, you define an `active_customers` segment once and reuse it:

```yaml
segments:
  active_customers:
    expression: "{customers.status} = 'active'"
    description: "Customers with active subscriptions"
  
  high_value:
    expression: "{customers.total_spent} > 10000"
    description: "Customers who spent over $10K"
  
  recent_signups:
    expression: "{customers.signup_date} >= CURRENT_DATE - INTERVAL '30 days'"
    description: "Customers who signed up in last 30 days"
```

Segments make your semantic layer more consistent, everyone uses the same definition of "active customers" or "high value," so there's no confusion about what those terms mean.

## Joins

Joins define relationships between semantic models. They're what enable cross-model analysis, like combining order data with customer data or product data.

You define the relationship type (`one_to_one`, `one_to_many`, `many_to_one`) and the join expression:

```yaml
joins:
  customers:
    type: many_to_one
    expression: "{orders.customer_id} = {customers.customer_id}"
    description: "Order's customer"
  
  products:
    type: many_to_one
    expression: "{orders.product_id} = {products.product_id}"
    description: "Ordered product"
```

The relationship type helps Vulcan understand the cardinality, which is important for aggregations and preventing double-counting. The expression is the actual SQL join condition, using semantic references with curly braces.

## Cross-model analysis

Once you've defined joins, you can reference columns and measures from other models in your current model's definitions. This is where semantic models really shine, you can build complex analytical definitions that span multiple models.

### Referencing joined model fields

You can use columns from joined models in measure expressions and filters:

```yaml
measures:
  enterprise_revenue:
    type: sum
    expression: "{orders.amount}"
    filters:
      - "{customers.customer_tier} = 'Enterprise'"
    description: "Revenue from Enterprise customers"
```

Even though `enterprise_revenue` is defined on the `orders` model, it filters by `customers.customer_tier` from the joined `customers` model. Vulcan handles the join logic automatically.

### Proxy dimensions

Proxy dimensions let you expose measures from joined models as dimensions on the current model. This is useful when you want to filter or group by aggregated values from other models:

```yaml
dimensions:
  proxies:
    - name: plan_average_monthly_price
      measure: subscription_plans.avg_monthly_price
    
    - name: plan_average_annual_price
      measure: subscription_plans.avg_annual_price
```

**Requirements:**
- The referenced model must be joined to the current model
- The measure must exist on the target model
- Use the format `model_alias.measure_name`

Proxy dimensions are powerful, they let you analyze one model using aggregated values from another model, all without writing complex SQL.

## Complete example

Here's a complete semantic model definition that brings it all together:

```yaml
models:
  analytics.customers:
    alias: customers
    
    dimensions:
      excludes:
        - password_hash
        - internal_notes
      enhancements:
        - name: signup_date
          granularities:
            - name: monthly
              interval: "1 month"
              description: "Monthly signup cohorts"
            - name: quarterly
              interval: "3 months"
              description: "Quarterly signup cohorts"
    
    measures:
      total_customers:
        type: count
        expression: "{customers.customer_id}"
        description: "Total number of customers"
      
      active_customers:
        type: count_distinct
        expression: "{customers.customer_id}"
        filters:
          - "{customers.status} = 'active'"
        description: "Number of active customers"
    
    segments:
      active:
        expression: "{customers.status} = 'active'"
        description: "Active customers"
      
      high_value:
        expression: "{customers.total_spent} > 10000"
        description: "High-value customers"
    
    joins:
      orders:
        type: one_to_many
        expression: "{customers.customer_id} = {orders.customer_id}"
        description: "Customer's orders"
```

This semantic model:
- Exposes customer dimensions (with some exclusions and enhancements)
- Defines customer measures (total and active counts)
- Creates reusable segments (active and high-value customers)
- Joins to orders for cross-model analysis

## Best practices

### Use business-friendly aliases

Your aliases should make sense to business users, not just developers:

```yaml
# ✅ Good: Consumer-friendly
alias: customers
alias: orders
alias: subscriptions

# ❌ Bad: Technical naming
alias: dim_customers
alias: fact_orders
```

The whole point of semantic models is to hide technical complexity. Don't bring it back with technical naming!

### Design models with semantics in mind

When you're building your Vulcan models, think about how they'll be used semantically:

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

Clean, descriptive column names make semantic models easier to build and use. Avoid abbreviations and technical jargon.

### Document business logic

Add descriptions and metadata to help people understand what measures and segments mean:

```yaml
measures:
  total_revenue:
    type: sum
    expression: "{orders.amount}"
    description: "Total revenue from all completed orders"
    meta:
      business_owner: "Finance Team"
      calculation_method: "Sum of order amounts excluding refunds"
```

The `meta` section is perfect for business context, ownership, calculation details, and other information that helps people understand and trust the metric.

### Use curly braces for references

When referencing any column or measure anywhere in your semantic model definitions, always use curly braces `{}`:

```yaml
# ✅ Good: Use curly braces for all references
measures:
  total_revenue:
    type: sum
    expression: "{orders.amount}"  # Column reference with curly braces
  
  active_customers:
    type: count_distinct
    expression: "{customers.customer_id}"  # Column reference with curly braces
    filters:
      - "{customers.status} = 'active'"  # Column reference in filter

segments:
  high_value:
    expression: "{customers.total_spent} > 10000"  # Column reference with curly braces

joins:
  customers:
    type: many_to_one
    expression: "{orders.customer_id} = {customers.customer_id}"  # Both references use curly braces
```

**Why use curly braces?**
- Clear distinction between semantic references and SQL functions
- Consistent syntax across all semantic model definitions
- Prevents ambiguity in complex expressions
- Required for cross-model references (e.g., `{customers.customer_tier}`)

It's a best practice that makes your semantic models more maintainable and less error-prone.

## Validation

Vulcan automatically validates semantic model definitions when you create a plan. It checks:

- All column references in measures exist
- All column references in segments exist
- Join expressions reference valid columns
- Cross-model references have valid join paths
- Semantic aliases are properly defined

If something's wrong, you'll know about it before you try to use the semantic layer. This catches errors early and keeps your semantic models reliable.

## Next steps

- Learn about [Business Metrics](../../../../business_semantics/business_metrics.md) that combine measures with time and dimensions
- Explore semantic model examples in your project's `semantics/` directory
- See the [Semantics Overview](overview.md) for the complete picture
