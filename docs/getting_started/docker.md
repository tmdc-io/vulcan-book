# Get Started
Welcome to the Vulcan quickstart, which will get you up and running with an example project.

The example project runs locally on your machine with a Postgres SQL engine, and Vulcan will generate all the necessary project files - no configuration necessary!

All you need to do is download Vulcan on your machine - get started by ensuring your system meets the basic prerequisites for using Vulcan.

## Prerequisites

=== "Mac/Linux"
    1. Docker Desktop is installed and running, at least with 4GB RAM, Verify that Docker is installed and running: 
    ```bash
    docker --version
    docker compose version
    ```
    2. If not Download from [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/){:target="_blank"}

    3. Install Docker Engine and Docker Compose from [Docker for Linux](https://docs.docker.com/engine/install/){:target="_blank"}


=== "Windows"
    1. Docker Desktop for Windows installed and running, at least 4GB RAM, Verify that Docker is installed and running: 
    ```bash
    docker --version
    docker compose version
    ```

    2. If not Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/){:target="_blank"}

<div class="grid" markdown>

<div markdown="1">

## Vulcan Setup Locally

=== "Mac/Linux"
      
    [:material-download: Download for Mac/Linux](zip-mac/vulcan-project.zip){ .md-button .md-button--primary .download-button target="_blank" }
    
    <small>Contains: Docker Compose files, Makefile, and README</small>
        
    1. **Extract the zip file and navigate to the directory:**
       ```bash
       cd vulcan-project
       ```
    
    2. **Run setup:**
       ```bash
       make setup
       ```
       This creates:
        - **statestore** (PostgreSQL): Stores Vulcan's internal state, including model definitions, plan information, & execution history, and Vulcan uses it to persist the semantic model, plans, and track materialization state
        - **minio** (Object Storage): Stores query results, artifacts, and other data objects that Vulcan generates, and 
        Vulcan uses it to store query results and artifacts, enabling efficient data retrieval and caching
        - **minio-init**: Initializes MinIO buckets and policies, and these services are essential for Vulcan's operation and must be running before you can use Vulcan
    
    3. **Access Vulcan:**
       ```bash
       alias vulcan="docker run -it --network=vulcan  --rm -v .:/workspace tmdcio/vulcan:0.225.0-dev-02 vulcan"
       ```
        **Note**: This alias is temporary and will be lost when you close your shell session. To make it permanent, add it to your shell configuration file (~/.bashrc or ~/.zshrc).

    4. **Start API Services:**
       ```bash
       make vulcan-up
       ```
       This starts **vulcan-api** for querying your semantic model by **REST API**(available at `http://localhost:8000`) &
        **vulcan-transpiler** for transpiling semantic queries to SQL

=== "Windows"
        
    [:material-download: Download for Windows](zip-window/vulcan-project.zip){ .md-button .md-button--primary .download-button target="_blank" }
    
    <small>Contains: Docker Compose files, Windows batch scripts, and README</small>
        
    1. **Extract the zip file and navigate to the directory:**
       ```cmd
       cd vulcan-project
       ```
    
    2. **Run setup:**
       ```cmd
       setup.bat
       ```
       This creates:
        - **statestore** (PostgreSQL): Stores Vulcan's internal state, including model definitions, plan information, & execution history, and Vulcan uses it to persist the semantic model, plans, and track materialization state
        - **minio** (Object Storage): Stores query results, artifacts, and other data objects that Vulcan generates, and 
        Vulcan uses it to store query results and artifacts, enabling efficient data retrieval and caching
        - **minio-init**: Initializes MinIO buckets and policies, and these services are essential for Vulcan's operation and must be running before you can use Vulcan
    
    3. **Access Vulcan:**
       ```cmd
       vulcan.bat
       ```

    4. **Start API Services:**
       ```cmd
       start-vulcan-api.bat
       ```
       This starts:

        **vulcan-api** for querying your semantic model by **REST API**(available at `http://localhost:8000`) &

        **vulcan-transpiler** for transpiling semantic queries to SQL

</div>

<div markdown="1">

## Create First Project

=== "Mac/Linux"
    
    1. **Initialize project:** [*Click here*](../reference/cli.md#init){:target="_blank"}
       ```bash
       vulcan init
       ```
       Choose `DEFAULT` project type and `Postgres` as SQL engine. 
       
        It creates 7 `directories` containing SQL/PYTHON models,seed data files, audit files, test files, macro files, checks files, and semantics files

    2. **Check connection and number of models, macros, and other project components:** [*Click here*](../reference/cli.md#info){:target="_blank"}
       ```bash
       vulcan info
       ```
      It verifies that the setup is correct before running plans


    3. **Run the plan:** [*Click here*](../reference/cli.md#plan){:target="_blank"}
       ```bash
       vulcan plan
       ```
      This will:

        1. Validate and creates the necessary database objects (tables, views, etc.) based on your models
        2. Backfills historical data according to your model's `start` date and `cron` schedule
        3. Prompt you to apply the plan

        Enter `y` when prompted to apply the plan and backfill your models.
        
    4. **Query the models:** [*Click here*](../reference/cli.md#fetchdf){:target="_blank"}
       ```bash
       vulcan fetchdf "select * from schema.model_name"
       ```
       Executes a SQL query and returns results as a pandas DataFrame

    5. **Query the Semantic:** [*Click here*](../reference/cli.md#transpile){:target="_blank"}
      ```bash
       vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"
      ```
      Returns the generated SQL that can be executed against your warehouse

=== "Windows"
    
    1. **Initialize project:** [*Click here*](../reference/cli.md#init){:target="_blank"}
       ```cmd
       vulcan init
       ```
       Choose `DEFAULT` project type and `Postgres` as SQL engine. 
       
        It creates 7 `directories` containing SQL/PYTHON models,seed data files, audit files, test files, macro files, checks files, and semantics files

    2. **Check connection and number of models, macros, and other project components:** [*Click here*](../reference/cli.md#info){:target="_blank"}
       ```cmd
       vulcan info
       ```
       It verifies that the setup is correct before running plans

    3. **Run the plan:** [*Click here*](../reference/cli.md#plan){:target="_blank"}
       ```cmd
       vulcan plan
       ```
      This will:

        1. Validate and creates the necessary database objects (tables, views, etc.) based on your models
        2. Backfills historical data according to your model's `start` date and `cron` schedule
        3. Prompt you to apply the plan

        Enter `y` when prompted to apply the plan and backfill your models.
        
    4. **Query the models:** [*Click here*](../reference/cli.md#fetchdf){:target="_blank"}
       ```cmd
       vulcan fetchdf "select * from schema.model_name"
       ```
       Executes a SQL query and returns results as a pandas DataFrame

    5. **Query the Semantic:** [*Click here*](../reference/cli.md#transpile){:target="_blank"}
      ```cmd
       vulcan transpile --format sql "SELECT MEASURE(measure_name) FROM model"
      ```
      Returns the generated SQL that can be executed against your warehouse

</div>

</div>

## Stopping Services

=== "Mac/Linux"
    
    To stop all services:    
    ```bash
    make all-down       # Stop all services
    make all-clean      # Stop and remove volumes (this will delete all data)
    make vulcan-down     # Stop only Vulcan services
    ```
    To stop individual services:
    ```bash
    make vulcan-down     # Stop Vulcan services
    make infra-down      # Stop infrastructure services
    make warehouse-down  # Stop warehouse services
    ```

=== "Windows"
    
    To stop services, you can use batch scripts:
    
    ```cmd
    stop-all.bat           # Stop all services
    clean.bat              # Stop and remove volumes (this will delete all data)
    vulcan-down.bat        # Stop only Vulcan API services
    ```

## Troubleshooting

??? note "Troubleshooting"
    **Services won't start:** Ensure Docker Desktop is running with at least 4GB RAM allocated.

    **Network errors:** Ensure the `vulcan` network exists:
    === "Mac/Linux"
        ```bash
        docker network ls | grep vulcan
        ```
        If it doesn't exist, create it:
        ```bash
        docker network create vulcan
        ```
    === "Windows"
        ```cmd
         docker network ls | grep vulcan
        ```
        If it doesn't exist, create it:
        ```cmd
        docker network create vulcan
        ```

    **Port conflicts:** If ports 5431, 5433, 9000, 9001, or 8000 are already in use, you can modify the port mappings in the Docker Compose files.

    **Can't connect to services:** Make sure all services are running:
    ```bash
    docker compose -f docker/docker-compose.infra.yml ps
    docker compose -f docker/docker-compose.warehouse.yml ps
    ```

    **MinIO console:**
    You can access the MinIO console at `http://localhost:9001` with:
    - Username: `admin`
    - Password: `password`


## Next Steps

- [Learn more about Vulcan CLI commands](../reference/cli.md){:target="_blank"}
- [Explore Vulcan concepts](../concepts/overview.md){:target="_blank"}
- [Set up connections to different warehouses](../guides/connections.md){:target="_blank"}
