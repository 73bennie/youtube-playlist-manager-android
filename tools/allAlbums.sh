#!/usr/bin/env bash

source "../lib/config.sh"
source "../lib/sqlite_escape.sh"

echo -e "${CYAN}=== Check All Albums ===${RESET}"
echo

MYALBUMS="$HOME/storage/shared/Documents/MyAlbums.txt"

echo -e "\nChecking downloaded albums against database:\n"

while IFS='/' read -r artist album; do
    artist=$(echo "$artist" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    album=$(echo "$album" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Use sqlite_escape function for proper escaping
    artist_escaped=$(sqlite_escape "$artist")
    album_escaped=$(sqlite_escape "$album")

    found=$(sqlite3 "$DB" "
      SELECT 1
      FROM tracks
      WHERE artist = '$artist_escaped' AND album = '$album_escaped'
      LIMIT 1;
    ")

    if [[ "$found" == "1" ]]; then
        #echo -e "\e[32m$artist/$album\e[0m"
    else
        echo -e "\e[31m$artist/$album\e[0m"
    fi
done < "$MYALBUMS"

if [[ "$found" == "1" ]]; then
    echo "No albums found."
    exit 1
fi
