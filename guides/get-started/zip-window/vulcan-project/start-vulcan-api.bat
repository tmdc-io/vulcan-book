@echo off
REM Start Vulcan API services

echo Starting Vulcan API services...
docker compose -f docker/docker-compose.vulcan.yml up -d
echo Vulcan API is available at http://localhost:8000/redoc

