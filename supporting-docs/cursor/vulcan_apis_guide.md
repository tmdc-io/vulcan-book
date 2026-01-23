# Vulcan APIs Guide

This guide explains how to access Vulcan APIs, what setup is required, and how to consume all types of APIs that Vulcan exposes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup Commands](#setup-commands)
3. [API Types Overview](#api-types-overview)
4. [REST API](#rest-api)
5. [GraphQL API](#graphql-api)
6. [Python API](#python-api)
7. [CLI Interface](#cli-interface)
8. [Transpiler API](#transpiler-api)
9. [API Access Verification](#api-access-verification)

## Prerequisites

Before accessing Vulcan APIs, ensure you have:

- **Docker Desktop** installed and running
- **Docker Compose** (included with Docker Desktop)
- At least **4GB of available RAM**
- A **Vulcan project** initialized (run `vulcan init` if you haven't already)
- **Infrastructure services** running (statestore, MinIO, warehouse database)

## Setup Commands

### Step 1: Start Infrastructure Services

Before accessing any APIs, you must start the required infrastructure services:

**Mac/Linux:**
```bash
make setup
# OR manually:
docker network create vulcan
docker compose -f docker/docker-compose.infra.yml up -d
docker compose -f docker/docker-compose.warehouse.yml up -d
```

**Windows:**
```cmd
setup.bat
```

This starts:
- **statestore** (PostgreSQL) on port 5431 - Stores Vulcan's internal state
- **minio** (Object Storage) on ports 9000 and 9001 - Stores query results and artifacts
- **warehouse** database (PostgreSQL) on port 5433 - Your data warehouse

**Note:** These services are essential for Vulcan's operation and must be running before you can use any APIs.

### Step 2: Configure Vulcan CLI Access

Before using any Vulcan commands, you need to set up the CLI alias. This allows you to run `vulcan` commands easily.

**Mac/Linux:**

Create an alias to access the Vulcan CLI:

```bash
alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-postgres:0.228.2 vulcan"
```

**Note:** This alias is temporary and will be lost when you close your shell session. To make it permanent, add this line to your shell configuration file:
- **Bash**: Add to `~/.bashrc` or `~/.bash_profile`
- **Zsh**: Add to `~/.zshrc`

After adding, restart your terminal or run:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

**Alternative (older version):**
```bash
alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev-02 vulcan"
```

**Windows:**

Use the provided batch script to access the Vulcan CLI:

```cmd
vulcan.bat
```

This script runs Vulcan commands in a Docker container with the correct network and volume settings.

**Verify the alias works:**

Test that the Vulcan CLI is accessible:

```bash
vulcan --help
```

You should see the Vulcan command help output. If you get an error, verify:
- Docker Desktop is running
- The `vulcan` Docker network exists (created in Step 1)
- You're in your project directory

### Step 3: Initialize Your Project

Now that the CLI is configured, initialize your Vulcan project:

```bash
vulcan init
```

When prompted:
- Choose `DEFAULT` as the project type
- Select your SQL engine (e.g., `Postgres`)

### Step 4: Create and Apply a Plan

Before APIs can access your semantic models, you need to create and apply a plan:

```bash
vulcan plan
```

When prompted, enter `y` to apply the plan. This validates your models and creates the necessary database objects.

### Step 5: Start API Services

Start the Vulcan API services:

**Mac/Linux:**
```bash
make vulcan-up
# OR manually:
docker compose -f docker/docker-compose.vulcan.yml up -d
```

**Windows:**
```cmd
start-vulcan-api.bat
```

This starts:
- **vulcan-api**: REST API server (available at `http://localhost:8000`)
- **vulcan-transpiler**: Service for transpiling semantic queries to SQL

### Step 6: Verify Services Are Running

Check that all services are running:

```bash
docker ps
```

You should see containers for:
- statestore
- minio
- warehouse (if using Docker setup)
- vulcan-api
- vulcan-transpiler

## API Types Overview

Vulcan provides multiple API interfaces for different use cases:

1. **REST API** - HTTP endpoints for web applications and integrations
2. **GraphQL API** - GraphQL interface for flexible queries
3. **Python API** - VulcanContext for programmatic access in Python
4. **CLI Interface** - Command-line interface for operations
5. **Transpiler API** - Service for converting semantic queries to SQL

## REST API

The REST API provides HTTP endpoints for querying your semantic model, accessing models, metrics, lineage information, and telemetry.

### Starting the REST API Server

The REST API server is started as part of the `vulcan-up` command, or you can start it manually:

```bash
vulcan api --host 0.0.0.0 --port 8000
```

**Options:**
- `--host TEXT`: Bind socket to this host (default: 0.0.0.0)
- `--port INTEGER`: Bind socket to this port (default: 8000)
- `--reload`: Enable auto-reload on file changes (default: False)
- `--workers INTEGER`: Number of worker processes (default: 1)

### Base URL

Once started, the REST API is available at:
```
http://localhost:8000
```

The API typically follows the pattern:
```
http://localhost:8000/api/v1/<endpoint>
```

### API Endpoints

The REST API exposes endpoints for:

- **Models** - Query and manage data models
- **Metrics** - Access semantic layer metrics
- **Lineage** - Query model dependencies and relationships
- **Telemetry** - Access execution and performance data
- **Semantic Queries** - Execute semantic layer queries

### Consuming REST API

#### Using cURL

```bash
# Example: Query semantic layer
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "measures": ["users.total_users"],
      "dimensions": ["users.plan_type"]
    }
  }'
```

#### Using Python (requests)

```python
import requests

api_url = "http://localhost:8000/api/v1/query"

payload = {
    "query": {
        "measures": ["users.total_users"],
        "dimensions": ["users.plan_type"]
    }
}

response = requests.post(api_url, json=payload)
data = response.json()
print(data)
```

#### Using JavaScript (fetch)

```javascript
const apiUrl = 'http://localhost:8000/api/v1/query';

const payload = {
  query: {
    measures: ['users.total_users'],
    dimensions: ['users.plan_type']
  }
};

fetch(apiUrl, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(payload)
})
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

### REST API Query Format

REST API queries use JSON payloads with semantic query definitions:

```json
{
  "query": {
    "measures": ["alias.measure_name"],
    "dimensions": ["alias.dimension_name"],
    "segments": ["segment_name"],
    "timeDimensions": [{
      "dimension": "alias.time_dimension",
      "dateRange": ["2024-01-01", "2024-12-31"],
      "granularity": "month"
    }],
    "filters": [{
      "member": "alias.dimension_name",
      "operator": "equals",
      "values": ["value1", "value2"]
    }],
    "order": {
      "alias.measure_name": "desc"
    },
    "limit": 100,
    "offset": 0,
    "timezone": "UTC",
    "renewQuery": false
  },
  "ttl_minutes": 60
}
```

**Key Components:**
- `measures`: Array of fully qualified measure names (required)
- `dimensions`: Array of fully qualified dimension names (optional)
- `segments`: Array of segment names (optional)
- `timeDimensions`: Array of time dimension objects (optional)
- `filters`: Array of filter objects (optional)
- `order`: Object mapping member names to sort direction (optional)
- `limit`: Maximum rows to return (optional)
- `offset`: Rows to skip for pagination (optional)

## GraphQL API

Vulcan provides a GraphQL API for flexible querying of your semantic layer and models.

### Starting the GraphQL Service

Start the GraphQL service using the CLI:

```bash
vulcan graphql up
```

**Options:**
- `--no-detach`: Run docker compose in the foreground (omit -d)

To stop the GraphQL service:

```bash
vulcan graphql down
```

### GraphQL Endpoint

Once started, the GraphQL API is typically available at:
```
http://localhost:4000/graphql
```

(Exact port may vary based on configuration)

### Consuming GraphQL API

#### Using cURL

```bash
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { models { name } }"
  }'
```

#### Using Python (requests)

```python
import requests

graphql_url = "http://localhost:4000/graphql"

query = """
query {
  models {
    name
    description
  }
}
"""

response = requests.post(graphql_url, json={"query": query})
data = response.json()
print(data)
```

#### Using JavaScript (fetch)

```javascript
const graphqlUrl = 'http://localhost:4000/graphql';

const query = `
  query {
    models {
      name
      description
    }
  }
`;

fetch(graphqlUrl, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ query })
})
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

#### Using GraphQL Client Libraries

For more advanced usage, consider using GraphQL client libraries:

**Python:**
```python
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

transport = RequestsHTTPTransport(url="http://localhost:4000/graphql")
client = Client(transport=transport, fetch_schema_from_transport=True)

query = gql("""
  query {
    models {
      name
      description
    }
  }
""")

result = client.execute(query)
print(result)
```

**JavaScript (Apollo Client):**
```javascript
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

const client = new ApolloClient({
  uri: 'http://localhost:4000/graphql',
  cache: new InMemoryCache()
});

const GET_MODELS = gql`
  query {
    models {
      name
      description
    }
  }
`;

client.query({ query: GET_MODELS })
  .then(result => console.log(result.data))
  .catch(error => console.error('Error:', error));
```

## Python API

Vulcan provides a Python API through `VulcanContext` for programmatic access to your data pipeline.

### Installation

The Python API is available when you install Vulcan:

```bash
pip install vulcan
```

### Using VulcanContext

```python
from vulcan import VulcanContext

# Initialize Vulcan context
ctx = VulcanContext()

# Access models
models = ctx.models()

# Execute queries
result = ctx.fetchdf("SELECT * FROM schema.model_name")

# Access semantic layer
# (Specific methods depend on Vulcan version and implementation)
```

### Common Python API Operations

```python
from vulcan import VulcanContext

ctx = VulcanContext()

# Get project information
info = ctx.info()

# Render a model's SQL
sql = ctx.render("model_name")

# Evaluate a model
df = ctx.evaluate("model_name")

# Run a plan
ctx.plan()

# Execute a run
ctx.run()
```

**Note:** The exact Python API methods may vary by Vulcan version. Refer to the Vulcan Python documentation for the complete API reference.

## CLI Interface

The Vulcan CLI provides a command-line interface that can be used programmatically or in scripts.

### Accessing the CLI

**Important:** If you haven't set up the CLI alias yet, refer to [Step 2: Configure Vulcan CLI Access](#step-2-configure-vulcan-cli-access) in the Setup Commands section above.

Once configured, you can use `vulcan` commands directly. The alias setup is:

**Mac/Linux:**
```bash
alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan-postgres:0.228.2 vulcan"
```

**Windows:**
```cmd
vulcan.bat
```

### Common CLI Commands for API-like Operations

```bash
# Get project information
vulcan info

# Render model SQL
vulcan render model_name

# Execute SQL query
vulcan fetchdf "SELECT * FROM schema.model_name"

# Transpile semantic queries
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
vulcan transpile --format json '{"query": {"measures": ["users.total_users"]}}'

# Start API server
vulcan api --host 0.0.0.0 --port 8000

# Manage GraphQL service
vulcan graphql up
vulcan graphql down
```

### Using CLI in Scripts

**Bash Script:**
```bash
#!/bin/bash
# Query using CLI
vulcan fetchdf "SELECT * FROM schema.model_name LIMIT 10"

# Transpile semantic query
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

**Python Script:**
```python
import subprocess

# Execute CLI command
result = subprocess.run(
    ['vulcan', 'fetchdf', 'SELECT * FROM schema.model_name'],
    capture_output=True,
    text=True
)
print(result.stdout)
```

## Transpiler API

The Vulcan Transpiler service converts semantic queries into executable SQL. It's available both as a CLI command and as a service.

### Transpiler Service

The transpiler service runs as part of `vulcan-up` and is configured to connect to the Vulcan API:

```yaml
vulcan-transpiler:
  environment:
    VULCAN_API_URL: http://vulcan-api:8000/api/v1
    VULCAN_EXPORT_QUERY_PARAMS: strict=true
```

### Using Transpiler via CLI

#### Transpiling Semantic SQL

```bash
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

#### Transpiling REST API Payloads

```bash
vulcan transpile --format json '{"query": {"measures": ["users.total_users"]}}'
```

**Options:**
- `--format`: Output format (`sql` or `json`) - **required**
- `--disable-post-processing`: Enable pushdown mode for CTE support

### Transpiler Query Formats

#### Semantic SQL Format

```sql
SELECT 
  alias.dimension_name,
  MEASURE(alias.measure_name)
FROM alias
CROSS JOIN other_alias
WHERE alias.dimension_name = 'value'
  AND segment_name = true
GROUP BY alias.dimension_name
ORDER BY MEASURE(alias.measure_name)
LIMIT 100
OFFSET 0
```

#### JSON Format (REST API Payload)

```json
{
  "query": {
    "measures": ["alias.measure_name"],
    "dimensions": ["alias.dimension_name"],
    "segments": ["segment_name"],
    "timeDimensions": [{
      "dimension": "alias.time_dimension",
      "dateRange": ["2024-01-01", "2024-12-31"],
      "granularity": "month"
    }],
    "filters": [{
      "member": "alias.dimension_name",
      "operator": "equals",
      "values": ["value1"]
    }],
    "order": {
      "alias.measure_name": "desc"
    },
    "limit": 100,
    "offset": 0
  }
}
```

### Example Transpiler Usage

```bash
# Simple measure query
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"

# Query with dimensions
vulcan transpile --format sql "SELECT users.plan_type, MEASURE(total_users) FROM users GROUP BY users.plan_type"

# Query with filters
vulcan transpile --format sql "SELECT MEASURE(total_arr) FROM subscriptions WHERE subscriptions.status = 'active'"

# Complex JSON query
vulcan transpile --format json '{
  "query": {
    "measures": ["subscriptions.total_arr"],
    "dimensions": ["subscriptions.plan_type", "users.industry"],
    "filters": [{
      "member": "subscriptions.status",
      "operator": "equals",
      "values": ["active"]
    }],
    "timeDimensions": [{
      "dimension": "subscriptions.start_date",
      "dateRange": ["2024-01-01", "2024-12-31"],
      "granularity": "month"
    }],
    "order": {"subscriptions.total_arr": "desc"},
    "limit": 100
  }
}'
```

## API Access Verification

### Verify REST API is Running

```bash
# Check if API server is responding
curl http://localhost:8000/health
# OR
curl http://localhost:8000/api/v1/health
```

### Verify GraphQL API is Running

```bash
# Check GraphQL endpoint
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { queryType { name } } }"}'
```

### Verify Transpiler Service

```bash
# Test transpilation
vulcan transpile --format sql "SELECT MEASURE(total_users) FROM users"
```

### Check Docker Containers

```bash
# List running containers
docker ps

# Check API container logs
docker logs vulcan-api

# Check transpiler container logs
docker logs vulcan-transpiler
```

### Common Issues and Solutions

**Issue: API not accessible**
- Ensure infrastructure services are running (`make setup`)
- Ensure API services are started (`make vulcan-up`)
- Check Docker containers are running (`docker ps`)
- Verify ports are not blocked (8000 for REST API, 4000 for GraphQL)

**Issue: "Connection refused" errors**
- Verify services are running: `docker ps`
- Check service logs: `docker logs vulcan-api`
- Ensure Docker network is created: `docker network create vulcan`
- Verify firewall settings

**Issue: "Model not found" errors**
- Ensure you've created and applied a plan: `vulcan plan`
- Verify semantic models are defined in `semantics/` directory
- Check model aliases match your queries

**Issue: Transpiler errors**
- Verify semantic models are properly defined
- Check query syntax matches expected format
- Ensure measures and dimensions are correctly qualified (e.g., `alias.measure_name`)

## Service Ports Reference

- **Statestore**: 5431
- **Warehouse**: 5433
- **MinIO API**: 9000
- **MinIO Console**: 9001
- **Vulcan REST API**: 8000
- **GraphQL API**: 4000 (may vary)

## Next Steps

- Explore the [Semantic Layer documentation](../docs/components/semantics/overview.md) to understand how to define metrics and dimensions
- Learn about [Transpiling Semantics](../docs/guides/transpiling_semantics.md) for advanced query patterns
- Check the [CLI Reference](../docs/cli-command/cli.md) for complete command documentation
- Review [Getting Started Guide](../docs/guides/get-started/docker.md) for project setup

## Additional Resources

- Vulcan CLI commands: `vulcan --help`
- API documentation: Available at `http://localhost:8000/docs` when API server is running (if OpenAPI/Swagger is enabled)
- GraphQL schema: Available via introspection queries when GraphQL service is running
