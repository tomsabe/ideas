#!/usr/bin/env bash
#
# Usage: ./publish.sh temp_article_revised_TICKER.md [YYYY-MM-DD]
#
# Creates a Jekyll blog post from a temp article markdown file.
# - Extracts title from the first "# " line
# - Extracts summary from the first bold (**...**) or italic (*...*) line
# - Generates a slug from the title
# - Strips the duplicate H1, subhead, and leading HR from the body
# - Writes the post to _posts/ with front matter
#
# Date defaults to today if not provided.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: ./publish.sh <markdown-file> [YYYY-MM-DD]"
  exit 1
fi

SOURCE="$1"
DATE="${2:-$(date +%Y-%m-%d)}"

if [[ ! -f "$SOURCE" ]]; then
  echo "Error: file not found: $SOURCE"
  exit 1
fi

# Extract title from first H1 line
TITLE=$(grep -m1 '^# ' "$SOURCE" | sed 's/^# //')
if [[ -z "$TITLE" ]]; then
  echo "Error: no H1 title found in $SOURCE"
  exit 1
fi

# Extract summary from first bold or italic line (strip markers)
SUMMARY=$(grep -m1 '^\*\*\|^\*[^*]' "$SOURCE" | sed 's/^\*\*//;s/\*\*$//;s/^\*//;s/\*$//')

# Generate slug from title
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

# Truncate slug to something reasonable
SLUG=$(echo "$SLUG" | cut -c1-60 | sed 's/-$//')

OUTFILE="_posts/${DATE}-${SLUG}.md"

if [[ -f "$OUTFILE" ]]; then
  echo "Error: $OUTFILE already exists"
  exit 1
fi

# Build the post: front matter + body with duplicate header stripped
{
  echo "---"
  echo "title: \"$(echo "$TITLE" | sed 's/"/\\"/g')\""
  echo "date: $DATE"
  if [[ -n "$SUMMARY" ]]; then
    echo "summary: \"$(echo "$SUMMARY" | sed 's/"/\\"/g')\""
  fi
  echo "tags:"
  echo "  - equities"
  echo "---"
  echo ""

  # Skip everything up to and including the first "---" line after the H1/subhead block,
  # then emit the rest of the file
  awk '
    BEGIN { skipping=1; found_hr=0 }
    skipping && /^# /    { next }
    skipping && /^\*\*/  { next }
    skipping && /^\*[^*]/{ next }
    skipping && /^---$/  { found_hr=1; next }
    skipping && /^$/     { next }
    { skipping=0; print }
  ' "$SOURCE"
} > "$OUTFILE"

echo "Published: $OUTFILE"
echo "  Title: $TITLE"
echo "  Date:  $DATE"
