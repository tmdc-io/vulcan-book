# Spark

Apache Spark is a unified analytics engine for large-scale data processing. Vulcan integrates with Spark to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `spark`

### Prerequisites

1. A running Spark cluster (standalone, YARN, or Kubernetes)
2. Spark 3.x or higher (3.4+ recommended for catalog support)
3. Network connectivity to the Spark master node

### Permissions

Vulcan requires the following Spark permissions:

- Access to create and manage tables in the configured catalog
- Read/write access to the configured storage (S3, HDFS, etc.)
- Permission to submit Spark applications

### Connection Options

Here are all the connection parameters you can use when setting up a Spark gateway:

| Option       | Description                                                              | Type   | Required |
|--------------|--------------------------------------------------------------------------|:------:|:--------:|
| `type`       | Engine type name - must be `spark`                                       | string | Y        |
| `config_dir` | Value to set for `SPARK_CONFIG_DIR`                                      | string | N        |
| `catalog`    | The catalog to use when issuing commands                                 | string | N        |
| `config`     | Key/value pairs to set for the Spark Configuration                       | dict   | N        |

### Catalog Support

Vulcan's Spark integration is designed for single catalog usage. All models must be defined with a single catalog.

If `catalog` is not set, the behavior depends on the Spark version:

| Spark Version | Default Catalog Behavior |
|---------------|--------------------------|
| >= 3.4 | Default catalog determined at runtime |
| < 3.4 | Default catalog is `spark_catalog` |

### Docker Images

The following Docker images are available for running Vulcan with Spark:

| Image | Description |
|-------|-------------|
| `tmdcio/vulcan-spark:0.228.1.6` | Main Vulcan API service for Spark |
| `tmdcio/vulcan-transpiler:0.228.1.1` | SQL transpiler service |

Pull the images:

```bash
docker pull tmdcio/vulcan-spark:0.228.1.6
docker pull tmdcio/vulcan-transpiler:0.228.1.1
```

!!! note
    Spark may not be used for the Vulcan state connection. Use a transactional database like PostgreSQL for the `state_connection`.

!!! warning
    Always use environment variables for sensitive credentials in your Spark configuration (S3 keys, database passwords, etc.).
