# Chapter 04: Audits

> **Audits are SQL queries that validate your model's data after execution** - they act as automatic gatekeepers, ensuring only valid data flows downstream to dependent models and consumers.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Quick Start](#2-quick-start)
3. [Built-in Audits Reference](#3-built-in-audits-reference)
4. [Creating Custom Audits](#4-creating-custom-audits)
5. [Inline Audits](#5-inline-audits)
6. [Advanced Audit Patterns](#6-advanced-audit-patterns)
7. [Audit Execution and Lifecycle](#7-audit-execution-and-lifecycle)
8. [Troubleshooting and Debugging](#8-troubleshooting-and-debugging)
9. [Best Practices](#9-best-practices)
10. [Real-World Examples](#10-real-world-examples)
11. [Quick Reference](#11-quick-reference)
12. [Summary and Next Steps](#12-summary-and-next-steps)

---

## 1. Introduction

### 1.1 What are Audits?

**Audits are SQL queries that run automatically after model execution to validate data quality.** They search for invalid data, and if any is found, they halt the flow of data to prevent bad data from propagating downstream.

---

### 1.1.1 Terminology: Audits and Assertions

**Two related concepts:**
- **AUDIT** - The validation rule (the SQL query that checks for problems)
- **ASSERTION** - Attaching an audit to a model (claiming it should pass)

**In MODEL definitions:**
```sql
-- Define the AUDIT (the rule)
AUDIT (name check_positive_price);
SELECT * FROM @this_model WHERE price <= 0;

-- Make ASSERTIONS about your model (attach the audit)
MODEL (
  name products,
  assertions (check_positive_price)  -- Declaring this audit should pass
);
```

> **Note:** You may encounter older code that attaches audits using `audits` instead of `assertions` in MODEL definitions. While both work identically, please update to use `assertions` for clearer semantics. This chapter uses `assertions` throughout.

---

### 1.1.2 How Audits Work

**Core Principles:**

**Audits are:**
- **Automatic** - Run after every model execution without manual intervention
- **Blocking** - Always halt execution when they fail (no "warning-only" mode in Vulcan)
- **Scoped** - For incremental models, validate only the newly processed intervals
- **SQL-based** - Written as SQL queries that search for invalid data

**How audits work:**
1. Model executes and generates/updates table
2. Audits run automatically against the result
3. Each audit query:
   - Returns NO rows → Audit passes
   - Returns ANY rows → Audit fails → Execution halts
4. If all audits pass → Data flows downstream
5. If any audit fails → Execution stops, bad data is contained

### 1.1.3 Why Use Audits?

Audits provide **immediate feedback** during transformation:

| Without Audits | With Audits |
|----------------|-------------|
| Bad data propagates silently | Bad data is caught immediately |
| Downstream models consume invalid data | Downstream models never see invalid data |
| Data quality issues discovered by users | Data quality issues discovered by system |
| Manual validation required | Automatic validation built-in |
| Root cause is hard to trace | Failure points to exact model |

**Real-world impact:**
```sql
-- Without audit: $0 revenue records propagate to finance dashboard
-- Finance team discovers it 2 days later, traces through 5 models

-- With audit: Caught immediately at source
MODEL (
  name sales.orders,
  assertions (
    accepted_range(column := revenue, min_v := 0, max_v := 10000000)
  )
);
-- Audit fails → Execution halts → Alert sent → Fixed within 30 minutes
```

---

### 1.2 Audits vs Quality Checks vs Profiles

Vulcan provides three complementary data quality mechanisms. Understanding when to use each is critical:

#### Comparison Table

| Feature | **Audits** | **Quality Checks** | **Profiles** |
|---------|-----------|-------------------|--------------|
| **Purpose** | Validate & block invalid data | Monitor & track quality over time | Observe & track statistical trends |
| **Definition** | SQL queries (inline or `audits/`) | YAML configurations (`checks.yml`) | Column list in model metadata |
| **Execution** | After model execution (automatic) | Scheduled/triggered (flexible) | After model execution (automatic) |
| **Behavior** | **Always blocking** | Configurable (blocking or warning) | **Always non-blocking** |
| **Output** | Pass/Fail → Halts on failure | Pass/Fail + historical tracking | Metrics stored in `_check_profiles` |
| **Scope** | Model-level (coupled to model) | Project-level (centralized) | Model-level (observability) |
| **Use Case** | Critical validations | Comprehensive monitoring | Baseline tracking, anomaly detection |
| **Example** | `not_null(columns := (id))` | `row_count > 1000` | Track null % trend over 30 days |

#### When to Use Each

**Use Audits When:**
- Data quality is **critical** - invalid data must not pass through
- Validation must be **tightly coupled** to model transformation logic
- You need **immediate feedback** during execution
- The rule is a **hard constraint** (similar to database constraints)
- Failure should **halt the flow of data**

**Examples:**
```sql
-- Primary key must be unique and not null
assertions (
  not_null(columns := (order_id)),
  unique_values(columns := (order_id))
)

-- Revenue must be positive
assertions (
  forall(criteria := (revenue >= 0))
)

-- Status must be in valid set
assertions (
  accepted_values(column := status, is_in := ('pending', 'completed', 'cancelled'))
)
```

**Use Quality Checks When:**
- Monitoring data quality **trends over time**
- Need **flexible scheduling** independent of model runs
- Want **centralized configuration** across all models
- Require **detailed reporting** and alerting
- Some checks should be **warnings** rather than blocking

**Examples (YAML):**
```yaml
# checks/orders.yml
checks:
  sales.orders:
    completeness:
      - row_count > 1000:
          name: sufficient_daily_orders
          attributes:
            description: "At least 1000 orders expected daily"
    
    validity:
      - failed rows:
          name: invalid_status_values
          fail query: |
            SELECT order_id, status
            FROM sales.orders
            WHERE status NOT IN ('pending', 'completed', 'cancelled')
          samples limit: 10
```

**Use Profiles When:**
- Tracking **statistical trends** (mean, stddev, null %, distinct count)
- Understanding **data distribution** changes over time
- Building **baseline metrics** for anomaly detection
- Data **observability** without enforcing rules
- Planning future audits based on observed patterns

**Examples:**
```sql
MODEL (
  name sales.orders,
  profiles (revenue, customer_id, order_date, discount)
);

-- Profiles automatically track:
-- • Null count/percentage
-- • Distinct value count
-- • Min/max/mean/stddev (numeric columns)
-- • Date ranges (date columns)
```

#### Decision Flow

```
Need data quality control?
│
├─ Must BLOCK bad data?
│  └─ YES → Use AUDIT
│     ├─ Reusable across models? → File-based audit in audits/
│     └─ Model-specific? → Inline audit in MODEL()
│
├─ Need historical tracking?
│  └─ YES → Use QUALITY CHECK
│     ├─ Should block? → Set blocking: true
│     └─ Just monitor? → Set blocking: false
│
└─ Just observing patterns?
   └─ YES → Use PROFILE
      └─ View trends in _check_profiles table
```

---

### 1.3 Audits and OLTP Constraints: Similar But Different

If you're familiar with relational databases, audits serve a similar purpose to table constraints (like `NOT NULL`, `CHECK`, `UNIQUE`, `FOREIGN KEY`) - but with a critical difference in **where** the blocking happens.

#### The Key Difference: WHERE Blocking Happens

**OLTP Constraints: Block at INSERT/UPDATE**

In traditional OLTP databases, constraints are enforced at the **row-insert level**:

```sql
-- Traditional OLTP database
CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  customer_tier VARCHAR(20) CHECK (customer_tier IN ('free', 'pro', 'enterprise')),
  lifetime_value DECIMAL(10,2) CHECK (lifetime_value >= 0)
);

-- What happens during INSERT:
INSERT INTO customers VALUES (1, 'user@example.com', 'invalid_tier', 100);
-- ❌ ERROR: Check constraint violation
-- ❌ Transaction ABORTED
-- ❌ Data never written to table
```

**Key characteristics:**
- Blocking happens **during the write operation**
- Individual bad rows are **rejected immediately**
- Good rows can still be inserted (if constraints pass)
- Bad data **never enters the table**

**Audits: Block Downstream Data Flow**

In Vulcan, audits are enforced **after transformation completes**:

```sql
-- Vulcan model
MODEL (
  name analytics.customers,
  assertions (
    not_null(columns := (customer_id, email)),
    accepted_values(
      column := customer_tier, 
      is_in := ('free', 'pro', 'enterprise')
    ),
    forall(criteria := (lifetime_value >= 0))
  )
);

SELECT
  customer_id,
  email,
  customer_tier,
  lifetime_value
FROM raw.customers;

-- What happens during execution:
-- 1. Model executes → Table is written/updated
-- 2. Audits run against the complete result
-- 3. If audit finds violations:
--    ❌ Execution halts
--    ❌ Downstream models DO NOT run
--    ❌ Bad data is CONTAINED in this model (doesn't propagate)
-- 4. Note: The table itself contains the bad data, 
--    but it's isolated - downstream flow is blocked
```

**Key characteristics:**
- Blocking happens **after transformation completes**
- Entire result set is validated (batch-level)
- Bad data may be written to the table, but is **contained**
- Downstream models never see the bad data

#### Visualizing the Difference

**OLTP Constraints:**
```
Source Data → INSERT → [Constraint Check] → ❌ REJECTED → Table unchanged
                                          → ✅ PASS → Data in table
```

**Audits/Assertions:**
```
Source Data → Model Execution → Data written to table → [Audit Check] 
                                                       → ❌ FAIL → Stop here; Downstream blocked
                                                       → ✅ PASS → Flow downstream
```

#### Why This Difference Matters

**Scenario: Bad data appears in source system**

**With OLTP Constraints:**
```sql
-- Bad rows are rejected at INSERT time
INSERT INTO orders (order_id, amount) VALUES (1, -100);  -- ❌ Rejected
INSERT INTO orders (order_id, amount) VALUES (2, 50);    -- ✅ Accepted
-- Result: Partial data load, some rows missing
```

**With Audits:**
```sql
-- All data is transformed, then validated
MODEL (name orders, assertions (forall(criteria := (amount >= 0))));
SELECT * FROM raw.orders;  -- Includes order_id=1 with amount=-100

-- Result: 
-- • Entire batch is validated
-- • If ANY row violates audit, ALL data is flagged
-- • Downstream models are protected from seeing ANY of this batch
-- • You fix the source, then reprocess the entire batch
```

**CORRECT: Use audits when:**
- You're transforming batch data (not transactional inserts)
- You want to validate entire result sets
- You want to protect downstream consumers
- You can reprocess data after fixing source issues

**INCORRECT: Don't expect audits to:**
- Reject individual rows and accept others
- Prevent bad data from being written to the model's own table
- Work like row-level INSERT constraints

---

#### Mapping OLTP Constraints to Audits

| OLTP Constraint | Audit Equivalent | Purpose |
|----------------|------------------|---------|
| `NOT NULL` | `not_null(columns := (col))` | Ensure required fields exist |
| `UNIQUE` | `unique_values(columns := (col))` | Prevent duplicate values |
| `PRIMARY KEY` | `not_null(...)` + `unique_values(...)` | Enforce primary key integrity |
| `CHECK (price > 0)` | `forall(criteria := (price > 0))` | Business rule validation |
| `CHECK (status IN (...))` | `accepted_values(column := status, is_in := (...))` | Enum/domain validation |
| `CHECK (start < end)` | `forall(criteria := (start_date < end_date))` | Multi-column validation |
| `FOREIGN KEY` | Custom audit with `LEFT JOIN` | Referential integrity |

**Example: Complete constraint mapping**

**OLTP Table:**
```sql
CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_date DATE NOT NULL,
  shipped_date DATE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'cancelled')),
  CHECK (shipped_date IS NULL OR shipped_date >= order_date),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

**Vulcan Model with Equivalent Audits:**
```sql
MODEL (
  name analytics.orders,
  grain order_id,
  references (customer_id),
  assertions (
    -- PRIMARY KEY: NOT NULL + UNIQUE
    not_null(columns := (order_id)),
    unique_values(columns := (order_id)),
    
    -- NOT NULL columns
    not_null(columns := (customer_id, order_date, amount)),
    
    -- CHECK (amount >= 0)
    forall(criteria := (amount >= 0)),
    
    -- CHECK (status IN (...))
    accepted_values(
      column := status,
      is_in := ('pending', 'completed', 'cancelled')
    ),
    
    -- CHECK (shipped_date >= order_date)
    forall(criteria := (
      shipped_date IS NULL OR shipped_date >= order_date
    ))
    
    -- FOREIGN KEY - requires custom audit (see Section 6.1)
  )
);

SELECT
  order_id::INT,
  customer_id::INT,
  order_date::DATE,
  shipped_date::DATE,
  amount::DECIMAL(10,2),
  status::VARCHAR
FROM raw.orders;
```

---

#### Audits Go Beyond Row-Level Constraints

While OLTP constraints work at the row level, audits can validate much more:

**1. Aggregate Validations** (impossible with row-level constraints)
```sql
-- Ensure table has minimum number of rows
assertions (
  number_of_rows(threshold := 1000)
)

-- Ensure we have data for all expected dates
AUDIT (name complete_date_range);
SELECT expected_date
FROM (
  SELECT GENERATE_SERIES(
    '2024-01-01'::DATE, 
    CURRENT_DATE, 
    '1 day'::INTERVAL
  ) AS expected_date
) expected
LEFT JOIN @this_model actual ON expected.expected_date = actual.order_date
WHERE actual.order_date IS NULL;
```

**2. Statistical Validations**
```sql
-- Ensure revenue mean is within expected range
assertions (
  mean_in_range(column := revenue, min_v := 50, max_v := 500)
)

-- Detect outliers
assertions (
  z_score(column := transaction_amount, threshold := 3)
)

-- Ensure distributions are similar
assertions (
  kl_divergence(
    column := current_month_revenue,
    target_column := last_month_revenue,
    threshold := 0.1
  )
)
```

**3. Cross-Table Referential Integrity** (more flexible than FK constraints)
```sql
-- Validate foreign key relationship
AUDIT (name valid_customer_reference);
SELECT o.* 
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL  -- Exclude nulls (separate audit)
  AND c.customer_id IS NULL;      -- Customer doesn't exist

-- Validate multi-column foreign key
AUDIT (name valid_product_location_reference);
SELECT ol.*
FROM @this_model ol
LEFT JOIN dim.product_locations pl 
  ON ol.product_id = pl.product_id 
  AND ol.warehouse_id = pl.warehouse_id
WHERE pl.product_id IS NULL;
```

**4. Complex Business Logic**
```sql
-- Validate discount rules
assertions (
  forall(criteria := (
    -- Discount amount can't exceed order amount
    discount_amount <= order_amount,
    -- Discount percentage can't exceed 100%
    discount_percent <= 1.0,
    -- Can't have both dollar discount AND percentage discount
    (discount_amount = 0) OR (discount_percent = 0),
    -- Premium customers get discounts, others don't
    (customer_tier = 'premium') OR (discount_amount = 0 AND discount_percent = 0)
  ))
)
```

**5. Time-Series Consistency**
```sql
-- Ensure no gaps in time series data
AUDIT (name no_gaps_in_daily_data);
WITH expected_dates AS (
  SELECT DATE_TRUNC('day', GENERATE_SERIES(
    (SELECT MIN(order_date) FROM @this_model),
    (SELECT MAX(order_date) FROM @this_model),
    '1 day'::INTERVAL
  )) AS expected_date
)
SELECT ed.expected_date
FROM expected_dates ed
LEFT JOIN (
  SELECT DISTINCT DATE_TRUNC('day', order_date) AS order_date
  FROM @this_model
) actual ON ed.expected_date = actual.order_date
WHERE actual.order_date IS NULL;

-- Ensure monotonic increase
AUDIT (name cumulative_revenue_increases);
SELECT 
  t1.date,
  t1.cumulative_revenue,
  t2.cumulative_revenue AS previous_cumulative_revenue
FROM @this_model t1
JOIN @this_model t2 
  ON t2.date = t1.date - INTERVAL '1 day'
WHERE t1.cumulative_revenue < t2.cumulative_revenue;
```

**Summary: Constraints vs Audits**

| Capability | OLTP Constraints | Audits |
|------------|------------------|--------|
| Row-level validation | Yes | Yes |
| Aggregate validation | No | Yes |
| Statistical validation | No | Yes |
| Cross-table validation | Limited (FK only) | Full SQL flexibility |
| Complex business logic | Limited | Full SQL flexibility |
| Time-series validation | No | Yes |
| Blocking location | At INSERT/UPDATE | After transformation, before downstream |
| Granularity | Individual rows | Entire batch |

---

### 1.4 When to Use Audits

#### Audit Coverage Strategy

Layer your audits by **criticality** and **impact**:

**CRITICAL (Always Audit)**

These validations are non-negotiable - failure indicates severe data corruption:

| Validation Type | Why Critical | Audit |
|-----------------|--------------|-------|
| **Primary Key Integrity** | Breaks joins, violates uniqueness | `not_null` + `unique_values` |
| **Foreign Key Integrity** | Orphaned records, broken relationships | Custom JOIN audit |
| **Non-negative Amounts** | Business logic violation | `forall(criteria := (amount >= 0))` |
| **Required Fields** | Downstream models expect them | `not_null(columns := (...))` |
| **Date Ordering** | Illogical sequences | `forall(criteria := (start <= end))` |

**Example: Orders table (critical audits only)**
```sql
MODEL (
  name sales.orders,
  grain order_id,
  references (customer_id),
  assertions (
    -- Critical validations only
    not_null(columns := (order_id, customer_id, order_date, amount)),
    unique_values(columns := (order_id)),
    forall(criteria := (amount >= 0))
  )
);
```

**IMPORTANT (Audit Frequently)**

Should catch these, but rare edge cases may exist:

| Validation Type | Why Important | Audit |
|-----------------|---------------|-------|
| **Enum Validation** | Protects downstream case statements | `accepted_values` |
| **Range Validation** | Business constraints | `accepted_range` |
| **Format Validation** | Ensures parsability | `valid_email`, `valid_url` |
| **Calculated Field Logic** | Derived values must be consistent | Custom audit |
| **Row Count Thresholds** | Catches upstream failures | `number_of_rows` |

**Example: Adding important audits**
```sql
MODEL (
  name sales.orders,
  assertions (
    -- Critical (from above)
    not_null(columns := (order_id, customer_id, order_date, amount)),
    unique_values(columns := (order_id)),
    forall(criteria := (amount >= 0)),
    
    -- Important (added)
    accepted_values(
      column := status, 
      is_in := ('pending', 'completed', 'cancelled', 'refunded')
    ),
    accepted_range(column := amount, min_v := 0, max_v := 1000000),
    number_of_rows(threshold := 100)  -- Expect at least 100 orders
  )
);
```

**NICE-TO-HAVE (Audit Selectively)**

These improve data quality but don't justify blocking:

| Validation Type | Consideration | Audit or Profile? |
|-----------------|---------------|-------------------|
| **String Length** | Rarely breaks downstream | Profile first, audit if issues found |
| **Statistical Bounds** | Natural variation exists | Profile first, audit for outliers |
| **Format Patterns** | Best-effort validation | Audit if format is critical |
| **Data Consistency** | Soft business rules | Check (warning) first, audit if critical |

**Recommendation:** Start with **profiles** to understand patterns, then promote to **audits** if you find recurring issues.

#### Anti-Patterns: When NOT to Use Audits

**INCORRECT: Don't audit just because you can**
```sql
-- TOO MANY AUDITS (over-engineering)
MODEL (
  name sales.orders,
  assertions (
    not_null(columns := (order_id, customer_id)),           -- CORRECT
    unique_values(columns := (order_id)),                    -- CORRECT
    string_length_equal(column := order_id, v := 36),        -- Overkill
    valid_uuid(column := order_id),                           -- Overkill
    not_constant(column := order_id),                         -- Redundant
    at_least_one(column := order_id),                         -- Redundant
    z_score(column := order_id, threshold := 3),              -- Nonsensical
    mean_in_range(column := order_id, min_v := 1000, max_v := 9999)  -- Nonsensical
  )
);
```

**INCORRECT: Don't use audits for exploratory validation**
```sql
-- INCORRECT: Blocking on unknown thresholds
assertions (
  accepted_range(column := session_duration, min_v := 0, max_v := 3600)
)

-- CORRECT: Use profiles to understand distribution first
profiles (session_duration)
-- After seeing the distribution, add audit with appropriate threshold
```

**INCORRECT: Don't use audits when the business rule is unclear**
```sql
-- INCORRECT: What if legitimate orders exceed $1M?
assertions (
  accepted_range(column := amount, min_v := 0, max_v := 1000000)
)

-- CORRECT: Clarify business rules first, or use profiles
-- Option 1: Clarify with stakeholders
assertions (
  accepted_range(column := amount, min_v := 0, max_v := 10000000)  -- Confirmed max
)

-- Option 2: Profile and monitor instead
profiles (amount)
```

---

### 1.5 Audit Execution Lifecycle

#### When Audits Run

Audits execute automatically in this sequence:

**1. Model Execution**
```
Model SQL executes → Data written to table
```

**2. Audit Execution (Automatic)**
```
For each audit defined in MODEL():
  → Run audit SQL query
  → Check if any rows returned
  → If rows returned: FAIL
  → If no rows returned: PASS
```

**3. Result Handling**
```
All audits pass → Continue to next model in execution graph
Any audit fails → Halt execution, log failure, send alerts
```

#### Incremental Models: Audit Scope

For **incremental models**, audits only validate **newly processed intervals**:

```sql
MODEL (
  name sales.daily_revenue,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date
  ),
  assertions (
    not_null(columns := (order_date, revenue))
  )
);

-- If processing 2024-01-15:
-- Audit runs: SELECT * FROM daily_revenue 
--             WHERE order_date = '2024-01-15' 
--             AND revenue IS NULL
--
-- Historical data (2024-01-01 to 2024-01-14) is NOT re-audited
```

**Why?** Efficiency. Re-auditing the entire table on every run would be expensive and unnecessary.

**Special macro:** `@this_model` automatically handles interval filtering for incremental models.

#### Full Refresh Models: Audit Scope

For **full refresh models**, audits validate the **entire table**:

```sql
MODEL (
  name dim.customers,
  kind FULL,
  assertions (
    unique_values(columns := (customer_id))
  )
);

-- Every execution: SELECT customer_id, COUNT(*) 
--                  FROM dim.customers 
--                  GROUP BY customer_id 
--                  HAVING COUNT(*) > 1
```

---

### 1.6 Audit Philosophy: Query for Bad Data

#### The Inverted Logic Pattern

Audits use **inverted logic** - they query for violations, not compliance:

**CORRECT: Find Bad Data**
```sql
-- Audit succeeds if NO rows are returned
AUDIT (name assert_positive_revenue);
SELECT * FROM @this_model 
WHERE revenue <= 0;  -- Find violations

-- Returns 0 rows → All revenue is positive → Audit passes
-- Returns N rows → Found negative revenue → Audit fails
```

**INCORRECT: Find Good Data**
```sql
-- DON'T DO THIS - Logic is backwards!
AUDIT (name assert_positive_revenue);
SELECT * FROM @this_model 
WHERE revenue > 0;  -- Find compliant rows

-- Returns N rows → Audit fails (found data!)
-- This is backwards - you want to find PROBLEMS, not successes
```

#### Why This Pattern?

This pattern aligns with how constraints work:

| System | Pattern |
|--------|---------|
| **SQL Constraints** | Define what's NOT allowed: `CHECK (price > 0)` |
| **Unit Tests** | Assert what should NOT happen: `assert x != null` |
| **Audits** | Query for what should NOT exist: `SELECT ... WHERE bad_condition` |

#### Common Audit Patterns

**Pattern 1: Null Check**
```sql
-- CORRECT: Find rows with nulls
SELECT * FROM @this_model WHERE customer_id IS NULL;
```

**Pattern 2: Range Validation**
```sql
-- CORRECT: Find rows outside valid range
SELECT * FROM @this_model WHERE age < 0 OR age > 120;
```

**Pattern 3: Enum Validation**
```sql
-- CORRECT: Find rows with invalid status
SELECT * FROM @this_model 
WHERE status NOT IN ('pending', 'completed', 'cancelled');
```

**Pattern 4: Uniqueness**
```sql
-- CORRECT: Find duplicate keys
SELECT order_id, COUNT(*) as duplicate_count
FROM @this_model
GROUP BY order_id
HAVING COUNT(*) > 1;
```

**Pattern 5: Referential Integrity**
```sql
-- CORRECT: Find orphaned records (customer_id doesn't exist)
SELECT o.*
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL  -- Exclude nulls (separate audit)
  AND c.customer_id IS NULL;      -- Customer doesn't exist
```

[↑ Back to Top](#chapter-04-audits)

---

## 2. Quick Start

### 2.1 Your First Audit

Let's start with the most common use case: ensuring required fields have no NULL values.

**Model without audit:**
```sql
MODEL (
  name sales.orders,
  grain order_id
);

SELECT
  order_id,
  customer_id,
  order_date,
  amount
FROM raw.orders;
```

**Add your first audit:**
```sql
MODEL (
  name sales.orders,
  grain order_id,
  assertions (
    not_null(columns := (order_id, customer_id, order_date, amount))
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  amount
FROM raw.orders;
```

**What happens:**
1. Model executes and populates `sales.orders` table
2. Audit runs automatically: `SELECT * FROM sales.orders WHERE order_id IS NULL OR customer_id IS NULL OR order_date IS NULL OR amount IS NULL`
3. If query returns 0 rows → Audit passes → Downstream models can run
4. If query returns any rows → Audit fails → Execution halts

**Example failure output:**
```
Failure in audit 'not_null' for model 'sales.orders'.
Got 3 results, expected 0.
Query: SELECT * FROM sales.orders WHERE ... IS NULL
```

---

### 2.2 Common Patterns (5 Most-Used Audits)

Here are the five audits you'll use most frequently:

#### 1. Not Null - Required Fields
```sql
MODEL (
  name sales.orders,
  assertions (
    not_null(columns := (order_id, customer_id, order_date))
  )
);
```

**Use when:** Fields are required for downstream processing.

---

#### 2. Unique Values - Primary Keys
```sql
MODEL (
  name dim.customers,
  grain customer_id,
  assertions (
    unique_values(columns := (customer_id))
  )
);
```

**Use when:** Column must be unique (typically primary keys).

---

#### 3. Accepted Values - Enum Validation
```sql
MODEL (
  name sales.orders,
  assertions (
    accepted_values(
      column := status,
      is_in := ('pending', 'completed', 'cancelled', 'refunded')
    )
  )
);
```

**Use when:** Column has a fixed set of valid values.

---

#### 4. Accepted Range - Numeric Bounds
```sql
MODEL (
  name sales.orders,
  assertions (
    accepted_range(column := amount, min_v := 0, max_v := 10000000)
  )
);
```

**Use when:** Numeric columns must fall within business-defined bounds.

---

#### 5. Forall - Custom Business Logic
```sql
MODEL (
  name sales.orders,
  assertions (
    forall(criteria := (
      amount >= 0,
      order_date <= CURRENT_DATE,
      shipped_date IS NULL OR shipped_date >= order_date
    ))
  )
);
```

**Use when:** You need custom SQL logic that built-in audits don't cover.

---

### 2.3 Multiple Audits on One Model

You can (and should) apply multiple audits to the same model:

```sql
MODEL (
  name sales.orders,
  grain order_id,
  references (customer_id),
  assertions (
    -- Completeness: Required fields
    not_null(columns := (order_id, customer_id, order_date, amount)),
    
    -- Uniqueness: Primary key
    unique_values(columns := (order_id)),
    
    -- Validity: Status enum
    accepted_values(
      column := status,
      is_in := ('pending', 'completed', 'cancelled', 'refunded')
    ),
    
    -- Validity: Amount range
    accepted_range(column := amount, min_v := 0, max_v := 10000000),
    
    -- Business logic: Date ordering
    forall(criteria := (
      shipped_date IS NULL OR shipped_date >= order_date
    )),
    
    -- Data quality: Minimum row count
    number_of_rows(threshold := 100)
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  shipped_date,
  amount,
  status
FROM raw.orders;
```

**Execution order:**
- Audits run in the order they're defined
- If any audit fails, execution halts immediately
- Subsequent audits don't run after a failure

**TIP:** Order audits from fastest to slowest (cheap checks first, expensive checks last).

[↑ Back to Top](#chapter-04-audits)

---

## 3. Built-in Audits Reference

Vulcan provides 29 built-in audits covering common validation scenarios. All audits are **blocking by default** (and only blocking in Vulcan - there is no non-blocking mode).

### Audit Categories

- [3.1 Data Completeness Audits](#31-data-completeness-audits) - NULL values, row counts
- [3.2 Data Uniqueness Audits](#32-data-uniqueness-audits) - Duplicates, distinct values
- [3.3 Data Validity Audits](#33-data-validity-audits) - Enums, ranges, sequences
- [3.4 String Validation Audits](#34-string-validation-audits) - Length, format, patterns
- [3.5 Pattern Matching Audits](#35-pattern-matching-audits) - Regex, LIKE patterns
- [3.6 Statistical Audits](#36-statistical-audits) - Mean, stddev, outliers
- [3.7 Generic Assertion Audit](#37-generic-assertion-audit) - Custom boolean logic

---

### 3.1 Data Completeness Audits

These audits validate that required data is present.

#### `not_null`

Ensures specified columns contain no NULL values.

**Parameters:**
- `columns` - List of column names to check (required)

**Example:**
```sql
MODEL (
  name sales.orders,
  assertions (
    not_null(columns := (order_id, customer_id, order_date, amount))
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM sales.orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR order_date IS NULL
   OR amount IS NULL;
```

**Use when:**
- Columns are required for downstream processing
- Missing values would break joins or calculations
- Implementing NOT NULL constraint equivalent

**TIP:** Group related required fields together for clarity.

---

#### `at_least_one`

Ensures a column contains at least one non-NULL value.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name dim.customers,
  assertions (
    at_least_one(column := email)
  )
);
```

**Equivalent SQL:**
```sql
SELECT CASE 
  WHEN COUNT(*) = 0 THEN 'No rows in table'
  WHEN COUNT(email) = 0 THEN 'All emails are NULL'
END AS violation
FROM dim.customers
HAVING COUNT(email) = 0;
```

**Use when:**
- Optional column should have at least some data
- Detecting complete data loss in a column
- Ensuring a table isn't completely empty

**WARNING:** This audit fails if the table is empty OR if all values are NULL.

---

#### `not_null_proportion`

Ensures the proportion of NULL values doesn't exceed a threshold.

**Parameters:**
- `column` - Column name to check (required)
- `threshold` - Maximum proportion of NULLs allowed, as decimal 0-1 (required)

**Example:**
```sql
MODEL (
  name dim.customers,
  assertions (
    not_null_proportion(column := zip_code, threshold := 0.2)  -- Max 20% NULLs
  )
);
```

**Equivalent SQL:**
```sql
SELECT 
  COUNT(*) AS total_rows,
  COUNT(zip_code) AS non_null_count,
  (COUNT(*) - COUNT(zip_code)) / COUNT(*)::FLOAT AS null_proportion
FROM dim.customers
HAVING (COUNT(*) - COUNT(zip_code)) / COUNT(*)::FLOAT > 0.2;
```

**Use when:**
- Column is optional but should be mostly populated
- Monitoring data quality degradation over time
- Soft requirement (not completely required, but expected)

**Example thresholds:**
- `threshold := 0.1` - Max 10% NULLs (mostly required)
- `threshold := 0.5` - Max 50% NULLs (nice to have)
- `threshold := 0.9` - Max 90% NULLs (rarely populated)

---

#### `number_of_rows`

Ensures the table contains at least a minimum number of rows.

**Parameters:**
- `threshold` - Minimum number of rows required (required)

**Example:**
```sql
MODEL (
  name sales.daily_orders,
  assertions (
    number_of_rows(threshold := 100)  -- Expect at least 100 orders
  )
);
```

**Equivalent SQL:**
```sql
SELECT COUNT(*) AS row_count
FROM sales.daily_orders
HAVING COUNT(*) < 100;
```

**Use when:**
- Detecting upstream data source failures
- Ensuring minimum data volume for analytics
- Catching incomplete data loads

**TIP:** Set threshold based on historical patterns. If you typically have 10,000 rows, a threshold of 1,000 catches major issues without false positives.

---

### 3.2 Data Uniqueness Audits

These audits validate that values or combinations are unique.

#### `unique_values`

Ensures specified columns contain no duplicate values.

**Parameters:**
- `columns` - List of column names to check for uniqueness (required)

**Example:**
```sql
MODEL (
  name dim.customers,
  grain customer_id,
  assertions (
    unique_values(columns := (customer_id))
  )
);
```

**Equivalent SQL:**
```sql
SELECT customer_id, COUNT(*) AS duplicate_count
FROM dim.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;
```

**Multiple columns (each must be individually unique):**
```sql
assertions (
  unique_values(columns := (customer_id, email))
)
-- Both customer_id must be unique AND email must be unique
```

**Use when:**
- Enforcing primary key uniqueness
- Ensuring no duplicate records
- Validating unique constraint equivalent

**WARNING:** `unique_values(columns := (col1, col2))` checks that BOTH are unique individually, NOT that the combination is unique. For combination uniqueness, use `unique_combination_of_columns`.

---

#### `unique_combination_of_columns`

Ensures each row has a unique combination of values across specified columns.

**Parameters:**
- `columns` - List of column names that form composite key (required)

**Example:**
```sql
MODEL (
  name sales.daily_customer_revenue,
  grains (customer_id, order_date),
  assertions (
    unique_combination_of_columns(columns := (customer_id, order_date))
  )
);
```

**Equivalent SQL:**
```sql
SELECT customer_id, order_date, COUNT(*) AS duplicate_count
FROM sales.daily_customer_revenue
GROUP BY customer_id, order_date
HAVING COUNT(*) > 1;
```

**Use when:**
- Composite primary keys (multi-column grain)
- Ensuring no duplicate rows for customer + date
- Fact tables with compound keys

**Example use cases:**
- `(user_id, date)` - One row per user per day
- `(order_id, line_item)` - One row per line item
- `(product_id, warehouse_id)` - One row per product-warehouse combination

---

#### `not_constant`

Ensures a column has at least two distinct non-NULL values.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name sales.customer_segmentation,
  assertions (
    not_constant(column := customer_segment)
  )
);
```

**Equivalent SQL:**
```sql
SELECT COUNT(DISTINCT customer_segment) AS distinct_count
FROM sales.customer_segmentation
WHERE customer_segment IS NOT NULL
HAVING COUNT(DISTINCT customer_segment) < 2;
```

**Use when:**
- Ensuring variation in a column (not all same value)
- Catching upstream filter mistakes (e.g., WHERE country = 'US' applied incorrectly)
- Validating segmentation columns have multiple segments

**WARNING:** This audit ignores NULL values. A column with all NULLs will fail `at_least_one`, not `not_constant`.

---

### 3.3 Data Validity Audits

These audits validate that values fall within expected sets or ranges.

#### `accepted_values`

Ensures all values in a column are in an allowed list.

**Parameters:**
- `column` - Column name to check (required)
- `is_in` - List of accepted values (required)

**Example:**
```sql
MODEL (
  name sales.orders,
  assertions (
    accepted_values(
      column := status,
      is_in := ('pending', 'completed', 'cancelled', 'refunded')
    )
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM sales.orders
WHERE status NOT IN ('pending', 'completed', 'cancelled', 'refunded');
```

**Use when:**
- Enum columns (status, type, category)
- Fixed set of valid values
- Protecting downstream CASE statements

**NOTE:** NULL values pass this audit. If you want to ensure no NULLs, add a separate `not_null` audit.

---

#### `not_accepted_values`

Ensures no values in a column are in a rejected list.

**Parameters:**
- `column` - Column name to check (required)
- `is_in` - List of rejected values (required)

**Example:**
```sql
MODEL (
  name dim.products,
  assertions (
    not_accepted_values(
      column := product_name,
      is_in := ('test', 'dummy', 'placeholder')
    )
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM dim.products
WHERE product_name IN ('test', 'dummy', 'placeholder');
```

**Use when:**
- Ensuring test data doesn't reach production
- Blocking known invalid values
- Catching placeholder values

**NOTE:** This audit does not reject NULL values. Use `not_null` for that.

---

#### `accepted_range`

Ensures numeric values fall within a specified range.

**Parameters:**
- `column` - Column name to check (required)
- `min_v` - Minimum value (required)
- `max_v` - Maximum value (required)
- `inclusive` - Whether range boundaries are included (optional, default: true)

**Example (inclusive):**
```sql
MODEL (
  name sales.orders,
  assertions (
    accepted_range(column := amount, min_v := 0, max_v := 1000000)
    -- Allows amount >= 0 AND amount <= 1000000
  )
);
```

**Example (exclusive):**
```sql
MODEL (
  name analytics.metrics,
  assertions (
    accepted_range(column := percentage, min_v := 0, max_v := 1, inclusive := false)
    -- Allows percentage > 0 AND percentage < 1 (excludes 0 and 1)
  )
);
```

**Equivalent SQL (inclusive):**
```sql
SELECT * FROM sales.orders
WHERE amount < 0 OR amount > 1000000;
```

**Equivalent SQL (exclusive):**
```sql
SELECT * FROM analytics.metrics
WHERE percentage <= 0 OR percentage >= 1;
```

**Use when:**
- Enforcing business rules (revenue > 0, age between 0-120)
- Catching outliers or data entry errors
- Implementing CHECK constraint equivalent

---

#### `mutually_exclusive_ranges`

Ensures numeric ranges in different rows don't overlap.

**Parameters:**
- `lower_bound_column` - Column containing range start (required)
- `upper_bound_column` - Column containing range end (required)

**Example:**
```sql
MODEL (
  name pricing.tier_ranges,
  assertions (
    mutually_exclusive_ranges(
      lower_bound_column := min_revenue,
      upper_bound_column := max_revenue
    )
  )
);
```

**Equivalent SQL:**
```sql
SELECT 
  t1.tier_name AS tier1,
  t2.tier_name AS tier2,
  t1.min_revenue AS t1_min,
  t1.max_revenue AS t1_max,
  t2.min_revenue AS t2_min,
  t2.max_revenue AS t2_max
FROM pricing.tier_ranges t1
JOIN pricing.tier_ranges t2 ON t1.tier_id < t2.tier_id
WHERE t1.min_revenue <= t2.max_revenue 
  AND t1.max_revenue >= t2.min_revenue;
```

**Use when:**
- Pricing tiers with revenue ranges
- Date ranges that shouldn't overlap
- Territory assignments (zip code ranges)

**Example data:**
```
Tier      | Min Revenue | Max Revenue
----------|-------------|-------------
Bronze    | 0           | 10000       ✓ Valid
Silver    | 10001       | 50000       ✓ Valid  
Gold      | 50001       | 100000      ✓ Valid
Platinum  | 40000       | 200000      ✗ Overlaps with Silver & Gold
```

---

#### `sequential_values`

Ensures ordered numeric column values are sequential with consistent interval.

**Parameters:**
- `column` - Column name to check (required)
- `interval` - Expected difference between consecutive values (required)

**Example:**
```sql
MODEL (
  name dim.date_spine,
  assertions (
    sequential_values(column := date_key, interval := 1)
    -- date_key should be 20240101, 20240102, 20240103, ... (no gaps)
  )
);
```

**Equivalent SQL:**
```sql
WITH ordered_values AS (
  SELECT 
    date_key,
    LAG(date_key) OVER (ORDER BY date_key) AS prev_date_key
  FROM dim.date_spine
)
SELECT * FROM ordered_values
WHERE prev_date_key IS NOT NULL
  AND date_key != prev_date_key + 1;
```

**Use when:**
- Date dimensions with no gaps
- Sequential ID columns
- Time series with regular intervals

**WARNING:** This audit assumes values are naturally ordered. It fails if there are gaps in the sequence.

---

### 3.4 String Validation Audits

These audits validate string/character data characteristics.

#### `not_empty_string`

Ensures no rows contain empty strings ('').

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name dim.products,
  assertions (
    not_empty_string(column := product_name)
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM dim.products
WHERE product_name = '';
```

**Use when:**
- Catching empty strings vs NULL (they're different!)
- Ensuring string columns have meaningful content
- Validating user input

**NOTE:** Empty string ('') and NULL are different. This audit checks for '', not NULL.

---

#### `string_length_equal`

Ensures all string values have exactly the specified length.

**Parameters:**
- `column` - Column name to check (required)
- `v` - Expected string length (required)

**Example:**
```sql
MODEL (
  name dim.locations,
  assertions (
    string_length_equal(column := zip_code, v := 5)
    -- All zip codes must be exactly 5 characters
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM dim.locations
WHERE LENGTH(zip_code) != 5;
```

**Use when:**
- Fixed-length codes (zip codes, country codes, SKUs)
- Standardized identifiers
- Validating data format

---

#### `string_length_between`

Ensures string values have length within a specified range.

**Parameters:**
- `column` - Column name to check (required)
- `min_v` - Minimum length (required)
- `max_v` - Maximum length (required)
- `inclusive` - Whether boundaries are included (optional, default: true)

**Example:**
```sql
MODEL (
  name dim.customers,
  assertions (
    string_length_between(column := customer_name, min_v := 2, max_v := 100)
    -- Names between 2 and 100 characters (inclusive)
  )
);
```

**Equivalent SQL (inclusive):**
```sql
SELECT * FROM dim.customers
WHERE LENGTH(customer_name) < 2 OR LENGTH(customer_name) > 100;
```

**Use when:**
- Validating reasonable name lengths
- Ensuring text fields aren't too long
- Catching truncated data

---

#### `valid_email`

Ensures strings match email address format.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name dim.users,
  assertions (
    valid_email(column := email)
  )
);
```

**Equivalent SQL:**
```sql
-- Uses regex: ^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$
SELECT * FROM dim.users
WHERE email IS NOT NULL
  AND NOT REGEXP_MATCHES(email, '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
```

**Use when:**
- Validating email addresses
- Ensuring parseable contact information
- Catching malformed data

**NOTE:** NULL values pass this audit. Use `not_null` separately if required.

---

#### `valid_url`

Ensures strings match URL format.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name dim.products,
  assertions (
    valid_url(column := product_url)
  )
);
```

**Equivalent SQL:**
```sql
-- Uses regex: ^(https?|ftp)://[^\s/$.?#].[^\s]*$
SELECT * FROM dim.products
WHERE product_url IS NOT NULL
  AND NOT REGEXP_MATCHES(product_url, '^(https?|ftp)://[^\s/$.?#].[^\s]*$');
```

**Use when:**
- Validating website URLs
- Ensuring clickable links
- API endpoint validation

---

#### `valid_uuid`

Ensures strings match UUID format.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name events.user_sessions,
  assertions (
    valid_uuid(column := session_id)
  )
);
```

**Equivalent SQL:**
```sql
-- UUID format: 8-4-4-4-12 hexadecimal digits
-- Example: 550e8400-e29b-41d4-a716-446655440000
SELECT * FROM events.user_sessions
WHERE session_id IS NOT NULL
  AND NOT REGEXP_MATCHES(session_id, 
    '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
```

**Use when:**
- Validating UUID identifiers
- Ensuring proper format from UUID generators
- Catching malformed IDs

---

#### `valid_http_method`

Ensures values are valid HTTP methods.

**Parameters:**
- `column` - Column name to check (required)

**Example:**
```sql
MODEL (
  name logs.api_requests,
  assertions (
    valid_http_method(column := http_method)
  )
);
```

**Valid HTTP methods:**
- GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE, CONNECT

**Equivalent SQL:**
```sql
SELECT * FROM logs.api_requests
WHERE http_method NOT IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 
                          'HEAD', 'OPTIONS', 'TRACE', 'CONNECT');
```

**Use when:**
- Validating API logs
- Ensuring standardized HTTP methods
- Catching typos or malformed requests

---

### 3.5 Pattern Matching Audits

These audits validate strings against patterns.

#### `match_regex_pattern_list`

Ensures all non-NULL values match at least one regex pattern.

**Parameters:**
- `column` - Column name to check (required)
- `patterns` - List of regex patterns (required)

**Example:**
```sql
MODEL (
  name products.inventory,
  assertions (
    match_regex_pattern_list(
      column := sku,
      patterns := ('^[A-Z]{3}-[0-9]{6}$', '^LEGACY-.*')
      -- Matches: ABC-123456 OR LEGACY-anything
    )
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM products.inventory
WHERE sku IS NOT NULL
  AND NOT (
    REGEXP_MATCHES(sku, '^[A-Z]{3}-[0-9]{6}$') OR
    REGEXP_MATCHES(sku, '^LEGACY-.*')
  );
```

**Use when:**
- Multiple valid format patterns
- Complex validation rules
- Migrating between formats

---

#### `not_match_regex_pattern_list`

Ensures no non-NULL values match any regex pattern.

**Parameters:**
- `column` - Column name to check (required)
- `patterns` - List of regex patterns to reject (required)

**Example:**
```sql
MODEL (
  name products.inventory,
  assertions (
    not_match_regex_pattern_list(
      column := sku,
      patterns := ('^TEST-.*', '^TEMP-.*', '^DEBUG-.*')
      -- Reject: TEST-*, TEMP-*, DEBUG-*
    )
  )
);
```

**Use when:**
- Blocking test data patterns
- Ensuring production-only data
- Catching debug/temporary records

---

#### `match_like_pattern_list`

Ensures all non-NULL values match at least one LIKE pattern.

**Parameters:**
- `column` - Column name to check (required)
- `patterns` - List of LIKE patterns (required)

**Example:**
```sql
MODEL (
  name sales.customers,
  assertions (
    match_like_pattern_list(
      column := email,
      patterns := ('%@company.com', '%@subsidiary.com')
      -- Only company or subsidiary emails
    )
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM sales.customers
WHERE email IS NOT NULL
  AND NOT (email LIKE '%@company.com' OR email LIKE '%@subsidiary.com');
```

**Use when:**
- Simple wildcard patterns
- Domain validation
- Simpler than regex

---

#### `not_match_like_pattern_list`

Ensures no non-NULL values match any LIKE pattern.

**Parameters:**
- `column` - Column name to check (required)
- `patterns` - List of LIKE patterns to reject (required)

**Example:**
```sql
MODEL (
  name products.catalog,
  assertions (
    not_match_like_pattern_list(
      column := product_name,
      patterns := ('%test%', '%dummy%', '%placeholder%')
    )
  )
);
```

**Use when:**
- Blocking keywords (test, dummy, etc.)
- Ensuring clean data
- Catching placeholders

---

### 3.6 Statistical Audits

These audits validate statistical properties of numeric columns.

**WARNING:** Thresholds for statistical audits typically require tuning based on your data distribution. Start with profiles to understand baseline statistics before setting audit thresholds.

#### `mean_in_range`

Ensures column mean falls within specified range.

**Parameters:**
- `column` - Column name to check (required)
- `min_v` - Minimum mean (required)
- `max_v` - Maximum mean (required)
- `inclusive` - Whether boundaries are included (optional, default: true)

**Example:**
```sql
MODEL (
  name sales.daily_revenue,
  assertions (
    mean_in_range(column := order_amount, min_v := 50, max_v := 200)
    -- Average order should be between $50-$200
  )
);
```

**Use when:**
- Detecting shifts in average behavior
- Ensuring expected data distribution
- Catching data quality issues affecting aggregates

---

#### `stddev_in_range`

Ensures column standard deviation falls within specified range.

**Parameters:**
- `column` - Column name to check (required)
- `min_v` - Minimum standard deviation (required)
- `max_v` - Maximum standard deviation (required)
- `inclusive` - Whether boundaries are included (optional, default: true)

**Example:**
```sql
MODEL (
  name analytics.customer_metrics,
  assertions (
    stddev_in_range(column := purchase_frequency, min_v := 5, max_v := 20)
  )
);
```

**Use when:**
- Monitoring data variability
- Detecting unusual distribution changes
- Ensuring consistent spread

---

#### `z_score`

Ensures no values have absolute z-score exceeding threshold (outlier detection).

**Parameters:**
- `column` - Column name to check (required)
- `threshold` - Maximum absolute z-score (required, typically 3 or 4)

**Example:**
```sql
MODEL (
  name sales.transactions,
  assertions (
    z_score(column := transaction_amount, threshold := 3)
    -- Flag values >3 standard deviations from mean
  )
);
```

**Z-score calculation:**
```
z = |value - mean| / stddev
```

**Common thresholds:**
- `threshold := 2` - Strict (catches values >2σ from mean, ~5% of normal distribution)
- `threshold := 3` - Standard (catches values >3σ from mean, ~0.3% of normal distribution)
- `threshold := 4` - Lenient (catches extreme outliers only)

**Use when:**
- Detecting extreme outliers
- Catching data entry errors
- Ensuring realistic value ranges

---

#### `kl_divergence`

Ensures symmetrized KL divergence between two columns doesn't exceed threshold.

**Parameters:**
- `column` - First column to compare (required)
- `target_column` - Second column to compare (required)
- `threshold` - Maximum KL divergence (required)

**Example:**
```sql
MODEL (
  name analytics.cohort_comparison,
  assertions (
    kl_divergence(
      column := current_month_revenue_distribution,
      target_column := last_month_revenue_distribution,
      threshold := 0.1
    )
  )
);
```

**Use when:**
- Comparing distributions across time periods
- Detecting distribution shifts
- A/B test validation

**NOTE:** This is an advanced statistical audit. Most use cases are better served by profiles or quality checks with trending.

---

#### `chi_square`

Ensures chi-square statistic for two categorical columns doesn't exceed critical value.

**Parameters:**
- `column` - First categorical column (required)
- `target_column` - Second categorical column (required)
- `critical_value` - Chi-square critical value (required)

**Example:**
```sql
MODEL (
  name analytics.user_segments,
  assertions (
    chi_square(
      column := user_region,
      target_column := subscription_tier,
      critical_value := 6.635  -- p-value 0.95, df=1
    )
  )
);
```

**Finding critical values:**
```python
from scipy.stats import chi2
# critical_value for p=0.95, degrees_of_freedom=1
chi2.ppf(0.95, 1)  # Returns 3.841
```

**Use when:**
- Testing independence of categorical variables
- Validating expected relationships
- Advanced statistical validation

**NOTE:** This is an advanced statistical audit requiring knowledge of chi-square testing.

---

### 3.7 Generic Assertion Audit

#### `forall`

Ensures arbitrary boolean expressions evaluate to TRUE for all rows.

**Parameters:**
- `criteria` - List of boolean SQL expressions (required)

**Example:**
```sql
MODEL (
  name sales.orders,
  assertions (
    forall(criteria := (
      amount >= 0,
      order_date <= CURRENT_DATE,
      shipped_date IS NULL OR shipped_date >= order_date,
      discount_amount <= amount,
      (customer_tier = 'premium') OR (discount_percent = 0)
    ))
  )
);
```

**Equivalent SQL:**
```sql
SELECT * FROM sales.orders
WHERE NOT (
  amount >= 0
  AND order_date <= CURRENT_DATE
  AND (shipped_date IS NULL OR shipped_date >= order_date)
  AND discount_amount <= amount
  AND ((customer_tier = 'premium') OR (discount_percent = 0))
);
```

**Use when:**
- Multiple related conditions
- Complex business logic
- Custom validation not covered by built-in audits

**TIP:** This is the most flexible audit - use it when built-in audits don't fit your needs.

[↑ Back to Top](#chapter-04-audits)

---

## 4. Creating Custom Audits

When built-in audits don't cover your specific validation needs, create custom audits.

### 4.1 Basic Custom Audit

Custom audits are defined in `.sql` files within an `audits/` directory in your project.

**Project structure:**
```
my_project/
├── models/
│   ├── staging/
│   └── marts/
├── audits/           ← Create this directory
│   └── business_rules.sql
└── config.yaml
```

**Example: audits/business_rules.sql**
```sql
AUDIT (
  name assert_positive_price,
  dialect postgres
);

SELECT * FROM @this_model
WHERE price IS NOT NULL 
  AND price <= 0;
```

**Apply to model:**
```sql
-- models/staging/products.sql
MODEL (
  name staging.products,
  assertions (assert_positive_price)
);

SELECT
  product_id,
  product_name,
  price,
  cost
FROM raw.products;
```

**Key components:**
1. `AUDIT (name ...)` - Defines the audit name
2. `dialect` - Optional, specifies SQL dialect if different from project default
3. `SELECT * FROM @this_model WHERE ...` - Query for bad data

---

### 4.2 Parameterized Audits (Reusable)

Make audits reusable by adding parameters:

**audits/generic_checks.sql**
```sql
AUDIT (
  name threshold_check
);

SELECT * FROM @this_model
WHERE @column > @threshold;
```

**Apply with different parameters:**
```sql
MODEL (
  name sales.orders,
  assertions (
    threshold_check(column := amount, threshold := 10000),
    threshold_check(column := quantity, threshold := 100)
  )
);
```

**How it works:**
- `@column` and `@threshold` are macro variables
- Values are substituted when audit runs
- Same audit definition, multiple uses

**Example: Range check audit**
```sql
AUDIT (
  name value_in_range
);

SELECT * FROM @this_model
WHERE @column < @min_value OR @column > @max_value;
```

**Usage:**
```sql
assertions (
  value_in_range(column := age, min_value := 0, max_value := 120),
  value_in_range(column := discount_percent, min_value := 0, max_value := 1)
)
```

---

### 4.3 Audit File Organization

Organize audits by domain or function:

**Recommended structure:**
```
audits/
├── common/                    # Reusable generic audits
│   ├── nulls.sql             # Null-related checks
│   ├── ranges.sql            # Range validations
│   └── formats.sql           # Format validations
├── sales/                     # Domain-specific audits
│   ├── orders.sql
│   └── revenue.sql
├── finance/
│   └── transactions.sql
└── data_quality/
    └── referential.sql       # Referential integrity checks
```

**Example: audits/common/ranges.sql**
```sql
-- Generic positive value check
AUDIT (name assert_positive);
SELECT * FROM @this_model
WHERE @column <= 0;

-- Generic non-negative check
AUDIT (name assert_non_negative);
SELECT * FROM @this_model
WHERE @column < 0;

-- Generic percentage check (0-1)
AUDIT (name assert_valid_percentage);
SELECT * FROM @this_model
WHERE @column < 0 OR @column > 1;

-- Generic percentage check (0-100)
AUDIT (name assert_valid_percentage_100);
SELECT * FROM @this_model
WHERE @column < 0 OR @column > 100;
```

**Example: audits/sales/orders.sql**
```sql
-- Order-specific business rules
AUDIT (name valid_order_dates);
SELECT * FROM @this_model
WHERE order_date > CURRENT_DATE
   OR (shipped_date IS NOT NULL AND shipped_date < order_date)
   OR (delivered_date IS NOT NULL AND delivered_date < shipped_date);

-- Order amount validation
AUDIT (name valid_order_amounts);
SELECT * FROM @this_model
WHERE amount < 0
   OR discount_amount > amount
   OR tax_amount < 0
   OR total_amount != amount - discount_amount + tax_amount;
```

**TIP:** Multiple audits can be defined in a single file. Group related audits together.

---

### 4.4 Special Macros

Vulcan provides special macros for audit queries:

#### `@this_model`

References the model being audited. For incremental models, automatically filters to processed intervals.

**Usage:**
```sql
AUDIT (name check_values);
SELECT * FROM @this_model
WHERE invalid_condition;
```

**For incremental models:**
```sql
-- If model is INCREMENTAL_BY_TIME_RANGE with time_column = order_date
-- And processing interval 2024-01-15

-- @this_model expands to:
-- (SELECT * FROM sales.orders WHERE order_date = '2024-01-15')

AUDIT (name check_today_orders);
SELECT * FROM @this_model
WHERE amount < 0;
-- Only checks orders from 2024-01-15
```

#### `@start_ds` and `@end_ds`

For incremental models, these provide the date/timestamp boundaries of the processed interval.

**Usage:**
```sql
AUDIT (name check_date_range);
SELECT * FROM @this_model
WHERE order_date < @start_ds
   OR order_date > @end_ds;
```

**Example: Ensure all data is within expected interval**
```sql
AUDIT (name data_within_interval);
SELECT 
  order_date,
  '@start_ds' AS expected_start,
  '@end_ds' AS expected_end
FROM @this_model
WHERE order_date NOT BETWEEN @start_ds AND @end_ds;
```

#### Custom Parameters

Any parameter passed to the audit becomes a macro variable:

**Audit definition:**
```sql
AUDIT (name multi_param_check);
SELECT * FROM @this_model
WHERE @column1 > @threshold1
   OR @column2 < @threshold2
   OR @status NOT IN @valid_statuses;
```

**Usage:**
```sql
assertions (
  multi_param_check(
    column1 := revenue,
    threshold1 := 1000000,
    column2 := margin,
    threshold2 := 0.1,
    valid_statuses := ('active', 'pending')
  )
)
```

---

### 4.5 Dialect-Specific Audits

Specify SQL dialect if different from project default:

**audits/spark_specific.sql**
```sql
AUDIT (
  name check_array_length,
  dialect spark
);

SELECT * FROM @this_model
WHERE SIZE(@array_column) < @min_size;
```

**Common use cases:**
- Using database-specific functions
- Warehouse-specific syntax
- Multi-warehouse projects

**Example: BigQuery specific**
```sql
AUDIT (
  name check_json_field,
  dialect bigquery
);

SELECT * FROM @this_model
WHERE JSON_EXTRACT_SCALAR(@json_column, '$.field') IS NULL;
```

**Example: Snowflake specific**
```sql
AUDIT (
  name check_variant_field,
  dialect snowflake
);

SELECT * FROM @this_model
WHERE @variant_column:field::STRING IS NULL;
```

---

### 4.6 Default Parameters

Provide default values for parameters:

**audits/defaults_example.sql**
```sql
AUDIT (
  name threshold_check,
  defaults (
    threshold = 100,
    column = value
  )
);

SELECT * FROM @this_model
WHERE @column > @threshold;
```

**Usage with defaults:**
```sql
-- Use default threshold (100) and default column (value)
assertions (
  threshold_check()
)

-- Override threshold, use default column
assertions (
  threshold_check(threshold := 1000)
)

-- Override both
assertions (
  threshold_check(column := amount, threshold := 5000)
)
```

**Example: Flexible range check**
```sql
AUDIT (
  name range_check,
  defaults (
    min_value = 0,
    max_value = 999999,
    column = amount,
    inclusive = true
  )
);

SELECT * FROM @this_model
WHERE (
  CASE WHEN @inclusive THEN
    @column < @min_value OR @column > @max_value
  ELSE
    @column <= @min_value OR @column >= @max_value
  END
);
```

---

### 4.7 Naming Conventions for Custom Audits

**CORRECT naming:**
```sql
-- Descriptive, action-oriented names
assert_positive_revenue
validate_customer_exists
check_order_date_before_shipped_date
ensure_email_format_valid
verify_no_duplicate_transactions
```

**INCORRECT naming:**
```sql
-- Too vague
audit1
check_data
validation
my_audit

-- Too generic
check
validate
ensure
```

**Naming patterns:**
- `assert_*` - For simple assertions (assert_positive_price)
- `validate_*` - For complex validations (validate_referential_integrity)
- `check_*` - For conditional checks (check_date_ordering)
- `ensure_*` - For guarantee checks (ensure_completeness)
- `verify_*` - For verification logic (verify_calculations)

---

### 4.8 Documenting Custom Audits

Add comments to explain complex audits:

**audits/documented_example.sql**
```sql
-- =============================================================================
-- Audit: validate_revenue_calculation
-- Description: Ensures revenue calculation is correct
-- Business Rule: Revenue = Quantity * Unit Price - Discounts + Taxes
-- Tolerance: Allow $0.01 rounding difference
-- =============================================================================
AUDIT (name validate_revenue_calculation);

SELECT 
  order_id,
  revenue AS recorded_revenue,
  (quantity * unit_price - discount_amount + tax_amount) AS calculated_revenue,
  ABS(revenue - (quantity * unit_price - discount_amount + tax_amount)) AS difference
FROM @this_model
WHERE ABS(revenue - (quantity * unit_price - discount_amount + tax_amount)) > 0.01;
```

**Complex business logic audit:**
```sql
-- =============================================================================
-- Audit: validate_subscription_lifecycle
-- Description: Ensures subscription dates follow valid lifecycle
-- Business Rules:
--   1. start_date <= current_date
--   2. end_date > start_date (if not NULL)
--   3. cancelled_date between start_date and end_date
--   4. renewal_date > end_date (for auto-renew subscriptions)
-- =============================================================================
AUDIT (name validate_subscription_lifecycle);

SELECT 
  subscription_id,
  start_date,
  end_date,
  cancelled_date,
  renewal_date,
  CASE
    WHEN start_date > CURRENT_DATE THEN 'Future start date'
    WHEN end_date IS NOT NULL AND end_date <= start_date THEN 'End before start'
    WHEN cancelled_date IS NOT NULL AND cancelled_date < start_date THEN 'Cancelled before start'
    WHEN cancelled_date IS NOT NULL AND end_date IS NOT NULL AND cancelled_date > end_date THEN 'Cancelled after end'
    WHEN renewal_date IS NOT NULL AND end_date IS NOT NULL AND renewal_date <= end_date THEN 'Renewal before end'
    ELSE 'Unknown violation'
  END AS violation_type
FROM @this_model
WHERE start_date > CURRENT_DATE
   OR (end_date IS NOT NULL AND end_date <= start_date)
   OR (cancelled_date IS NOT NULL AND cancelled_date < start_date)
   OR (cancelled_date IS NOT NULL AND end_date IS NOT NULL AND cancelled_date > end_date)
   OR (renewal_date IS NOT NULL AND end_date IS NOT NULL AND renewal_date <= end_date);
```

[↑ Back to Top](#chapter-04-audits)

---

## 5. Inline Audits

Inline audits are defined directly within model files, keeping audit logic close to the model it validates.

### 5.1 When to Use Inline vs File-Based Audits

| Use Inline Audits | Use File-Based Audits |
|-------------------|----------------------|
| Model-specific validation | Reusable across models |
| Simple, one-off checks | Complex parameterized logic |
| Keep audit close to model logic | Shared team standards |
| Quick prototyping | Organized by domain |
| Few audits (1-3) | Many audits (4+) |

**CORRECT: Use inline for model-specific logic**
```sql
-- models/sales/daily_metrics.sql
MODEL (
  name sales.daily_metrics,
  assertions (revenue_matches_orders, no_future_dates)
);

SELECT
  order_date,
  SUM(amount) AS revenue,
  COUNT(*) AS order_count
FROM sales.orders
GROUP BY order_date;

-- Inline audit 1: Model-specific calculation check
AUDIT (name revenue_matches_orders);
SELECT dm.order_date, dm.revenue, SUM(o.amount) AS actual_revenue
FROM @this_model dm
JOIN sales.orders o ON dm.order_date = o.order_date
GROUP BY dm.order_date, dm.revenue
HAVING dm.revenue != SUM(o.amount);

-- Inline audit 2: Model-specific date check
AUDIT (name no_future_dates);
SELECT * FROM @this_model
WHERE order_date > CURRENT_DATE;
```

**INCORRECT: Don't inline generic reusable audits**
```sql
-- DON'T DO THIS - This should be in audits/common/
MODEL (
  name sales.orders,
  assertions (not_null_check, positive_amount_check)
);

SELECT * FROM raw.orders;

AUDIT (name not_null_check);  -- Generic! Should be in audits/
SELECT * FROM @this_model WHERE order_id IS NULL;

AUDIT (name positive_amount_check);  -- Generic! Should be in audits/
SELECT * FROM @this_model WHERE amount <= 0;
```

---

### 5.2 Inline Audit Syntax

**Basic syntax:**
```sql
MODEL (
  name schema.table_name,
  assertions (audit1, audit2, audit3)  -- Reference inline audits
);

-- Model query
SELECT ...;

-- Inline audit definitions
AUDIT (name audit1);
SELECT ...;

AUDIT (name audit2);
SELECT ...;

AUDIT (name audit3);
SELECT ...;
```

**Example: Product inventory**
```sql
MODEL (
  name inventory.product_stock,
  grain (product_id, warehouse_id),
  assertions (
    valid_stock_levels,
    consistent_totals
  )
);

SELECT
  product_id,
  warehouse_id,
  on_hand_qty,
  reserved_qty,
  available_qty
FROM raw.inventory;

-- Audit 1: Stock quantities make sense
AUDIT (name valid_stock_levels);
SELECT * FROM @this_model
WHERE on_hand_qty < 0
   OR reserved_qty < 0
   OR available_qty < 0
   OR reserved_qty > on_hand_qty
   OR available_qty != (on_hand_qty - reserved_qty);

-- Audit 2: Totals match warehouse aggregates
AUDIT (name consistent_totals);
SELECT 
  product_id,
  COUNT(*) AS warehouse_count,
  SUM(on_hand_qty) AS total_on_hand
FROM @this_model
GROUP BY product_id
HAVING SUM(on_hand_qty) < 0;  -- Shouldn't be possible if audit 1 passes
```

---

### 5.3 Multiple Inline Audits

You can define many inline audits in a single model file:

**Example: Comprehensive order validation**
```sql
MODEL (
  name sales.orders,
  grain order_id,
  assertions (
    valid_amounts,
    valid_dates,
    valid_status_transitions,
    valid_customer_references,
    valid_calculations
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  shipped_date,
  delivered_date,
  amount,
  discount_amount,
  tax_amount,
  total_amount,
  status
FROM raw.orders;

-- Audit 1: Amount validations
AUDIT (name valid_amounts);
SELECT * FROM @this_model
WHERE amount <= 0
   OR discount_amount < 0
   OR tax_amount < 0
   OR total_amount < 0
   OR discount_amount > amount;

-- Audit 2: Date validations
AUDIT (name valid_dates);
SELECT * FROM @this_model
WHERE order_date > CURRENT_DATE
   OR (shipped_date IS NOT NULL AND shipped_date < order_date)
   OR (delivered_date IS NOT NULL AND delivered_date < shipped_date);

-- Audit 3: Status logic
AUDIT (name valid_status_transitions);
SELECT * FROM @this_model
WHERE (status = 'shipped' AND shipped_date IS NULL)
   OR (status = 'delivered' AND delivered_date IS NULL)
   OR (status = 'pending' AND shipped_date IS NOT NULL);

-- Audit 4: Referential integrity
AUDIT (name valid_customer_references);
SELECT o.*
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Audit 5: Calculation validation
AUDIT (name valid_calculations);
SELECT * FROM @this_model
WHERE ABS(total_amount - (amount - discount_amount + tax_amount)) > 0.01;
```

**TIP:** Inline audits run in the order defined. Put fast audits first, expensive audits last.

---

### 5.4 Combining Inline and File-Based Audits

You can use both inline and file-based audits together:

**Example: Mix generic and specific audits**
```sql
MODEL (
  name sales.orders,
  grain order_id,
  assertions (
    -- File-based generic audits
    not_null(columns := (order_id, customer_id, order_date)),
    unique_values(columns := (order_id)),
    accepted_range(column := amount, min_v := 0, max_v := 1000000),
    
    -- Inline model-specific audits
    valid_order_lifecycle,
    revenue_matches_line_items
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  shipped_date,
  amount,
  discount_amount
FROM raw.orders;

-- Inline audit 1: Order-specific lifecycle
AUDIT (name valid_order_lifecycle);
SELECT * FROM @this_model
WHERE shipped_date IS NOT NULL 
  AND shipped_date < order_date;

-- Inline audit 2: Order-specific calculation
AUDIT (name revenue_matches_line_items);
SELECT 
  o.order_id,
  o.amount AS order_amount,
  SUM(li.quantity * li.unit_price) AS line_items_total
FROM @this_model o
JOIN raw.order_line_items li ON o.order_id = li.order_id
GROUP BY o.order_id, o.amount
HAVING ABS(o.amount - SUM(li.quantity * li.unit_price)) > 0.01;
```

**When to combine:**
- Use file-based audits for standard validations (nulls, uniqueness, ranges)
- Use inline audits for model-specific business logic
- This gives you both reusability and specificity

---

### 5.5 Inline Audits with Parameters

Inline audits can be parameterized too:

```sql
MODEL (
  name sales.orders,
  assertions (
    threshold_check(column := amount, threshold := 10000),
    threshold_check(column := quantity, threshold := 100)
  )
);

SELECT * FROM raw.orders;

-- Parameterized inline audit
AUDIT (name threshold_check);
SELECT * FROM @this_model
WHERE @column > @threshold;
```

**Reusing inline audits within the same model:**
```sql
MODEL (
  name sales.metrics,
  assertions (
    range_check(column := revenue, min_val := 0, max_val := 1000000),
    range_check(column := profit, min_val := -100000, max_val := 500000),
    range_check(column := margin, min_val := 0, max_val := 1)
  )
);

SELECT * FROM raw.metrics;

AUDIT (name range_check);
SELECT * FROM @this_model
WHERE @column < @min_val OR @column > @max_val;
```

---

### 5.6 Organizing Inline Audits

**For clarity, add comments:**
```sql
MODEL (
  name sales.complex_metrics,
  assertions (
    completeness_checks,
    business_rule_validations,
    calculation_validations
  )
);

SELECT * FROM ...;

-- =============================================================================
-- COMPLETENESS CHECKS
-- =============================================================================

AUDIT (name completeness_checks);
SELECT * FROM @this_model
WHERE customer_id IS NULL
   OR revenue IS NULL
   OR order_count IS NULL;

-- =============================================================================
-- BUSINESS RULE VALIDATIONS
-- =============================================================================

AUDIT (name business_rule_validations);
SELECT * FROM @this_model
WHERE revenue < 0
   OR order_count < 0
   OR (order_count = 0 AND revenue > 0);  -- Revenue without orders

-- =============================================================================
-- CALCULATION VALIDATIONS
-- =============================================================================

AUDIT (name calculation_validations);
SELECT * FROM @this_model
WHERE ABS(average_order_value - (revenue / NULLIF(order_count, 0))) > 0.01;
```

---

### 5.7 Inline Audit Anti-Patterns

**INCORRECT: Too many inline audits**
```sql
-- DON'T DO THIS - Too many inline audits (10+)
MODEL (
  name sales.orders,
  assertions (audit1, audit2, audit3, audit4, audit5, audit6, audit7, audit8, audit9, audit10, audit11, audit12)
);

SELECT * FROM ...;

AUDIT (name audit1); SELECT ...;
AUDIT (name audit2); SELECT ...;
AUDIT (name audit3); SELECT ...;
-- ... 12 total audits ...

-- RESULT: Model file is 500+ lines, hard to navigate
```

**CORRECT: Move to file-based**
```sql
-- Create audits/sales/orders.sql with the 12 audits
-- Keep model file clean

MODEL (
  name sales.orders,
  assertions (
    orders_completeness,
    orders_validity,
    orders_calculations,
    orders_referential_integrity
    -- Only 4 references, but 12+ actual audits in audits/sales/orders.sql
  )
);

SELECT * FROM ...;
```

**INCORRECT: Generic inline audits**
```sql
-- DON'T DO THIS - These should be in audits/common/
MODEL (name dim.products, assertions (check_not_null));
SELECT * FROM ...;

AUDIT (name check_not_null);
SELECT * FROM @this_model WHERE product_id IS NULL;
```

**CORRECT: Use built-in or file-based**
```sql
MODEL (
  name dim.products,
  assertions (not_null(columns := (product_id)))  -- Built-in
);
SELECT * FROM ...;
```

[↑ Back to Top](#chapter-04-audits)

---

## 6. Advanced Audit Patterns

This section covers complex audit patterns for sophisticated data validation scenarios.

### 6.1 Referential Integrity Checks

Validate foreign key relationships using JOINs:

**Basic referential integrity:**
```sql
-- audits/referential/customer_orders.sql
AUDIT (name valid_customer_references);

SELECT o.*
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL  -- Separate null check
  AND c.customer_id IS NULL;      -- Customer doesn't exist
```

**Multi-column foreign keys:**
```sql
AUDIT (name valid_product_location_references);

SELECT ol.*
FROM @this_model ol
LEFT JOIN dim.product_locations pl 
  ON ol.product_id = pl.product_id 
  AND ol.warehouse_id = pl.warehouse_id
WHERE ol.product_id IS NOT NULL
  AND ol.warehouse_id IS NOT NULL
  AND pl.product_id IS NULL;
```

**Conditional referential integrity:**
```sql
-- Only certain statuses require customer reference
AUDIT (name conditional_customer_reference);

SELECT o.*
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE o.status IN ('completed', 'shipped')  -- Only these statuses
  AND o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;
```

**Temporal referential integrity:**
```sql
-- Order date must be within customer's active period
AUDIT (name temporal_customer_reference);

SELECT o.*
FROM @this_model o
JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE o.order_date < c.first_purchase_date
   OR (c.last_purchase_date IS NOT NULL AND o.order_date > c.last_purchase_date);
```

---

### 6.2 Multi-Column Business Logic

Validate complex relationships between multiple columns:

**Date ordering:**
```sql
AUDIT (name valid_date_sequence);

SELECT * FROM @this_model
WHERE order_date > CURRENT_DATE
   OR (shipped_date IS NOT NULL AND shipped_date < order_date)
   OR (delivered_date IS NOT NULL AND delivered_date < shipped_date)
   OR (cancelled_date IS NOT NULL AND cancelled_date < order_date);
```

**Calculated fields validation:**
```sql
AUDIT (name revenue_calculation_valid);

SELECT 
  order_id,
  subtotal,
  discount_amount,
  tax_amount,
  shipping_cost,
  total_amount,
  (subtotal - discount_amount + tax_amount + shipping_cost) AS calculated_total,
  ABS(total_amount - (subtotal - discount_amount + tax_amount + shipping_cost)) AS difference
FROM @this_model
WHERE ABS(total_amount - (subtotal - discount_amount + tax_amount + shipping_cost)) > 0.01;
```

**Conditional logic:**
```sql
AUDIT (name conditional_business_rules);

SELECT * FROM @this_model
WHERE 
  -- Premium customers get free shipping
  (customer_tier = 'premium' AND shipping_cost > 0)
  
  -- Orders over $100 get discount
  OR (subtotal > 100 AND discount_amount = 0)
  
  -- Cancelled orders shouldn't have shipped/delivered dates
  OR (status = 'cancelled' AND (shipped_date IS NOT NULL OR delivered_date IS NOT NULL))
  
  -- Delivered orders must have both shipped and delivered dates
  OR (status = 'delivered' AND (shipped_date IS NULL OR delivered_date IS NULL));
```

**Percentage validations:**
```sql
AUDIT (name percentage_consistency);

SELECT * FROM @this_model
WHERE 
  -- Discount percentage should match discount amount
  ABS(discount_percent - (discount_amount / NULLIF(subtotal, 0))) > 0.001
  
  -- Tax percentage should match tax amount
  OR ABS(tax_percent - (tax_amount / NULLIF(subtotal, 0))) > 0.001
  
  -- Margin percentage should match margin amount
  OR ABS(margin_percent - ((revenue - cost) / NULLIF(revenue, 0))) > 0.001;
```

---

### 6.3 Cross-Model Validation

Validate data consistency across multiple models:

**Aggregate consistency:**
```sql
AUDIT (name orders_match_line_items);

SELECT 
  o.order_id,
  o.total_amount AS order_total,
  SUM(li.quantity * li.unit_price) AS line_items_total,
  ABS(o.total_amount - SUM(li.quantity * li.unit_price)) AS difference
FROM @this_model o
JOIN raw.order_line_items li ON o.order_id = li.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(li.quantity * li.unit_price)) > 0.01;
```

**Count consistency:**
```sql
AUDIT (name customer_order_count_matches);

SELECT 
  c.customer_id,
  c.total_orders AS recorded_count,
  COUNT(o.order_id) AS actual_count
FROM @this_model c
LEFT JOIN sales.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.total_orders
HAVING c.total_orders != COUNT(o.order_id);
```

**Date range consistency:**
```sql
AUDIT (name date_ranges_match_detail_data);

SELECT 
  s.customer_id,
  s.first_order_date AS summary_first_date,
  s.last_order_date AS summary_last_date,
  MIN(o.order_date) AS actual_first_date,
  MAX(o.order_date) AS actual_last_date
FROM @this_model s
LEFT JOIN sales.orders o ON s.customer_id = o.customer_id
GROUP BY s.customer_id, s.first_order_date, s.last_order_date
HAVING s.first_order_date != MIN(o.order_date)
   OR s.last_order_date != MAX(o.order_date);
```

---

### 6.4 Time-Based Audits

Special considerations for incremental and time-series data:

**No gaps in time series:**
```sql
AUDIT (name no_date_gaps);

WITH expected_dates AS (
  SELECT DATE_TRUNC('day', GENERATE_SERIES(
    (SELECT MIN(order_date) FROM @this_model),
    (SELECT MAX(order_date) FROM @this_model),
    '1 day'::INTERVAL
  )) AS expected_date
)
SELECT ed.expected_date
FROM expected_dates ed
LEFT JOIN (
  SELECT DISTINCT DATE_TRUNC('day', order_date) AS order_date
  FROM @this_model
) actual ON ed.expected_date = actual.order_date
WHERE actual.order_date IS NULL;
```

**Monotonic increase validation:**
```sql
AUDIT (name cumulative_values_increase);

SELECT 
  t1.date,
  t1.cumulative_revenue,
  t2.cumulative_revenue AS previous_cumulative_revenue
FROM @this_model t1
JOIN @this_model t2 
  ON t2.date = t1.date - INTERVAL '1 day'
WHERE t1.cumulative_revenue < t2.cumulative_revenue;
```

**Late arrival data detection:**
```sql
AUDIT (name no_late_arriving_data);

-- For incremental models: ensure no data before current interval
SELECT * FROM @this_model
WHERE order_date < @start_ds
   OR order_date > @end_ds;
```

**Rolling window consistency:**
```sql
AUDIT (name rolling_average_consistency);

SELECT 
  date,
  rolling_7day_avg,
  daily_value
FROM @this_model
WHERE ABS(
  rolling_7day_avg - 
  AVG(daily_value) OVER (
    ORDER BY date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  )
) > 0.01;
```

---

### 6.5 State Transition Validation

Validate that status/state changes follow valid paths:

**Valid status transitions:**
```sql
AUDIT (name valid_status_lifecycle);

SELECT * FROM @this_model
WHERE 
  -- Pending can only transition to processing or cancelled
  (previous_status = 'pending' AND status NOT IN ('processing', 'cancelled', 'pending'))
  
  -- Processing can only transition to completed, failed, or cancelled
  OR (previous_status = 'processing' AND status NOT IN ('completed', 'failed', 'cancelled', 'processing'))
  
  -- Completed is terminal (no transitions)
  OR (previous_status = 'completed' AND status != 'completed')
  
  -- Failed can transition to processing (retry)
  OR (previous_status = 'failed' AND status NOT IN ('processing', 'failed'))
  
  -- Cancelled is terminal
  OR (previous_status = 'cancelled' AND status != 'cancelled');
```

**Status-date consistency:**
```sql
AUDIT (name status_date_consistency);

SELECT * FROM @this_model
WHERE 
  -- Shipped status requires shipped_date
  (status = 'shipped' AND shipped_date IS NULL)
  
  -- Delivered status requires both shipped_date and delivered_date
  OR (status = 'delivered' AND (shipped_date IS NULL OR delivered_date IS NULL))
  
  -- Cancelled status requires cancelled_date
  OR (status = 'cancelled' AND cancelled_date IS NULL)
  
  -- Pending/processing shouldn't have these dates
  OR (status IN ('pending', 'processing') AND (shipped_date IS NOT NULL OR delivered_date IS NOT NULL));
```

**One-way transitions:**
```sql
AUDIT (name subscription_no_reactivation);

-- Once cancelled, subscription shouldn't reactivate
SELECT 
  subscription_id,
  status,
  LAG(status) OVER (PARTITION BY subscription_id ORDER BY updated_at) AS previous_status
FROM @this_model
WHERE LAG(status) OVER (PARTITION BY subscription_id ORDER BY updated_at) = 'cancelled'
  AND status = 'active';
```

---

### 6.6 Aggregate Consistency Checks

Validate that aggregates match their detail data:

**Sum of parts equals whole:**
```sql
AUDIT (name revenue_components_sum_to_total);

SELECT * FROM @this_model
WHERE ABS(
  total_revenue - (
    product_revenue + 
    shipping_revenue + 
    tax_revenue + 
    other_revenue
  )
) > 0.01;
```

**Percentage parts sum to 100%:**
```sql
AUDIT (name category_percentages_sum_to_one);

SELECT 
  product_id,
  category_a_percent + category_b_percent + category_c_percent + other_percent AS total_percent
FROM @this_model
WHERE ABS((category_a_percent + category_b_percent + category_c_percent + other_percent) - 1.0) > 0.001;
```

**Count aggregates match:**
```sql
AUDIT (name aggregate_counts_consistent);

SELECT * FROM @this_model
WHERE total_customers != (active_customers + inactive_customers + cancelled_customers)
   OR total_orders != (completed_orders + pending_orders + cancelled_orders);
```

**Weighted averages:**
```sql
AUDIT (name weighted_average_valid);

SELECT 
  product_id,
  weighted_average_price,
  SUM(quantity * unit_price) / NULLIF(SUM(quantity), 0) AS calculated_weighted_avg
FROM @this_model
JOIN sales.order_line_items li ON @this_model.product_id = li.product_id
GROUP BY product_id, weighted_average_price
HAVING ABS(weighted_average_price - (SUM(quantity * unit_price) / NULLIF(SUM(quantity), 0))) > 0.01;
```

---

### 6.7 Statistical Outlier Detection

Beyond simple z-score, detect complex outliers:

**Inter-quartile range (IQR) method:**
```sql
AUDIT (name iqr_outlier_detection);

WITH stats AS (
  SELECT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
  FROM @this_model
),
bounds AS (
  SELECT 
    q1,
    q3,
    q3 - q1 AS iqr,
    q1 - 1.5 * (q3 - q1) AS lower_bound,
    q3 + 1.5 * (q3 - q1) AS upper_bound
  FROM stats
)
SELECT m.*
FROM @this_model m, bounds
WHERE m.amount < bounds.lower_bound
   OR m.amount > bounds.upper_bound;
```

**Moving average deviation:**
```sql
AUDIT (name moving_average_deviation);

WITH moving_stats AS (
  SELECT 
    date,
    daily_value,
    AVG(daily_value) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS moving_avg_30d,
    STDDEV(daily_value) OVER (ORDER BY date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS moving_stddev_30d
  FROM @this_model
)
SELECT *
FROM moving_stats
WHERE ABS(daily_value - moving_avg_30d) > 3 * moving_stddev_30d;
```

**Comparing to historical baseline:**
```sql
AUDIT (name deviation_from_historical_baseline);

WITH historical_stats AS (
  SELECT 
    AVG(daily_revenue) AS baseline_avg,
    STDDEV(daily_revenue) AS baseline_stddev
  FROM @this_model
  WHERE date BETWEEN @start_ds - INTERVAL '90 days' AND @start_ds - INTERVAL '1 day'
)
SELECT m.*
FROM @this_model m, historical_stats
WHERE ABS(m.daily_revenue - historical_stats.baseline_avg) > 3 * historical_stats.baseline_stddev;
```

---

### 6.8 Hierarchical Data Validation

Validate parent-child relationships:

**Parent exists:**
```sql
AUDIT (name category_parent_exists);

SELECT c.*
FROM @this_model c
LEFT JOIN @this_model p ON c.parent_category_id = p.category_id
WHERE c.parent_category_id IS NOT NULL
  AND p.category_id IS NULL;
```

**No circular references:**
```sql
AUDIT (name no_circular_category_references);

WITH RECURSIVE category_path AS (
  -- Base case: start with leaf categories
  SELECT 
    category_id,
    parent_category_id,
    ARRAY[category_id] AS path,
    1 AS depth
  FROM @this_model
  WHERE parent_category_id IS NOT NULL
  
  UNION ALL
  
  -- Recursive case: walk up the hierarchy
  SELECT 
    cp.category_id,
    c.parent_category_id,
    cp.path || c.category_id,
    cp.depth + 1
  FROM category_path cp
  JOIN @this_model c ON cp.parent_category_id = c.category_id
  WHERE c.parent_category_id IS NOT NULL
    AND NOT (c.category_id = ANY(cp.path))  -- Stop if we see a cycle
    AND cp.depth < 10  -- Prevent infinite recursion
)
SELECT *
FROM category_path
WHERE parent_category_id = ANY(path);  -- Found a cycle
```

**Hierarchy consistency:**
```sql
AUDIT (name hierarchy_level_consistency);

-- Ensure level matches actual depth in hierarchy
WITH RECURSIVE hierarchy_depth AS (
  SELECT 
    category_id,
    parent_category_id,
    level,
    1 AS actual_depth
  FROM @this_model
  WHERE parent_category_id IS NULL
  
  UNION ALL
  
  SELECT 
    c.category_id,
    c.parent_category_id,
    c.level,
    hd.actual_depth + 1
  FROM @this_model c
  JOIN hierarchy_depth hd ON c.parent_category_id = hd.category_id
)
SELECT *
FROM hierarchy_depth
WHERE level != actual_depth;
```

[↑ Back to Top](#chapter-04-audits)

---

## 7. Audit Execution and Lifecycle

### 7.1 When Audits Run

Audits execute automatically at specific points:

**1. After model execution completes**
```
Model SQL runs → Data written → Audits run immediately
```

**2. During `vulcan plan` and `vulcan run`**
```
vulcan plan → Models execute in virtual environments → Audits run → Apply promotes clean data
vulcan run → Models execute in target environments → Audits run → Blocks downstream on failure
```

**3. Not during schema changes**
```
ALTER TABLE statements → No audits run
```

---

### 7.2 Plan vs Run: Where Bad Data Lives

**This is a critical distinction that affects how you recover from audit failures.**

#### During `vulcan plan` (Development/Staging Workflow)

**Virtual Environments:**
- SQLMesh creates **isolated schemas/databases** (virtual environments)
- Models execute and write to **isolated tables**, NOT production
- Audits run against the isolated tables
- Only models that **pass audits** get promoted to production when you apply the plan

**Execution flow:**
```
vulcan plan
  → Creates virtual environment (e.g., schema: myproject__dev_123)
  → Model writes to: myproject__dev_123.sales.orders
  → Audit runs on: myproject__dev_123.sales.orders
  → ❌ Audit fails
      → Bad data stays in virtual environment
      → Production tables remain untouched ✅
      → Fix and re-plan (virtual env is disposable)
  → ✅ Audit passes
      → vulcan plan apply
      → Promotes clean data to production ✅
```

**Key benefits:**
- **Safe testing** - Production never sees bad data
- **Easy rollback** - Just don't apply the plan
- **Isolated debugging** - Inspect bad data in virtual environment without production impact

**Example:**
```bash
# Plan creates virtual environment and runs audits
vulcan plan

# Output:
# ======================================================================
# Model: sales.orders (myproject__dev_456.sales.orders)
# Status: ❌ AUDIT FAILED
# Audit: not_null
# Violations: 3 rows
# ======================================================================
# 
# Bad data is in: myproject__dev_456.sales.orders
# Production table: myproject__prod.sales.orders (unchanged ✅)

# Investigate bad data in virtual environment
SELECT * FROM myproject__dev_456.sales.orders WHERE order_id IS NULL;

# Fix source issue, then re-plan (creates new virtual env)
vulcan plan

# All audits pass ✅
vulcan plan apply  # Now promote to production
```

---

#### During `vulcan run` (Direct Execution)

**Direct Writes:**
- Models execute and write **directly to target tables** (often production)
- Audits run **after** the model has already written data
- If audit fails, bad data is **already committed** to the table

**Execution flow:**
```
vulcan run
  → Model writes directly to: myproject__prod.sales.orders
  → Data is committed ✅ (already in table)
  → Audit runs on: myproject__prod.sales.orders
  → ❌ Audit fails
      → Bad data is ALREADY in production table ⚠️
      → Downstream models are blocked ✅ (won't see bad data)
      → Must fix source and re-run to overwrite ⚠️
  → ✅ Audit passes
      → Downstream models proceed
```

**Key implications:**
- **Production impact** - Failed model's table contains bad data
- **Downstream protection** - Dependent models don't run (data doesn't propagate further)
- **Recovery required** - Must fix issue and re-run to replace bad data

**Example:**
```bash
# Run directly writes to production
vulcan run

# Output:
# ======================================================================
# Model: sales.orders
# Table updated: myproject__prod.sales.orders ✅
# Auditing...
# Status: ❌ AUDIT FAILED
# Audit: not_null
# Violations: 3 rows
# ======================================================================
# 
# ⚠️  Bad data is now in: myproject__prod.sales.orders
# ✅  Downstream models blocked: sales.daily_metrics, sales.customer_summary
# 
# Recovery steps:
# 1. Investigate: SELECT * FROM myproject__prod.sales.orders WHERE order_id IS NULL
# 2. Fix source data
# 3. Re-run: vulcan run (overwrites bad data)

# Investigate bad data (already in production)
SELECT * FROM myproject__prod.sales.orders WHERE order_id IS NULL;

# After fixing source issue
vulcan run  # Overwrites the bad data
```

---

#### Comparison: Plan vs Run

| Aspect | `vulcan plan` | `vulcan run` |
|--------|--------------|-------------|
| **Write destination** | Virtual environment (isolated) | Target environment (often production) |
| **Audit failure impact** | Bad data in isolated schema | Bad data in production table ⚠️ |
| **Production safety** | ✅ Production never sees bad data | ⚠️ Failed model's table has bad data |
| **Downstream protection** | ✅ Never promoted | ✅ Blocked from running |
| **Recovery** | Easy - don't apply plan | Must fix and re-run to overwrite |
| **Use case** | Development, staging, testing changes | Direct production updates (use cautiously) |

---

### 7.3 Audit Execution Order

Audits run in the order they're defined:

```sql
MODEL (
  name sales.orders,
  assertions (
    not_null(columns := (order_id)),      -- Runs 1st
    unique_values(columns := (order_id)), -- Runs 2nd
    accepted_range(column := amount, min_v := 0, max_v := 1000000), -- Runs 3rd
    forall(criteria := (order_date <= CURRENT_DATE))  -- Runs 4th
  )
);
```

**If any audit fails:**
- Execution halts immediately
- Subsequent audits don't run
- Downstream models don't execute

**Optimization tip:** Order audits by execution speed (fast → slow):
```sql
assertions (
  not_null(columns := (order_id)),           -- Fast: simple null check
  unique_values(columns := (order_id)),       -- Medium: GROUP BY + HAVING
  referential_integrity_check,                 -- Slow: JOIN with large table
  complex_statistical_outlier_detection        -- Slowest: multiple passes
)
```

---

### 7.4 Incremental Models and Audits

For incremental models, audits scope automatically to processed intervals:

**Example: Incremental model**
```sql
MODEL (
  name sales.daily_orders,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date
  ),
  assertions (
    not_null(columns := (order_id, amount))
  )
);

SELECT * FROM raw.orders
WHERE order_date BETWEEN @start_ds AND @end_ds;
```

**Execution on 2024-01-15:**
```
1. Model processes: WHERE order_date BETWEEN '2024-01-15' AND '2024-01-15'
2. Audit runs on: Only rows with order_date = '2024-01-15'
3. Historical data (2024-01-01 to 2024-01-14) is NOT re-audited
```

**How `@this_model` works:**
```sql
-- Your audit definition
AUDIT (name check_amounts);
SELECT * FROM @this_model WHERE amount < 0;

-- For incremental model on 2024-01-15, expands to:
SELECT * FROM (
  SELECT * FROM sales.daily_orders 
  WHERE order_date BETWEEN '2024-01-15' AND '2024-01-15'
) WHERE amount < 0;
```

**Why this matters:**
- Efficiency: Don't re-audit unchanged historical data
- Correctness: Only validate what you just processed
- Performance: Audits scale with interval size, not total table size

---

### 7.5 Full Refresh and Audits

For full refresh models, audits validate the entire table:

```sql
MODEL (
  name dim.customers,
  kind FULL,
  assertions (
    unique_values(columns := (customer_id))
  )
);

SELECT * FROM raw.customers;
```

**Every execution:**
```
1. Table is completely replaced
2. Audit runs on entire new table contents
3. All rows validated every time
```

**Performance consideration:**
- Full refresh + expensive audits = slow execution
- Use profiles instead for less critical validations
- Consider incremental models if possible

---

### 7.6 Temporarily Skipping Audits

Use `skip` flag to temporarily disable audits:

**Skip specific audit:**
```sql
-- audits/temp_disabled.sql
AUDIT (
  name experimental_check,
  skip true  -- This audit won't run
);
SELECT * FROM @this_model WHERE experimental_condition;
```

**When to skip:**
- Developing/testing a new audit
- Known data quality issue being fixed
- Temporarily expensive audit during investigation

**WARNING:** Never skip critical audits in production. Use `skip` only for development or temporary issues.

**Alternative: Comment out instead of skip**
```sql
MODEL (
  name sales.orders,
  assertions (
    not_null(columns := (order_id)),
    -- unique_values(columns := (order_id)),  -- Temporarily disabled
    accepted_range(column := amount, min_v := 0, max_v := 1000000)
  )
);
```

---

### 7.7 Audit Failure Handling

**What happens when an audit fails:**

1. **Execution halts immediately**
   - Model execution completed
   - Audit detected violations
   - Downstream models blocked

2. **Error message includes:**
   - Audit name
   - Model name
   - Number of violating rows
   - Audit SQL query

**Example error:**
```
Failure in audit 'not_null' for model 'sales.orders'.
Got 3 results, expected 0.
Query: SELECT * FROM sales.orders WHERE order_id IS NULL OR customer_id IS NULL
```

3. **Data state:**
   - Model's own table contains the bad data (already written)
   - Downstream models don't run (data doesn't propagate)
   - Source data unchanged

4. **Next steps:**
   - Investigate root cause
   - Fix source data or model logic
   - Re-run execution

---

### 7.8 Audit Performance Impact

**Audits add to execution time:**
```
Total execution time = Model execution + All audits execution
```

**Performance tips:**

**1. Keep audits simple:**
```sql
-- Fast audit
SELECT * FROM @this_model WHERE amount < 0;

-- Slow audit
SELECT * FROM @this_model t1
JOIN huge_dimension_table d ON t1.id = d.id
WHERE complex_function(d.column) = invalid_value;
```

**2. Use indexes on audited columns:**
```sql
-- If auditing customer_id frequently, add index:
CREATE INDEX idx_customer_id ON sales.orders (customer_id);

-- Audits will be faster:
SELECT * FROM @this_model WHERE customer_id IS NULL;
```

**3. Limit cross-model audits:**
```sql
-- Expensive: JOINs with large tables
AUDIT (name referential_check);
SELECT * FROM @this_model o
JOIN enormous_table e ON o.key = e.key
WHERE validation_condition;

-- Consider: Move to quality check (runs separately) or profile
```

**4. Avoid function calls in audits:**
```sql
-- Slow: Function call per row
SELECT * FROM @this_model
WHERE EXPENSIVE_UDF(column) = 'invalid';

-- Better: Pre-compute if possible
SELECT * FROM @this_model
WHERE computed_column = 'invalid';
```

[↑ Back to Top](#chapter-04-audits)

---

## 8. Troubleshooting and Debugging

### 8.1 Reading Audit Failure Messages

Audit failures provide detailed information:

**Example failure:**
```
Failure in audit 'not_null' for model 'sales.orders'.
Got 3 results, expected 0.
Query: SELECT * FROM sales.orders WHERE order_id IS NULL OR customer_id IS NULL
```

**Message components:**
1. **Audit name:** `not_null`
2. **Model name:** `sales.orders`
3. **Row count:** `Got 3 results` (3 rows violated)
4. **SQL query:** The actual audit query that found violations

---

### 8.2 Debugging Failed Audits (Step-by-Step)

**Step 1: Run the audit query manually**
```sql
-- Copy the query from error message
SELECT * FROM sales.orders 
WHERE order_id IS NULL OR customer_id IS NULL;

-- Result shows the 3 problematic rows
```

**Step 2: Add context to understand the issue**
```sql
-- Expand query to see full row context
SELECT 
  *,
  'Missing order_id' AS issue_type
FROM sales.orders 
WHERE order_id IS NULL

UNION ALL

SELECT 
  *,
  'Missing customer_id' AS issue_type
FROM sales.orders 
WHERE customer_id IS NULL;
```

**Step 3: Trace upstream to find root cause**
```sql
-- Check source data
SELECT * FROM raw.orders
WHERE order_id IS NULL OR customer_id IS NULL;

-- If source is clean, check model logic
-- Look for JOIN conditions that might create nulls
```

**Step 4: Determine fix location**
- **Source data issue:** Fix upstream system, re-run extraction
- **Model logic issue:** Update model SQL, re-run transformation
- **Audit logic issue:** Audit is too strict, adjust audit query

---

### 8.3 Common Audit Issues

**Issue 1: Audit fails intermittently**

**Cause:** Time-dependent data or race conditions

**Solution:**
```sql
-- Bad: Checks against current time (changes every second)
SELECT * FROM @this_model 
WHERE created_at > CURRENT_TIMESTAMP;

-- Good: Check against model's time range
SELECT * FROM @this_model
WHERE created_at > @end_ds + INTERVAL '1 hour';
```

**Issue 2: Audit too strict (fails on edge cases)**

**Cause:** Missing business context

**Solution:**
```sql
-- Too strict: Fails on valid $0 free-tier products
SELECT * FROM @this_model WHERE price <= 0;

-- Better: Account for free-tier
SELECT * FROM @this_model 
WHERE price <= 0 
  AND product_tier != 'free';
```

**Issue 3: Audit passes but data still wrong**

**Cause:** Inverted logic

**Solution:**
```sql
-- Wrong: Returns good data
SELECT * FROM @this_model WHERE price > 0;  -- Audit always fails!

-- Right: Returns bad data
SELECT * FROM @this_model WHERE price <= 0;  -- Audit passes if no bad data
```

**Issue 4: Performance issues**

**Cause:** Expensive audit queries

**Solution:**
```sql
-- Slow: Full table scan with function
SELECT * FROM @this_model
WHERE EXPENSIVE_FUNCTION(column) = 'invalid';

-- Fast: Use indexed column or pre-computed value
SELECT * FROM @this_model
WHERE computed_flag = 'invalid';
```

---

### 8.4 Fixing Failed Audits

**Scenario A: Fix source data**
```
1. Identify bad data in source system
2. Correct at source
3. Re-extract data
4. Re-run Vulcan model
5. Audit passes
```

**Scenario B: Fix model logic**
```sql
-- Before: Model creates nulls via LEFT JOIN
SELECT o.*, c.customer_name
FROM raw.orders o
LEFT JOIN raw.customers c ON o.customer_id = c.id;
-- Result: customer_name is NULL for some rows

-- After: Use INNER JOIN or handle nulls
SELECT o.*, COALESCE(c.customer_name, 'Unknown') AS customer_name
FROM raw.orders o
LEFT JOIN raw.customers c ON o.customer_id = c.id;
```

**Scenario C: Adjust audit**
```sql
-- Before: Too strict
SELECT * FROM @this_model WHERE discount_amount > 0;

-- After: Account for legitimate discounts
SELECT * FROM @this_model 
WHERE discount_amount > 0 
  AND discount_amount > order_amount;  -- Only invalid discounts
```

---

### 8.5 Testing Audits Before Deployment

**Test with `skip` flag during development:**
```sql
AUDIT (
  name new_audit_under_development,
  skip true  -- Won't run yet
);
SELECT * FROM @this_model WHERE new_condition;
```

**Test audit query separately:**
```sql
-- Run audit query manually on existing data
SELECT * FROM sales.orders  -- Replace @this_model with actual table
WHERE new_condition;

-- Verify it finds issues (or doesn't) as expected
```

**Test with small dataset:**
```sql
-- Add WHERE clause to limit scope during testing
AUDIT (name test_audit);
SELECT * FROM @this_model
WHERE condition
  AND order_date >= '2024-01-01'  -- Temporary: test on recent data only
LIMIT 100;
```

[↑ Back to Top](#chapter-04-audits)

---

## 9. Best Practices

### 9.1 Audit Logic Patterns

**Always query for bad data (inverted logic):**
```sql
-- Correct
SELECT * FROM @this_model WHERE price <= 0;  -- Find violations

-- Incorrect
SELECT * FROM @this_model WHERE price > 0;   -- Find good data (backwards!)
```

**Use clear, explicit conditions:**
```sql
-- Vague
SELECT * FROM @this_model WHERE status != 'good';

-- Clear
SELECT * FROM @this_model 
WHERE status NOT IN ('completed', 'shipped', 'delivered');
```

---

### 9.2 Audit Granularity Strategy

**Start broad, add specificity over time:**

**Phase 1: Essential validations**
```sql
assertions (
  not_null(columns := (order_id, customer_id)),
  unique_values(columns := (order_id))
)
```

**Phase 2: Add business rules**
```sql
assertions (
  not_null(columns := (order_id, customer_id)),
  unique_values(columns := (order_id)),
  accepted_range(column := amount, min_v := 0, max_v := 1000000)
)
```

**Phase 3: Add complex validations**
```sql
assertions (
  not_null(columns := (order_id, customer_id)),
  unique_values(columns := (order_id)),
  accepted_range(column := amount, min_v := 0, max_v := 1000000),
  forall(criteria := (order_date <= shipped_date))
)
```

---

### 9.3 Performance Optimization

**1. Order audits by cost (fast first)**
```sql
assertions (
  not_null(columns := (id)),           -- Fast
  unique_values(columns := (id)),       -- Medium
  referential_integrity_check           -- Slow
)
```

**2. Add indexes on audited columns**
```sql
CREATE INDEX idx_customer_id ON orders (customer_id);
CREATE INDEX idx_order_date ON orders (order_date);
```

**3. Avoid expensive operations**
```sql
-- Slow
SELECT * FROM @this_model WHERE REGEXP_MATCH(email, complex_pattern);

-- Fast
SELECT * FROM @this_model WHERE email NOT LIKE '%@%';
```

---

### 9.4 Naming Conventions

**Use descriptive, action-oriented names:**
- `assert_positive_revenue`
- `validate_customer_exists`
- `check_date_ordering`
- `ensure_email_format`
- `verify_calculations`

**Avoid:**
- `audit1`, `check`, `test`, `validation`

---

### 9.5 Audit Coverage Strategy

**Critical (always audit):**
- Primary keys: `not_null` + `unique_values`
- Foreign keys: referential integrity
- Non-negative amounts: `forall(criteria := (amount >= 0))`
- Required fields: `not_null`

**Important (audit frequently):**
- Enums: `accepted_values`
- Ranges: `accepted_range`
- Formats: `valid_email`, `valid_url`

**Nice-to-have (use profiles first):**
- String lengths
- Statistical bounds
- Format patterns

---

### 9.6 Organizing Audits by Domain

**Recommended structure:**
```
audits/
├── common/           # Reusable
│   ├── nulls.sql
│   ├── ranges.sql
│   └── formats.sql
├── sales/            # Domain-specific
│   ├── orders.sql
│   └── revenue.sql
└── finance/
    └── transactions.sql
```

[↑ Back to Top](#chapter-04-audits)

---

## 10. Real-World Examples

### 10.1 E-commerce Order Validation

**Complete order model with audits:**
```sql
MODEL (
  name sales.orders,
  grain order_id,
  references (customer_id),
  assertions (
    -- Completeness
    not_null(columns := (order_id, customer_id, order_date, amount)),
    
    -- Uniqueness
    unique_values(columns := (order_id)),
    
    -- Business rules
    forall(criteria := (
      amount > 0,
      discount_amount >= 0,
      discount_amount <= amount,
      tax_amount >= 0,
      order_date <= CURRENT_DATE,
      shipped_date IS NULL OR shipped_date >= order_date,
      delivered_date IS NULL OR delivered_date >= shipped_date
    )),
    
    -- Status logic
    valid_order_status,
    
    -- Referential integrity
    valid_customer_reference
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  shipped_date,
  delivered_date,
  amount,
  discount_amount,
  tax_amount,
  status
FROM raw.orders;

AUDIT (name valid_order_status);
SELECT * FROM @this_model
WHERE (status = 'shipped' AND shipped_date IS NULL)
   OR (status = 'delivered' AND (shipped_date IS NULL OR delivered_date IS NULL))
   OR (status NOT IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'));

AUDIT (name valid_customer_reference);
SELECT o.*
FROM @this_model o
LEFT JOIN dim.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
```

---

### 10.2 Financial Transaction Audits

```sql
MODEL (
  name finance.transactions,
  grain transaction_id,
  assertions (
    not_null(columns := (transaction_id, account_id, transaction_date, amount)),
    unique_values(columns := (transaction_id)),
    forall(criteria := (
      transaction_date <= CURRENT_DATE,
      ABS(amount) > 0,  -- No zero transactions
      (transaction_type = 'debit' AND amount < 0) OR 
      (transaction_type = 'credit' AND amount > 0)  -- Sign matches type
    )),
    balanced_transactions  -- Credits = Debits
  )
);

SELECT * FROM raw.transactions;

AUDIT (name balanced_transactions);
-- For each account, ensure sum of transactions = 0 (balanced)
SELECT 
  account_id,
  transaction_date,
  SUM(amount) AS net_amount
FROM @this_model
GROUP BY account_id, transaction_date
HAVING ABS(SUM(amount)) > 0.01;  -- Allow rounding difference
```

---

### 10.3 User Registration Validation

```sql
MODEL (
  name users.registrations,
  grain user_id,
  assertions (
    not_null(columns := (user_id, email, signup_date)),
    unique_values(columns := (user_id, email)),
    valid_email(column := email),
    forall(criteria := (
      signup_date <= CURRENT_DATE,
      age >= 13,  -- Legal requirement
      age <= 120  -- Reasonable maximum
    )),
    valid_country_codes
  )
);

SELECT * FROM raw.user_registrations;

AUDIT (name valid_country_codes);
SELECT * FROM @this_model u
LEFT JOIN dim.countries c ON u.country_code = c.code
WHERE u.country_code IS NOT NULL
  AND c.code IS NULL;
```

[↑ Back to Top](#chapter-04-audits)

---

## 11. Quick Reference

### 11.1 Most Common Audits (Cheat Sheet)

| Use Case | Audit | Example |
|----------|-------|---------|
| No NULLs | `not_null` | `not_null(columns := (id, email))` |
| Unique | `unique_values` | `unique_values(columns := (id))` |
| In list | `accepted_values` | `accepted_values(column := status, is_in := ('A', 'B'))` |
| Numeric range | `accepted_range` | `accepted_range(column := age, min_v := 0, max_v := 120)` |
| Positive | `forall` | `forall(criteria := (amount > 0))` |
| Email format | `valid_email` | `valid_email(column := email)` |
| No duplicate combo | `unique_combination_of_columns` | `unique_combination_of_columns(columns := (user, date))` |
| Min rows | `number_of_rows` | `number_of_rows(threshold := 100)` |
| Not empty string | `not_empty_string` | `not_empty_string(column := name)` |
| Custom logic | `forall` | `forall(criteria := (start_date < end_date))` |

---

### 11.2 Syntax Quick Reference

**Built-in audit:**
```sql
MODEL (
  name schema.table,
  assertions (
    not_null(columns := (col1, col2))
  )
);
```

**Custom audit (file-based):**
```sql
-- audits/my_audit.sql
AUDIT (name my_audit, dialect postgres);
SELECT * FROM @this_model WHERE bad_condition;

-- In model
MODEL (name schema.table, assertions (my_audit));
```

**Inline audit:**
```sql
MODEL (name schema.table, assertions (my_audit));
SELECT * FROM source;

AUDIT (name my_audit);
SELECT * FROM @this_model WHERE bad_condition;
```

**Parameterized audit:**
```sql
AUDIT (name check_threshold);
SELECT * FROM @this_model WHERE @column > @threshold;

-- Usage
assertions (check_threshold(column := amount, threshold := 1000))
```

---

### 11.3 Decision Tree

```
Need data validation?
│
├─ Must BLOCK bad data immediately?
│  └─ YES → Use AUDIT
│     ├─ Reusable? → audits/common/*.sql
│     └─ Model-specific? → Inline audit
│
├─ Need historical tracking?
│  └─ Use QUALITY CHECK (YAML)
│
└─ Just observing trends?
   └─ Use PROFILE
```

---

### 11.4 Complete Audit Index (Alphabetical)

**Built-in audits (29 total):**
- [`accepted_range`](#accepted_range)
- [`accepted_values`](#accepted_values)
- [`at_least_one`](#at_least_one)
- [`chi_square`](#chi_square)
- [`forall`](#forall)
- [`kl_divergence`](#kl_divergence)
- [`match_like_pattern_list`](#match_like_pattern_list)
- [`match_regex_pattern_list`](#match_regex_pattern_list)
- [`mean_in_range`](#mean_in_range)
- [`mutually_exclusive_ranges`](#mutually_exclusive_ranges)
- [`not_accepted_values`](#not_accepted_values)
- [`not_constant`](#not_constant)
- [`not_empty_string`](#not_empty_string)
- [`not_match_like_pattern_list`](#not_match_like_pattern_list)
- [`not_match_regex_pattern_list`](#not_match_regex_pattern_list)
- [`not_null`](#not_null)
- [`not_null_proportion`](#not_null_proportion)
- [`number_of_rows`](#number_of_rows)
- [`sequential_values`](#sequential_values)
- [`stddev_in_range`](#stddev_in_range)
- [`string_length_between`](#string_length_between)
- [`string_length_equal`](#string_length_equal)
- [`unique_combination_of_columns`](#unique_combination_of_columns)
- [`unique_values`](#unique_values)
- [`valid_email`](#valid_email)
- [`valid_http_method`](#valid_http_method)
- [`valid_url`](#valid_url)
- [`valid_uuid`](#valid_uuid)
- [`z_score`](#z_score)

[↑ Back to Top](#chapter-04-audits)

---

## 12. Summary and Next Steps

### Key Takeaways

1. **Audits = Data Warehouse Constraints**
   - Similar to OLTP constraints but block downstream flow instead of INSERT/UPDATE
   - Always blocking in Vulcan (no warning-only mode)

2. **Three Quality Mechanisms**
   - **Audits**: Critical, blocking validation
   - **Quality Checks**: Monitoring with history
   - **Profiles**: Trend tracking

3. **Query for Bad Data**
   - Audits use inverted logic: return violations
   - `SELECT * FROM @this_model WHERE bad_condition`

4. **29 Built-in Audits**
   - Completeness, uniqueness, validity, strings, patterns, statistics
   - Use `forall` for custom logic

5. **Custom Audits**
   - File-based: Reusable in `audits/` directory
   - Inline: Model-specific within model file
   - Parameterized: Use `@column`, `@threshold`, etc.

6. **Performance Matters**
   - Order audits fast → slow
   - Add indexes on audited columns
   - Keep audits simple

7. **Layer by Criticality**
   - Critical: PKs, FKs, non-negative amounts
   - Important: Enums, ranges, formats
   - Nice-to-have: Start with profiles

---

### Related Topics

**For deeper learning:**

1. **Quality Checks** - Scheduled monitoring with historical tracking
2. **Profiles** - Statistical trend analysis
3. **Tests** - Unit tests for model logic (run before audits)
4. **Semantic Layer** - How audits integrate with semantic validations

---

### Next Steps

**Immediate:**
1. Add basic audits to your critical models (`not_null`, `unique_values`)
2. Review existing models for audit opportunities
3. Create `audits/` directory and organize by domain

**Short-term:**
4. Implement referential integrity audits
5. Add business rule validations with `forall`
6. Set up profiles to understand data patterns

**Long-term:**
7. Build comprehensive audit coverage across all models
8. Integrate audits into CI/CD
9. Monitor audit performance and optimize

---

### Final Thoughts

Audits are your first line of defense against bad data. They:
- Catch issues immediately during transformation
- Prevent bad data from propagating downstream
- Build confidence in your data products
- Document expected data characteristics

Start simple with critical validations, then expand coverage over time. Your future self (and downstream consumers) will thank you.

**Congratulations! You've completed the Audits chapter.**

---

## Appendix: Audit Catalog

For a complete list of all 29 built-in audits with parameters, see [Section 3: Built-in Audits Reference](#3-built-in-audits-reference).

[↑ Back to Top](#chapter-04-audits)

---

