# Vulcan Project Lifecycle

A complete end-to-end guide to understanding how a Vulcan project flows from setup to production. Follow this linear path to see how all features work together.

---

## 🚀 Phase 1: Setup & Infrastructure

**Goal:** Get your environment ready for Vulcan

### Step 1: Start Infrastructure Services
```bash
make setup
# Creates: statestore, MinIO, warehouse database
```

**What happens:**
- Docker network `vulcan` is created
- Statestore (PostgreSQL) starts on port 5431 → Stores Vulcan's internal state
- MinIO starts on ports 9000/9001 → Stores query results and artifacts
- Warehouse database starts on port 5433 → Your data warehouse

### Step 2: Configure CLI Access
```bash
alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-postgres:0.228.2 vulcan"
```

**Verify it works:**
```bash
vulcan --help
```

---

## 📁 Phase 2: Project Initialization

**Goal:** Create your project structure

### Step 3: Initialize Project
```bash
vulcan init
```

**What gets created:**
```
your-project/
├── models/      # SQL/Python transformation models
├── seeds/       # CSV files for static data
├── audits/      # Data quality assertions
├── tests/       # Unit tests for models
├── macros/      # Reusable SQL patterns
├── checks/      # Data quality monitoring
├── semantics/   # Semantic layer (metrics, dimensions)
└── config.yaml  # Project configuration
```

### Step 4: Configure Project
Edit `config.yaml`:
- Set database connections
- Define model defaults (dialect, start date, cron schedule)
- Configure linting rules

### Step 5: Verify Setup
```bash
vulcan info
```
**Checks:** Connection status, project structure, configuration

---

## ✍️ Phase 3: Model Development

**Goal:** Write your data transformation logic

### Step 6: Write Models

**SQL Models** (`models/example.sql`):
```sql
MODEL (
  name warehouse.users,
  start '2024-01-01',
  cron '@daily'
);

SELECT 
  user_id,
  email,
  created_at
FROM raw.users
WHERE status = 'active';
```

**Python Models** (`models/example.py`):
```python
def execute(context, start, end):
    # Complex logic, API calls, ML models
    return pd.DataFrame(...)
```

### Step 7: Lint Your Code
```bash
vulcan lint
```
**What happens:** Vulcan checks for syntax errors, ambiguous columns, invalid SQL patterns

**Result:** Code is validated before execution

---

## 🧪 Phase 4: Testing & Validation

**Goal:** Ensure your models work correctly

### Step 8: Write Tests
```bash
vulcan create_test model_name
```

**What tests do:**
- Validate model logic locally
- Run without touching your warehouse
- Fast feedback, no costs

### Step 9: Run Tests
```bash
vulcan test
```
**Result:** Tests pass → Model logic is correct

---

## 📊 Phase 5: Semantic Layer

**Goal:** Define business metrics and dimensions

### Step 10: Define Semantic Models
Create `semantics/users.yml`:
```yaml
semantic_models:
  - name: users
    model: warehouse.users
    dimensions:
      - name: plan_type
        type: string
    measures:
      - name: total_users
        agg: count
```

**What this enables:**
- Business-friendly query interface
- Automatic API generation
- Single source of truth for metrics

---

## 📋 Phase 6: Planning

**Goal:** Review and apply changes safely

### Step 11: Create a Plan
```bash
vulcan plan
```

**What happens:**
1. **Validates** models and dependencies
2. **Calculates** which intervals need backfill
3. **Shows** full impact of changes
4. **Creates** isolated environment for testing

**Plan output shows:**
- Models that will be created/modified
- Data intervals that need processing
- Dependencies and execution order

### Step 12: Review Plan
**Check:**
- Are the right models affected?
- Is the backfill scope correct?
- Any breaking changes?

### Step 13: Apply Plan
```bash
# When prompted, enter 'y'
```

**What happens:**
1. Creates model variants (with unique fingerprints)
2. Creates physical tables in warehouse
3. Backfills historical data
4. Creates/updates views (virtual layer)
5. Updates environment references

**Result:** Changes are deployed to target environment

---

## 🔄 Phase 7: Running & Scheduling

**Goal:** Process new data on schedule

### Step 14: Run Scheduled Execution
```bash
vulcan run
```

**What happens:**
1. Checks for missing intervals (compares with state)
2. Filters models by cron schedule (only processes due models)
3. Executes missing intervals
4. Updates state database

**Key difference from `plan`:**
- `plan` = Apply code changes
- `run` = Process new data intervals

### Step 15: Schedule for Production
**Set up automation:**
- **Cron job:** `0 * * * * vulcan run`
- **CI/CD pipeline:** Scheduled workflows
- **Kubernetes CronJob:** Container orchestration

**Result:** Models run automatically on schedule

---

## ✅ Phase 8: Data Quality

**Goal:** Ensure data quality at every step

### Step 16: Write Audits
Create `audits/unique_users.sql`:
```sql
SELECT user_id, COUNT(*) as count
FROM warehouse.users
GROUP BY user_id
HAVING COUNT(*) > 1
```

**What audits do:**
- Block bad data before it reaches production
- Stop execution if data quality fails
- Query for bad data (returns rows = failure)

### Step 17: Write Checks
Create `checks/completeness.yml`:
```yaml
checks:
  - name: user_email_completeness
    model: warehouse.users
    expression: email IS NOT NULL
```

**What checks do:**
- Monitor data quality over time
- Non-blocking (warnings, not failures)
- Track quality metrics

**Result:** Bad data is caught and blocked

---

## 🔌 Phase 9: API Access

**Goal:** Expose your data via APIs

### Step 18: Start API Services
```bash
make vulcan-up
# Starts: vulcan-api (port 8000), vulcan-transpiler
```

### Step 19: Query via REST API
```bash
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "measures": ["users.total_users"],
      "dimensions": ["users.plan_type"]
    }
  }'
```

### Step 20: Query via Semantic Layer
```bash
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

**Result:** Data accessible via REST, GraphQL, Python APIs, and semantic queries

---

## 🔍 Phase 10: Monitoring & Iteration

**Goal:** Monitor, debug, and improve

### Step 21: Monitor Execution
```bash
# Check project status
vulcan info

# View logs
cat .logs/vulcan_*.log

# Render SQL to debug
vulcan render model_name

# Test queries
vulcan fetchdf "SELECT * FROM schema.model_name LIMIT 10"
```

### Step 22: Iterate
**When you need to change models:**
1. Edit model files
2. Run `vulcan plan` (applies changes)
3. Run `vulcan run` (processes new data)

**When you need to add features:**
1. Add new models → `vulcan plan`
2. Add semantic definitions → `vulcan plan`
3. Add audits/checks → `vulcan plan`
4. Test → `vulcan test`

**Result:** Continuous improvement cycle

---

## 📈 Complete Lifecycle Flow

```
Setup Infrastructure
    ↓
Initialize Project
    ↓
Write Models (SQL/Python)
    ↓
Lint Code
    ↓
Write Tests → Run Tests
    ↓
Define Semantic Layer
    ↓
Create Plan → Review → Apply
    ↓
Schedule Runs (vulcan run)
    ↓
Add Audits & Checks
    ↓
Start APIs
    ↓
Monitor & Iterate
```

---

## 🎯 Key Commands Reference

| Phase | Command | Purpose |
|-------|---------|---------|
| **Setup** | `make setup` | Start infrastructure |
| **Setup** | `alias vulcan=...` | Configure CLI |
| **Init** | `vulcan init` | Create project |
| **Init** | `vulcan info` | Verify setup |
| **Develop** | `vulcan lint` | Check code quality |
| **Test** | `vulcan test` | Run unit tests |
| **Plan** | `vulcan plan` | Create & apply changes |
| **Run** | `vulcan run` | Process new data |
| **Query** | `vulcan fetchdf` | Execute SQL queries |
| **Semantic** | `vulcan transpile` | Convert semantic to SQL |
| **API** | `make vulcan-up` | Start API services |
| **Debug** | `vulcan render` | See generated SQL |

---

## 💡 Key Concepts

**Plans vs Runs:**
- **`vulcan plan`** = Apply code/model changes (use when you modify code)
- **`vulcan run`** = Process new data intervals (use for scheduled execution)

**Environments:**
- **Dev/Staging:** Test changes safely
- **Production:** Deploy validated changes
- Plans create isolated environments for testing

**Data Quality:**
- **Audits:** Block bad data (stops execution)
- **Checks:** Monitor quality (warnings only)
- **Tests:** Validate logic (before execution)

**Semantic Layer:**
- Define metrics once, use everywhere
- Automatic API generation
- Business-friendly query interface

---

## 🔄 Daily Workflow

**Morning Routine:**
1. Check `vulcan info` for status
2. Review logs: `.logs/vulcan_*.log`
3. Verify scheduled runs completed

**When Making Changes:**
1. Edit models/semantics
2. `vulcan lint` → Fix issues
3. `vulcan test` → Verify logic
4. `vulcan plan` → Review & apply
5. `vulcan run` → Process new data

**When Debugging:**
1. `vulcan render model_name` → See SQL
2. `vulcan fetchdf "query"` → Test queries
3. Check logs for errors
4. Fix and re-plan

---

## 🎓 Summary

**Vulcan's lifecycle is:**

1. **Setup** → Infrastructure and project initialization
2. **Develop** → Write models, tests, semantics
3. **Validate** → Lint, test, audit, check
4. **Plan** → Review and apply changes safely
5. **Run** → Process data on schedule
6. **Expose** → APIs and semantic queries
7. **Monitor** → Logs, status, debugging
8. **Iterate** → Continuous improvement

**The flow is linear and predictable:** Each phase builds on the previous one, and you can always trace back to see what happened at each step.

---

*This lifecycle ensures: code quality, data quality, safe deployments, and continuous operation of your data pipeline.*
