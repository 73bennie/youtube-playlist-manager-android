#!/usr/bin/env bash
set -euo pipefail

# Source the sqlite_escape function
source "../lib/sqlite_escape.sh"

declare -A NOT_FOUND_ALBUMS

DB="ytdata/metadata.db"
LIST="$HOME/storage/shared/Documents/MyMusic.txt"
DRYRUN=0
LOG_MATCHED="matched.log"
LOG_UNMATCHED="unmatched.log"
LOG_DEBUG="debug.log"

# Parse flags
if [[ "${1:-}" == "--dry-run" ]]; then
  DRYRUN=1
  echo "🔍 Running in DRY-RUN mode — no changes will be made." | tee "$LOG_DEBUG"
else
  echo "✅ Running in LIVE mode — database will be updated." | tee "$LOG_DEBUG"
fi

# Empty logs
: > "$LOG_MATCHED"
: > "$LOG_UNMATCHED"

# Read each line of the music file
while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  # Extract artist, album, title
  artist=$(echo "$line" | cut -d'/' -f1)
  album=$(echo "$line" | cut -d'/' -f2)
  file=$(basename "$line")
  title=$(echo "$file" | sed -E 's/^[0-9]+ - //; s/\.opus$//')

  echo "🔎 Matching: artist=[$artist] album=[$album] title=[$title]" >> "$LOG_DEBUG"

  # Use sqlite_escape function for proper escaping
  sql_artist=$(sqlite_escape "$artist")
  sql_album=$(sqlite_escape "$album")
  sql_title=$(sqlite_escape "$title")

  # Check match
  match=$(sqlite3 "$DB" "
    SELECT COUNT(*) FROM tracks
    WHERE artist = '$sql_artist'
      AND album = '$sql_album'
      AND title = '$sql_title'
    COLLATE NOCASE;
  ")

  if [[ "$match" -gt 0 ]]; then
    if [[ "$DRYRUN" -eq 1 ]]; then
      echo "🟡 Would mark: $artist - $album - $title"
#read -p WOULDMARK</dev/tty
    else
      sqlite3 "$DB" "
        UPDATE tracks
        SET downloaded = 1
        WHERE artist = '$sql_artist'
          AND album = '$sql_album'
          AND title = '$sql_title'
        COLLATE NOCASE;
      "
      echo "✅ Marked: $artist - $album - $title"
#read -p MARKED</dev/tty
    fi
    echo "$line" >> "$LOG_MATCHED"
  else
#    echo "⚠️  Not found: $line"

echo "⚠️  Not found: $line"
NOT_FOUND_ALBUMS["$artist — $album"]=1

    echo "$line" >> "$LOG_UNMATCHED"
#read -p NOTFOUND</dev/tty
  fi

done < "$LIST"

if (( ${#NOT_FOUND_ALBUMS[@]} > 0 )); then
  echo -e "\n📦 Summary of artist/album combinations not found in DB:"
  for key in "${!NOT_FOUND_ALBUMS[@]}"; do
    echo "• $key"
  done
fi
