# Vulcan Postgres — local Docker stack.
#
# One command:  make up
# CLI:          make vulcan-cli CMD="plan"
#
VULCAN_IMAGE ?= tmdcio/vulcan-postgres:0.228.1.15

VULCAN_DOCKER_COMMON = docker run -it --rm --network=vulcan \
	-v "$$(pwd):/workspace" -w /workspace \
	-e STATESTORE_HOST=statestore \
	-e STATESTORE_PORT=5432 \
	-e POSTGRES_HOST=warehouse \
	-e POSTGRES_PORT=5432 \
	-e POSTGRES_DATABASE=warehouse \
	-e POSTGRES_USER=vulcan \
	-e POSTGRES_PASSWORD=vulcan \
	-e MINIO_ENDPOINT=http://minio:9000 \
	-e VULCAN__TRANSPILER__BASE_URL=http://vulcan-transpiler-api:8100 \
	-e VULCAN__GRAPHQL__BASE_URL=http://vulcan-graphql:3000 \
	$(VULCAN_IMAGE)

.PHONY: help up down network certs infra transpiler transpiler-down setup \
	vulcan-cli vulcan-api-docker vulcan-up vulcan-down \
	proxy-up proxy-down infra-down all-down all-clean

DOCKER_COMPOSE = docker compose

help: ## Show targets
	@echo 'Vulcan Postgres — local Docker stack'
	@echo 'Image: $(VULCAN_IMAGE)'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-22s %s\n", $$1, $$2}'

vulcan-cli: ## Run CLI in Docker: make vulcan-cli CMD="plan"
	@test -n "$(CMD)" || (echo 'Usage: make vulcan-cli CMD="plan"' && exit 1)
	$(VULCAN_DOCKER_COMMON) vulcan -p . $(CMD)

vulcan-api-docker: ## Vulcan API :8000 standalone (needs infra + transpiler)
	docker run -it --rm --network=vulcan \
		-v "$$(pwd):/workspace" -w /workspace \
		-e STATESTORE_HOST=statestore \
		-e STATESTORE_PORT=5432 \
		-e POSTGRES_HOST=warehouse \
		-e POSTGRES_PORT=5432 \
		-e POSTGRES_DATABASE=warehouse \
		-e POSTGRES_USER=vulcan \
		-e POSTGRES_PASSWORD=vulcan \
		-e MINIO_ENDPOINT=http://minio:9000 \
		-e VULCAN__TRANSPILER__BASE_URL=http://vulcan-transpiler-api:8100 \
		-e VULCAN__GRAPHQL__BASE_URL=http://vulcan-graphql:3000 \
		-p 8000:8000 \
		$(VULCAN_IMAGE) vulcan -p . api --host 0.0.0.0 --port 8000

up: ## Start everything (infra → transpiler → vulcan → proxy)
	$(MAKE) network
	$(MAKE) certs
	$(MAKE) infra
	$(MAKE) transpiler
	$(MAKE) vulcan-up
	$(MAKE) proxy-up
	@echo ""
	@echo "  Vulcan API   http://localhost:8000/redoc"
	@echo "  GraphQL      http://localhost:3000"
	@echo "  Transpiler   http://localhost:8100"
	@echo "  MinIO        http://localhost:9001"
	@echo "  Warehouse PG postgresql://vulcan:vulcan@localhost:5434/warehouse"
	@echo ""
	@echo "  CLI:  make vulcan-cli CMD=\"plan\""

down: all-down ## Stop everything

certs:
	@mkdir -p docker/ssl
	@if [ -f docker/ssl/server.crt ] && [ -f docker/ssl/server.key ]; then \
		echo "docker/ssl/server.crt present — skip"; \
	else \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout docker/ssl/server.key -out docker/ssl/server.crt \
			-subj "/CN=vulcan-mysql" 2>/dev/null; \
		echo "Created docker/ssl/server.crt"; \
	fi

network:
	@docker network create vulcan 2>/dev/null || true

infra: network ## Statestore + warehouse Postgres + MinIO
	$(DOCKER_COMPOSE) -p vulcan-statestore -f docker/docker-compose.infra.yml up -d --quiet-pull

transpiler: network ## Transpiler API :8100
	$(DOCKER_COMPOSE) -p vulcan-transpiler -f docker/docker-compose.transpiler.yml up -d --quiet-pull

transpiler-down:
	$(DOCKER_COMPOSE) -p vulcan-transpiler -f docker/docker-compose.transpiler.yml down

setup: network infra transpiler ## Infra + transpiler only

vulcan-up: ## Vulcan API + GraphQL + MySQL wire
	@test -f docker/ssl/server.crt || ($(MAKE) certs)
	$(DOCKER_COMPOSE) -f docker/docker-compose.vulcan.yml up -d

vulcan-down:
	$(DOCKER_COMPOSE) -f docker/docker-compose.vulcan.yml down

proxy-up: network certs ## MySQL proxy :3306
	$(DOCKER_COMPOSE) -p vulcan-proxy -f docker/docker-compose.proxy.yml up -d --quiet-pull

proxy-down:
	$(DOCKER_COMPOSE) -p vulcan-proxy -f docker/docker-compose.proxy.yml down

infra-down:
	$(DOCKER_COMPOSE) -p vulcan-statestore -f docker/docker-compose.infra.yml down

all-down: proxy-down vulcan-down transpiler-down infra-down ## Stop all stacks
	@echo "Stopped."

all-clean: all-down ## Stop all + remove volumes
	@$(DOCKER_COMPOSE) -p vulcan-proxy -f docker/docker-compose.proxy.yml down -v 2>/dev/null || true
	@$(DOCKER_COMPOSE) -p vulcan-transpiler -f docker/docker-compose.transpiler.yml down -v 2>/dev/null || true
	@$(DOCKER_COMPOSE) -p vulcan-statestore -f docker/docker-compose.infra.yml down -v 2>/dev/null || true
	@$(DOCKER_COMPOSE) -f docker/docker-compose.vulcan.yml down -v 2>/dev/null || true
	@echo "Volumes removed."
