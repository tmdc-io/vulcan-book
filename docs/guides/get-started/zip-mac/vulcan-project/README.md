# Vulcan Docker Quickstart

This package contains all the Docker Compose files and configuration needed to get started with Vulcan using Docker.

## Contents

- `docker/docker-compose.infra.yml` - Infrastructure services (statestore, MinIO)

- `docker/docker-compose.warehouse.yml` - Warehouse database (PostgreSQL)

- `docker/docker-compose.vulcan.yml` - Vulcan API and transpiler services

- `Makefile` - Convenient commands for managing services

## Prerequisites

- Docker Desktop installed and running

- Docker Compose (included with Docker Desktop)

- At least 4GB of available RAM

- A terminal/command line interface

## Quick Start

1. **Start all infrastructure:**
   ```bash
   make setup
   ```
   This will:
   - Create the Docker network

   - Start statestore (PostgreSQL) on port 5431

   - Start MinIO object storage on ports 9000 and 9001

   - Start warehouse database (PostgreSQL) on port 5433

2. **Access Vulcan:**
   ```bash
   alias vulcan="docker run -it --network=vulcan  --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev-02 vulcan"
   ```

3. **Initialize your project:**
   ```bash
   vulcan init
   ```

4. **Update your `config.yaml`** to match the Docker setup:
   ```yaml
   # Project identity
   name: orders-analytics
   display_name: Orders Analytics Platform
   tenant: engineering
   description: Orders Analytics delivers insights across the full order lifecycle.

   # Classification
   tags:
     - postgres
     - sales_analytics
     - demo

   terms:
     - glossary.data_product
     - glossary.sales_operations

   # Metadata
   metadata:
     domain: sales_operations
     use_cases:
       - Daily sales reporting
       - Customer analytics
     limitations:
       - Demo dataset with synthetic data

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
   ```bash
   vulcan plan
   ```

## Available Make Commands
- `make setup` - Run all setup steps

- `make vulcan-up` - Start Vulcan API services

- `make network` - Create the Docker network

- `make infra` - Start infrastructure services

- `make warehouse` - Start warehouse database

- `make all-down` - Stop all services

- `make all-clean` - Stop all services and remove volumes

## Service Ports

- **Statestore**: 5431

- **Warehouse**: 5433

- **MinIO API**: 9000

- **MinIO Console**: 9001 (admin/password)

- **Vulcan API**: 8000



