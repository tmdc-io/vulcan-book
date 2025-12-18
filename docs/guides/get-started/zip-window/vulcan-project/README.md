# Vulcan Docker Quickstart - Windows

This package contains all the Docker Compose files and Windows batch scripts needed to get started with Vulcan using Docker on Windows.

## Contents

- `docker/docker-compose.infra.yml` - Infrastructure services (statestore, MinIO)
- `docker/docker-compose.warehouse.yml` - Warehouse database (PostgreSQL)
- `docker/docker-compose.vulcan.yml` - Vulcan API and transpiler services
- `setup.bat` - Setup script to start all infrastructure
- `vulcan.bat` - Wrapper script to run Vulcan CLI commands
- `start-vulcan-api.bat` - Start Vulcan API services
- `stop-all.bat` - Stop all services
- `clean.bat` - Stop all services and remove volumes

## Prerequisites

- Docker Desktop for Windows installed and running
- At least 4GB of available RAM

## Quick Start

1. **Run the setup script:**
   ```cmd
   setup.bat
   ```
   This will:
   - Create the Docker network
   - Start statestore (PostgreSQL) on port 5431
   - Start MinIO object storage on ports 9000 and 9001
   - Start warehouse database (PostgreSQL) on port 5433

2. **Access Vulcan:**
   ```cmd
   vulcan.bat
   ```
3. **Initialize your project:**
   ```cmd
   vulcan.bat init
   ```

4. **Update your `config.yaml`** to match the Docker setup:
   ```yaml
   # Project metadata
   name: orders360
   tenant: sales
   description: Daily sales analytics pipeline

   # Gateway Connection
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
         type: postgres
         host: statestore
         port: 5432
         database: statestore
         user: vulcan
         password: vulcan

   default_gateway: default

   # Model Defaults (required)
   model_defaults:
   dialect: postgres
   start: 2024-01-01
   cron: '@daily'

   # Linting Rules
   linter:
   enabled: true
   rules:
      - ambiguousorinvalidcolumn
      - invalidselectstarexpansion
   ```

5. **Create and apply your first plan:**
   ```cmd
   vulcan.bat plan
   ```

## Available Scripts

- `setup.bat` - Create network and start all infrastructure
- `start-vulcan-api.bat` - Start Vulcan API services
- `stop-all.bat` - Stop all services
- `clean.bat` - Stop all services and remove volumes


## Service Ports

- **Statestore**: 5431
- **Warehouse**: 5433
- **MinIO API**: 9000
- **MinIO Console**: 9001 (admin/password)
- **Vulcan API**: 8000
```


