# Vulcan Book

Documentation for Vulcan - built with MkDocs.

## Quick Start

```bash
make setup    # First time setup
make serve    # Start development server
make build    # Build static site
make deploy   # Deploy to GitHub Pages
```

## Structure

- `docs/` - Documentation source files
- `draft/` - Draft and reference materials
- `mkdocs.yml` - MkDocs configuration
- `pyproject.toml` - Python dependencies

## Development

The development server runs at `http://127.0.0.1:8000` and automatically reloads on file changes.

## Deployment

Deploy to GitHub Pages:

```bash
make deploy
```

This will build the site and push it to the `gh-pages` branch. Configure GitHub Pages in repository settings to use the `gh-pages` branch as the source.

The site will be available at: `https://tmdc-io.github.io/vulcan-book`

