@echo off
REM Stop all services and remove volumes

call stop-all.bat

echo Removing all Docker volumes...
docker compose -f docker/docker-compose.infra.yml down -v
docker compose -f docker/docker-compose.warehouse.yml down -v
docker compose -f docker/docker-compose.vulcan.yml down -v

echo All volumes removed.

