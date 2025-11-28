# Chapter 3B: Advanced Measures

> **Complex measure patterns and advanced techniques** - Build sophisticated aggregations, cross-model measures, measure dependencies, performance optimization, and measure pattern libraries.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 3: Semantic Layer** - Understanding of:
- Basic measure syntax
- Measure expressions and filters
- Cross-model references

**Chapter 3A: YAML Reference** - Understanding of:
- Complete measure field reference
- Reference format rules

**SQL Proficiency - Level 3**
- Advanced aggregations
- Window functions
- CTEs and subqueries
- SQL optimization concepts

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Measure Expression Patterns](#2-measure-expression-patterns)
3. [Cross-Model Measures](#3-cross-model-measures)
4. [Measure Dependencies](#4-measure-dependencies)
5. [Window Functions and Advanced SQL](#5-window-functions-and-advanced-sql)
6. [Performance Optimization](#6-performance-optimization)
7. [Measure Pattern Library](#7-measure-pattern-library)
8. [Best Practices](#8-best-practices)
9. [Troubleshooting](#9-troubleshooting)
10. [Summary](#10-summary)

---

## 1. Introduction

### 1.1 What Are Advanced Measures?

Advanced measures go beyond simple `SUM()` and `COUNT()` aggregations. They include:

- Complex SQL expressions with multiple aggregations
- Cross-model calculations spanning multiple tables
- Measure dependencies (measures built on other measures)
- Window functions for running totals and rankings
- Conditional logic and case statements
- Performance-optimized patterns

### 1.2 When to Use Advanced Measures

**Use advanced measures when:**

- Simple aggregations don't capture your business logic
- You need calculations across multiple models
- You want reusable measure building blocks
- Performance is critical for large datasets
- You need sophisticated analytical calculations

**Start simple, then advance:**

1. **Basic:** `SUM(amount)`, `COUNT(*)`
2. **Filtered:** Add `filters:` array
3. **Complex:** Multi-line expressions with CASE statements
4. **Cross-model:** Reference joined models
5. **Dependent:** Build on other measures
6. **Advanced:** Window functions, CTEs, subqueries

### 1.3 Measure Expression Capabilities

**What you can do in measure expressions:**

✅ **Aggregations:**
- `SUM()`, `AVG()`, `COUNT()`, `MIN()`, `MAX()`
- `COUNT(DISTINCT ...)`
- Custom aggregations

✅ **SQL Functions:**
- Date functions: `DATE_TRUNC()`, `EXTRACT()`, `DATEDIFF()`
- String functions: `CONCAT()`, `SUBSTRING()`, `UPPER()`
- Math functions: `ROUND()`, `ABS()`, `POWER()`
- Conditional: `CASE WHEN ... THEN ... ELSE ... END`
- Null handling: `COALESCE()`, `NULLIF()`, `ISNULL()`

✅ **References:**
- Current model columns and dimensions
- Other measures (no self-reference)
- Joined model columns and dimensions
- Joined model measures

✅ **Advanced SQL:**
- Window functions: `OVER()`, `PARTITION BY`, `ORDER BY`
- Subqueries: `(SELECT ...)`
- CTEs: `WITH ... AS (...)`

**Limitations:**
- Cannot reference the measure itself (no self-reference)
- Must be valid SQL for your warehouse dialect
- Performance considerations for complex expressions

[↑ Back to Top](#)

---

## 2. Measure Expression Patterns

### 2.1 Conditional Aggregations

**Pattern: SUM with CASE**

Calculate different values based on conditions:

```yaml
measures:
  active_revenue:
    type: sum
    expression: |
      SUM(CASE 
        WHEN status = 'active' THEN amount 
        ELSE 0 
      END)
    description: "Revenue from active subscriptions only"
  
  high_value_revenue:
    type: sum
    expression: |
      SUM(CASE 
        WHEN amount > 1000 THEN amount 
        ELSE 0 
      END)
    description: "Revenue from orders over $1000"
  
  tiered_revenue:
    type: sum
    expression: |
      SUM(CASE 
        WHEN customer_tier = 'Enterprise' THEN amount * 1.1
        WHEN customer_tier = 'Pro' THEN amount * 1.05
        ELSE amount
      END)
    description: "Revenue with tier-based multipliers"
```

**Alternative: Use filters instead**

```yaml
# ✅ Prefer filters for clarity
measures:
  active_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'active'"
    description: "Revenue from active subscriptions only"
```

**When to use CASE vs filters:**
- **Use CASE:** When you need different calculations per condition
- **Use filters:** When you're just filtering rows (simpler, clearer)

### 2.2 Ratio and Percentage Calculations

**Pattern: Division with NULLIF**

Always handle division by zero:

```yaml
measures:
  conversion_rate:
    type: expression
    expression: |
      COUNT(DISTINCT CASE WHEN converted = true THEN user_id END) * 100.0 
      / NULLIF(COUNT(DISTINCT user_id), 0)
    format: percentage
    description: "Percentage of users who converted"
  
  avg_order_value:
    type: expression
    expression: "SUM(amount) / NULLIF(COUNT(*), 0)"
    format: currency
    description: "Average order value"
  
  revenue_per_customer:
    type: expression
    expression: "SUM(amount) / NULLIF(COUNT(DISTINCT customer_id), 0)"
    format: currency
    description: "Average revenue per customer"
```

**Pattern: Percentage of Total**

```yaml
measures:
  enterprise_revenue_pct:
    type: expression
    expression: |
      SUM(CASE WHEN customer_tier = 'Enterprise' THEN amount ELSE 0 END) * 100.0
      / NULLIF(SUM(amount), 0)
    format: percentage
    description: "Enterprise revenue as percentage of total"
```

### 2.3 Distinct Count Patterns

**Pattern: Count Distinct**

```yaml
measures:
  unique_customers:
    type: count_distinct
    expression: "COUNT(DISTINCT customer_id)"
    description: "Number of unique customers"
  
  unique_products_sold:
    type: count_distinct
    expression: "COUNT(DISTINCT product_id)"
    description: "Number of distinct products sold"
  
  unique_active_users_30d:
    type: count_distinct
    expression: |
      COUNT(DISTINCT CASE 
        WHEN last_activity_date >= CURRENT_DATE - INTERVAL '30 days' 
        THEN user_id 
      END)
    description: "Unique users active in last 30 days"
```

**Pattern: Count Distinct with Multiple Columns**

```yaml
measures:
  unique_customer_product_combinations:
    type: count_distinct
    expression: "COUNT(DISTINCT customer_id || '-' || product_id)"
    description: "Unique customer-product pairs"
```

### 2.4 Weighted Averages

**Pattern: Weighted Average**

```yaml
measures:
  weighted_avg_score:
    type: expression
    expression: "SUM(score * weight) / NULLIF(SUM(weight), 0)"
    description: "Weighted average of scores"
  
  weighted_avg_price:
    type: expression
    expression: "SUM(price * quantity) / NULLIF(SUM(quantity), 0)"
    format: currency
    description: "Average price weighted by quantity sold"
```

### 2.5 Time-Based Calculations

**Pattern: Date Range Aggregations**

```yaml
measures:
  revenue_last_30_days:
    type: sum
    expression: |
      SUM(CASE 
        WHEN order_date >= CURRENT_DATE - INTERVAL '30 days' 
        THEN amount 
        ELSE 0 
      END)
    description: "Revenue from last 30 days"
  
  new_customers_this_month:
    type: count_distinct
    expression: |
      COUNT(DISTINCT CASE 
        WHEN DATE_TRUNC('month', signup_date) = DATE_TRUNC('month', CURRENT_DATE)
        THEN customer_id 
      END)
    description: "New customers signed up this month"
```

**Pattern: Year-over-Year**

```yaml
measures:
  revenue_yoy_growth:
    type: expression
    expression: |
      (SUM(CASE 
        WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        THEN amount 
        ELSE 0 
      END) - 
      SUM(CASE 
        WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
        THEN amount 
        ELSE 0 
      END)) * 100.0
      / NULLIF(SUM(CASE 
        WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
        THEN amount 
        ELSE 0 
      END), 0)
    format: percentage
    description: "Year-over-year revenue growth percentage"
```

### 2.6 Percentile and Statistical Measures

**Pattern: Percentiles**

```yaml
measures:
  p50_order_value:
    type: expression
    expression: "PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount)"
    format: currency
    description: "Median order value"
  
  p95_order_value:
    type: expression
    expression: "PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount)"
    format: currency
    description: "95th percentile order value"
  
  p99_response_time:
    type: expression
    expression: "PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_ms)"
    format: duration_ms
    description: "99th percentile response time"
```

**Pattern: Standard Deviation**

```yaml
measures:
  revenue_stddev:
    type: expression
    expression: "STDDEV(amount)"
    format: currency
    description: "Standard deviation of order amounts"
  
  avg_revenue_with_stddev:
    type: expression
    expression: |
      AVG(amount) || ' ± ' || ROUND(STDDEV(amount), 2)
    description: "Average revenue with standard deviation"
```

[↑ Back to Top](#)

---

## 3. Cross-Model Measures

### 3.1 Basic Cross-Model References

**Pattern: Aggregate from Joined Model**

```yaml
models:
  analytics.customers:
    alias: customers
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
    
    measures:
      customer_order_count:
        type: count
        expression: "COUNT(orders.order_id)"
        description: "Number of orders per customer"
      
      customer_total_spent:
        type: sum
        expression: "SUM(orders.amount)"
        format: currency
        description: "Total amount spent by customer"
```

**Pattern: Filter by Joined Model**

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      enterprise_order_revenue:
        type: sum
        expression: "SUM(amount)"
        filters:
          - "customers.customer_tier = 'Enterprise'"
        description: "Revenue from Enterprise customer orders"
```

### 3.2 Multi-Model Aggregations

**Pattern: Aggregate Across Multiple Models**

```yaml
models:
  analytics.customers:
    alias: customers
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
      
      subscriptions:
        type: one_to_many
        expression: "customers.customer_id = subscriptions.customer_id"
    
    measures:
      total_customer_value:
        type: expression
        expression: |
          COALESCE(SUM(orders.amount), 0) + 
          COALESCE(SUM(subscriptions.mrr), 0)
        format: currency
        description: "Combined value from orders and subscriptions"
```

### 3.3 Cross-Model Ratios

**Pattern: Ratio Across Models**

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      revenue_per_customer_tier:
        type: expression
        expression: |
          SUM(orders.amount) / 
          NULLIF(COUNT(DISTINCT customers.customer_tier), 0)
        format: currency
        description: "Average revenue per customer tier"
```

### 3.4 Conditional Cross-Model Logic

**Pattern: Conditional Aggregation Based on Joined Model**

```yaml
models:
  analytics.orders:
    alias: orders
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
    
    measures:
      tier_adjusted_revenue:
        type: sum
        expression: |
          SUM(CASE 
            WHEN customers.customer_tier = 'Enterprise' THEN orders.amount * 1.1
            WHEN customers.customer_tier = 'Pro' THEN orders.amount * 1.05
            ELSE orders.amount
          END)
        format: currency
        description: "Revenue adjusted by customer tier"
```

[↑ Back to Top](#)

---

## 4. Measure Dependencies

### 4.1 Building Measures on Other Measures

**Pattern: Simple Dependency**

```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Total revenue"
  
  total_orders:
    type: count
    expression: "COUNT(*)"
    description: "Total order count"
  
  avg_order_value:
    type: expression
    expression: "total_revenue / NULLIF(total_orders, 0)"
    format: currency
    description: "Average order value (revenue per order)"
```

**How it works:**
- Vulcan automatically resolves measure dependencies
- Measures are evaluated in dependency order
- No need to specify order explicitly

### 4.2 Complex Dependency Chains

**Pattern: Multi-Level Dependencies**

```yaml
measures:
  # Level 1: Base measures
  total_revenue:
    type: sum
    expression: "SUM(amount)"
  
  total_costs:
    type: sum
    expression: "SUM(cost)"
  
  # Level 2: Derived measures
  gross_profit:
    type: expression
    expression: "total_revenue - total_costs"
    format: currency
  
  total_orders:
    type: count
    expression: "COUNT(*)"
  
  # Level 3: Final calculations
  profit_margin:
    type: expression
    expression: "gross_profit * 100.0 / NULLIF(total_revenue, 0)"
    format: percentage
  
  profit_per_order:
    type: expression
    expression: "gross_profit / NULLIF(total_orders, 0)"
    format: currency
```

**Dependency graph:**
```
total_revenue ──┐
                ├──→ gross_profit ──┐
total_costs ────┘                   ├──→ profit_margin
                                    │
total_orders ───────────────────────┼──→ profit_per_order
                                    │
                                    └──→ profit_per_order
```

### 4.3 Circular Dependency Prevention

**Rule: Measures cannot reference themselves**

```yaml
# ❌ Invalid: Self-reference
measures:
  revenue_growth:
    type: expression
    expression: "revenue_growth * 1.1"  # Cannot reference itself

# ✅ Valid: Reference other measures
measures:
  base_revenue:
    type: sum
    expression: "SUM(amount)"
  
  revenue_with_growth:
    type: expression
    expression: "base_revenue * 1.1"  # References other measure
```

**Rule: No circular dependencies between measures**

```yaml
# ❌ Invalid: Circular dependency
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"
  
  measure_b:
    type: expression
    expression: "measure_a + 20"  # Circular!

# ✅ Valid: Acyclic dependencies
measures:
  base_value:
    type: sum
    expression: "SUM(amount)"
  
  adjusted_value:
    type: expression
    expression: "base_value * 1.1"
  
  final_value:
    type: expression
    expression: "adjusted_value + 100"
```

### 4.4 Conditional Dependencies

**Pattern: Conditional Measure Selection**

```yaml
measures:
  base_revenue:
    type: sum
    expression: "SUM(amount)"
  
  discounted_revenue:
    type: sum
    expression: "SUM(amount * 0.9)"
  
  effective_revenue:
    type: expression
    expression: |
      CASE 
        WHEN COUNT(CASE WHEN has_discount = true THEN 1 END) > 0
        THEN discounted_revenue
        ELSE base_revenue
      END
    description: "Revenue with conditional discount application"
```

[↑ Back to Top](#)

---

## 5. Window Functions and Advanced SQL

### 5.1 Running Totals

**Pattern: Cumulative Sum**

```yaml
measures:
  cumulative_revenue:
    type: expression
    expression: |
      SUM(SUM(amount)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      )
    format: currency
    description: "Running total of revenue by month"
```

**Pattern: Moving Average**

```yaml
measures:
  revenue_30day_avg:
    type: expression
    expression: |
      AVG(SUM(amount)) OVER (
        ORDER BY order_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
      )
    format: currency
    description: "30-day moving average of revenue"
```

### 5.2 Rankings and Percentiles

**Pattern: Rank by Value**

```yaml
measures:
  customer_revenue_rank:
    type: expression
    expression: |
      RANK() OVER (
        PARTITION BY customer_tier
        ORDER BY SUM(amount) DESC
      )
    description: "Customer rank by revenue within tier"
```

**Pattern: Percentile Rank**

```yaml
measures:
  order_value_percentile:
    type: expression
    expression: |
      PERCENT_RANK() OVER (
        ORDER BY amount
      ) * 100
    format: percentage
    description: "Percentile rank of order value"
```

### 5.3 Period-over-Period Comparisons

**Pattern: Previous Period Comparison**

```yaml
measures:
  revenue_vs_previous_month:
    type: expression
    expression: |
      SUM(amount) - 
      LAG(SUM(amount)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
      )
    format: currency
    description: "Revenue change vs previous month"
  
  revenue_growth_rate:
    type: expression
    expression: |
      (SUM(amount) - 
       LAG(SUM(amount)) OVER (
         ORDER BY DATE_TRUNC('month', order_date)
       )) * 100.0
      / NULLIF(LAG(SUM(amount)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
      ), 0)
    format: percentage
    description: "Month-over-month revenue growth rate"
```

### 5.4 First and Last Values

**Pattern: First Value in Window**

```yaml
measures:
  first_order_value:
    type: expression
    expression: |
      FIRST_VALUE(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
      )
    format: currency
    description: "First order value per customer"
```

**Pattern: Last Value in Window**

```yaml
measures:
  latest_customer_tier:
    type: expression
    expression: |
      LAST_VALUE(customer_tier) OVER (
        PARTITION BY customer_id
        ORDER BY updated_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
      )
    description: "Most recent customer tier"
```

### 5.5 Advanced Window Functions

**Pattern: N-Tile Bucketing**

```yaml
measures:
  revenue_quartile:
    type: expression
    expression: |
      NTILE(4) OVER (
        ORDER BY SUM(amount)
      )
    description: "Revenue quartile (1-4)"
```

**Pattern: Lead and Lag**

```yaml
measures:
  next_month_revenue:
    type: expression
    expression: |
      LEAD(SUM(amount)) OVER (
        ORDER BY DATE_TRUNC('month', order_date)
      )
    format: currency
    description: "Revenue for next month"
```

[↑ Back to Top](#)

---

## 6. Performance Optimization

### 6.1 Expression Simplification

**Pattern: Prefer Filters Over CASE**

```yaml
# ❌ Slower: CASE in expression
measures:
  active_revenue:
    type: sum
    expression: "SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END)"

# ✅ Faster: Filters
measures:
  active_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'active'"
```

**Why:** Filters are applied before aggregation, reducing data scanned

### 6.2 Avoid Redundant Calculations

**Pattern: Reuse Base Measures**

```yaml
# ❌ Bad: Redundant calculations
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
  
  active_revenue:
    type: sum
    expression: "SUM(amount)"  # Redundant SUM
    filters:
      - "status = 'active'"
  
  completed_revenue:
    type: sum
    expression: "SUM(amount)"  # Redundant SUM
    filters:
      - "status = 'completed'"

# ✅ Good: Base measure + filters
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
  
  active_revenue:
    type: expression
    expression: "total_revenue"  # Reuse base
    filters:
      - "status = 'active'"
  
  completed_revenue:
    type: expression
    expression: "total_revenue"  # Reuse base
    filters:
      - "status = 'completed'"
```

### 6.3 Limit Cross-Model Aggregations

**Pattern: Minimize Cross-Model Scans**

```yaml
# ❌ Expensive: Multiple cross-model aggregations
measures:
  complex_calculation:
    type: expression
    expression: |
      SUM(orders.amount) + 
      SUM(subscriptions.mrr) + 
      SUM(usage_events.event_count)
    # Scans 3 joined models

# ✅ Better: Pre-aggregate in base models
# Define measures in each model, then combine
measures:
  total_customer_value:
    type: expression
    expression: "orders.total_revenue + subscriptions.total_mrr"
    # References pre-aggregated measures
```

### 6.4 Optimize Window Functions

**Pattern: Limit Window Size**

```yaml
# ❌ Expensive: Unbounded window
measures:
  cumulative_all_time:
    type: expression
    expression: |
      SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      )

# ✅ Better: Bounded window
measures:
  cumulative_90days:
    type: expression
    expression: |
      SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
      )
```

[↑ Back to Top](#)

---

## 7. Measure Pattern Library

### 7.1 Revenue Patterns

**Total Revenue:**
```yaml
total_revenue:
  type: sum
  expression: "SUM(amount)"
  format: currency
  tags: [revenue, financial, kpi]
```

**Net Revenue (after refunds):**
```yaml
net_revenue:
  type: expression
  expression: "SUM(amount) - SUM(COALESCE(refund_amount, 0))"
  format: currency
  tags: [revenue, financial]
```

**Recurring Revenue:**
```yaml
mrr:
  type: sum
  expression: "SUM(mrr)"
  format: currency
  tags: [revenue, recurring, saas]
```

### 7.2 Count Patterns

**Total Count:**
```yaml
total_orders:
  type: count
  expression: "COUNT(*)"
  tags: [count, orders]
```

**Distinct Count:**
```yaml
unique_customers:
  type: count_distinct
  expression: "COUNT(DISTINCT customer_id)"
  tags: [count, customers, distinct]
```

**Conditional Count:**
```yaml
active_subscriptions:
  type: count
  expression: "COUNT(CASE WHEN status = 'active' THEN 1 END)"
  tags: [count, subscriptions, active]
```

### 7.3 Average Patterns

**Simple Average:**
```yaml
avg_order_value:
  type: avg
  expression: "AVG(amount)"
  format: currency
  tags: [average, orders]
```

**Weighted Average:**
```yaml
weighted_avg_price:
  type: expression
  expression: "SUM(price * quantity) / NULLIF(SUM(quantity), 0)"
  format: currency
  tags: [average, weighted, price]
```

### 7.4 Rate Patterns

**Conversion Rate:**
```yaml
conversion_rate:
  type: expression
  expression: |
    COUNT(DISTINCT CASE WHEN converted = true THEN user_id END) * 100.0
    / NULLIF(COUNT(DISTINCT user_id), 0)
  format: percentage
  tags: [rate, conversion]
```

**Churn Rate:**
```yaml
churn_rate:
  type: expression
  expression: |
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100.0
    / NULLIF(COUNT(*), 0)
  format: percentage
  tags: [rate, churn, retention]
```

### 7.5 Growth Patterns

**Month-over-Month Growth:**
```yaml
revenue_mom_growth:
  type: expression
  expression: |
    (SUM(amount) - 
     LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', order_date))) * 100.0
    / NULLIF(LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', order_date)), 0)
  format: percentage
  tags: [growth, mom]
```

**Year-over-Year Growth:**
```yaml
revenue_yoy_growth:
  type: expression
  expression: |
    (SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN amount END) -
     SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN amount END)) * 100.0
    / NULLIF(SUM(CASE WHEN EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN amount END), 0)
  format: percentage
  tags: [growth, yoy]
```

[↑ Back to Top](#)

---

## 8. Best Practices

### 8.1 Expression Clarity

**✅ DO:**
- Use descriptive measure names
- Add clear descriptions
- Break complex expressions into multiple measures
- Use filters instead of CASE when possible
- Handle NULLs and division by zero

**❌ DON'T:**
- Create overly complex single expressions
- Omit descriptions
- Use magic numbers without explanation
- Ignore NULL handling
- Create circular dependencies

### 8.2 Performance Guidelines

**✅ DO:**
- Use filters for row-level conditions
- Reuse base measures for derived calculations
- Limit window function ranges
- Minimize cross-model aggregations
- Test with production-scale data

**❌ DON'T:**
- Use CASE when filters would work
- Redundant calculations
- Unbounded window functions unnecessarily
- Excessive cross-model joins in single measure
- Assume expressions scale without testing

### 8.3 Dependency Management

**✅ DO:**
- Build measures in logical layers
- Document measure dependencies
- Use clear naming conventions
- Test dependency chains

**❌ DON'T:**
- Create circular dependencies
- Reference measures that don't exist
- Create deep dependency chains (>5 levels)
- Mix dependency levels without organization

### 8.4 Documentation

**✅ DO:**
- Document business logic in descriptions
- Explain calculation methods in meta
- Tag measures for discovery
- Note data sources and freshness

**❌ DON'T:**
- Leave measures undocumented
- Use unclear or technical descriptions
- Omit business context
- Forget to update documentation when logic changes

[↑ Back to Top](#)

---

## 9. Troubleshooting

### 9.1 Common Errors

**Error: "Measure not found"**

**Cause:** Referencing non-existent measure

**Solution:**
```yaml
# ❌ Error: measure_b doesn't exist
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"

# ✅ Fix: Define measure_b first
measures:
  measure_b:
    type: sum
    expression: "SUM(amount)"
  
  measure_a:
    type: expression
    expression: "measure_b + 10"
```

**Error: "Circular dependency detected"**

**Cause:** Measure references itself or creates cycle

**Solution:**
```yaml
# ❌ Error: Circular dependency
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"
  
  measure_b:
    type: expression
    expression: "measure_a + 20"

# ✅ Fix: Break the cycle
measures:
  base_value:
    type: sum
    expression: "SUM(amount)"
  
  measure_a:
    type: expression
    expression: "base_value + 10"
  
  measure_b:
    type: expression
    expression: "base_value + 20"
```

**Error: "Column not found"**

**Cause:** Referencing non-existent column or wrong model

**Solution:**
```yaml
# ❌ Error: Column doesn't exist
measures:
  - name: total
    expression: "SUM(non_existent_column)"

# ✅ Fix: Use correct column name
measures:
  - name: total
    expression: "SUM(amount)"
```

### 9.2 Performance Issues

**Issue: Slow measure evaluation**

**Symptoms:**
- Measures take long time to compute
- Queries timeout
- High warehouse costs

**Solutions:**
1. Check for unbounded window functions
2. Verify filters are being applied
3. Review cross-model join complexity
4. Consider pre-aggregating in base models
5. Test with smaller date ranges first

### 9.3 Validation Errors

**Issue: SQL syntax errors**

**Cause:** Invalid SQL in expression

**Solution:**
- Test SQL directly in warehouse
- Check dialect compatibility
- Verify function names and syntax
- Review window function syntax

[↑ Back to Top](#)

---

## 10. Summary

### Key Takeaways

1. **Advanced measures enable sophisticated analytics**
   - Complex SQL expressions
   - Cross-model calculations
   - Measure dependencies
   - Window functions

2. **Patterns for common use cases**
   - Conditional aggregations
   - Ratios and percentages
   - Time-based calculations
   - Statistical measures

3. **Performance matters**
   - Use filters instead of CASE when possible
   - Reuse base measures
   - Limit window function ranges
   - Minimize cross-model aggregations

4. **Best practices**
   - Clear, descriptive names
   - Comprehensive documentation
   - Logical dependency organization
   - Proper NULL handling

### Next Steps

- [Chapter 3C: Advanced Joins](joins.md) - Cross-model analysis patterns
- [Chapter 3D: Validation](validation.md) - Complete validation rules
- [Chapter 3: Semantic Layer](index.md) - Foundation concepts

[↑ Back to Top](#)

