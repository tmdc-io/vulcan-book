
---

# Vulcan Troubleshooting

This guide walks you through the most common things that make Vulcan unhappy, what those errors actually mean, and how to get back to a clean `plan` or `apply`. If you’re staring at logs wondering *“what did I break?”*, you’re in the right place.

The examples here come from real projects and logs, so they’re practical rather than theoretical.

---

## Log Locations

Most issues surface in:

* `.logs/vulcan_*.log`

If something fails, start there.

---

## Model Errors

These errors come directly from how models are defined: their names, audits, or SQL.

### Audit failures: `Audits failed: unique_values`

**Error**

```
NodeAuditsErrors: Audits failed: unique_values
```

Vulcan ran a uniqueness check and found duplicate values.

#### Why this happens

A model defines a `unique_values(...)` audit, but the data produced by the model isn’t actually unique for those columns.

This is especially common in demos, seeds, or test data where the grain doesn’t quite match the audit definition.

#### How to fix it

* Fix the upstream data so the columns really are unique.
* Update the audit to match the true grain of the model.
* Remove or relax audit but for local or demo runs(**NOT RECOMMENDED**).

For sample projects, removing the audit is often the fastest path forward.

---

### SQLMesh model naming errors

#### Table must match the schema’s nesting level

**Error**

```
Table "<model>" must match the schema's nesting level: 3
```

#### Why this happens

SQLMesh requires model names to match the configured schema nesting level. With a nesting level of 3, model names must be fully qualified:

* `catalog.schema.table`

Names like `table` or `schema.table` aren’t enough.

#### How to fix it

Rename the model to include the full namespace:

```sql
-- ❌ Invalid
name xxx

-- ✅ Valid
name warehouse.analytics.xxx
```

Make sure all downstream references use the same fully qualified name.


---

## Tests and Checks

These errors happen after models build, when Vulcan validates correctness.

### Check snapshot name parsing fails

**Error**

```
Failed to parse '__checks...:completeness' into Table
```

#### Why this happens

Some check snapshot names include `:` characters, which can confuse SQL parsing during planning.

#### How to fix it

* Upgrade Vulcan if this is fixed upstream.
* Temporarily disable the checks generating `__checks.*` snapshots.

---

### Checks reference a model that doesn’t exist

**Error**

```
Model '<model>' not found. Did you mean ...?
```

#### Why this happens

The checks YAML references a model name that doesn’t exist, often due to a singular vs plural mismatch.

#### How to fix it

Update the checks file to reference the correct model name.

---

### Checks fail with `relation does not exist`

**Error**

```
relation '<schema>.<table>' does not exist
```

#### Why this happens

The model was built successfully, but the checks are pointing at a different schema or environment name.

#### How to fix it

Align check targets with the schema naming Vulcan uses for that environment.

---

### Plan blocked by failing tests

**Error**

```
Cannot generate plan due to failing test(s)
```

#### Why this happens

Vulcan runs tests during planning. If they fail, planning stops.

A common gotcha is test fixture collisions, where multiple tests reuse the same primary keys.

#### How to fix it

* Ensure all tests use globally unique IDs.
* Or configure isolated test execution if your setup supports it.

---

## Semantic Validation Errors

Semantic errors usually show up early and block planning entirely. They’re strict by design.

### Duplicate field names

**Error**

```
duplicate field names found: [...]
```

#### Why this happens

A semantic model defines the same field more than once. Vulcan doesn’t try to guess which one you meant.

#### How to fix it

Ensure each field name appears only once per semantic model. Rename or remove duplicates.

---

### Time dimensions must be `TIMESTAMP`

**Error**

```
'<field>' uses DATE type. Time dimensions require TIMESTAMP
```

#### Why this happens

Semantic time dimensions must be `TIMESTAMP`, but the underlying SQL model returns a `DATE`.

#### How to fix it

Cast the column in the SQL model output and keep the alias unchanged:

```sql
CAST(order_date AS TIMESTAMP) AS order_date
```

Do this in the model SQL, not in the semantics YAML.

---

### Unknown columns referenced by semantics

**Error**

```
dimensions reference unknown columns on model '<alias>'
```

#### Why this happens

The semantics YAML references a column that doesn’t exist in the model output.

#### How to fix it

Update the semantic model to reference a column that actually exists.

---

### Circular join dependency detected

**Error**

```
Circular join dependency detected
```

#### Why this happens

Two semantic models join to each other, directly or indirectly. The semantic join graph must be acyclic.

#### How to fix it

Pick a direction and stick to it. A common pattern is:

* **Fact → Dimension**

Remove the reverse join and keep a single, one-directional path.

---

### Proxy measure has no join path

**Error**

```
proxy '<proxy>' references '<model>.<measure>' but no join path exists
```

#### Why this happens

Proxy measures can only reference models that are connected through the semantic join graph.

#### How to fix it

Add a join path between the models, directly or transitively. Avoid adding joins in both directions.

---

## Engine-Specific Errors

These errors depend on the execution engine rather than your model logic.

### Spark catalog does not support views

**Error**

```
Catalog postgres does not support views
```

#### Why this happens

Spark’s JDBC v2 catalog does not support views, but Vulcan’s virtual-layer promotion attempts to create them.

#### How to fix it

* Promote into a catalog that supports views, or
* Disable virtual-layer promotion for that target.

---

### Upstream model not found (Spark)

**Error**

```
TABLE_OR_VIEW_NOT_FOUND
```

#### Why this happens

A downstream model references a logical model name that doesn’t exist at execution time.

Common causes:

* The upstream model was renamed or removed.
* A previous plan failed and never created the upstream object.
* The project is in a partially-applied state.

#### How to fix it

* Verify the SQL reference points to the correct model.
* If state looks confusing, run `vulcan destroy` and start fresh.

---

### Postgres relation does not exist

**Error**

```
UndefinedTable: relation '<schema>.<table>' does not exist
```

#### Why this happens

The SQL references a table that doesn’t exist, often due to a typo or singular vs plural mismatch.

#### How to fix it

Fix the table name in the SQL or ensure the expected external table exists.


---

