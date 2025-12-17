# External

Sometimes your models need to query tables that exist outside your Vulcan project—maybe a third-party data source, a table managed by another system, or a read-only database. These are "external" tables.

Vulcan doesn't manage external tables (you can't create or update them), but it can use metadata about them to make your life easier. By defining external models, you give Vulcan information about column names and types, which enables better column-level lineage and query optimization.

**Why define external models?** Even though Vulcan can't manage them, knowing their schema helps with:
- Column-level lineage (see how data flows through external tables)
- Query optimization (Vulcan can make better decisions)
- Documentation (your data catalog knows what's in those tables)

Vulcan stores this metadata as `EXTERNAL` models.

## How External Models Work

`EXTERNAL` models are metadata-only—they just describe a table's schema (column names and types). There's no query for Vulcan to run, and Vulcan doesn't manage the data.

**Important limitations:**
- Vulcan doesn't know what data is in the table (or if it even exists)
- If someone alters the external table, Vulcan won't detect it
- If all data is deleted, Vulcan won't know
- Vulcan never modifies external tables

The querying model's [`kind`](../model_kinds.md), [`cron`](../overview.md#cron), and previously loaded time intervals determine when Vulcan will query the `EXTERNAL` model.

**When external tables get queried:** Only when a Vulcan model references them. The querying model's `kind`, `cron`, and time intervals determine when the external table is actually queried. Vulcan doesn't proactively query external tables—it only queries them as part of executing your models.

## Creating External Models

External models are defined in YAML files. You have two options:
1. **Let Vulcan generate it** (easiest) - Use the `create_external_models` CLI command
2. **Write it yourself** - Hand-craft the YAML if you need more control

The main file is `external_models.yaml` (or `schema.yaml`) in your project root. You can also add more files in the `external_models/` directory.

Let's say you have a model that queries external tables. Here's an example:

```sql
MODEL (
  name vulcan_demo.full_model,
  kind FULL
);

SELECT
  c.customer_id,
  c.name AS customer_name,
  c.email,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spent
FROM vulcan_demo.customers AS c
LEFT JOIN vulcan_demo.orders AS o
  ON c.customer_id = o.customer_id
LEFT JOIN vulcan_demo.order_items AS oi
  ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.email
```

The following sections show you how to create external models for these tables. You can define all external models in `external_models.yaml`, or split them across multiple files in the `external_models/` directory (useful for organization or when Vulcan regenerates the main file).

### Using CLI

Instead of creating the `external_models.yaml` file manually, Vulcan can generate it for you with the [create_external_models](../../../cli-command/cli.md#create_external_models) CLI command.

The command identifies all external tables referenced in your Vulcan project, fetches their column information from the SQL engine's metadata, and then stores the information in the `external_models.yaml` file.

If Vulcan does not have access to an external table's metadata, the table will be omitted from the file and Vulcan will issue a warning.

`create_external_models` solely queries SQL engine metadata and does not query external tables themselves.

### Gateway-specific external models

In some use-cases such as [isolated systems with multiple gateways](../../guides-old/isolated_systems.md#multiple-gateways), there are external models that only exist on a certain gateway.

**Gateway names are case-insensitive in external model configurations.** You can specify the gateway name using any case (e.g., `gateway: dev`, `gateway: DEV`, `gateway: Dev`) and Vulcan will handle the matching correctly.

Consider the following model that queries an external table with a dynamic database based on the current gateway:

```bash
vulcan create_external_models
```

**What it does:**
- Scans your project for references to external tables
- Fetches column information from your SQL engine's metadata
- Writes everything to `external_models.yaml`

**Important:** This command only queries metadata (table schemas), not the actual data. It's fast and safe.

**If Vulcan can't access a table's metadata:** That table gets skipped and Vulcan warns you. You'll need to define it manually (see the "Writing YAML by hand" section below).

### Gateway-Specific External Models

If you're using [isolated systems with multiple gateways](../../guides/isolated_systems.md#multiple-gateways), you might have external tables that only exist on specific gateways.

**Example:** Your model uses a gateway variable to select different databases:

```sql
MODEL (
  name vulcan_demo.customer_summary,
  kind FULL
);

SELECT * FROM @{gateway}_db.customers;
```

When you run with `--gateway dev`, it queries `dev_db.customers`. When you run with `--gateway prod`, it queries `prod_db.customers`. These are different tables with potentially different schemas!

**Solution:** Run `create_external_models` with the `--gateway` flag:

```bash
vulcan --gateway dev create_external_models
```

This sets `gateway: dev` on the external model, so it only loads when that gateway is active. Do this for each gateway that has different external tables.

!!! note "Case-Insensitive Gateway Names"

    Gateway names are case-insensitive in external model configs. `gateway: dev`, `gateway: DEV`, and `gateway: Dev` all work the same.

### Writing YAML by Hand

Sometimes you need to define external models manually—maybe Vulcan can't access the metadata, or you want more control. Here's the structure:

```yaml
- name: '"warehouse"."vulcan_demo"."customers"'
  description: "Customer dimension table from external system"
  gateway: dev  # Optional: only load for this gateway
  columns:
    customer_id: INT
    region_id: INT
    name: TEXT
    email: TEXT
- name: '"warehouse"."vulcan_demo"."orders"'
  columns:
    order_id: INT
    customer_id: INT
    order_date: TIMESTAMP
    warehouse_id: INT
```

**What you need:**
- `name`: Fully qualified table name (with quotes if needed for case sensitivity)
- `columns`: Dictionary of column names to data types

**Optional fields:**
- `description`: Human-readable description
- `gateway`: Gateway name (for gateway-specific tables)

**Pro tip:** Use triple-quoted names if your table names have special characters or need case sensitivity. The exact format depends on your SQL engine.

### Using the `external_models` Directory

Here's a common problem: You run `vulcan create_external_models` and it generates `external_models.yaml`. But some tables need manual definitions (maybe Vulcan can't access their metadata). If you add them to `external_models.yaml` and run the command again, your manual changes get overwritten!

**Solution:** Put manual definitions in the `external_models/` directory:

```
external_models.yaml              # Auto-generated by Vulcan
external_models/manual_tables.yaml # Your manual definitions
external_models/legacy_tables.yaml # More manual definitions
```

**How it works:**
- Vulcan loads `external_models.yaml` first (or `schema.yaml`)
- Then it loads all `.yaml` files from `external_models/`
- Everything gets merged together

**Best practice:** Use `create_external_models` to manage the main file, and put any tables that need manual definitions in the `external_models/` directory. That way you can regenerate the main file without losing your manual work!

### External Assertions

You can define [assertions](components/model/audits.md) on external models! This is super useful for validating upstream data quality before your internal models run.

**Why this matters:** If your external data source has quality issues, you want to catch them early—before they flow into your models and cause bigger problems downstream.

Here's how you'd add assertions to an external model:

```yaml
- name: '"warehouse"."vulcan_demo"."customers"'
  description: Table containing customer information
  assertions:
    - name: not_null
      columns: "[customer_id, email]"
    - name: unique_values
      columns: "[customer_id]"
  columns:
    customer_id: INT
    region_id: INT
    name: TEXT
    email: TEXT
- name: '"warehouse"."vulcan_demo"."orders"'
  description: Table containing order transactions
  assertions:
    - name: not_null
      columns: "[order_id, customer_id, order_date]"
    - name: accepted_range
      column: order_id
      min_v: "1"
  columns:
    order_id: INT
    customer_id: INT
    order_date: TIMESTAMP
    warehouse_id: INT
```
