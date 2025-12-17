# CLI Commands

```
Usage: vulcan [OPTIONS] COMMAND [ARGS]...

  Vulcan command line tool.

Options:
  --version            Show the version and exit.
  -p, --paths TEXT     Path(s) to the Vulcan config/project.
  --config TEXT        Name of the config object. Only applicable to
                       configuration defined using Python script.
  --gateway TEXT       The name of the gateway.
  --ignore-warnings    Ignore warnings.
  --debug              Enable debug mode.
  --log-to-stdout      Display logs in stdout.
  --log-file-dir TEXT  The directory to write log files to.
  --dotenv PATH        Path to a custom .env file to load environment
                       variables.
  --help               Show this message and exit.

Commands:
  api                     Start the Vulcan API server (models, metrics,...
  audit                   Run audits for the target model(s).
  check_intervals         Show missing intervals in an environment,...
  clean                   Clears the Vulcan cache and any build artifacts.
  create_external_models  Create a schema file containing external model...
  create_test             Generate a unit test fixture for a given model.
  dag                     Render the DAG as an html file.
  destroy                 The destroy command removes all project resources.
  diff                    Show the diff between the local state and the...
  dlt_refresh             Attaches to a DLT pipeline with the option to...
  environments            Prints the list of Vulcan environments with its...
  evaluate                Evaluate a model and return a dataframe with a...
  fetchdf                 Run a SQL query and display the results.
  format                  Format all SQL models and audits.
  graphql                 Manage the GraphQL service (subcommands: up,...
  info                    Print information about a Vulcan project.
  invalidate              Invalidate the target environment, forcing its...
  janitor                 Run the janitor process on-demand.
  lint                    Run the linter for the target model(s).
  migrate                 Migrate Vulcan to the current running version.
  plan                    Apply local changes to the target environment.
  render                  Render a model's query, optionally expanding...
  rollback                Rollback Vulcan to the previous migration.
  run                     Evaluate missing intervals for the target...
  semantic                Semantic layer operations.
  state                   Commands for interacting with state
  table_diff              Show the diff between two tables or a selection...
  table_name              Prints the name of the physical table for the...
  test                    Run model unit tests.
  transpile               Transpile a semantic SQL or REST-style semantic...
  transpiler              Manage the Transpiler service (subcommands: up,...
```

## audit

```
Usage: vulcan audit [OPTIONS]

  Run audits for the target model(s).

Options:
  --model TEXT           A model to audit. Multiple models can be audited.
  -s, --start TEXT       The start datetime of the interval for which this
                         command will be applied.
  -e, --end TEXT         The end datetime of the interval for which this
                         command will be applied.
  --execution-time TEXT  The execution time (defaults to now).
  --help                 Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan audit
      Found 11 audit(s).
      unique_values on model sales.daily_sales ✅ PASS.
      not_null on model sales.daily_sales ✅ PASS.
      positive_values on model sales.daily_sales ✅ PASS.
      positive_values on model sales.daily_sales ✅ PASS.
      unique_values on model raw.raw_products ✅ PASS.
      not_null on model raw.raw_products ✅ PASS.
      unique_values on model raw.raw_customers ✅ PASS.
      not_null on model raw.raw_customers ✅ PASS.
      unique_values on model raw.raw_orders ✅ PASS.
      not_null on model raw.raw_orders ✅ PASS.
      positive_values on model raw.raw_orders ✅ PASS.

      Finished with 0 audit errors and 0 audits skipped.
      Done.
    ```

## check_intervals

```
Usage: vulcan check_intervals [OPTIONS] [ENVIRONMENT]

  Show missing intervals in an environment, respecting signals.

Options:
  --no-signals         Disable signal checks and only show missing intervals.
  --select-model TEXT  Select specific models to show missing intervals for.
  -s, --start TEXT     The start datetime of the interval for which this
                       command will be applied.
  -e, --end TEXT       The end datetime of the interval for which this command
                       will be applied.
  --help               Show this message and exit.
```


## clean

```
Usage: vulcan clean [OPTIONS]

  Clears the Vulcan cache and any build artifacts.

Options:
  --help  Show this message and exit.
```

## create_external_models

```
Usage: vulcan create_external_models [OPTIONS]

  Create a schema file containing external model schemas.

Options:
  --help  Show this message and exit.
```
??? example "Example"

    ```
    $ vulcan create_external_models
    ```


## create_test

```
Usage: vulcan create_test [OPTIONS] MODEL

  Generate a unit test fixture for a given model.

Options:
  -q, --query <TEXT TEXT>...  Queries that will be used to generate data for
                              the model's dependencies.
  -o, --overwrite             When true, the fixture file will be overwritten
                              in case it already exists.
  -v, --var <TEXT TEXT>...    Key-value pairs that will define variables
                              needed by the model.
  -p, --path TEXT             The file path corresponding to the fixture,
                              relative to the test directory. By default, the
                              fixture will be created under the test directory
                              and the file name will be inferred based on the
                              test's name.
  -n, --name TEXT             The name of the test that will be created. By
                              default, it's inferred based on the model's
                              name.
  --include-ctes              When true, CTE fixtures will also be generated.
  --help                      Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan create_test sales.daily_sales --query raw.raw_orders "SELECT * FROM raw.raw_orders"
    ```

## dag

```
Usage: vulcan dag [OPTIONS] FILE

  Render the DAG as an html file.

Options:
  --select-model TEXT  Select specific models to include in the dag.
  --help               Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan dag ./dag.html
    ```

## destroy

```
Usage: vulcan destroy

  Removes all state tables, the Vulcan cache and all project resources, including warehouse objects. This includes all tables, views and schemas managed by Vulcan, as well as any external resources that may have been created by other tools within those schemas.

Options:
  --help               Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan destroy
    [WARNING] This will permanently delete all engine-managed objects, state tables and Vulcan cache.
    The operation may disrupt any currently running or scheduled plans.

    Schemas to be deleted:
      • warehouse.raw
      • warehouse.sales

    Snapshot tables to be deleted:
      • warehouse.vulcan__raw.raw__raw_customers__1474975870
      • warehouse.vulcan__raw.raw__raw_orders__1032938324
      • warehouse.vulcan__raw.raw__raw_products__3337559381
      • warehouse.vulcan__sales.sales__daily_sales__2671854529

    This action will DELETE ALL the above resources managed by Vulcan AND
    potentially external resources created by other tools in these schemas.

    Are you ABSOLUTELY SURE you want to proceed with deletion? [y/n]: y
    Environment 'prod' invalidated.

    Deleted object warehouse.raw
    Deleted object warehouse.sales
    Deleted object warehouse.vulcan__raw.raw__raw_products__3337559381__dev
    Deleted object warehouse.vulcan__raw.raw__raw_customers__1474975870__dev
    Deleted object warehouse.vulcan__sales.sales__daily_sales__2671854529__dev
    Deleted object warehouse.vulcan__sales.sales__daily_sales__2671854529
    Deleted object warehouse.vulcan__raw.raw__raw_customers__1474975870
    Deleted object warehouse.vulcan__raw.raw__raw_products__3337559381
    Deleted object warehouse.vulcan__raw.raw__raw_orders__1032938324__dev
    Deleted object warehouse.vulcan__raw.raw__raw_orders__1032938324
    State tables removed.
    Destroy completed successfully.
    ```


## dlt_refresh

```
Usage: dlt_refresh PIPELINE [OPTIONS]

  Attaches to a DLT pipeline with the option to update specific or all models of the Vulcan project.

Options:
  -t, --table TEXT  The DLT tables to generate Vulcan models from. When none specified, all new missing tables will be generated.
  -f, --force       If set it will overwrite existing models with the new generated models from the DLT tables.
  --help            Show this message and exit.
```

## diff

```
Usage: vulcan diff [OPTIONS] ENVIRONMENT

  Show the diff between the local state and the target environment.

Options:
  --help  Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan diff prod

    Differences from the `prod` environment:

    Models:
    └── Directly Modified:
        └── sales.daily_sales
            --- .../daily_sales.sql

            +++ .../daily_sales.sql

            @@ -20,10 +20,11 @@

              grains (order_date)
            )
            SELECT
              CAST(order_date AS TIMESTAMP) AS order_date,
              CAST(COUNT(order_id) AS INT) AS total_orders,
              CAST(SUM(total_amount) AS DOUBLE PRECISION) AS total_revenue,
            -  CAST(MAX(order_id) AS VARCHAR) AS last_order_id
            +  CAST(MAX(order_id) AS VARCHAR) AS last_order_id,
            +  COUNT(DISTINCT product_id) AS total_products
            FROM raw.raw_orders
            GROUP BY
              order_date
    Semantics:
    └── Indirectly Modified:
        ├── semantic-model:sales.daily_sales
        ├── semantic-metric:order_volume
        └── semantic-metric:revenue_trends
    Quality Checks:
    └── Indirectly Modified:
        ├── check-suite:sales.daily_sales:accuracy
        ├── check-suite:sales.daily_sales:timeliness
        ├── check-suite:sales.daily_sales:completeness
        └── check-suite:sales.daily_sales:validity
    ```

## environments
```
Usage: vulcan environments [OPTIONS]

  Prints the list of Vulcan environments with its expiry datetime.

Options:
  --help             Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan environments
    Number of Vulcan environments are: 2
    prod - No Expiry
    dev - 2025-12-23 00:00:00
    ```

## evaluate

```
Usage: vulcan evaluate [OPTIONS] MODEL

  Evaluate a model and return a dataframe with a default limit of 1000.

Options:
  -s, --start TEXT       The start datetime of the interval for which this
                         command will be applied.
  -e, --end TEXT         The end datetime of the interval for which this
                         command will be applied.
  --execution-time TEXT  The execution time (defaults to now).
  --limit INTEGER        The number of rows which the query should be limited
                         to.
  --help                 Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan evaluate sales.daily_sales
       order_date  total_orders  total_revenue last_order_id  total_products
    0  2024-01-05             1          70.77          O001               1
    1  2024-01-10             1          44.22          O002               1
    2  2024-01-15             1          65.52          O003               1
    3  2024-01-20             1          79.42          O004               1
    4  2024-02-01             1          91.35          O005               1
    ....
    19 2024-05-15             1          38.38          O020               1
    ```

## fetchdf

```
Usage: vulcan fetchdf [OPTIONS] SQL

  Run a SQL query and display the results.

Options:
  --help  Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan fetchdf "select count(*) from sales.daily_sales"
    ┏━━━━━━━┓
    ┃ count ┃
    ┡━━━━━━━┩
    │ 20    │
    └───────┘
    ```

## format

```
Usage: vulcan format [OPTIONS]

  Format all SQL models and audits.

Options:
  -t, --transpile TEXT        Transpile project models to the specified
                              dialect.
  --append-newline            Include a newline at the end of each file.
  --no-rewrite-casts          Preserve the existing casts, without rewriting
                              them to use the :: syntax.
  --normalize                 Whether or not to normalize identifiers to
                              lowercase.
  --pad INTEGER               Determines the pad size in a formatted string.
  --indent INTEGER            Determines the indentation size in a formatted
                              string.
  --normalize-functions TEXT  Whether or not to normalize all function names.
                              Possible values are: 'upper', 'lower'
  --leading-comma             Determines whether or not the comma is leading
                              or trailing in select expressions. Default is
                              trailing.
  --max-text-width INTEGER    The max number of characters in a segment before
                              creating new lines in pretty mode.
  --check                     Whether or not to check formatting (but not
                              actually format anything).
  --help                      Show this message and exit.
```

## info

```
Usage: vulcan info [OPTIONS]

  Print information about a Vulcan project.

  Includes counts of project models and macros and connection tests for the
  data warehouse.

Options:
  --skip-connection  Skip the connection test.
  -v, --verbose      Verbose output.
  --help  Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan info
    Models: 4
    Macros: 0
    Data warehouse connection succeeded
    State backend connection succeeded
    ```

## init

```
Usage: vulcan init [OPTIONS] [ENGINE]

  Create a new Vulcan repository.

Options:
  -t, --template TEXT  Project template. Supported values: dbt, dlt, default,
                       empty.
  --dlt-pipeline TEXT  DLT pipeline for which to generate a Vulcan project.
                       Use alongside template: dlt
  --dlt-path TEXT      The directory where the DLT pipeline resides. Use
                       alongside template: dlt
  --help               Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan init postgres
    ```

## invalidate

```
Usage: vulcan invalidate [OPTIONS] ENVIRONMENT

  Invalidate the target environment, forcing its removal during the next run
  of the janitor process.

Options:
  -s, --sync  Wait for the environment to be deleted before returning. If not
              specified, the environment will be deleted asynchronously by the
              janitor process. This option requires a connection to the data
              warehouse.
  --help      Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan invalidate dev
    Environment 'dev' invalidated.
    ```

## janitor

```
Usage: vulcan janitor [OPTIONS]

  Run the janitor process on-demand.

  The janitor cleans up old environments and expired snapshots.

Options:
  --ignore-ttl  Cleanup snapshots that are not referenced in any environment,
                regardless of when they're set to expire
  --help        Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan janitor
    Deleted object warehouse.sales__dev
    Deleted object warehouse.raw__dev
    Cleanup complete.
    ```

## migrate

```
Usage: vulcan migrate [OPTIONS]

  Migrate Vulcan to the current running version.

Options:
  --help  Show this message and exit.
```

!!! danger "Caution"

    The `migrate` command affects all Vulcan users. Contact your Vulcan administrator before running.

## plan

```
Usage: vulcan plan [OPTIONS] [ENVIRONMENT]

  Apply local changes to the target environment.

Options:
  -s, --start TEXT                The start datetime of the interval for which
                                  this command will be applied.
  -e, --end TEXT                  The end datetime of the interval for which
                                  this command will be applied.
  --execution-time TEXT           The execution time (defaults to now).
  --create-from TEXT              The environment to create the target
                                  environment from if it doesn't exist.
                                  Default: prod.
  --skip-tests                    Skip tests prior to generating the plan if
                                  they are defined.
  --skip-linter                   Skip linting prior to generating the plan if
                                  the linter is enabled.
  -r, --restate-model TEXT        Restate data for specified models and models
                                  downstream from the one specified. For
                                  production environment, all related model
                                  versions will have their intervals wiped,
                                  but only the current versions will be
                                  backfilled. For development environment,
                                  only the current model versions will be
                                  affected.
  --no-gaps                       Ensure that new snapshots have no data gaps
                                  when comparing to existing snapshots for
                                  matching models in the target environment.
  --skip-backfill, --dry-run      Skip the backfill step and only create a
                                  virtual update for the plan.
  --empty-backfill                Produce empty backfill. Like --skip-backfill
                                  no models will be backfilled, unlike --skip-
                                  backfill missing intervals will be recorded
                                  as if they were backfilled.
  --forward-only                  Create a plan for forward-only changes.
  --allow-destructive-model TEXT  Allow destructive forward-only changes to
                                  models whose names match the expression.
  --allow-additive-model TEXT     Allow additive forward-only changes to
                                  models whose names match the expression.
  --effective-from TEXT           The effective date from which to apply
                                  forward-only changes on production.
  --no-prompts                    Disable interactive prompts for the backfill
                                  time range. Please note that if this flag is
                                  set and there are uncategorized changes,
                                  plan creation will fail.
  --auto-apply                    Automatically apply the new plan after
                                  creation.
  --no-auto-categorization        Disable automatic change categorization.
  --include-unmodified            Include unmodified models in the target
                                  environment.
  --select-model TEXT             Select specific model changes that should be
                                  included in the plan.
  --backfill-model TEXT           Backfill only the models whose names match
                                  the expression.
  --no-diff                       Hide text differences for changed models.
  --run                           Run latest intervals as part of the plan
                                  application (prod environment only).
  --enable-preview                Enable preview for forward-only models when
                                  targeting a development environment.
  --diff-rendered                 Output text differences for the rendered
                                  versions of the models and standalone
                                  audits.
  --explain                       Explain the plan instead of applying it.
  --ignore-cron                   Run all missing intervals, ignoring
                                  individual cron schedules. Only applies if
                                  --run is set.
  --min-intervals INTEGER         For every model, ensure at least this many
                                  intervals are covered by a missing intervals
                                  check regardless of the plan start date
  -v, --verbose                   Verbose output. Use -vv for very verbose
                                  output.
  --help                          Show this message and exit.
```

## api

```
Usage: vulcan api [OPTIONS]

  Start the Vulcan API server (models, metrics, lineage, telemetry).

Options:
  --host TEXT        Bind socket to this host. Default: 0.0.0.0
  --port INTEGER     Bind socket to this port. Default: 8000
  --reload           Enable auto-reload on file changes. Default: False
  --workers INTEGER  Number of worker processes. Default: 1
  --help             Show this message and exit.
```

## render

```
Usage: vulcan render [OPTIONS] MODEL

  Render a model's query, optionally expanding referenced models.

Options:
  -s, --start TEXT            The start datetime of the interval for which
                              this command will be applied.
  -e, --end TEXT              The end datetime of the interval for which this
                              command will be applied.
  --execution-time TEXT       The execution time (defaults to now).
  --expand TEXT               Whether or not to expand materialized models
                              (defaults to False). If True, all referenced
                              models are expanded as raw queries. Multiple
                              model names can also be specified, in which case
                              only they will be expanded as raw queries.
  --dialect TEXT              The SQL dialect to render the query as.
  --no-format                 Disable fancy formatting of the query.
  --max-text-width INTEGER    The max number of characters in a segment before
                              creating new lines in pretty mode.
  --leading-comma             Determines whether or not the comma is leading
                              or trailing in select expressions. Default is
                              trailing.
  --normalize-functions TEXT  Whether or not to normalize all function names.
                              Possible values are: 'upper', 'lower'
  --indent INTEGER            Determines the indentation size in a formatted
                              string.
  --pad INTEGER               Determines the pad size in a formatted string.
  --normalize                 Whether or not to normalize identifiers to
                              lowercase.
  --help                      Show this message and exit.
```

??? example "Example"

    ```
    $ vulcan render sales.daily_sales

    SELECT
      CAST("raw_orders"."order_date" AS TIMESTAMP) AS "order_date",
      CAST(COUNT("raw_orders"."order_id") AS INT) AS "total_orders",
      CAST(SUM("raw_orders"."total_amount") AS DOUBLE PRECISION) AS "total_revenue",
      CAST(MAX("raw_orders"."order_id") AS VARCHAR) AS "last_order_id",
      COUNT(DISTINCT "raw_orders"."product_id") AS "total_products"
    FROM "warehouse"."vulcan__raw"."raw__raw_orders__1032938324" AS "raw_orders" /* warehouse.raw.raw_orders */
    GROUP BY
      "raw_orders"."order_date"
    ORDER BY
      "order_date"
    ```

## rollback

```
Usage: vulcan rollback [OPTIONS]

  Rollback Vulcan to the previous migration.

Options:
  --help  Show this message and exit.
```

!!! danger "Caution"

    The `rollback` command affects all Vulcan users. Contact your Vulcan administrator before running.

## run

```
Usage: vulcan run [OPTIONS] [ENVIRONMENT]

  Evaluate missing intervals for the target environment.

Options:
  -s, --start TEXT              The start datetime of the interval for which
                                this command will be applied.
  -e, --end TEXT                The end datetime of the interval for which
                                this command will be applied.
  --skip-janitor                Skip the janitor task.
  --ignore-cron                 Run for all missing intervals, ignoring
                                individual cron schedules.
  --select-model TEXT           Select specific models to run. Note: this
                                always includes upstream dependencies.
  --exit-on-env-update INTEGER  If set, the command will exit with the
                                specified code if the run is interrupted by an
                                update to the target environment.
  --no-auto-upstream            Do not automatically include upstream models.
                                Only applicable when --select-model is used.
                                Note: this may result in missing / invalid
                                data for the selected models.
  --help                        Show this message and exit.
```

## state

```
Usage: vulcan state [OPTIONS] COMMAND [ARGS]...

  Commands for interacting with state

Options:
  --help  Show this message and exit.

Commands:
  export  Export the state database to a file
  import  Import a state export file back into the state database
```

### export

```
Usage: vulcan state export [OPTIONS]

  Export the state database to a file

Options:
  -o, --output-file FILE  Path to write the state export to  [required]
  --environment TEXT      Name of environment to export. Specify multiple
                          --environment arguments to export multiple
                          environments
  --local                 Export local state only. Note that the resulting
                          file will not be importable
  --no-confirm            Do not prompt for confirmation before exporting
                          existing state
  --help                  Show this message and exit.
```

### import

```
Usage: vulcan state import [OPTIONS]

  Import a state export file back into the state database

Options:
  -i, --input-file FILE  Path to the state file  [required]
  --replace              Clear the remote state before loading the file. If
                         omitted, a merge is performed instead
  --no-confirm           Do not prompt for confirmation before updating
                         existing state
  --help                 Show this message and exit.
```

## table_diff

```
Usage: vulcan table_diff [OPTIONS] SOURCE:TARGET [MODEL]

  Show the diff between two tables or a selection of models when they are
  specified.

Options:
  -o, --on TEXT            The column to join on. Can be specified multiple
                           times. The model grain will be used if not
                           specified.
  -s, --skip-columns TEXT  The column(s) to skip when comparing the source and
                           target table.
  --where TEXT             An optional where statement to filter results.
  --limit INTEGER          The limit of the sample dataframe.
  --show-sample            Show a sample of the rows that differ. With many
                           columns, the output can be very wide.
  -d, --decimals INTEGER   The number of decimal places to keep when comparing
                           floating point columns. Default: 3
  --skip-grain-check       Disable the check for a primary key (grain) that is
                           missing or is not unique.
  --warn-grain-check       Warn if any selected model is missing a grain,
                           and compute diffs for the remaining models.
  --temp-schema TEXT       Schema used for temporary tables. It can be
                           `CATALOG.SCHEMA` or `SCHEMA`. Default:
                           `vulcan_temp`
  -m, --select-model TEXT  Specify one or more models to data diff. Use
                           wildcards to diff multiple models. Ex: '*' (all
                           models with applied plan diffs), 'demo.model+'
                           (this and downstream models),
                           'git:feature_branch' (models with direct
                           modifications in this branch only)
  --help                   Show this message and exit.
```

## table_name

```
Usage: vulcan table_name [OPTIONS] MODEL_NAME

  Prints the name of the physical table for the given model.

Options:
  --environment, --env TEXT  The environment to source the model version from.
  --prod                     If set, return the name of the physical table
                             that will be used in production for the model
                             version promoted in the target environment.
  --help                     Show this message and exit.
```

## test

```
Usage: vulcan test [OPTIONS] [TESTS]...

  Run model unit tests.

Options:
  -k TEXT              Only run tests that match the pattern of substring.
  -v, --verbose        Verbose output.
  --preserve-fixtures  Preserve the fixture tables in the testing database,
                       useful for debugging.
  --help               Show this message and exit.
```

## semantic

```
Usage: vulcan semantic [OPTIONS] {export} [ENVIRONMENT]

  Semantic layer operations.

  This command provides semantic layer export functionality, allowing users to
  convert semantic models and metrics into CubeJS-compatible YAML schemas.

Options:
  -o, --output PATH   Output file path for the CubeJS schema.  [required]
  --strict            Strict mode: export only explicitly defined semantic
                      models.
  --no-auto-measures  Disable automatic generation of measures (e.g., _count)
                      for models with grains.
  --no-confirm        Do not prompt for confirmation before overwriting
                      existing output file.
  --help              Show this message and exit.
```

## transpile

```
Usage: vulcan transpile [OPTIONS] [QUERY]

  Transpile a semantic SQL or REST-style semantic query to executable SQL.

Options:
  --format [sql|rest]        Input type: semantic SQL ('sql') or REST-style
                             semantic payload ('rest').  [required]
  --file TEXT                Read query or REST payload from file. Use '-' to
                             read from stdin.
  --user TEXT                User id to propagate in the X-User header
                             (defaults to 'cli').
  --disable-post-processing  Disable post-processing in the Transpiler.
  --style [pretty|compact]   SQL output style: 'pretty' (formatted with
                             indentation), 'compact' (unformatted but
                             processed),
  --help                     Show this message and exit.
```

## transpiler

```
Usage: vulcan transpiler [OPTIONS] {up|down}

  Manage the Transpiler service (subcommands: up, down).

Options:
  --no-detach  Run docker compose in the foreground (omit -d).
  --help       Show this message and exit.
```

## graphql

```
Usage: vulcan graphql [OPTIONS] {up|down}

  Manage the GraphQL service (subcommands: up, down).

Options:
  --no-detach  Run docker compose in the foreground (omit -d).
  --help       Show this message and exit.
```

## lint
```
Usage: vulcan lint [OPTIONS]
  Run linter for the target model(s).

Options:
  --model TEXT           A model to lint. Multiple models can be linted.  If no models are specified, every model will be linted.
  --help                 Show this message and exit.

```
