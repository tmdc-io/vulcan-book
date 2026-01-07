# State

Vulcan stores project information in a state database, usually separate from your main warehouse.

The state database contains:

- Information about every [model version](../../components/model/overview.md) in your project (query, loaded intervals, dependencies)
- A list of every [Virtual Data Environment](./environments.md) in the project
- Which model versions are [promoted](./plans.md#plan-application) into each [Virtual Data Environment](./environments.md)
- Information about any [auto restatements](../../components/model/overview.md#auto_restatement_cron) in your project
- Other metadata such as current Vulcan and SQLGlot versions

The state database lets Vulcan remember what it's done before, so it computes the minimum set of operations to apply changes instead of rebuilding everything each time. It also tracks which historical data has already been backfilled for [incremental models](../../components/model/model_kinds.md#incremental_by_time_range), so you don't need branching logic in model queries.

!!! info "State database performance"

    The state database workload is OLTP and requires transaction support.

    Use databases designed for OLTP workloads such as [PostgreSQL](./integrations/engines/postgres.md).

    Using your warehouse OLAP database for state works for proof-of-concept projects but isn't suitable for production. It leads to poor performance and consistency.

    For more information on engines suitable for the Vulcan state database, see the [configuration guide](../../configurations/overview.md#gateways).

## Exporting / Importing State

Vulcan exports the state database to a `.json` file. You can inspect the file with any text editor or tool. You can also transfer the file and import it into another Vulcan project.

### Exporting state

Vulcan can export the state database to a file like so:

```bash
$ vulcan state export -o state.json
Exporting state to 'state.json' from the following connection:

Gateway: dev
State Connection:
├── Type: postgres
├── Catalog: sushi_dev
└── Dialect: postgres

Continue? [y/n]: y

    Exporting versions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 3/3   • 0:00:00
   Exporting snapshots ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 17/17 • 0:00:00
Exporting environments ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 1/1   • 0:00:00

State exported successfully to 'state.json'
```

This will produce a file `state.json` in the current directory containing the Vulcan state.

The state file is a simple `json` file that looks like:

```json
{
    /* State export metadata */
    "metadata": {
        "timestamp": "2025-03-16 23:09:00+00:00", /* UTC timestamp of when the file was produced */
        "file_version": 1, /* state export file format version */
        "importable": true /* whether or not this file can be imported with `vulcan state import` */
    },
    /* Library versions used to produce this state export file */
    "versions": {
        "schema_version": 76 /* vulcan state database schema version */,
        "sqlglot_version": "26.10.1" /* version of SQLGlot used to produce the state file */,
        "vulcan_version": "0.165.1" /* version of Vulcan used to produce the state file */,
    },
    /* array of objects containing every Snapshot (physical table) tracked by the Vulcan project */
    "snapshots": [
        { "name": "..." }
    ],
    /* object for every Virtual Data Environment in the project. key = environment name, value = environment details */
    "environments": {
        "prod": {
            /* information about the environment itself */
            "environment": {
                "..."
            },
            /* information about any before_all / after_all statements for this environment */
            "statements": [
                "..."
            ]
        }
    }
}
```

#### Specific environments

You can export a specific environment like so:

```sh
$ vulcan state export --environment my_dev -o my_dev_state.json
```

Every snapshot that is part of the environment is exported, not just differences from `prod`. This lets you import the environment elsewhere without assuming which snapshots already exist in state.

#### Local state

You can export local state like so:

```bash
$ vulcan state export --local -o local_state.json
```

This exports the state of the local context, including local changes that haven't been applied to any virtual data environments.

A local state export only has `snapshots` populated. `environments` is empty because virtual data environments exist only in the warehouse or remote state. The file is marked as **not importable**, so you can't use it with `vulcan state import`.

### Importing state

!!! warning "Back up your state database first!"

    Create an independent backup of your state database before importing state.

    Vulcan tries to wrap the state import in a transaction, but some database engines don't support transactions against DDL. An import error can leave the state database in an inconsistent state.

Vulcan can import a state file into the state database like so:

```bash
$ vulcan state import -i state.json --replace
Loading state from 'state.json' into the following connection:

Gateway: dev
State Connection:
├── Type: postgres
├── Catalog: sushi_dev
└── Dialect: postgres

[WARNING] This destructive operation will delete all existing state against the 'dev' gateway
and replace it with what\'s in the 'state.json' file.

Are you sure? [y/n]: y

State File Information:
├── Creation Timestamp: 2025-03-31 02:15:00+00:00
├── File Version: 1
├── Vulcan version: 0.170.1.dev0
├── Vulcan migration version: 76
└── SQLGlot version: 26.12.0

    Importing versions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 3/3   • 0:00:00
   Importing snapshots ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 17/17 • 0:00:00
Importing environments ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100.0% • 1/1   • 0:00:00

State imported successfully from 'state.json'
```

The state database structure must be present and up to date. Run `vulcan migrate` before `vulcan state import` if you get a version mismatch error.

To merge a partial state export (for example, a single environment), omit the `--replace` parameter:

```bash
$ vulcan state import -i state.json
...

[WARNING] This operation will merge the contents of the state file to the state located at the 'dev' gateway.
Matching snapshots or environments will be replaced.
Non-matching snapshots or environments will be ignored.

Are you sure? [y/n]: y

...
State imported successfully from 'state.json'
```


### Specific gateways

If your project has [multiple gateways](../../configurations/overview.md#gateways) with different state connections per gateway, target a specific gateway's state connection like this:

```bash
# state export
$ vulcan --gateway <gateway> state export -o state.json

# state import
$ vulcan --gateway <gateway> state import -i state.json
```

## Version Compatibility

When importing state, the state file must have been produced with the same major and minor Vulcan version you're using to import it.

If you attempt to import state with an incompatible version, you will get the following error:

```bash
$ vulcan state import -i state.json
...SNIP...

State import failed!
Error: Vulcan version mismatch. You are running '0.165.1' but the state file was created with '0.164.1'.
Please upgrade/downgrade your Vulcan version to match the state file before performing the import.
```

### Upgrading a state file

Upgrade a state file from an old Vulcan version to be compatible with a newer version:

1. Load it into a local database using the older Vulcan version
2. Install the newer Vulcan version
3. Run `vulcan migrate` to upgrade the state in the local database
4. Run `vulcan state export` to export it again. The new export is compatible with the newer Vulcan version.

Below is an example of how to upgrade a state file created with Vulcan `0.164.1` to be compatible with Vulcan `0.165.1`.

First, create and activate a virtual environment to isolate the Vulcan versions from your main environment:

```bash
$ python -m venv migration-env

$ . ./migration-env/bin/activate

(migration-env)$
```

Install the Vulcan version compatible with your state file. The correct version to use is printed in the error message, eg `the state file was created with '0.164.1'` means you need to install Vulcan `0.164.1`:

```bash
(migration-env)$ pip install "vulcan==0.164.1"
```

Add a gateway to your `config.yaml` like so:

```yaml
gateways:
  migration:
    connection:
      type: duckdb
      database: ./state-migration.duckdb
```

Define just enough config for Vulcan to use a local database for state export/import commands. Vulcan still needs to inherit `model_defaults` from your project to migrate state correctly, which is why we haven't used an isolated directory.

!!! warning

    From here on, specify `--gateway migration` to all Vulcan commands or you risk accidentally overwriting state on your main gateway.

You can now import your state export using the same version of Vulcan it was created with:

```bash
(migration-env)$ vulcan --gateway migration migrate

(migration-env)$ vulcan --gateway migration state import -i state.json
...
State imported successfully from 'state.json'
```

With the state imported, upgrade Vulcan and export the state from the new version. The new version was printed in the original error message, for example `You are running '0.165.1'`.

To upgrade Vulcan, simply install the new version:

```bash
(migration-env)$ pip install --upgrade "vulcan==0.165.1"
```

Migrate the state to the new version:

```bash
(migration-env)$ vulcan --gateway migration migrate
```

And finally, create a new state file which is now compatible with the new Vulcan version:

```bash
 (migration-env)$ vulcan --gateway migration state export -o state-migrated.json
```

The `state-migrated.json` file is now compatible with the newer version of Vulcan.
You can then transfer it to the place you originally needed it and import it in:

```bash
$ vulcan state import -i state-migrated.json
...
State imported successfully from 'state-migrated.json'
```