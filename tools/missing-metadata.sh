#!/bin/bash

# Path to the SQLite database
DB="ytdata/metadata.db"

# Output file
OUTFILE="missing-metadata.txt"

# Run the SQLite query
sqlite3 "$DB" <<EOF > "$OUTFILE"
.headers off
.mode csv
SELECT DISTINCT playlist_id
FROM tracks
WHERE (artist IS NULL OR TRIM(artist) = '')
   OR (album IS NULL OR TRIM(album) = '');
EOF

# Confirm export
echo "Distinct playlist_ids with missing artist and/or album written to: $OUTFILE"
