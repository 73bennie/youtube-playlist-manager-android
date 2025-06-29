#!/usr/bin/env bash
set -euo pipefail

echo -e "${CYAN}=== Diagnose File ===${RESET}"
echo

DB="ytdata/metadata.db"
FILE="$1"

if [[ ! -f "$DB" ]]; then
  echo "❌ Database not found: $DB"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

# Source the sqlite_escape function
source "../lib/sqlite_escape.sh"

# Extract artist, album, title
relpath="${FILE#*/}" # Strip leading ./ if present
artist=$(echo "$relpath" | cut -d'/' -f1)
album=$(echo "$relpath" | cut -d'/' -f2)
filename=$(basename "$relpath")
title=$(echo "$filename" | sed -E 's/^[0-9]+ - //; s/\.opus$//')

echo "🎧 Testing file: $FILE"
echo "🎨 Artist: [$artist]"
echo "📀 Album:  [$album]"
echo "🎵 Title:  [$title]"

# Use sqlite_escape function for proper escaping
sql_artist=$(sqlite_escape "$artist")
sql_album=$(sqlite_escape "$album")
sql_title=$(sqlite_escape "$title")

SQL_QUERY="SELECT id, artist, album, title FROM tracks
WHERE artist = '$sql_artist'
  AND album = '$sql_album'
  AND title = '$sql_title'
COLLATE NOCASE;"

echo "🧪 Running query:"
echo "$SQL_QUERY"
echo

sqlite3 "$DB" "$SQL_QUERY" || echo "⚠️  No results."

