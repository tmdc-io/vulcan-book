# Trino

Trino (formerly PrestoSQL) is a distributed SQL query engine designed for fast, interactive analytics across large datasets. It excels at querying data from multiple sources including data lakes, databases, and object storage. Vulcan integrates with Trino to manage your data transformations using catalogs like Iceberg, Hive, and Delta Lake.

## Local/Built-in Scheduler
**Engine Adapter Type**: `trino`

### Prerequisites

1. A Trino cluster with coordinator and worker nodes
2. A catalog configured (e.g., Iceberg, Hive, or Delta Lake)
3. Network connectivity to the Trino coordinator

### Permissions

Vulcan requires the following Trino permissions (depending on your security configuration):

- `CREATE SCHEMA` on the target catalog
- `CREATE TABLE` and `CREATE VIEW` on schemas
- `SELECT`, `INSERT`, `UPDATE`, `DELETE` on tables
- `DROP TABLE` for table cleanup during development

### Connection Options

Here are all the connection parameters you can use when setting up a Trino gateway:

| Option        | Description                                                              | Type   | Required |
|---------------|--------------------------------------------------------------------------|:------:|:--------:|
| `type`        | Engine type name - must be `trino`                                       | string | Y        |
| `host`        | The hostname of the Trino coordinator                                    | string | Y        |
| `port`        | The port number of the Trino coordinator (default: `8080`)               | int    | Y        |
| `user`        | The username for Trino authentication                                    | string | Y        |
| `catalog`     | The default catalog to use for queries                                   | string | Y        |
| `http_scheme` | The HTTP scheme (`http` or `https`)                                      | string | N        |
| `password`    | The password for Trino authentication (if password authentication is enabled) | string | N        |
| `roles`       | Role to use for queries (if role-based access control is enabled)        | dict   | N        |

### Authentication Methods

- Username authentication (required)
- Password authentication (optional): Use `password` parameter if password authentication is enabled
- Role-based access control (optional): Use `roles` parameter if RBAC is enabled
- HTTP scheme configuration (optional): Use `http_scheme: https` for secure connections in production environments

### Docker Images

The following Docker images are available for running Vulcan with Trino:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-trino:0.228.1.19` | Main Vulcan API service for Trino |

Pull the images:

```bash
docker pull tmdcio/vulcan-trino:0.228.1.19
```

### Materialization Strategy

Materialization strategies for Trino depend on the model kind and underlying catalog capabilities (Iceberg, Hive, Delta Lake, etc.). For detailed information about how different model kinds are materialized, see the [model kinds documentation](../../../components/model/model_kinds.md).

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    Use `http_scheme: https` for secure connections in production environments.

!!! warning
    Always use environment variables for passwords: `password: {{ env_var('TRINO_PASSWORD') }}`

## DataOS Deployment with Minerva

Minerva is the Trino-based query cluster that ships with DataOS. From Vulcan's perspective it is a standard Trino endpoint, so the same `trino` adapter is used. The only difference is *how* you wire the connection: instead of hard-coding host, user, catalog, and password into `config.yaml`, you store them in a DataOS secret and let the `vulcan` resource project them into the runtime as environment variables. `config.yaml` then reads those variables with `env_var(...)`.

This pattern keeps credentials out of the project repo and lets you promote the same code across environments by swapping the secret.

### How It Works

1. Store the Minerva (Trino) connection values in a DataOS secret.
2. Use `spec.use.projection` in the `vulcan` resource (`domain-resource.yaml`) to map secret values into environment variables for the runtime.
3. Reference those environment variables in `config.yaml` under the Trino gateway connection.

### Generate the Minerva Password

The Minerva password is a base64-encoded JSON object containing the cluster name, an API key, and the tenant. Generate it with:

```bash
echo '{"cluster": "<cluster-name>", "apikey": "<your-api-key>", "tenant": "<tenant-name>"}' | base64
```

Use the resulting string as the `PASSWORD` value in the secret below.

### Example Secret

Create a `key-value` secret that holds the Minerva connection details:

```yaml
name: trino-connection-secret
version: v2alpha
type: secret
layer: user
secret:
  type: key-value
  data:
    HOST: "tcp.<env-name>"
    USER: "<user-id>"
    CATALOG: "<catalog-name>"
    PASSWORD: "<base64-password-from-step-above>"
```

| Key        | Description                                                      |
|------------|------------------------------------------------------------------|
| `HOST`     | Minerva (Trino) coordinator host (e.g. `tcp.<env-name>`)         |
| `USER`     | DataOS user id used to authenticate                              |
| `CATALOG`  | Default catalog to query                                         |
| `PASSWORD` | Base64 string produced by the `echo ... | base64` command above  |

Apply it with:

```bash
ds resource apply -f trino-connection-secret.yaml
```

### Example `config.yaml`

The gateway block stays in the project's `config.yaml`, but every sensitive value is sourced from an environment variable:

```yaml
name: trino-analytics-prod
display_name: Trino Analytics

model_defaults:
  dialect: trino

gateways:
  default:
    connection:
      type: trino
      host: "{{ env_var('TRINO_HOST', '') }}"
      port: 7432
      user: "{{ env_var('TRINO_USER', '') }}"
      catalog: "{{ env_var('TRINO_CATALOG', '') }}"
      http_scheme: https
      method: basic
      password: "{{ env_var('TRINO_PASSWORD', '') }}"
      verify: true
```

### Example `domain-resource.yaml`

The `vulcan` resource declares the secret it consumes and projects each key into an environment variable. The `base64_decode` filter unwraps the values stored in the secret so the runtime sees the raw connection details:

```yaml
version: v1alpha
type: vulcan
name: trino-analytics-prod

spec:
  runAsUser: <your-user>
  compute: <your-compute>
  engine: trino
  repo:
    url: https://bitbucket.org/<your-org>/<your-repo>
    baseDir: path/to/project
    secret: <your-tenant>:git-sync
  use:
    projection:
      secrets:
        - id: <your-tenant>:trino-connection-secret
          contextAlias: trn
      projections:
        envVars:
          - key: TRINO_HOST
            template: "{{ secrets['trn'].HOST | base64_decode }}"
          - key: TRINO_USER
            template: "{{ secrets['trn'].USER | base64_decode }}"
          - key: TRINO_CATALOG
            template: "{{ secrets['trn'].CATALOG | base64_decode }}"
          - key: TRINO_PASSWORD
            template: "{{ secrets['trn'].PASSWORD | base64_decode }}"
```

### Secret-to-Environment Mapping

The projection above maps each secret key to the variable that `config.yaml` reads:

| Secret Key | Environment Variable | Used In `config.yaml` As           |
|------------|----------------------|------------------------------------|
| `HOST`     | `TRINO_HOST`         | `host: "{{ env_var('TRINO_HOST') }}"`     |
| `USER`     | `TRINO_USER`         | `user: "{{ env_var('TRINO_USER') }}"`     |
| `CATALOG`  | `TRINO_CATALOG`      | `catalog: "{{ env_var('TRINO_CATALOG') }}"` |
| `PASSWORD` | `TRINO_PASSWORD`     | `password: "{{ env_var('TRINO_PASSWORD') }}"` |

!!! note
    Minerva is a Trino cluster, so the engine adapter type stays `trino` in both `model_defaults.dialect` and `gateways.default.connection.type`.

!!! tip
    To rotate credentials, update the secret and re-apply the `vulcan` resource — no change to `config.yaml` is required.
