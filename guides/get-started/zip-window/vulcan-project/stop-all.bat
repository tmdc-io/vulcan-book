@echo off
REM Stop all Vulcan services

echo Stopping Vulcan services...
docker compose -f docker/docker-compose.vulcan.yml down

echo Stopping infrastructure services...
docker compose -f docker/docker-compose.infra.yml down

echo Stopping warehouse services...
docker compose -f docker/docker-compose.warehouse.yml down

echo All services stopped.

