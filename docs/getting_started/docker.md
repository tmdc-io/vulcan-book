# Docker Quickstart

In this quickstart, you'll use Docker to get up and running with Vulcan. This approach uses Docker Compose to set up all the necessary infrastructure and services, making it the fastest way to start working with Vulcan.

Before beginning, ensure that you meet all the [prerequisites](./prerequisites.md) for using Vulcan.

## Overview

This quickstart will guide you through:

1. Setting up the Docker infrastructure (network, statestore, object storage, warehouse)
2. Accessing Vulcan through a Docker shell
3. Creating your first Vulcan project
4. Running your first plan

The setup uses three separate Docker Compose files for better service management:
- **Infrastructure** (`docker-compose.infra.yml`): Statestore and object storage
- **Warehouse** (`docker-compose.warehouse.yml`): Your data warehouse
- **Vulcan** (`docker-compose.vulcan.yml`): Vulcan services and shell

All services communicate through a shared external Docker network.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose (included with Docker Desktop)
- At least 4GB of available RAM
- A terminal/command line interface

## Step 1: Create Your Project Directory

Create a directory for your Vulcan project:

```bash
mkdir vulcan-project
cd vulcan-project
```

## Step 2: Create Docker Compose Files

Create a `docker` directory and add the following Docker Compose files:

### Infrastructure Services

Create `docker/docker-compose.infra.yml`:

```yaml
x-images:
  postgres: &postgres_image "postgres:15-alpine"
  minio: &minio_image "minio/minio:latest"
  minio-mc: &minio_mc_image "minio/mc:latest"

volumes:
  objeststore:
    driver: local
  statestore:
    driver: local

networks:
  vulcan:
    external: true

services:
  #########################################################################
  # Vulcan infrastructure services                                        #
  #                                                                       #
  # The services below (statestore, object store, etc.) are part of the   #
  # shared Vulcan runtime and are not specific to the b2b_saas project.   #
  #                                                                       #
  # NOTE: When deployed in DataOS, these services will be automatically   #
  # managed by DataOS. You typically should NOT modify them in individual #
  # projects. Instead, treat them as managed infrastructure that Vulcan   #
  # depends on.                                                           #
  #########################################################################
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

  # MinIO Object Storage - For query results and artifacts
  minio:
    image: *minio_image
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: password
    volumes:
      - objeststore:/data
    restart: unless-stopped
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    networks:
      - vulcan

  # MinIO initialization - creates bucket and sets policies
  minio-init:
    image: *minio_mc_image
    depends_on:
      minio:
        condition: service_healthy
    restart: "no"
    entrypoint: >
      /bin/sh -c "
      /usr/bin/mc alias set myminio http://minio:9000 admin password;
      /usr/bin/mc mb myminio/warehouse --ignore-existing;
      /usr/bin/mc anonymous set download myminio/warehouse/queries;
      exit 0;
      "
    networks:
      - vulcan

```
### Warehouse Services

Create `docker/docker-compose.warehouse.yml`:

```yaml
x-images:
  postgres: &postgres_image "postgres:15-alpine"

volumes:
  warehouse:
    driver: local

networks:
  vulcan:
    external: true

services:
  # PostgreSQL Warehouse
  warehouse:
    image: *postgres_image
    environment:
      POSTGRES_DB: warehouse
      POSTGRES_USER: vulcan
      POSTGRES_PASSWORD: vulcan
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - "5433:5432"
    volumes:
      - warehouse:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U vulcan -d warehouse"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - vulcan
```

### Vulcan Services

Create `docker/docker-compose.vulcan.yml`:

```yaml
x-images:
  vulcan: &vulcan_image "tmdcio/vulcan:${VERSION:-0.225.0-dev}"
  vulcan-transpiler: &vulcan_transpiler_image "tmdcio/vulcan-transpiler:${VERSION:-0.225.0-dev}"

networks:
  vulcan:
    external: true

services:
  # Vulcan API for this example project
  vulcan-api:
    image: *vulcan_image
    working_dir: /workspace
    command: ["vulcan", "--log-to-stdout","api", "--host", "0.0.0.0", "--port", "8000"]
    environment:
      PROJECT_PATH: ${PROJECT_PATH:-/workspace}
    ports:
      - "8000:8000"
    volumes:
      - ../:/workspace
    restart: unless-stopped
    networks:
      - vulcan
    # Note: depends_on with external services (statestore, minio) won't work across compose files
    # Ensure infra services are running before starting this service

  # Transpiler service
  vulcan-transpiler:
    image: *vulcan_transpiler_image
    environment:
      VULCAN_API_URL: http://vulcan-api:8000/api/v1
    depends_on:
      - vulcan-api
    restart: unless-stopped
    networks:
      - vulcan

```

## Step 3: Create a Makefile (Optional but Recommended)

Create a `Makefile` in your project root for convenient commands:

```makefile
.PHONY: help network infra warehouse vulcan vulcan-shell vulcan-api vulcan-up setup all-down infra-down warehouse-down vulcan-down clean-volumes all-clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Setup targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(network|infra|warehouse|setup)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Vulcan targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(vulcan|core|api)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'
	@echo ''
	@echo 'Cleanup targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E '(down|clean)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

network: ## Create the external Docker network (Step 1)
	@echo "Creating external Docker network 'vulcan'..."
	@docker network create vulcan || echo "Network 'vulcan' already exists"

infra: network ## Start infrastructure services - statestore, minio (Step 2)
	@echo "Starting infrastructure services..."
	docker compose -f docker/docker-compose.infra.yml up -d

warehouse: network ## Start warehouse database (Step 3)
	@echo "Starting warehouse database..."
	docker compose -f docker/docker-compose.warehouse.yml up -d

setup: network infra warehouse ## Run all setup steps (network + infra + warehouse)
	@echo "Setup complete! Infrastructure and warehouse are running."
	@echo "You can now run 'make vulcan-shell' to start working with Vulcan."

vulcan-up: ## Start Vulcan API services - API and transpiler (Getting Started Step 3)
	@echo "Starting Vulcan API services..."
	docker compose -f docker/docker-compose.vulcan.yml up -d
	@echo "Vulcan API is available at http://localhost:8000/redoc"

vulcan-down: ## Stop Vulcan services
	@echo "Stopping Vulcan services..."
	docker compose -f docker/docker-compose.vulcan.yml down

infra-down: ## Stop infrastructure services
	@echo "Stopping infrastructure services..."
	docker compose -f docker/docker-compose.infra.yml down

warehouse-down: ## Stop warehouse services
	@echo "Stopping warehouse services..."
	docker compose -f docker/docker-compose.warehouse.yml down

all-down: vulcan-down infra-down warehouse-down ## Stop all services
	@echo "All services stopped."

all-clean: all-down ## Stop all services and remove all volumes
	@echo "Removing all Docker volumes..."
	@docker compose -f docker/docker-compose.infra.yml down -v || true
	@docker compose -f docker/docker-compose.warehouse.yml down -v || true
	@docker compose -f docker/docker-compose.vulcan.yml down -v || true
	@echo "All volumes removed."
```

## Step 4: Setup Infrastructure

### 4.1 Create the Docker Network

All services need to communicate through a shared network. Create it:

```bash
make network
```

Or directly:
```bash
docker network create vulcan
```

**Why?** The external network allows services from different Docker Compose files to communicate with each other using service names.

### 4.2 Start Infrastructure Services

Start the infrastructure services that Vulcan depends on:

```bash
make infra
```

Or directly:
```bash
docker compose -f docker/docker-compose.infra.yml up -d
```

**What gets setup:**
- **statestore** (PostgreSQL): Stores Vulcan's internal state, including model definitions, plan information, and execution history
- **minio** (Object Storage): Stores query results, artifacts, and other data objects that Vulcan generates
- **minio-init**: Initializes MinIO buckets and policies

**How Vulcan uses them:**
- Vulcan uses the statestore to persist your semantic model, plans, and track materialization state
- Vulcan uses MinIO to store query results and artifacts, enabling efficient data retrieval and caching
- These services are essential for Vulcan's operation and must be running before you can use Vulcan

### 4.3 Start Warehouse Database

Start the warehouse database:

```bash
make warehouse
```

Or directly:
```bash
docker compose -f docker/docker-compose.warehouse.yml up -d
```

**What gets setup:**
- **warehouse** (PostgreSQL): Your data warehouse containing the source tables that Vulcan will query

**Note:** We're using PostgreSQL as an example warehouse for this project. In production, Vulcan supports various warehouse types (BigQuery, Snowflake, Redshift, etc.), and you would configure your actual warehouse connection instead.

### Quick Setup

You can run all setup steps at once:

```bash
make setup
```

This will create the network and start both infrastructure and warehouse services.

## Step 5: Access Vulcan 

Now that the infrastructure is running, you can access Vulcan through an command:

```bash
docker run -it --network=vulcan  --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev vulcan
```

### Create a Convenient Alias (Optional)

For easier access, you can create a temporary alias in your current shell session:

```bash
alias vulcan="docker run -it --network=vulcan  --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev vulcan"
```

After creating this alias, you can use `vulcan` directly instead of entering the shell first:

```bash
vulcan --help
vulcan plan
```

**Note:** This alias is temporary and will be lost when you close your shell session. To make it permanent, add it to your shell configuration file (`~/.bashrc` or `~/.zshrc`).

## Step 6: Create Your First Vulcan Project

Inside the Vulcan shell (or using your alias), initialize a new Vulcan project:

```bash
vulcan init
```

The scaffold generator will ask you some questions:

1. **Project type**: Choose `DEFAULT` (option 1) to create an example project with models
2. **SQL engine**: Choose `Postgres` (or the engine matching your warehouse)
3. **CLI mode**: Choose `DEFAULT` (option 1) to see all details

The scaffold generator will create:
- `config.yaml` - Project configuration file
- `models/` - Directory for your SQL models
- `seeds/` - Directory for seed data files
- `audits/` - Directory for audit files
- `tests/` - Directory for test files
- `macros/` - Directory for macro files
- `checks/` - Directory for checks files
- `semantics/` - Directory for semantics files

### Update Configuration

If you chose PostgreSQL, update the `config.yaml` file to match your Docker setup:

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
      host: statestore
      port: 5432
      database: statestore
      user: vulcan
      password: vulcan

default_gateway: default

model_defaults:
  dialect: postgres
  start: 2025-01-01
  cron: '@daily'
```

## Step 7: Run Your First Plan

Now you can create and apply your first plan:

```bash
vulcan plan
```

This will:
1. Validate your models
2. Create a plan showing what will be created or changed
3. Prompt you to apply the plan

Enter `y` when prompted to apply the plan and backfill your models.

## Step 8: Start API Services (Optional)

If you want to use Vulcan's API endpoints (for querying, transpiler, etc.), start the API services:

```bash
make vulcan-up
```

This starts:
- **vulcan-api**: REST API for querying your semantic model (available at `http://localhost:8000`)
- **vulcan-transpiler**: Service for transpiling semantic queries to SQL

## Stopping Services

To stop services, you can use make commands:

```bash
make all-down        # Stop all services
make vulcan-down     # Stop only Vulcan services
make infra-down      # Stop only infrastructure services
make warehouse-down  # Stop only warehouse services
```

Or directly:
```bash
docker compose -f docker/docker-compose.infra.yml down
docker compose -f docker/docker-compose.warehouse.yml down
docker compose -f docker/docker-compose.vulcan.yml down
```

## Next Steps

Congratulations! You've set up Vulcan using Docker and created your first project.

From here, you can:

- [Learn more about Vulcan CLI commands](../reference/cli.md)
- [Explore Vulcan concepts](../concepts/overview.md)
- [Set up connections to different warehouses](../guides/connections.md)
- [Learn about semantic models](../concepts/overview.md)

## Troubleshooting

### Services won't start

Make sure Docker Desktop is running and you have enough resources allocated (at least 4GB RAM).

### Network errors

Ensure the `vulcan` network exists:
```bash
docker network ls | grep vulcan
```

If it doesn't exist, create it:
```bash
docker network create vulcan
```

### Port conflicts

If ports 5431, 5433, 9000, 9001, or 8000 are already in use, you can modify the port mappings in the Docker Compose files.

### Can't connect to services

Make sure all services are running:
```bash
docker compose -f docker/docker-compose.infra.yml ps
docker compose -f docker/docker-compose.warehouse.yml ps
```

### MinIO console

You can access the MinIO console at `http://localhost:9001` with:
- Username: `admin`
- Password: `password`

