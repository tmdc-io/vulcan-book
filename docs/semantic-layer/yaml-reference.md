# Chapter 3A: Semantic Layer YAML Reference

> **Complete reference for all semantic layer YAML syntax** - Every field, option, and pattern explained with examples, defaults, and validation rules.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 3: Semantic Layer** - Understanding of:
- Basic semantic layer concepts
- Models, dimensions, measures, segments, joins, metrics
- How semantic layer maps to physical models

**YAML Syntax**
- Basic YAML structure (dictionaries, lists)
- Multi-line strings (`|` syntax)
- Indentation rules

**SQL Proficiency**
- Basic SQL expressions
- Aggregations (`COUNT`, `SUM`, `AVG`)
- `WHERE` clauses

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Top-Level Structure](#2-top-level-structure)
3. [Semantic Models](#3-semantic-models)
4. [Dimensions](#4-dimensions)
5. [Measures](#5-measures)
6. [Segments](#6-segments)
7. [Joins](#7-joins)
8. [Business Metrics](#8-business-metrics)
9. [Naming and Validation Rules](#9-naming-and-validation-rules)
10. [YAML Formatting Best Practices](#10-yaml-formatting-best-practices)
11. [Quick Reference](#11-quick-reference)
12. [Complete Examples](#12-complete-examples)

---

## 1. Introduction

### 1.1 What is This Reference?

This chapter provides a **complete, exhaustive reference** for every field, option, and pattern in semantic layer YAML files. Use it when you need to:

- Understand what a specific field does
- Know what values are valid
- See examples of complex patterns
- Debug validation errors
- Find the exact syntax for a feature

### 1.2 How to Use This Reference

**For Quick Lookups:**
- Jump to [Quick Reference](#11-quick-reference) for syntax cheat sheets
- Use the table of contents to find specific components

**For Deep Understanding:**
- Read each section in order
- Study the examples
- Review validation rules

**For Troubleshooting:**
- Check [Naming and Validation Rules](#9-naming-and-validation-rules)
- Review field requirements
- Verify syntax patterns

### 1.3 File Organization

Semantic layer definitions live in YAML files, typically:

```
project/
├── semantics/
│   ├── customers.yml      # Customer model definitions
│   ├── orders.yml         # Order model definitions
│   ├── products.yml       # Product model definitions
│   └── metrics.yml        # Business metrics
└── config.yaml
```

**File naming:**
- Must end with `.yml` or `.yaml`
- Name doesn't matter (Vulcan reads all files)
- Organize by domain or model for clarity

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 2. Top-Level Structure

### 2.1 Root Keys

Every semantic layer YAML file has two top-level keys:

```yaml
models:      # Dictionary of semantic model definitions
  <physical_model>:  # Dictionary key (physical model name)
    name: ...        # Business-friendly alias
    dimensions: ...
    measures: ...
    segments: ...
    joins: ...

metrics:     # Dictionary of business metric definitions
  metric_name: ...
    measure: ...
    time: ...
    dimensions: ...
```

**Both keys are optional:**
- File can contain only `models:` (no metrics)
- File can contain only `metrics:` (no models)
- File can contain both

### 2.2 Models Dictionary

`models:` is a **dictionary** of semantic model definitions:

```yaml
models:
  analytics.customers:    # Physical model name (dictionary key)
    alias: customers       # Business-friendly semantic alias
    measures: {...}
  
  analytics.orders:        # Physical model name (dictionary key)
    alias: orders          # Business-friendly semantic alias
    measures: {...}
```

**Key points:**
- Each model is a dictionary key (physical model name)
- `name:` field provides the business-friendly alias
- Models are independent (can reference each other)
- Order doesn't matter (Vulcan resolves dependencies)

### 2.3 Metrics Dictionary

`metrics:` is a **dictionary** of business metric definitions:

```yaml
metrics:
  monthly_revenue:              # Metric name (key)
    measure: orders.total_revenue
    time: orders.order_date
  
  customer_growth:               # Another metric (key)
    measure: customers.total_customers
    time: customers.signup_date
```

**Key points:**
- Each metric is a dictionary key
- Metric names must be unique across all files
- Metrics reference models defined in `models:`

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 3. Semantic Models

### 3.1 Model Structure

A semantic model maps a physical Vulcan model to a semantic representation:

```yaml
models:
  <physical_model_name>:     # REQUIRED (dictionary key)
    name: <semantic_alias>   # Required for schema.table format
    description: "..."        # Optional
    dimensions: {...}         # Optional
    measures: {...}           # Optional
    segments: {...}           # Optional
    joins: {...}              # Optional
```

### 3.2 `name` (Required)

**Purpose:** References the physical Vulcan model

**Format:**
- Simple name: `customers` (no schema prefix)
- Fully qualified: `analytics.customers` (schema.table format)

**Examples:**
```yaml
# Simple model name
customers:
  alias: customers

# Fully qualified name (schema.table)
analytics.dim_customers:
  alias: customers
- name: sales.fact_orders
```

**Validation:**
- Must match an existing Vulcan model name exactly
- Case-sensitive
- Must exist when semantic layer is loaded

**Error examples:**
```yaml
# ❌ Model doesn't exist
- name: non_existent_model

# ❌ Typo in name
- name: analytics.custmers  # Should be 'customers'
```

### 3.3 `alias` (Required for FQN)

**Purpose:** Consumer-facing name for the semantic model

**When required:**
- **Required** when `name` is fully qualified (`schema.table`)
- **Optional** when `name` is simple (no schema prefix)

**Format:**
- Must follow identifier rules (see [Naming Rules](#9-naming-and-validation-rules))
- Letters, digits, underscores only
- Starts with letter
- Max 64 characters

**Examples:**
```yaml
# ✅ FQN with alias (required)
- name: analytics.dim_customers
  alias: customers

# ✅ Simple name (alias optional, defaults to name)
- name: customers
  # alias defaults to 'customers'

# ✅ Simple name with explicit alias
- name: customers
  alias: users  # Override default
```

**Usage:**
- Use `alias` in all references (joins, metrics, dimension proxies)
- Never use physical model name (`analytics.customers`) in references
- Always use semantic alias (`customers`) in references

**Error examples:**
```yaml
# ❌ FQN without alias
- name: analytics.customers
  # Missing alias!

# ❌ Invalid alias format
- name: analytics.customers
  alias: "customer-users"  # Hyphens not allowed
```

### 3.4 `description` (Optional)

**Purpose:** Human-readable description of the semantic model

**Format:**
- String (single or multi-line)
- No length limit
- Supports markdown (tool-dependent)

**Examples:**
```yaml
- name: analytics.customers
  alias: customers
  description: "Customer dimension table with subscription and profile data"
  
- name: analytics.orders
  alias: orders
  description: |
    Fact table containing all customer orders.
    Includes order details, amounts, and status.
    Updated daily from transactional system.
```

**Best practices:**
- Explain what the model represents
- Note data freshness or update frequency
- Mention key business use cases

### 3.5 Model Sections

Each semantic model can have four optional sections:

| Section | Purpose | Required? |
|---------|---------|-----------|
| `dimensions` | Column selection and enhancement | No |
| `measures` | Aggregated calculations | No |
| `segments` | Reusable filter conditions | No |
| `joins` | Relationships to other models | No |

**All sections are optional:**
```yaml
# Minimal model (all columns as dimensions, no measures)
analytics.customers:
  alias: customers

# Model with measures only
analytics.orders:
  alias: orders
  measures:
    total_revenue:
      type: sum
      expression: "SUM(amount)"

# Complete model
analytics.customers:
  alias: customers
  dimensions: {...}
  measures: {...}
  segments: {...}
  joins: {...}
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 4. Dimensions

### 4.1 Dimension Structure

Dimensions control which columns are exposed and how they're enriched:

```yaml
dimensions:
  includes: [...]                # Option 1: Whitelist columns
  excludes: [...]                # Option 2: Blacklist columns
  overrides: [...]               # Add tags/meta to dimensions
  proxies: [...]                 # Proxy joined model measures as dimensions
```

**All fields are optional:**
- If `dimensions:` block is omitted, all columns are available
- If `dimensions:` block exists, at least one field should be specified

### 4.2 `includes` (Optional)

**Purpose:** Explicitly list columns to expose as dimensions

**Format:**
- Array of column names (strings)
- Column names must exist in physical model
- Case-sensitive

**Examples:**
```yaml
dimensions:
  includes:
    - customer_id
    - email
    - customer_tier
    - signup_date
```

**Use when:**
- Working with sensitive data models
- Only exposing specific columns
- Tight control over exposed dimensions

**Validation:**
- All listed columns must exist in physical model
- Cannot use both `includes` and `excludes` (mutually exclusive)

**Error examples:**
```yaml
# ❌ Column doesn't exist
dimensions:
  includes:
    - non_existent_column

# ❌ Using both includes and excludes
dimensions:
  includes: [col1, col2]
  excludes: [col3]  # Error: mutually exclusive
```

### 4.3 `excludes` (Optional)

**Purpose:** Hide specific columns from dimensions

**Format:**
- Array of column names (strings)
- Column names must exist in physical model
- Case-sensitive

**Examples:**
```yaml
dimensions:
  excludes:
    - password_hash
    - ssn
    - internal_notes
    - deleted_at
```

**Use when:**
- Most columns are fine, but need to hide a few
- Hiding sensitive or internal columns
- Most common pattern

**Validation:**
- All listed columns must exist in physical model
- Cannot use both `includes` and `excludes` (mutually exclusive)

**Default behavior:**
- If neither `includes` nor `excludes` is specified, all columns are available

### 4.4 `overrides` (Optional)

**Purpose:** Add tags and metadata to specific dimensions

**Format:**
- Array of dimension override objects
- Each override has `name` (required) and optional `tags`/`meta`

**Structure:**
```yaml
overrides:
  <column_name>:                 # REQUIRED (dictionary key)
    tags: [...]                  # Optional: Array of strings
    meta: {...}                  # Optional: Dictionary
```

**Examples:**
```yaml
dimensions:
  excludes:
    - password_hash
  
  overrides:
    customer_tier:
      tags:
        - segmentation
        - revenue
        - high_priority
      meta:
        business_owner: "Product Team"
        display_name: "Customer Tier"
        sort_order: ["Free", "Pro", "Enterprise"]
    
    - name: signup_date
      tags:
        - temporal
        - acquisition
      meta:
        business_owner: "Growth Team"
        format: "YYYY-MM-DD"
        timezone: "UTC"
```

**Validation:**
- `name` must refer to an existing column (after includes/excludes are applied)
- `tags` must be an array of strings
- `meta` must be a dictionary (key-value pairs)

**Common metadata fields:**
- `business_owner` - Team responsible
- `display_name` - UI-friendly name
- `description` - Business definition
- `possible_values` - Valid values for enums
- `format` - Display format hints
- `sort_order` - Preferred ordering
- Custom fields as needed

### 4.5 `proxies` (Optional)

**Purpose:** Expose measures from joined models as dimensions on current model

**Format:**
- Array of proxy objects
- Each proxy has `name` (required) and `measure` (required)

**Structure:**
```yaml
proxies:
  <dimension_alias>:              # REQUIRED (dictionary key)
    measure: <model_alias>.<measure_name>  # REQUIRED
```

**Examples:**
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.total_orders
    
    lifetime_value_dim:
      measure: orders.total_revenue
```

**Use when:**
- Need to filter/group by a measure from another model
- Creating segments that reference cross-model measures
- Enabling CubeJS-like functionality

**Validation:**
- `name` must follow identifier rules and be unique
- `measure` must be in `model.measure` format (exactly one dot)
- Referenced model must exist and be reachable via joins
- Referenced measure must exist on target model
- Cannot reference current model (only joined models)

**Error examples:**
```yaml
# ❌ Invalid measure format
proxies:
  order_count:
    measure: total_orders  # Missing model prefix

# ❌ Model doesn't exist
proxies:
  order_count:
    measure: non_existent_model.total_orders

# ❌ Measure doesn't exist
proxies:
  order_count:
    measure: orders.non_existent_measure
```

**Usage in segments:**
```yaml
segments:
  has_orders:
    expression: "{order_count_dim} > 0"  # Use proxy in segment
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 5. Measures

### 5.1 Measure Structure

Measures define aggregated values computed from your data:

```yaml
measures:
  <measure_name>:                # REQUIRED (dictionary key)
    type: <type>                 # REQUIRED (count, sum, avg, expression, etc.)
    expression: "<SQL_EXPRESSION>"  # REQUIRED
    description: "..."         # Optional
    filters: [...]               # Optional: Array of WHERE conditions
    format: <format_type>        # Optional: Display hint
    tags: [...]                  # Optional: Array of strings
    meta: {...}                  # Optional: Dictionary
```

### 5.2 `name` (Required)

**Purpose:** Unique identifier for the measure

**Format:**
- Must follow identifier rules (see [Naming Rules](#9-naming-and-validation-rules))
- Letters, digits, underscores only
- Starts with letter
- Max 64 characters
- Must be unique within model

**Examples:**
```yaml
measures:
  total_revenue:
    type: sum
  active_customers:
    type: count
  avg_order_value:
    type: avg
  customer_count_30d:
    type: count
```

**Validation:**
- Must be unique within model (cannot duplicate measure names)
- Cannot conflict with segment names
- Cannot conflict with dimension proxy names

**Error examples:**
```yaml
# ❌ Duplicate measure name
measures:
  total_revenue:
    type: sum
  total_revenue:  # Duplicate! (same key twice)

# ❌ Invalid format
measures:
  "total-revenue":  # Hyphens not allowed
    type: sum
```

### 5.3 `expression` (Required)

**Purpose:** SQL expression that computes the measure value

**Format:**
- Valid SQL aggregation expression
- Can reference columns, dimensions, other measures
- Use `model.field` format for other models

**Basic examples:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
  
  order_count:
    type: count
    expression: "COUNT(*)"
  
  avg_order_value:
    type: avg
    expression: "AVG(order_total)"
  
  unique_customers:
    type: count_distinct
    expression: "COUNT(DISTINCT customer_id)"
```

**Complex examples:**
```yaml
measures:
  active_revenue:
    type: sum
    expression: |
      SUM(CASE 
        WHEN status = 'active' 
        THEN amount 
        ELSE 0 
      END)
  
  revenue_per_customer:
    type: expression
    expression: "SUM(amount) / COUNT(DISTINCT customer_id)"
  
  conversion_rate:
    type: expression
    expression: |
      COUNT(CASE WHEN converted = true THEN 1 END)::FLOAT / 
      NULLIF(COUNT(*), 0)
```

**Cross-model references:**
```yaml
measures:
  customer_order_count:
    type: count
    expression: "COUNT(orders.order_id)"  # Reference joined model
  
  total_customer_value:
    type: sum
    expression: "SUM(orders.amount)"  # Aggregate from joined model
```

**What can be referenced:**
- ✅ Current model columns: `amount`, `customer_id`
- ✅ Current model dimensions: `customer_tier`, `signup_date`
- ✅ Current model measures: `base_revenue` (no self-reference)
- ✅ Joined model dimensions: `users.country`, `products.category`
- ✅ Joined model measures: `subscriptions.mrr`, `usage.total_events`

**Validation:**
- Must be valid SQL
- Referenced fields must exist
- Other models must be connected via joins
- Cannot reference the measure itself (no self-reference)

### 5.4 `filters` (Optional)

**Purpose:** Apply WHERE conditions to measure calculation

**Format:**
- Array of SQL WHERE conditions (strings)
- Each filter is a separate condition
- Conditions are combined with AND logic

**Examples:**
```yaml
measures:
  active_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "status = 'active'"
  
  recent_signups:
    type: count
    expression: "COUNT(*)"
    filters:
      - "signup_date >= CURRENT_DATE - INTERVAL '30 days'"
  
  enterprise_mrr:
    type: sum
    expression: "SUM(mrr)"
    filters:
      - "plan_type = 'Enterprise'"
      - "status = 'active'"
      - "start_date <= CURRENT_DATE"
```

**Filter logic:**
- All filters are combined with AND
- Applied before aggregation
- Can reference current model columns/dimensions
- Can reference joined model dimensions (via `model.field`)

**Cross-model filters:**
```yaml
measures:
  us_customer_revenue:
    type: sum
    expression: "SUM(amount)"
    filters:
      - "customers.country = 'US'"  # Reference joined model
      - "status = 'completed'"
```

**What can be referenced:**
- ✅ Current model columns: `status`, `amount`
- ✅ Current model dimensions: `customer_tier`, `signup_date`
- ✅ Current model dimension proxies: `order_count_dim`
- ✅ Joined model dimensions: `users.country`, `products.category`
- ❌ Measures (current or other models)

**Validation:**
- Each filter must be valid SQL WHERE condition
- Cannot be empty strings
- Referenced fields must exist
- Other models must be connected via joins

### 5.5 `format` (Optional)

**Purpose:** Display format hint for the measure

**Format:**
- String value from predefined list
- Tool-dependent (may be ignored by some consumers)

**Valid values:**
- `currency` - Monetary values ($1,234.56)
- `percentage` - Percentages (12.5%)
- `number` - Numeric values (1,234.56)
- `duration_ms` - Time duration in milliseconds
- `bytes` - Byte sizes (1.5 MB)

**Examples:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    format: currency
  
  conversion_rate:
    type: expression
    expression: "COUNT(converted) / COUNT(*)"
    format: percentage
  
  avg_session_duration:
    type: avg
    expression: "AVG(duration)"
    format: duration_ms
```

**Note:** Format is a hint only - actual formatting depends on consuming tool

### 5.6 `description` (Optional)

**Purpose:** Human-readable description of the measure

**Format:**
- String (single or multi-line)
- No length limit
- Supports markdown (tool-dependent)

**Examples:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    description: "Total revenue from all orders"
  
  active_mrr:
    type: sum
    expression: "SUM(mrr)"
    description: |
      Monthly Recurring Revenue from active subscriptions only.
      Excludes cancelled, paused, or trial subscriptions.
      Updated daily at 2 AM UTC.
```

**Best practices:**
- Explain what the measure calculates
- Note any filters or conditions
- Mention update frequency if relevant

### 5.7 `tags` (Optional)

**Purpose:** Categorize measures for discovery and organization

**Format:**
- Array of strings
- No predefined values
- Case-sensitive

**Examples:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    tags:
      - revenue
      - financial
      - kpi
      - core_metric
  
  active_customers:
    type: count
    expression: "COUNT(*)"
    tags:
      - count
      - customers
      - active
```

**Common tag patterns:**
- **Domain:** `sales`, `marketing`, `finance`, `product`
- **Type:** `revenue`, `count`, `rate`, `average`
- **Priority:** `kpi`, `core_metric`, `experimental`
- **Status:** `deprecated`, `certified`, `under_review`

### 5.8 `meta` (Optional)

**Purpose:** Free-form metadata dictionary

**Format:**
- Dictionary (key-value pairs)
- Any keys allowed
- Values can be strings, numbers, arrays, dictionaries

**Examples:**
```yaml
measures:
  total_revenue:
    type: sum
    expression: "SUM(amount)"
    meta:
      business_owner: "Finance Team"
      certified: true
      calculation_method: "sum_of_order_amounts"
      data_source: "orders table"
      last_updated: "2024-01-15"
      kpi_target: 1000000
```

**Common metadata fields:**
- `business_owner` - Team responsible
- `certified` - Boolean indicating certification status
- `calculation_method` - How measure is computed
- `data_source` - Source table/model
- `last_updated` - Update timestamp
- Custom fields as needed

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 6. Segments

### 6.1 Segment Structure

Segments define reusable filter conditions for the current model:

```yaml
segments:
  <segment_name>:                 # REQUIRED (dictionary key)
    expression: "<WHERE_CONDITION>"  # REQUIRED (no WHERE keyword)
    description: "..."            # Optional
    tags: [...]                   # Optional: Array of strings
    meta: {...}                   # Optional: Dictionary
```

### 6.2 `name` (Required)

**Purpose:** Unique identifier for the segment

**Format:**
- Must follow identifier rules (see [Naming Rules](#9-naming-and-validation-rules))
- Letters, digits, underscores only
- Starts with letter
- Max 64 characters
- Must be unique within model

**Examples:**
```yaml
segments:
  active_users:
    expression: "..."
  high_value_customers:
    expression: "..."
  recent_signups:
    expression: "..."
  enterprise_tier:
    expression: "..."
```

**Validation:**
- Must be unique within model (cannot duplicate segment names)
- Cannot conflict with measure names
- Cannot conflict with dimension proxy names

### 6.3 `expression` (Required)

**Purpose:** SQL WHERE condition (without WHERE keyword)

**Format:**
- Valid SQL WHERE condition
- Can only reference current model columns
- Use `{dimension_proxy_name}` syntax for dimension proxies

**Basic examples:**
```yaml
segments:
  active:
    expression: "status = 'active'"
  
  high_value:
    expression: "total_spent > 10000"
  
  recent_signups:
    expression: "signup_date >= CURRENT_DATE - INTERVAL '30 days'"
```

**Complex examples:**
```yaml
segments:
  active_enterprise:
    expression: |
      status = 'active'
      AND customer_tier = 'Enterprise'
      AND signup_date >= CURRENT_DATE - INTERVAL '90 days'
  
  at_risk:
    expression: |
      status = 'active'
      AND last_activity_date < CURRENT_DATE - INTERVAL '14 days'
      AND total_spent < 1000
```

**Using dimension proxies:**
```yaml
dimensions:
  proxies:
    order_count_dim:
      measure: orders.total_orders

segments:
  has_orders:
    expression: "{order_count_dim} > 0"  # Use proxy in segment
```

**What can be referenced:**
- ✅ Current model columns: `status`, `amount`, `customer_id`
- ✅ Current model dimensions: `customer_tier`, `signup_date`
- ✅ Current model dimension proxies: `{order_count_dim}`
- ❌ Other models: `users.country` (not allowed)
- ❌ Measures: `total_revenue` (not allowed)

**Validation:**
- Must be valid SQL WHERE condition
- Can only reference current model's raw columns
- Dimension proxies must use `{proxy_name}` syntax
- Cannot reference other models

**Error examples:**
```yaml
# ❌ Reference other model
segments:
  us_customers:
    expression: "users.country = 'US'"  # Not allowed

# ❌ Reference measure
segments:
  high_revenue:
    expression: "total_revenue > 1000"  # Not allowed
```

### 6.4 `description` (Optional)

**Purpose:** Human-readable description of the segment

**Format:**
- String (single or multi-line)
- No length limit

**Examples:**
```yaml
segments:
  active_users:
    expression: "status = 'active'"
    description: "Users with active status"
  
  high_value:
    expression: "total_spent > 10000"
    description: |
      Customers with lifetime spend exceeding $10,000.
      Used for VIP program eligibility and targeted marketing.
```

### 6.5 `tags` (Optional)

**Purpose:** Categorize segments for discovery

**Format:**
- Array of strings
- No predefined values

**Examples:**
```yaml
segments:
  active_users:
    expression: "status = 'active'"
    tags:
      - lifecycle
      - active
      - core_segment
  
  high_value:
    expression: "total_spent > 10000"
    tags:
      - segmentation
      - revenue
      - vip
```

### 6.6 `meta` (Optional)

**Purpose:** Free-form metadata dictionary

**Format:**
- Dictionary (key-value pairs)
- Any keys allowed

**Examples:**
```yaml
segments:
  active_users:
    expression: "status = 'active'"
    meta:
      business_owner: "Product Team"
      use_cases: ["dashboard", "reporting", "alerts"]
      last_reviewed: "2024-01-15"
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 7. Joins

### 7.1 Join Structure

Joins connect semantic models for cross-model analysis:

```yaml
joins:
  <target_model_alias>:            # REQUIRED (dictionary key)
    type: <type>                   # REQUIRED (one_to_one, one_to_many, many_to_one)
    expression: "<JOIN_CONDITION>"  # REQUIRED
    description: "..."             # Optional
    meta: {...}                   # Optional: Dictionary
```

### 7.2 `name` (Required)

**Purpose:** Semantic alias of the target model to join

**Format:**
- Must be a semantic model alias (not physical name)
- Must exist in `models:` array
- Case-sensitive

**Examples:**
```yaml
# In customers model
joins:
  orders:                     # Join to orders semantic model
    type: one_to_many
    expression: "customers.customer_id = orders.customer_id"

# In orders model
joins:
  customers:                 # Join to customers semantic model
    type: many_to_one
    expression: "orders.customer_id = customers.customer_id"
```

**Validation:**
- Target model alias must exist
- Cannot reference non-existent models
- Cannot create circular dependencies (see [Join Graph](#7-5-join-graph-consistency))

**Error examples:**
```yaml
# ❌ Target model doesn't exist
joins:
  non_existent_model:
    type: one_to_many
    expression: "..."

# ❌ Using physical name instead of alias
joins:
  analytics.customers:  # Should be 'customers' (alias)
    type: one_to_many
    expression: "..."
```

### 7.3 `relationship` (Required)

**Purpose:** Defines the cardinality of the join relationship

**Format:**
- String value from predefined list
- Case-sensitive

**Valid values:**
- `one_to_one` - One row matches one row (1:1)
- `one_to_many` - One row matches many rows (1:N)
- `many_to_one` - Many rows match one row (N:1)

**Examples:**
```yaml
# Customer → Orders (one customer has many orders)
joins:
  orders:
    type: one_to_many
    expression: "customers.customer_id = orders.customer_id"

# Orders → Customer (many orders belong to one customer)
joins:
  customers:
    type: many_to_one
    expression: "orders.customer_id = customers.customer_id"

# User → Profile (one user has one profile)
joins:
  user_profile:
    type: one_to_one
    expression: "users.user_id = user_profile.user_id"
```

**Choosing relationship type:**
- `one_to_many`: Current model is "one" side (e.g., customer → orders)
- `many_to_one`: Current model is "many" side (e.g., orders → customer)

**Note:** The field name is `type:` not `relationship:` in the YAML definition.
- `one_to_one`: Both sides are unique (e.g., user → profile)

**Note:** Relationship type is informational - actual join behavior depends on SQL engine

### 7.4 `expression` (Required)

**Purpose:** SQL join condition

**Format:**
- Valid SQL join condition
- Must use `model.column` format for all references
- Both models must be specified

**Examples:**
```yaml
# Simple join
joins:
  orders:
    type: one_to_many
    expression: "customers.customer_id = orders.customer_id"

# Multi-column join
joins:
  product_locations:
    type: many_to_one
    expression: |
      inventory.product_id = product_locations.product_id
      AND inventory.warehouse_id = product_locations.warehouse_id

# Join with additional conditions
joins:
  active_orders:
    type: one_to_many
    expression: |
      customers.customer_id = orders.customer_id
      AND orders.status = 'active'
```

**What can be referenced:**
- ✅ Current model columns: `customers.customer_id`
- ✅ Target model columns: `orders.customer_id`
- ❌ Unqualified columns: `customer_id` (must use `model.column`)
- ❌ Other models: `third_model.field` (not allowed)

**Validation:**
- All column references must use `model.column` format
- Model name must be either current model or join target
- Both columns must exist in their respective SQL models
- Expression must be valid SQL join condition

**Error examples:**
```yaml
# ❌ Unqualified column
joins:
  orders:
    type: one_to_many
    expression: "customer_id = orders.customer_id"  # Missing model prefix

# ❌ Column doesn't exist
joins:
  orders:
    type: one_to_many
    expression: "customers.non_existent_col = orders.customer_id"
```

### 7.5 Join Graph Consistency

**Purpose:** Ensures joins form a valid, non-cyclic graph

**Rules:**
- Join graph must not contain circular dependencies
- Joins must allow system to determine join paths between models
- All models referenced in metrics must be reachable via joins

**Example of valid join graph:**
```
customers ←→ orders ←→ products
     ↓
subscriptions
```

**Example of invalid join graph (circular):**
```
customers → orders → products → customers  # Circular!
```

**Validation:**
- System checks for cycles during semantic layer load
- Errors indicate which models form a cycle
- Fix by removing or restructuring joins

### 7.6 `description` (Optional)

**Purpose:** Human-readable description of the join

**Format:**
- String (single or multi-line)

**Examples:**
```yaml
joins:
  orders:
    type: one_to_many
    expression: "customers.customer_id = orders.customer_id"
    description: "Customer's orders relationship"
```

### 7.7 `meta` (Optional)

**Purpose:** Free-form metadata dictionary

**Format:**
- Dictionary (key-value pairs)

**Examples:**
```yaml
joins:
  orders:
    type: one_to_many
    expression: "customers.customer_id = orders.customer_id"
    meta:
      join_type: "INNER"
      performance_note: "Indexed on customer_id"
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 8. Business Metrics

### 8.1 Metric Structure

Metrics combine measures, time dimensions, and grouping dimensions:

```yaml
metrics:
  <metric_name>:                 # REQUIRED: Dictionary key
    measure: <model>.<measure>   # REQUIRED
    time: <model>.<column>       # REQUIRED
    dimensions: [...]            # Optional: Array of dimension references
    description: "..."           # Optional
    tags: [...]                  # Optional: Array of strings
    meta: {...}                  # Optional: Dictionary
```

### 8.2 Metric Name (Required)

**Purpose:** Unique identifier for the metric

**Format:**
- Dictionary key (not a field)
- Must follow identifier rules (see [Naming Rules](#9-naming-and-validation-rules))
- Letters, digits, underscores only
- Starts with letter
- Max 64 characters
- Must be unique across all semantic files

**Examples:**
```yaml
metrics:
  monthly_revenue: ...
  customer_growth: ...
  daily_active_users: ...
  conversion_rate_by_channel: ...
```

**Validation:**
- Must be unique across all files
- Cannot conflict with other metric names

### 8.3 `measure` (Required)

**Purpose:** Reference to a measure to aggregate

**Format:**
- Must be in `model.measure` format (exactly one dot)
- Model must be semantic alias (not physical name)
- Measure must exist on target model

**Examples:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
  
  customer_growth:
    measure: customers.total_customers
    time: customers.signup_date
```

**Validation:**
- Must use `model.measure` format
- Model alias must exist
- Measure must exist on target model
- Model must be reachable via joins (if multiple models in metric)

**Error examples:**
```yaml
# ❌ Missing model prefix
metrics:
  monthly_revenue:
    measure: total_revenue  # Should be 'orders.total_revenue'

# ❌ Measure doesn't exist
metrics:
  monthly_revenue:
    measure: orders.non_existent_measure
```

### 8.4 `time` (Required)

**Purpose:** Reference to a time column for time-series aggregation

**Format:**
- Must be in `model.column` format (exactly one dot)
- Model must be semantic alias (not physical name)
- Column must exist and be timestamp/datetime type

**Examples:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
  
  daily_signups:
    measure: customers.new_signups
    time: customers.signup_date
```

**Validation:**
- Must use `model.column` format
- Model alias must exist
- Column must exist on target model
- Column must be timestamp/datetime type (not DATE, TIME, or INTERVAL)
- Cannot be the same field as measure (if measure references same model)

**Error examples:**
```yaml
# ❌ Wrong column type
metrics:
  daily_revenue:
    measure: orders.total_revenue
    time: orders.status  # Not a timestamp column

# ❌ Column doesn't exist
metrics:
  daily_revenue:
    measure: orders.total_revenue
    time: orders.non_existent_date
```

### 8.5 `dimensions` (Optional)

**Purpose:** List of dimensions to group by

**Format:**
- Array of dimension references
- Each reference must be in `model.field` format
- Can reference columns, dimensions, or dimension proxies

**Examples:**
```yaml
metrics:
  monthly_revenue_by_tier:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.region
  
  daily_signups_by_channel:
    measure: customers.new_signups
    time: customers.signup_date
    dimensions:
      - customers.signup_channel
      - customers.customer_tier
```

**Cross-model dimensions:**
```yaml
metrics:
  revenue_by_product_category:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier    # From joined model
      - products.category           # From joined model
      - orders.status               # From measure's model
```

**Validation:**
- All references must use `model.field` format
- Referenced models must exist
- Referenced fields must exist (columns, dimensions, or proxies)
- All models must be connected via joins (if multiple models)
- No duplicate dimensions in list

**Error examples:**
```yaml
# ❌ Duplicate dimension
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.customer_tier  # Duplicate!

# ❌ Models not connected
metrics:
  revenue_by_product:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - products.category  # No join path from orders to products
```

### 8.6 `description` (Optional)

**Purpose:** Human-readable description of the metric

**Format:**
- String (single or multi-line)

**Examples:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
    description: "Monthly revenue trends by customer tier"
```

### 8.7 `tags` (Optional)

**Purpose:** Categorize metrics for discovery

**Format:**
- Array of strings

**Examples:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    tags:
      - revenue
      - financial
      - kpi
      - time_series
```

### 8.8 `meta` (Optional)

**Purpose:** Free-form metadata dictionary

**Format:**
- Dictionary (key-value pairs)

**Examples:**
```yaml
metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    meta:
      business_owner: "Finance Team"
      certified: true
      kpi_target: 1000000
      update_frequency: "daily"
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 9. Naming and Validation Rules

### 9.1 Identifier Format Rules

The following semantic identifiers must follow the same naming rules:

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
- After the first character, may contain only:
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

# ❌ Invalid names
- name: "total-revenue"      # Hyphens not allowed
- name: "123revenue"         # Cannot start with digit
- name: "total revenue"      # Spaces not allowed
- name: "total.revenue"      # Dots not allowed (except in references)
```

### 9.2 Uniqueness Rules

**Within a semantic model:**
- Measure names must be unique
- Segment names must be unique
- Dimension proxy names must be unique
- Dimension override names must be unique
- **No semantic field name** should be reused across measures, segments, and dimension proxies

**Across semantic files:**
- Metric names must be unique across all files
- Model aliases must be unique across all files

**Error examples:**
```yaml
# ❌ Duplicate measure name
measures:
  total_revenue:
    type: sum
  total_revenue:  # Duplicate! (same key twice)
    type: sum

# ❌ Measure and segment with same name
measures:
  active_users:
    type: count
segments:
  active_users:  # Conflicts with measure name
    expression: "..."

# ❌ Duplicate metric name across files
# In file1.yml:
metrics:
  monthly_revenue: ...

# In file2.yml:
metrics:
  monthly_revenue: ...  # Duplicate!
```

### 9.3 Reference Format Rules

**Model references:**
- Always use semantic alias (not physical name)
- Format: `model_alias.field_name`
- Exactly one dot required

**Examples:**
```yaml
# ✅ Correct references
measure: orders.total_revenue
time: orders.order_date
dimensions:
  - customers.customer_tier

# ❌ Incorrect references
measure: analytics.orders.total_revenue  # Too many dots
measure: total_revenue                   # Missing model prefix
time: analytics.orders.order_date        # Using physical name
```

### 9.4 Column Existence Rules

**Columns referenced in:**
- `dimensions.includes` - Must exist in physical model
- `dimensions.excludes` - Must exist in physical model
- `dimensions.overrides[].name` - Must exist (after includes/excludes)
- `segments[].expression` - Must exist in current model
- `joins[].expression` - Must exist in source/target models
- `metrics[].time` - Must exist and be timestamp/datetime type

**Validation:**
- All column references are validated against physical models
- Errors indicate which column is missing
- Case-sensitive matching

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 10. YAML Formatting Best Practices

### 10.1 Multi-line Expressions

**Use `|` for multi-line SQL:**

```yaml
# ✅ Good: Multi-line expression
expression: |
  SUM(CASE 
    WHEN status = 'active' 
    THEN amount 
    ELSE 0 
  END)

# ✅ Good: Single-line expression
expression: "SUM(amount)"

# ❌ Bad: Inconsistent formatting
expression: "SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END)"
```

### 10.2 Arrays

**One per line (preferred for readability):**

```yaml
# ✅ Good: One per line
tags:
  - revenue
  - financial
  - kpi

# ✅ Also OK: Inline for short lists
tags: [revenue, financial, kpi]

# ❌ Bad: Inconsistent
tags: [revenue,
  financial, kpi]
```

### 10.3 Indentation

**Use 2 spaces per level:**

```yaml
models:
  analytics.customers:
    alias: customers
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
        filters:
          - "status = 'active'"
```

**Common indentation errors:**
```yaml
# ❌ Bad: Tabs instead of spaces
models:
	customers:  # Tab character
	  alias: customers

# ❌ Bad: Inconsistent spacing
models:
  analytics.customers:
     alias: users  # 3 spaces instead of 2
```

### 10.4 String Quoting

**When to quote:**
- Strings with special characters: `"status = 'active'"`
- Strings starting with numbers: `"30_day_count"`
- Strings with colons: `"format: currency"`

**When not to quote:**
- Simple identifiers: `name: total_revenue`
- Simple values: `format: currency`

**Examples:**
```yaml
# ✅ Good: Quote filter expressions
filters:
  - "status = 'active'"
  - "signup_date >= CURRENT_DATE - INTERVAL '30 days'"

# ✅ Good: No quotes for simple names
name: total_revenue
format: currency

# ❌ Bad: Missing quotes for expressions with special chars
filters:
  - status = 'active'  # Should be quoted
```

### 10.5 Comments

**Use `#` for comments:**

```yaml
models:
  analytics.customers:
    alias: customers
    
    # Hide sensitive columns
    dimensions:
      excludes:
        - password_hash
        - ssn
    
    # Core revenue metrics
    measures:
      total_revenue:
        type: sum
        expression: "SUM(amount)"
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 11. Quick Reference

### 11.1 Component Quick Reference

| Component | Required Fields | Optional Fields |
|-----------|----------------|-----------------|
| **Model** | `name` | `alias` (req for FQN), `description`, `dimensions`, `measures`, `segments`, `joins` |
| **Dimension Selection** | One of: `includes` OR `excludes` | `overrides`, `proxies` |
| **Dimension Override** | `name` | `tags`, `meta` |
| **Dimension Proxy** | `name`, `measure` | - |
| **Measure** | `name`, `expression` | `description`, `filters`, `format`, `tags`, `meta` |
| **Segment** | `name`, `expression` | `description`, `tags`, `meta` |
| **Join** | `name`, `relationship`, `expression` | `description`, `meta` |
| **Metric** | `measure`, `time` | `dimensions`, `description`, `tags`, `meta` |

### 11.2 Reference Format Quick Reference

| Context | Format | Example |
|---------|--------|---------|
| **Measure reference** | `model.measure` | `orders.total_revenue` |
| **Time reference** | `model.column` | `orders.order_date` |
| **Dimension reference** | `model.field` | `customers.customer_tier` |
| **Dimension proxy in segment** | `{proxy_name}` | `{order_count_dim}` |
| **Join expression** | `model.column` | `customers.customer_id = orders.customer_id` |

### 11.3 Relationship Types Quick Reference

| Type | Description | Example |
|------|-------------|---------|
| `one_to_one` | One row matches one row | User ↔ Profile |
| `one_to_many` | One row matches many rows | Customer → Orders |
| `many_to_one` | Many rows match one row | Orders → Customer |

### 11.4 Format Types Quick Reference

| Format | Description | Example |
|--------|-------------|---------|
| `currency` | Monetary values | $1,234.56 |
| `percentage` | Percentages | 12.5% |
| `number` | Numeric values | 1,234.56 |
| `duration_ms` | Time duration | 1,500 ms |
| `bytes` | Byte sizes | 1.5 MB |

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## 12. Complete Examples

### 12.1 Minimal Example

```yaml
models:
  analytics.customers:
    alias: customers
```

**Result:**
- All columns from `analytics.customers` model are available as dimensions
- No measures, segments, or joins defined

### 12.2 Complete Example

```yaml
models:
  analytics.dim_customers:
    alias: customers
    description: "Customer dimension table"
    
    dimensions:
      excludes:
        - password_hash
        - internal_notes
      
      overrides:
        customer_tier:
          tags: [segmentation, revenue]
          meta:
            business_owner: "Product Team"
            sort_order: ["Free", "Pro", "Enterprise"]
      
      proxies:
        order_count_dim:
          measure: orders.total_orders
    
    measures:
      total_customers:
        type: count
        expression: "COUNT(*)"
        description: "Total number of customers"
        tags: [count, core_metric]
      
      active_customers:
        type: count
        expression: "COUNT(*)"
        filters:
          - "status = 'active'"
        description: "Customers with active status"
        tags: [count, active]
    
    segments:
      high_value:
        expression: "total_spent > 10000"
        description: "Customers with >$10K lifetime spend"
        tags: [segmentation, revenue]
      
      has_orders:
        expression: "{order_count_dim} > 0"
        description: "Customers with at least one order"
        tags: [behavior]
    
    joins:
      orders:
        type: one_to_many
        expression: "customers.customer_id = orders.customer_id"
        description: "Customer's orders"
  
  analytics.fact_orders:
    alias: orders
    
    measures:
      total_revenue:
        type: sum
        expression: "SUM(amount)"
        format: currency
        description: "Total order revenue"
        tags: [revenue, financial, kpi]
      
      completed_revenue:
        type: sum
        expression: "SUM(amount)"
        filters:
          - "status = 'completed'"
        format: currency
        description: "Revenue from completed orders"
        tags: [revenue, completed]
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"

metrics:
  monthly_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - customers.region
    description: "Monthly revenue by tier and region"
    tags: [revenue, financial, time_series]
    meta:
      business_owner: "Finance Team"
      certified: true
  
  customer_growth:
    measure: customers.total_customers
    time: customers.signup_date
    dimensions:
      - customers.signup_channel
      - customers.customer_tier
    description: "Customer acquisition trends"
    tags: [growth, acquisition]
```

### 12.3 Cross-Model Example

```yaml
models:
  analytics.orders:
    alias: orders
    
    measures:
      total_revenue:
        type: sum
        expression: "SUM(amount)"
        filters:
          - "customers.country = 'US'"  # Cross-model filter
          - "products.category = 'Electronics'"  # Cross-model filter
    
    joins:
      customers:
        type: many_to_one
        expression: "orders.customer_id = customers.customer_id"
      
      products:
        type: many_to_many
        expression: "orders.order_id = order_items.order_id AND order_items.product_id = products.product_id"

metrics:
  us_electronics_revenue:
    measure: orders.total_revenue
    time: orders.order_date
    dimensions:
      - customers.customer_tier
      - products.brand
    description: "US electronics revenue by tier and brand"
```

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

---

## Summary

This reference covers every field, option, and pattern in semantic layer YAML files. Use it as your definitive guide when:

- Writing semantic layer definitions
- Debugging validation errors
- Understanding field requirements
- Finding syntax examples

**Key takeaways:**
- All model references use semantic aliases (not physical names)
- Reference format is always `model.field` (exactly one dot)
- Dimensions default to all columns (use excludes/includes to control)
- Segments can only reference current model columns
- Measures can reference joined models via `model.field` syntax
- Metrics combine measures, time, and dimensions across models

**Next steps:**
- [Chapter 3B: Advanced Measures](03b-semantic-measures.md) - Complex measure patterns
- [Chapter 3C: Advanced Joins](03c-semantic-joins.md) - Cross-model analysis patterns
- [Chapter 3D: Validation](03d-semantic-validation.md) - Complete validation rules

[↑ Back to Top](#chapter-3a-semantic-yaml-reference)

