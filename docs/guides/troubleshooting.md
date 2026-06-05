# Troubleshooting

Vulcan rejects bad requests early so you don't waste warehouse cycles or end up with half-broken results. When a query, plan, or API call fails, you get back a specific error code and message. This page lists every error you can hit at validation or request time, what triggered it, and how to fix it.

If you came here from a `4xx` response, copy the code or message into your browser's find dialog (`Cmd/Ctrl + F`) and jump straight to the entry.

---

## How each entry is structured

Each error below follows the same shape:

- **Error message:** the literal string Vulcan returns.
- A short paragraph explaining when and why it fires.
- **Fix:** a short list of what to change.

If the same fix appears in more than one place (for example, "check your token"), it's because the underlying problem really is the same. The categories tell you where in the request path the error came from.

---

## Query validation errors

These come back when you submit SQL to the Vulcan query API and Vulcan rejects it before any execution happens.

### `PARSE_ERROR`

> SQL could not be parsed.

The SQL doesn't parse against the target gateway dialect, or it uses a construct the parser doesn't understand. This is almost always a syntax issue, not a permissions or model issue.

**Fix:**

- Recheck the SQL against the dialect of the selected gateway.
- Replace dialect-specific functions if you're pointing at a different engine.
- Break apart deeply nested or vendor-specific syntax.

### `DATA_MANIPULATION_DETECTED`

> Only read-only SQL is allowed, but the query contains write or mutation operations.

The raw SQL endpoint accepts read-only statements only. Anything that mutates data or schema gets blocked: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE`, `DROP`, `ALTER`, `TRUNCATE`, `REPLACE`, and similar.

**Fix:**

- Send a read-only query (`SELECT`, `WITH`, etc.).
- Move data modification logic into a model, pipeline, or job. The query API isn't the right place for it.
- If you meant to send a semantic query, use the semantic endpoint instead of the raw SQL endpoint.

### `NOT_FOUND`

> One or more referenced tables or models were not found.

The query references a table or model name that doesn't exist in the selected environment, or the snapshot Vulcan is reading from doesn't include it yet.

**Fix:**

- Double-check the table or model name for typos.
- Confirm you're targeting the right environment.
- Run `vulcan plan <env>` if the model hasn't been planned or applied there yet.

### `TABLE_EXTRACTION_ERROR`

> Vulcan could not extract table references from the SQL.

The SQL parsed cleanly, but the lineage step that walks the AST to find table references failed. Usually a complex or unsupported construct trips this up.

**Fix:**

- Simplify the SQL.
- Split large nested queries into smaller CTEs.
- Avoid unusual dialect-specific patterns where you can.

### `NORMALIZATION_ERROR`

> Vulcan could not normalize the SQL after parsing.

The query parsed, but serializing it back into normalized SQL failed. This is rare and usually points to an edge case in the AST.

**Fix:**

- Simplify the query structure.
- Remove edge-case syntax.
- Test with more standard SQL constructs and add back complexity from there.

### `RECENT_FAILURE`

> An identical query failed recently, so Vulcan prevents immediate retry by default.

Vulcan fingerprints every query and blocks repeat submissions of a recently-failed query for a short window. This stops noisy retry loops from hammering the warehouse and Vulcan itself.

**Fix:**

- Fix the original failure first. Whatever caused the previous run to fail will keep failing if you just retry.
- Resubmit after the fix.
- If retrying is intentional (for example, an upstream blip you've already confirmed is resolved), set `retry_on_recent_failure=true` on the request.

!!! tip "Why this exists"
    Without this guard, a failing query in a tight loop can produce thousands of identical failures in seconds. The fingerprint is hashed on the normalized SQL, so cosmetic changes won't bypass it: fix the actual problem.

---

## Request validation errors

These come from FastAPI and Pydantic checks on the request body itself, before the SQL or semantic logic ever runs.

### Invalid `ttl`

> `ttl must be 0 (never expires) or between 5 and 43200 minutes`

The TTL you sent is outside the allowed range. Vulcan accepts:

- `0` for "never expire"
- `5` to `43200` minutes for expiring cache entries

Values from `1` to `4` are explicitly rejected so you don't accidentally cache results for a too-short window.

**Fix:**

- Use `0` if the result should not expire.
- Use a value between `5` and `43200`.

### Oversized `meta`

> `meta field exceeds 10KB limit`

The request metadata is larger than the size Vulcan allows for direct SQL submissions. The `meta` field is intended for tracing, debugging, and small context, not for shipping payloads.

**Fix:**

- Trim the `meta` object down to what you actually need.
- Keep only fields you'll read back later (request ID, user ID, source, etc.).
- Store anything large somewhere else and reference it by ID.

### Generic `422` validation error

> The request body or query parameters are invalid.

FastAPI or Pydantic rejected the request because of one of the usual suspects:

- a required field is missing
- a field has the wrong type
- an enum value isn't one of the allowed options
- a parameter has an unexpected shape

**Fix:**

- Compare your payload against the API schema at `/redoc` or `/openapi.json`.
- Make sure every required field is present.
- Match field types exactly to the contract for that endpoint.

---

## Semantic query and transpiler errors

These show up when you query the semantic layer and Vulcan or the transpiler rejects the request.

### `API.QUERY.POST_PROCESSING_REQUIRED`

> The semantic query requires post-processing, but post-processing is disabled.

Some semantic queries need a post-processing step after transpilation (for example, certain time grain rollups). When `disable_post_processing=true` is set on the request, Vulcan refuses to run those queries because the results would be wrong.

**Fix:**

- Resend the request with `disable_post_processing=false`.
- If the query still fails after that, look at the transpiler error attached to the response for the real cause.

### `TRANSPILER.QUERY.INVALID`

> The transpiler rejected the semantic query as invalid.

The semantic SQL or REST query is structurally invalid, references the wrong semantic objects, or violates a semantic query rule (for example, mixing measures and dimensions in a way that has no valid SQL).

**Fix:**

- Verify your measures, dimensions, filters, and joins.
- Make sure every reference matches a real semantic object.
- For grouped queries, include the right dimensions in the grouping fields.

!!! tip "Preview before you send"
    Run `vulcan transpile` locally on the same payload before submitting it to the API. You'll see the error immediately and the SQL it would produce, which usually points straight at the problem.

### `TRANSPILER.SERVICE.UNAVAILABLE`

> The semantic query service is unavailable.

The transpiler service couldn't be reached, timed out, or hasn't finished initializing.

**Fix:**

- Hit the transpiler health endpoint to confirm it's actually running.
- Check network connectivity between the API service and the transpiler.
- Retry once the upstream service is back.

### `TRANSPILER.UPSTREAM.ERROR`

> The transpiler service returned an upstream server error.

The transpiler itself crashed or errored while processing the request.

**Fix:**

- Check transpiler logs for the actual exception.
- Retry if it looks transient.
- Escalate if the same valid query fails consistently: that's a bug, not a config issue.

### `SQL_TRANSPILATION_ERROR`

> Client SQL dialect transpilation failed.

This usually shows up on internal semantic SQL flows where an incoming dialect (for example, MySQL) needs to be converted into the target backend dialect first, and that conversion failed.

**Fix:**

- Rewrite the SQL using simpler or more portable syntax.
- Avoid dialect-specific functions that have no direct mapping in the target engine.
- Confirm the declared client dialect actually matches what you're sending.

### `SEMANTIC_QUERY_ERROR`

> Semantic SQL compilation failed.

The semantic query is invalid after Vulcan hands it to the transpiler. The most common cause is bad aggregation or grouping logic.

**Fix:**

- Check the query syntax.
- Make sure every non-aggregated column appears in `GROUP BY`.
- Verify your semantic field and metric references are correct.

---

## Authentication and authorization errors

These come from Heimdall and the auth middleware. They tell you whether the request was authenticated, and whether the authenticated user is allowed to do what they asked.

### `COMMON.AUTH.UNAUTHORIZED`

> Missing or malformed authorization header.

The request didn't include a valid `Authorization` header in the expected Bearer token format.

**Fix:**

- Send the header as `Authorization: Bearer <token>`.
- Make sure it isn't empty or trimmed by an intermediate proxy.

### `COMMON.AUTH.INVALID_TOKEN`

> The provided token is invalid.

Heimdall received the request but determined the token is expired, malformed, revoked, or otherwise unusable.

**Fix:**

- Refresh or replace the token.
- Confirm the token was issued for the correct tenant or environment.

### `COMMON.AUTH.FORBIDDEN`

> The user is authenticated but not allowed to perform the action.

The token is valid, but access policies deny the request.

**Fix:**

- Check the user's roles or tags.
- Update the access policy if the user should be allowed.
- Retry with a service account that has the right permission, if you have one.

### `COMMON.INTERNAL.ERROR` during auth

> Authorization service unavailable.

Heimdall timed out, returned invalid data, or wasn't reachable.

**Fix:**

- Check Heimdall's health and logs.
- Verify network connectivity from the API service to Heimdall.
- Retry after Heimdall is restored.

---

## Environment and service initialization errors

These show up when an environment doesn't exist, or when the API process didn't initialize correctly at startup.

### Environment not found

> `Environment '<env>' not found. Run 'vulcan plan <env>' to create it.`

The environment doesn't exist in the state store. Common causes:

- the environment name is misspelled
- the environment was never created
- the state database was reset and lost it

**Fix:**

- Verify the environment name.
- Create it with `vulcan plan <env>`.
- Confirm the state store still contains the environment by running `vulcan environments`.

### Transpiler client not initialized

> The API cannot access the shared transpiler client.

The API process started, but the transpiler client wasn't wired up. Without it, semantic queries can't be transpiled.

**Fix:**

- Read API startup logs for the underlying initialization error.
- Verify transpiler-related configuration (host, port, credentials).
- Restart the service after fixing the cause.

### Environment context manager not initialized

> The API cannot resolve environment context.

Startup failed before the environment context manager was constructed.

**Fix:**

- Read API startup logs for the underlying error.
- Fix the initialization failure that you find there.
- Restart the API.

---

## Metric and semantic catalog errors

These come from the metric and model lookup paths in the semantic layer.

### Metric not found

> `Metric '<metric_name>' not found`

The metric name isn't in the loaded semantic catalog for this environment.

**Fix:**

- Check the metric name for typos.
- Confirm the metric is defined and loaded in the selected environment.

### Model not found

> `Model '<model_name>' not found`

The model name (or alias) isn't in the environment catalog.

**Fix:**

- Verify the model name.
- If you're using model aliases, confirm the alias actually resolves.
- Make sure the model has been planned into this environment.

### Unknown slices for metric

> `Unknown slice(s) for metric ...`

The request asked for slices that aren't defined for that metric.

**Fix:**

- Use only the slices the metric actually exposes.
- Look at the metric definition to see the allowed slice names.

### Metric misconfigured because slice ref is missing

> `Metric is misconfigured ... slice '<name>.ref' is missing`

The metric exists, but one of its slices doesn't carry the required semantic reference. This is a configuration bug, not a request bug.

**Fix:**

- Open the metric definition.
- Add the missing slice reference in the semantic configuration.

---

## Semantic field definition errors

These fail at validation time when Vulcan loads the semantic layer. They almost always come from a `models/semantics/*.yml` file that's been edited.

### Field has no role

> `Field '<name>' must have at least one role: is_column, is_dimension, is_measure, or is_segment`

The field was declared without any semantic or physical role, so Vulcan doesn't know what to do with it.

**Fix:**

- Mark the field as at least one valid role.
- Decide whether the field is a column, dimension, measure, or segment, and set that flag to `true`.

### Field is both measure and segment

> `Field '<name>' cannot be both measure and segment`

The field has conflicting roles. A field can't be aggregated and used as a segment filter at the same time.

**Fix:**

- Pick one role for the field.
- If you need both behaviors, define two separate fields, one for each.

### Time properties on non-dimension field

> `Field '<name>' has time properties but is_dimension=False`

You added time-specific metadata (granularity, time type, etc.) to a field that isn't marked as a dimension.

**Fix:**

- Set `is_dimension=true` if the field is meant to be a time dimension.
- Otherwise, remove the time-specific properties.

### Measure type on non-measure field

> `Field '<name>' has measure_type but is_measure=False`

You set `measure_type` on a field that isn't marked as a measure.

**Fix:**

- Set `is_measure=true` if the field should behave as a measure.
- Otherwise, remove `measure_type`.

---

## Perspective errors

Perspectives are saved views over a statement's result. These errors fire when you create, update, or read one.

### `SLUG_CONFLICT`

> The requested perspective slug is already taken.

Perspective slugs are unique. The slug you sent (or the one Vulcan generated) is already in use.

**Fix:**

- Pick a different slug.
- Use one of the slug suggestions returned in the API response.

### Statement not found for perspective creation or update

> `Statement not found`

The `statement_id` you supplied doesn't exist.

**Fix:**

- Verify the statement ID.
- Confirm the statement was created in the same system and environment you're posting against.

### Statement must be `SUCCESS`

> `Statement must be SUCCESS` or `Primary statement must be SUCCESS`

You can only build a perspective from a statement that completed successfully and has a stored result. Pending or failed statements are rejected.

**Fix:**

- Wait for the statement to finish.
- Fix the underlying query if it failed, then re-submit.

### Statement has no result

> `Statement has no result`, `Primary statement has no result`, or `Cache result not found`

The statement metadata exists, but the result isn't where Vulcan expects it. Either it was never produced, never stored, or its link is broken.

**Fix:**

- Check worker execution logs for that statement.
- Check object store and result metadata for the missing artifact.
- Re-run the statement after fixing storage or execution.

### Only owner can update perspective

> `Only owner can update perspective`

The current user isn't the owner of the perspective.

**Fix:**

- Update from the owner account.
- If your product workflow allows transferring ownership, do that first.

### Access denied on perspective

> `Access denied`

The perspective is private and the current user is neither the owner nor in the allowed user list.

**Fix:**

- Add the user to `allowed_user_ids` on the perspective.
- Make the perspective public if that's appropriate for your use case.
- Otherwise, access it as the owner.

---

## Result retrieval errors

These show up when you ask for a statement's result.

### Result not available yet

> `Result not available. Statement status: ...` or `Result not available. Primary status: ...`

You requested the result before the underlying statement reached `SUCCESS`.

**Fix:**

- Poll the statement detail endpoint first.
- Only fetch the result once the status is `SUCCESS`.

!!! note "How to poll properly"
    See [Vulcan API Guide: Step 3](vulcan_api_guide.md#step-3-poll-for-status) for the full status lifecycle and recommended poll behavior.

### Unsupported format

> `Format '<x>' not supported. Use: parquet, json, yaml, csv`

The requested output format isn't one Vulcan supports.

**Fix:**

- Use one of `parquet`, `json`, `yaml`, or `csv`.

### Invalid columns requested

> `Invalid columns requested: ...`

You asked for columns by name, but at least one of them isn't in the result schema.

**Fix:**

- Use only column names that the statement actually returned.
- Inspect the statement schema before asking for filtered output.

---

## File API validation errors

These come from the file API and protect the project root from path traversal and ignored files.

### Path outside project directory

> `Path outside project directory`

The path you sent resolves to a location outside the configured project root.

**Fix:**

- Use a path relative to the project directory.
- Don't use traversal patterns like `../`.

### Path matches ignore patterns

> `Path matches ignore patterns`

The path is blocked by configured ignore rules. This usually catches files that contain secrets, large artifacts, or anything you've explicitly told Vulcan not to expose.

**Fix:**

- Use a path that isn't covered by an ignore rule.
- Update the ignore rules only if exposing that file is intended and safe.

---

## Time range validation errors

### Invalid timestamp range

> `start_ts must be <= end_ts` or equivalent parameter names

The start timestamp is later than the end timestamp.

**Fix:**

- Swap the timestamps.
- Confirm the start value is earlier than or equal to the end value.

---

## Still stuck?

If your error isn't on this page, or the suggested fix didn't help:

- Run `vulcan transpile` locally on the failing payload to see the generated SQL and any earlier errors. See [Transpiling Semantics](transpiling_semantics.md).
- Look at the API logs around the failing request for additional context.
- Check the [Vulcan API Guide](vulcan_api_guide.md) troubleshooting section for connection, auth, and result-fetching issues that aren't validation errors.
- For lifecycle questions (why a query went to cache, why deduplication kicked in, why a status looks stuck), see [Semantic Query Lifecycle](semantic_query_lifecycle.md).
