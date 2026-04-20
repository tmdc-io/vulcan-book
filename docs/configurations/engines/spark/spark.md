# Spark

Apache Spark is a unified analytics engine for large-scale data processing. Vulcan integrates with Spark to manage your data transformations with version control and safe deployments.

## Local/Built-in Scheduler
**Engine Adapter Type**: `spark`

### Prerequisites

1. A running Spark cluster (standalone, YARN, or Kubernetes)
2. Spark 3.x or higher (3.4+ recommended for catalog support)
3. Network connectivity to the Spark master node
4. **Spark version alignment** — the Spark version on your cluster must match the version bundled in the Vulcan Spark Docker image

!!! warning "Spark Version Mismatch"
    The Spark version running on your cluster **must match** the version bundled in the Vulcan Spark Docker image. The Vulcan container acts as the Spark driver and serializes task objects that your cluster's executors deserialize. Even a minor version difference (e.g., 3.5.1 in the image vs 3.5.7 on your cluster) can break serialization and produce errors like:

    ```
    java.io.InvalidClassException: org.apache.spark.scheduler.Task;
    local class incompatible: stream classdesc serialVersionUID = <UID_A>,
    local class serialVersionUID = <UID_B>
    ```

    To resolve this, either:

    - Update your Spark cluster to match the version in the Vulcan image, **or**
    - Use a Vulcan Spark Docker image built with the same Spark version as your cluster

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

### Authentication Methods

- Configuration-based authentication: Authentication credentials are typically configured through Spark configuration (`config` parameter) or `SPARK_CONFIG_DIR` environment variable
- Catalog-based authentication: Depends on the underlying catalog (S3, HDFS, etc.) configured in Spark

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
| `tmdcio/vulcan-spark:0.228.1.18` | Main Vulcan API service for Spark |

Pull the images:

```bash
docker pull tmdcio/vulcan-spark:0.228.1.18
```

### Materialization Strategy

Spark uses the following materialization strategies depending on the model kind:

| Model Kind | Strategy | Description |
|------------|----------|-------------|
| `INCREMENTAL_BY_TIME_RANGE` | INSERT OVERWRITE by time column partition | Vulcan will overwrite the entire partition that corresponds to the time column, rather than deleting and inserting individual records. This approach is more efficient for partitioned data and leverages Spark's native partitioning capabilities. |
| `INCREMENTAL_BY_UNIQUE_KEY` | Not supported | Spark does not support `INCREMENTAL_BY_UNIQUE_KEY` models. Consider using `INCREMENTAL_BY_TIME_RANGE` or `INCREMENTAL_BY_PARTITION` instead. |
| `INCREMENTAL_BY_PARTITION` | INSERT OVERWRITE by partitioning key | Vulcan will overwrite the entire partition based on the partitioning key. This leverages Spark's native partitioning for efficient data management. |
| `FULL` | INSERT OVERWRITE | Vulcan uses Spark's `INSERT OVERWRITE` statement to completely replace the table contents each time. |

**Learn more about materialization strategies:**

- [INCREMENTAL_BY_TIME_RANGE](../../../components/model/model_kinds.md#materialization-strategy)
- [INCREMENTAL_BY_UNIQUE_KEY](../../../components/model/model_kinds.md#materialization-strategy_1)
- [INCREMENTAL_BY_PARTITION](../../../components/model/model_kinds.md#materialization-strategy_3)
- [FULL](../../../components/model/model_kinds.md#materialization-strategy_2)

!!! note
    Spark may not be used for the Vulcan state connection. Use a transactional database like PostgreSQL for the `state_connection`.

!!! warning
    Always use environment variables for sensitive credentials in your Spark configuration (S3 keys, database passwords, etc.).
