---
layout: page
title: Field Notes from the Terminal
description: A markdown-first notebook for Tenzing-generated investment articles, research fragments, and market observations.
permalink: /
---

> A quiet, markdown-first notebook rendered in Nord.

## Current projects

- Publishing investment articles as plain `.md`
- Keeping research lightweight, readable, and versioned
- Building a calm archive instead of a noisy dashboard

---

## Latest dispatches

<ul class="post-list">
  {% for post in site.posts %}
    <li class="post-card">
      <p class="meta-line">{{ post.date | date: "%Y-%m-%d" }}</p>
      <h3><a href="{{ post.url | relative_url }}">{{ post.title }}</a></h3>
      {% if post.summary %}
        <p>{{ post.summary }}</p>
      {% else %}
        <p>{{ post.excerpt | strip_html | strip_newlines | truncate: 180 }}</p>
      {% endif %}
    </li>
  {% endfor %}
</ul>

---

## Posting workflow

1. Drop a new markdown file into `_posts/` using `YYYY-MM-DD-title.md`.
2. Add front matter with `title`, `date`, and an optional `summary` or `tags`.
3. Push to GitHub Pages and let Jekyll rebuild the site.

`bundle exec jekyll serve`
