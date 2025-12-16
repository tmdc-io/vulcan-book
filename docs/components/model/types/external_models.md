# External models

Vulcan model queries may reference "external" tables that are created and managed outside the Vulcan project. For example, a model might ingest data from a third party's read-only data system.

Vulcan does not manage external tables, but it can use information about the tables' columns and data types to make features more useful. For example, column information allows column-level lineage to include external tables' columns.

Vulcan stores external tables' column information as `EXTERNAL` models.

## How external models work

`EXTERNAL` models consist solely of an external table's column information, so there is no query for Vulcan to run.

Vulcan has no information about the data contained in the table represented by an `EXTERNAL` model. The table could be altered or have all its data deleted, and Vulcan will not detect it. All Vulcan knows about the table is that it contains the columns specified in the `EXTERNAL` model's file (more information below).

Vulcan will not take any actions based on an `EXTERNAL` model - its actions are solely determined by the model whose query selects from the `EXTERNAL` model.

The querying model's [`kind`](./model_kinds.md), [`cron`](./overview.md#cron), and previously loaded time intervals determine when Vulcan will query the `EXTERNAL` model.

## Generating an external models schema file

External models can be defined in the `external_models.yaml` file in the Vulcan project's root folder. The alternative name for this file is `schema.yaml`.

You can create this file by either writing the YAML by hand or allowing Vulcan to fetch information about external tables with the `create_external_models` CLI command.

Consider this example model that queries external tables `vulcan_demo.customers`, `vulcan_demo.orders`, and `vulcan_demo.order_items`:

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

The following sections demonstrate how to create external models containing the column information for these tables.

All of a Vulcan project's external models are defined in a single `external_models.yaml` file, so the files created below might also include column information for other external models.

Alternatively, additional external models can also be defined in the [external_models/](#using-the-external_models-directory) folder.

### Using CLI

Instead of creating the `external_models.yaml` file manually, Vulcan can generate it for you with the [create_external_models](../../reference/cli.md#create_external_models) CLI command.

The command identifies all external tables referenced in your Vulcan project, fetches their column information from the SQL engine's metadata, and then stores the information in the `external_models.yaml` file.

If Vulcan does not have access to an external table's metadata, the table will be omitted from the file and Vulcan will issue a warning.

`create_external_models` solely queries SQL engine metadata and does not query external tables themselves.

### Gateway-specific external models

In some use-cases such as [isolated systems with multiple gateways](../../guides/isolated_systems.md#multiple-gateways), there are external models that only exist on a certain gateway.

**Gateway names are case-insensitive in external model configurations.** You can specify the gateway name using any case (e.g., `gateway: dev`, `gateway: DEV`, `gateway: Dev`) and Vulcan will handle the matching correctly.

Consider the following model that queries an external table with a dynamic database based on the current gateway:

```
MODEL (
  name vulcan_demo.customer_summary,
  kind FULL
);

SELECT
  *
FROM
  @{gateway}_db.customers;
```

This table will be named differently depending on which `--gateway` Vulcan is run with (learn more about the curly brace `@{gateway}` syntax [here](../../concepts/macros/vulcan_macros.md#embedding-variables-in-strings)).

For example:

- `vulcan --gateway dev plan` - Vulcan will try to query `dev_db.customers`
- `vulcan --gateway prod plan` - Vulcan will try to query `prod_db.customers`

To ensure Vulcan can look up the correct schema when the relevant gateway is set, run `create_external_models` with the `--gateway` argument. For example:

- `vulcan --gateway dev create_external_models`

This will set `gateway: dev` on the external model and ensure that it is only loaded when the current gateway is set to `dev`.

### Writing YAML by hand

This example demonstrates the structure of a `external_models.yaml` file based on a typical e-commerce data model:

```yaml
- name: '"warehouse"."vulcan_demo"."customers"'
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
- name: '"warehouse"."vulcan_demo"."shipments"'
  columns:
    shipment_id: INT
    order_id: INT
    shipped_date: DATE
    carrier: TEXT
```

It contains each `EXTERNAL` model's name and each of the external table's columns' name and data type. An optional description and gateway can also be specified.

The file can be constructed by hand using a standard text editor or IDE.

### Using the `external_models` directory

Sometimes, Vulcan cannot infer the structure of a model and you need to add it manually.

However, since `vulcan create_external_models` replaces the `external_models.yaml` file, any manual changes you made to that file will be overwritten.

The solution is to create the manual model definition files in the `external_models/` directory, like so:

```
external_models.yaml
external_models/more_external_models.yaml
external_models/even_more_external_models.yaml
```

Files in the `external_models` directory must be `.yaml` files that follow the same structure as the `external_models.yaml` file.

When Vulcan loads the definitions, it will first load the models defined in `external_models.yaml` (or `schema.yaml`) and  any models found in `external_models/*.yaml`.

Therefore, you can use `vulcan create_external_models` to manage the `external_models.yaml` file and then put any models that need to be defined manually inside the `external_models/` directory.

### External assertions

It is possible to define [assertions](../assertions.md) on external models. This can be useful to check the data quality of upstream dependencies before your internal models evaluate.

This example shows an external model with assertions:

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
