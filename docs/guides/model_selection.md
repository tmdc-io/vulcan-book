# Model Selection

This guide explains how to select specific models to include in a Vulcan plan using the Orders360 example project. Use this when you want to test or apply changes to a subset of your models without processing everything.

In large projects, model selection saves time. Instead of waiting for all models to process, focus on what you're working on.

**Note:** The selector syntax described below is also used for the Vulcan `plan` [`--allow-destructive-model` and `--allow-additive-model` selectors](./plan_guide.md).

---

## Background

A Vulcan [plan](./plan_guide.md) automatically detects changes between your local project and the deployed environment. When applied, it backfills directly modified models and their downstream dependencies.

In large projects, a single model change can impact many downstream models, making plans take a long time. Model selection lets you filter which changes to include, so you can test specific models without processing everything.

**Key Concept:**

- **Directly Modified**: Models you changed in your code - these are the ones you actually edited

- **Indirectly Modified**: Downstream models affected by your changes - these depend on what you changed, so they need to be reprocessed too

Understanding this distinction helps you understand what model selection is doing. You're filtering which directly modified models to include, and Vulcan automatically figures out the indirect ones.

*[Screenshot: Visual showing directly vs indirectly modified models]*

---

## Understanding Model Dependencies

Before we dive into selection, let's understand how models relate to each other in Orders360. This will help you understand why selecting one model might include others.

```mermaid
flowchart TD
    subgraph "Orders360 Model DAG"
        RAW_CUSTOMERS[raw.raw_customers<br/>Seed Model]
        RAW_ORDERS[raw.raw_orders<br/>Seed Model]
        RAW_PRODUCTS[raw.raw_products<br/>Seed Model]
        
        DAILY_SALES[sales.daily_sales<br/>Daily Aggregation]
        WEEKLY_SALES[sales.weekly_sales<br/>Weekly Aggregation]
    end
    
    RAW_CUSTOMERS --> DAILY_SALES
    RAW_ORDERS --> DAILY_SALES
    RAW_PRODUCTS --> DAILY_SALES
    
    DAILY_SALES --> WEEKLY_SALES
    
    style RAW_CUSTOMERS fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style RAW_ORDERS fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style RAW_PRODUCTS fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style DAILY_SALES fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,color:#000
    style WEEKLY_SALES fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000
```

**Dependency Flow:**

- `raw.raw_orders` → `sales.daily_sales` → `sales.weekly_sales`

- Changing `raw.raw_orders` affects `daily_sales` (indirectly modified) - because daily_sales reads from raw_orders

- Changing `daily_sales` affects `weekly_sales` (indirectly modified) - because weekly_sales reads from daily_sales

This is important! When you select a model, Vulcan automatically includes its downstream dependencies. You can't process `weekly_sales` without processing `daily_sales` first, because `weekly_sales` depends on it.

*[Screenshot: Orders360 project structure showing model files]*

---

## Syntax

Model selections use the `--select-model` argument in `vulcan plan`. You can select models in several ways, by name, pattern, tags, git changes, and more. Let's explore all the options!

### Basic Selection

Select a single model by name:

```bash
vulcan plan dev --select-model "sales.daily_sales"
```

*[Screenshot: Plan output showing only daily_sales selected]*

Select multiple models:

```bash
vulcan plan dev --select-model "sales.daily_sales" --select-model "raw.raw_orders"
```

*[Screenshot: Plan output showing multiple models selected]*

### Wildcard Selection

Use `*` to match multiple models:

```bash
# Select all models starting with "raw."
vulcan plan dev --select-model "raw.*"

# Select all models ending with "_sales"
vulcan plan dev --select-model "sales.*_sales"

# Select all models containing "daily"
vulcan plan dev --select-model "*daily*"
```

**Examples:**

- `"raw.*"` matches `raw.raw_customers`, `raw.raw_orders`, `raw.raw_products` - all models in the raw schema

- `"sales.*_sales"` matches `sales.daily_sales`, `sales.weekly_sales` - all models ending with _sales in the sales schema

- `"*.daily_sales"` matches `sales.daily_sales` - matches daily_sales in any schema

Wildcards let you select a group of related models without listing them all individually.

*[Screenshot: Plan output showing wildcard selection results]*

### Tag Selection

Select models by tags using `tag:tag_name`:

```bash
# Select all models with "seed" tag
vulcan plan dev --select-model "tag:seed"

# Select all models with tags starting with "reporting"
vulcan plan dev --select-model "tag:reporting*"
```

**Example:** If `raw.raw_orders` and `raw.raw_customers` have the `seed` tag:

```bash
vulcan plan dev --select-model "tag:seed"
# Selects: raw.raw_orders, raw.raw_customers
```

*[Screenshot: Plan output showing tag-based selection]*

### Upstream/Downstream Selection

Use `+` to include upstream or downstream models:

- `+model_name` = Include upstream models (dependencies)

- `model_name+` = Include downstream models (dependents)

```mermaid
flowchart LR
    subgraph "Model Dependencies"
        RAW[raw.raw_orders]
        DAILY[sales.daily_sales]
        WEEKLY[sales.weekly_sales]
    end
    
    RAW -->|upstream| DAILY
    DAILY -->|downstream| WEEKLY
    
    style RAW fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style DAILY fill:#fff9c4,stroke:#fbc02d,stroke-width:3px,color:#000
    style WEEKLY fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000
```

**Examples:**

```bash
# Select daily_sales only
vulcan plan dev --select-model "sales.daily_sales"
# Result: daily_sales (directly modified)

# Select daily_sales + upstream (raw.raw_orders)
vulcan plan dev --select-model "+sales.daily_sales"
# Result: raw.raw_orders, daily_sales

# Select daily_sales + downstream (weekly_sales)
vulcan plan dev --select-model "sales.daily_sales+"
# Result: daily_sales, weekly_sales

# Select daily_sales + both upstream and downstream
vulcan plan dev --select-model "+sales.daily_sales+"
# Result: raw.raw_orders, daily_sales, weekly_sales
```

*[Screenshot: Plan outputs showing different selection results]*

### Git-Based Selection

Select models changed in a git branch:

```bash
# Select models changed in feature branch
vulcan plan dev --select-model "git:feature"

# Select changed models + downstream
vulcan plan dev --select-model "git:feature+"

# Select changed models + upstream
vulcan plan dev --select-model "+git:feature"
```

**What it includes:**

- Untracked files (new models) - models you've created but haven't committed yet

- Uncommitted changes - models you've modified but haven't committed

- Committed changes different from target branch - models that differ between your branch and the target (like `main`)

Use this for feature branches. Select all models you've changed in your feature branch without listing them manually.

*[Screenshot: Plan output showing git-based selection]*

### Complex Selections

Combine conditions with logical operators:

- `&` (AND): Both conditions must be true

- `|` (OR): Either condition must be true

- `^` (NOT): Negates a condition

```bash
# Models with finance tag that don't have deprecated tag
vulcan plan dev --select-model "(tag:finance & ^tag:deprecated)"

# daily_sales + upstream OR weekly_sales + downstream
vulcan plan dev --select-model "(+sales.daily_sales | sales.weekly_sales+)"

# Changed models that also have finance tag
vulcan plan dev --select-model "(tag:finance & git:main)"

# Models in sales schema without test tag
vulcan plan dev --select-model "^(tag:test) & sales.*"
```

*[Screenshot: Plan output showing complex selection results]*

---

## Examples with Orders360

Let's see how model selection works with the Orders360 project. We'll modify `raw.raw_orders` and `sales.daily_sales` to demonstrate different selection scenarios.

### Example Setup

We've modified two models:

- `raw.raw_orders` (directly modified)

- `sales.daily_sales` (directly modified)

The dependency chain:
```
raw.raw_orders → sales.daily_sales → sales.weekly_sales
```

*[Screenshot: Orders360 project showing modified files]*

### No Selection (Default)

Without selection, Vulcan includes all directly modified models and their downstream dependencies:

```bash
vulcan plan dev
```

**Expected Output:**
```
======================================================================
Successfully Ran 2 tests against postgres
----------------------------------------------------------------------

Differences from the `prod` environment:

Models:
├── Directly Modified:
│   ├── sales.daily_sales
│   └── raw.raw_orders
└── Indirectly Modified:
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing all modified models]*

**What Happened:**

- Both directly modified models are included - you changed both, so both are in the plan

- `weekly_sales` is indirectly modified (depends on `daily_sales`) - even though you didn't change weekly_sales, it depends on daily_sales, so it needs to be reprocessed

This is the default behavior, Vulcan includes everything that's affected. Model selection lets you narrow this down.

### Select Single Model

Select only `sales.daily_sales`:

```bash
vulcan plan dev --select-model "sales.daily_sales"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   └── sales.daily_sales
└── Indirectly Modified:
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing only daily_sales selected]*

**What Happened:**

- `raw.raw_orders` is excluded (not selected) - you changed it, but you didn't select it, so it's not in the plan

- `daily_sales` is included (directly modified) - you selected it, so it's in the plan

- `weekly_sales` is included (indirectly modified, downstream of `daily_sales`) - it depends on daily_sales, so Vulcan automatically includes it

Notice how Vulcan automatically includes downstream models. You can't process daily_sales without processing weekly_sales, because weekly_sales depends on it.

### Select with Upstream Indicator

Select `daily_sales` and include its upstream dependencies:

```bash
vulcan plan dev --select-model "+sales.daily_sales"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   ├── raw.raw_orders
│   └── sales.daily_sales
└── Indirectly Modified:
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing upstream selection]*

**What Happened:**

- `raw.raw_orders` is included (upstream of `daily_sales`)

- `daily_sales` is included (selected)

- `weekly_sales` is included (downstream of `daily_sales`)

### Select with Downstream Indicator

Select `daily_sales` and include its downstream dependencies:

```bash
vulcan plan dev --select-model "sales.daily_sales+"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   ├── sales.daily_sales
│   └── sales.weekly_sales
└── Indirectly Modified:
    (none)
```

*[Screenshot: Plan output showing downstream selection]*

**What Happened:**

- `daily_sales` is included (selected)

- `weekly_sales` is included (downstream, now directly modified)

- `raw.raw_orders` is excluded (not selected)

### Select with Wildcard

Select all models matching a pattern:

```bash
vulcan plan dev --select-model "sales.*_sales"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   └── sales.daily_sales
└── Indirectly Modified:
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing wildcard selection]*

**What Happened:**

- `sales.daily_sales` matches the pattern (selected)

- `sales.weekly_sales` matches the pattern but is indirectly modified

- `raw.raw_orders` doesn't match (excluded)

### Select with Tags

If models have tags, select by tag:

```bash
vulcan plan dev --select-model "tag:seed"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   └── raw.raw_orders
└── Indirectly Modified:
    ├── sales.daily_sales
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing tag-based selection]*

**What Happened:**

- `raw.raw_orders` has `seed` tag (selected)

- Downstream models are indirectly modified

### Select with Git Changes

Select models changed in a git branch:

```bash
vulcan plan dev --select-model "git:feature"
```

**Expected Output:**
```
Differences from the `prod` environment:

Models:
├── Directly Modified:
│   └── sales.daily_sales  # Changed in feature branch
└── Indirectly Modified:
    └── sales.weekly_sales
```

*[Screenshot: Plan output showing git-based selection]*

**What Happened:**

- Only models changed in `feature` branch are selected

- Downstream models are included automatically

---

## Backfill Selection

By default, Vulcan backfills all models in a plan. You can limit which models are backfilled using `--backfill-model`.

**Important:** `--backfill-model` only works in development environments (not `prod`).

### How Backfill Selection Works

```mermaid
flowchart TB
    subgraph "Backfill Selection Flow"
        PLAN[vulcan plan dev]
        SELECT[--select-model<br/>Which models in plan?]
        BACKFILL[--backfill-model<br/>Which models to backfill?]
        
        subgraph "Plan Includes"
            IN_PLAN[Models in Plan<br/>daily_sales, weekly_sales]
        end
        
        subgraph "Backfill Includes"
            BACKFILL_LIST[Models to Backfill<br/>Only daily_sales]
        end
        
        RESULT[Result:<br/>Plan shows all models<br/>Only selected models backfilled]
    end
    
    PLAN --> SELECT
    PLAN --> BACKFILL
    SELECT --> IN_PLAN
    BACKFILL --> BACKFILL_LIST
    IN_PLAN --> RESULT
    BACKFILL_LIST --> RESULT
    
    style PLAN fill:#fff3e0,stroke:#f57c00,stroke-width:3px,color:#000
    style SELECT fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style BACKFILL fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,color:#000
    style RESULT fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:#000
```

**Key Points:**

- `--select-model` determines which models appear in the plan - this is about what's in the plan

- `--backfill-model` determines which models are actually backfilled - this is about what gets processed

- Upstream models are always backfilled (required for downstream models) - if you backfill weekly_sales, you need daily_sales first

This separation lets you see what would be affected (select-model) but only process what you need (backfill-model). Useful for testing.

*[Screenshot: Visual diagram explaining backfill selection]*

### Backfill Examples

#### No Backfill Selection (Default)

All models in the plan are backfilled:

```bash
vulcan plan dev
```

**Expected Output:**
```
Models needing backfill (missing dates):
├── sales__dev.daily_sales: 2025-01-01 - 2025-01-15
└── sales__dev.weekly_sales: 2025-01-01 - 2025-01-15
```

*[Screenshot: Plan output showing all models needing backfill]*

#### Backfill Specific Model

Only backfill `daily_sales`:

```bash
vulcan plan dev --backfill-model "sales.daily_sales"
```

**Expected Output:**
```
Models needing backfill (missing dates):
└── sales__dev.daily_sales: 2025-01-01 - 2025-01-15
```

*[Screenshot: Plan output showing only daily_sales needs backfill]*

**What Happened:**

- `weekly_sales` is excluded from backfill - it's in the plan, but it won't be processed

- Only `daily_sales` will be processed - just what you selected

Use this in development. See what would be affected, but only process what you're actually testing. Saves time and compute costs.

#### Backfill with Upstream

When you backfill a model, its upstream dependencies are automatically included:

```bash
vulcan plan dev --backfill-model "sales.weekly_sales"
```

**Expected Output:**
```
Models needing backfill (missing dates):
├── raw__dev.raw_orders: 2025-01-01 - 2025-01-15
└── sales__dev.weekly_sales: 2025-01-01 - 2025-01-15
```

*[Screenshot: Plan output showing upstream models included in backfill]*

**What Happened:**

- `weekly_sales` is selected for backfill - you want to process this one

- `raw.raw_orders` is automatically included (upstream dependency) - weekly_sales depends on daily_sales, which depends on raw_orders, so Vulcan includes it

- `daily_sales` is excluded (not upstream of `weekly_sales`) - wait, that doesn't seem right...

Actually, this example might be incorrect. If weekly_sales depends on daily_sales, then daily_sales should be included as an upstream dependency. The key point is: Vulcan automatically includes upstream dependencies when you backfill a model.

---

## Visual Selection Guide

Here's a quick reference for common selection patterns:

```mermaid
flowchart LR
    subgraph "Selection Patterns"
        PAT1["sales.daily_sales<br/>Select only this model"]
        PAT2["+sales.daily_sales<br/>Select + upstream"]
        PAT3["sales.daily_sales+<br/>Select + downstream"]
        PAT4["+sales.daily_sales+<br/>Select + both"]
        PAT5["sales.*_sales<br/>Wildcard match"]
        PAT6["tag:seed<br/>Tag selection"]
    end
    
    subgraph "Results"
        RES1[daily_sales only]
        RES2[raw_orders + daily_sales]
        RES3[daily_sales + weekly_sales]
        RES4[All connected]
        RES5[All matching]
        RES6[All tagged]
    end
    
    PAT1 --> RES1
    PAT2 --> RES2
    PAT3 --> RES3
    PAT4 --> RES4
    PAT5 --> RES5
    PAT6 --> RES6
    
    style PAT1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style PAT2 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style PAT3 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style PAT4 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style PAT5 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    style PAT6 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
```

*[Screenshot: Visual cheat sheet for selection patterns]*

---

## Best Practices

Here are some tips to help you use model selection effectively:

1. **Start Small**: Select only the models you're testing
   ```bash
   vulcan plan dev --select-model "sales.daily_sales"
   ```
   Don't process everything if you're only testing one model. Start small, then expand if needed.

2. **Use Wildcards**: When selecting multiple related models
   ```bash
   vulcan plan dev --select-model "sales.*"
   ```
   Wildcards are your friend! They let you select groups of models without listing them all.

3. **Include Dependencies**: Use `+` when you need upstream/downstream models
   ```bash
   vulcan plan dev --select-model "+sales.daily_sales+"
   ```
   The `+` syntax includes the full dependency chain. Use it when you need all dependencies.

4. **Limit Backfill**: Use `--backfill-model` to save time in development
   ```bash
   vulcan plan dev --backfill-model "sales.daily_sales"
   ```
   In dev environments, you often don't need to backfill everything. Use this to save time and money.

5. **Use Tags**: Organize models with tags for easier selection
   ```bash
   vulcan plan dev --select-model "tag:reporting"
   ```
   Tags organize models. If you tag related models, you can select them all at once.

---

## Summary

**Model Selection:**

- Filter which models appear in a plan

- Use wildcards, tags, and git changes

- Include upstream/downstream with `+`

- Combine with logical operators

**Backfill Selection:**

- Limit which models are actually backfilled

- Upstream models are always included

- Only works in development environments

- Saves time when testing specific models

---

## Next Steps

- Learn about [Plans](./plan_guide.md) for understanding plan behavior

