@echo off
REM Vulcan Docker Quickstart - Windows Setup Script

echo Creating external Docker network 'vulcan'...
docker network create vulcan 2>nul || echo Network 'vulcan' already exists

echo Starting infrastructure services...
docker compose -f docker/docker-compose.infra.yml up -d

echo Starting warehouse database...
docker compose -f docker/docker-compose.warehouse.yml up -d

echo Setup complete! Infrastructure and warehouse are running.
echo You can now use Vulcan commands.

