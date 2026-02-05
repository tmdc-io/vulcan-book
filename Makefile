PYTHON := python3
VENV := venv
PIP := $(VENV)/bin/pip
MKDOCS := $(VENV)/bin/mkdocs

.PHONY: setup venv install serve build deploy clean

setup: venv install ## Complete setup (venv + install)

venv: ## Create virtual environment
	@if [ ! -d "$(VENV)" ]; then \
		$(PYTHON) -m venv $(VENV); \
	fi

install: venv ## Install dependencies from pyproject.toml
	@$(PIP) install --upgrade pip setuptools
	@$(PIP) install -e .

update-images: ## Update Docker image versions in docker.md from engine configs
	@echo "Updating Docker image versions in docker.md..."
	@$(PYTHON) scripts/update_docker_images.py

serve: venv update-images ## Start development server
	@echo "Starting MkDocs server at http://127.0.0.1:7000/"
	@echo "Note: Access the site at http://127.0.0.1:7000/ (root path) for local development"
	@$(MKDOCS) serve --dev-addr 127.0.0.1:7000 --livereload

build: venv update-images ## Build static site
	@$(MKDOCS) build

deploy: venv ## Deploy to GitHub Pages
	@echo "Deploying to GitHub Pages..."
	@$(MKDOCS) gh-deploy --force --ignore-version
	@echo "Deployed to GitHub Pages!$(NC)"

clean: ## Clean generated files
	@rm -rf site/ .cache

