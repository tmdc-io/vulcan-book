# Get Started

This guide shows you how to set up a complete Vulcan project on your local machine.

The example project runs locally using a Postgres SQL engine. Vulcan automatically generates all necessary project files and configurations.

To get started, ensure your system meets the [prerequisites](#prerequisites) below, then follow the step-by-step instructions for your operating system.

## Prerequisites

Before you begin, make sure you have Docker installed and configured on your system. Follow the instructions below for your operating system.

=== "Mac/Linux"
    
    **1. Verify Docker Installation**
    
    First, check if Docker Desktop (Mac) or Docker Engine (Linux) is installed and running:
    
    ```bash
    docker --version
    docker compose version
    ```
    
    If both commands return version numbers, Docker is installed. Make sure Docker Desktop is running (you should see the Docker icon in your menu bar or system tray).
    
    **2. Install Docker (if needed)**
    
    - **Mac**: Download and install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/){:target="_blank"}

    - **Linux**: Install Docker Engine and Docker Compose following the [official Docker installation guide](https://docs.docker.com/engine/install/){:target="_blank"}
    
    **3. Configure Resources**
    
    Ensure Docker Desktop has at least **4GB of RAM** allocated. You can adjust this in Docker Desktop settings under Resources → Advanced.

=== "Windows"
    
    **1. Verify Docker Installation**
    
    Check if Docker Desktop for Windows is installed and running:
    
    ```bash
    docker --version
    docker compose version
    ```
    
    If both commands return version numbers, Docker is installed. Make sure Docker Desktop is running (you should see the Docker icon in your system tray).
    
    **2. Install Docker (if needed)**
    
    If Docker is not installed, download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/){:target="_blank"}
    
    **3. Configure Resources**
    
    Ensure Docker Desktop has at least **4GB of RAM** allocated. You can adjust this in Docker Desktop settings under Settings → Resources → Advanced.

## Vulcan Setup Locally

Follow these steps to set up Vulcan on your local machine. The setup process will create all necessary infrastructure services and prepare your environment for development.

=== "Mac/Linux"
      
    [:material-download: Download for Mac/Linux](zip-mac/vulcan-project.zip){ .md-button .md-button--primary .download-button target="_blank" }
    
    <small>The download includes: Docker Compose files, Makefile, and a comprehensive README</small>
        
    **Step 1: Extract and Navigate**
    
    Extract the downloaded zip file and open the `vulcan-project` folder in VS Code or your preferred IDE:
    
    ```bash
    cd vulcan-project
    ```
    
    **Step 2: Run Setup**
    
    **Important**: Before running setup, ensure Docker Desktop is running on your machine and that you are logged into RubikLabs.
    
    Execute the setup command:
    
    ```bash
    make setup
    ```
    
    This command creates and starts three essential services:
    
    - **statestore** (PostgreSQL): Stores Vulcan's internal state, including model definitions, plan information, and execution history. This database persists your semantic model, plans, and tracks materialization state.
    
    - **minio** (Object Storage): Stores query results, artifacts, and other data objects that Vulcan generates. This service provides data retrieval and caching for your workflows.
    
    - **minio-init**: Initializes MinIO buckets and policies with the correct configuration. This service runs once to set up the storage infrastructure.
    
    **Note**: These services are essential for Vulcan's operation and must be running before you can use Vulcan. The setup process typically takes 1-2 minutes to complete.
    
    **Step 3: Configure Vulcan CLI Access**
    
    Create an alias to access the Vulcan CLI easily:
    
    ```bash
    alias vulcan="docker run -it --network=vulcan --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev-02 vulcan"
    ```
    
    **Note**: This alias is temporary and will be lost when you close your shell session. To make it permanent, add this line to your shell configuration file (`~/.bashrc` for Bash or `~/.zshrc` for Zsh), then restart your terminal or run `source ~/.zshrc` (or `source ~/.bashrc`).
    
    **Step 4: Start API Services**
    
    Start the Vulcan API services:
    
    ```bash
    make vulcan-up
    ```
    
    This command starts two services:
    
    - **vulcan-api**: A REST API server for querying your semantic model (available at `http://localhost:8000`)

    - **vulcan-transpiler**: A service for transpiling semantic queries to SQL
    
    Once these services are running, you're ready to create your first project!

=== "Windows"
        
    [:material-download: Download for Windows](zip-window/vulcan-project.zip){ .md-button .md-button--primary .download-button target="_blank" }
    
    <small>The download includes: Docker Compose files, Windows batch scripts, and a comprehensive README</small>
        
    **Step 1: Extract and Navigate**
    
    Extract the downloaded zip file and navigate to the `vulcan-project` directory:
    
    ```cmd
    cd vulcan-project
    ```
    
    **Step 2: Run Setup**
    
    **Important**: Before running setup, ensure Docker Desktop for Windows is running and that you are logged into RubikLabs.
    
    Execute the setup script:
    
    ```cmd
    setup.bat
    ```
    
    This script creates and starts three essential services:
    
    - **statestore** (PostgreSQL): Stores Vulcan's internal state, including model definitions, plan information, and execution history. This database persists your semantic model, plans, and tracks materialization state.
    
    - **minio** (Object Storage): Stores query results, artifacts, and other data objects that Vulcan generates. This service provides data retrieval and caching for your workflows.
    
    - **minio-init**: Initializes MinIO buckets and policies with the correct configuration. This service runs once to set up the storage infrastructure.
    
    **Note**: These services are essential for Vulcan's operation and must be running before you can use Vulcan. The setup process typically takes 1-2 minutes to complete.
    
    **Step 3: Access Vulcan CLI**
    
    Use the provided batch script to access the Vulcan CLI:
    
    ```cmd
    vulcan.bat
    ```
    
    This script runs Vulcan commands in a Docker container with the correct network and volume settings.
    
    **Step 4: Start API Services**
    
    Start the Vulcan API services:
    
    ```cmd
    start-vulcan-api.bat
    ```
    
    This command starts two services:
    
    - **vulcan-api**: A REST API server for querying your semantic model (available at `http://localhost:8000`)

    - **vulcan-transpiler**: A service for transpiling semantic queries to SQL
    
    Once these services are running, you're ready to create your first project!

## Create Your First Project

Now that your environment is set up, let's create your first Vulcan project. This section walks you through initializing a project, verifying the setup, running your first plan, and querying your data.

=== "Mac/Linux"
    
    **Step 1: Initialize Your Project**
    
    Initialize a new Vulcan project: [*Learn more about init*](../../cli-command/cli.md#init){:target="_blank"}
    
    ```bash
    vulcan init
    ```
    
    When prompted:

    - Choose `DEFAULT` as the project type

    - Select `Postgres` as your SQL engine
    
    This command creates a complete project structure with 7 directories:

    - `models/` - Contains `.sql` and `.py` files for your data models

    - `seeds/` - CSV files for static datasets

    - `audits/` - Write logic to assert data quality and block downstream models if checks fail

    - `tests/` - Test files for validating your model logic

    - `macros/` - Write custom macros for reusable SQL patterns

    - `checks/` - Write data quality checks

    - `semantics/` - Semantic layer definitions (measures, dimensions, etc.)

    **Step 2: Verify Your Setup**
    
    Check your project configuration and connection status: [*Learn more about info*](../../cli-command/cli.md#info){:target="_blank"}
    
    ```bash
    vulcan info
    ```
    
    This command displays:

    - Connection status to your database

    - Number of models, macros, and other project components

    - Project configuration details
    
    **Important**: Verify that the setup is correct before proceeding to run plans. If you see any errors, check the Troubleshooting section below.

    **Step 3: Create and Apply Your First Plan**
    
    Generate a plan for your models: [*Learn more about plan*](../../cli-command/cli.md#plan){:target="_blank"}
    
    ```bash
    vulcan plan
    ```
    
    This command performs three key actions:
    
    1. **Validates** your models and creates the necessary database objects (tables, views, etc.)
    2. **Calculates** which data intervals need to be backfilled based on your model's `start` date and `cron` schedule
    3. **Prompts** you to apply the plan
    
    When prompted, enter `y` to apply the plan and backfill your models with historical data.
    
    **Note**: The backfill process may take a few minutes depending on the amount of historical data to process.
        
    **Step 4: Query Your Models**
    
    Execute SQL queries against your models: [*Learn more about fetchdf*](../../cli-command/cli.md#fetchdf){:target="_blank"}
    
    ```bash
    vulcan fetchdf "select * from schema.model_name"
    ```
    
    This command executes a SQL query and returns the results as a pandas DataFrame.

    **Step 5: Query Using Semantic Layer**
    
    Use Vulcan's semantic layer to query your data: [*Learn more about transpile*](../../cli-command/cli.md#transpile){:target="_blank"}
    
    ```bash
    vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"
    ```
    
    This command transpiles your semantic query into SQL that can be executed against your data warehouse. The semantic layer provides a business-friendly interface for querying your data models.

=== "Windows"
    
    **Step 1: Initialize Your Project**
    
    Initialize a new Vulcan project: [*Learn more about init*](../../cli-command/cli.md#init){:target="_blank"}
    
    ```cmd
    vulcan init
    ```
    
    When prompted:

    - Choose `DEFAULT` as the project type

    - Select `Postgres` as your SQL engine
    
    This command creates a complete project structure with 7 directories:

    - `models/` - Contains `.sql` and `.py` files for your data models

    - `seeds/` - CSV files for static datasets

    - `audits/` - Write logic to assert data quality and block downstream models if checks fail

    - `tests/` - Test files for validating your model logic

    - `macros/` - Write custom macros for reusable SQL patterns

    - `checks/` - Write data quality checks

    - `semantics/` - Semantic layer definitions (measures, dimensions, etc.)

    **Step 2: Verify Your Setup**
    
    Check your project configuration and connection status: [*Learn more about info*](../../cli-command/cli.md#info){:target="_blank"}
    
    ```cmd
    vulcan info
    ```
    
    This command displays:

    - Connection status to your database

    - Number of models, macros, and other project components

    - Project configuration details
    
    **Important**: Verify that the setup is correct before proceeding to run plans. If you see any errors, check the Troubleshooting section below.

    **Step 3: Create and Apply Your First Plan**
    
    Generate a plan for your models: [*Learn more about plan*](../../cli-command/cli.md#plan){:target="_blank"}
    
    ```cmd
    vulcan plan
    ```
    
    This command performs three key actions:
    
    1. **Validates** your models and creates the necessary database objects (tables, views, etc.)
    2. **Calculates** which data intervals need to be backfilled based on your model's `start` date and `cron` schedule
    3. **Prompts** you to apply the plan
    
    When prompted, enter `y` to apply the plan and backfill your models with historical data.
    
    **Note**: The backfill process may take a few minutes depending on the amount of historical data to process.
        
    **Step 4: Query Your Models**
    
    Execute SQL queries against your models: [*Learn more about fetchdf*](../../cli-command/cli.md#fetchdf){:target="_blank"}
    
    ```cmd
    vulcan fetchdf "select * from schema.model_name"
    ```
    
    This command executes a SQL query and returns the results as a pandas DataFrame.

    **Step 5: Query Using Semantic Layer**
    
    Use Vulcan's semantic layer to query your data: [*Learn more about transpile*](../../cli-command/cli.md#transpile){:target="_blank"}
    
    ```cmd
    vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"
    ```
    
    This command transpiles your semantic query into SQL that can be executed against your data warehouse. The semantic layer provides a business-friendly interface for querying your data models.

## Stopping Services

When you're done working with Vulcan, you can stop the services to free up system resources. Use the commands below based on your operating system.

=== "Mac/Linux"
    
    **Stop All Services**
    
    To stop all running services:
    
    ```bash
    make all-down       # Stop all services
    ```
    
    **Stop and Clean Up (Warning: This deletes all data)**
    
    To stop all services and remove volumes (this will delete all data):
    
    ```bash
    make all-clean      # Stop and remove volumes (this will delete all data)
    ```
    
    **Stop Individual Service Groups**
    
    You can also stop specific service groups:
    
    ```bash
    make vulcan-down     # Stop only Vulcan API services
    make infra-down      # Stop infrastructure services (statestore, minio)
    make warehouse-down  # Stop warehouse services
    ```

=== "Windows"
    
    **Stop All Services**
    
    To stop all running services:
    
    ```cmd
    stop-all.bat           # Stop all services
    ```
    
    **Stop and Clean Up (Warning: This deletes all data)**
    
    To stop all services and remove volumes (this will delete all data):
    
    ```cmd
    clean.bat              # Stop and remove volumes (this will delete all data)
    ```
    
    **Stop Individual Services**
    
    To stop only the Vulcan API services:
    
    ```cmd
    vulcan-down.bat        # Stop only Vulcan API services
    ```

## Troubleshooting

If you encounter any issues during setup or while using Vulcan, refer to the solutions below.

??? note "Common Issues and Solutions"
    
    **Services Won't Start**
    
    If services fail to start, ensure Docker Desktop is running with at least 4GB RAM allocated. You can check and adjust this in Docker Desktop settings:

    - **Mac**: Docker Desktop → Settings → Resources → Advanced

    - **Windows**: Docker Desktop → Settings → Resources → Advanced
    
    **Network Errors**
    
    If you encounter network-related errors, ensure the `vulcan` Docker network exists:
    
    === "Mac/Linux"
        Check if the network exists:
        ```bash
        docker network ls | grep vulcan
        ```
        If it doesn't exist, create it:
        ```bash
        docker network create vulcan
        ```
    === "Windows"
        Check if the network exists:
        ```cmd
        docker network ls | grep vulcan
        ```
        If it doesn't exist, create it:
        ```cmd
        docker network create vulcan
        ```

    **Port Conflicts**
    
    If you see errors about ports already being in use, one of the required ports (5431, 5433, 9000, 9001, or 8000) is likely occupied by another application. You have two options:
    
    1. **Stop the conflicting application** using that port
    2. **Modify the port mappings** in the Docker Compose files (`docker/docker-compose.infra.yml` and `docker/docker-compose.warehouse.yml`)

    **Can't Connect to Services**
    
    If you're unable to connect to Vulcan services, verify that all required services are running:
    
    ```bash
    docker compose -f docker/docker-compose.infra.yml ps
    docker compose -f docker/docker-compose.warehouse.yml ps
    ```
    
    All services should show as "Up" or "running". If any service shows as "Exited" or "Stopped", check the logs:
    
    ```bash
    docker compose -f docker/docker-compose.infra.yml logs
    ```

    **Access MinIO Console**
    
    You can access the MinIO console to manage your object storage:

    - **URL**: `http://localhost:9001`

    - **Username**: `admin`

    - **Password**: `password`
    
    The MinIO console allows you to browse buckets, upload files, and manage storage policies.


## Next Steps

You've set up Vulcan and created your first project. Here are recommended next steps:

- **[Learn more about Vulcan CLI commands](../../cli-command/cli.md){:target="_blank"}** - Explore all available commands and their options

- **[Explore Vulcan concepts](../../components/model/overview.md){:target="_blank"}** - Deep dive into how models work and how to structure your data pipeline

- **[Read the model kinds documentation](../../components/model/model_kinds.md){:target="_blank"}** - Understand different model types and when to use them
