# 7.3.1 Completeness

**TEMPORARY DOCUMENTATION - FOR REVIEW**

**SodaCL References:**
- [Missing Metrics (missing_count, missing_percent, missing_values, missing_regex)](https://docs.soda.io/sodacl-reference/missing-metrics)
- [Numeric Metrics (includes row_count)](https://docs.soda.io/sodacl-reference/numeric-metrics)
- [Filters and Variables](https://docs.soda.io/sodacl-reference/filters)
- [SodaCL Reference Overview](https://docs.soda.io/sodacl-reference)

---

Completeness ensures that all required data is present and tables have sufficient volume.

---

## Missing Metrics

**Reference:** [SodaCL Missing Metrics Documentation](https://docs.soda.io/sodacl-reference/missing-metrics)

Detect missing values (NULL by default, or custom-defined values).

### Basic Syntax

```yaml
completeness:
  # Count of missing values
  - missing_count(email) = 0:
      name: no_missing_emails
      attributes:
        description: "All users must have an email address"
  
  # Percentage of missing values (0-100, not 0-1)
  - missing_percent(phone_number) < 5:
      name: phone_mostly_complete
      attributes:
        description: "Less than 5% phone numbers can be missing"
  
  # Can use % character for readability
  - missing_percent(backup_email) < 10%:
      name: backup_email_optional
```

### What Counts as "Missing"?

By default, only `NULL` is considered missing.

### Define Custom Missing Values

You can specify custom values that should be considered missing:

```yaml
completeness:
  # List of custom missing values
  - missing_count(status) = 0:
      missing values: [NA, n/a, unknown, none, '']
      name: no_unknown_status
      attributes:
        description: "Status must be defined"
  
  # Regex pattern for missing values
  - missing_count(first_name) = 0:
      missing regex: (?:N/A|null|UNKNOWN)
      name: valid_first_names
      attributes:
        description: "First names must be present"
  
  # Multiple patterns
  - missing_count(last_name) < 5:
      missing values: [NA, n/a, 0]
      name: few_missing_last_names
```

**Important notes:**
- Values in `missing values` list must be in square brackets `[]`
- For **BigQuery**: Don't wrap numeric values in quotes
- Percentage thresholds are **0-100**, not 0-1
- `missing regex` uses regex pattern **without forward slash delimiters**
- String values only for `missing regex`

---

## Comparison Operators

All standard comparison operators are supported:

```yaml
completeness:
  - missing_count(column) = 0                    # Exactly zero
  - missing_count(column) < 10                   # Less than
  - missing_count(column) <= 10                  # Less than or equal
  - missing_count(column) > 5                    # Greater than
  - missing_count(column) >= 5                   # Greater than or equal
  - missing_count(column) != 0                   # Not equal
  - missing_count(column) <> 0                   # Not equal (alternative)
  - missing_count(column) between 1 and 10       # Range (inclusive)
  - missing_count(column) not between 5 and 15   # Outside range
```

---

## Row Count Checks

Ensure tables have sufficient data volume:

```yaml
completeness:
  # Minimum threshold
  - row_count > 1000:
      name: sufficient_data
      attributes:
        description: "Table must have at least 1000 rows"
  
  # Expected range
  - row_count between 1000 and 100000:
      name: expected_row_range
      attributes:
        description: "Row count within normal operating range"
  
  # Exact count (useful for seed/reference tables)
  - row_count = 50:
      name: exact_country_count
      attributes:
        description: "Country reference table must have exactly 50 countries"
```

### Alert Configurations

Define warn and fail zones:

```yaml
completeness:
  # Warn at 100, fail at 50
  - row_count:
      warn: when < 100
      fail: when < 50
      name: row_count_with_alerts
      attributes:
        description: "Warn if below 100 rows, fail if below 50"
  
  # Multiple thresholds
  - missing_percent(email):
      warn: when between 1% and 5%
      fail: when > 5%
      name: email_completion_rate
```

---

## Failed Row Sampling

Control which failed rows are collected for inspection.

### Sample Size Control

```yaml
completeness:
  # Limit sample size (default is 100)
  - missing_count(email) = 0:
      samples limit: 20
      name: email_required
      attributes:
        description: "Collect up to 20 failed rows"
  
  # Disable sampling for sensitive data
  - missing_count(ssn) = 0:
      samples limit: 0
      name: ssn_required
      attributes:
        description: "SSN required but don't collect samples"
```

### Specify Sample Columns

```yaml
completeness:
  # Only collect specific columns in samples
  - missing_count(gender) = 0:
      missing values: [M, F, Other]
      samples columns: [employee_key, first_name, last_name]
      name: valid_gender
      attributes:
        description: "Gender required - only sample key and name columns"
```

**Note:** `samples columns` does not support wildcard characters (%).

---

## Vulcan-Specific Features

### Dynamic Variables

Vulcan injects runtime variables into check execution:

```yaml
completeness:
  # Use ${run_date} from Vulcan
  - row_count > 0:
      name: daily_records_exist
      filter: "created_at >= CAST('${run_date}' AS DATE)"
      attributes:
        description: "At least one record created on run date"
  
  # Time window with run_date
  - missing_count(event_type) = 0:
      name: events_in_window
      filter: "event_date >= CAST('${run_date}' AS DATE) - INTERVAL '7 days'"
      attributes:
        description: "All events in last 7 days must have event type"
  
  # Environment-specific checks
  - row_count > 1000:
      name: prod_volume_check
      filter: "environment = '${environment}'"
      attributes:
        description: "Production environment must have >1000 rows"
```

**Available Vulcan variables:**
- `${run_date}` - Current run date (YYYY-MM-DD format)
- `${environment}` - Environment name (prod, dev, staging)

### Dataset Filters

Apply checks to data subsets:

```yaml
checks:
  b2b_saas.users:
    # Filter applies to ALL checks in this suite
    filter: "industry = 'finance'"
    
    completeness:
      - missing_count(company_name) = 0:
          name: finance_users_have_companies
      
      - row_count > 50:
          name: sufficient_finance_users
```

---

## Real Examples from b2b_saas

### Basic Completeness Checks

```yaml
# checks/users.yml
checks:
  b2b_saas.users:
    filter: "industry = 'finance'"
    
    completeness:
      - missing_count(company_name) = 0:
          name: no_missing_company_names
          attributes:
            description: "All users must have a company name"
      
      - missing_count(email) = 0:
          name: no_missing_emails
          attributes:
            description: "All users must have an email"
      
      - row_count > 20:
          name: sufficient_users
          attributes:
            description: "At least 20 users in the system (will fail - only 15 users)"
```

### With Vulcan Variables

```yaml
# checks/usage_events.yml
checks:
  b2b_saas.usage_events:
    completeness:
      - missing_count(user_id) = 0:
          name: no_missing_user_ids
          attributes:
            description: "All events must have a user ID"
      
      - missing_count(event_date) = 0:
          name: no_missing_event_dates
          attributes:
            description: "All events must have an event date"
      
      - row_count > 0:
          name: events_in_run_window
          # Vulcan variable injection
          filter: "event_date >= CAST('${run_date}' AS DATE) - INTERVAL '7 days'"
          attributes:
            description: "Events exist in the run window (uses Vulcan run_date variable)"
```

### Multiple Models

```yaml
# checks/subscriptions.yml
checks:
  hello.subscriptions:
    completeness:
      - missing_count(user_id) = 0:
          name: no_missing_user_ids
          attributes:
            description: "All subscriptions must have a user ID"
      
      - missing_count(plan_id) = 0:
          name: no_missing_plan_ids
          attributes:
            description: "All subscriptions must have a plan ID"
      
      - missing_count(start_date) = 0:
          name: no_missing_start_dates
          attributes:
            description: "All subscriptions must have a start date"
      
      - row_count > 5:
          name: sufficient_subscriptions
          attributes:
            description: "At least 5 subscriptions in the system"
```

---

## Complete Example

Comprehensive completeness check with all features:

```yaml
completeness:
  # Complex missing value definition with sampling
  - missing_count(customer_status) < 10:
      missing values: [unknown, pending, '', null, N/A]
      samples limit: 5
      samples columns: [customer_id, customer_name, status, signup_date]
      filter: signup_date >= '2024-01-01'
      name: recent_customers_have_status
      attributes:
        description: "Customers from 2024 must have defined status (allow <10 missing)"
        owner: "data-quality-team"
        severity: "high"
  
  # Pattern-based missing detection
  - missing_count(email) = 0:
      missing regex: (?:invalid|dummy|test@)
      samples limit: 10
      name: no_invalid_emails
      attributes:
        description: "Filter out test/dummy emails"
  
  # Row count with alert zones
  - row_count:
      warn: when < 1000
      fail: when < 500
      filter: "created_at >= CURRENT_DATE - INTERVAL '30 days'"
      name: recent_data_volume
      attributes:
        description: "Monitor recent data volume"
```

---

## When to Use

| Check Type | Use When | Example Use Case |
|------------|----------|------------------|
| `missing_count(col) = 0` | Column is absolutely required | Email, customer_id, order_id |
| `missing_percent(col) < X%` | Optional field with expected completion rate | Phone number (80% complete), backup email (50% complete) |
| `missing values: [...]` | Multiple values qualify as "missing" | Status with unknown/pending/NA/null |
| `missing regex` | Pattern-based missing detection | Various "N/A" formats, test emails |
| `row_count > X` | Minimum data volume expected | Daily fact tables, event streams |
| `row_count between X and Y` | Expected operating range | Dimension tables (stable size) |
| `samples limit: X` | Control failed row collection | Large tables (limit=20), sensitive data (limit=0) |
| `samples columns: [...]` | Specify which columns to sample | Exclude PII, include only keys |
| `warn/fail` alerts | Gradual degradation detection | Volume drops, completion rate trends |
| With `filter` | Subset-specific validation | By region, customer tier, time window |
| With `${run_date}` | Time-based validation | Daily/weekly data arrival |

---

## Best Practices

### ✅ DO:

- **Use `missing_count = 0`** for absolutely required fields (keys, critical attributes)
- **Use `missing_percent < X%`** for optional fields with expected completion rates
- **Define custom missing values** when your data has non-NULL missing indicators
- **Limit samples** for large tables (`samples limit: 20`) or disable for sensitive data (`samples limit: 0`)
- **Use alert configurations** (`warn`/`fail`) for gradual degradation detection
- **Add descriptive names and attributes** to every check
- **Use filters** to test checks on subsets before full deployment
- **Leverage Vulcan variables** (`${run_date}`, `${environment}`) for dynamic checks

### ❌ DON'T:

- Don't use `missing_percent` on small tables (percentages unstable with low row counts)
- Don't forget BigQuery doesn't use quotes around numeric `missing values`
- Don't use percentage range 0-1 (it's 0-100!)
- Don't collect failed row samples for PII/sensitive columns
- Don't use wildcard characters in `samples columns` (not supported)
- Don't skip attributes - they're essential for monitoring dashboards

---

## Comparison: Missing vs Invalid vs Valid

Vulcan automatically categorizes all column values into three buckets:

```
missing count(column) + invalid count(column) + valid count(column) = row_count
missing percent(column) + invalid percent(column) + valid percent(column) = 100
```

**Example:**

Table with 1000 rows, `email` column:
- 50 NULLs → `missing_count(email) = 50`, `missing_percent(email) = 5%`
- 30 invalid formats → `invalid_count(email) = 30`, `invalid_percent(email) = 3%`
- 920 valid emails → `valid_count(email) = 920`, `valid_percent(email) = 92%`

This enables **relative thresholds**:
```yaml
completeness:
  - missing_percent(email) < 10%  # Relative to total rows
```

---

## Integration with Other Layers

**Completeness works with:**

1. **Audits** (Section 6) - Critical completeness checks that block pipeline
   ```sql
   MODEL (
     audits (
       not_null(columns := (customer_id, email))  -- Blocking
     )
   );
   ```

2. **Checks** (this section) - Monitoring and alerting
   ```yaml
   completeness:
     - missing_count(email) = 0:  # Non-blocking, with samples
         samples limit: 10
   ```

3. **Profiles** (Section 7.5) - Observability
   ```sql
   MODEL (
     profiles (email, phone_number)  -- Track null % over time
   );
   ```

**Strategy:** Use audits for critical validation, checks for monitoring, profiles for trend tracking.

---

## Related Check Types

- **Validity** (Section 7.3.2) - Checks if non-missing values are valid
- **Uniqueness** (Section 7.3.3) - Checks for duplicates
- **Coverage** (Section 7.3.8) - Row count comparisons across tables

---

## Status

- ✅ **Verified** against b2b_saas examples
- ✅ **Documented** all SodaCL missing metrics features
- ✅ **Includes** Vulcan-specific features (variables, filters)
- ⏳ **Pending** integration into main book

---

**Next Dimension:** Validity (7.3.2) - Failed rows checks, validity metrics

