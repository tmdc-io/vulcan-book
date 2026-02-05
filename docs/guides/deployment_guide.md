# DataOS 2.0 Env Deployment

This guide provides step-by-step instructions for deploying Vulcan data products in a DataOS environment.

<!-- ## Table of Contents
- [Prerequisites](#prerequisites)
- [Configuration Files](#configuration-files)
- [Deployment Steps](#deployment-steps)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting) -->

---

## Prerequisites

Before deploying a Vulcan data product, ensure you have the following resources configured in your DataOS environment:

### 1. DataOS 2.0 CLI

Ensure you have the DataOS CLI installed and configured:

```bash
# Verify CLI installation
ds version

# Login to your DataOS instance
ds login
```

### 2. Depot (Data Source Connection)

A depot must be configured to connect to your data warehouse (e.g., Snowflake, BigQuery, Databricks).

**List available depots:**
```bash
ds resource -t depot get -a
```

> **Note:** Ensure the depot has read/write permissions for your data warehouse schema.

### 3. Engine Stack

An engine stack defines the execution environment for Vulcan operations (e.g., Snowflake, BigQuery, Spark).

**List available stacks:**
```bash
ds resource -t stack get -a
```

**Supported engines:**
- `snowflake`
- `bigquery`
- `databricks`
- `postgres`
- `redshift`
- `trino`
- `mysql`
- `mssql`

### 4. Compute Resource

A compute resource provides the execution environment for running Vulcan workflows.

**List available compute resources:**
```bash
ds resource -t compute get -a
```

**Example compute resources:**
- `cyclone-compute` (general purpose)
- `minerva-compute` (query engine)
- Custom compute clusters

### 5. Git-Sync Secret

A secret is required to access your private Git repository containing Vulcan models and configurations.

**Create a git-sync secret:**
```bash
ds resource apply -f git-sync-secret.yaml
```

**Example secret configuration:**
```yaml
version: v1
type: secret
name: git-sync
workspace: <workspace-name>
spec:
  type: key-value-properties
  acl: r
  data:
    username: <your-git-username>
    password: <your-git-token-or-password>
```

> **Important:** Replace credentials with your actual Git repository access tokens.

---

## Configuration Files

Vulcan deployments require two key configuration files:

### 1. `config.yaml` - Vulcan Configuration

This file contains Vulcan-specific configurations including model defaults, gateways, notifications, and metadata.

**Location:** `<project-root>/config.yaml`

**Key sections:**

#### Basic Metadata
```yaml
name: <data-product-name>
display_name: <Data Product Title>
tenant: <tenant-name>
description: <Description .... >

tags:
  - <tag1>
  - <tag2>
```

#### Model Defaults
```yaml
model_defaults:
  dialect: <engine-dialect>          # Database dialect eg. snowflake, bigquery
  start: '2025-01-01'        # Start date for time-based models
  cron: '<cron>'             # Default scheduling cadence @daily
```

#### Gateway Configuration
```yaml
gateways:
  default:
    connection:
      type: depot
      address: dataos://<depot-name>  # Reference to your depot
```

#### Users and Ownership
```yaml
users:
  - username: <username1>
    email: <username1@email.id>
    type: OWNER
  - username: <username2>
    email: <username2@email.id>
    type: CONTRIBUTOR
```

#### Complete config.yaml Example

<details>
<summary>📋 Click to see complete config.yaml example</summary>

```yaml
name: user-engagement
display_name: User Engagement Analytics
tenant: engineering
description: User Engagement Analytics is a comprehensive data product delivering insights into user engagement patterns.

tags:
  - snowflake
  - user_engagement
  - device_analytics

model_defaults:
  dialect: snowflake
  start: '2025-01-01'
  cron: '@daily'

gateways:
  default:
    connection:
      type: depot
      address: dataos://snowflakevulcan2

notification_targets:
  - type: console
    notify_on:
      - apply_failure
      - run_failure
      - check_failure

users:
  - username: shreya
    email: shreya.sikarwar@tmdc.io
    type: OWNER
  - username: rohit
    email: rohit.raj@tmdc.io
    type: CONTRIBUTOR
```
</details>

---

### 2. `domain-resource.yaml` - DataOS Resource Configuration

This file defines the DataOS-specific resource configuration for deploying Vulcan as a managed service.

**Location:** `<project-root>/domain-resource.yaml`

**Key sections:**

#### Resource Metadata
```yaml
version: v1alpha
type: vulcan
name: <data-product-name>
tags:
  - <tag1>
  - <tag2>
```

#### Execution Configuration
```yaml
spec:
  runAsUser: "<dataos-username>"     # DataOS user identity
  compute: <compute-name>            # Compute cluster name eg. cyclone-compute
  engine: <engine-name>              # Execution engine eg. snowflake, bigquery
```

#### Repository Configuration
```yaml
  repo:
    url: <git-repository-url>                # eg. https://github.com/org/repo
    syncFlags:
      - '--ref=<branch-name>'                # Git branch eg. main
      - '--submodules=off'
    baseDir: <path-to-project-in-repo>       # Path to project folder
    secret: <workspace>:<secret>          # Git credentials secret eg. engineering:git-sync-name
```

#### Depot References
```yaml
  depots:
    - dataos://<depot-name>?purpose=rw      # Read-write depot access
```

#### Workflow Configuration
```yaml
  workflow:
    type: schedule              # Run on a schedule
    schedule:
      crons:
        - '<cron-expression>'  # eg. '*/45 * * * *' (Every 45 minutes)
      endOn: '<end-date>'      # eg. '2027-01-01T00:00:00-00:00'
      timezone: '<timezone>'   # eg. 'US/Pacific'
      concurrencyPolicy: Forbid
    
    logLevel: INFO
    
    resource:                   # Resource allocation
      request:
        cpu: "<cpu-request>"   # eg. "200m"
        memory: "<memory-request>"  # eg. "512Mi"
      limit:
        cpu: "<cpu-limit>"     # eg. "1000m"
        memory: "<memory-limit>"    # eg. "1Gi"
```

#### Vulcan Commands
```yaml
    migrate:                    # Schema migration
      command: [vulcan]
      arguments: [migrate]
    
    plan:                       # Plan changes
      command: [vulcan]
      arguments:
        - --log-to-stdout
        - plan
        - --auto-apply
    
    run:                        # Execute models
      command: [vulcan]
      arguments:
        - --log-to-stdout
        - run
```

#### API Configuration
```yaml
  api:
    replicas: <replica-count>     # eg. 1
    logLevel: INFO
    resource:
      request:
        cpu: "<cpu-request>"      # eg. "200m"
        memory: "<memory-request>"     # eg. "512Mi"
      limit:
        cpu: "<cpu-limit>"        # eg. "5000m"
        memory: "<memory-limit>"       # eg. "4Gi"
```

#### Complete domain-resource.yaml Example

<details>
<summary>📋 Click to see complete domain-resource.yaml example</summary>

```yaml
version: v1alpha
type: vulcan
name: user-engagement
tags:
  - snowflake-analytics
  - user_engagement
  - device_analytics
spec:
  runAsUser: "shreyasikarwartmdcio"
  compute: cyclone-compute
  engine: snowflake
  repo:
    url: https://bitbucket.org/rubik_/vulcan-examples
    syncFlags:
      - '--ref=main'
      - '--submodules=off'
    baseDir: vulcan-examples/customer-usecase/usdk
    secret: engineering:git-sync
  depots:
    - dataos://snowflakevulcan2?purpose=rw
  workflow:
    type: schedule
    schedule:
      crons:
        - '*/45 * * * *'
      endOn: '2027-01-01T00:00:00-00:00'
      timezone: 'US/Pacific'
      concurrencyPolicy: Forbid
    logLevel: INFO
    resource:
      request:
        cpu: "200m"
        memory: "512Mi"
      limit:
        cpu: "1000m"
        memory: "1Gi"
    migrate:
      command:
        - vulcan
      arguments:
        - migrate
    plan:
      command:
        - vulcan
      arguments:
        - --log-to-stdout
        - plan
        - --auto-apply
    run:
      command:
        - vulcan
      arguments:
        - --log-to-stdout
        - run
  api:
    replicas: 1
    logLevel: INFO
    resource:
      request:
        cpu: "200m"
        memory: "512Mi"
      limit:
        cpu: "5000m"
        memory: "4Gi"
```
</details>

---

## Deployment Steps

### Step 1: Prepare Your Repository

1. Create your Vulcan project structure:
```
your-project/
├── config.yaml              # Vulcan configuration
├── domain-resource.yaml     # DataOS resource definition
├── models/                  # SQL model files
│   ├── staging/
│   └── marts/
├── seeds/                   # Static data files
├── checks/                  # Data quality checks
├── audits/                  # Audit queries
└── semantics/              # Semantic layer definitions
```

2. Configure `config.yaml` with your project settings
3. Configure `domain-resource.yaml` with DataOS settings
4. Push your code to a Git repository

### Step 2: Create Required Secrets

```bash
# Create git-sync secret (if not exists)
ds resource apply -f git-sync-secret.yaml
```

### Step 3: Verify Prerequisites

```bash
# Verify depot exists
ds resource -t depot get -n <depot-name> -a

# Verify compute exists
ds resource -t compute get -n <compute-name> -a

# Verify stack exists
ds resource -t stack get -a 
```

### Step 4: Deploy Vulcan Resource

```bash
# Apply the domain-resource configuration
ds resource apply -f domain-resource.yaml

```

### Step 5: Monitor Deployment

```bash
# Get resource status
ds resource -t vulcan -n <data-product-name> get


# Check logs
ds resource -t vulcan -n <data-product-name> logs
```

---

## Verification

### Verify Models in Data Warehouse

Connect to your data warehouse and verify that tables/views have been created:

```sql
-- For Snowflake
SHOW TABLES IN SCHEMA <database>.<schema>;

-- Check specific table
SELECT * FROM <database>.<schema>.<table-name> LIMIT 10;
```

### Access Vulcan API

```bash
# Test API (if exposed)
curl --location 'https://<env-fqn>/<tenant>/vulcan/<data-product-name>/livez' \
  --header 'Authorization: Bearer <your-token>'
```

