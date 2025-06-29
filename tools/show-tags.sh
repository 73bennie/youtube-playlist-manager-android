#!/bin/bash
# Usage: ./show-tags.sh /path/to/directory

set -e

echo -e "${CYAN}=== Show File Tags ===${RESET}"
echo

DIR="$1"
if [[ -z "$DIR" || ! -d "$DIR" ]]; then
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

TEMP_OUTPUT="$(mktemp)"

find "$DIR" -type f -iname "*.opus" -o -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.flac" | while read -r file; do
    echo "==> $file" >> "$TEMP_OUTPUT"
    ffprobe -v quiet -show_entries format_tags:stream_tags \
        -of default=noprint_wrappers=1:nokey=0 "$file" >> "$TEMP_OUTPUT" 2>/dev/null
    echo "" >> "$TEMP_OUTPUT"
done

less "$TEMP_OUTPUT"
rm -f "$TEMP_OUTPUT"

