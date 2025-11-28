# Chapter 2B: Model Testing

> **Comprehensive guide to unit testing Vulcan models** - Validate model logic with predefined inputs and expected outputs, catch regressions before deployment, and ensure data quality.

---

## Prerequisites

Before diving into this chapter, you should have:

### Required Knowledge

**Chapter 2: Models** - Understanding of:
- Basic MODEL DDL syntax
- Model query structure
- Model dependencies

**YAML Syntax**
- Basic YAML structure (dictionaries, lists)
- Key-value pairs
- Multi-line strings

**SQL Proficiency**
- SELECT statements
- CTEs (Common Table Expressions)
- Basic aggregations

### Optional but Helpful

**Software Testing Concepts**
- Unit testing basics
- Test-driven development (TDD)
- Test fixtures

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Test Structure](#2-test-structure)
3. [Input Data Formats](#3-input-data-formats)
4. [Output Validation](#4-output-validation)
5. [Testing Patterns](#5-testing-patterns)
6. [Testing Incremental Models](#6-testing-incremental-models)
7. [Testing Python Models](#7-testing-python-models)
8. [Automatic Test Generation](#8-automatic-test-generation)
9. [Running Tests](#9-running-tests)
10. [Advanced Patterns](#10-advanced-patterns)
11. [Troubleshooting](#11-troubleshooting)
12. [Best Practices](#12-best-practices)
13. [Quick Reference](#13-quick-reference)

---

## 1. Introduction

### 1.1 What Are Unit Tests?

**Unit tests validate model logic** by comparing actual outputs against expected outputs for given inputs.

**Key characteristics:**
- **Predefined inputs** - You specify test data
- **Expected outputs** - You define what should happen
- **Automatic validation** - Vulcan compares actual vs expected
- **Fast execution** - Run in-memory (DuckDB by default)
- **Isolated** - Don't require production data

### 1.2 Tests vs Audits vs Checks

Understanding the three validation mechanisms:

| Feature | **Tests** | **Audits** | **Checks** |
|---------|-----------|------------|------------|
| **Purpose** | Validate logic | Block bad data | Monitor trends |
| **When runs** | Before deployment | After execution | Scheduled separately |
| **Configuration** | YAML files (`tests/`) | MODEL assertions | YAML files (`checks/`) |
| **Input** | Predefined fixtures | Model output | Model output |
| **Output** | Pass/fail | Pass/fail (blocks) | Pass/fail + history |
| **Best for** | Logic validation | Data quality gates | Trend monitoring |

**Use tests for:** Logic validation before deployment  
**Use audits for:** Blocking invalid data (see [Chapter 4](../audits/index.md))  
**Use checks for:** Monitoring over time (see [Chapter 5](../data-quality/index.md))

### 1.3 Why Write Tests?

**Benefits:**

1. **Catch Regressions Early**
   - Detect logic errors before deployment
   - Prevent bad data from reaching production
   - Faster feedback than manual testing

2. **Document Expected Behavior**
   - Tests serve as executable documentation
   - Show how models should behave
   - Examples for other developers

3. **Enable Refactoring**
   - Refactor with confidence
   - Tests verify behavior unchanged
   - Safe to optimize queries

4. **CI/CD Integration**
   - Run tests automatically in CI/CD
   - Block deployments on test failures
   - Ensure quality gates

**Example:**

```sql
-- Model: analytics.daily_revenue
SELECT
  customer_id,
  order_date,
  SUM(amount) as revenue
FROM staging.orders
WHERE status = 'completed'
GROUP BY customer_id, order_date;
```

**Without tests:**
- Deploy → Discover bug → Fix → Redeploy
- Risk: Bad data in production

**With tests:**
- Write test → Test fails → Fix → Test passes → Deploy
- Result: Correct logic, no bad data

### 1.4 When to Write Tests

✅ **Write tests for:**
- Critical business logic (revenue, customer metrics)
- Complex transformations (joins, aggregations)
- Edge cases (NULL handling, empty inputs)
- Models feeding downstream systems
- Models with complex calculations

❌ **Skip tests for:**
- Simple pass-through models (SELECT * FROM ...)
- Models that are just filters (WHERE ...)
- Very simple aggregations (COUNT, SUM)
- Experimental models (test manually first)

**Test Coverage Strategy:**

- **Critical models:** 100% test coverage
- **Important models:** Test main logic paths
- **Simple models:** Test edge cases only
- **Experimental models:** Test after stabilization

[↑ Back to Top](#chapter-2b-model-testing)

---

## 2. Test Structure

### 2.1 Test File Organization

Tests are YAML files in the `tests/` directory:

```
project/
├── models/
│   ├── analytics/
│   │   └── customers.sql
│   └── staging/
│       └── orders.sql
├── tests/
│   ├── test_customers.yaml      # Tests for customers model
│   ├── test_orders.yaml         # Tests for orders model
│   └── test_integration.yaml    # Integration tests
└── config.yaml
```

**File Naming:**
- Must start with `test`
- Must end with `.yaml` or `.yml`
- Name doesn't matter (Vulcan reads all files)
- Convention: `test_<model_name>.yaml`

### 2.2 Basic Test Structure

**Minimal test:**

```yaml
test_name:
  model: schema.table_name
  inputs:
    upstream_model:
      rows:
        - column1: value1
          column2: value2
  outputs:
    query:
      rows:
        - column1: expected_value1
          column2: expected_value2
```

**Complete test structure:**

```yaml
test_name:
  model: schema.table_name          # Required: Model to test
  gateway: gateway_name             # Optional: Testing gateway
  inputs:                           # Required: Input data
    upstream_model1:
      rows:
        - col1: val1
          col2: val2
    upstream_model2:
      query: SELECT ...
  outputs:                          # Required: Expected outputs
    query:                          # Query output
      rows:
        - col1: expected_val1
    ctes:                           # Optional: CTE outputs
      cte_name:
        rows:
          - col1: expected_val1
  vars:                             # Optional: Macro variables
    execution_time: '2024-01-01 12:00:00'
    start: '2024-01-01'
  description: 'Test description'   # Optional: Documentation
  schema: custom_schema_name        # Optional: Custom schema
```

### 2.3 Test Components

**1. Test Name**

```yaml
test_customer_revenue:  # Unique test name
  model: ...
```

**Naming conventions:**
- `test_<model_name>` - Basic test
- `test_<model_name>_<scenario>` - Specific scenario
- `test_<model_name>_edge_case` - Edge case test

**Examples:**
```yaml
test_customers:                    # Basic test
test_customers_empty_input:       # Edge case
test_customers_null_handling:     # Specific scenario
test_customers_multiple_orders:   # Multiple orders scenario
```

**2. Model Reference**

```yaml
test_name:
  model: analytics.customers  # Fully qualified model name
```

**3. Inputs**

Define data for upstream models:

```yaml
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: 100
        amount: 50.00
```

**4. Outputs**

Define expected results:

```yaml
outputs:
  query:
    rows:
      - customer_id: 100
        total_revenue: 50.00
```

**5. Variables**

Set macro variables:

```yaml
vars:
  execution_time: '2024-01-01 12:00:00'
  start: '2024-01-01'
  end: '2024-01-02'
```

### 2.4 Multiple Tests in One File

You can define multiple tests in a single YAML file:

```yaml
# tests/test_customers.yaml

test_customers_basic:
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 50.00

test_customers_empty_input:
  model: analytics.customers
  inputs:
    staging.orders:
      rows: []  # Empty input
  outputs:
    query:
      rows: []  # Empty output expected

test_customers_multiple_orders:
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
        - order_id: 2
          customer_id: 100
          amount: 75.00
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
```

**Organization:**

- **One file per model:** `test_customers.yaml` contains all customer tests
- **One file per domain:** `test_revenue.yaml` contains all revenue-related tests
- **One file per scenario:** `test_edge_cases.yaml` contains edge case tests

**Recommendation:** Start with one file per model, split when files get large (>500 lines).

[↑ Back to Top](#chapter-2b-model-testing)

---


## 3. Input Data Formats

Vulcan supports three ways to define input data for tests.

### 3.1 YAML Dictionaries (Default)

**Format:** List of dictionaries where each dictionary is a row.

**Syntax:**
```yaml
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: 100
        amount: 50.00
        order_date: '2024-01-01'
      - order_id: 2
        customer_id: 100
        amount: 75.00
        order_date: '2024-01-02'
```

**Example:**

```yaml
test_customer_revenue:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          status: 'completed'
        - order_id: 3
          customer_id: 200
          amount: 100.00
          status: 'completed'
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
        - customer_id: 200
          total_revenue: 100.00
```

**Data Types:**

Vulcan infers types from model definitions. Common types:

| YAML Value | SQL Type | Example |
|------------|----------|---------|
| `123` | INT | `order_id: 123` |
| `123.45` | DECIMAL/FLOAT | `amount: 123.45` |
| `'text'` | VARCHAR/TEXT | `status: 'completed'` |
| `'2024-01-01'` | DATE | `order_date: '2024-01-01'` |
| `'2024-01-01 12:00:00'` | TIMESTAMP | `created_at: '2024-01-01 12:00:00'` |
| `true` / `false` | BOOLEAN | `is_active: true` |
| `null` | NULL | `deleted_at: null` |

**Omitting Columns:**

Missing columns are treated as `NULL`:

```yaml
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: 100
        amount: 50.00
        # status omitted → NULL
        # order_date omitted → NULL
```

### 3.2 CSV Format

**Format:** Comma-separated values with header row.

**Syntax:**
```yaml
inputs:
  staging.orders:
    format: csv
    rows: |
      order_id,customer_id,amount,order_date
      1,100,50.00,2024-01-01
      2,100,75.00,2024-01-02
      3,200,100.00,2024-01-03
```

**Example:**

```yaml
test_customer_revenue:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      format: csv
      rows: |
        order_id,customer_id,amount,status,order_date
        1,100,50.00,completed,2024-01-01
        2,100,75.00,completed,2024-01-02
        3,200,100.00,completed,2024-01-03
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
        - customer_id: 200
          total_revenue: 100.00
```

**When to Use CSV:**

✅ **Good for:**
- Large datasets (easier to read)
- Copy-paste from spreadsheets
- Data with many columns
- Reusing test data across tests

❌ **Avoid for:**
- Small datasets (YAML is clearer)
- Complex nested data
- Data requiring type precision

**Multi-line CSV:**

```yaml
inputs:
  staging.orders:
    format: csv
    rows: |
      order_id,customer_id,amount,order_date
      1,100,50.00,2024-01-01
      2,100,75.00,2024-01-02
      3,200,100.00,2024-01-03
      4,200,25.00,2024-01-04
      5,300,150.00,2024-01-05
```

### 3.3 SQL Query Format

**Format:** SQL query that generates input data.

**Syntax:**
```yaml
inputs:
  staging.orders:
    query: |
      SELECT 1 AS order_id, 100 AS customer_id, 50.00 AS amount, '2024-01-01'::DATE AS order_date
      UNION ALL
      SELECT 2, 100, 75.00, '2024-01-02'::DATE
      UNION ALL
      SELECT 3, 200, 100.00, '2024-01-03'::DATE
```

**Example:**

```yaml
test_customer_revenue:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      query: |
        SELECT 
          1 AS order_id,
          100 AS customer_id,
          50.00 AS amount,
          'completed' AS status,
          '2024-01-01'::DATE AS order_date
        UNION ALL
        SELECT 2, 100, 75.00, 'completed', '2024-01-02'::DATE
        UNION ALL
        SELECT 3, 200, 100.00, 'completed', '2024-01-03'::DATE
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
        - customer_id: 200
          total_revenue: 100.00
```

**When to Use SQL:**

✅ **Good for:**
- Complex data generation
- Dynamic test data
- Reusing existing queries
- Testing with realistic data distributions

❌ **Avoid for:**
- Simple test data (YAML is clearer)
- Tests that need to be portable
- Data that changes frequently

**Using VALUES:**

```yaml
inputs:
  staging.orders:
    query: |
      SELECT * FROM (VALUES
        (1, 100, 50.00, 'completed', '2024-01-01'::DATE),
        (2, 100, 75.00, 'completed', '2024-01-02'::DATE),
        (3, 200, 100.00, 'completed', '2024-01-03'::DATE)
      ) AS t(order_id, customer_id, amount, status, order_date)
```

### 3.4 External Files

**Format:** Load data from external CSV or YAML files.

**Syntax:**
```yaml
inputs:
  staging.orders:
    format: csv
    path: fixtures/orders_test_data.csv
```

**File Structure:**

```
project/
├── models/
├── tests/
│   └── test_customers.yaml
└── fixtures/
    ├── orders_test_data.csv
    └── customers_test_data.yaml
```

**CSV File:**

```csv
order_id,customer_id,amount,status,order_date
1,100,50.00,completed,2024-01-01
2,100,75.00,completed,2024-01-02
3,200,100.00,completed,2024-01-03
```

**YAML File:**

```yaml
# fixtures/orders_test_data.yaml
- order_id: 1
  customer_id: 100
  amount: 50.00
  status: completed
  order_date: '2024-01-01'
- order_id: 2
  customer_id: 100
  amount: 75.00
  status: completed
  order_date: '2024-01-02'
```

**Test Reference:**

```yaml
test_customer_revenue:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      format: csv
      path: fixtures/orders_test_data.csv
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
        - customer_id: 200
          total_revenue: 100.00
```

**When to Use External Files:**

✅ **Good for:**
- Large test datasets
- Reusing data across multiple tests
- Data maintained separately
- Real-world sample data

❌ **Avoid for:**
- Small, simple test data
- Tests that should be self-contained
- Data that changes frequently

### 3.5 Multiple Input Models

Tests can specify inputs for multiple upstream models:

```yaml
test_customer_summary:
  model: analytics.customer_summary
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
        - order_id: 2
          customer_id: 100
          amount: 75.00
    staging.customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
          signup_date: '2023-01-01'
  outputs:
    query:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
          total_revenue: 125.00
          order_count: 2
```

**Input Order:**

Input models are processed in the order they appear. Dependencies are automatically resolved.

[↑ Back to Top](#chapter-2b-model-testing)

---

## 4. Output Validation

### 4.1 Query Output Validation

**Basic syntax:**

```yaml
outputs:
  query:
    rows:
      - column1: expected_value1
        column2: expected_value2
```

**Example:**

```yaml
test_customer_revenue:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
        - order_id: 2
          customer_id: 100
          amount: 75.00
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
          order_count: 2
```

**Row Order:**

By default, row order **does not matter**. Vulcan compares sets, not sequences.

**To enforce order:**

```yaml
outputs:
  query:
    sort_by: customer_id  # Sort before comparison
    rows:
      - customer_id: 100
        total_revenue: 125.00
      - customer_id: 200
        total_revenue: 100.00
```

### 4.2 CTE Output Validation

Test individual CTEs within the model query:

**Model:**

```sql
MODEL (
  name analytics.customer_metrics,
  kind FULL
);

WITH filtered_orders AS (
  SELECT *
  FROM staging.orders
  WHERE status = 'completed'
),
customer_totals AS (
  SELECT
    customer_id,
    SUM(amount) as total_revenue,
    COUNT(*) as order_count
  FROM filtered_orders
  GROUP BY customer_id
)
SELECT * FROM customer_totals;
```

**Test:**

```yaml
test_customer_metrics:
  model: analytics.customer_metrics
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          status: 'pending'  # Filtered out
        - order_id: 3
          customer_id: 200
          amount: 100.00
          status: 'completed'
  outputs:
    ctes:
      filtered_orders:
        rows:
          - order_id: 1
            customer_id: 100
            amount: 50.00
            status: 'completed'
          - order_id: 3
            customer_id: 200
            amount: 100.00
            status: 'completed'
      customer_totals:
        rows:
          - customer_id: 100
            total_revenue: 50.00
            order_count: 1
          - customer_id: 200
            total_revenue: 100.00
            order_count: 1
    query:
      rows:
        - customer_id: 100
          total_revenue: 50.00
          order_count: 1
        - customer_id: 200
          total_revenue: 100.00
          order_count: 1
```

**When to Test CTEs:**

✅ **Test CTEs when:**
- CTE logic is complex
- Debugging specific CTE issues
- Validating intermediate transformations
- Documenting CTE behavior

❌ **Skip CTE testing when:**
- CTEs are simple (just filters)
- Testing final output is sufficient
- CTEs are implementation details

### 4.3 Partial Validation

Test only a subset of output columns:

**Syntax:**

```yaml
outputs:
  query:
    partial: true  # Only validate specified columns
    rows:
      - customer_id: 100
        total_revenue: 125.00
        # Other columns ignored
```

**Example:**

```yaml
test_customer_revenue_partial:
  model: analytics.customer_summary
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
  outputs:
    query:
      partial: true  # Only validate revenue, ignore other columns
      rows:
        - customer_id: 100
          total_revenue: 125.00
          # order_count, avg_order_value, etc. ignored
```

**When to Use Partial Validation:**

✅ **Good for:**
- Wide tables (many columns)
- Testing specific calculations
- Ignoring non-deterministic columns (timestamps)
- Focusing on critical columns

❌ **Avoid for:**
- Narrow tables (few columns)
- Need to validate all columns
- Critical data quality checks

**Apply to All Outputs:**

```yaml
outputs:
  partial: true  # Applies to all outputs (query and CTEs)
  query:
    rows:
      - customer_id: 100
        total_revenue: 125.00
  ctes:
    filtered_orders:
      rows:
        - order_id: 1
          customer_id: 100
```

### 4.4 Omitting Columns

**Missing columns in expected output:**

If a column is missing from expected output, Vulcan **ignores it** (doesn't validate):

```yaml
outputs:
  query:
    rows:
      - customer_id: 100
        total_revenue: 125.00
        # order_count omitted → not validated
```

**Missing columns in actual output:**

If actual output has extra columns, test **fails** (unless `partial: true`):

```yaml
# Model returns: customer_id, total_revenue, order_count
# Test expects: customer_id, total_revenue
# Result: FAIL (unless partial: true)
```

**Best Practice:**

Include all columns you care about in expected output:

```yaml
outputs:
  query:
    rows:
      - customer_id: 100
        total_revenue: 125.00
        order_count: 2  # Explicitly validate
```

### 4.5 Type Validation

Vulcan validates both **values** and **types**:

**Type Mismatch Example:**

```yaml
# Model returns: total_revenue DECIMAL(10,2) = 125.00
# Test expects: total_revenue: 125 (INT)
# Result: FAIL (type mismatch)
```

**Correct:**

```yaml
outputs:
  query:
    rows:
      - customer_id: 100
        total_revenue: 125.00  # DECIMAL, matches model
```

**Type Inference:**

Vulcan infers types from:
1. Model `columns` property (if specified)
2. Model query output (if not specified)
3. External model definitions (for external models)

**Explicit Type Specification:**

If types are ambiguous, specify in model:

```sql
MODEL (
  name analytics.customer_revenue,
  columns (
    customer_id INT,
    total_revenue DECIMAL(10,2),
    order_count INT
  )
);
```

[↑ Back to Top](#chapter-2b-model-testing)

---


## 5. Testing Patterns

### 5.1 Basic Aggregation Test

**Model:**

```sql
MODEL (
  name analytics.customer_revenue,
  kind FULL
);

SELECT
  customer_id,
  SUM(amount) as total_revenue,
  COUNT(*) as order_count
FROM staging.orders
WHERE status = 'completed'
GROUP BY customer_id;
```

**Test:**

```yaml
test_customer_revenue_basic:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          status: 'completed'
        - order_id: 3
          customer_id: 200
          amount: 100.00
          status: 'completed'
        - order_id: 4
          customer_id: 100
          amount: 25.00
          status: 'pending'  # Filtered out
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
          order_count: 2
        - customer_id: 200
          total_revenue: 100.00
          order_count: 1
```

### 5.2 Join Test

**Model:**

```sql
MODEL (
  name analytics.customer_summary,
  kind FULL
);

SELECT
  c.customer_id,
  c.customer_name,
  COALESCE(SUM(o.amount), 0) as total_revenue,
  COUNT(o.order_id) as order_count
FROM staging.customers c
LEFT JOIN staging.orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed' OR o.status IS NULL
GROUP BY c.customer_id, c.customer_name;
```

**Test:**

```yaml
test_customer_summary_join:
  model: analytics.customer_summary
  inputs:
    staging.customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
        - customer_id: 200
          customer_name: 'Bob'
        - customer_id: 300
          customer_name: 'Charlie'  # No orders
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          status: 'completed'
        - order_id: 3
          customer_id: 200
          amount: 100.00
          status: 'completed'
  outputs:
    query:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
          total_revenue: 125.00
          order_count: 2
        - customer_id: 200
          customer_name: 'Bob'
          total_revenue: 100.00
          order_count: 1
        - customer_id: 300
          customer_name: 'Charlie'
          total_revenue: 0.00
          order_count: 0
```

### 5.3 NULL Handling Test

**Model:**

```sql
MODEL (
  name analytics.customer_metrics,
  kind FULL
);

SELECT
  customer_id,
  COUNT(*) as total_orders,
  COUNT(email) as orders_with_email,  -- NULLs excluded
  SUM(COALESCE(amount, 0)) as total_revenue
FROM staging.orders
GROUP BY customer_id;
```

**Test:**

```yaml
test_null_handling:
  model: analytics.customer_metrics
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          email: 'alice@example.com'
        - order_id: 2
          customer_id: 100
          amount: null  # NULL amount
          email: 'alice@example.com'
        - order_id: 3
          customer_id: 100
          amount: 75.00
          email: null  # NULL email
  outputs:
    query:
      rows:
        - customer_id: 100
          total_orders: 3
          orders_with_email: 2  # NULL email excluded
          total_revenue: 125.00  # NULL amount treated as 0
```

### 5.4 Edge Case Tests

**Empty Input:**

```yaml
test_empty_input:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows: []  # Empty input
  outputs:
    query:
      rows: []  # Empty output expected
```

**Single Row:**

```yaml
test_single_row:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 50.00
          order_count: 1
```

**All NULLs:**

```yaml
test_all_nulls:
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: null
          amount: null
          status: null
  outputs:
    query:
      rows:
        - customer_id: null
          total_revenue: null  # Or 0, depending on logic
          order_count: 1
```

### 5.5 Complex Calculation Test

**Model:**

```sql
MODEL (
  name analytics.order_metrics,
  kind FULL
);

SELECT
  order_id,
  amount,
  discount_amount,
  tax_amount,
  (amount - discount_amount + tax_amount) as total_amount,
  CASE
    WHEN amount > 100 THEN 'high_value'
    WHEN amount > 50 THEN 'medium_value'
    ELSE 'low_value'
  END as order_tier
FROM staging.orders;
```

**Test:**

```yaml
test_order_metrics_calculation:
  model: analytics.order_metrics
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          amount: 100.00
          discount_amount: 10.00
          tax_amount: 9.00
        - order_id: 2
          amount: 75.00
          discount_amount: 5.00
          tax_amount: 7.00
        - order_id: 3
          amount: 25.00
          discount_amount: 0.00
          tax_amount: 2.50
  outputs:
    query:
      rows:
        - order_id: 1
          amount: 100.00
          discount_amount: 10.00
          tax_amount: 9.00
          total_amount: 99.00  # 100 - 10 + 9
          order_tier: 'high_value'
        - order_id: 2
          amount: 75.00
          discount_amount: 5.00
          tax_amount: 7.00
          total_amount: 77.00  # 75 - 5 + 7
          order_tier: 'medium_value'
        - order_id: 3
          amount: 25.00
          discount_amount: 0.00
          tax_amount: 2.50
          total_amount: 27.50  # 25 - 0 + 2.50
          order_tier: 'low_value'
```

### 5.6 Window Function Test

**Model:**

```sql
MODEL (
  name analytics.customer_order_rank,
  kind FULL
);

SELECT
  customer_id,
  order_id,
  amount,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY amount DESC) as order_rank
FROM staging.orders;
```

**Test:**

```yaml
test_window_function:
  model: analytics.customer_order_rank
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
        - order_id: 2
          customer_id: 100
          amount: 100.00  # Highest for customer 100
        - order_id: 3
          customer_id: 100
          amount: 25.00
        - order_id: 4
          customer_id: 200
          amount: 75.00  # Only order for customer 200
  outputs:
    query:
      sort_by: customer_id, order_rank
      rows:
        - customer_id: 100
          order_id: 2
          amount: 100.00
          order_rank: 1
        - customer_id: 100
          order_id: 1
          amount: 50.00
          order_rank: 2
        - customer_id: 100
          order_id: 3
          amount: 25.00
          order_rank: 3
        - customer_id: 200
          order_id: 4
          amount: 75.00
          order_rank: 1
```

[↑ Back to Top](#chapter-2b-model-testing)

---

## 6. Testing Incremental Models

### 6.1 Testing with Time Variables

Incremental models use `@start_ds` and `@end_ds` macros. Set these in test `vars`:

**Model:**

```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date
  ),
  cron '@daily'
);

SELECT
  customer_id,
  order_date as revenue_date,
  SUM(amount) as revenue
FROM staging.orders
WHERE order_date BETWEEN @start_ds AND @end_ds
GROUP BY customer_id, order_date;
```

**Test:**

```yaml
test_daily_revenue_incremental:
  model: analytics.daily_revenue
  vars:
    start: '2024-01-01'  # @start_ds
    end: '2024-01-03'     # @end_ds
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          order_date: '2024-01-01'  # Within range
        - order_id: 2
          customer_id: 100
          amount: 75.00
          order_date: '2024-01-02'  # Within range
        - order_id: 3
          customer_id: 200
          amount: 100.00
          order_date: '2024-01-03'  # Within range
        - order_id: 4
          customer_id: 100
          amount: 25.00
          order_date: '2023-12-31'  # Outside range (filtered)
        - order_id: 5
          customer_id: 200
          amount: 50.00
          order_date: '2024-01-04'  # Outside range (filtered)
  outputs:
    query:
      rows:
        - customer_id: 100
          revenue_date: '2024-01-01'
          revenue: 50.00
        - customer_id: 100
          revenue_date: '2024-01-02'
          revenue: 75.00
        - customer_id: 200
          revenue_date: '2024-01-03'
          revenue: 100.00
```

### 6.2 Testing Lookback

Models with `lookback` reprocess previous intervals:

**Model:**

```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column revenue_date,
    lookback 2  -- Reprocess last 2 days
  ),
  cron '@daily'
);

SELECT
  customer_id,
  order_date as revenue_date,
  SUM(amount) as revenue
FROM staging.orders
WHERE order_date BETWEEN @start_ds AND @end_ds
GROUP BY customer_id, order_date;
```

**Test:**

```yaml
test_daily_revenue_lookback:
  model: analytics.daily_revenue
  vars:
    start: '2024-01-01'  # Processes: 2024-01-01, 2024-01-02, 2024-01-03
    end: '2024-01-03'     # (current day + 2 days lookback)
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          order_date: '2024-01-01'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          order_date: '2024-01-02'
        - order_id: 3
          customer_id: 200
          amount: 100.00
          order_date: '2024-01-03'
  outputs:
    query:
      rows:
        - customer_id: 100
          revenue_date: '2024-01-01'
          revenue: 50.00
        - customer_id: 100
          revenue_date: '2024-01-02'
          revenue: 75.00
        - customer_id: 200
          revenue_date: '2024-01-03'
          revenue: 100.00
```

### 6.3 Testing INCREMENTAL_BY_UNIQUE_KEY

**Model:**

```sql
MODEL (
  name analytics.customers,
  kind INCREMENTAL_BY_UNIQUE_KEY (
    unique_key customer_id
  ),
  cron '@daily'
);

SELECT
  customer_id,
  customer_name,
  email,
  updated_at
FROM staging.customers
WHERE updated_at >= @start_ds;
```

**Test:**

```yaml
test_customers_upsert:
  model: analytics.customers
  vars:
    start: '2024-01-01'
  inputs:
    staging.customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
          email: 'alice@example.com'
          updated_at: '2024-01-01'
        - customer_id: 200
          customer_name: 'Bob'
          email: 'bob@example.com'
          updated_at: '2024-01-01'
  outputs:
    query:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
          email: 'alice@example.com'
          updated_at: '2024-01-01'
        - customer_id: 200
          customer_name: 'Bob'
          email: 'bob@example.com'
          updated_at: '2024-01-01'
```

**Note:** Upsert logic (INSERT vs UPDATE) is tested by Vulcan's execution engine, not unit tests. Unit tests validate the query logic.

[↑ Back to Top](#chapter-2b-model-testing)

---

## 7. Testing Python Models

### 7.1 Basic Python Model Test

**Model:**

```python
from vulcan import ExecutionContext, model
import pandas as pd
from datetime import datetime
import typing as t

@model(
    "analytics.customer_predictions",
    columns={
        "customer_id": "INT",
        "churn_probability": "FLOAT",
        "prediction_date": "DATE"
    }
)
def execute(
    context: ExecutionContext,
    start: datetime,
    end: datetime,
    execution_time: datetime,
    **kwargs: t.Any,
) -> pd.DataFrame:
    customers = context.fetchdf("SELECT customer_id FROM analytics.customers")
    
    # Simple prediction logic
    customers['churn_probability'] = 0.1  # Placeholder
    customers['prediction_date'] = execution_time.date()
    
    return customers[['customer_id', 'churn_probability', 'prediction_date']]
```

**Test:**

```yaml
test_customer_predictions:
  model: analytics.customer_predictions
  vars:
    execution_time: '2024-01-01 12:00:00'
  inputs:
    analytics.customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
        - customer_id: 200
          customer_name: 'Bob'
  outputs:
    query:
      rows:
        - customer_id: 100
          churn_probability: 0.1
          prediction_date: '2024-01-01'
        - customer_id: 200
          churn_probability: 0.1
          prediction_date: '2024-01-01'
```

### 7.2 Python Model with Complex Logic

**Model:**

```python
@model(
    "analytics.customer_segments",
    columns={
        "customer_id": "INT",
        "segment": "VARCHAR(50)",
        "lifetime_value": "DECIMAL(10,2)"
    }
)
def execute(context, start, end, execution_time, **kwargs):
    customers = context.fetchdf("""
        SELECT 
            customer_id,
            total_revenue,
            order_count
        FROM analytics.customer_metrics
    """)
    
    # Segment logic
    customers['segment'] = customers.apply(
        lambda row: 'high_value' if row['total_revenue'] > 1000 
                   else 'medium_value' if row['total_revenue'] > 500 
                   else 'low_value',
        axis=1
    )
    
    customers['lifetime_value'] = customers['total_revenue'] * 2
    
    return customers[['customer_id', 'segment', 'lifetime_value']]
```

**Test:**

```yaml
test_customer_segments:
  model: analytics.customer_segments
  inputs:
    analytics.customer_metrics:
      rows:
        - customer_id: 100
          total_revenue: 1500.00
          order_count: 10
        - customer_id: 200
          total_revenue: 750.00
          order_count: 5
        - customer_id: 300
          total_revenue: 250.00
          order_count: 2
  outputs:
    query:
      rows:
        - customer_id: 100
          segment: 'high_value'
          lifetime_value: 3000.00
        - customer_id: 200
          segment: 'medium_value'
          lifetime_value: 1500.00
        - customer_id: 300
          segment: 'low_value'
          lifetime_value: 500.00
```

### 7.3 Python Model with Multiple Dependencies

**Model:**

```python
@model(
    "analytics.customer_analysis",
    columns={
        "customer_id": "INT",
        "revenue_score": "FLOAT",
        "engagement_score": "FLOAT",
        "combined_score": "FLOAT"
    }
)
def execute(context, start, end, execution_time, **kwargs):
    revenue = context.fetchdf("SELECT customer_id, total_revenue FROM analytics.revenue")
    engagement = context.fetchdf("SELECT customer_id, engagement_score FROM analytics.engagement")
    
    # Merge and calculate
    merged = revenue.merge(engagement, on='customer_id', how='outer')
    merged['revenue_score'] = merged['total_revenue'] / 1000.0
    merged['engagement_score'] = merged['engagement_score'].fillna(0)
    merged['combined_score'] = merged['revenue_score'] * 0.6 + merged['engagement_score'] * 0.4
    
    return merged[['customer_id', 'revenue_score', 'engagement_score', 'combined_score']]
```

**Test:**

```yaml
test_customer_analysis:
  model: analytics.customer_analysis
  inputs:
    analytics.revenue:
      rows:
        - customer_id: 100
          total_revenue: 2000.00
        - customer_id: 200
          total_revenue: 500.00
    analytics.engagement:
      rows:
        - customer_id: 100
          engagement_score: 0.8
        - customer_id: 200
          engagement_score: 0.5
  outputs:
    query:
      rows:
        - customer_id: 100
          revenue_score: 2.0
          engagement_score: 0.8
          combined_score: 1.52  # 2.0 * 0.6 + 0.8 * 0.4
        - customer_id: 200
          revenue_score: 0.5
          engagement_score: 0.5
          combined_score: 0.5  # 0.5 * 0.6 + 0.5 * 0.4
```

[↑ Back to Top](#chapter-2b-model-testing)

---

## 8. Automatic Test Generation

### 8.1 Using `vulcan create_test`

Generate tests automatically from live data:

**Command:**

```bash
vulcan create_test analytics.daily_revenue \
  --query staging.orders "SELECT * FROM staging.orders WHERE order_date BETWEEN '2024-01-01' AND '2024-01-03' LIMIT 10" \
  --var start '2024-01-01' \
  --var end '2024-01-03'
```

**What It Does:**

1. Executes query against data warehouse
2. Fetches input data for upstream models
3. Runs model with test data
4. Captures actual output
5. Generates complete test YAML

**Generated Test:**

```yaml
test_daily_revenue:
  model: analytics.daily_revenue
  vars:
    start: '2024-01-01'
    end: '2024-01-03'
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          order_date: '2024-01-01'
        # ... more rows from query
  outputs:
    query:
      rows:
        - customer_id: 100
          revenue_date: '2024-01-01'
          revenue: 50.00
        # ... expected output
```

### 8.2 Best Practices for Test Generation

**1. Use Representative Data:**

```bash
# ✅ Good: Representative sample
vulcan create_test analytics.daily_revenue \
  --query staging.orders "SELECT * FROM staging.orders WHERE order_date BETWEEN '2024-01-01' AND '2024-01-07' ORDER BY RANDOM() LIMIT 100"

# ❌ Avoid: Too small or biased
vulcan create_test analytics.daily_revenue \
  --query staging.orders "SELECT * FROM staging.orders LIMIT 1"
```

**2. Set Macro Variables:**

Always set `start`, `end`, `execution_time` for incremental models:

```bash
vulcan create_test analytics.daily_revenue \
  --var start '2024-01-01' \
  --var end '2024-01-07' \
  --var execution_time '2024-01-07 12:00:00'
```

**3. Review Generated Tests:**

- Verify inputs are representative
- Check expected outputs are correct
- Add edge cases manually
- Remove unnecessary complexity

**4. Edit Generated Tests:**

Generated tests are starting points. Enhance them:

```yaml
# Generated test (basic)
test_daily_revenue:
  model: analytics.daily_revenue
  # ... basic test

# Enhanced test (add edge cases)
test_daily_revenue_empty:
  model: analytics.daily_revenue
  # ... empty input test

test_daily_revenue_null_handling:
  model: analytics.daily_revenue
  # ... NULL handling test
```

### 8.3 Limitations

**Automatic generation:**
- ✅ Good for initial test creation
- ✅ Captures current behavior
- ❌ Doesn't test edge cases
- ❌ Doesn't test error conditions
- ❌ May include production data (review carefully)

**Recommendation:** Use `create_test` to bootstrap, then add manual tests for edge cases.

[↑ Back to Top](#chapter-2b-model-testing)

---

## 9. Running Tests

### 9.1 CLI Commands

**Run all tests:**

```bash
vulcan test
```

**Output:**
```
.
----------------------------------------------------------------------
Ran 1 test in 0.042s

OK
```

**Run specific test:**

```bash
vulcan test tests/test_customers.yaml::test_customer_revenue
```

**Run tests matching pattern:**

```bash
vulcan test tests/test_customer*
vulcan test tests/test_*_revenue.yaml
```

**Verbose output:**

```bash
vulcan test -v
```

**Preserve fixtures (for debugging):**

```bash
vulcan test --preserve-fixtures
```

### 9.2 Test Execution in Plans

Tests run **automatically** when creating plans:

```bash
vulcan plan
```

**What happens:**
1. Plan is created
2. Tests run automatically
3. If tests fail → Plan creation halts
4. If tests pass → Plan continues

**Skip tests (not recommended):**

```bash
vulcan plan --skip-tests
```

### 9.3 Notebook Magics

**Run tests in Jupyter:**

```python
import vulcan

%run_test
```

**Run specific test:**

```python
%run_test tests/test_customers.yaml::test_customer_revenue
```

**Verbose output:**

```python
%run_test -v
```

### 9.4 CI/CD Integration

**GitHub Actions Example:**

```yaml
name: Test Models

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: |
          pip install vulcan
      - name: Run tests
        run: |
          vulcan test
```

**Exit Codes:**

- `0` - All tests passed
- `1` - Tests failed

**Use in CI/CD:**

```bash
#!/bin/bash
set -e  # Exit on error

vulcan test
# If tests fail, script exits with code 1
# CI/CD pipeline halts
```

[↑ Back to Top](#chapter-2b-model-testing)

---


## 10. Advanced Patterns

### 10.1 Testing with Macros

**Model with macros:**

```sql
MODEL (
  name analytics.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (time_column revenue_date),
  cron '@daily'
);

SELECT
  customer_id,
  @start_ds as revenue_date,
  SUM(amount) as revenue
FROM staging.orders
WHERE order_date BETWEEN @start_ds AND @end_ds
  AND @IF(@gateway = 'prod', status = 'completed', status IN ('completed', 'pending'))
GROUP BY customer_id;
```

**Test with macro variables:**

```yaml
test_daily_revenue_with_macros:
  model: analytics.daily_revenue
  vars:
    start: '2024-01-01'
    end: '2024-01-01'
    gateway: 'dev'  # Test dev behavior
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
          amount: 50.00
          status: 'completed'
        - order_id: 2
          customer_id: 100
          amount: 75.00
          status: 'pending'  # Included in dev
  outputs:
    query:
      rows:
        - customer_id: 100
          revenue_date: '2024-01-01'
          revenue: 125.00  # Includes pending in dev
```

### 10.2 Testing with Execution Time

**Model:**

```sql
MODEL (
  name analytics.daily_snapshot,
  kind FULL
);

SELECT
  customer_id,
  CURRENT_DATE as snapshot_date,
  CURRENT_TIMESTAMP as snapshot_timestamp
FROM staging.customers;
```

**Test with frozen time:**

```yaml
test_daily_snapshot_time:
  model: analytics.daily_snapshot
  vars:
    execution_time: '2024-01-15 14:30:00'  # Freeze time
  inputs:
    staging.customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
  outputs:
    query:
      rows:
        - customer_id: 100
          snapshot_date: '2024-01-15'      # Matches execution_time date
          snapshot_timestamp: '2024-01-15 14:30:00'  # Matches execution_time
```

### 10.3 Testing Parameterized Model Names

**Model:**

```sql
MODEL (
  name @{schema}.customers,
  kind FULL
);

SELECT * FROM @{schema}.raw_customers;
```

**Test:**

```yaml
test_parameterized_model:
  model: "{{ var('schema') }}.customers"  # Jinja syntax
  vars:
    schema: 'analytics'  # Set schema variable
  inputs:
    analytics.raw_customers:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
  outputs:
    query:
      rows:
        - customer_id: 100
          customer_name: 'Alice'
```

### 10.4 Testing with Different Gateways

**Test using specific gateway:**

```yaml
test_customers_spark:
  gateway: spark_testing  # Use Spark gateway
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
  outputs:
    query:
      rows:
        - customer_id: 100
```

**Gateway Configuration:**

```yaml
# config.yaml
gateways:
  spark_testing:
    test_connection:
      type: spark
      config:
        "spark.master": "local"
```

### 10.5 Testing External Models

**External model definition:**

```yaml
# external_models.yaml
- name: external.third_party_data
  columns:
    id: INT
    value: TEXT
```

**Test:**

```yaml
test_with_external_model:
  model: analytics.enriched_data
  inputs:
    external.third_party_data:
      rows:
        - id: 1
          value: 'test'
    staging.orders:
      rows:
        - order_id: 1
          external_id: 1
  outputs:
    query:
      rows:
        - order_id: 1
          external_value: 'test'
```

### 10.6 Testing with Custom Schema

**Test with custom schema name:**

```yaml
test_customers:
  model: analytics.customers
  schema: my_test_schema  # Custom schema for fixtures
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
  outputs:
    query:
      rows:
        - customer_id: 100
```

**Use case:** Isolate test fixtures, avoid conflicts.

[↑ Back to Top](#chapter-2b-model-testing)

---

## 11. Troubleshooting

### 11.1 Test Failures

**Common failure: Data mismatch**

```
FAIL: test_customer_revenue (tests/test_customers.yaml)
----------------------------------------------------------------------
AssertionError: Data mismatch (exp: expected, act: actual)

  total_revenue
         exp  act
0     125.00  150.00
```

**Debugging steps:**

1. **Check input data:**
   ```yaml
   # Verify inputs are correct
   inputs:
     staging.orders:
       rows:
         - order_id: 1
           amount: 50.00
   ```

2. **Check model logic:**
   ```sql
   -- Review model query
   SELECT customer_id, SUM(amount) as total_revenue
   FROM staging.orders
   GROUP BY customer_id;
   ```

3. **Check expected output:**
   ```yaml
   # Verify expected values are correct
   outputs:
     query:
       rows:
         - customer_id: 100
           total_revenue: 125.00  # Is this correct?
   ```

4. **Use verbose output:**
   ```bash
   vulcan test -v
   ```

### 11.2 Type Mismatches

**Error:** Type mismatch between expected and actual.

**Solution 1: Specify types in model:**

```sql
MODEL (
  name analytics.customer_revenue,
  columns (
    customer_id INT,
    total_revenue DECIMAL(10,2)  # Explicit type
  )
);
```

**Solution 2: Specify types in test:**

```yaml
inputs:
  staging.orders:
    columns:
      order_id: INT
      amount: DECIMAL(10,2)
    rows:
      - order_id: 1
        amount: 50.00
```

**Solution 3: Use SQL query:**

```yaml
inputs:
  staging.orders:
    query: |
      SELECT 
        1::INT AS order_id,
        50.00::DECIMAL(10,2) AS amount
```

### 11.3 Preserving Fixtures

**Debug test failures:**

```bash
vulcan test --preserve-fixtures
```

**What it does:**
- Keeps test fixtures (views) after test completes
- Allows querying fixtures directly
- Helps debug input data issues

**Query fixtures:**

```sql
-- After running test with --preserve-fixtures
SELECT * FROM vulcan_test_<random_id>.staging_orders;
```

**Schema name:**

Fixtures are in schema: `vulcan_test_<random_id>`

**Custom schema:**

```yaml
test_customers:
  model: analytics.customers
  schema: debug_test  # Custom schema name
  # ...
```

### 11.4 Common Issues

**Issue 1: Missing columns in expected output**

**Error:** Test fails because actual output has extra columns.

**Solution:** Use `partial: true`:

```yaml
outputs:
  query:
    partial: true  # Ignore extra columns
    rows:
      - customer_id: 100
        total_revenue: 125.00
```

**Issue 2: Row order matters**

**Error:** Test fails due to row order.

**Solution:** Use `sort_by`:

```yaml
outputs:
  query:
    sort_by: customer_id
    rows:
      - customer_id: 100
        total_revenue: 125.00
      - customer_id: 200
        total_revenue: 100.00
```

**Issue 3: NULL handling**

**Error:** NULL values not handled correctly.

**Solution:** Explicitly test NULLs:

```yaml
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: null  # Explicit NULL
        amount: 50.00
```

**Issue 4: Floating point precision**

**Error:** Decimal comparison fails due to precision.

**Solution:** Round in model or use approximate comparison:

```sql
-- In model
SELECT ROUND(total_revenue, 2) as total_revenue
```

### 11.5 Debugging Tips

**1. Start simple:**

```yaml
# Start with minimal test
test_minimal:
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
  outputs:
    query:
      rows:
        - customer_id: 100
```

**2. Add complexity gradually:**

```yaml
# Add more rows
# Add more columns
# Add more upstream models
```

**3. Test CTEs separately:**

```yaml
outputs:
  ctes:
    filtered_orders:
      rows:
        - order_id: 1
  query:
    rows:
      - customer_id: 100
```

**4. Use SQL queries for complex data:**

```yaml
inputs:
  staging.orders:
    query: |
      -- Complex data generation
      WITH generated_data AS (
        SELECT * FROM (VALUES
          (1, 100, 50.00),
          (2, 100, 75.00)
        ) AS t(order_id, customer_id, amount)
      )
      SELECT * FROM generated_data
```

[↑ Back to Top](#chapter-2b-model-testing)

---

## 12. Best Practices

### 12.1 Test Coverage Strategy

**Critical models:** 100% coverage
- All business logic paths
- All edge cases
- All error conditions

**Important models:** Main paths
- Happy path
- Common edge cases
- Critical calculations

**Simple models:** Edge cases only
- NULL handling
- Empty inputs
- Boundary conditions

### 12.2 Test Organization

**By model:**

```
tests/
├── test_customers.yaml      # All customer tests
├── test_orders.yaml          # All order tests
└── test_revenue.yaml         # All revenue tests
```

**By domain:**

```
tests/
├── customers/
│   ├── test_customer_revenue.yaml
│   ├── test_customer_segments.yaml
│   └── test_customer_metrics.yaml
├── orders/
│   ├── test_order_aggregation.yaml
│   └── test_order_validation.yaml
```

**By scenario:**

```
tests/
├── test_happy_path.yaml      # Happy path tests
├── test_edge_cases.yaml       # Edge case tests
└── test_integration.yaml      # Integration tests
```

**Recommendation:** Start with one file per model, split when files get large.

### 12.3 Test Naming

**Conventions:**

- `test_<model_name>` - Basic test
- `test_<model_name>_<scenario>` - Specific scenario
- `test_<model_name>_edge_case` - Edge case

**Examples:**

```yaml
test_customer_revenue:              # Basic test
test_customer_revenue_empty:        # Empty input
test_customer_revenue_null:         # NULL handling
test_customer_revenue_multiple:     # Multiple orders
test_customer_revenue_high_value:   # High value scenario
```

### 12.4 Test Data

**Use realistic data:**

```yaml
# ✅ Good: Realistic values
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: 100
        amount: 49.99
        status: 'completed'

# ❌ Avoid: Unrealistic values
inputs:
  staging.orders:
    rows:
      - order_id: 999999
        customer_id: 0
        amount: 999999.99
```

**Keep tests small:**

```yaml
# ✅ Good: Minimal data
inputs:
  staging.orders:
    rows:
      - order_id: 1
        customer_id: 100
        amount: 50.00

# ❌ Avoid: Too much data
inputs:
  staging.orders:
    rows:
      # ... 100+ rows
```

**Document test data:**

```yaml
test_customer_revenue:
  description: 'Tests revenue aggregation with multiple orders per customer'
  model: analytics.customer_revenue
  inputs:
    staging.orders:
      rows:
        # Customer 100: 2 orders totaling $125
        - order_id: 1
          customer_id: 100
          amount: 50.00
        - order_id: 2
          customer_id: 100
          amount: 75.00
        # Customer 200: 1 order totaling $100
        - order_id: 3
          customer_id: 200
          amount: 100.00
  outputs:
    query:
      rows:
        - customer_id: 100
          total_revenue: 125.00
        - customer_id: 200
          total_revenue: 100.00
```

### 12.5 Test Maintenance

**Keep tests up to date:**

- Update tests when model logic changes
- Remove obsolete tests
- Refactor duplicate test code

**Review test failures:**

- Don't ignore failures
- Fix tests or fix models
- Understand why tests fail

**Test performance:**

- Keep tests fast (< 1 second each)
- Use minimal data
- Avoid expensive operations

### 12.6 What to Test

✅ **Test:**

- Business logic (calculations, aggregations)
- Edge cases (NULLs, empty inputs, boundaries)
- Filter logic (WHERE clauses)
- Join logic (LEFT, INNER, etc.)
- Transformations (CASE statements, functions)

❌ **Don't test:**

- Simple pass-through (SELECT * FROM ...)
- Trivial filters (WHERE status = 'active')
- Database functions (use database tests)
- Performance (use benchmarks)

### 12.7 Test Independence

**Each test should:**

- Be independent (no shared state)
- Be repeatable (same result every time)
- Be isolated (doesn't affect other tests)

**Avoid:**

- Tests that depend on execution order
- Tests that modify shared fixtures
- Tests that depend on external state

[↑ Back to Top](#chapter-2b-model-testing)

---

## 13. Quick Reference

### 13.1 Test Structure Cheat Sheet

```yaml
test_name:
  model: schema.table_name          # Required
  gateway: gateway_name             # Optional
  schema: custom_schema             # Optional
  description: 'Test description'  # Optional
  inputs:                           # Required (if model has dependencies)
    upstream_model:
      rows:                         # YAML dictionaries
        - col1: val1
      format: csv                   # Or CSV format
      query: SELECT ...             # Or SQL query
      path: fixtures/data.csv       # Or external file
      columns:                      # Optional type hints
        col1: INT
  outputs:                          # Required
    partial: true                   # Optional: partial validation
    query:                          # Query output
      rows:
        - col1: expected_val1
      partial: true                 # Optional: partial for query only
    ctes:                           # Optional: CTE outputs
      cte_name:
        rows:
          - col1: expected_val1
  vars:                             # Optional: Macro variables
    execution_time: '2024-01-01 12:00:00'
    start: '2024-01-01'
    end: '2024-01-02'
    gateway: 'dev'
```

### 13.2 Common Test Patterns

**Basic test:**

```yaml
test_basic:
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          customer_id: 100
  outputs:
    query:
      rows:
        - customer_id: 100
```

**Incremental test:**

```yaml
test_incremental:
  model: analytics.daily_revenue
  vars:
    start: '2024-01-01'
    end: '2024-01-01'
  inputs:
    staging.orders:
      rows:
        - order_id: 1
          order_date: '2024-01-01'
  outputs:
    query:
      rows:
        - revenue_date: '2024-01-01'
```

**CTE test:**

```yaml
test_with_cte:
  model: analytics.customers
  inputs:
    staging.orders:
      rows:
        - order_id: 1
  outputs:
    ctes:
      filtered_orders:
        rows:
          - order_id: 1
    query:
      rows:
        - customer_id: 100
```

**Partial validation:**

```yaml
test_partial:
  model: analytics.customers
  outputs:
    query:
      partial: true
      rows:
        - customer_id: 100
          # Other columns ignored
```

### 13.3 CLI Commands

```bash
# Run all tests
vulcan test

# Run specific test
vulcan test tests/test_customers.yaml::test_customer_revenue

# Run tests matching pattern
vulcan test tests/test_customer*

# Verbose output
vulcan test -v

# Preserve fixtures
vulcan test --preserve-fixtures

# Generate test
vulcan create_test analytics.customers \
  --query staging.orders "SELECT * FROM staging.orders LIMIT 10" \
  --var start '2024-01-01' \
  --var end '2024-01-01'
```

### 13.4 Decision Tree

```
Need to test a model?
│
├─ Model has complex logic?
│  └─ YES → Write comprehensive tests
│     ├─ Test happy path
│     ├─ Test edge cases
│     └─ Test error conditions
│
├─ Model is simple (pass-through)?
│  └─ YES → Skip tests or test edge cases only
│
├─ Model feeds critical downstream?
│  └─ YES → Write tests (prevent breaking changes)
│
└─ Model is experimental?
   └─ YES → Test after stabilization
```

### 13.5 Test Checklist

**Before writing test:**

- [ ] Understand model logic
- [ ] Identify edge cases
- [ ] Determine test data needs
- [ ] Plan test scenarios

**Writing test:**

- [ ] Use realistic test data
- [ ] Test happy path
- [ ] Test edge cases (NULLs, empty, boundaries)
- [ ] Validate all important columns
- [ ] Add description

**After writing test:**

- [ ] Test passes
- [ ] Test is readable
- [ ] Test is maintainable
- [ ] Test is fast (< 1 second)

[↑ Back to Top](#chapter-2b-model-testing)

---

## Summary

You've learned comprehensive unit testing for Vulcan models:

### Key Takeaways

1. **Test Structure:**
   - YAML files in `tests/` directory
   - `inputs` for upstream models
   - `outputs` for expected results
   - `vars` for macro variables

2. **Input Formats:**
   - YAML dictionaries (default)
   - CSV format
   - SQL queries
   - External files

3. **Output Validation:**
   - Query output
   - CTE output
   - Partial validation
   - Type checking

4. **Testing Patterns:**
   - Basic aggregations
   - Joins
   - NULL handling
   - Edge cases
   - Complex calculations

5. **Incremental Models:**
   - Set `start`, `end` in `vars`
   - Test time filtering logic
   - Test lookback behavior

6. **Python Models:**
   - Test DataFrame outputs
   - Test complex logic
   - Test multiple dependencies

7. **Best Practices:**
   - Test critical models thoroughly
   - Keep tests small and fast
   - Use realistic data
   - Maintain tests over time

### Related Topics

- **[Chapter 2: Models](index.md)** - Model basics
- **[Chapter 4: Audits](../audits/index.md)** - Data quality validation
- **[Chapter 5: Quality Checks](../data-quality/index.md)** - Monitoring and trends

### Next Steps

1. Write tests for your critical models
2. Add tests to CI/CD pipeline
3. Use `vulcan create_test` to bootstrap tests
4. Review and maintain tests regularly

**Congratulations! You've completed the Model Testing chapter.**

[↑ Back to Top](#chapter-2b-model-testing)

---
