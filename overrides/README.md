# Theme Overrides

This directory is used for customizing the MkDocs Material theme.

## Usage

Place custom theme files here to override the default Material theme:

- **CSS**: `main.html` or `partials/` directory for HTML partials
- **JavaScript**: Custom JS files referenced in `main.html`
- **Assets**: Images, fonts, etc.

## Examples

### Custom CSS

Create `main.html`:
```html
{% extends "base.html" %}
{% block styles %}
  {{ super() }}
  <link rel="stylesheet" href="{{ 'assets/css/custom.css' | url }}">
{% endblock %}
```

### Custom Footer

Create `partials/footer.html`:
```html
{% import "partials/footer.html" as footer %}
{{ footer.footer() }}
```

## Documentation

See [MkDocs Material documentation](https://squidfunk.github.io/mkdocs-material/customization/) for more details.

