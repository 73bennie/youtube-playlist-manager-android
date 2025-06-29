#!/bin/bash

# Usage: ./merge_sqlite_tracks.sh target.db source.db

set -euo pipefail

# === INPUT CHECK ===
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 target.db source.db"
    exit 1
fi

TARGET_DB="$1"
SOURCE_DB="$2"

# === VALIDATION ===
if [ ! -f "$TARGET_DB" ]; then
    echo "Error: target DB '$TARGET_DB' not found."
    exit 1
fi

if [ ! -f "$SOURCE_DB" ]; then
    echo "Error: source DB '$SOURCE_DB' not found."
    exit 1
fi

# === MERGE LOGIC ===
echo "Merging '$SOURCE_DB' into '$TARGET_DB'..."

sqlite3 "$TARGET_DB" <<EOF
ATTACH DATABASE '$SOURCE_DB' AS source;

-- Optional: preview counts
-- SELECT COUNT(*) FROM source.tracks;
-- SELECT COUNT(*) FROM tracks;

INSERT OR IGNORE INTO tracks
SELECT * FROM source.tracks;

DETACH DATABASE source;
EOF

echo "Merge complete. All unique tracks from '$SOURCE_DB' added to '$TARGET_DB'."
