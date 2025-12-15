# Checks

Quality checks monitor data quality over time without blocking your pipeline. They track trends, detect anomalies, and help you build data quality dashboards.

## Quick start

### Your first check

Create a check file in your `checks/` directory:

```yaml
# checks/customers.yml
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_emails
          attributes:
            description: "All customers must have an email address"
```

Checks run automatically when models are executed through a plan or run command.

### Running checks manually

You can also run checks independently:

```bash
$ vulcan check
Running checks...

✓ analytics.customers.no_missing_emails
  Pass: missing_count(email) = 0 (actual: 0)

----------------------------------------------------------------------
Ran 1 check in 0.234s

OK
```

## Check execution

Checks and profiles run automatically when models are executed. Here's what the output looks like:

```bash
Check Executions (1 Models)
└── hello.subscriptions
    ├── ✓ completeness (4/4)
    ├── ✓ uniqueness (1/1)
    └── ✓ validity (3/3)

Profiled 1 model (3 columns):
  ✓ warehouse.hello.subscriptions: 3 columns
```

## Common check patterns

### Completeness checks

Ensure required data is present:

```yaml
checks:
  analytics.orders:
    completeness:
      - missing_count(customer_id) = 0:
          name: customer_id_required
      
      - missing_percent(email) < 5:
          name: email_mostly_complete
      
      - row_count > 1000:
          name: sufficient_orders
```

### Validity checks

Validate data format and values:

```yaml
checks:
  analytics.users:
    validity:
      - failed rows:
          name: invalid_emails
          fail query: |
            SELECT user_id, email
            FROM analytics.users
            WHERE email NOT LIKE '%@%'
          samples limit: 10
      
      - failed rows:
          name: invalid_ages
          fail query: |
            SELECT user_id, age
            FROM analytics.users
            WHERE age < 0 OR age > 120
```

### Uniqueness checks

Ensure no duplicates:

```yaml
checks:
  analytics.customers:
    uniqueness:
      - duplicate_count(email) = 0:
          name: unique_emails
      
      - duplicate_count(customer_id, order_date) = 0:
          name: unique_customer_date_combination
```

### Anomaly detection

Detect unusual patterns using historical data:

```yaml
checks:
  analytics.daily_revenue:
    accuracy:
      - anomaly detection for row_count:
          name: row_count_anomaly
      
      - anomaly detection for avg(revenue):
          name: revenue_anomaly
```

**Note:** Anomaly detection needs historical data (30+ runs recommended) to build accurate models.

### Change monitoring

Track changes compared to previous runs:

```yaml
checks:
  analytics.orders:
    timeliness:
      - change for row_count >= -50%:
          name: row_count_drop_alert
          attributes:
            description: "Alert if row count drops more than 50%"
```

## Organizing checks

### File structure

Organize checks by domain or table:

```
project/
├── models/
├── checks/
│   ├── users.yml           # Checks for user tables
│   ├── orders.yml          # Checks for order tables
│   ├── revenue.yml         # Checks for revenue tables
│   └── cross_model.yml     # Checks spanning multiple tables
└── config.yaml
```

### Multiple models in one file

Group related checks together:

```yaml
checks:
  analytics.customers:
    completeness:
      - missing_count(email) = 0:
          name: no_missing_emails
  
  analytics.orders:
    completeness:
      - missing_count(customer_id) = 0:
          name: orders_have_customers
```

## Filtering checks

Apply checks to a subset of data:

```yaml
checks:
  analytics.orders:
    filter: "status = 'completed' AND order_date >= CURRENT_DATE - INTERVAL '30 days'"
    
    completeness:
      - missing_count(customer_id) = 0:
          name: completed_orders_have_customers
```

Use multiple filters for different scenarios:

```yaml
checks:
  analytics.customers:
    filter: "country = 'US'"
    completeness:
      - row_count > 1000
  
  analytics.customers:
    filter: "country = 'EU'"
    completeness:
      - row_count > 500
```

## Using Vulcan variables

Vulcan injects runtime variables into check execution:

```yaml
checks:
  analytics.events:
    completeness:
      - row_count > 0:
          name: daily_records_exist
          filter: "created_at >= CAST('${run_date}' AS DATE)"
          attributes:
            description: "At least one record created on run date"
```

**Available variables:**
- `${run_date}` - Current run date (YYYY-MM-DD format)
- `${environment}` - Environment name (prod, dev, staging)

## Failed row sampling

Control which failed rows are collected for debugging:

```yaml
checks:
  analytics.orders:
    validity:
      - failed rows:
          name: invalid_revenue
          fail query: |
            SELECT customer_id, revenue, order_date
            FROM analytics.orders
            WHERE revenue < 0 OR revenue > 10000000
          samples limit: 20
          attributes:
            description: "Revenue must be between 0 and 10M"
```

**Sampling options:**
- `samples limit: 20` - Collect up to 20 failed rows (default: 100)
- `samples limit: 0` - Disable sampling for sensitive data
- `samples columns: [id, status]` - Only collect specific columns

## Check attributes

Add metadata to help with monitoring and alerting:

```yaml
checks:
  analytics.revenue:
    completeness:
      - row_count > 1000:
          name: sufficient_revenue_data
          attributes:
            description: "Revenue table must have at least 1000 rows for analysis"
            severity: error
            tags: [critical, daily, revenue]
            owner: data-team
            jira: DATA-1234
            sla: "< 1 hour"
```

**Standard attributes:**
- `description` - Human-readable explanation
- `severity` - `error` (default) or `warning`
- `tags` - List of tags for filtering/organization
- `owner` - Team or person responsible
- Custom attributes - Any key-value pairs

## Cross-model validation

Validate relationships between models:

```yaml
checks:
  analytics.orders:
    consistency:
      - failed rows:
          name: orphaned_orders
          fail query: |
            SELECT o.order_id, o.customer_id
            FROM analytics.orders o
            LEFT JOIN analytics.customers c ON o.customer_id = c.customer_id
            WHERE c.customer_id IS NULL
          samples limit: 10
          attributes:
            description: "All orders must have a valid customer"
```

## Data quality dimensions

Organize checks by the 8 standard data quality dimensions:

1. **Completeness** - No missing required data
2. **Validity** - Data conforms to format/syntax
3. **Accuracy** - Data matches reality
4. **Consistency** - Data agrees across sources
5. **Uniqueness** - No duplicates
6. **Timeliness** - Data is current
7. **Conformity** - Follows standards
8. **Coverage** - All records are present

See the [checks concepts](../concepts/checks.md) for detailed examples of each dimension.

## Best practices

### ✅ DO:

- **Start with completeness** - Ensure required data is present
- **Use descriptive names** - Makes debugging easier
- **Add attributes** - Essential for monitoring dashboards
- **Limit samples** - Use `samples limit: 20` for large tables
- **Use filters** - Test checks on subsets before full deployment
- **Leverage anomaly detection** - After collecting 30+ data points

### ❌ DON'T:

- Don't use checks for critical blocking rules - Use audits instead
- Don't collect samples for PII - Set `samples limit: 0` or use `samples columns`
- Don't skip attributes - They're essential for monitoring
- Don't create too many checks initially - Start simple and add gradually

## Checks vs Audits vs Profiles

**Use Audits for:**
- Critical business rules that must pass
- Model-specific validation (runs inline)
- Blocking invalid data from flowing downstream

**Use Checks for:**
- Monitoring data quality trends over time
- Statistical anomaly detection
- Non-critical validation (warnings, not blockers)
- Cross-model validation

**Use Profiles for:**
- Understanding data characteristics
- Discovering patterns (not validation)
- Detecting data drift
- Informing which checks/audits to add

See the [checks concepts](../concepts/checks.md#checks-vs-audits-vs-profiles) for a detailed comparison.

## Troubleshooting

### Check failures

Investigate failed checks:

```bash
# Run specific check with verbose output
vulcan check --select analytics.customers.invalid_emails --verbose
```

### Performance issues

**Problem:** Check takes too long to run

**Solution:** Add filters to limit data scanned:

```yaml
checks:
  analytics.orders:
    filter: "order_date >= CURRENT_DATE - INTERVAL '30 days'"
    validity:
      - failed rows:
          fail query: |
            SELECT * FROM analytics.orders
            WHERE email NOT LIKE '%@%'
```

### False positives

**Problem:** Check fails during normal variance

**Solution:** Use ranges instead of exact values:

```yaml
# ❌ Too strict
completeness:
  - row_count = 10000

# ✅ Allow variance
completeness:
  - row_count between 9000 and 11000
```

Or use anomaly detection instead of fixed thresholds:

```yaml
accuracy:
  - anomaly detection for row_count:
      name: row_count_anomaly
```

## Next steps

- Learn about [data quality dimensions](../concepts/checks.md#data-quality-dimensions) - Comprehensive reference
- Set up [audits](./audits.md) - Critical blocking validation
- Read the [checks concepts](../concepts/checks.md) - Deep dive into how checks work
- Explore [data profiling](../concepts/checks.md#data-profiling) - Track metrics over time

