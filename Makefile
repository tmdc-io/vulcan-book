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

serve: venv ## Start development server
	@$(MKDOCS) serve

build: venv ## Build static site
	@$(MKDOCS) build

deploy: venv ## Deploy to GitHub Pages
	@$(MKDOCS) gh-deploy --force --ignore-version

clean: ## Clean generated files
	@rm -rf site/ .cache

