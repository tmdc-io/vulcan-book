# Vulcan Errors Reference Guide

This is a comprehensive reference guide for all error messages you may encounter when using Vulcan. **Copy and paste any error message into your browser's search (Ctrl+F / Cmd+F) to quickly find the cause and resolution.**

---

## How to Use This Guide

1. **Copy the error message** you're seeing
2. **Press Ctrl+F (Windows/Linux) or Cmd+F (Mac)** to open search
3. **Paste the error message** and search
4. **Find the matching entry** with the error, cause, and resolution

---

## Table of Contents

1. [Setup & Infrastructure Errors](#1-setup--infrastructure-errors)
2. [Model & SQL Errors](#2-model--sql-errors)
3. [Semantic Layer Errors](#3-semantic-layer-errors)
4. [Plan & Run Errors](#4-plan--run-errors)
5. [Tests and Checks Errors](#5-tests-and-checks-errors)
6. [Audit Errors](#6-audit-errors)
7. [State & Migration Errors](#7-state--migration-errors)
8. [API & Service Errors](#8-api--service-errors)
9. [Configuration Errors](#9-configuration-errors)
10. [Connection & Database Errors](#10-connection--database-errors)
11. [Engine-Specific Errors](#11-engine-specific-errors)
12. [Transpiler Errors](#12-transpiler-errors)
13. [Linter Errors](#13-linter-errors)
14. [Python Model Errors](#14-python-model-errors)

---

## 1. Setup & Infrastructure Errors

### 1.1 Services Won't Start

**Error Message:**
```
Services fail to start
Docker containers exit immediately
```

**Cause:** Docker Desktop may not have enough resources allocated or may not be running.

**Resolution:**
- Ensure Docker Desktop is running
- Allocate at least 4GB RAM in Docker Desktop settings:
  - **Mac**: Docker Desktop → Settings → Resources → Advanced
  - **Windows**: Docker Desktop → Settings → Resources → Advanced
- Check Docker Desktop logs for specific errors

---

### 1.2 Network Errors

**Error Message:**
```
network vulcan not found
network-related errors
docker network errors
```

**Cause:** The `vulcan` Docker network doesn't exist.

**Resolution:**
```bash
# Check if network exists
docker network ls | grep vulcan

# Create the network if it doesn't exist
docker network create vulcan
```

---

### 1.3 Port Conflicts

**Error Message:**
```
port already in use
address already in use
bind: address already in use
port 5431/5433/9000/9001/8000 already in use
```

**Cause:** One of the required ports (5431, 5433, 9000, 9001, or 8000) is occupied by another application.

**Resolution:**
1. **Stop the conflicting application** using that port
2. **Modify port mappings** in Docker Compose files:
   - `docker/docker-compose.infra.yml`
   - `docker/docker-compose.warehouse.yml`
   - `docker/docker-compose.vulcan.yml`

---

### 1.4 Can't Connect to Services

**Error Message:**
```
unable to connect to services
connection refused
service not available
```

**Cause:** Required services are not running or not accessible.

**Resolution:**
```bash
# Verify services are running
docker compose -f docker/docker-compose.infra.yml ps
docker compose -f docker/docker-compose.warehouse.yml ps
docker compose -f docker/docker-compose.vulcan.yml ps

# Check service logs
docker compose -f docker/docker-compose.infra.yml logs
docker logs vulcan-api
docker logs vulcan-transpiler

# Ensure all services show as "Up" or "running"
# If any show as "Exited" or "Stopped", check logs for errors
```

---

### 1.5 Permission Denied

**Error Message:**
```
permission denied
PermissionError
cannot create .logs folder
```

**Cause:** Insufficient file system permissions.

**Resolution:**
```bash
# Create .logs folder manually
mkdir .logs

# Change permissions
chmod 755 .logs

# On Windows, ensure you have write permissions in the project directory
```

---

## 2. Model & SQL Errors

### 2.1 Model Definition Errors

#### 2.1.1 Model definitions have changed. Use 'vulcan plan' to apply changes first

**Error Message:**
```
Error: Model definitions have changed. Use 'vulcan plan' to apply changes first.

Changed models:
└── model_name

Please run 'vulcan plan' to apply these changes before using 'vulcan run'.
```

**Cause:** You're trying to run models that have been modified without applying a plan first.

**Resolution:**
```bash
# Always run plan first when models change
vulcan plan

# Then apply the plan
# After plan is applied, you can use vulcan run
```

---

### 2.2 SQL Syntax Errors

#### 2.2.1 SQL Syntax Error

**Error Message:**
```
SQL syntax error
invalid SQL syntax
syntax error at or near
```

**Cause:** Invalid SQL syntax in your model file.

**Resolution:**
- Review the SQL syntax in your model file
- Check for missing commas, quotes, or parentheses
- Validate SQL using a SQL validator
- Use the linter to catch syntax errors: `vulcan lint --model model_name`

---

### 2.3 Column & Table Reference Errors

#### 2.3.1 Column Does Not Exist

**Error Message:**
```
column "column_name" does not exist
relation "table_name" does not exist
```

**Cause:** Referenced column or table doesn't exist in the database or upstream model.

**Resolution:**
- Verify the column/table name spelling (case-sensitive)
- Check if the upstream model has been applied: `vulcan plan`
- Ensure the model dependency is correct
- Check if the table exists: `vulcan fetchdf "SELECT * FROM schema.table_name LIMIT 1"`

#### 2.3.2 Ambiguous Column Reference

**Error Message:**
```
ambiguous column reference
column reference is ambiguous
```

**Cause:** Column name exists in multiple tables in a JOIN without proper qualification.

**Resolution:**
- Qualify column names with table aliases: `table_alias.column_name`
- Use explicit table prefixes in SELECT statements
- Review JOIN conditions to ensure proper table relationships

#### 2.3.3 Invalid SELECT Star Expansion

**Error Message:**
```
invalid select star expansion
SELECT * expansion error
```

**Cause:** Using `SELECT *` in a context where column expansion is ambiguous or invalid.

**Resolution:**
- Replace `SELECT *` with explicit column names
- Use table aliases: `SELECT alias.column1, alias.column2`
- Avoid `SELECT *` in JOINs or CTEs

---

### 2.4 File & Encoding Errors

#### 2.4.1 UTF-8 Encoding Error

**Error Message:**
```
encoding error
UTF-8 encoding error
parsing errors
```

**Cause:** SQL model file is not UTF-8 encoded.

**Resolution:**
- Ensure all SQL model files are saved as UTF-8
- Convert file encoding if necessary
- Check file encoding in your editor settings

---

## 3. Semantic Layer Errors

### 3.1 Member Reference Errors

#### 3.1.1 Unknown member: X

**Error Message:**
```
Unknown member: X
Member 'X' not found
```

**Cause:** Member doesn't exist in semantic model or is misspelled.

**Resolution:**
- Verify member exists in your semantic model definitions
- Check spelling and casing (case-sensitive): `users.plan_type` ≠ `users.Plan_Type`
- Use fully qualified format: `alias.member_name` (always include alias prefix)
- Review semantic model files in `semantics/` directory

#### 3.1.2 Measure not found: X

**Error Message:**
```
Measure not found: X
Measure 'X' does not exist
```

**Cause:** Measure referenced without proper qualification or doesn't exist.

**Resolution:**
- **For SQL format**: Use `MEASURE(measure_name)` wrapper
- **For JSON format**: Use fully qualified format `alias.measure_name`
- Verify measure is defined in semantic model
- Check semantic model YAML files for measure definitions

#### 3.1.3 Model not found: X

**Error Message:**
```
Model not found: X
Semantic model 'X' not found
```

**Cause:** Alias doesn't match any semantic model.

**Resolution:**
- Check semantic model aliases in `semantics/` directory
- Verify alias spelling and casing
- Ensure semantic models are properly defined in YAML files
- Run `vulcan plan` to ensure semantic models are loaded

---

### 3.2 Format & Syntax Errors

#### 3.2.1 Invalid JSON format

**Error Message:**
```
Invalid JSON format
JSON parsing error
malformed JSON
```

**Cause:** JSON payload is malformed.

**Resolution:**
- Validate JSON syntax using a JSON validator
- Ensure proper quoting of strings
- Check array and object structure
- Verify all brackets and braces are properly closed

#### 3.2.2 Projection references non-aggregate values

**Error Message:**
```
Projection references non-aggregate values
non-aggregated columns not in GROUP BY
```

**Cause:** Non-aggregated columns not in GROUP BY, or measures missing MEASURE() wrapper.

**Resolution:**
- Add all non-aggregated columns to GROUP BY clause
- Use MEASURE() wrapper for all measures in SQL format
- Ensure proper aggregation when mixing aggregated and non-aggregated columns

---

### 3.3 Dependency & Relationship Errors

#### 3.3.1 Circular dependency detected

**Error Message:**
```
Circular dependency detected
circular reference in semantic model
```

**Cause:** Semantic model has circular dependencies (e.g., Model A depends on Model B, which depends on Model A).

**Resolution:**
- Review semantic model dependencies
- Break the circular dependency by restructuring models
- Check join definitions in semantic models
- Review model relationships in `semantics/` directory

#### 3.3.2 Duplicate field names

**Error Message:**
```
duplicate field names found: [...]
```

**Cause:** A semantic model defines the same field more than once. Vulcan doesn't try to guess which one you meant.

**Resolution:**
- Ensure each field name appears only once per semantic model
- Rename or remove duplicates
- Check semantic model YAML files for duplicate field definitions

#### 3.3.3 Time dimensions must be TIMESTAMP

**Error Message:**
```
'<field>' uses DATE type. Time dimensions require TIMESTAMP
```

**Cause:** Semantic time dimensions must be `TIMESTAMP`, but the underlying SQL model returns a `DATE`.

**Resolution:**
Cast the column in the SQL model output and keep the alias unchanged:
```sql
CAST(order_date AS TIMESTAMP) AS order_date
```
Do this in the model SQL, not in the semantics YAML.

#### 3.3.4 Unknown columns referenced by semantics

**Error Message:**
```
dimensions reference unknown columns on model '<alias>'
```

**Cause:** The semantics YAML references a column that doesn't exist in the model output.

**Resolution:**
- Update the semantic model to reference a column that actually exists
- Verify the column name spelling and casing
- Check that the model has been applied and the column exists
- Review model output schema

#### 3.3.5 Circular join dependency detected

**Error Message:**
```
Circular join dependency detected
```

**Cause:** Two semantic models join to each other, directly or indirectly. The semantic join graph must be acyclic.

**Resolution:**
- Pick a direction and stick to it. A common pattern is: **Fact → Dimension**
- Remove the reverse join and keep a single, one-directional path
- Review semantic join definitions to eliminate circular references

#### 3.3.6 Proxy measure has no join path

**Error Message:**
```
proxy '<proxy>' references '<model>.<measure>' but no join path exists
```

**Cause:** Proxy measures can only reference models that are connected through the semantic join graph.

**Resolution:**
- Add a join path between the models, directly or transitively
- Avoid adding joins in both directions
- Review semantic join graph to ensure connectivity

---

## 4. Plan & Run Errors

### 4.1 Plan Errors

#### 4.1.1 Plan application failed

**Error Message:**
```
Plan application failed.
PlanError: Plan application failed
```

**Cause:** One or more models failed during plan evaluation, often due to audit failures or SQL errors.

**Resolution:**
- Check the error details in the output
- Review audit failures (see Audit Errors section)
- Fix SQL errors in failing models
- Check model dependencies
- Review logs: `.logs/vulcan_*.log`

---

### 4.2 Execution Errors

#### 4.2.1 Execution failed for node

**Error Message:**
```
Execution failed for node EvaluateNode
NodeExecutionFailedError
```

**Cause:** Model evaluation failed during plan or run execution.

**Resolution:**
- Check the specific model that failed
- Review SQL syntax and logic
- Verify database connections
- Check for data quality issues
- Review audit results if audits are configured

---

### 4.3 State & Interval Errors

#### 4.3.1 No changes to apply

**Error Message:**
```
No changes to apply
Nothing to do
```

**Cause:** No model changes detected or all intervals are already processed.

**Resolution:**
- This is normal when everything is up to date
- If you expected changes, verify:
  - Model files were saved
  - You're in the correct directory
  - Changes match the target environment

#### 4.3.2 Missing intervals check failed

**Error Message:**
```
Missing intervals check failed
interval validation error
```

**Cause:** Interval calculation or validation failed.

**Resolution:**
- Check model `start` date and `cron` schedule
- Verify date formats are correct
- Review incremental model configuration
- Ensure timezone settings are consistent

---

## 5. Tests and Checks Errors

### 5.1 Check Errors

#### 5.1.1 Check snapshot name parsing fails

**Error Message:**
```
Failed to parse '__checks...:completeness' into Table
```

**Cause:** Some check snapshot names include `:` characters, which can confuse SQL parsing during planning.

**Resolution:**
- Upgrade Vulcan if this is fixed upstream
- Temporarily disable the checks generating `__checks.*` snapshots

#### 5.1.2 Checks reference a model that doesn't exist

**Error Message:**
```
Model '<model>' not found. Did you mean ...?
```

**Cause:** The checks YAML references a model name that doesn't exist, often due to a singular vs plural mismatch.

**Resolution:**
- Update the checks file to reference the correct model name
- Verify model name spelling and casing
- Check for singular vs plural mismatches

#### 5.1.3 Checks fail with relation does not exist

**Error Message:**
```
relation '<schema>.<table>' does not exist
```

**Cause:** The model was built successfully, but the checks are pointing at a different schema or environment name.

**Resolution:**
- Align check targets with the schema naming Vulcan uses for that environment
- Verify the schema name matches the environment configuration
- Check if environment-specific schema suffixes are needed

---

### 5.2 Test Errors

#### 5.2.1 Plan blocked by failing tests

**Error Message:**
```
Cannot generate plan due to failing test(s)
```

**Cause:** Vulcan runs tests during planning. If they fail, planning stops. A common gotcha is test fixture collisions, where multiple tests reuse the same primary keys.

**Resolution:**
- Ensure all tests use globally unique IDs
- Or configure isolated test execution if your setup supports it
- Review test fixtures for ID collisions
- Check test data for conflicts

---

## 6. Audit Errors

### 6.1 Audit Failure Errors

#### 6.1.1 Audits failed: [audit_name]

**Error Message:**
```
Audits failed: [audit_name]
NodeAuditsErrors: Audits failed
audit query returned rows
```

**Cause:** Audit query returned rows, indicating bad data was found.

**Resolution:**
1. **Find the root cause**: Look at audit query results to see what data failed
2. **Check upstream models**: Verify data in source models
3. **Fix the source data**: Correct the data issue at its origin
4. **Re-run**: Execute `vulcan plan` or `vulcan run` again after fixing

**Note:** 
- With `vulcan plan`: Bad data stays in isolated table, production is safe
- With `vulcan run`: Bad data is already in production table, must fix and re-run

#### 6.1.2 Audits failed: unique_values

**Error Message:**
```
NodeAuditsErrors: Audits failed: unique_values
```

**Cause:** A model defines a `unique_values(...)` audit, but the data produced by the model isn't actually unique for those columns. This is especially common in demos, seeds, or test data where the grain doesn't quite match the audit definition.

**Resolution:**
- Fix the upstream data so the columns really are unique
- Update the audit to match the true grain of the model
- Remove or relax audit for local or demo runs (NOT RECOMMENDED for production)
- For sample projects, removing the audit is often the fastest path forward

---

### 6.2 Audit Configuration Errors

#### 6.2.1 Audit query syntax error

**Error Message:**
```
audit query syntax error
invalid audit SQL
```

**Cause:** SQL syntax error in audit definition.

**Resolution:**
- Review audit SQL syntax
- Ensure audit queries return rows for bad data (not good data)
- Test audit query independently: `vulcan fetchdf "your_audit_query"`
- Check for proper table references and column names

---

## 7. State & Migration Errors

### 7.1 Version Mismatch Errors

#### 7.1.1 Vulcan version mismatch

**Error Message:**
```
State import failed!
Error: Vulcan version mismatch. You are running 'X.X.X' but the state file was created with 'Y.Y.Y'.
Please upgrade/downgrade your Vulcan version to match the state file before performing the import.
```

**Cause:** State file was created with a different Vulcan version.

**Resolution:**

**Option 1: Use matching version**
```bash
# Install the version that created the state file
pip install "vulcan==Y.Y.Y"

# Import state
vulcan state import -i state.json

# Then upgrade Vulcan
pip install --upgrade "vulcan==X.X.X"
vulcan migrate
vulcan state export -o state_updated.json
```

**Option 2: Upgrade state file**
1. Import state with old version
2. Upgrade Vulcan version
3. Run `vulcan migrate`
4. Export state with new version

#### 7.1.2 Version mismatch error

**Error Message:**
```
version mismatch error
state database version mismatch
```

**Cause:** State database structure is out of date.

**Resolution:**
```bash
# Run migrations to update state database
vulcan migrate

# Then retry your operation
```

---

### 7.2 State Import/Export Errors

#### 7.2.1 State import failed

**Error Message:**
```
State import failed!
state import error
```

**Cause:** State import encountered an error (version mismatch, invalid format, or database error).

**Resolution:**
- Check error message for specific cause
- Ensure state database is up to date: `vulcan migrate`
- Verify state file format is valid JSON
- Check database permissions and connectivity
- Review state file for corruption

#### 7.2.2 State database structure must be present

**Error Message:**
```
state database structure must be present
state database not initialized
```

**Cause:** State database hasn't been initialized or migrated.

**Resolution:**
```bash
# Initialize/migrate state database
vulcan migrate

# Then retry your operation
```

---

## 8. API & Service Errors

### 8.1 Connection Errors

#### 8.1.1 Connection refused

**Error Message:**
```
connection refused
ConnectionError
cannot connect to API
```

**Cause:** API service is not running or not accessible.

**Resolution:**
```bash
# Verify services are running
docker ps

# Check API container logs
docker logs vulcan-api

# Ensure Docker network exists
docker network create vulcan

# Start API services
make vulcan-up
# OR
docker compose -f docker/docker-compose.vulcan.yml up -d

# Verify API is accessible
curl http://localhost:8000/health
```

#### 8.1.2 API not accessible

**Error Message:**
```
API not accessible
cannot reach API endpoint
```

**Cause:** API services not started or ports blocked.

**Resolution:**
- Ensure infrastructure services are running: `make setup`
- Ensure API services are started: `make vulcan-up`
- Check Docker containers: `docker ps`
- Verify ports are not blocked (8000 for REST API, 4000 for GraphQL)
- Check firewall settings

---

### 8.2 API Query Errors

#### 8.2.1 Model not found (API)

**Error Message:**
```
Model not found
model 'X' not found in API
```

**Cause:** Model hasn't been applied via plan or semantic model not defined.

**Resolution:**
- Ensure you've created and applied a plan: `vulcan plan`
- Verify semantic models are defined in `semantics/` directory
- Check model aliases match your queries
- Ensure API service has access to project files

---

### 8.3 Service Configuration Errors

#### 8.3.1 Transpiler service error

**Error Message:**
```
transpiler service error
VULCAN_API_URL connection error
```

**Cause:** Transpiler service cannot connect to Vulcan API.

**Resolution:**
- Verify `VULCAN_API_URL` environment variable is correct
- Ensure Vulcan API is running: `docker ps | grep vulcan-api`
- Check transpiler service logs: `docker logs vulcan-transpiler`
- Verify network connectivity between services

---

## 9. Configuration Errors

### 9.1 Configuration File Errors

#### 9.1.1 Invalid configuration

**Error Message:**
```
invalid configuration
configuration error
config.yaml error
```

**Cause:** Configuration file has syntax errors or invalid values.

**Resolution:**
- Validate YAML syntax in `config.yaml`
- Check indentation (YAML is sensitive to spacing)
- Verify all required fields are present
- Review configuration reference documentation
- Use a YAML validator

---

### 9.2 Gateway & Connection Configuration Errors

#### 9.2.1 Gateway not found

**Error Message:**
```
gateway not found
gateway 'X' does not exist
```

**Cause:** Referenced gateway doesn't exist in configuration.

**Resolution:**
- Check `config.yaml` for gateway definitions
- Verify gateway name spelling
- Ensure `default_gateway` is set if not specifying `--gateway`
- Review gateway configuration syntax

#### 9.2.2 Connection configuration error

**Error Message:**
```
connection configuration error
database connection failed
```

**Cause:** Database connection settings are incorrect.

**Resolution:**
- Verify connection parameters in `config.yaml`:
  - Host, port, database name
  - Username and password
  - Connection type matches your database
- Test connection independently
- Check network connectivity to database
- Verify database credentials

---

### 9.3 Model Configuration Errors

#### 9.3.1 Model defaults missing

**Error Message:**
```
model defaults missing
required model_defaults not found
```

**Cause:** Required `model_defaults` section missing from configuration.

**Resolution:**
- Add `model_defaults` section to `config.yaml`:
```yaml
model_defaults:
  dialect: postgres  # or your SQL engine
  start: 2024-01-01
  cron: '@daily'
```
- Ensure all required fields are present
- Verify dialect matches your database engine

---

## 10. Connection & Database Errors

### 10.1 Database Connection Errors

#### 10.1.1 Database connection failed

**Error Message:**
```
database connection failed
cannot connect to database
connection timeout
```

**Cause:** Cannot establish connection to database.

**Resolution:**
- Verify database is running and accessible
- Check connection parameters (host, port, database)
- Verify network connectivity
- Check firewall rules
- Ensure database credentials are correct
- Test connection: `vulcan info`

---

### 10.2 Table & Object Errors

#### 10.2.1 Table does not exist

**Error Message:**
```
table does not exist
relation does not exist
```

**Cause:** Referenced table hasn't been created yet.

**Resolution:**
- Run `vulcan plan` to create tables
- Verify model has been applied
- Check schema name is correct
- Ensure you're querying the right environment

---

### 10.3 Permission Errors

#### 10.3.1 Permission denied (database)

**Error Message:**
```
permission denied
insufficient privileges
access denied
```

**Cause:** Database user lacks required permissions.

**Resolution:**
- Verify database user has CREATE, SELECT, INSERT, UPDATE, DELETE permissions
- Check schema permissions
- Ensure user can create tables in target schema
- Review database user role and privileges

---

### 10.4 Object Naming Errors

#### 10.4.1 Object name length limitation

**Error Message:**
```
object name length limitation
table name too long
name exceeds maximum length
```

**Cause:** Table or view name exceeds database engine's maximum length.

**Resolution:**
- Shorten model or schema names
- Review database engine's name length limits
- Use shorter aliases in model definitions
- Consider naming conventions to keep names concise

---

### 10.5 Engine-Specific Operation Errors

#### 10.5.1 Delta table unsupported operation

**Error Message:**
```
DELTA_UNSUPPORTED_DROP_COLUMN
DROP COLUMN is not supported for your Delta table
```

**Cause:** Attempting unsupported operation on Delta table (Databricks).

**Resolution:**
- Ensure `enable_delta_alter` is set in model configuration
- Use Delta-compatible operations only
- Review Databricks Delta table limitations
- Consider alternative approaches for schema changes

---

## 11. Engine-Specific Errors

### 11.1 Spark Engine Errors

#### 11.1.1 Spark catalog does not support views

**Error Message:**
```
Catalog postgres does not support views
```

**Cause:** Spark's JDBC v2 catalog does not support views, but Vulcan's virtual-layer promotion attempts to create them.

**Resolution:**
- Promote into a catalog that supports views, or
- Disable virtual-layer promotion for that target

#### 11.1.2 Upstream model not found (Spark)

**Error Message:**
```
TABLE_OR_VIEW_NOT_FOUND
```

**Cause:** A downstream model references a logical model name that doesn't exist at execution time. Common causes:
- The upstream model was renamed or removed
- A previous plan failed and never created the upstream object
- The project is in a partially-applied state

**Resolution:**
- Verify the SQL reference points to the correct model
- If state looks confusing, run `vulcan destroy` and start fresh
- Check that upstream models have been applied: `vulcan plan`
- Review model dependencies

---

### 11.2 Postgres Engine Errors

#### 11.2.1 Postgres relation does not exist

**Error Message:**
```
UndefinedTable: relation '<schema>.<table>' does not exist
```

**Cause:** The SQL references a table that doesn't exist, often due to a typo or singular vs plural mismatch.

**Resolution:**
- Fix the table name in the SQL or ensure the expected external table exists
- Verify table name spelling and casing
- Check if the model has been applied: `vulcan plan`
- Ensure you're querying the correct schema/environment

---

## 12. Transpiler Errors

### 12.1 General Troubleshooting

Before troubleshooting specific transpiler errors, follow these general steps:

**Step 1: Ensure Latest Version**
- Use the latest Vulcan version to get the most recent transpiler fixes and improvements
- Check your version: `vulcan --version`
- Update if needed: `pip install --upgrade vulcan`

**Step 2: Verify Configuration**
- Ensure `config.yaml` has correct transpiler configuration syntax:
```yaml
transpiler:
  # Override via VULCAN_TRANSPILER_BASE_URL for host runs if needed.
  base_url: "{{ env_var('VULCAN_TRANSPILER_BASE_URL', 'http://vulcan-transpiler:4000/transpiler') }}"
```
- Verify the transpiler service is running: `docker ps | grep vulcan-transpiler`
- Check transpiler service logs: `docker logs vulcan-transpiler`

**Step 3: Verify Semantic Models**
- Ensure semantic models are properly defined in `semantics/` directory
- Run `vulcan plan` to ensure semantic models are loaded
- Verify semantic model aliases match your queries

**Step 4: Test Basic Transpilation**
- Test with a simple query: `vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"`
- If basic queries fail, check service connectivity and configuration

---

### 12.2 Format Errors

#### 12.2.1 Invalid transpile format

**Error Message:**
```
invalid transpile format
format must be 'sql' or 'json'
```

**Cause:** Invalid format specified for transpile command.

**Resolution:**
- Use `--format sql` for semantic SQL queries
- Use `--format json` for REST API payload format
- Ensure format parameter is correctly specified

---

### 12.3 Query Errors

#### 12.3.1 Transpile query error

**Error Message:**
```
transpile query error
failed to transpile query
```

**Cause:** Query syntax is invalid or references non-existent members.

**Resolution:**
- **Verify semantic query syntax** - Check query follows correct format
- **Check that all referenced members exist** - Verify members are defined in semantic models
- **Ensure proper use of MEASURE() wrapper** - Use `MEASURE(measure_name)` for SQL format
- **Use fully qualified names** - Always use `alias.member_name` format
- **Review semantic model definitions** - Check `semantics/` directory for correct definitions
- **Verify transpiler configuration** - Ensure `config.yaml` has correct `transpiler.base_url` setting
- **Check transpiler service** - Verify service is running and accessible

---

### 12.4 Syntax Errors

#### 12.4.1 Segment syntax error

**Error Message:**
```
segment syntax error
invalid segment usage
```

**Cause:** Segments used incorrectly in query.

**Resolution:**
- Segments only support `= true`, not `= false`
- Use format: `WHERE segment_name = true`
- Verify segment is defined in semantic model
- Check segment syntax matches expected format

---

## 13. Linter Errors

### 13.1 General Linter Errors

#### 13.1.1 Linter rule violation

**Error Message:**
```
linter rule violation
linting error
```

**Cause:** Code violates configured linting rules.

**Resolution:**
- Review linter output for specific rule violation
- Fix the code to comply with linting rules
- Check `config.yaml` for enabled linting rules
- Use `vulcan lint --model model_name` to see details
- Review linter documentation for rule explanations

---

### 13.2 Specific Rule Violations

#### 13.2.1 Ambiguous or invalid column

**Error Message:**
```
ambiguous or invalid column
ambiguousorinvalidcolumn rule violation
```

**Cause:** Column reference is ambiguous or invalid.

**Resolution:**
- Qualify column names with table aliases
- Verify column exists in referenced table
- Check JOIN conditions
- Use explicit table prefixes

#### 13.2.2 Invalid SELECT star expansion

**Error Message:**
```
invalid select star expansion
invalidselectstarexpansion rule violation
```

**Cause:** Using `SELECT *` in invalid context.

**Resolution:**
- Replace `SELECT *` with explicit column names
- Use table aliases when selecting columns
- Avoid `SELECT *` in JOINs or subqueries

---

## 14. Python Model Errors

### 14.1 Execution Errors

#### 14.1.1 Python model execution error

**Error Message:**
```
Python model execution error
model evaluation failed
```

**Cause:** Error in Python model code or dependencies.

**Resolution:**
- Review Python model code for syntax errors
- Check that all required Python packages are installed
- Verify model returns a pandas DataFrame
- Check for import errors
- Review model logs for specific Python errors

---

### 14.2 Dependency Errors

#### 14.2.1 Missing Python dependency

**Error Message:**
```
ModuleNotFoundError
ImportError
missing dependency
```

**Cause:** Required Python package not installed.

**Resolution:**
- Install missing package: `pip install package_name`
- Check model requirements
- Verify Python environment has all dependencies
- Review model's import statements

---

### 14.3 Format Errors

#### 14.3.1 DataFrame format error

**Error Message:**
```
DataFrame format error
model must return DataFrame
```

**Cause:** Python model doesn't return a pandas DataFrame.

**Resolution:**
- Ensure model function returns `pd.DataFrame`
- Check return statement in model code
- Verify DataFrame structure matches expected schema
- Review model output format

---

## General Troubleshooting Tips

### Log Locations

Most issues surface in:
- `.logs/vulcan_*.log`

If something fails, start there.

### Check Logs

Always check logs for detailed error information:

```bash
# View recent logs
ls -lt .logs/

# View specific log file
cat .logs/vulcan_YYYY_MM_DD_HH_MM_SS.log

# Tail logs in real-time (if available)
tail -f .logs/vulcan_*.log
```

### Verify Setup

```bash
# Check project info
vulcan info

# Verify connections
vulcan info | grep -i connection

# Check Docker services
docker ps
```

### Common Commands for Debugging

```bash
# Validate models
vulcan lint

# Render SQL to see what will execute
vulcan render model_name

# Test query execution
vulcan fetchdf "SELECT * FROM schema.model_name LIMIT 1"

# Check plan without applying
vulcan plan --explain

# Transpile semantic queries
vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"
```

---

## Still Can't Find Your Error?

If you can't find your error message in this guide:

1. **Check the full error output** - Often the root cause is in the stack trace
2. **Review logs** - Check `.logs/vulcan_*.log` files for detailed information
3. **Search error keywords** - Try searching for key phrases from the error
4. **Check component-specific docs**:
   - Models: `docs/components/model/`
   - Semantics: `docs/components/semantics/`
   - Configuration: `docs/references/configuration.md`
   - Plans: `docs/references/plans.md`
5. **Verify your setup** - Ensure all prerequisites are met and services are running

---

## Error Categories Quick Reference

| Category | Common Errors |
|----------|-------------|
| **Setup** | Services won't start, network errors, port conflicts |
| **Models** | SQL syntax errors, column not found, ambiguous references |
| **Semantics** | Unknown member, measure not found, invalid JSON |
| **Plans** | Plan application failed, execution failed, no changes |
| **Audits** | Audits failed, audit query errors |
| **State** | Version mismatch, import failed, database structure |
| **API** | Connection refused, model not found, service errors |
| **Config** | Invalid configuration, gateway not found, connection errors |
| **Database** | Connection failed, permission denied, table not found |
| **Transpiler** | Invalid format, query errors, segment syntax |
| **Linter** | Rule violations, ambiguous columns, invalid SELECT * |
| **Python** | Execution errors, missing dependencies, DataFrame format |

---

*Last Updated: Based on Vulcan documentation and common error patterns*
