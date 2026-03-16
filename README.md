# Tenzing Field Notes

A GitHub Pages-ready Jekyll site for publishing markdown investment articles with a Nord-inspired console aesthetic.

## Stack

- Jekyll on GitHub Pages
- `remote_theme: b2a3e8/jekyll-theme-console`
- Local layouts and styles tuned for markdown-heavy research notes

## Project structure

- `_config.yml` sets the site metadata, theme, plugins, and post defaults
- `_layouts/` contains local `default`, `page`, and `post` templates
- `assets/custom.scss` holds the Nord palette and markdown styling
- `_posts/` contains dated article markdown files

## Local preview

```bash
bundle install
bundle exec jekyll serve
```

Then open `http://localhost:4000`.

## Publishing a new article

1. Create a new file in `_posts/` named `YYYY-MM-DD-title.md`.
2. Add front matter with at least `title` and `date`.
3. Write the article in markdown.
4. Push to the branch used by GitHub Pages.

## GitHub Pages setup

1. Create a GitHub repository.
2. Push this site to the default branch.
3. In the repository settings, enable GitHub Pages.
4. If you use a project site, set `baseurl` in `_config.yml` to `/repo-name`.
