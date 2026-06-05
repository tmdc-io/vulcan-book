# Set Up Spark Locally

This guide shows how to run Vulcan locally against a Docker-based Spark lakehouse. Vulcan runs from your laptop in a Python 3.10 virtual environment. Docker runs the supporting services: Spark master, Spark worker, MinIO, and an Iceberg REST catalog.

Use this setup when you want a local Spark development environment without installing a full Spark cluster directly on your machine.

## Prerequisites

### Python 3.10

Install Vulcan locally in a Python 3.10 virtual environment.

=== "Mac/Linux"
    ```bash
    python3.10 --version
    python3.10 -m venv .venv
    source .venv/bin/activate
    python -m pip install --upgrade pip setuptools wheel
    pip install "./vulcan-0.228.1.24b1-py3-none-any.whl[spark,postgres]"
    ```

=== "Windows"
    ```powershell
    py -3.10 --version
    py -3.10 -m venv .venv
    .venv\Scripts\activate
    py -3.10 -m pip install --upgrade pip setuptools wheel
    pip install "./vulcan-0.228.1.24b1-py3-none-any.whl[spark,postgres]"
    ```

### Java 17 SDK

The Spark driver runs from your local Vulcan process, so Java must be installed on your laptop and available on your shell `PATH`.

```bash
java -version
```

The output should show Java 17. If it does not, install a Java 17 SDK and reopen your terminal so `JAVA_HOME` and `PATH` are updated.

### Docker

Docker runs the local Spark and lakehouse services.

```bash
docker --version
docker compose version
```

## Create the Docker Compose File

Save this as `docker/docker-compose.spark.yml`:

```yaml
services:
  # Spark standalone cluster for running Spark executors in containers.
  spark-master:
    image: tmdcio/vulcan-spark-base:0.228.1.21
    container_name: spark-seeds-minimal-spark-master
    restart: unless-stopped
    command: ["/bin/bash", "-lc", "/opt/spark/sbin/start-master.sh --host 0.0.0.0 --port 7077 --webui-port 8080 && tail -f /opt/spark/logs/*"]
    ports:
      - "7077:7077"
      - "8080:8080"
    networks:
      - spark-seeds-minimal-net

  spark-worker:
    image: tmdcio/vulcan-spark-base:0.228.1.21
    container_name: spark-seeds-minimal-spark-worker
    restart: unless-stopped
    command: ["/bin/bash", "-lc", "/opt/spark/sbin/start-worker.sh spark://spark-master:7077 --webui-port 8081 && tail -f /opt/spark/logs/*"]
    depends_on:
      - spark-master
    ports:
      - "8081:8081"
    networks:
      - spark-seeds-minimal-net

  # MinIO for S3-compatible storage.
  minio:
    image: minio/minio:latest
    container_name: spark-seeds-minimal-minio
    restart: unless-stopped
    environment:
      - MINIO_ROOT_USER=admin
      - MINIO_ROOT_PASSWORD=password
      - MINIO_DOMAIN=minio
    ports:
      - "9000:9000"
      - "9001:9001"
    networks:
      spark-seeds-minimal-net:
        aliases:
          - minio
          - warehouse.minio
    volumes:
      - minio_data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 5s
      timeout: 5s
      retries: 10

  # MinIO setup - creates warehouse bucket.
  mc:
    image: minio/mc:latest
    container_name: spark-seeds-minimal-mc
    networks:
      - spark-seeds-minimal-net
    depends_on:
      minio:
        condition: service_healthy
    entrypoint: >
      /bin/sh -c "
        mc alias set minio http://minio:9000 admin password;
        mc mb --ignore-existing minio/warehouse;
        mc anonymous set public minio/warehouse;
        exit 0;
      "

  # Iceberg REST Catalog.
  iceberg-rest:
    image: tabulario/iceberg-rest:latest
    container_name: spark-seeds-minimal-iceberg-rest
    restart: unless-stopped
    ports:
      - "8181:8181"
    networks:
      - spark-seeds-minimal-net
    environment:
      - AWS_ACCESS_KEY_ID=admin
      - AWS_SECRET_ACCESS_KEY=password
      - AWS_REGION=us-east-1
      - CATALOG_WAREHOUSE=s3://warehouse/
      - CATALOG_IO__IMPL=org.apache.iceberg.aws.s3.S3FileIO
      - CATALOG_S3_ENDPOINT=http://minio:9000
    depends_on:
      minio:
        condition: service_healthy

networks:
  spark-seeds-minimal-net:
    driver: bridge

volumes:
  minio_data:
```

## Start the Services

```bash
docker compose -f docker/docker-compose.spark.yml up -d
```

Check the service UIs:

- Spark master: `http://localhost:8080`
- Spark worker: `http://localhost:8081`
- MinIO console: `http://localhost:9001`
- Iceberg REST catalog: `http://localhost:8181`

## Configure Vulcan

Use this connection in `config.yaml`:

```yaml
gateways:
  default:
    connection:
      type: spark
      config:
        spark.master: spark://localhost:7077
        spark.app.name: vulcan
        spark.sql.catalog.local: org.apache.iceberg.spark.SparkCatalog
        spark.sql.catalog.local.type: rest
        spark.sql.catalog.local.uri: http://localhost:8181
        spark.sql.catalog.local.warehouse: s3://warehouse/
        spark.sql.catalog.local.io-impl: org.apache.iceberg.aws.s3.S3FileIO
        spark.sql.catalog.local.s3.endpoint: http://localhost:9000
        spark.sql.catalog.local.s3.path-style-access: "true"
        spark.hadoop.fs.s3a.access.key: admin
        spark.hadoop.fs.s3a.secret.key: password
        spark.hadoop.fs.s3a.endpoint: http://localhost:9000
        spark.hadoop.fs.s3a.path.style.access: "true"
    state_connection:
      type: duckdb
      database: ./.state/vulcan.db

default_gateway: default

model_defaults:
  dialect: spark2
```

## Verify Vulcan

Run Vulcan from your activated Python environment:

```bash
vulcan --version
vulcan plan
```

## Stop the Services

```bash
docker compose -f docker/docker-compose.spark.yml down
```

To remove the MinIO volume as well:

```bash
docker compose -f docker/docker-compose.spark.yml down -v
```

## Troubleshooting

If Vulcan cannot start Spark, check that Java 17 is available in the same terminal where you run Vulcan:

```bash
java -version
echo "$JAVA_HOME"
```

If Vulcan cannot connect to Spark, confirm the Docker services are running and the Spark master is listening on `localhost:7077`:

```bash
docker compose -f docker/docker-compose.spark.yml ps
```

If Spark cannot read or write Iceberg tables, confirm MinIO and the Iceberg REST catalog are healthy:

```bash
docker compose -f docker/docker-compose.spark.yml logs minio iceberg-rest
```
