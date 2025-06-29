#!/usr/bin/env bash

# Source the functions
source "../lib/functions.sh"

DB="../ytdata/metadata.db"
SQL_TMP=$(mktemp)

# Start SQL transaction
echo "BEGIN TRANSACTION;" > "$SQL_TMP"

# Extract and sanitize
sqlite3 -separator $'\t' "$DB" "
  SELECT id, artist, album, title
  FROM tracks
  WHERE artist IS NOT NULL OR album IS NOT NULL OR title IS NOT NULL;
" | while IFS=$'\t' read -r id artist album title; do
    artist_clean=$(sanitize_db_entry "$artist")
    album_clean=$(sanitize_db_entry "$album")
    title_clean=$(sanitize_db_entry "$title")

    if [[ "$artist" != "$artist_clean" || "$album" != "$album_clean" || "$title" != "$title_clean" ]]; then
        echo "UPDATE tracks SET artist = '$(sqlite_escape "$artist_clean")', album = '$(sqlite_escape "$album_clean")', title = '$(sqlite_escape "$title_clean")' WHERE id = '$(sqlite_escape "$id")';" >> "$SQL_TMP"
        echo "✓ Will clean track: $id"
    fi
done

# Finish SQL and execute in one shot
echo "COMMIT;" >> "$SQL_TMP"

sqlite3 "$DB" < "$SQL_TMP"
rm -f "$SQL_TMP"
