@echo off
REM Start Vulcan API services

echo Down Vulcan API services...
docker compose -f docker/docker-compose.vulcan.yml down -v


