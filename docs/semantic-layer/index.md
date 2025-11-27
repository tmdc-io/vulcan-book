# Chapter 03: Semantic Layer

> **Add business context to your data models** - The semantic layer bridges the gap between physical tables and business understanding, making your data accessible to business users and analytics tools without requiring SQL knowledge.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 2: Models** - Understanding of:
- How Vulcan models work
- Model structure and properties
- Model columns and schemas
- Basic SQL transformations

**YAML Syntax**
- Basic YAML structure (dictionaries, lists)
- Multi-line strings (`|` syntax)
- Indentation rules

**SQL Proficiency - Level 2**
- Aggregations (`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`)
- `GROUP BY` clauses
- Basic `WHERE` conditions
- SQL expressions and calculations

**Dimensional Modeling Concepts** (helpful but not required)
- Star schema basics
- Fact tables vs dimension tables
- Measures vs dimensions

### Optional but Helpful

**Analytics Tools**
- Understanding of how BI tools query data
- Familiarity with metrics/KPIs concepts
- API usage (for querying semantic layer)

**If you're coming from other semantic layers** (like Cube.js, LookML, or dbt metrics), you'll find Vulcan's semantic layer familiar but with tighter integration to the data transformation layer.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Quick Start](#2-quick-start)
3. [Semantic Models & Aliases](#3-semantic-models--aliases)
4. [Dimensions](#4-dimensions)
5. [Measures](#5-measures)
6. [Segments](#6-segments)
7. [Joins](#7-joins)
8. [Business Metrics](#8-business-metrics)
9. [Validation Overview](#9-validation-overview)
10. [Best Practices](#10-best-practices)
11. [Quick Reference](#11-quick-reference)
12. [Summary and Next Steps](#12-summary-and-next-steps)

---

## 1. Introduction

### 1.1 What is the Semantic Layer?

The semantic layer adds **business context** to your Vulcan data models. It transforms technical table structures into business-friendly definitions that can be queried without SQL knowledge.

**Key Insight:** Your Vulcan model columns automatically become dimensions. The semantic layer adds measures, segments, joins, and metrics on top.

### 1.2 Core Concepts

**Semantic Models** - Map physical Vulcan models to business concepts
- Reference your `models/*.sql` files
- Provide business-friendly aliases
- Expose dimensions, measures, segments, and joins

**Dimensions** - Attributes for grouping and filtering
- Automatically exposed from model columns
- Answer "by what?" questions
- Examples: `customer_tier`, `country`, `order_date`

**Measures** - Aggregated calculations
- Answer "how much?" or "how many?" questions
- SQL expressions like `SUM(amount)`, `COUNT(*)`
- Examples: `total_revenue`, `customer_count`, `avg_order_value`

**Segments** - Reusable filter conditions
- Define meaningful subsets of data
- Answer "which ones?" questions
- Examples: `active_customers`, `high_value`, `recent_signups`

**Joins** - Relationships between models
- Connect semantic models together
- Enable cross-model analysis
- Examples: `orders → customers`, `subscriptions → customers`

**Business Metrics** - Complete analytical definitions
- Combine measures with dimensions and time
- Ready for time-series analysis
- Examples: `monthly_revenue_by_tier`, `daily_active_users`

### 1.3 Why Use the Semantic Layer?

**Without Semantic Layer:**
```sql
-- Business users must write SQL
SELECT 
  DATE_TRUNC('month', order_date) as month,
  customer_tier,
  SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) as revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_date >= '2024-01-01'
GROUP BY 1, 2;
```

**With Semantic Layer:**
```yaml
# Define once in YAML
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'completed'"

# Business users query via API
GET /api/metrics/revenue?
  time=order_date
  &dimensions=customer_tier
  &granularity=month
  &start=2024-01-01
```

**Benefits:**

**For Developers:**
- ✅ Define metrics once, use everywhere
- ✅ Automatic validation catches errors early
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

### 1.4 File Organization

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

**Loading:** Vulcan automatically merges all YAML files in `semantics/` directory.

**File naming:** Use any name ending in `.yml` or `.yaml`. Organize by domain or model for clarity.

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 2. Quick Start

### 2.1 Your First Semantic Model

Start with a simple model that references your Vulcan data model:

```yaml
# semantics/customers.yml
models:
  analytics.customers:  # Physical model name (dictionary key)
    alias: customers     # Business-friendly semantic alias
```

**What happens:**
- All columns from `analytics.customers` become dimensions automatically
- You can query `customers.customer_id`, `customers.customer_tier`, etc.
- No additional configuration needed for basic use

### 2.2 Your First Measure

Add a measure to calculate aggregations:

```yaml
models:
  analytics.customers:
    alias: customers
    
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
        description: "Total number of customers"
```

**Usage:**
```
GET /api/query?
  model=customers
  &measures=total_customers
```

### 2.3 Your First Segment

Create a reusable filter:

```yaml
models:
  analytics.customers:
    alias: customers
    
    segments:
      active_customers:
        expression: "status = 'active'"
        description: "Customers with active subscriptions"
```

**Usage:**
```
GET /api/query?
  model=customers
  &measures=total_customers
  &segments=active_customers
```

### 2.4 Your First Join

Connect two models:

```yaml
# semantics/orders.yml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      total_revenue:
        type: sum
        expression: "SUM(orders.amount)"
      
      enterprise_revenue:
        type: sum
        expression: "SUM(orders.amount)"
        filters:
          - "customers.customer_tier = 'Enterprise'"
```

### 2.5 Your First Business Metric

Combine measure, time, and dimensions:

```yaml
# semantics/metrics.yml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
    description: "Monthly revenue trends by customer tier"
```

**Usage:**
```
GET /api/metrics/monthly_revenue?
  granularity=month
  &start=2024-01-01
```

### 2.6 Complete Quick Start Example

```yaml
# semantics/customers.yml
models:
  analytics.customers:
    alias: customers
    
    dimensions:
      excludes:
        - password_hash
        - internal_notes
    
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
      
      active_customers:
        type: count
        expression: "COUNT(*)"
        filters:
          - "status = 'active'"
    
    segments:
      high_value:
        expression: "total_spent > 10000"
```

**Run validation:**
```bash
vulcan plan
```

Vulcan automatically validates your semantic layer definitions.

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 3. Semantic Models & Aliases

### 3.1 Basic Structure

Every semantic model references a physical Vulcan model:

```yaml
models:
  <physical_model_name>:          # REQUIRED: Dictionary key
    name: <business_name>         # Required for schema.table format (or use 'alias:')
    dimensions: ...               # Optional
    measures: ...                 # Optional
    segments: ...                 # Optional
    joins: ...                    # Optional
```

### 3.2 Model Name: Physical Reference

The `name` field must match your Vulcan model exactly:

```yaml
models:
  analytics.customers:  # References models/customers.sql
    alias: customers
  raw.orders:          # References external or raw model
    alias: orders
  events:              # Simple table name (no schema)
    alias: events
```

**Rules:**
- Must match exact Vulcan model name (case-sensitive)
- Can be `schema.table` or just `table`
- Model must exist in your Vulcan project

### 3.3 Alias: Business Name

The `alias` provides a consumer-friendly name:

```yaml
models:
  # With schema prefix - name/alias REQUIRED
  analytics.dim_customers:
    alias: customers  # ✅ Hide technical naming
  
  # Simple table name - name optional (defaults to model name)
  events:
    # No name needed, 'events' is already clean
```

**Why Aliases Matter:**
- Hides technical schemas and prefixes (`dim_`, `fact_`, etc.)
- Provides stable API as physical names change
- Makes metrics and joins readable

**Alias Requirements:**
- ✅ Required for `schema.table` format
- ✅ Must be alphanumeric with underscores: `users`, `order_items`
- ❌ Cannot contain: dots (`.`), hyphens (`-`), spaces
- ✅ Keep it consumer-friendly

### 3.4 Using Aliases in References

Once defined, use aliases everywhere:

**In Joins:**
```yaml
joins:
  customers:  # ✅ Use alias
    type: many_to_one
    expression: "orders.customer_id = customers.customer_id"
```

**In Metrics:**
```yaml
metrics:
  revenue_by_tier:
    measure: orders.total_revenue     # Use alias
    time: orders.order_date
    dimensions:
      - customers.customer_tier       # Use alias
```

**In APIs:**
```
GET /api/query?
  model=customers              # Use alias
  &measures=total_customers
  &dimensions=customer_tier
```

### 3.5 Multiple Models in One File

You can define multiple semantic models in one YAML file:

```yaml
# semantics/sales.yml
models:
  analytics.customers:
    alias: customers
    measures: {...}
  
  analytics.orders:
    alias: orders
    measures: {...}
  
  analytics.products:
    alias: products
    measures: {...}
```

Or organize by domain in separate files - Vulcan merges them all automatically.

### 3.6 Complete Example

```yaml
# semantics/b2b_saas.yml
models:
  # Customer model
  analytics.dim_customers:
    alias: customers
    
    dimensions:
      includes:
        - customer_id
        - customer_tier
        - signup_date
    
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
    
    segments:
      active:
        expression: "status = 'active'"
  
  # Subscription model
  analytics.fact_subscriptions:
    alias: subscriptions
    
    measures:
      total_mrr:
        type: sum
        expression: "SUM(mrr)"
        format: currency
    
    joins:
      customers:
        type: many_to_one
        expression: "subscriptions.customer_id = customers.customer_id"
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 4. Dimensions

Dimensions are columns you can filter and group by. By default, **all columns** from your Vulcan model become dimensions automatically.

### 4.1 Default Behavior

```sql
-- Your Vulcan model
MODEL (name analytics.customers);
SELECT
  customer_id,
  email,
  customer_tier,
  signup_date,
  company_name
FROM raw.customers;
```

```yaml
# Semantic model - all columns available as dimensions
models:
  analytics.customers:
    alias: customers
    # No dimensions block needed!
    # All 5 columns are automatically dimensions:
    # - customers.customer_id
    # - customers.email
    # - customers.customer_tier
    # - customers.signup_date
    # - customers.company_name
```

**Key Point:** You don't need to configure dimensions unless you want to hide columns or add metadata.

### 4.2 Column Selection

Control which columns are exposed:

#### Option 1: Exclude Columns (Most Common)

```yaml
dimensions:
  excludes:
    - password_hash       # Hide sensitive data
    - internal_notes
    - deleted_at
```

**Use when:** You want most columns, but need to hide a few sensitive ones.

#### Option 2: Include Only Specific Columns

```yaml
dimensions:
  includes:
    - customer_id
    - customer_tier
    - signup_date
    - company_name
```

**Use when:** Working with sensitive data models where you only expose specific columns.

**⚠️ Important:** Cannot use both `includes` and `excludes` - they're mutually exclusive.

### 4.3 Column Overrides

Add business context to important dimensions:

```yaml
dimensions:
  excludes:
    - internal_id
  
  overrides:
    customer_tier:
      tags:
        - segmentation
        - marketing
      meta:
        business_owner: "Marketing Team"
        display_name: "Customer Tier"
        sort_order: ["Free", "Pro", "Enterprise"]
    
    signup_date:
      tags:
        - temporal
        - acquisition
      meta:
        business_owner: "Growth Team"
        format: "YYYY-MM-DD"
```

**What You Can Add:**
- `tags` - Categorization labels (array)
- `meta` - Free-form metadata (dictionary)

**Common Tags:**
- **Domain:** `sales`, `marketing`, `finance`, `product`
- **Type:** `temporal`, `geographic`, `categorical`, `identifier`
- **Sensitivity:** `pii`, `sensitive`, `public`
- **Usage:** `high_priority`, `deprecated`, `experimental`

**Common Metadata Fields:**
- `business_owner` - Team responsible
- `display_name` - UI-friendly name
- `possible_values` - Valid values for enums
- `format` - Display format hints
- Custom fields as needed

### 4.4 Dimension Proxies (Cross-Model Dimensions)

When you need to use a measure from a joined model as a dimension, use dimension proxies:

```yaml
models:
  analytics.customers:
    alias: customers
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
    
    dimensions:
      proxies:
        order_count_dim:
          measure: orders.total_orders  # Reference: model.measure
    
    segments:
      has_orders:
        expression: "{order_count_dim} > 0"  # Use in segments
```

**Use Case:** Segments can only reference columns from their own model. Dimension proxies let you use measures from joined models in segment expressions.

**Syntax:** Reference dimension proxies with `{proxy_name}` in segment expressions.

### 4.5 Complete Example

```yaml
models:
  analytics.customers:
    alias: customers
    
    dimensions:
      # Hide sensitive columns
      excludes:
        - ssn
        - password_hash
        - internal_notes
      
      # Add context to key dimensions
      overrides:
        customer_tier:
          tags:
            - segmentation
            - revenue
            - core_dimension
          meta:
            business_owner: "Revenue Team"
            display_name: "Customer Tier"
            sort_order: ["Free", "Starter", "Pro", "Enterprise"]
        
        signup_date:
          tags:
            - temporal
            - acquisition
          meta:
            business_owner: "Growth Team"
            timezone: "UTC"
```

### 4.6 Best Practices

**1. Minimize Excludes**

```yaml
# ❌ Bad: Excluding too much
dimensions:
  excludes:
    - col1, col2, col3, col4, col5, col6, col7, col8

# ✅ Good: Design models with right columns
# Fix in Vulcan model instead:
SELECT
  customer_id,
  email,
  customer_tier
FROM customers;  -- Only select needed columns
```

**2. Tag Consistently**

```yaml
# ✅ Good: Consistent tagging across models
# In customers.yml
- name: customer_tier
  tags: [segmentation, revenue]

# In subscriptions.yml
- name: plan_type
  tags: [segmentation, revenue]  # Same tags

# Now easy to find all segmentation dimensions
```

**3. Document Business Logic**

```yaml
- name: customer_status
  tags: [lifecycle, critical]
  meta:
    business_owner: "Operations"
    logic: "active = has subscription, churned = cancelled > 30 days"
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 5. Measures

Measures are aggregations that calculate metrics from your data. They answer "how much?" or "how many?" questions.

### 5.1 Basic Structure

```yaml
measures:
  measure_name:                  # REQUIRED: Dictionary key
    type: count                  # REQUIRED: count, sum, avg, count_distinct, etc.
    expression: "SQL_EXPRESSION" # REQUIRED
    description: "..."           # Recommended
    filters: []                  # Optional
    format: currency             # Optional
    tags: []                     # Optional
    meta: {}                     # Optional
```

### 5.2 Simple Measures

```yaml
measures:
  total_customers:
    type: count
    expression: "COUNT(*)"
    description: "Total number of customers"
  
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Sum of all order amounts"
  
  avg_order_value:
    type: avg
    expression: "AVG(amount)"
    description: "Average order value"
```

### 5.3 Measures with Filters

Apply conditions to focus calculations:

```yaml
measures:
  completed_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'completed'"
    description: "Revenue from completed orders only"
  
  active_customers_30d:
    type: count_distinct
    expression: "customer_id"
    filters:
      - "last_activity_date >= CURRENT_DATE - INTERVAL '30 days'"
    description: "Customers active in last 30 days"
  
  enterprise_revenue:
    type: sum
    expression: "SUM(mrr)"
    filters:
      - "plan_type = 'Enterprise'"
      - "status = 'active'"
    description: "MRR from active Enterprise customers"
```

**Multiple filters** are combined with AND logic.

### 5.4 Referencing Other Measures

Build measures on top of other measures:

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
  
  total_orders:
    type: count
    expression: "COUNT(*)"
  
  avg_order_value:
    type: expression
    expression: "total_revenue / NULLIF(total_orders, 0)"
    description: "Average order value (revenue per order)"
```

Vulcan automatically resolves dependencies.

**⚠️ Important:** Always handle division by zero with `NULLIF`:

```yaml
# ❌ Bad: Can cause division by zero
- name: avg_value
  expression: "SUM(amount) / COUNT(*)"

# ✅ Good: Use NULLIF
- name: avg_value
  expression: "SUM(amount) / NULLIF(COUNT(*), 0)"
```

### 5.5 Cross-Model Measures

Reference columns from joined models:

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:  # Define join first
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      enterprise_revenue:
        type: sum
        expression: "SUM(orders.amount)"
        filters:
          - "customers.customer_tier = 'Enterprise'"
        description: "Revenue from Enterprise customers"
```

**⚠️ Requirement:** Join must be defined before referencing other model's columns.

### 5.6 Measure Formats

Hint at how values should be displayed:

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    format: currency
    description: "Total revenue in USD"
  
  conversion_rate:
    type: expression
    expression: "..."
    format: percentage
    description: "Conversion rate as percentage"
  
  avg_response_time:
    type: avg
    expression: "AVG(response_ms)"
    format: duration_ms
    description: "Average response time in milliseconds"
```

**Common formats:** `currency`, `percentage`, `number`, `duration_ms`, `bytes`

### 5.7 Common Patterns

#### Pattern 1: Distinct Counts

```yaml
measures:
  unique_customers:
    type: count_distinct
    expression: "COUNT(DISTINCT customer_id)"
  
  unique_products_sold:
    type: count_distinct
    expression: "COUNT(DISTINCT product_id)"
```

#### Pattern 2: Ratios and Percentages

```yaml
measures:
  conversion_rate:
    type: expression
    expression: |
      COUNT(DISTINCT CASE WHEN converted THEN user_id END) * 100.0 
      / NULLIF(COUNT(DISTINCT user_id), 0)
    format: percentage
```

#### Pattern 3: Conditional Aggregations

```yaml
measures:
  high_value_revenue:
    type: sum
    expression: |
      SUM(CASE 
        WHEN amount > 1000 THEN amount 
        ELSE 0 
      END)
```

**TIP:** Use filters instead of CASE when possible:

```yaml
# ❌ Less clear
- name: active_revenue
  expression: "SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END)"

# ✅ More clear
- name: active_revenue
  expression: "SUM(amount)"
  filters:
    - "status = 'active'"
```

### 5.8 Complete Example

```yaml
models:
  analytics.subscriptions:
    alias: subscriptions
    
    joins:
      customers:
        type: many_to_one
        expression: "subscriptions.customer_id = customers.customer_id"
    
    measures:
      # Basic aggregations
      total_subscriptions:
        type: count
        expression: "COUNT(*)"
        description: "Total number of subscriptions"
        tags: [count, subscription]
      
      total_mrr:
        type: sum
        expression: "SUM(mrr)"
        description: "Monthly Recurring Revenue"
        format: currency
        tags: [revenue, financial, kpi]
      
      # Filtered measures
      active_mrr:
        type: sum
        expression: "SUM(mrr)"
        filters:
          - "status = 'active'"
        description: "MRR from active subscriptions only"
        format: currency
      
      # Complex calculations
      avg_mrr_per_customer:
        type: number
        expression: "SUM(mrr) / NULLIF(COUNT(DISTINCT customer_id), 0)"
        description: "Average MRR per customer"
        format: currency
      
      # Cross-model measures
      revenue_per_tier:
        type: expression
        expression: "SUM(subscriptions.mrr) / NULLIF(COUNT(DISTINCT customers.customer_tier), 0)"
        description: "Average revenue per customer tier"
        format: currency
```

### 5.9 Best Practices

**1. Always Handle Division by Zero**

```yaml
# ✅ Good: Use NULLIF
- name: avg_value
  expression: "SUM(amount) / NULLIF(COUNT(*), 0)"
```

**2. Use Filters Instead of CASE**

```yaml
# ✅ Good: More readable
- name: active_revenue
  expression: "SUM(amount)"
  filters:
    - "status = 'active'"
```

**3. Document Business Logic**

```yaml
- name: net_revenue
  expression: "SUM(amount) - SUM(refund_amount)"
  description: "Gross revenue minus refunds"
  meta:
    business_owner: "Finance Team"
    calculation_rules: "Excludes cancelled orders, includes partial refunds"
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 6. Segments

Segments are reusable filter conditions that define meaningful subsets of your data. They answer "which ones?" questions.

### 6.1 Basic Structure

```yaml
segments:
  segment_name:                  # REQUIRED: Dictionary key
    expression: "WHERE_CLAUSE"   # REQUIRED (without WHERE keyword)
    description: "..."           # Recommended
    tags: []                     # Optional
    meta: {}                     # Optional
```

### 6.2 Simple Segments

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

### 6.3 Complex Segments

Use boolean logic for sophisticated filters:

```yaml
segments:
  at_risk_customers:
    expression: |
      status = 'active' 
      AND plan_type = 'Free'
      AND signup_date < CURRENT_DATE - INTERVAL '90 days'
      AND last_activity_date < CURRENT_DATE - INTERVAL '14 days'
    description: "Free users inactive for 14+ days (churn risk)"
  
  enterprise_segment:
    expression: |
      (plan_type = 'Enterprise' OR plan_type = 'Business')
      AND seats > 50
      AND mrr > 5000
    description: "Large enterprise accounts"
```

### 6.4 Segments are Model-Scoped

**⚠️ Important:** Segments can ONLY reference columns from their own model.

```yaml
models:
  analytics.customers:
    alias: customers
    
    segments:
      # ✅ Good: References own columns
      high_value:
        expression: "total_spent > 10000"
      
      # ❌ Bad: Cannot reference other models directly
      has_orders:
        expression: "orders.order_count > 0"  # ERROR!
```

**Solution:** Use dimension proxies for cross-model segments (see Section 4.4).

### 6.5 Using Dimension Proxies

When you need to segment based on measures from joined models:

```yaml
models:
  analytics.customers:
    alias: customers
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
    
    dimensions:
      proxies:
        order_count_dim:
          measure: orders.total_orders
    
    segments:
      has_orders:
        expression: "{order_count_dim} > 0"
        description: "Customers with at least one order"
      
      frequent_buyers:
        expression: "{order_count_dim} >= 10"
        description: "Customers with 10+ orders"
```

**Syntax:** Reference dimension proxies with `{proxy_name}` in segment expressions.

### 6.6 Common Patterns

#### Date-Based Segments

```yaml
segments:
  recent_signups:
    expression: "signup_date >= CURRENT_DATE - INTERVAL '7 days'"
    description: "Signed up in last 7 days"
  
  dormant_users:
    expression: "last_activity_date < CURRENT_DATE - INTERVAL '90 days'"
    description: "Inactive for 90+ days"
```

#### Enum/Category Segments

```yaml
segments:
  enterprise_and_business:
    expression: "plan_type IN ('Enterprise', 'Business')"
    description: "Premium plan customers"
  
  paid_plans:
    expression: "plan_type != 'Free'"
    description: "All paid subscription plans"
```

#### Numeric Range Segments

```yaml
segments:
  mid_market:
    expression: "mrr BETWEEN 1000 AND 10000"
    description: "Mid-market segment ($1K-$10K MRR)"
  
  high_engagement:
    expression: "engagement_score >= 0.7"
    description: "Users with 70%+ engagement"
```

### 6.7 Complete Example

```yaml
models:
  analytics.customers:
    alias: customers
    
    joins:
      subscriptions:
        type: one_to_many
        expression: "customers.customer_id = subscriptions.customer_id"
    
    dimensions:
      proxies:
        subscription_count_dim:
          measure: subscriptions.total_subscriptions
    
    segments:
      # Lifecycle segments
      active:
        expression: "status = 'active'"
        description: "Active customers"
        tags: [lifecycle, core]
      
      # Value-based segments
      high_value:
        expression: "total_spent > 10000"
        description: "Lifetime spend over $10K"
        tags: [segmentation, revenue]
      
      # Behavior-based segments (using dimension proxies)
      has_subscription:
        expression: "{subscription_count_dim} > 0"
        description: "Customers with at least one subscription"
        tags: [behavior, conversion]
```

### 6.8 Best Practices

**1. Make Segments Mutually Exclusive (When Appropriate)**

```yaml
# ✅ Good: Clear lifecycle stages
segments:
  trial:
    expression: "status = 'trial'"
  
  active:
    expression: "status = 'active'"
  
  churned:
    expression: "status = 'churned'"
```

**2. Document Business Logic**

```yaml
- name: at_risk
  expression: "..."
  description: "Customers likely to churn based on engagement"
  meta:
    business_owner: "Customer Success"
    criteria: "Active plan, no activity 14+ days, engagement score < 0.3"
```

**3. Use Descriptive Names**

```yaml
# ❌ Bad: Unclear
- name: seg_1
  expression: "..."

# ✅ Good: Self-explanatory
- name: high_value_at_risk
  expression: "..."
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 7. Joins

Joins define relationships between semantic models, enabling cross-model measures and dimensions.

### 7.1 Basic Structure

```yaml
joins:
  <target_model_alias>:           # REQUIRED: Dictionary key
    type: <relationship_type>    # REQUIRED: one_to_many, many_to_one, one_to_one
    expression: "JOIN_CONDITION"  # REQUIRED
    description: "..."            # Optional
    meta: {}                      # Optional
```

### 7.2 Relationship Types

| Relationship | Meaning | Example |
|--------------|---------|---------|
| `one_to_many` | 1 → N | Customer → Orders (1 customer, many orders) |
| `many_to_one` | N → 1 | Orders → Customer (many orders, 1 customer) |
| `one_to_one` | 1 → 1 | User → Profile (1 user, 1 profile) |

### 7.3 Simple Join

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:  # Target semantic model alias (dictionary key)
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
        description: "Orders belong to one customer"
```

### 7.4 Join Expression Rules

**✅ Complete SQL with full model references:**

```yaml
# ✅ Good: Full model.column syntax
expression: "orders.customer_id = customers.customer_id"

# ❌ Bad: Incomplete
expression: "customer_id = customer_id"  # Which table?

# ❌ Bad: Column only
expression: "customer_id"  # Not a join condition
```

**Use semantic model aliases** (not physical table names):

```yaml
# ✅ Good: Use alias
- name: customers  # Semantic alias
  expression: "orders.customer_id = customers.customer_id"

# ❌ Bad: Don't use physical name
- name: analytics.dim_customers  # Physical name
  expression: "..."
```

### 7.5 Multiple Joins

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      # Join to customers
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
        description: "Order's customer"
      
      # Join to products
      products:
        type: many_to_one
        expression: "orders.product_id = products.product_id"
        description: "Ordered product"
```

### 7.6 Using Joins in Measures

Once joined, reference other model's columns:

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      # Reference orders columns (same model)
      total_revenue:
        type: sum
        expression: "SUM(orders.amount)"
      
      # Reference customers columns (joined model)
      enterprise_revenue:
        type: sum
        expression: "SUM(orders.amount)"
        filters:
          - "customers.customer_tier = 'Enterprise'"
        description: "Revenue from Enterprise customers"
```

### 7.7 Bidirectional Joins

Define joins from both sides:

```yaml
# customers.yml
models:
  analytics.customers:
    alias: customers
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
```

```yaml
# orders.yml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
```

Now you can start from either model.

### 7.8 Complete Example

```yaml
# orders.yml
models:
  analytics.orders:
    alias: orders
    
    joins:
      # Customer relationship
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
        description: "Customer who placed the order"
      
      # Product relationship
      products:
        type: many_to_one
        expression: "orders.product_id = products.product_id"
        description: "Product that was ordered"
    
    measures:
      # Order metrics
      total_orders:
        type: count
        expression: "COUNT(*)"
      
      total_revenue:
        type: sum
        expression: "SUM(orders.amount)"
      
      # Customer-segmented metrics
      enterprise_revenue:
        type: sum
        expression: "SUM(orders.amount)"
        filters:
          - "customers.customer_tier = 'Enterprise'"
```

### 7.9 Best Practices

**1. Define Joins at Source of Foreign Key**

```yaml
# ✅ Good: Define in orders (has customer_id FK)
models:
  analytics.orders:
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
```

**2. Document Cardinality**

```yaml
joins:
  customers:
    type: many_to_one
    description: "Orders belong to one customer"
    meta:
      cardinality: "N:1"
      expected_match_rate: 0.99
```

**3. Use Full Model.Column Syntax**

```yaml
# ✅ Good: Clear and explicit
expression: "orders.customer_id = customers.customer_id"

# ❌ Bad: Ambiguous
expression: "customer_id = customer_id"
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 8. Business Metrics

Business metrics combine measures with dimensions to create complete analytical definitions ready for time-series analysis.

### 8.1 Basic Structure

```yaml
metrics:
  metric_name:                   # REQUIRED
    measure: model.measure_name  # REQUIRED
    time: model.date_column      # REQUIRED
    dimensions: []               # Optional
    description: "..."           # Optional
    tags: []                     # Optional
    meta: {}                     # Optional
```

### 8.2 Simple Metric

```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue      # Which measure to calculate
    time: orders.order_date            # Time dimension for analysis
    description: "Monthly revenue trends"
```

**Usage:**
```
GET /api/metrics/monthly_revenue?
  granularity=month
  &start=2024-01-01
  &end=2024-12-31
```

### 8.3 Metric with Dimensions

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

**Usage:**
```
GET /api/metrics/revenue_by_tier?
  granularity=month
  &dimensions=customer_tier,country
  &start=2024-01-01
```

### 8.4 Cross-Model Metrics

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

**⚠️ Requirement:** Proper joins must be defined between models.

### 8.5 Reference Format

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

### 8.6 Time Granularity

Metrics support different time granularities at query time:

```yaml
metrics:
  revenue_trends:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Revenue at any time granularity"
```

**Query with different granularities:**
```
# Daily
GET /api/metrics/revenue_trends?granularity=day

# Weekly
GET /api/metrics/revenue_trends?granularity=week

# Monthly
GET /api/metrics/revenue_trends?granularity=month

# Quarterly
GET /api/metrics/revenue_trends?granularity=quarter

# Yearly
GET /api/metrics/revenue_trends?granularity=year
```

### 8.7 Complete Example

```yaml
metrics:
  # Simple revenue metric
  daily_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    description: "Daily revenue trends"
    tags: [revenue, financial, kpi]
    meta:
      business_owner: "Finance Team"
      refresh_schedule: "hourly"
  
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

### 8.8 Best Practices

**1. Name Metrics Descriptively**

```yaml
# ❌ Bad: Vague
metrics:
  metric_1: ...
  rev: ...

# ✅ Good: Self-explanatory
metrics:
  monthly_revenue_by_tier: ...
  daily_active_users: ...
```

**2. Include Essential Dimensions**

```yaml
# ❌ Too few: Limited analysis
metrics:
  revenue:
    measure: orders.total_revenue
    time: orders.order_date
    # Missing dimensions

# ✅ Good: Key business dimensions
metrics:
  revenue_analysis:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.region
      - products.category
```

**3. Document Business Context**

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

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 9. Validation Overview

When you run `vulcan plan` or start your Vulcan project, **all semantic models are automatically validated**. This catches configuration errors before any queries run.

### 9.1 What Gets Validated

- ✅ All column references in measures exist
- ✅ All column references in segments exist
- ✅ Join expressions reference valid columns
- ✅ Cross-model references have valid join paths
- ✅ Metric references point to existing models
- ✅ Semantic aliases are properly defined

### 9.2 When Validation Fails

Vulcan shows detailed error messages with:
- File name and location
- Which object has the error
- What's wrong
- How to fix it

**Example:**
```
Model `customers` (semantics/customers.yml)
measure 'total_revenue' references unknown field 'amount_total'
(must be a column or measure in current model)
```

### 9.3 Common Validation Errors

#### Error 1: Unknown Column

**Error:**
```
Model `customers` (semantics/customers.yml)
measure 'bad_measure' references unknown field 'revenue_amount'
```

**Fix:** Check your Vulcan model's column names and update the semantic definition.

#### Error 2: Missing Alias

**Error:**
```
Semantic model 'analytics.customers' must have a 'name' or 'alias' field
```

**Fix:** Add name/alias:
```yaml
models:
  analytics.customers:
    alias: customers  # ✅ Add this
```

#### Error 3: Cross-Model Reference Without Join

**Error:**
```
Model `orders` (semantics/orders.yml)
measure 'customer_revenue' references 'customers.total_spent' but no join path exists
```

**Fix:** Add join definition:
```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:  # ✅ Define join
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
```

#### Error 4: Segment Cross-Model Reference

**Error:**
```
Model `customers` (semantics/customers.yml)
segment 'has_orders' references unknown identifier 'orders.order_count'
```

**Fix:** Use dimension proxies:
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.order_count

segments:
  has_orders:
    expression: "{order_count_dim} > 0"  # ✅ Use dimension proxy
```

### 9.4 Validation Workflow

```
1. Write semantic YAML
   ↓
2. Run: vulcan plan
   ↓
3. Validation runs automatically
   ↓
4a. ✅ Valid → Success!
   OR
4b. ❌ Invalid → Error message with location
   ↓
5. Fix error in YAML
   ↓
6. Go to step 2
```

### 9.5 Quick Troubleshooting Checklist

When you get a validation error:

- [ ] **Check file path** - Error shows which YAML file
- [ ] **Check object name** - Error shows which measure/segment/join
- [ ] **Check column spelling** - Verify exact column names in Vulcan model
- [ ] **Check aliases** - Use semantic aliases, not physical names
- [ ] **Check joins** - Cross-model refs need join definitions
- [ ] **Check dimension proxies** - Segments using cross-model measures need dimension proxies

**For complete validation reference:** See [Chapter 3D: Semantic Validation](03d-semantic-validation.md)

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 10. Best Practices

### 10.1 Naming Conventions

**Semantic Model Aliases:**
```yaml
# ✅ Good: Consumer-friendly
alias: customers
alias: orders
alias: subscriptions

# ❌ Bad: Technical naming
alias: dim_customers
alias: fact_orders
```

**Measures:**
```yaml
# ✅ Good: Descriptive
- name: total_revenue
- name: active_customer_count
- name: avg_order_value

# ❌ Bad: Vague
- name: rev
- name: count1
- name: avg
```

**Segments:**
```yaml
# ✅ Good: Self-explanatory
- name: active_customers
- name: high_value_at_risk
- name: enterprise_segment

# ❌ Bad: Unclear
- name: seg1
- name: active
- name: hv
```

### 10.2 File Organization

**By Domain:**
```
semantics/
├── customers.yml      # Customer-related models
├── orders.yml         # Order-related models
├── products.yml        # Product-related models
└── metrics.yml         # Business metrics
```

**By Model:**
```
semantics/
├── customers.yml      # customers model + related
├── orders.yml         # orders model + related
└── subscriptions.yml  # subscriptions model + related
```

**Vulcan merges all files** - choose organization that makes sense for your team.

### 10.3 When to Use What

**Use Dimensions When:**
- ✅ You want to filter or group by a column
- ✅ Column is already in your model
- ✅ You need to add metadata/tags

**Use Measures When:**
- ✅ You need to calculate aggregations
- ✅ You need to combine multiple columns
- ✅ You need filtered calculations

**Use Segments When:**
- ✅ You have reusable filter conditions
- ✅ Business users need predefined subsets
- ✅ You want to document business logic

**Use Joins When:**
- ✅ You need cross-model analysis
- ✅ You want to reference other model's columns
- ✅ You're building star/snowflake schemas

**Use Metrics When:**
- ✅ You need time-series analysis
- ✅ You want complete analytical definitions
- ✅ You're exposing KPIs to business users

### 10.4 Integration with Models

**Design Models with Semantic Layer in Mind:**

```sql
-- ✅ Good: Clean column names, business-friendly
MODEL (name analytics.customers);
SELECT
  customer_id,
  customer_tier,      -- Good dimension name
  signup_date,        -- Good time dimension
  total_spent         -- Good for segments
FROM raw.customers;

-- ❌ Bad: Technical naming, hard to use semantically
MODEL (name analytics.dim_cust);
SELECT
  cust_id,
  tier_cd,
  signup_dt,
  tot_spent_amt
FROM raw.customers;
```

**Key Insight:** Model columns automatically become dimensions. Design models with business users in mind.

### 10.5 Incremental Development

**Start Simple:**

```yaml
# Step 1: Basic model
models:
  analytics.customers:
    alias: customers

# Validate
# Step 2: Add measures
models:
  analytics.customers:
    alias: customers
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"

# Validate
# Step 3: Add segments, joins, etc.
```

**Build incrementally** - validate after each change.

### 10.6 Documentation

**Always Add Descriptions:**

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Total revenue from all completed orders"  # ✅ Always include
    meta:
      business_owner: "Finance Team"
      calculation_method: "Sum of order amounts excluding refunds"
```

**Document Business Logic:**

```yaml
segments:
  at_risk:
    expression: "..."
    description: "Customers likely to churn"
    meta:
      business_owner: "Customer Success"
      criteria: "Active plan, no activity 14+ days, engagement score < 0.3"
      action: "Trigger outreach campaign"
```

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 11. Quick Reference

### 11.1 Syntax Cheat Sheet

**Semantic Model:**
```yaml
models:
  <physical_model>:  # REQUIRED (e.g., analytics.customers)
    name: <business_name>  # Required for schema.table (e.g., customers)
    dimensions: ...
    measures: ...
    segments: ...
    joins: ...
```

**Dimensions:**
```yaml
dimensions:
  excludes: [...]           # Hide columns
  includes: [...]           # Show only these
  proxies:                  # Cross-model measures as dimensions
    <proxy_name>:
      measure: <model.measure>
  overrides:                # Add tags/meta
    <column>:
      tags: [...]
      meta: {...}
```

**Measures:**
```yaml
measures:
  <name>:                  # REQUIRED (dictionary key)
    type: <type>           # REQUIRED (count, sum, avg, expression, etc.)
    expression: "<SQL>"     # REQUIRED
    filters: [...]          # Optional
    format: currency        # Optional
    description: "..."      # Recommended
```

**Segments:**
```yaml
segments:
  <name>:                  # REQUIRED (dictionary key)
    expression: "<WHERE>"   # REQUIRED (no WHERE keyword)
    description: "..."      # Recommended
```

**Joins:**
```yaml
joins:
  <target_alias>:          # REQUIRED (dictionary key)
    type: <type>           # REQUIRED (one_to_one, one_to_many, many_to_one)
    expression: "<JOIN>"    # REQUIRED (model.column = model.column)
```

**Business Metrics:**
```yaml
metrics:
  <metric_name>:           # REQUIRED
    measure: <model.measure>  # REQUIRED
    time: <model.column>       # REQUIRED
    dimensions: [...]         # Optional
```

### 11.2 Decision Trees

**Which Component Should I Use?**

```
Need to filter/group by column?
├─ YES → Use DIMENSION
│
Need to calculate aggregation?
├─ YES → Use MEASURE
│
Need reusable filter condition?
├─ YES → Use SEGMENT
│
Need to connect models?
├─ YES → Use JOIN
│
Need time-series analysis?
└─ YES → Use METRIC
```

**Do I Need an Alias?**

```
Physical model name format?
├─ schema.table → YES, alias REQUIRED
└─ table → NO, alias optional
```

**Can Segments Reference Other Models?**

```
Need cross-model segment?
├─ YES → Use DIMENSION PROXY
│  1. Define join
│  2. Create dimension proxy
│  3. Use {proxy_name} in segment
└─ NO → Use model columns directly
```

### 11.3 Common Patterns

**Pattern 1: Basic Model**
```yaml
models:
  analytics.customers:
    alias: customers
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
```

**Pattern 2: Filtered Measure**
```yaml
measures:
  active_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'active'"
```

**Pattern 3: Cross-Model Measure**
```yaml
joins:
  customers:
    type: many_to_one
    expression: "orders.customer_id = customers.customer_id"

measures:
  enterprise_revenue:
    expression: "SUM(orders.amount)"
    filters:
      - "customers.customer_tier = 'Enterprise'"
```

**Pattern 4: Dimension Proxy Segment**
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.total_orders

segments:
  has_orders:
    expression: "{order_count_dim} > 0"
```

**Pattern 5: Time-Series Metric**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
```

### 11.4 Reference Format Rules

**Always Use Dot Notation:**
- Measures: `model.measure_name`
- Dimensions: `model.column_name`
- Time: `model.date_column`

**Use Semantic Aliases:**
- ✅ `customers.customer_tier`
- ❌ `analytics.dim_customers.customer_tier`

**Cross-Model References:**
- ✅ `customers.customer_tier` (requires join)
- ❌ `customer_tier` (ambiguous)

[↑ Back to Top](#chapter-03-semantic-layer)

---

## 12. Summary and Next Steps

### 12.1 What You've Learned

**Core Concepts:**
1. **Semantic Models** - Map physical models to business concepts
2. **Dimensions** - Columns for filtering and grouping (auto-exposed)
3. **Measures** - Aggregated calculations (`SUM`, `COUNT`, etc.)
4. **Segments** - Reusable filter conditions
5. **Joins** - Relationships between models
6. **Business Metrics** - Complete analytical definitions with time

**Key Principles:**
- Model columns automatically become dimensions
- Use aliases for consumer-friendly names
- Segments are model-scoped (use dimension proxies for cross-model)
- Always use dot notation: `model.field`
- Validation catches errors automatically

### 12.2 Next Steps

**Continue Learning:**

- **[Chapter 3A: YAML Reference](03a-semantic-yaml-reference.md)** - Complete syntax reference, all options
- **[Chapter 3B: Advanced Measures](03b-semantic-measures.md)** - Complex expressions, patterns, performance
- **[Chapter 3C: Advanced Joins](03c-semantic-joins.md)** - Cross-model analysis, complex relationships
- **[Chapter 3D: Semantic Validation](03d-semantic-validation.md)** - Complete validation rules, troubleshooting

**Related Chapters:**

- **[Chapter 2: Models](../02-models/02-models.md)** - Understanding model structure
- **[Chapter 6: APIs](../06-apis.md)** - Querying semantic layer via APIs

### 12.3 Additional Resources

- **Examples** - `examples/b2b_saas/semantics/` in your Vulcan installation
- **Validation Reference** - `readings/SEMANTIC_VALIDATIONS.md`
- **API Documentation** - See Chapter 6 for querying semantic layer

---

**Congratulations!** You now have a solid foundation in Vulcan's semantic layer. You can:
- ✅ Create semantic models with measures and dimensions
- ✅ Build reusable segments
- ✅ Connect models with joins
- ✅ Define business metrics for time-series analysis
- ✅ Understand validation and troubleshooting basics

**Happy modeling!**

[↑ Back to Top](#chapter-03-semantic-layer)

