---
layout: page
title: About
description: Why this site exists and how articles should be structured.
permalink: /about/
---

This site is designed for investment writing that starts life as markdown and stays readable all the way to production.

## Writing conventions

- Use one file per article in `_posts/`
- Keep opening summaries short and specific
- Prefer tables, bullets, and short sections over long walls of text
- Treat blockquotes as side notes, assumptions, or model caveats

## Front matter template

```yaml
---
title: "Article title"
date: 2026-03-16
summary: One-sentence takeaway for the homepage.
tags:
  - equities
  - software
  - valuation
---
```

## Publishing note

If you publish this as a project site instead of `username.github.io`, set `baseurl` in [`_config.yml`](/Users/toms/GitHub/ideas/_config.yml) to the repository name before deploying.
