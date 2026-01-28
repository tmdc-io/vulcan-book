# Migrations

New versions of Vulcan may be incompatible with the project's stored metadata format. Migrations provide a way to upgrade the project metadata format to operate with the new Vulcan version.

## Detecting incompatibility
When issuing a Vulcan command, Vulcan will automatically check for incompatibilities between the installed version of Vulcan and the project's metadata format, prompting what action is required. Vulcan commands will not execute until the action is complete.

### Installed version is newer than metadata format
In this scenario, the project's metadata format needs to be migrated.

```bash
> vulcan plan my_dev
Error: Vulcan (local) is using version '2' which is ahead of '1' (remote). Please run a migration ('vulcan migrate' command).
```

### Installed version is older than metadata format
Here, the installed version of Vulcan needs to be upgraded.

```bash
> vulcan plan my_dev
VulcanError: Vulcan (local) is using version '1' which is behind '2' (remote). Please upgrade Vulcan.
```

## How to migrate

### Built-in Scheduler Migrations

The project metadata can be migrated to the latest metadata format using Vulcan's migrate command.

```bash
> vulcan migrate
```

Migration should be issued manually by a single user and the migration will affect all users of the project. 
Migrations should ideally run when no one will be running plan/apply. 
Migrations should not be run in parallel. 
Due to these constraints, it is better for a person responsible for managing Vulcan to manually issue migrations. 
Therefore, it is not recommended to issue migrations from CI/CD pipelines.
