# Get Started

This guide helps you create and test Vulcan locally using the **Local Development Kit (LDK)**.

## What is the LDK?

The LDK is a lightweight Docker-based setup that gives you the **Vulcan CLI** on your local machine. Use it to build models, run plans, test queries, and validate your semantic layer — without any cloud deployment.

**What the LDK gives you:**

- **Vulcan CLI** — `vulcan init`, `vulcan plan`, `vulcan run`, and every other command
- **State backend** — choose PostgreSQL (persistent, Docker-based) or DuckDB (lightweight, zero-setup)

No zip downloads. No cloud setup. Pick your engine, choose a state backend, and start building.

---

## Prerequisites

=== "Mac/Linux"

    **1. Verify Docker is installed**

    ```bash
    docker --version
    docker compose version
    ```

    Both commands should return version numbers. Make sure Docker Desktop is running (Docker icon in your menu bar).

    **2. Install Docker (if needed)**

    - **Mac**: [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/){:target="_blank"}
    - **Linux**: [Docker Engine](https://docs.docker.com/engine/install/){:target="_blank"}

    **3. Allocate resources**

    Open Docker Desktop → **Settings → Resources → Advanced** and set RAM to at least **4 GB**.

=== "Windows"

    **1. Verify Docker is installed**

    ```cmd
    docker --version
    docker compose version
    ```

    Both commands should return version numbers. Make sure Docker Desktop is running (Docker icon in your system tray).

    **2. Install Docker (if needed)**

    [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/){:target="_blank"}

    **3. Allocate resources**

    Open Docker Desktop → **Settings → Resources → Advanced** and set RAM to at least **4 GB**.

---

## Setup Vulcan Locally

### Step 1: Create a project folder

=== "Mac/Linux"
    ```bash
    mkdir my-vulcan-project && cd my-vulcan-project
    ```

=== "Windows"
    ```powershell
    mkdir my-vulcan-project
    cd my-vulcan-project
    ```

### Step 2: Create a Docker network

Vulcan runs the CLI as a Docker container. For it to reach other containers (like the statestore), all containers must be on the same Docker network.

=== "Mac/Linux"
    ```bash
    docker network create vulcan
    ```

=== "Windows"
    ```cmd
    docker network create vulcan
    ```

The `vulcan` network is what makes container-to-container communication work. When you run `vulcan plan` or `vulcan run`, the CLI container connects to the statestore container by its name (`statestore`) — this only works if both are on the same network. Without it, the CLI would have no way to reach the state backend.

!!! note
    If you see `network with name vulcan already exists`, that's fine — the network is already there and you can continue.

### Step 3: Set the Vulcan CLI alias

The Vulcan CLI runs as a Docker container. The image you use depends on your engine. Run the command for your engine and OS:

=== "Mac/Linux"

    === "Postgres"
        ```bash
        alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-postgres:0.228.1.19 vulcan"
        ```

    === "Snowflake"
        ```bash
        alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-snowflake:0.228.1.19 vulcan"
        ```

    === "Databricks"
        ```bash
        alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-databricks:0.228.1.19 vulcan"
        ```

    === "Trino"
        ```bash
        alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-trino:0.228.1.19 vulcan"
        ```

    === "Spark"
        ```bash
        alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-spark:0.228.1.19 vulcan"
        ```

        !!! warning "Spark requires a running cluster"
            Unlike other engines, Spark requires a running Spark cluster on your machine or network. The Spark version on your cluster **must match** the version bundled in the image — a mismatch causes `InvalidClassException` serialization errors at runtime. See [Spark prerequisites](../../configurations/engines/spark/spark.md#prerequisites) for details.

        **Local Spark cluster**

        To run Spark locally, save this as `docker-compose.spark.yml` in your project folder and bring it up. It starts the Spark cluster together with the supporting infrastructure — PostgreSQL (state + warehouse), MinIO (object storage), and the Iceberg REST catalog — so every hostname in `config.yaml` resolves correctly. The Spark image version (`3.5.1`) must match the version bundled in the Vulcan Spark image.

        ```bash
        docker compose -f docker-compose.spark.yml up -d
        ```

        ```yaml
        x-images:
          postgres: &postgres_image "postgres:15-alpine"
          minio: &minio_image "minio/minio:latest"
          minio-mc: &minio_mc_image "minio/mc:latest"

        volumes:
          statestore:
          minio-warehouse-data:

        networks:
          vulcan:
            external: true

        services:

          # ── State backend ────────────────────────────────────────────────
          statestore:
            image: *postgres_image
            environment:
              POSTGRES_DB: statestore
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_HOST_AUTH_METHOD: trust
            ports:
              - "5431:5432"
            volumes:
              - statestore:/var/lib/postgresql/data
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U vulcan -d statestore"]
              interval: 5s
              timeout: 5s
              retries: 5
            networks:
              - vulcan

          # ── Warehouse (PostgreSQL — available as a JDBC Spark catalog) ───
          warehouse:
            image: postgres:15
            container_name: warehouse
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: warehouse
            ports:
              - "5432:5432"
            networks:
              - vulcan

          # ── Object storage (MinIO) ───────────────────────────────────────
          minio-warehouse:
            image: *minio_image
            command: server /data --console-address ":9001"
            environment:
              MINIO_ROOT_USER: admin
              MINIO_ROOT_PASSWORD: password
              MINIO_DOMAIN: minio-warehouse
            ports:
              - "9000:9000"
              - "9001:9001"
            volumes:
              - minio-warehouse-data:/data
            healthcheck:
              test: ["CMD", "mc", "ready", "local"]
              interval: 5s
              timeout: 5s
              retries: 5
            networks:
              - vulcan

          minio-warehouse-init:
            image: *minio_mc_image
            depends_on:
              minio-warehouse:
                condition: service_healthy
            entrypoint: >
              /bin/sh -c "
              /usr/bin/mc alias set minio-warehouse http://minio-warehouse:9000 admin password;
              /usr/bin/mc mb minio-warehouse/warehouse --ignore-existing;
              /usr/bin/mc anonymous set download minio-warehouse/warehouse;
              exit 0;
              "
            networks:
              - vulcan

          # ── Iceberg REST catalog ─────────────────────────────────────────
          iceberg-rest-warehouse:
            image: tabulario/iceberg-rest:latest
            environment:
              CATALOG_WAREHOUSE: s3://warehouse/
              CATALOG_IO__IMPL: org.apache.iceberg.aws.s3.S3FileIO
              CATALOG_S3_ENDPOINT: http://minio-warehouse:9000
              CATALOG_S3_ACCESS__KEY__ID: admin
              CATALOG_S3_SECRET__ACCESS__KEY: password
              CATALOG_S3_PATH__STYLE__ACCESS: "true"
              AWS_REGION: us-east-1
              AWS_DEFAULT_REGION: us-east-1
            ports:
              - "8181:8181"
            depends_on:
              - minio-warehouse
            networks:
              vulcan:
                aliases:
                  - iceberg-rest.minio-warehouse

          # ── Spark cluster ────────────────────────────────────────────────
          spark-master:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-master
            command: /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master
            environment:
              SPARK_MASTER_HOST: spark-master
              SPARK_MASTER_PORT: 7077
              SPARK_MASTER_WEBUI_PORT: 8080
            ports:
              - "7077:7077"
              - "8080:8080"
            networks:
              - vulcan

          spark-worker-1:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-worker-1
            depends_on:
              - spark-master
            environment:
              SPARK_WORKER_CORES: 4
              SPARK_WORKER_MEMORY: 2g
            command: >
              /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker
              spark://spark-master:7077
            networks:
              - vulcan

          spark-worker-2:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-worker-2
            depends_on:
              - spark-master
            environment:
              SPARK_WORKER_CORES: 4
              SPARK_WORKER_MEMORY: 2g
            command: >
              /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker
              spark://spark-master:7077
            networks:
              - vulcan
        ```

        **Vulcan config for Spark**

        Choose the example that matches your setup:

        ??? note "Local setup — Docker Spark cluster + Iceberg over MinIO"

            ```yaml
            gateways:
              default:
                connection:
                  type: spark
                  config:
                    "spark.master": "spark://spark-master:7077"
                    "spark.app.name": "vulcan"
                    "spark.driver.extraJavaOptions": "-Daws.region=us-east-1 -Djava.io.tmpdir=/tmp/iceberg"
                    "spark.executor.extraJavaOptions": "-Daws.region=us-east-1 -Djava.io.tmpdir=/tmp/iceberg"
                    # JARs are baked into the Vulcan Spark image — no Ivy downloads at plan/run time
                    "spark.executor.extraClassPath": "{{ env_var('VULCAN_SPARK_EXECUTOR_EXTRA_JARS_DIR', '/etc/dataos/work/jars') }}/*"
                    # Iceberg catalog over MinIO
                    "spark.sql.catalog.warehouse": "org.apache.iceberg.spark.SparkCatalog"
                    "spark.sql.catalog.warehouse.type": "rest"
                    "spark.sql.catalog.warehouse.uri": "http://iceberg-rest-warehouse:8181"
                    "spark.sql.catalog.warehouse.warehouse": "s3://warehouse/"
                    "spark.sql.catalog.warehouse.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
                    "spark.sql.catalog.warehouse.s3.endpoint": "http://minio-warehouse:9000"
                    "spark.sql.catalog.warehouse.s3.path-style-access": "true"
                    "spark.sql.catalog.warehouse.s3.access-key-id": "admin"
                    "spark.sql.catalog.warehouse.s3.secret-access-key": "password"
                    "spark.sql.catalog.warehouse.client.region": "us-east-1"
                    # S3/MinIO credentials
                    "spark.hadoop.fs.s3a.access.key": "admin"
                    "spark.hadoop.fs.s3a.secret.key": "password"
                    "spark.hadoop.fs.s3a.endpoint": "http://minio-warehouse:9000"
                    "spark.hadoop.fs.s3a.path.style.access": "true"
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
                    # Iceberg extensions
                    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
                    # Dynamic allocation
                    "spark.dynamicAllocation.enabled": "true"
                    "spark.dynamicAllocation.shuffleTracking.enabled": "true"
                    "spark.dynamicAllocation.initialExecutors": "1"
                    "spark.dynamicAllocation.minExecutors": "1"
                    "spark.dynamicAllocation.maxExecutors": "2"
                state_connection:
                  type: postgres
                  host: statestore
                  port: 5432
                  database: statestore
                  user: vulcan
                  password: vulcan

            default_gateway: default

            model_defaults:
              dialect: spark2
            ```

        ??? note "Existing lakehouse depot"

            ```yaml
            name: spark
            tenant: ct-sandbox

            model_defaults:
              dialect: spark2
              cron: '*/5 * * * *'

            linter:
              enabled: false

            gateways:
              default:
                connection:
                  type: spark
                  config:
                    "spark.master": "{{ env_var('SPARK_MASTER_URL') }}"
                    "spark.app.name": "{{ env_var('SPARK_APP_NAME') }}"
                    "spark.driver.extraJavaOptions": "-Daws.region={{ env_var('AWS_REGION') }} -Djava.io.tmpdir=/tmp/iceberg"
                    "spark.executor.extraJavaOptions": "-Daws.region={{ env_var('AWS_REGION') }} -Djava.io.tmpdir=/tmp/iceberg"
                    # Download Iceberg + AWS + PostgreSQL JDBC dependencies
                    "spark.jars.packages": "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.5.2,org.apache.iceberg:iceberg-aws-bundle:1.5.2,org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262,org.postgresql:postgresql:42.7.1"
                    "spark.jars.ivy": "/tmp/.ivy2"
                    # S3 credentials
                    "spark.hadoop.fs.s3a.access.key": "{{ env_var('MINIO_WAREHOUSE_ACCESS_KEY') }}"
                    "spark.hadoop.fs.s3a.secret.key": "{{ env_var('MINIO_WAREHOUSE_SECRET_KEY') }}"
                    "spark.hadoop.fs.s3a.endpoint": "{{ env_var('MINIO_WAREHOUSE_ENDPOINT') }}"
                    "spark.hadoop.fs.s3a.path.style.access": "true"
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
                    # Iceberg extensions
                    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
                    # Default catalog
                    "spark.sql.defaultCatalog": "s3depot"
                    # Iceberg catalog via lakehouse depot
                    "spark.sql.catalog.s3depot": "org.apache.iceberg.spark.SparkCatalog"
                    "spark.sql.catalog.s3depot.type": "rest"
                    "spark.sql.catalog.s3depot.uri": "{{ env_var('ICEBERG_DEPOT_URI') }}"
                    "spark.sql.catalog.s3depot.header.apikey": "{{ env_var('DEPOT_API_KEY') }}"
                    "spark.sql.catalog.s3depot.warehouse": "{{ env_var('DEPOT_WAREHOUSE_PATH') }}"
                    "spark.sql.catalog.s3depot.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
                    "spark.sql.catalog.s3depot.s3.path-style-access": "true"
                    "spark.sql.catalog.s3depot.s3.access-key-id": "{{ env_var('DEPOT_ACCESS_KEY') }}"
                    "spark.sql.catalog.s3depot.s3.secret-access-key": "{{ env_var('DEPOT_SECRET_KEY') }}"
                    "spark.sql.catalog.s3depot.client.region": "{{ env_var('AWS_REGION') }}"
                    # Dynamic allocation
                    "spark.dynamicAllocation.enabled": "true"
                    "spark.dynamicAllocation.shuffleTracking.enabled": "true"
                    "spark.dynamicAllocation.initialExecutors": "1"
                    "spark.dynamicAllocation.minExecutors": "1"
                    "spark.dynamicAllocation.maxExecutors": "2"
                state_connection:
                  type: postgres
                  database: "{{ env_var('STATESTORE_DATABASE') }}"
                  host: "{{ env_var('STATESTORE_HOST') }}"
                  port: "{{ env_var('STATESTORE_PORT') }}"
                  user: "{{ env_var('STATESTORE_USER') }}"
                  password: "{{ env_var('STATESTORE_PASSWORD') }}"
                state_schema: spark

            default_gateway: default
            ```

    !!! tip "Make the alias permanent"
        Add the alias line to `~/.zshrc` (Zsh) or `~/.bashrc` (Bash), then run `source ~/.zshrc` to reload without restarting your terminal.

=== "Windows"

    === "Postgres"
        ```powershell
        function vulcan { docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-postgres:0.228.1.19 vulcan $args }
        ```

    === "Snowflake"
        ```powershell
        function vulcan { docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-snowflake:0.228.1.19 vulcan $args }
        ```

    === "Databricks"
        ```powershell
        function vulcan { docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-databricks:0.228.1.19 vulcan $args }
        ```

    === "Trino"
        ```powershell
        function vulcan { docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-trino:0.228.1.19 vulcan $args }
        ```

    === "Spark"
        ```powershell
        function vulcan { docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-spark:0.228.1.19 vulcan $args }
        ```

        !!! warning "Spark requires a running cluster"
            Unlike other engines, Spark requires a running Spark cluster on your machine or network. The Spark version on your cluster **must match** the version bundled in the image — a mismatch causes `InvalidClassException` serialization errors at runtime. See [Spark prerequisites](../../configurations/engines/spark/spark.md#prerequisites) for details.

        **Local Spark cluster**

        To run Spark locally, save this as `docker-compose.spark.yml` in your project folder and bring it up. It starts the Spark cluster together with the supporting infrastructure — PostgreSQL (state + warehouse), MinIO (object storage), and the Iceberg REST catalog — so every hostname in `config.yaml` resolves correctly. The Spark image version (`3.5.1`) must match the version bundled in the Vulcan Spark image.

        ```cmd
        docker compose -f docker-compose.spark.yml up -d
        ```

        ```yaml
        x-images:
          postgres: &postgres_image "postgres:15-alpine"
          minio: &minio_image "minio/minio:latest"
          minio-mc: &minio_mc_image "minio/mc:latest"

        volumes:
          statestore:
          minio-warehouse-data:

        networks:
          vulcan:
            external: true

        services:

          # ── State backend ────────────────────────────────────────────────
          statestore:
            image: *postgres_image
            environment:
              POSTGRES_DB: statestore
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_HOST_AUTH_METHOD: trust
            ports:
              - "5431:5432"
            volumes:
              - statestore:/var/lib/postgresql/data
            healthcheck:
              test: ["CMD-SHELL", "pg_isready -U vulcan -d statestore"]
              interval: 5s
              timeout: 5s
              retries: 5
            networks:
              - vulcan

          # ── Warehouse (PostgreSQL — available as a JDBC Spark catalog) ───
          warehouse:
            image: postgres:15
            container_name: warehouse
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: warehouse
            ports:
              - "5432:5432"
            networks:
              - vulcan

          # ── Object storage (MinIO) ───────────────────────────────────────
          minio-warehouse:
            image: *minio_image
            command: server /data --console-address ":9001"
            environment:
              MINIO_ROOT_USER: admin
              MINIO_ROOT_PASSWORD: password
              MINIO_DOMAIN: minio-warehouse
            ports:
              - "9000:9000"
              - "9001:9001"
            volumes:
              - minio-warehouse-data:/data
            healthcheck:
              test: ["CMD", "mc", "ready", "local"]
              interval: 5s
              timeout: 5s
              retries: 5
            networks:
              - vulcan

          minio-warehouse-init:
            image: *minio_mc_image
            depends_on:
              minio-warehouse:
                condition: service_healthy
            entrypoint: >
              /bin/sh -c "
              /usr/bin/mc alias set minio-warehouse http://minio-warehouse:9000 admin password;
              /usr/bin/mc mb minio-warehouse/warehouse --ignore-existing;
              /usr/bin/mc anonymous set download minio-warehouse/warehouse;
              exit 0;
              "
            networks:
              - vulcan

          # ── Iceberg REST catalog ─────────────────────────────────────────
          iceberg-rest-warehouse:
            image: tabulario/iceberg-rest:latest
            environment:
              CATALOG_WAREHOUSE: s3://warehouse/
              CATALOG_IO__IMPL: org.apache.iceberg.aws.s3.S3FileIO
              CATALOG_S3_ENDPOINT: http://minio-warehouse:9000
              CATALOG_S3_ACCESS__KEY__ID: admin
              CATALOG_S3_SECRET__ACCESS__KEY: password
              CATALOG_S3_PATH__STYLE__ACCESS: "true"
              AWS_REGION: us-east-1
              AWS_DEFAULT_REGION: us-east-1
            ports:
              - "8181:8181"
            depends_on:
              - minio-warehouse
            networks:
              vulcan:
                aliases:
                  - iceberg-rest.minio-warehouse

          # ── Spark cluster ────────────────────────────────────────────────
          spark-master:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-master
            command: /opt/spark/bin/spark-class org.apache.spark.deploy.master.Master
            environment:
              SPARK_MASTER_HOST: spark-master
              SPARK_MASTER_PORT: 7077
              SPARK_MASTER_WEBUI_PORT: 8080
            ports:
              - "7077:7077"
              - "8080:8080"
            networks:
              - vulcan

          spark-worker-1:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-worker-1
            depends_on:
              - spark-master
            environment:
              SPARK_WORKER_CORES: 4
              SPARK_WORKER_MEMORY: 2g
            command: >
              /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker
              spark://spark-master:7077
            networks:
              - vulcan

          spark-worker-2:
            image: spark:3.5.1-scala2.12-java17-python3-ubuntu
            container_name: spark-worker-2
            depends_on:
              - spark-master
            environment:
              SPARK_WORKER_CORES: 4
              SPARK_WORKER_MEMORY: 2g
            command: >
              /opt/spark/bin/spark-class org.apache.spark.deploy.worker.Worker
              spark://spark-master:7077
            networks:
              - vulcan
        ```

        **Vulcan config for Spark**

        Choose the example that matches your setup:

        ??? note "Local setup — Docker Spark cluster + Iceberg over MinIO"

            ```yaml
            gateways:
              default:
                connection:
                  type: spark
                  config:
                    "spark.master": "spark://spark-master:7077"
                    "spark.app.name": "vulcan"
                    "spark.driver.extraJavaOptions": "-Daws.region=us-east-1 -Djava.io.tmpdir=/tmp/iceberg"
                    "spark.executor.extraJavaOptions": "-Daws.region=us-east-1 -Djava.io.tmpdir=/tmp/iceberg"
                    # JARs are baked into the Vulcan Spark image — no Ivy downloads at plan/run time
                    "spark.executor.extraClassPath": "{{ env_var('VULCAN_SPARK_EXECUTOR_EXTRA_JARS_DIR', '/etc/dataos/work/jars') }}/*"
                    # Iceberg catalog over MinIO
                    "spark.sql.catalog.warehouse": "org.apache.iceberg.spark.SparkCatalog"
                    "spark.sql.catalog.warehouse.type": "rest"
                    "spark.sql.catalog.warehouse.uri": "http://iceberg-rest-warehouse:8181"
                    "spark.sql.catalog.warehouse.warehouse": "s3://warehouse/"
                    "spark.sql.catalog.warehouse.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
                    "spark.sql.catalog.warehouse.s3.endpoint": "http://minio-warehouse:9000"
                    "spark.sql.catalog.warehouse.s3.path-style-access": "true"
                    "spark.sql.catalog.warehouse.s3.access-key-id": "admin"
                    "spark.sql.catalog.warehouse.s3.secret-access-key": "password"
                    "spark.sql.catalog.warehouse.client.region": "us-east-1"
                    # S3/MinIO credentials
                    "spark.hadoop.fs.s3a.access.key": "admin"
                    "spark.hadoop.fs.s3a.secret.key": "password"
                    "spark.hadoop.fs.s3a.endpoint": "http://minio-warehouse:9000"
                    "spark.hadoop.fs.s3a.path.style.access": "true"
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
                    # Iceberg extensions
                    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
                    # Dynamic allocation
                    "spark.dynamicAllocation.enabled": "true"
                    "spark.dynamicAllocation.shuffleTracking.enabled": "true"
                    "spark.dynamicAllocation.initialExecutors": "1"
                    "spark.dynamicAllocation.minExecutors": "1"
                    "spark.dynamicAllocation.maxExecutors": "2"
                state_connection:
                  type: postgres
                  host: statestore
                  port: 5432
                  database: statestore
                  user: vulcan
                  password: vulcan

            default_gateway: default

            model_defaults:
              dialect: spark2
            ```

        ??? note "Existing lakehouse depot"

            ```yaml
            name: spark
            tenant: ct-sandbox

            model_defaults:
              dialect: spark2
              cron: '*/5 * * * *'

            linter:
              enabled: false

            gateways:
              default:
                connection:
                  type: spark
                  config:
                    "spark.master": "{{ env_var('SPARK_MASTER_URL') }}"
                    "spark.app.name": "{{ env_var('SPARK_APP_NAME') }}"
                    "spark.driver.extraJavaOptions": "-Daws.region={{ env_var('AWS_REGION') }} -Djava.io.tmpdir=/tmp/iceberg"
                    "spark.executor.extraJavaOptions": "-Daws.region={{ env_var('AWS_REGION') }} -Djava.io.tmpdir=/tmp/iceberg"
                    # Download Iceberg + AWS + PostgreSQL JDBC dependencies
                    "spark.jars.packages": "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.5.2,org.apache.iceberg:iceberg-aws-bundle:1.5.2,org.apache.hadoop:hadoop-aws:3.3.4,com.amazonaws:aws-java-sdk-bundle:1.12.262,org.postgresql:postgresql:42.7.1"
                    "spark.jars.ivy": "/tmp/.ivy2"
                    # S3 credentials
                    "spark.hadoop.fs.s3a.access.key": "{{ env_var('MINIO_WAREHOUSE_ACCESS_KEY') }}"
                    "spark.hadoop.fs.s3a.secret.key": "{{ env_var('MINIO_WAREHOUSE_SECRET_KEY') }}"
                    "spark.hadoop.fs.s3a.endpoint": "{{ env_var('MINIO_WAREHOUSE_ENDPOINT') }}"
                    "spark.hadoop.fs.s3a.path.style.access": "true"
                    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
                    # Iceberg extensions
                    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
                    # Default catalog
                    "spark.sql.defaultCatalog": "s3depot"
                    # Iceberg catalog via lakehouse depot
                    "spark.sql.catalog.s3depot": "org.apache.iceberg.spark.SparkCatalog"
                    "spark.sql.catalog.s3depot.type": "rest"
                    "spark.sql.catalog.s3depot.uri": "{{ env_var('ICEBERG_DEPOT_URI') }}"
                    "spark.sql.catalog.s3depot.header.apikey": "{{ env_var('DEPOT_API_KEY') }}"
                    "spark.sql.catalog.s3depot.warehouse": "{{ env_var('DEPOT_WAREHOUSE_PATH') }}"
                    "spark.sql.catalog.s3depot.io-impl": "org.apache.iceberg.aws.s3.S3FileIO"
                    "spark.sql.catalog.s3depot.s3.path-style-access": "true"
                    "spark.sql.catalog.s3depot.s3.access-key-id": "{{ env_var('DEPOT_ACCESS_KEY') }}"
                    "spark.sql.catalog.s3depot.s3.secret-access-key": "{{ env_var('DEPOT_SECRET_KEY') }}"
                    "spark.sql.catalog.s3depot.client.region": "{{ env_var('AWS_REGION') }}"
                    # Dynamic allocation
                    "spark.dynamicAllocation.enabled": "true"
                    "spark.dynamicAllocation.shuffleTracking.enabled": "true"
                    "spark.dynamicAllocation.initialExecutors": "1"
                    "spark.dynamicAllocation.minExecutors": "1"
                    "spark.dynamicAllocation.maxExecutors": "2"
                state_connection:
                  type: postgres
                  database: "{{ env_var('STATESTORE_DATABASE') }}"
                  host: "{{ env_var('STATESTORE_HOST') }}"
                  port: "{{ env_var('STATESTORE_PORT') }}"
                  user: "{{ env_var('STATESTORE_USER') }}"
                  password: "{{ env_var('STATESTORE_PASSWORD') }}"
                state_schema: spark

            default_gateway: default
            ```

    !!! tip "Make the function permanent"
        Run `notepad $PROFILE` to open your PowerShell profile, paste the function, and save.

### Step 4: Initialize your project

=== "Mac/Linux"
    ```bash
    vulcan init
    ```

=== "Windows"
    ```cmd
    vulcan init
    ```

When prompted, choose `DEFAULT` as the project type and select your engine.

This creates the standard project structure:

| Directory | Purpose |
|-----------|---------|
| `models/` | SQL and Python model files |
| `seeds/` | Static CSV data files |
| `audits/` | Quality assertions that block execution on failure |
| `checks/` | Quality monitors (non-blocking) |
| `tests/` | Model logic validation |
| `macros/` | Reusable SQL snippets |
| `semantics/` | Semantic layer definitions (measures, dimensions) |

### Step 5: Configure your connection

Open `config.yaml` in your project root and add your engine connection and state backend. Pick the tab that matches your engine:

=== "Postgres"
    ```yaml
    gateways:
      default:
        connection:
          type: postgres
          host: warehouse
          port: 5432
          database: warehouse
          user: vulcan
          password: vulcan
        state_connection:
          type: duckdb
          database: /workspace/.state/vulcan.db
    ```

    ??? note "Using PostgreSQL as state backend instead"

        First, create and start a `docker-compose.infra.yml` with the statestore:

        ```yaml
        networks:
          vulcan:
            driver: bridge

        services:
          statestore:
            image: postgres:15
            container_name: statestore
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: statestore
            ports:
              - "5433:5432"
            networks:
              - vulcan
        ```

        === "Mac/Linux"
            ```bash
            docker compose -f docker-compose.infra.yml up -d
            ```
        === "Windows"
            ```cmd
            docker compose -f docker-compose.infra.yml up -d
            ```

        Then set this in `config.yaml`:

        ```yaml
        state_connection:
          type: postgres
          host: statestore
          port: 5432
          database: statestore
          user: vulcan
          password: vulcan
        ```

    [:material-book-open-variant: Full Postgres reference](../../configurations/engines/postgres/postgres.md)

=== "Snowflake"
    ```yaml
    gateways:
      default:
        connection:
          type: snowflake
          account: your_account
          user: your_user
          password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
          warehouse: your_warehouse
          database: your_database
        state_connection:
          type: duckdb
          database: /workspace/.state/vulcan.db
    ```

    ??? note "Using PostgreSQL as state backend instead"

        First, create and start a `docker-compose.infra.yml` with the statestore:

        ```yaml
        networks:
          vulcan:
            driver: bridge

        services:
          statestore:
            image: postgres:15
            container_name: statestore
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: statestore
            ports:
              - "5433:5432"
            networks:
              - vulcan
        ```

        === "Mac/Linux"
            ```bash
            docker compose -f docker-compose.infra.yml up -d
            ```
        === "Windows"
            ```cmd
            docker compose -f docker-compose.infra.yml up -d
            ```

        Then set this in `config.yaml`:

        ```yaml
        state_connection:
          type: postgres
          host: statestore
          port: 5432
          database: statestore
          user: vulcan
          password: vulcan
        ```

    [:material-book-open-variant: Full Snowflake reference](../../configurations/engines/snowflake/snowflake.md)

=== "Databricks"
    ```yaml
    gateways:
      default:
        connection:
          type: databricks
          server_hostname: your-workspace.azuredatabricks.net
          http_path: /sql/1.0/warehouses/your_warehouse_id
          access_token: "{{ env_var('DATABRICKS_TOKEN') }}"
          catalog: your_catalog
        state_connection:
          type: duckdb
          database: /workspace/.state/vulcan.db
    ```

    ??? note "Using PostgreSQL as state backend instead"

        First, create and start a `docker-compose.infra.yml` with the statestore:

        ```yaml
        networks:
          vulcan:
            driver: bridge

        services:
          statestore:
            image: postgres:15
            container_name: statestore
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: statestore
            ports:
              - "5433:5432"
            networks:
              - vulcan
        ```

        === "Mac/Linux"
            ```bash
            docker compose -f docker-compose.infra.yml up -d
            ```
        === "Windows"
            ```cmd
            docker compose -f docker-compose.infra.yml up -d
            ```

        Then set this in `config.yaml`:

        ```yaml
        state_connection:
          type: postgres
          host: statestore
          port: 5432
          database: statestore
          user: vulcan
          password: vulcan
        ```

    [:material-book-open-variant: Full Databricks reference](../../configurations/engines/databricks/databricks.md)

=== "Trino"
    ```yaml
    gateways:
      default:
        connection:
          type: trino
          host: your_trino_host
          port: 8080
          user: your_user
          catalog: your_catalog
        state_connection:
          type: duckdb
          database: /workspace/.state/vulcan.db
    ```

    ??? note "Using PostgreSQL as state backend instead"

        First, create and start a `docker-compose.infra.yml` with the statestore:

        ```yaml
        networks:
          vulcan:
            driver: bridge

        services:
          statestore:
            image: postgres:15
            container_name: statestore
            environment:
              POSTGRES_USER: vulcan
              POSTGRES_PASSWORD: vulcan
              POSTGRES_DB: statestore
            ports:
              - "5433:5432"
            networks:
              - vulcan
        ```

        === "Mac/Linux"
            ```bash
            docker compose -f docker-compose.infra.yml up -d
            ```
        === "Windows"
            ```cmd
            docker compose -f docker-compose.infra.yml up -d
            ```

        Then set this in `config.yaml`:

        ```yaml
        state_connection:
          type: postgres
          host: statestore
          port: 5432
          database: statestore
          user: vulcan
          password: vulcan
        ```

    [:material-book-open-variant: Full Trino reference](../../configurations/engines/trino/trino.md)

=== "Spark"
    ```yaml
    gateways:
      default:
        connection:
          type: spark
          config:
            "spark.master": "spark://spark-master:7077"
            "spark.app.name": "vulcan"
            # ... see Step 3 for the full spark.* config
        state_connection:
          type: postgres
          host: statestore
          port: 5432
          database: statestore
          user: vulcan
          password: vulcan
    ```

    [:material-book-open-variant: Full Spark reference](../../configurations/engines/spark/spark.md)

Add the required top-level keys at the bottom of `config.yaml`:

```yaml
default_gateway: default

model_defaults:
  dialect: postgres  # change to match your engine: snowflake, databricks, trino, spark2
```

### Step 6: Verify your setup

=== "Mac/Linux"
    ```bash
    vulcan info
    ```

=== "Windows"
    ```cmd
    vulcan info
    ```

This shows your connection status, model count, and project configuration. Fix any errors before proceeding.

### Step 7: Run your first plan

=== "Mac/Linux"
    ```bash
    vulcan plan
    ```

=== "Windows"
    ```cmd
    vulcan plan
    ```

Vulcan validates your models, computes what needs to be materialized, and prompts you to apply. Enter `y` to confirm.

For a full walkthrough of what happens after `plan` — running models, querying data, and iterating — see the [Plan guide](../plan_guide.md).

---

## Troubleshooting

??? note "Common issues and solutions"

    **Statestore container won't start**

    Only relevant if you're using PostgreSQL state. Ensure Docker Desktop is running and has at least 4 GB RAM allocated. Check under **Settings → Resources → Advanced**.

    **Invalid connection config**

    If `vulcan info` or any command shows:

    ```
    Error: Invalid 'postgres' connection config:
      Field 'host': Input should be a valid string
    ```

    Your `config.yaml` is missing or incomplete. Run `vulcan init` if you haven't already, or verify the `gateways` section is present with all required connection fields.

    **Network error: `vulcan` network not found**

    The Docker network may not exist. Check:

    === "Mac/Linux"
        ```bash
        docker network ls | grep vulcan
        ```
        If missing, create it:
        ```bash
        docker network create vulcan
        ```
    === "Windows"
        ```cmd
        docker network ls | findstr vulcan
        ```
        If missing:
        ```cmd
        docker network create vulcan
        ```

    **Port already in use**

    If a port is occupied by another process, either stop that process or update the port mapping in `docker-compose.infra.yml`.

    | Service | Default port |
    |---------|-------------|
    | Statestore (Postgres, if used) | 5433 |
    | Warehouse (Postgres engine only) | 5432 |

    **Permission denied**

    ```bash
    chmod -R a+w .
    ```

    **Spark: `InvalidClassException` at runtime**

    The Spark version on your cluster doesn't match the version bundled in the Vulcan image. Check your cluster version:

    ```bash
    spark-submit --version
    ```

    Then use a Vulcan Spark image built against the same Spark version. See [Spark prerequisites](../../configurations/engines/spark/spark.md#prerequisites).

---

## Next Steps

- [Data Product Lifecycle](../data-product-lifecycle.md) — the full path from local setup to production deployment
- [CLI Reference](../../cli-commands/cli.md) — all available commands and options
- [Model Kinds](../../components/model/model_kinds.md) — FULL, INCREMENTAL, VIEW, and more
- [Vulcan API Guide](../vulcan_api_guide.md) — query your semantic layer via REST, GraphQL, or MySQL wire protocol
