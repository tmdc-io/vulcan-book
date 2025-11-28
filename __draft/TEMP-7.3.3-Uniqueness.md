# 7.3.3 Uniqueness

**TEMPORARY DOCUMENTATION - FOR REVIEW**

**SodaCL References:**
- [Numeric Metrics (includes duplicate_count, duplicate_percent)](https://docs.soda.io/sodacl-reference/numeric-metrics)
- [SodaCL Metrics and Checks](https://docs.soda.io/sodacl-reference/metrics-and-checks)
- [SodaCL Reference Overview](https://docs.soda.io/sodacl-reference)

---

Uniqueness ensures that records are distinct and identifies duplicate entries that can lead to inaccurate analyses and reporting.

---

## Overview

Uniqueness checks validate that values in a column (or combination of columns) are unique, preventing duplicate entries that can:
- Inflate metrics and KPIs
- Cause incorrect JOIN results
- Violate primary key constraints
- Lead to incorrect aggregations

**Common use cases:**
- Primary key validation (customer_id, order_id, user_id)
- Unique constraint enforcement (email, SSN, account_number)
- Natural key validation (first_name + last_name + birth_date)
- Composite key validation (customer_id + date, order_id + line_item)

---

## Duplicate Metrics

**Reference:** [SodaCL Numeric Metrics - Duplicate Count](https://docs.soda.io/sodacl-reference/numeric-metrics)

### Basic Syntax

```yaml
uniqueness:
  # Count of duplicate values
  - duplicate_count(email) = 0:
      name: unique_emails
      attributes:
        description: "Email addresses must be unique"
  
  # Percentage of duplicate values (0-100, not 0-1)
  - duplicate_percent(phone_number) < 2:
      name: mostly_unique_phones
      attributes:
        description: "Less than 2% duplicate phone numbers allowed"
  
  # Can use % character for readability
  - duplicate_percent(ssn) < 0.1%:
      name: negligible_duplicate_ssn
```

### Single Column Uniqueness

Check for duplicates in a single column:

```yaml
uniqueness:
  # Primary key - must be unique
  - duplicate_count(customer_id) = 0:
      name: unique_customer_ids
      attributes:
        description: "Customer IDs must be unique (primary key)"
  
  # Email - must be unique
  - duplicate_count(email) = 0:
      name: unique_emails
      attributes:
        description: "Each email can only be registered once"
  
  # Username - must be unique
  - duplicate_count(username) = 0:
      name: unique_usernames
      attributes:
        description: "Usernames must be unique across system"
```

### Multiple Column Uniqueness (Composite Keys)

Check for duplicate combinations across multiple columns:

```yaml
uniqueness:
  # Composite primary key
  - duplicate_count(customer_id, order_date) = 0:
      name: unique_customer_date
      attributes:
        description: "Each customer can only have one record per date"
  
  # Natural key
  - duplicate_count(first_name, last_name, birth_date) = 0:
      name: unique_person
      attributes:
        description: "Combination of name and birth date must be unique"
  
  # Multi-column business key
  - duplicate_count(account_number, transaction_date, transaction_type) = 0:
      name: unique_transaction
      attributes:
        description: "Transaction uniqueness by account, date, and type"
  
  # Fact table grain
  - duplicate_count(product_id, store_id, sale_date) = 0:
      name: unique_daily_sales
      attributes:
        description: "One sales record per product/store/day"
```

### Comparison Operators

All standard operators supported:

```yaml
uniqueness:
  - duplicate_count(column) = 0       # No duplicates
  - duplicate_count(column) < 10      # Less than 10 duplicates
  - duplicate_count(column) <= 5      # Up to 5 duplicates
  - duplicate_count(column) > 0       # At least one duplicate exists
  - duplicate_count(column) between 1 and 10
  - duplicate_percent(column) < 1%    # Less than 1% duplicates
  - duplicate_percent(column) = 0%    # No duplicates (0-100 scale)
```

---

## Real Examples from b2b_saas

### Single Column Uniqueness

```yaml
# checks/users.yml
checks:
  b2b_saas.users:
    uniqueness:
      # Email must be unique
      - duplicate_count(email) = 0:
          name: unique_emails
          attributes:
            description: "Email addresses must be unique"
```

```yaml
# checks/subscriptions.yml
checks:
  hello.subscriptions:
    uniqueness:
      # Subscription ID must be unique (primary key)
      - duplicate_count(subscription_id) = 0:
          name: unique_subscription_ids
          attributes:
            description: "Subscription IDs must be unique"
```

```yaml
# checks/usage_events.yml
checks:
  b2b_saas.usage_events:
    uniqueness:
      # Event ID must be unique
      - duplicate_count(event_id) = 0:
          name: unique_event_ids
          attributes:
            description: "Event IDs must be unique"
```

### With Dataset Filters

```yaml
# Check uniqueness within subset
checks:
  b2b_saas.users:
    filter: "status = 'active'"
    
    uniqueness:
      - duplicate_count(email) = 0:
          name: unique_active_user_emails
          attributes:
            description: "Active users must have unique emails"
```

---

## Failed Row Sampling

**Reference:** [SodaCL Optional Check Configurations - Samples](https://docs.soda.io/sodacl-reference/optional-check-configurations)

Control which duplicate rows are collected for inspection.

### Sample Size Control

```yaml
uniqueness:
  # Default: 100 samples
  - duplicate_count(email) = 0:
      name: unique_emails
  
  # Limit samples
  - duplicate_count(customer_id) = 0:
      samples limit: 20
      name: unique_customers
      attributes:
        description: "Collect up to 20 duplicate customer records"
  
  # Disable sampling (sensitive data)
  - duplicate_count(ssn) = 0:
      samples limit: 0
      name: unique_ssn
      attributes:
        description: "SSN must be unique but don't collect samples"
```

### Specify Sample Columns

```yaml
uniqueness:
  # Only collect specific columns in duplicate samples
  - duplicate_count(email) = 0:
      samples columns: [user_id, email, created_at]
      name: unique_emails
      attributes:
        description: "Exclude PII from duplicate samples"
```

**Note:** Duplicate checks automatically collect samples of duplicate rows. Default is 100 samples.

---

## Advanced Patterns

### Alert Configurations

Define warn and fail zones:

```yaml
uniqueness:
  # Warn at any duplicates, fail above threshold
  - duplicate_count(email):
      warn: when > 0
      fail: when > 10
      name: email_uniqueness_alerts
      attributes:
        description: "Warn on any duplicates, fail if >10"
  
  # Percentage-based thresholds
  - duplicate_percent(customer_id):
      warn: when between 0.1% and 1%
      fail: when > 1%
      name: customer_id_quality
      attributes:
        description: "Monitor customer ID uniqueness"
```

### With Vulcan Variables

```yaml
uniqueness:
  # Check uniqueness for recent data only
  - duplicate_count(order_id) = 0:
      filter: "order_date >= CAST('${run_date}' AS DATE) - INTERVAL '30 days'"
      name: recent_order_uniqueness
      attributes:
        description: "Ensure recent orders have unique IDs"
```

### Composite Key with Grain

Align with model grain definition:

```sql
-- In model DDL
MODEL (
  name analytics.daily_revenue,
  grains (customer_id, revenue_date)  -- Composite key
);
```

```yaml
# In checks file
checks:
  analytics.daily_revenue:
    uniqueness:
      # Match the model grain
      - duplicate_count(customer_id, revenue_date) = 0:
          name: unique_customer_date
          attributes:
            description: "Matches model grain - one row per customer per date"
```

---

## Complete Example

Comprehensive uniqueness checks:

```yaml
uniqueness:
  # 1. Primary key uniqueness
  - duplicate_count(customer_id) = 0:
      samples limit: 10
      name: unique_customer_ids
      attributes:
        description: "Customer ID is primary key - must be unique"
        owner: "data-quality-team"
        severity: "critical"
  
  # 2. Business key uniqueness
  - duplicate_count(email) = 0:
      samples columns: [customer_id, email, created_at]
      name: unique_emails
      attributes:
        description: "Email addresses must be unique"
        severity: "high"
  
  # 3. Composite key uniqueness (fact table grain)
  - duplicate_count(customer_id, transaction_date) = 0:
      samples limit: 15
      name: unique_daily_transactions
      attributes:
        description: "One transaction record per customer per day"
  
  # 4. Natural key with tolerance
  - duplicate_percent(first_name, last_name, birth_date) < 0.5%:
      samples limit: 20
      name: mostly_unique_persons
      attributes:
        description: "Allow <0.5% duplicates for common name combinations"
  
  # 5. Alert-based monitoring
  - duplicate_count(account_number):
      warn: when > 0
      fail: when > 5
      samples limit: 10
      name: account_number_uniqueness_monitor
      attributes:
        description: "Monitor account number uniqueness over time"
  
  # 6. Time-windowed uniqueness
  - duplicate_count(order_id) = 0:
      filter: "order_date >= CAST('${run_date}' AS DATE) - INTERVAL '90 days'"
      name: recent_order_uniqueness
      attributes:
        description: "Ensure recent orders have unique IDs"
```

---

## When to Use

| Check Type | Use When | Example |
|------------|----------|---------|
| `duplicate_count(col) = 0` | Column must be completely unique | Primary keys (customer_id, order_id) |
| `duplicate_percent(col) < X%` | Some duplicates acceptable | Natural keys, fuzzy matching results |
| `duplicate_count(col1, col2)` | Composite key uniqueness | Fact table grain, junction tables |
| `duplicate_count(col1, col2, col3)` | Multi-column natural key | Person (name + DOB), location (address) |
| With `samples limit` | Control sample size | Large tables, sensitive data |
| With `warn`/`fail` alerts | Monitor uniqueness trends | Detect gradual data quality degradation |
| With `filter` | Time-windowed uniqueness | Recent data validation |

---

## Uniqueness vs Grain

### Model Grain = Uniqueness Check

Your model's `grain` definition should match your uniqueness check:

**Example 1: Single column grain**

```sql
-- Model DDL
MODEL (
  name analytics.customers,
  grain customer_id  -- Single column
);
```

```yaml
# Checks file
uniqueness:
  - duplicate_count(customer_id) = 0:
      name: unique_customer_ids
```

**Example 2: Multiple column grain**

```sql
-- Model DDL
MODEL (
  name analytics.daily_revenue,
  grains (customer_id, revenue_date)  -- Composite key
);
```

```yaml
# Checks file
uniqueness:
  - duplicate_count(customer_id, revenue_date) = 0:
      name: unique_customer_date
```

**Why align them?**
- Grain defines what makes a row unique (conceptual)
- Uniqueness check validates the grain (operational)
- Misalignment indicates model design issue

---

## Best Practices

### ✅ DO:

- **Use `duplicate_count = 0`** for primary keys and unique constraints
- **Use `duplicate_percent < X%`** when fuzzy duplicates are expected
- **Check composite keys** for fact tables and junction tables
- **Align with model grain** - your uniqueness check should match `grains` DDL
- **Limit samples** for large tables (`samples limit: 10-20`)
- **Disable sampling** for PII (`samples limit: 0`)
- **Use `samples columns`** to exclude sensitive data from samples
- **Add alert configs** to monitor uniqueness trends over time
- **Filter recent data** for incremental models (avoid full table scans)
- **Document grain** in check description

### ❌ DON'T:

- Don't check uniqueness on non-key columns without business justification
- Don't use `duplicate_percent` on small tables (unstable percentages)
- Don't ignore duplicates in primary keys (always fail=0)
- Don't forget to align uniqueness checks with model `grain`/`grains`
- Don't collect samples for PII without `samples columns` restriction
- Don't check uniqueness across unrelated columns
- Don't skip the grain validation audit in the model

---

## Comparison: Uniqueness Check vs Audit

**In Model (Audit):**

```sql
MODEL (
  name analytics.customers,
  grain customer_id,
  audits (
    unique_key(columns := (customer_id))  -- Blocks pipeline
  )
);
```

**In Checks (Monitoring):**

```yaml
checks:
  analytics.customers:
    uniqueness:
      - duplicate_count(customer_id) = 0:  # Non-blocking, with samples
          samples limit: 10
          name: unique_customer_ids
```

**When to use each:**

| Concern | Use Audit | Use Check |
|---------|-----------|-----------|
| Primary key must be unique | ✅ | ✅ |
| Block pipeline on duplicates | ✅ | ❌ |
| Collect duplicate samples | ❌ | ✅ |
| Monitor trends over time | ❌ | ✅ |
| Business key uniqueness | ❌ | ✅ |
| Composite key validation | ✅ | ✅ |

**Recommended strategy:** Use BOTH
- Audit for critical blocking validation
- Check for monitoring with sample collection

---

## Integration with Other Layers

**Uniqueness works with:**

1. **Grain Definition** (Section 5) - Model grain should match uniqueness check
   ```sql
   MODEL (
     grains (customer_id, order_date)
   );
   ```

2. **Audits** (Section 6) - Critical uniqueness that blocks pipeline
   ```sql
   MODEL (
     audits (
       unique_key(columns := (customer_id)),
       unique_combination_of_columns(columns := (customer_id, order_date))
     )
   );
   ```

3. **Checks** (this section) - Monitoring with samples
   ```yaml
   uniqueness:
     - duplicate_count(customer_id, order_date) = 0:
         samples limit: 10
   ```

4. **Profiles** (Section 7.5) - Track distinct_count over time
   ```sql
   MODEL (
     profiles (customer_id, email)  # Track distinct/duplicate trends
   );
   ```

---

## Common Patterns

### Pattern 1: Dimension Table

```yaml
# One record per entity
uniqueness:
  - duplicate_count(customer_id) = 0:
      name: unique_customers
```

### Pattern 2: Fact Table

```yaml
# One record per grain (composite key)
uniqueness:
  - duplicate_count(customer_id, order_date, product_id) = 0:
      name: unique_sales_records
```

### Pattern 3: Junction Table

```yaml
# One record per relationship
uniqueness:
  - duplicate_count(user_id, role_id) = 0:
      name: unique_user_roles
```

### Pattern 4: Event Stream

```yaml
# Event ID must be globally unique
uniqueness:
  - duplicate_count(event_id) = 0:
      samples limit: 20
      name: unique_events
```

### Pattern 5: SCD Type 2

```yaml
# Composite key with effective date
uniqueness:
  - duplicate_count(customer_id, effective_from_date) = 0:
      name: unique_customer_history
```

---

## Troubleshooting Duplicates

When duplicates are found:

### Step 1: Review Failed Row Samples

```yaml
uniqueness:
  - duplicate_count(email) = 0:
      samples limit: 50  # Increase to see more duplicates
      samples columns: [user_id, email, created_at, source_system]
      name: investigate_email_duplicates
```

### Step 2: Count Duplicates by Group

Use `failed rows` to analyze duplicate patterns:

```yaml
validity:
  # Find which emails are duplicated and how many times
  - failed rows:
      name: email_duplicate_analysis
      fail query: |
        SELECT 
          email,
          COUNT(*) as duplicate_count,
          MIN(created_at) as first_seen,
          MAX(created_at) as last_seen,
          COUNT(DISTINCT source_system) as source_count
        FROM b2b_saas.users
        GROUP BY email
        HAVING COUNT(*) > 1
      samples limit: 100
```

### Step 3: Identify Root Cause

Common causes:
- Multiple source systems without deduplication
- Lack of unique constraint in source database
- Case sensitivity issues (Email vs email)
- Leading/trailing whitespace
- Race conditions in concurrent inserts
- Historical data loads without merge logic

---

## Related Check Types

- **Completeness** (Section 7.3.1) - Checks if keys are present (not NULL)
- **Validity** (Section 7.3.2) - Checks if keys are in valid format
- **Consistency** (Section 7.3.7) - Reference checks validate foreign keys

**Complete validation strategy:**

```yaml
# 1. Completeness - key is present
completeness:
  - missing_count(customer_id) = 0:
      name: customer_id_required

# 2. Validity - key is valid format
validity:
  - invalid_count(customer_id) = 0:
      valid regex: ^CUST-\d{8}$
      name: valid_customer_id_format

# 3. Uniqueness - key is unique
uniqueness:
  - duplicate_count(customer_id) = 0:
      name: unique_customer_ids

# 4. Consistency - key references exist
consistency:
  - reference:
      column: customer_id
      referenced_table: dim_customers
      referenced_column: customer_id
      name: valid_customer_references
```

---

## Status

- ✅ **Verified** against b2b_saas examples
- ✅ **Documented** all duplicate metrics (count, percent, single/multi-column)
- ✅ **Includes** failed row sampling controls
- ✅ **Includes** integration with model grain
- ✅ **Includes** comparison with audits
- ⏳ **Pending** integration into main book

---

**Next Dimension:** Timeliness (7.3.4) - Freshness checks, change over time, group evolution

