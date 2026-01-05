#!/bin/bash
# TovPlay Deployment Change Documentation Generator
# Tracks every change with original file creator for full team visibility

set -e

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
ENV_NAME="${2:-staging}"
COMMIT_SHA=$(git rev-parse HEAD)
COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an")
COMMIT_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 סיכום שינויים - TovPlay ${ENV_NAME^^}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔹 Environment: ${ENV_NAME}"
echo "🔹 Branch: ${BRANCH}"
echo "🔹 Commit: ${COMMIT_SHA}"
echo "🔹 Deployer: ${COMMIT_AUTHOR}"
echo "🔹 Time: ${COMMIT_DATE}"
echo ""

# Get commit message
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 תיאור השינוי:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git log -1 --pretty=format:"%B" | fold -w 76 -s
echo ""
echo ""

# Calculate statistics
ADDED=$(git diff HEAD~1 HEAD --numstat 2>/dev/null | awk '{add+=$1} END {print add+0}')
DELETED=$(git diff HEAD~1 HEAD --numstat 2>/dev/null | awk '{del+=$2} END {print del+0}')
FILES=$(git diff HEAD~1 HEAD --name-only 2>/dev/null | wc -l)
NET=$((ADDED - DELETED))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 תקציר:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $NET -lt 0 ]; then
  echo "עשיתי רפקטור: ${NET} שורות"
else
  echo "הוספתי: +${NET} שורות"
fi
echo "📊 קבצים שונו: ${FILES}"
echo "➕ שורות נוספו: ${ADDED}"
echo "➖ שורות נמחקו: ${DELETED}"
echo ""

# Group changes by original file author
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 מה עשיתי לפי יוצר מקורי:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create temp file for tracking authors and their file changes
TEMP_FILE=$(mktemp)

# Get all changed files with their status
git diff --name-status HEAD~1 HEAD 2>/dev/null | while IFS=$'\t' read -r status file; do
  if [ -z "$file" ]; then continue; fi

  # Get original author (first person to create/add the file)
  ORIGINAL_AUTHOR=""
  if [ "$status" != "D" ]; then
    # File exists, get original author from first commit that added it
    ORIGINAL_AUTHOR=$(git log --follow --format="%an" --diff-filter=A -- "$file" 2>/dev/null | tail -1)
  else
    # File was deleted, get last known author before deletion
    ORIGINAL_AUTHOR=$(git log -1 --format="%an" HEAD~1 -- "$file" 2>/dev/null)
  fi

  # If we couldn't find author, try alternative method
  if [ -z "$ORIGINAL_AUTHOR" ]; then
    ORIGINAL_AUTHOR=$(git log --format="%an" -- "$file" 2>/dev/null | tail -1)
  fi

  # Default to "Unknown" if still no author found
  if [ -z "$ORIGINAL_AUTHOR" ]; then
    ORIGINAL_AUTHOR="Unknown"
  fi

  # Get line changes for this file
  LINE_CHANGES=$(git diff HEAD~1 HEAD --numstat -- "$file" 2>/dev/null | awk '{print $1 "+" $2 "-"}')

  # Determine change type
  case "$status" in
    A) CHANGE_TYPE="✅ נוסף" ;;
    M) CHANGE_TYPE="✏️  שונה" ;;
    D) CHANGE_TYPE="❌ נמחק" ;;
    R*) CHANGE_TYPE="📦 שונה שם" ;;
    *) CHANGE_TYPE="$status" ;;
  esac

  echo "${ORIGINAL_AUTHOR}|${CHANGE_TYPE}|${file}|${LINE_CHANGES}" >> "$TEMP_FILE"
done

# Sort by author and display grouped results
if [ -s "$TEMP_FILE" ]; then
  # Get unique authors and their total line changes
  declare -A author_lines

  while IFS='|' read -r author change_type file line_changes; do
    if [ -n "$author" ]; then
      # Extract added/deleted from line_changes (format: 123+456-)
      added=$(echo "$line_changes" | sed 's/+.*//')
      deleted=$(echo "$line_changes" | sed 's/.*+//;s/-.*//')

      # Initialize if not exists
      if [ -z "${author_lines[$author]}" ]; then
        author_lines[$author]="0+0-"
      fi

      # Get current totals
      current=$(echo "${author_lines[$author]}" | sed 's/+.*//')
      current_del=$(echo "${author_lines[$author]}" | sed 's/.*+//;s/-.*//')

      # Add to totals
      new_total=$((current + added))
      new_del=$((current_del + deleted))
      author_lines[$author]="${new_total}+${new_del}-"
    fi
  done < "$TEMP_FILE"

  # Display each author's changes
  for author in $(cat "$TEMP_FILE" | cut -d'|' -f1 | sort -u); do
    if [ -z "$author" ]; then continue; fi

    # Get total lines for this author
    total_lines="${author_lines[$author]}"
    added=$(echo "$total_lines" | sed 's/+.*//')
    deleted=$(echo "$total_lines" | sed 's/.*+//;s/-.*//')
    net=$((added - deleted))

    echo "### ${author} - ${net} שורות (${added}+ ${deleted}-)"
    echo ""

    # Show all files modified by this author
    grep "^${author}|" "$TEMP_FILE" | while IFS='|' read -r auth change_type file line_changes; do
      echo "${change_type}: \`${file}\` (${line_changes})"

      # Try to explain WHY this change matters
      case "$file" in
        *package.json|*requirements.txt|*Pipfile|*poetry.lock)
          echo "   └─ למה: שינוי תלויות - עדכון ספריות"
          ;;
        *migrations/*|*alembic/*)
          echo "   └─ למה: שינוי מבנה DB - עדכון טבלאות"
          ;;
        *.env*|*.config.*|*docker*)
          echo "   └─ למה: קונפיגורציה - הגדרות סביבה"
          ;;
        *routes*|*api*)
          echo "   └─ למה: API - שינוי endpoints"
          ;;
        *test*|*spec*)
          echo "   └─ למה: Tests - בדיקות אוטומטיות"
          ;;
        *.github/workflows/*)
          echo "   └─ למה: CI/CD - פרוצס deployment"
          ;;
        *monitoring*|*metrics*|*health*)
          echo "   └─ למה: Monitoring - מעקב ביצועים"
          ;;
        *auth*|*login*|*user*)
          echo "   └─ למה: Authentication - ניהול משתמשים"
          ;;
      esac
    done
    echo ""
  done
else
  echo "⚠️  לא נמצאו שינויים"
fi

rm -f "$TEMP_FILE"

# Show detailed file stats
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 סטטיסטיקה מפורטת:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git diff --stat HEAD~1 HEAD 2>/dev/null || git show --stat
echo ""

# Critical changes detection
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  שינויים קריטיים:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CRITICAL_FOUND=0

# Check for dependency changes
if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -qE "package.json|requirements.txt|Pipfile|poetry.lock"; then
  echo "📦 שינוי תלויות - יש לבדוק compatibility"
  git diff HEAD~1 HEAD --name-only | grep -E "package.json|requirements.txt|Pipfile|poetry.lock"
  CRITICAL_FOUND=1
fi

# Check for database migrations
if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -qE "migrations/|alembic/"; then
  echo "🗄️  שינוי DB - לוודא backup לפני deploy"
  git diff HEAD~1 HEAD --name-only | grep -E "migrations/|alembic/"
  CRITICAL_FOUND=1
fi

# Check for config changes
if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -qE "\.env|\.config\.|docker|nginx"; then
  echo "🔐 שינוי קונפיג - לבדוק environment variables"
  git diff HEAD~1 HEAD --name-only | grep -E "\.env|\.config\.|docker|nginx"
  CRITICAL_FOUND=1
fi

# Check for auth/security changes
if git diff HEAD~1 HEAD --name-only 2>/dev/null | grep -qE "auth|security|jwt|oauth"; then
  echo "🔒 שינוי אבטחה - לבדוק authentication flow"
  git diff HEAD~1 HEAD --name-only | grep -E "auth|security|jwt|oauth"
  CRITICAL_FOUND=1
fi

if [ $CRITICAL_FOUND -eq 0 ]; then
  echo "✅ אין שינויים קריטיים - deploy בטוח"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ סיכום הושלם - מוכן ל-${ENV_NAME} deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
