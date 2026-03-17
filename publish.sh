#!/usr/bin/env bash
#
# Usage:
#   ./publish.sh                          # scan for new articles, prompt to publish
#   ./publish.sh <markdown-file> [DATE]   # publish a specific file
#
# Creates Jekyll blog posts from Tenzing temp article markdown files.
# - Extracts title from the first "# " line
# - Extracts summary from the first bold (**...**) or italic (*...*) line
# - Generates a slug from the title
# - Strips the duplicate H1, subhead, and leading HR from the body
# - Asks if the author holds the security and updates the disclaimer
# - Writes the post to _posts/ with front matter
#
# Date defaults to today if not provided.

set -euo pipefail

TENZING_DIR="../tenzing-master/tenzing-python/agents"
POSTS_DIR="_posts"

# Track published files for git commit
PUBLISHED_FILES=()

# --- Publish a single file ---
publish_file() {
  local SOURCE="$1"
  local DATE="$2"

  if [[ ! -f "$SOURCE" ]]; then
    echo "Error: file not found: $SOURCE"
    return 1
  fi

  # Extract title from first H1 line
  local TITLE
  TITLE=$(grep -m1 '^# ' "$SOURCE" | sed 's/^# //')
  if [[ -z "$TITLE" ]]; then
    echo "Error: no H1 title found in $SOURCE"
    return 1
  fi

  # Extract summary from first bold or italic line (strip markers)
  local SUMMARY
  SUMMARY=$(grep -m1 '^\*\*\|^\*[^*]' "$SOURCE" | sed 's/^\*\*//;s/\*\*$//;s/^\*//;s/\*$//')

  # Generate slug from title
  local SLUG
  SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
  SLUG=$(echo "$SLUG" | cut -c1-60 | sed 's/-$//')

  local OUTFILE="${POSTS_DIR}/${DATE}-${SLUG}.md"

  if [[ -f "$OUTFILE" ]]; then
    echo "Error: $OUTFILE already exists"
    return 1
  fi

  # Ask about ownership
  echo ""
  echo "  Title: $TITLE"
  echo "  Date:  $DATE"
  echo ""
  local OWNS
  read -rp "Do you hold a position in this security? (y/n): " OWNS

  local STANDARD_DISCLOSURE="*Disclosure: This article is for informational purposes only. It does not constitute investment advice. Investors should conduct their own due diligence before making investment decisions.*"
  local DISCLOSURE

  if [[ "$OWNS" =~ ^[Yy] ]]; then
    DISCLOSURE="*Disclosure: Tom Saberhagen held a position in this security as of the date of publication. This article is for informational purposes only. It does not constitute investment advice. Investors should conduct their own due diligence before making investment decisions.*"
  else
    DISCLOSURE="$STANDARD_DISCLOSURE"
  fi

  # Build the post: front matter + body with duplicate header stripped and disclaimer updated
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

    awk '
      BEGIN { skipping=1; found_hr=0 }
      skipping && /^# /    { next }
      skipping && /^\*\*/  { next }
      skipping && /^\*[^*]/{ next }
      skipping && /^---$/  { found_hr=1; next }
      skipping && /^$/     { next }
      { skipping=0; print }
    ' "$SOURCE" | sed "s|^\\*Disclosure: This article is for informational purposes only.*|$DISCLOSURE|"
  } > "$OUTFILE"

  PUBLISHED_FILES+=("$OUTFILE")
  echo ""
  echo "Published: $OUTFILE"
}

# --- Git commit and push all published posts ---
git_push() {
  if [[ ${#PUBLISHED_FILES[@]} -eq 0 ]]; then
    return
  fi

  echo ""
  echo "--- Pushing to GitHub Pages ---"

  git add "${PUBLISHED_FILES[@]}"

  if [[ ${#PUBLISHED_FILES[@]} -eq 1 ]]; then
    # Single post: use the article title in the commit message
    local title
    title=$(grep -m1 '^title:' "${PUBLISHED_FILES[0]}" | sed 's/^title: *"*//;s/"*$//')
    git commit -m "Publish: ${title}"
  else
    git commit -m "Publish ${#PUBLISHED_FILES[@]} new Tenzing articles"
  fi

  git push origin main
  echo ""
  echo "Pushed ${#PUBLISHED_FILES[@]} post(s) to GitHub Pages."
}

# --- Scan mode: find new articles not yet posted ---
scan_and_publish() {
  local DATE="${1:-$(date +%Y-%m-%d)}"

  if [[ ! -d "$TENZING_DIR" ]]; then
    echo "Error: Tenzing directory not found: $TENZING_DIR"
    exit 1
  fi

  # Collect titles already published
  local -a EXISTING_TITLES=()
  for post in "$POSTS_DIR"/*.md; do
    [[ -f "$post" ]] || continue
    local t
    t=$(grep -m1 '^title:' "$post" | sed 's/^title: *"*//;s/"*$//')
    EXISTING_TITLES+=("$t")
  done

  # Find revised articles with titles not yet published
  local -a NEW_FILES=()
  local -a NEW_TITLES=()

  for candidate in "$TENZING_DIR"/temp_article_revised_*.md; do
    [[ -f "$candidate" ]] || continue
    local ctitle
    ctitle=$(grep -m1 '^# ' "$candidate" | sed 's/^# //')
    [[ -z "$ctitle" ]] && continue

    local already=0
    for existing in "${EXISTING_TITLES[@]}"; do
      if [[ "$existing" == "$ctitle" ]]; then
        already=1
        break
      fi
    done

    if [[ $already -eq 0 ]]; then
      NEW_FILES+=("$candidate")
      NEW_TITLES+=("$ctitle")
    fi
  done

  if [[ ${#NEW_FILES[@]} -eq 0 ]]; then
    echo "No new articles to publish."
    exit 0
  fi

  echo ""
  echo "New articles found:"
  echo ""
  for i in "${!NEW_FILES[@]}"; do
    echo "  $((i+1)). ${NEW_TITLES[$i]}"
  done
  echo ""
  echo "  a. Publish all"
  echo "  q. Quit"
  echo ""
  read -rp "Select (number, 'a' for all, 'q' to quit): " CHOICE

  if [[ "$CHOICE" == "q" ]]; then
    exit 0
  elif [[ "$CHOICE" == "a" ]]; then
    for i in "${!NEW_FILES[@]}"; do
      publish_file "${NEW_FILES[$i]}" "$DATE"
    done
  elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#NEW_FILES[@]} )); then
    publish_file "${NEW_FILES[$((CHOICE-1))]}" "$DATE"
  else
    echo "Invalid selection."
    exit 1
  fi
}

# --- Main ---
if [[ $# -ge 1 && -f "$1" ]]; then
  # Direct file mode
  DATE="${2:-$(date +%Y-%m-%d)}"
  publish_file "$1" "$DATE"
else
  # Scan mode
  scan_and_publish "${1:-}"
fi

git_push
