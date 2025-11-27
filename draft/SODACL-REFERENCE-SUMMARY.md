# SodaCL Reference Summary & ODPS Mapping

**Complete reference of all SodaCL check types and their mapping to ODPS v3.1 dimensions**

**Source:** [SodaCL Reference Documentation](https://docs.soda.io/sodacl-reference)

> **Note on Veracity:** All links have been validated against the official SodaCL documentation (as of 2024-11-14). Note that some advanced features like full reconciliation checks may be Vulcan-specific implementations built on top of SodaCL primitives like cross checks.

---

## Table of Contents

1. [All SodaCL Metrics & Check Types](#all-sodacl-metrics--check-types)
2. [ODPS Dimension Mapping](#odps-dimension-mapping)
3. [Coverage by Dimension](#coverage-by-dimension)

---

## All SodaCL Metrics & Check Types

### 1. missing_count(column)

**Type:** Metric  
**Reference:** [Missing Metrics](https://docs.soda.io/sodacl-reference/missing-metrics)  
**Description:** Counts the number of missing (NULL or custom-defined) values in a column  
**Supports:** Single column  
**Configuration:**
- `missing values: [list]` - Define custom missing values
- `missing regex: pattern` - Pattern-based missing detection

**Example:**
```yaml
- missing_count(email) = 0
- missing_count(status):
    missing values: [unknown, n/a, '']
```

---

### 2. missing_percent(column)

**Type:** Metric  
**Reference:** [Missing Metrics](https://docs.soda.io/sodacl-reference/missing-metrics)  
**Description:** Calculates percentage of missing values (0-100 scale)  
**Supports:** Single column  
**Configuration:**
- `missing values: [list]` - Define custom missing values
- `missing regex: pattern` - Pattern-based missing detection

**Example:**
```yaml
- missing_percent(phone) < 10%
- missing_percent(status):
    missing values: [unknown, n/a]
```

---

### 3. row_count

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Counts total number of rows in a dataset  
**Supports:** Table-level (no column argument)  
**Configuration:** None

**Example:**
```yaml
- row_count > 1000
- row_count between 1000 and 100000
```

---

### 4. invalid_count(column)

**Type:** Metric  
**Reference:** [Validity Metrics](https://docs.soda.io/sodacl-reference/validity-metrics)  
**Description:** Counts the number of invalid values based on validity rules  
**Supports:** Single column  
**Configuration:**
- `valid format: format_name` - Built-in format validators
- `valid values: [list]` - Enum validation
- `valid regex: pattern` - Pattern-based validation

**Example:**
```yaml
- invalid_count(email) = 0:
    valid format: email
- invalid_count(status) = 0:
    valid values: [active, churned, suspended]
```

---

### 5. invalid_percent(column)

**Type:** Metric  
**Reference:** [Validity Metrics](https://docs.soda.io/sodacl-reference/validity-metrics)  
**Description:** Percentage of invalid values (0-100 scale)  
**Supports:** Single column  
**Configuration:**
- `valid format: format_name`
- `valid values: [list]`
- `valid regex: pattern`

**Example:**
```yaml
- invalid_percent(phone) < 5:
    valid format: phone number
```

---

### 6. valid_count(column)

**Type:** Metric  
**Reference:** [Validity Metrics](https://docs.soda.io/sodacl-reference/validity-metrics)  
**Description:** Counts the number of valid values  
**Supports:** Single column  
**Configuration:**
- `valid format: format_name`
- `valid values: [list]`
- `valid regex: pattern`

**Example:**
```yaml
- valid_count(status) > 100:
    valid values: [active, churned]
```

---

### 7. valid_percent(column)

**Type:** Metric  
**Reference:** [Validity Metrics](https://docs.soda.io/sodacl-reference/validity-metrics)  
**Description:** Percentage of valid values (0-100 scale)  
**Supports:** Single column  
**Configuration:**
- `valid format: format_name`
- `valid values: [list]`
- `valid regex: pattern`

**Example:**
```yaml
- valid_percent(email) >= 95:
    valid format: email
```

---

### 8. duplicate_count(column[, column2, ...])

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Counts the number of duplicate values  
**Supports:** Single or multiple columns (composite keys)  
**Configuration:** None

**Example:**
```yaml
- duplicate_count(email) = 0
- duplicate_count(customer_id, order_date) = 0
```

---

### 9. duplicate_percent(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Percentage of duplicate values (0-100 scale)  
**Supports:** Single column  
**Configuration:** None

**Example:**
```yaml
- duplicate_percent(phone) < 2%
```

---

### 10. distinct_count(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Counts the number of distinct values  
**Supports:** Single column  
**Configuration:** None

**Example:**
```yaml
- distinct_count(customer_id) > 1000
```

---

### 11. min(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Minimum value in a column  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- min(revenue) >= 0
- min(age) > 0
```

---

### 12. max(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Maximum value in a column  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- max(age) <= 120
- max(price) < 10000
```

---

### 13. avg(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Average value in a column  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- avg(order_value) between 50 and 500
```

---

### 14. sum(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Sum of all values in a column  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- sum(daily_revenue) > 100000
```

---

### 15. stddev(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Standard deviation of values  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- stddev(order_value) < 100
```

---

### 16. variance(column)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Variance of values  
**Supports:** Numeric columns  
**Configuration:** None

**Example:**
```yaml
- variance(revenue) < 10000
```

---

### 17. percentile(column, value)

**Type:** Metric  
**Reference:** [Numeric Metrics](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Percentile value (e.g., median = 0.5)  
**Supports:** Numeric columns  
**Configuration:** Percentile value (0.0-1.0)

**Example:**
```yaml
- percentile(revenue, 0.5) > 1000  # Median
- percentile(age, 0.95) < 100      # 95th percentile
```

---

### 18. failed rows

**Type:** Check  
**Reference:** [Failed Rows Checks](https://docs.soda.io/sodacl-reference/failed-rows-checks)  
**Description:** Custom SQL validation with sample collection  
**Supports:** Custom SQL queries  
**Configuration:**
- `fail query: |` - Full SELECT statement
- `fail condition:` - Simple WHERE clause
- `samples limit: N` - Sample size control
- `samples columns: [...]` - Column selection

**Example:**
```yaml
- failed rows:
    name: negative_revenue
    fail query: |
      SELECT * FROM orders WHERE revenue < 0
    samples limit: 10
```

---

### 19. freshness(column)

**Type:** Check  
**Reference:** [Freshness Checks](https://docs.soda.io/sodacl-reference/freshness-checks)  
**Description:** Validates data recency based on timestamp  
**Supports:** Timestamp/date columns  
**Configuration:** Time units: `s`, `m`, `h`, `d`, `w`

**Example:**
```yaml
- freshness(updated_at) < 1d
- freshness(last_sync) between 1h and 24h
```

---

### 20. schema

**Type:** Check  
**Reference:** [Schema Checks](https://docs.soda.io/sodacl-reference/schema-checks)  
**Description:** Validates table structure and schema evolution  
**Supports:** Table-level  
**Configuration:**
- `warn:` or `fail:` - Action on violation
- `when schema changes: any` - Detect any change
- `when required column missing: [...]` - Required columns
- `when wrong column type:` - Type validation
- `when forbidden column present: [...]` - Forbidden columns

**Example:**
```yaml
- schema:
    warn:
      when schema changes: any
    fail:
      when required column missing: [user_id, email]
```

---

### 21. reference

**Type:** Check  
**Reference:** [Reference Checks](https://docs.soda.io/sodacl-reference/reference-checks)  
**Description:** Foreign key validation (referential integrity)  
**Supports:** Column relationships  
**Configuration:**
- `column:` - Column to validate
- `referenced_table:` - Target table
- `referenced_column:` - Target column

**Example:**
```yaml
- reference:
    column: customer_id
    referenced_table: customers
    referenced_column: customer_id
    name: valid_customer_references
```

---

### 22. cross check

**Type:** Check  
**Reference:** [Cross Checks](https://docs.soda.io/sodacl-reference/cross-row-checks)  
**Description:** Compare row counts between datasets in the same or different data sources  
**Supports:** Row count comparison only  
**Configuration:**
- `row_count same as dataset_name` - Same data source
- `row_count same as dataset_name in data_source_name` - Different data source
- Both data sources must be configured in Soda

**Example:**
```yaml
checks for dim_customer:
  # Same data source
  - row_count same as dim_department_group
  
  # Different data source
  - row_count same as retail_customers in aws_postgres_retail:
      name: Cross check customer datasets
```

---

### 23. reconciliation

**Type:** Check  
**Reference:** [SodaCL Reference](https://docs.soda.io/sodacl-reference) *(Note: No dedicated reconciliation page found)*  
**Description:** Source-to-target data reconciliation and cross-dataset validation  
**Supports:** Cross-table/dataset comparisons  
**Configuration:**
- May use cross checks (`row_count same as`) for basic reconciliation
- Full reconciliation features may be Vulcan-specific or use cross checks
- See cross checks (#22) for row count comparison syntax

**Example:**
```yaml
# Basic row count reconciliation (using cross checks)
- row_count same as other_dataset

# Note: Advanced reconciliation may be Vulcan-specific
# For SodaCL, use cross checks for dataset comparisons
```

---

### 24. distribution check

**Type:** Check  
**Reference:** [Distribution Checks](https://docs.soda.io/sodacl-reference/distribution-checks)  
**Description:** Analyze value distributions and detect drift  
**Supports:** Statistical distribution analysis  
**Configuration:**
- `column:` - Column to analyze
- `method: ks_test` - Statistical test
- `reference_dataset:` - Baseline dataset
- `percentiles: [...]` - Percentile checks
- `expected_values: [...]` - Expected values

**Example:**
```yaml
- distribution check:
    column: revenue
    method: ks_test
    reference_dataset: revenue_baseline
```

---

### 25. anomaly detection for

**Type:** Check  
**Reference:** [Anomaly Detection Checks](https://docs.soda.io/sodacl-reference/anomaly-detection-checks) (deprecated but Vulcan uses it)  
**Description:** ML-based anomaly detection using historical data  
**Supports:** Metrics (row_count, avg, sum, etc.)  
**Configuration:** Requires historical check results

**Example:**
```yaml
- anomaly detection for row_count
- anomaly detection for avg(revenue)
- anomaly detection for distinct_count(customer_id)
```

---

### 26. anomaly score for

**Type:** Check  
**Reference:** [Anomaly Score Checks](https://docs.soda.io/sodacl-reference/anomaly-score-checks) (deprecated but Vulcan uses it)  
**Description:** Numeric anomaly scoring (0.0-1.0) with threshold  
**Supports:** Metrics with numeric threshold  
**Configuration:** Score threshold (0.0 = normal, 1.0 = highly anomalous)

**Example:**
```yaml
- anomaly score for row_count < 0.5
- anomaly score for avg(revenue) < 0.7
```

---

### 27. change for

**Type:** Check  
**Reference:** [Numeric Metrics - Change Over Time](https://docs.soda.io/sodacl-reference/numeric-metrics)  
**Description:** Detect changes compared to historical baseline  
**Supports:** Any numeric metric  
**Configuration:** Percentage threshold

**Example:**
```yaml
- change for row_count >= -50%
- change for avg(revenue) >= -20%
```

---

### 28. group evolution

**Type:** Check  
**Reference:** [Group Evolution Checks](https://docs.soda.io/sodacl-reference/group-evolution)  
**Description:** Track how groups change over time  
**Supports:** Categorical columns  
**Configuration:**
- `groups:` - Column(s) to track
- `threshold:` - Number of changes to alert

**Example:**
```yaml
- group evolution:
    groups: plan_type
    threshold: 5
```

---

### 29. for each

**Type:** Pattern  
**Reference:** [For Each](https://docs.soda.io/sodacl-reference/for-each)  
**Description:** Apply same check across multiple columns  
**Supports:** Any column-level check  
**Configuration:**
- `columns: [...]` - Columns to check
- `checks:` - Check definitions with `{column}` placeholder

**Example:**
```yaml
- for each column:
    columns: [email, backup_email, admin_email]
    checks:
      - invalid_count({column}) = 0:
          valid format: email
```

---

### 30. group by

**Type:** Pattern  
**Reference:** [Group By](https://docs.soda.io/sodacl-reference/group-by)  
**Description:** Check metrics within groups  
**Supports:** Any check with grouping  
**Configuration:**
- Group column name
- Check definitions with `{group}` placeholder

**Example:**
```yaml
- group by plan_type:
    checks:
      - row_count > 10:
          name: "sufficient_{group}_users"
```

---

### 31. filter

**Type:** Configuration  
**Reference:** [Filters and Variables](https://docs.soda.io/sodacl-reference/filters)  
**Description:** Apply checks to data subset  
**Supports:** Dataset-level filter  
**Configuration:** WHERE clause condition

**Example:**
```yaml
checks:
  table_name:
    filter: "status = 'active'"
    completeness:
      - missing_count(email) = 0
```

---

### 32. Variables

**Type:** Configuration  
**Reference:** [Filters and Variables](https://docs.soda.io/sodacl-reference/filters)  
**Description:** Dynamic variable substitution  
**Supports:** Any check  
**Configuration:** `${variable_name}` syntax

**Example:**
```yaml
- row_count > 0:
    filter: "created_at >= CAST('${run_date}' AS DATE)"
```

---

## ODPS Dimension Mapping

| SodaCL Check/Metric | ODPS Dimension(s) | Priority | Notes |
|---------------------|-------------------|----------|-------|
| `missing_count` | **Completeness** | 🔴 HIGH | Required data presence |
| `missing_percent` | **Completeness** | 🔴 HIGH | Percentage-based completeness |
| `row_count` | **Completeness**, Coverage | 🔴 HIGH | Volume validation |
| `invalid_count` | **Validity** | 🔴 HIGH | Format/pattern validation |
| `invalid_percent` | **Validity** | 🔴 HIGH | Percentage-based validity |
| `valid_count` | **Validity** | 🟡 MEDIUM | Positive validation |
| `valid_percent` | **Validity** | 🟡 MEDIUM | Percentage-based positive validation |
| `duplicate_count` | **Uniqueness** | 🔴 HIGH | Duplicate detection |
| `duplicate_percent` | **Uniqueness** | 🟡 MEDIUM | Percentage-based duplicates |
| `distinct_count` | **Uniqueness**, Accuracy | 🟡 MEDIUM | Cardinality validation |
| `failed rows` | **Validity**, All | 🔴 HIGH | Custom SQL validation (any dimension) |
| `freshness` | **Timeliness** | 🟡 MEDIUM | Data recency |
| `change for` | **Timeliness** | 🟡 MEDIUM | Detect degradation |
| `group evolution` | **Timeliness**, Consistency | 🟢 LOW | Track group changes |
| `schema` | **Conformity** | 🟡 MEDIUM | Structure validation |
| `min` | **Accuracy**, Validity | 🟡 MEDIUM | Range validation |
| `max` | **Accuracy**, Validity | 🟡 MEDIUM | Range validation |
| `avg` | **Accuracy** | 🟡 MEDIUM | Average validation |
| `sum` | **Accuracy** | 🟡 MEDIUM | Aggregate validation |
| `stddev` | **Accuracy** | 🟢 LOW | Consistency/stability |
| `variance` | **Accuracy** | 🟢 LOW | Consistency/stability |
| `percentile` | **Accuracy** | 🟡 MEDIUM | Distribution validation |
| `anomaly detection` | **Accuracy** | 🔴 HIGH | ML-based anomaly detection |
| `anomaly score` | **Accuracy** | 🔴 HIGH | Numeric anomaly scoring |
| `distribution check` | **Accuracy** | 🟡 MEDIUM | Distribution drift |
| `reference` | **Consistency** | 🟡 MEDIUM | Foreign key validation |
| `cross check` | **Coverage**, Consistency | 🟡 MEDIUM | Row count comparison across datasets |
| `reconciliation` | **Consistency**, Accuracy | 🟡 MEDIUM | Source-to-target validation |
| `for each` | All | 🟡 MEDIUM | Pattern for any dimension |
| `group by` | All | 🟡 MEDIUM | Pattern for any dimension |
| `filter` | All | 🔴 HIGH | Applies to any check |
| Variables (`${var}`) | All | 🔴 HIGH | Dynamic checks |

---

## Coverage by Dimension

### 1. Completeness
- ✅ `missing_count(column)`
- ✅ `missing_percent(column)`
- ✅ `row_count`
- ✅ `failed rows` (custom missing logic)

**Status:** COMPLETE ✅ (documented in TEMP-7.3.1)

---

### 2. Validity
- ✅ `invalid_count(column)`
- ✅ `invalid_percent(column)`
- ✅ `valid_count(column)`
- ✅ `valid_percent(column)`
- ✅ `valid format: ...` (email, phone, date, uuid, etc.)
- ✅ `valid values: [...]` (enum)
- ✅ `valid regex: pattern`
- ✅ `failed rows` (custom SQL)

**Status:** COMPLETE ✅ (documented in TEMP-7.3.2)

---

### 3. Uniqueness
- ✅ `duplicate_count(column)`
- ✅ `duplicate_count(col1, col2, ...)` (composite)
- ✅ `duplicate_percent(column)`
- ⚠️ `distinct_count(column)` (also Accuracy)

**Status:** COMPLETE ✅ (documented in TEMP-7.3.3)

---

### 4. Timeliness
- ⏳ `freshness(column)`
- ⏳ `change for metric`
- ⏳ `group evolution`

**Status:** PENDING ⏳ (needs TEMP-7.3.4)

---

### 5. Conformity
- ⏳ `schema`
- ⏳ `schema: warn/fail`
- ⏳ `when schema changes`
- ⏳ `when required column missing`
- ⏳ `when wrong column type`

**Status:** PENDING ⏳ (needs TEMP-7.3.5)

---

### 6. Accuracy
- ⏳ `min(column)`
- ⏳ `max(column)`
- ⏳ `avg(column)`
- ⏳ `sum(column)`
- ⏳ `stddev(column)`
- ⏳ `variance(column)`
- ⏳ `percentile(column, value)`
- ⏳ `anomaly detection for`
- ⏳ `anomaly score for`
- ⏳ `distribution check`
- ⏳ `distinct_count(column)` (also Uniqueness)

**Status:** PENDING ⏳ (needs TEMP-7.3.6)

---

### 7. Consistency
- ⏳ `reference` (foreign key)
- ⏳ `cross check` (cross-table)
- ⏳ `reconciliation` (source-to-target)
- ⏳ `failed rows` (custom consistency logic)

**Status:** PENDING ⏳ (needs TEMP-7.3.7)

---

### 8. Coverage
- ⏳ `row_count` (cross-table comparisons)
- ⏳ `cross check` (row count reconciliation)

**Status:** PENDING ⏳ (needs TEMP-7.3.8)

---

## Quick Reference Matrix

| Dimension | Check Count | Key Checks | Status |
|-----------|-------------|------------|--------|
| **Completeness** | 4 | `missing_count`, `missing_percent`, `row_count` | ✅ DONE |
| **Validity** | 8+ | `invalid_count`, `valid_format`, `failed rows` | ✅ DONE |
| **Uniqueness** | 3 | `duplicate_count`, `duplicate_percent` | ✅ DONE |
| **Timeliness** | 3 | `freshness`, `change for`, `group evolution` | ⏳ PENDING |
| **Conformity** | 5 | `schema`, column validation | ⏳ PENDING |
| **Accuracy** | 11 | `min`, `max`, `avg`, `anomaly detection` | ⏳ PENDING |
| **Consistency** | 4 | `reference`, `cross check`, `reconciliation` | ⏳ PENDING |
| **Coverage** | 2 | `row_count` comparisons | ⏳ PENDING |

**Progress:** 3/8 dimensions complete (37.5%)

---

## Next Steps

1. ✅ **Completeness** - COMPLETE
2. ✅ **Validity** - COMPLETE
3. ✅ **Uniqueness** - COMPLETE
4. ⏳ **Timeliness** - Create TEMP-7.3.4 (freshness, change, group evolution)
5. ⏳ **Conformity** - Create TEMP-7.3.5 (schema checks)
6. ⏳ **Accuracy** - Create TEMP-7.3.6 (numeric metrics, anomaly detection)
7. ⏳ **Consistency** - Create TEMP-7.3.7 (reference, cross, reconciliation)
8. ⏳ **Coverage** - Create TEMP-7.3.8 (row count comparisons)

---

**Last Updated:** 2024-11-14 (All links validated)  
**Source:** SodaCL Reference Documentation v3

