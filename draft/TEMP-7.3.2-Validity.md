# 7.3.2 Validity

**TEMPORARY DOCUMENTATION - FOR REVIEW**

**SodaCL References:**
- [Validity Metrics (invalid_count, invalid_percent, valid_count, valid_format, valid_values, valid_regex)](https://docs.soda.io/sodacl-reference/validity-metrics)
- [Failed Rows Checks (fail query, fail condition, samples)](https://docs.soda.io/sodacl-reference/failed-rows-checks)
- [User-Defined Checks](https://docs.soda.io/sodacl-reference/user-defined)
- [SodaCL Reference Overview](https://docs.soda.io/sodacl-reference)

---

Validity ensures that data conforms to expected formats, patterns, and business rules.

---

## Overview

Vulcan categorizes all column values into three buckets:
- **Missing** - NULL or custom-defined missing values
- **Invalid** - Present but doesn't meet validity criteria
- **Valid** - Present and meets all validity criteria

```
missing count + invalid count + valid count = row count
missing percent + invalid percent + valid percent = 100
```

**Example:** In a column with 1000 rows:
- 50 NULLs → missing
- 30 fail email format → invalid
- 920 valid emails → valid

---

## Validity Metrics

**Reference:** [SodaCL Validity Metrics Documentation](https://docs.soda.io/sodacl-reference/validity-metrics)

Use validity metrics to measure how many values meet validity criteria.

### Basic Syntax

```yaml
validity:
  # Count of invalid values
  - invalid_count(email) = 0:
      valid format: email
      name: valid_email_format
      attributes:
        description: "All emails must be in valid format"
  
  # Percentage of invalid values
  - invalid_percent(phone_number) < 5:
      valid format: phone number
      name: mostly_valid_phones
      attributes:
        description: "Less than 5% invalid phone numbers allowed"
  
  # Count of valid values
  - valid_count(status) > 100:
      valid values: [active, churned, suspended]
      name: sufficient_valid_status
```

### Valid Format

Built-in format validators (applies to TEXT columns):

```yaml
validity:
  # Email validation
  - invalid_count(email) = 0:
      valid format: email
  
  # Date formats
  - invalid_count(signup_date) = 0:
      valid format: date eu  # dd/mm/yyyy
  
  - invalid_count(created_at) = 0:
      valid format: date us  # mm/dd/yyyy
  
  - invalid_count(timestamp) = 0:
      valid format: date iso 8601
  
  # Numeric formats
  - invalid_count(quantity) = 0:
      valid format: integer
  
  - invalid_count(price) = 0:
      valid format: decimal
  
  - invalid_count(age) = 0:
      valid format: positive integer
  
  # Other formats
  - invalid_count(card_number) = 0:
      valid format: credit card number
  
  - invalid_count(server_ip) = 0:
      valid format: ip address
  
  - invalid_count(mobile) = 0:
      valid format: phone number
  
  - invalid_count(user_uuid) = 0:
      valid format: uuid
```

**Supported formats:**
- `email` - Standard email format
- `date eu` - European date format (dd/mm/yyyy)
- `date us` - US date format (mm/dd/yyyy)
- `date iso 8601` - ISO 8601 format
- `integer`, `decimal` - Numeric formats
- `positive integer`, `negative decimal` - Signed numbers
- `credit card number` - Credit card validation
- `ip address` - IPv4/IPv6 addresses
- `phone number` - Phone number format
- `uuid` - UUID format

### Valid Values

Define explicit list of acceptable values (enum validation):

```yaml
validity:
  # Simple list
  - invalid_count(status) = 0:
      valid values: [active, churned, suspended]
      name: valid_status_values
      attributes:
        description: "Status must be one of: active, churned, suspended"
  
  # With spaces or special characters
  - invalid_count(plan_type) = 0:
      valid values:
        - Free
        - Pro
        - Enterprise
        - Enterprise Plus
      name: valid_plan_types
  
  # Numeric values
  - invalid_count(priority) = 0:
      valid values: [1, 2, 3, 4, 5]
      name: valid_priority_levels
```

**Important notes:**
- Values must be in a list (brackets `[]` or YAML list format)
- For BigQuery: Don't wrap numeric values in quotes
- Case-sensitive by default

### Valid Regex

Pattern-based validation:

```yaml
validity:
  # Simple pattern
  - invalid_count(product_code) = 0:
      valid regex: ^PRD-\d{6}$
      name: valid_product_code_format
      attributes:
        description: "Product codes must match PRD-######"
  
  # Complex pattern
  - invalid_count(email) = 0:
      valid regex: ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
      name: email_regex_validation
  
  # Multiple patterns
  - invalid_count(phone) = 0:
      valid regex: (?:\+1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}
      name: us_phone_format
```

**Notes:**
- Regex patterns without forward slash delimiters
- String values only

### Comparison Operators

All standard operators supported:

```yaml
validity:
  - invalid_count(column) = 0      # No invalid values
  - invalid_count(column) < 10     # Less than 10 invalid
  - invalid_percent(column) < 5    # Less than 5% invalid
  - valid_count(column) > 100      # At least 100 valid
  - valid_percent(column) >= 95    # At least 95% valid
  - invalid_count(column) between 1 and 10
```

---

## Failed Rows Checks

**Reference:** [SodaCL Failed Rows Checks Documentation](https://docs.soda.io/sodacl-reference/failed-rows-checks)

Custom SQL validation with sample collection - the most powerful validity check.

### Basic Syntax

```yaml
validity:
  - failed rows:
      name: negative_revenue
      fail query: |
        SELECT customer_id, revenue, metric_date
        FROM analytics.revenue_metrics
        WHERE revenue < 0
      samples limit: 10
      attributes:
        description: "Revenue cannot be negative"
```

### Fail Query vs Fail Condition

**Option 1: `fail query` (explicit SELECT)**

```yaml
validity:
  - failed rows:
      name: invalid_emails
      fail query: |
        SELECT user_id, email, company_name
        FROM b2b_saas.users
        WHERE email NOT LIKE '%@%'
      samples limit: 10
```

**Option 2: `fail condition` (simpler WHERE clause)**

```yaml
validity:
  - failed rows:
      name: future_dates
      fail condition: order_date > CURRENT_DATE
      samples limit: 5
```

**When to use:**
- Use `fail query` when you need specific columns or complex logic
- Use `fail condition` for simple WHERE clause validation

### Real Examples from b2b_saas

```yaml
# checks/users.yml
validity:
  # Email format validation
  - failed rows:
      name: invalid_emails
      fail query: |
        SELECT user_id, email, company_name, signup_date
        FROM b2b_saas.users
        WHERE email NOT LIKE '%@%'
      samples limit: 10
      attributes:
        description: "Check for invalid email formats"
  
  # Enum validation
  - failed rows:
      name: invalid_status_values
      fail query: |
        SELECT user_id, email, status, plan_type
        FROM b2b_saas.users
        WHERE status NOT IN ('active', 'churned', 'suspended')
      samples limit: 10
      attributes:
        description: "Status must be one of: active, churned, suspended"
  
  # Missing vs invalid (using failed rows)
  - failed rows:
      name: missing_company_names
      fail query: |
        SELECT user_id, email, company_name, plan_type
        FROM b2b_saas.users
        WHERE company_name IS NULL OR company_name = ''
      samples limit: 10
      attributes:
        description: "All users must have a company name"
```

```yaml
# checks/subscriptions.yml
validity:
  # Positive value validation
  - failed rows:
      name: positive_mrr
      fail query: |
        SELECT * FROM hello.subscriptions
        WHERE mrr <= 0
      attributes:
        description: "MRR must be positive for all subscriptions"
  
  - failed rows:
      name: positive_seats
      fail query: |
        SELECT * FROM hello.subscriptions
        WHERE seats <= 0
      attributes:
        description: "Seats must be positive"
  
  # Date logic validation
  - failed rows:
      name: valid_date_range
      fail query: |
        SELECT * FROM hello.subscriptions
        WHERE end_date IS NOT NULL AND end_date < start_date
      attributes:
        description: "End date must be after start date"
```

```yaml
# checks/usage_events.yml
validity:
  # Positive numeric validation
  - failed rows:
      name: positive_event_count
      fail query: |
        SELECT * FROM b2b_saas.usage_events
        WHERE event_count <= 0
      attributes:
        description: "Event count must be positive"
  
  # Non-negative validation
  - failed rows:
      name: non_negative_session_duration
      fail query: |
        SELECT * FROM b2b_saas.usage_events
        WHERE session_duration < 0
      attributes:
        description: "Session duration cannot be negative"
  
  # Enum with IN clause
  - failed rows:
      name: valid_event_types
      fail query: |
        SELECT * FROM b2b_saas.usage_events
        WHERE event_type NOT IN ('api_call', 'feature_use', 'export', 'login', 'other')
      attributes:
        description: "Event types must be from valid set"
```

### Pattern Library from b2b_saas

Common validation patterns:

```yaml
# Email validation
WHERE email NOT LIKE '%@%'
WHERE email NOT LIKE '%_@_%.__%'

# Enum validation
WHERE status NOT IN ('active', 'churned', 'suspended')
WHERE event_type NOT IN ('type1', 'type2', 'type3')

# Range validation
WHERE revenue < 0
WHERE revenue > 10000000
WHERE price <= 0 OR price > 1000

# Date logic validation
WHERE end_date IS NOT NULL AND end_date < start_date
WHERE created_at > CURRENT_DATE
WHERE event_date < '2020-01-01'

# Positive/negative values
WHERE quantity <= 0
WHERE mrr <= 0
WHERE session_duration < 0

# String length
WHERE LENGTH(email) < 5
WHERE LENGTH(company_name) > 255

# NULL and empty
WHERE column IS NULL OR column = ''
WHERE TRIM(column) = ''

# Combination checks
WHERE revenue < 0 OR revenue > 10000000
WHERE (status = 'active' AND end_date IS NOT NULL)
```

---

## Failed Row Sampling

Control which failed rows are collected for debugging.

### Sample Size Control

```yaml
validity:
  # Default: 100 samples
  - failed rows:
      fail query: |
        SELECT * FROM table WHERE condition
      name: check_name
  
  # Limit samples
  - failed rows:
      fail query: |
        SELECT * FROM table WHERE condition
      samples limit: 20
      name: check_with_limit
  
  # Disable sampling (sensitive data)
  - failed rows:
      fail query: |
        SELECT * FROM table WHERE condition
      samples limit: 0
      name: no_samples
```

### Specify Sample Columns

```yaml
validity:
  # Only collect specific columns
  - failed rows:
      fail query: |
        SELECT user_id, email, ssn, status FROM users
        WHERE invalid_condition
      samples columns: [user_id, status]  # Exclude ssn from samples
      name: sensitive_data_check
```

**Note:** Failed rows checks automatically collect samples. Default is 100 rows.

---

## Advanced Patterns

### Complex Business Logic

```yaml
validity:
  # Revenue consistency check
  - failed rows:
      name: revenue_consistency
      fail query: |
        SELECT 
          s.subscription_id,
          s.mrr,
          SUM(o.amount) / 12 as calculated_mrr,
          ABS(s.mrr - (SUM(o.amount) / 12)) as difference
        FROM b2b_saas.subscriptions s
        JOIN b2b_saas.orders o ON s.subscription_id = o.subscription_id
        GROUP BY s.subscription_id, s.mrr
        HAVING ABS(s.mrr - (SUM(o.amount) / 12)) > 0.01
      samples limit: 10
      attributes:
        description: "MRR must match calculated value from orders"
```

### Multi-Column Validation

```yaml
validity:
  - failed rows:
      name: address_completeness
      fail query: |
        SELECT customer_id, address_line1, city, state, zip
        FROM customers
        WHERE address_line1 IS NOT NULL 
          AND (city IS NULL OR state IS NULL OR zip IS NULL)
      attributes:
        description: "If address provided, city/state/zip are required"
```

### With Vulcan Variables

```yaml
validity:
  - failed rows:
      name: recent_invalid_records
      fail query: |
        SELECT * FROM analytics.events
        WHERE event_type NOT IN ('click', 'view', 'purchase')
          AND event_date >= CAST('${run_date}' AS DATE) - INTERVAL '7 days'
      samples limit: 15
      attributes:
        description: "Validate recent events only (last 7 days)"
```

### Alert Configurations

```yaml
validity:
  # Warn and fail zones
  - invalid_count(email):
      valid format: email
      warn: when > 0
      fail: when > 10
      name: email_validation_alerts
  
  - invalid_percent(phone):
      valid format: phone number
      warn: when between 1% and 5%
      fail: when > 5%
      name: phone_validation_alerts
```

---

## Complete Example

Comprehensive validity checks for a customer table:

```yaml
validity:
  # 1. Format validation with metrics
  - invalid_count(email) = 0:
      valid format: email
      samples limit: 10
      name: valid_email_format
      attributes:
        description: "All emails must be in valid format"
        owner: "data-quality-team"
  
  # 2. Enum validation with metrics
  - invalid_count(status) = 0:
      valid values: [active, churned, suspended, pending]
      samples limit: 5
      name: valid_status_values
      attributes:
        description: "Status must be from predefined list"
  
  # 3. Pattern validation with regex
  - invalid_count(customer_id) = 0:
      valid regex: ^CUST-\d{8}$
      name: valid_customer_id_format
      attributes:
        description: "Customer IDs must match CUST-######## pattern"
  
  # 4. Custom SQL validation
  - failed rows:
      name: valid_subscription_dates
      fail query: |
        SELECT 
          customer_id,
          subscription_start,
          subscription_end,
          DATEDIFF(day, subscription_start, subscription_end) as duration
        FROM customers
        WHERE subscription_end IS NOT NULL 
          AND subscription_end <= subscription_start
      samples limit: 10
      samples columns: [customer_id, subscription_start, subscription_end]
      attributes:
        description: "Subscription end date must be after start date"
  
  # 5. Business rule validation
  - failed rows:
      name: enterprise_customer_validation
      fail query: |
        SELECT customer_id, plan_type, annual_revenue
        FROM customers
        WHERE plan_type = 'Enterprise' 
          AND (annual_revenue IS NULL OR annual_revenue < 100000)
      samples limit: 5
      attributes:
        description: "Enterprise customers must have annual revenue >= $100k"
        severity: "high"
  
  # 6. Alert-based validation
  - invalid_percent(phone_number):
      valid format: phone number
      warn: when between 1% and 5%
      fail: when > 5%
      name: phone_number_quality
      attributes:
        description: "Monitor phone number quality"
```

---

## When to Use

| Check Type | Use When | Example |
|------------|----------|---------|
| `invalid_count(col)` with `valid format` | Standard formats (email, phone, date) | Email addresses, phone numbers |
| `invalid_count(col)` with `valid values` | Fixed enum/categorical data | Status, country codes, product categories |
| `invalid_count(col)` with `valid regex` | Custom patterns | Product codes, SKUs, custom IDs |
| `failed rows` with simple WHERE | Simple validation rules | Negative numbers, date ranges |
| `failed rows` with complex SQL | Business logic, cross-column validation | Revenue consistency, multi-field rules |
| `samples limit` | Control sample size | Large tables (limit=20), sensitive data (limit=0) |
| `samples columns` | Exclude sensitive columns from samples | PII columns (SSN, credit cards) |
| `warn`/`fail` alerts | Gradual quality degradation | Format compliance trends |

---

## Best Practices

### ✅ DO:

- **Use `valid format`** for standard formats (email, phone, UUID)
- **Use `valid values`** for enums with small, stable value sets
- **Use `failed rows`** for complex business logic and debugging
- **Collect samples** for debugging (`samples limit: 10-20`)
- **Exclude PII** from samples using `samples columns`
- **Add descriptive names** and attributes to every check
- **Use alert configurations** for gradual degradation detection
- **Combine with filters** for subset testing
- **Test patterns** with small data samples first

### ❌ DON'T:

- Don't use `valid values` for high-cardinality data (use ranges or patterns)
- Don't collect samples for PII without `samples columns` restriction
- Don't use `valid format` for custom formats (use `valid regex`)
- Don't forget to set `samples limit: 0` for sensitive data checks
- Don't use regex when built-in formats exist (prefer `valid format: email`)
- Don't skip the `name` attribute in `failed rows` checks
- Don't write complex SQL in `fail condition` (use `fail query` instead)

---

## Validity vs Missing vs Completeness

**Key Differences:**

| Aspect | Missing | Invalid | Valid |
|--------|---------|---------|-------|
| **Definition** | NULL or custom missing values | Present but doesn't meet criteria | Present and meets criteria |
| **Check Type** | `missing_count`, `missing_percent` | `invalid_count`, `invalid_percent` | `valid_count`, `valid_percent` |
| **Example** | NULL email | "not-an-email" | "user@example.com" |
| **Dimension** | Completeness | Validity | Validity |

**Relationship:**
```
Total Rows = Missing + Invalid + Valid
100% = Missing % + Invalid % + Valid %
```

**Example Strategy:**

```yaml
# Check BOTH completeness and validity
completeness:
  - missing_count(email) = 0:
      name: email_required

validity:
  - invalid_count(email) = 0:
      valid format: email
      name: email_format_valid
```

This ensures:
1. Email is present (not NULL) ← Completeness
2. Email is in valid format ← Validity

---

## Integration with Other Layers

**Validity works with:**

1. **Audits** (Section 6) - Critical validity that blocks pipeline
   ```sql
   MODEL (
     audits (
       accepted_values(column := status, is_in := ('active', 'churned'))
     )
   );
   ```

2. **Checks** (this section) - Monitoring with samples
   ```yaml
   validity:
     - invalid_count(status) = 0:
         valid values: [active, churned]
         samples limit: 10
   ```

3. **Profiles** (Section 7.5) - Track invalid% over time
   ```sql
   MODEL (
     profiles (email, phone_number)
   );
   ```

---

## Related Check Types

- **Completeness** (Section 7.3.1) - Checks if values are present
- **Uniqueness** (Section 7.3.3) - Checks for duplicates
- **Conformity** (Section 7.3.5) - Schema and type validation

---

## Status

- ✅ **Verified** against b2b_saas examples
- ✅ **Documented** all SodaCL validity features
- ✅ **Includes** failed rows checks with real patterns
- ✅ **Includes** validity metrics (invalid_count, valid_format, valid_values, valid_regex)
- ⏳ **Pending** integration into main book

---

**Next Dimension:** Uniqueness (7.3.3) - Duplicate detection, unique constraints

