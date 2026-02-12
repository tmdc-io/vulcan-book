#!/usr/bin/env python3
"""
Script to automatically update Docker image versions in docker.md
by extracting versions from engine configuration files.
"""

import re
import os
from pathlib import Path
from typing import Dict, Optional

# Mapping of engine names to their display names and file paths
ENGINE_MAPPING = {
    "postgres": {"display": "Postgres (Default)", "file": "postgres/postgres.md"},
    "bigquery": {"display": "BigQuery", "file": "bigquery/bigquery.md"},
    "databricks": {"display": "Databricks", "file": "databricks/databricks.md"},
    "fabric": {"display": "Fabric", "file": "fabric/fabric.md"},
    "mssql": {"display": "MSSQL", "file": "mssql/mssql.md"},
    "mysql": {"display": "MySQL", "file": "mysql/mysql.md"},
    "redshift": {"display": "Redshift", "file": "redshift/redshift.md"},
    "snowflake": {"display": "Snowflake", "file": "snowflake/snowflake.md"},
    "spark": {"display": "Spark", "file": "spark/spark.md"},
    "trino": {"display": "Trino", "file": "trino/trino.md"},
}


def extract_image_version(engine_file: Path, engine_name: str) -> Optional[str]:
    """
    Extract Docker image version from an engine configuration file.
    
    Args:
        engine_file: Path to the engine markdown file
        engine_name: Name of the engine (e.g., 'postgres', 'bigquery')
    
    Returns:
        Version string (e.g., '0.228.1.8') or None if not found
    """
    if not engine_file.exists():
        print(f"Warning: Engine file not found: {engine_file}")
        return None
    
    content = engine_file.read_text()
    
    # Pattern to match: tmdcio/vulcan-{engine}:{version}
    pattern = rf"tmdcio/vulcan-{re.escape(engine_name)}:([\d.]+)"
    match = re.search(pattern, content)
    
    if match:
        return match.group(1)
    
    print(f"Warning: Could not find image version for {engine_name} in {engine_file}")
    return None


def update_docker_md(docker_md_path: Path, versions: Dict[str, str]) -> bool:
    """
    Update docker.md with the latest image versions.
    
    Args:
        docker_md_path: Path to docker.md file
        versions: Dictionary mapping engine names to versions
    
    Returns:
        True if file was updated, False otherwise
    """
    if not docker_md_path.exists():
        print(f"Error: docker.md not found at {docker_md_path}")
        return False
    
    content = docker_md_path.read_text()
    original_content = content
    
    # Update each engine's alias command
    for engine_name, engine_info in ENGINE_MAPPING.items():
        version = versions.get(engine_name)
        
        if not version:
            print(f"Warning: No version found for {engine_name}, skipping update")
            continue
        
        # Simple pattern to match the Docker image version in alias commands
        # Matches: tmdcio/vulcan-{engine}:{old_version} vulcan"
        pattern = rf'(tmdcio/vulcan-{re.escape(engine_name)}:)([\d.]+)( vulcan")'
        
        def replace_version(match):
            old_version = match.group(2)
            if old_version != version:
                print(f"  Updating {engine_name}: {old_version} -> {version}")
            return f'{match.group(1)}{version}{match.group(3)}'
        
        content = re.sub(pattern, replace_version, content)
    
    if content != original_content:
        docker_md_path.write_text(content)
        print(f"Successfully updated {docker_md_path}")
        return True
    else:
        print("No changes needed in docker.md")
        return False


def main():
    """Main function to extract versions and update docker.md"""
    # Get the project root (assuming script is in scripts/ directory)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    engines_dir = project_root / "docs" / "configurations" / "engines"
    docker_md_path = project_root / "docs" / "guides" / "get-started" / "docker.md"
    
    if not engines_dir.exists():
        print(f"Error: Engines directory not found: {engines_dir}")
        return 1
    
    if not docker_md_path.exists():
        print(f"Error: docker.md not found: {docker_md_path}")
        return 1
    
    # Extract versions from all engine files
    versions = {}
    for engine_name, engine_info in ENGINE_MAPPING.items():
        engine_file = engines_dir / engine_info["file"]
        version = extract_image_version(engine_file, engine_name)
        if version:
            versions[engine_name] = version
            print(f"Found {engine_name}: {version}")
    
    if not versions:
        print("Error: No versions found in any engine files")
        return 1
    
    # Update docker.md
    updated = update_docker_md(docker_md_path, versions)
    
    return 0 if updated or len(versions) > 0 else 1


if __name__ == "__main__":
    exit(main())
