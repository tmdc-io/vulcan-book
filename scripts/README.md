# Scripts

This directory contains utility scripts for maintaining the documentation.

## update_docker_images.py

Automatically updates Docker image versions in `docs/guides/get-started/docker.md` by extracting the latest versions from engine configuration files in `docs/configurations/engines/`.

### Usage

```bash
python3 scripts/update_docker_images.py
```

### How it works

1. Scans all engine configuration files in `docs/configurations/engines/`
2. Extracts Docker image versions using regex pattern matching
3. Updates the corresponding alias commands in `docs/guides/get-started/docker.md`

### When it runs

The script runs automatically:
- Before starting the MkDocs development server (`make serve`)
- Before building the static site (`make build`)

You can also run it manually using:
```bash
make update-images
```

### Supported engines

- Postgres
- BigQuery
- Databricks
- Fabric
- MSSQL
- MySQL
- Redshift
- Snowflake
- Spark
- Trino

### Requirements

- Python 3.9+
- No additional dependencies (uses only standard library)
