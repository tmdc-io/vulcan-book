# Chapter 3D: Semantic Layer Validation

> **Complete validation rules and error resolution** - Understand every validation rule, common errors, and how to fix them.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 3: Semantic Layer** - Understanding of:
- Semantic layer concepts
- Models, dimensions, measures, segments, joins, metrics

**Chapter 3A: YAML Reference** - Understanding of:
- Complete YAML syntax
- Field requirements and formats

**YAML Syntax**
- Basic YAML structure
- Indentation and formatting

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Naming and Uniqueness Rules](#2-naming-and-uniqueness-rules)
3. [Semantic Models Validation](#3-semantic-models-validation)
4. [Dimensions Validation](#4-dimensions-validation)
5. [Measures Validation](#5-measures-validation)
6. [Segments Validation](#6-segments-validation)
7. [Joins Validation](#7-joins-validation)
8. [Metrics Validation](#8-metrics-validation)
9. [Reference Validation](#9-reference-validation)
10. [Common Error Patterns](#10-common-error-patterns)
11. [Troubleshooting Guide](#11-troubleshooting-guide)
12. [Summary](#12-summary)

---

## 1. Introduction

### 1.1 What is Validation?

Semantic layer validation ensures your YAML definitions are:

- **Syntactically correct** - Valid YAML structure
- **Semantically valid** - References exist and are correct
- **Logically consistent** - No circular dependencies, valid relationships
- **Complete** - Required fields are present

### 1.2 When Validation Runs

Validation occurs:

1. **On load** - When semantic layer files are loaded
2. **On change** - When files are modified
3. **Before queries** - Before executing analytical queries
4. **Explicitly** - Via `vulcan validate` command

### 1.3 Validation Error Format

**Error message structure:**
```
ERROR: <component> '<name>': <rule_violated>
  Location: <file>:<line>
  Details: <additional_info>
```

**Example:**
```
ERROR: Measure 'total_revenue': Circular dependency detected
  Location: semantics/orders.yml:15
  Details: Measure 'total_revenue' references 'avg_revenue' which references 'total_revenue'
```

### 1.4 How to Use This Chapter

**For debugging:**
- Find the error message in relevant section
- Review validation rules
- Check examples and solutions

**For prevention:**
- Review validation rules before writing
- Follow naming conventions
- Validate frequently during development

[↑ Back to Top](#)

---

## 2. Naming and Uniqueness Rules

### 2.1 Identifier Format Rules

**Applicable to:**
- Semantic model aliases (`alias`)
- Measure names
- Segment names
- Join names (target model aliases)
- Metric names
- Dimension proxy names
- Dimension override names

**Rules:**
- Must **not be empty**
- Must **start with a letter** (`A–Z` or `a–z`)
- After first character, may contain only:
  - Letters (`A–Z`, `a–z`)
  - Digits (`0–9`)
  - Underscores (`_`)
- Maximum length: **64 characters**
- Case-sensitive

**Valid examples:**
```yaml
# ✅ Valid names
- name: total_revenue
- name: customer_count_30d
- name: avg_order_value
- name: monthly_revenue_by_tier
- name: revenue_2024
```

**Invalid examples:**
```yaml
# ❌ Invalid: Starts with digit
- name: "123revenue"

# ❌ Invalid: Contains hyphen
- name: "total-revenue"

# ❌ Invalid: Contains space
- name: "total revenue"

# ❌ Invalid: Contains dot (except in references)
- name: "total.revenue"

# ❌ Invalid: Empty
- name: ""
```

**Error messages:**
```
ERROR: Invalid identifier '123revenue': Must start with a letter
ERROR: Invalid identifier 'total-revenue': Invalid character '-' (only letters, digits, underscores allowed)
ERROR: Invalid identifier '': Identifier cannot be empty
```

### 2.2 Uniqueness Within Model

**Rule:** Within a single semantic model:

- Measure names must be unique
- Segment names must be unique
- Dimension proxy names must be unique
- Dimension override names must be unique
- **No semantic field name** should be reused across measures, segments, and dimension proxies

**Valid example:**
```yaml
models:
  analytics.customers:
    alias: customers
    
    measures:
      total_customers:
        type: count
      active_customers:
        type: count
    
    segments:
      active:
        expression: "..."
      high_value:
        expression: "..."
    
    dimensions:
      proxies:
        order_count_dim:
          measure: "..."
```

**Invalid examples:**
```yaml
# ❌ Error: Duplicate measure name
measures:
  total_revenue:
    type: sum
  total_revenue:  # Duplicate! (same key twice)
    type: sum

# ❌ Error: Measure and segment with same name
measures:
  active_users:
    type: count
segments:
  active_users:  # Conflicts with measure name
    expression: "..."

# ❌ Error: Measure and dimension proxy with same name
measures:
  order_count:
    type: count
dimensions:
  proxies:
    order_count:  # Conflicts with measure name
      measure: "..."
```

**Error messages:**
```
ERROR: Duplicate measure name 'total_revenue' in model 'customers'
ERROR: Name 'active_users' conflicts: used as both measure and segment in model 'customers'
ERROR: Name 'order_count' conflicts: used as both measure and dimension proxy in model 'customers'
```

### 2.3 Uniqueness Across Files

**Rule:** Across all semantic layer files:

- Metric names must be unique
- Model aliases must be unique

**Invalid example:**
```yaml
# In file1.yml:
metrics:
  monthly_revenue: ...

# In file2.yml:
metrics:
  monthly_revenue: ...  # Duplicate metric name!
```

**Error message:**
```
ERROR: Duplicate metric name 'monthly_revenue' (defined in both file1.yml and file2.yml)
```

[↑ Back to Top](#)

---

## 3. Semantic Models Validation

### 3.1 Model Name Validation

**Rule:** `name` field must match an existing Vulcan model

**Valid example:**
```yaml
models:
  analytics.customers:  # Matches Vulcan model (dictionary key)
    alias: customers
```

**Invalid examples:**
```yaml
# ❌ Error: Model doesn't exist
models:
  non_existent_model:
    alias: customers

# ❌ Error: Typo in model name
models:
  analytics.custmers:  # Should be 'customers'
    alias: customers
```

**Error messages:**
```
ERROR: Model 'non_existent_model' not found in Vulcan project
ERROR: Model 'analytics.custmers' not found (did you mean 'analytics.customers'?)
```

### 3.2 Alias Validation

**Rule:** `alias` is required when `name` is fully qualified (`schema.table`)

**Valid examples:**
```yaml
# ✅ FQN with name/alias (required)
models:
  analytics.customers:
    alias: customers

# ✅ Simple name (name/alias optional)
models:
  customers:
    # name defaults to 'customers'
```

**Invalid example:**
```yaml
# ❌ Error: FQN without name/alias
models:
  analytics.customers:
    # Missing name field!
```

**Error message:**
```
ERROR: Model 'analytics.customers': Alias required for fully qualified model name
```

**Rule:** Alias must follow identifier format rules

**Invalid example:**
```yaml
models:
  analytics.customers:
    alias: "customer-users"  # Invalid: contains hyphen
```

**Error message:**
```
ERROR: Invalid alias 'customer-users': Invalid character '-' (only letters, digits, underscores allowed)
```

### 3.3 Model Existence for References

**Rule:** All referenced model aliases must exist

**Referenced in:**
- `joins:` - Join target names
- Dimension proxy `measure` values - `model.measure` format
- Metric `measure`, `time`, `dimensions` - `model.field` format

**Invalid example:**
```yaml
joins:
  non_existent_model:  # Model alias doesn't exist
    type: one_to_many
    expression: "..."
```

**Error message:**
```
ERROR: Join target 'non_existent_model' not found (referenced in model 'customers')
```

[↑ Back to Top](#)

---

## 4. Dimensions Validation

### 4.1 Column Selection Validation

**Rule:** Cannot use both `includes` and `excludes`

**Invalid example:**
```yaml
dimensions:
  includes: [col1, col2]
  excludes: [col3]  # Error: mutually exclusive
```

**Error message:**
```
ERROR: Cannot use both 'includes' and 'excludes' in dimensions (model 'customers')
```

**Rule:** All listed columns must exist in physical model

**Invalid example:**
```yaml
dimensions:
  includes:
    - non_existent_column  # Column doesn't exist
```

**Error message:**
```
ERROR: Column 'non_existent_column' not found in model 'analytics.customers'
```

### 4.2 Dimension Override Validation

**Rule:** Override `name` must refer to existing column (after includes/excludes)

**Invalid example:**
```yaml
dimensions:
  excludes:
    - email
  
  overrides:
    - name: email  # Error: excluded column
      tags: [pii]
```

**Error message:**
```
ERROR: Dimension override 'email' references excluded column (model 'customers')
```

**Rule:** `tags` must be array of strings

**Invalid example:**
```yaml
overrides:
  customer_tier:
    tags: "segmentation"  # Should be array
```

**Error message:**
```
ERROR: Dimension override 'customer_tier': 'tags' must be an array (model 'customers')
```

### 4.3 Dimension Proxy Validation

**Rule:** Proxy `measure` must be in `model.measure` format (exactly one dot)

**Invalid examples:**
```yaml
proxies:
  # ❌ Error: Missing model prefix
  order_count_dim:
    measure: total_orders
  
  # ❌ Error: Too many dots
  order_count_dim_2:
    measure: analytics.orders.total_orders
```

**Error messages:**
```
ERROR: Dimension proxy 'order_count_dim': Measure reference must be in 'model.measure' format (got 'total_orders')
ERROR: Dimension proxy 'order_count_dim': Measure reference must have exactly one dot (got 'analytics.orders.total_orders')
```

**Rule:** Referenced model must exist and be reachable via joins

**Invalid example:**
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.total_orders  # No join to 'orders' model
```

**Error message:**
```
ERROR: Dimension proxy 'order_count_dim': Model 'orders' not reachable via joins (model 'customers')
```

**Rule:** Referenced measure must exist on target model

**Invalid example:**
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.non_existent_measure  # Measure doesn't exist
```

**Error message:**
```
ERROR: Dimension proxy 'order_count_dim': Measure 'non_existent_measure' not found in model 'orders'
```

**Rule:** Cannot reference current model (only joined models)

**Invalid example:**
```yaml
models:
  analytics.customers:
    alias: customers
    
    dimensions:
      proxies:
        customer_count_dim:
          measure: customers.total_customers  # Cannot reference self
```

**Error message:**
```
ERROR: Dimension proxy 'customer_count_dim': Cannot reference current model 'customers' (only joined models allowed)
```

[↑ Back to Top](#)

---

## 5. Measures Validation

### 5.1 Measure Name Validation

**Rule:** Measure name must follow identifier format rules

**Invalid example:**
```yaml
measures:
  "total-revenue":  # Invalid: contains hyphen
    type: sum
    expression: "SUM(amount)"
```

**Error message:**
```
ERROR: Invalid measure name 'total-revenue': Invalid character '-' (only letters, digits, underscores allowed)
```

### 5.2 Measure Expression Validation

**Rule:** Expression must be valid SQL

**Invalid example:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount"  # Missing closing parenthesis
```

**Error message:**
```
ERROR: Measure 'total_revenue': Invalid SQL expression (syntax error at position 10)
```

**Rule:** Referenced columns must exist

**Invalid example:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(non_existent_column)"  # Column doesn't exist
```

**Error message:**
```
ERROR: Measure 'total_revenue': Column 'non_existent_column' not found in model 'analytics.orders'
```

**Rule:** Other models must be connected via joins

**Invalid example:**
```yaml
models:
  analytics.orders:
    alias: orders
    
    measures:
      customer_revenue:
        type: sum
        expression: "SUM(customers.amount)"  # No join to 'customers'
```

**Error message:**
```
ERROR: Measure 'customer_revenue': Model 'customers' not reachable via joins (model 'orders')
```

**Rule:** Cannot reference the measure itself (no self-reference)

**Invalid example:**
```yaml
measures:
  total_revenue:
    type: expression
    expression: "total_revenue * 1.1"  # Self-reference
```

**Error message:**
```
ERROR: Measure 'total_revenue': Cannot reference itself (circular dependency)
```

### 5.3 Measure Filter Validation

**Rule:** Each filter must be valid SQL WHERE condition

**Invalid example:**
```yaml
measures:
  active_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'active'"  # Missing closing quote
```

**Error message:**
```
ERROR: Measure 'active_revenue': Invalid filter expression (syntax error)
```

**Rule:** Filters cannot reference measures

**Invalid example:**
```yaml
measures:
  high_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "total_revenue > 1000"  # Cannot reference measure
```

**Error message:**
```
ERROR: Measure 'high_revenue': Filter cannot reference measure 'total_revenue' (only columns and dimensions allowed)
```

### 5.4 Measure Dependency Validation

**Rule:** Referenced measures must exist

**Invalid example:**
```yaml
measures:
  avg_revenue:
    type: expression
    expression: "total_revenue / NULLIF(total_orders, 0)"  # total_revenue doesn't exist
```

**Error message:**
```
ERROR: Measure 'avg_revenue': Referenced measure 'total_revenue' not found
```

**Rule:** No circular dependencies

**Invalid example:**
```yaml
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"
  
  measure_b:
    type: expression
    expression: "measure_a + 20"  # Circular dependency
```

**Error message:**
```
ERROR: Circular dependency detected in measures: measure_a → measure_b → measure_a
```

[↑ Back to Top](#)

---

## 6. Segments Validation

### 6.1 Segment Name Validation

**Rule:** Segment name must follow identifier format rules

**Invalid example:**
```yaml
segments:
  "active-users":  # Invalid: contains hyphen
    expression: "status = 'active'"
```

**Error message:**
```
ERROR: Invalid segment name 'active-users': Invalid character '-' (only letters, digits, underscores allowed)
```

### 6.2 Segment Expression Validation

**Rule:** Expression must be valid SQL WHERE condition

**Invalid example:**
```yaml
segments:
  active:
    expression: "status = 'active"  # Missing closing quote
```

**Error message:**
```
ERROR: Segment 'active': Invalid expression (syntax error)
```

**Rule:** Can only reference current model columns

**Invalid example:**
```yaml
models:
  analytics.customers:
    alias: customers
    
    segments:
      has_orders:
        expression: "orders.order_count > 0"  # Cannot reference other model
```

**Error message:**
```
ERROR: Segment 'has_orders': Cannot reference other model 'orders' (only current model columns allowed)
```

**Rule:** Cannot reference measures

**Invalid example:**
```yaml
segments:
  high_value:
    expression: "total_revenue > 1000"  # Cannot reference measure
```

**Error message:**
```
ERROR: Segment 'high_value': Cannot reference measure 'total_revenue' (only columns allowed)
```

**Rule:** Dimension proxies must use `{proxy_name}` syntax

**Invalid example:**
```yaml
segments:
  has_orders:
    expression: "order_count_dim > 0"  # Should use {order_count_dim}
```

**Error message:**
```
ERROR: Segment 'has_orders': Dimension proxy 'order_count_dim' must be referenced as '{order_count_dim}'
```

**Valid example:**
```yaml
segments:
  has_orders:
    expression: "{order_count_dim} > 0"  # Correct syntax
```

[↑ Back to Top](#)

---

## 7. Joins Validation

### 7.1 Join Name Validation

**Rule:** Join `name` must be semantic model alias (not physical name)

**Invalid example:**
```yaml
joins:
  analytics.customers:  # Should be 'customers' (alias)
    type: many_to_one
    expression: "..."
```

**Error message:**
```
ERROR: Join target 'analytics.customers' not found (use semantic alias 'customers')
```

### 7.2 Join Target Validation

**Rule:** Target model must exist

**Invalid example:**
```yaml
joins:
  non_existent_model:
    type: one_to_many
    expression: "..."
```

**Error message:**
```
ERROR: Join target 'non_existent_model' not found
```

### 7.3 Join Expression Validation

**Rule:** Expression must use `model.column` format

**Invalid examples:**
```yaml
joins:
  # ❌ Error: Unqualified column
  customers:
    type: many_to_one
    expression: "customer_id = customers.customer_id"
  
  # ❌ Error: Column doesn't exist
  customers_2:
    type: many_to_one
    expression: "orders.non_existent_col = customers.customer_id"
```

**Error messages:**
```
ERROR: Join expression: Column 'customer_id' must be qualified with model name (use 'orders.customer_id')
ERROR: Join expression: Column 'non_existent_col' not found in model 'analytics.orders'
```

**Rule:** Expression must be valid SQL join condition

**Invalid example:**
```yaml
joins:
  customers:
    type: many_to_one
    expression: "orders.customer_id"  # Not a join condition
```

**Error message:**
```
ERROR: Join expression: Invalid join condition (must be comparison expression)
```

### 7.4 Join Graph Validation

**Rule:** No circular dependencies

**Invalid example:**
```yaml
# Creates cycle: customers → orders → products → customers
models:
  analytics.customers:
    alias: customers
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"

  analytics.orders:
    alias: orders
    joins:
      products:
        type: many_to_one
        expression: "orders.product_id = products.product_id"

  analytics.products:
    alias: products
    joins:
      customers:  # Creates cycle
        type: many_to_one
        expression: "products.vendor_id = customers.customer_id"
```

**Error message:**
```
ERROR: Circular dependency detected in join graph: customers → orders → products → customers
```

[↑ Back to Top](#)

---

## 8. Metrics Validation

### 8.1 Metric Name Validation

**Rule:** Metric name must follow identifier format rules

**Invalid example:**
```yaml
metrics:
  "monthly-revenue":  # Invalid: contains hyphen
    measure: orders.total_revenue
    time: orders.order_date
```

**Error message:**
```
ERROR: Invalid metric name 'monthly-revenue': Invalid character '-' (only letters, digits, underscores allowed)
```

### 8.2 Metric Measure Validation

**Rule:** `measure` must be in `model.measure` format

**Invalid examples:**
```yaml
metrics:
  monthly_revenue:
    # ❌ Error: Missing model prefix
    measure: total_revenue
    
    # ❌ Error: Too many dots
    measure: analytics.orders.total_revenue
```

**Error messages:**
```
ERROR: Metric 'monthly_revenue': Measure reference must be in 'model.measure' format (got 'total_revenue')
ERROR: Metric 'monthly_revenue': Measure reference must have exactly one dot (got 'analytics.orders.total_revenue')
```

**Rule:** Referenced measure must exist

**Invalid example:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.non_existent_measure
    time: orders.order_date
```

**Error message:**
```
ERROR: Metric 'monthly_revenue': Measure 'non_existent_measure' not found in model 'orders'
```

### 8.3 Metric Time Validation

**Rule:** `time` must be in `model.column` format

**Invalid example:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: order_date  # Missing model prefix
```

**Error message:**
```
ERROR: Metric 'monthly_revenue': Time reference must be in 'model.column' format (got 'order_date')
```

**Rule:** Column must be timestamp/datetime type

**Invalid example:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.status  # Not a timestamp column
```

**Error message:**
```
ERROR: Metric 'monthly_revenue': Time column 'status' must be timestamp/datetime type (got VARCHAR)
```

**Rule:** Cannot be same field as measure (if same model)

**Invalid example:**
```yaml
metrics:
  revenue_over_time:
    measure: orders.total_revenue
    time: orders.total_revenue  # Same field as measure
```

**Error message:**
```
ERROR: Metric 'revenue_over_time': Time and measure cannot reference same field 'total_revenue'
```

### 8.4 Metric Dimensions Validation

**Rule:** All references must use `model.field` format

**Invalid example:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customer_tier  # Missing model prefix
```

**Error message:**
```
ERROR: Metric 'monthly_revenue': Dimension reference must be in 'model.field' format (got 'customer_tier')
```

**Rule:** No duplicate dimensions

**Invalid example:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.customer_tier  # Duplicate
```

**Error message:**
```
ERROR: Metric 'monthly_revenue': Duplicate dimension 'customers.customer_tier'
```

**Rule:** All models must be connected via joins

**Invalid example:**
```yaml
metrics:
  revenue_by_product:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - products.category  # No join path from orders to products
```

**Error message:**
```
ERROR: Metric 'revenue_by_product': No join path found from 'orders' to 'products'
```

[↑ Back to Top](#)

---

## 9. Reference Validation

### 9.1 Model Reference Format

**Rule:** All model references must use semantic alias (not physical name)

**Invalid examples:**
```yaml
# ❌ Using physical name
measure: analytics.orders.total_revenue

# ✅ Using semantic alias
measure: orders.total_revenue
```

**Error message:**
```
ERROR: Model reference 'analytics.orders' not found (use semantic alias 'orders')
```

### 9.2 Field Reference Format

**Rule:** References must use `model.field` format (exactly one dot)

**Invalid examples:**
```yaml
# ❌ Missing model prefix
measure: total_revenue

# ❌ Too many dots
measure: analytics.orders.total_revenue

# ✅ Correct
measure: orders.total_revenue
```

**Error messages:**
```
ERROR: Reference must include model prefix (use 'model.field' format)
ERROR: Reference must have exactly one dot (got 'analytics.orders.total_revenue')
```

### 9.3 Cross-Model Reference Rules

**What can reference what:**

| From | Can Reference | Cannot Reference |
|------|---------------|------------------|
| **Measure filter** | Current model columns/dimensions, Joined model dimensions | Measures, Models without join |
| **Measure expression** | Current model columns/dimensions/measures, Joined model dimensions/measures | Self-reference, Models without join |
| **Segment expression** | Current model columns only | Other models, Measures, Dimension proxies (except `{proxy}` syntax) |
| **Join expression** | Source/target model columns | Other models |
| **Metric measure/time/dims** | Measures/dimensions/columns across models | Models without join path |

**Invalid examples:**
```yaml
# ❌ Measure filter referencing measure
measures:
  high_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "total_revenue > 1000"  # Cannot reference measure

# ❌ Segment referencing other model
segments:
  has_orders:
    expression: "orders.order_count > 0"  # Cannot reference other model

# ❌ Metric with disconnected models
metrics:
  revenue_by_product:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - products.category  # No join path
```

[↑ Back to Top](#)

---

## 10. Common Error Patterns

### 10.1 Naming Errors

**Pattern: Invalid characters**

```yaml
# ❌ Common mistakes
"total-revenue":     # Hyphen
  type: sum
"total revenue":     # Space
  type: sum
"123revenue":        # Starts with digit
  type: sum
"total.revenue":     # Dot
  type: sum
```

**Solution:** Use only letters, digits, underscores, start with letter

### 10.2 Reference Errors

**Pattern: Missing model prefix**

```yaml
# ❌ Common mistake
measure: total_revenue  # Missing 'orders.' prefix

# ✅ Correct
measure: orders.total_revenue
```

**Pattern: Using physical name instead of alias**

```yaml
# ❌ Common mistake
measure: analytics.orders.total_revenue  # Physical name

# ✅ Correct
measure: orders.total_revenue  # Semantic alias
```

### 10.3 Dependency Errors

**Pattern: Circular dependencies**

```yaml
# ❌ Common mistake
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"
  measure_b:
    type: expression
    expression: "measure_a + 20"  # Circular!
```

**Solution:** Break cycle with base measure

### 10.4 Join Errors

**Pattern: Disconnected models**

```yaml
# ❌ Common mistake
metrics:
  revenue_by_product:
    measure: orders.total_revenue
    dimensions:
      - products.category  # No join defined
```

**Solution:** Add join between models

[↑ Back to Top](#)

---

## 11. Troubleshooting Guide

### 11.1 Step-by-Step Debugging

**Step 1: Read the error message**
- Identify component (measure, segment, join, etc.)
- Note the rule violated
- Check file location

**Step 2: Locate the problematic definition**
- Open the file mentioned in error
- Find the line number
- Review the definition

**Step 3: Check validation rules**
- Refer to relevant section in this chapter
- Verify field requirements
- Check reference formats

**Step 4: Fix the issue**
- Apply the solution pattern
- Validate syntax
- Test the fix

**Step 5: Re-validate**
- Run `vulcan validate` again
- Check for additional errors
- Iterate until clean

### 11.2 Common Fixes

**Fix naming errors:**
```yaml
# Before
"total-revenue":
  type: sum

# After
total_revenue:
  type: sum
```

**Fix reference errors:**
```yaml
# Before
measure: total_revenue

# After
measure: orders.total_revenue
```

**Fix dependency errors:**
```yaml
# Before (circular)
measures:
  measure_a:
    type: expression
    expression: "measure_b + 10"
  measure_b:
    type: expression
    expression: "measure_a + 20"

# After (base measure)
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

**Fix join errors:**
```yaml
# Before (missing join)
metrics:
  revenue_by_product:
    measure: orders.total_revenue
    dimensions:
      - products.category

# After (add join)
models:
  analytics.orders:
    alias: orders
    joins:
      products:
        type: many_to_one
        expression: "orders.product_id = products.product_id"
```

### 11.3 Validation Checklist

**Before submitting:**
- [ ] All names follow identifier rules
- [ ] No duplicate names within models
- [ ] No duplicate metric names across files
- [ ] All model references use semantic aliases
- [ ] All field references use `model.field` format
- [ ] All referenced models exist
- [ ] All referenced fields exist
- [ ] All models in metrics are connected via joins
- [ ] No circular dependencies
- [ ] All required fields are present
- [ ] SQL expressions are valid
- [ ] YAML syntax is correct

[↑ Back to Top](#)

---

## 12. Summary

### Key Validation Rules

1. **Naming:**
   - Start with letter
   - Only letters, digits, underscores
   - Max 64 characters
   - Unique within scope

2. **References:**
   - Always use `model.field` format
   - Use semantic aliases (not physical names)
   - Exactly one dot in references

3. **Dependencies:**
   - No circular dependencies
   - All referenced entities must exist
   - Models must be connected via joins

4. **Field Requirements:**
   - Required fields must be present
   - Field types must match (e.g., timestamp for time)
   - SQL expressions must be valid

### Validation Workflow

1. **Write definitions** following syntax rules
2. **Validate frequently** during development
3. **Read error messages** carefully
4. **Fix issues** systematically
5. **Re-validate** until clean

### Next Steps

- [Chapter 3: Semantic Layer](index.md) - Foundation concepts
- [Chapter 3A: YAML Reference](yaml-reference.md) - Complete syntax reference
- [Chapter 3B: Advanced Measures](measures.md) - Complex measure patterns
- [Chapter 3C: Advanced Joins](joins.md) - Cross-model analysis patterns

[↑ Back to Top](#)

