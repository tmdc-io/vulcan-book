PYTHON := python3
VENV := venv
PIP := $(VENV)/bin/pip
MKDOCS := $(VENV)/bin/mkdocs

# Colors for pretty output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m # No Color

.PHONY: setup venv install serve build deploy clean

setup: venv install ## Complete setup (venv + install)

venv: ## Create virtual environment
	@if [ ! -d "$(VENV)" ]; then \
		$(PYTHON) -m venv $(VENV); \
	fi

install: venv ## Install dependencies from pyproject.toml
	@$(PIP) install --upgrade pip setuptools
	@$(PIP) install -e .

serve: venv ## Start development server
	@$(MKDOCS) serve

build: venv ## Build static site
	@$(MKDOCS) build

deploy: venv ## Deploy to GitHub Pages
	@echo "$(BLUE)Deploying to GitHub Pages...$(NC)"
	@if [ ! -d ".git" ]; then \
		echo "$(RED)Not a git repository. Initialize git first:$(NC)"; \
		echo "$(CYAN)   git init$(NC)"; \
		echo "$(CYAN)   git remote add origin git@github.com:tmdc-io/vulcan-book.git$(NC)"; \
		exit 1; \
	fi
	@$(MKDOCS) gh-deploy --force --ignore-version
	@echo "$(GREEN)Deployed to GitHub Pages!$(NC)"

clean: ## Clean generated files
	@rm -rf site/ .cache

