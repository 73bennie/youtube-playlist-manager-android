#!/usr/bin/env bash

source "lib/config.sh"
source "lib/functions.sh"
source "lib/sqlite_escape.sh"
# source "lib/input_validation.sh"

# Tag a single .opus file
 tag_opus_file() {
    local infile="$1"
    local title="$2"
    local artist="$3"
    local album="$4"
    local track_id="$5"
    local playlist_description="$6"
    local tmpfile
    tmpfile="$(mktemp --suffix=".opus")"

    # Validate inputs
    # if ! validate_video_id "$track_id"; then
    #     log_error "Invalid video ID: $track_id"
    #     return 1
    # fi

    local basename_only="$(basename "$infile" .opus)"
    local track_number="${basename_only%% -*}"

    ffmpeg -loglevel error -y -i "$infile" -c copy \
        -metadata artist="$artist" \
        -metadata album="$album" \
        -metadata title="$title" \
        -metadata track="$track_number" \
        -metadata track_id="$track_id" \
        -metadata playlist_id="$playlist_id" \
        -metadata playlist_description="$playlist_description" \
        "$tmpfile"

    if [[ -s "$tmpfile" ]]; then
        mv "$tmpfile" "$infile"
        sqlite3 "$DB" "UPDATE tracks SET tagged = 1 WHERE id = '$(sqlite_escape "$track_id")';"
        return 0
    else
        return 1
    fi
}

# Parse arguments
AUTO_ALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all)
      AUTO_ALL=1
      shift
      ;;
    # ...other argument parsing if any...
    *)
      shift
      ;;
  esac
done

if [[ "$AUTO_ALL" -eq 1 ]]; then
  # Automatically select all available playlists for download
  playlists_to_download=$(sqlite3 "$DB" "SELECT DISTINCT playlist_id FROM tracks WHERE artist IS NOT NULL AND TRIM(artist) != '' AND album IS NOT NULL AND TRIM(album) != '' GROUP BY playlist_id HAVING SUM(CASE WHEN downloaded = 0 THEN 1 ELSE 0 END) > 0 AND COUNT(DISTINCT artist || '|' || album) = 1;")
  for playlist_id in $playlists_to_download; do
    # Replace this with your actual download logic for each playlist
    ./download-playlist.sh "$playlist_id"
  done
  exit 0
fi

playlists=$(sqlite3 -separator '|' "$DB" "
  SELECT playlist_id, artist, album,
         COUNT(*) AS total_tracks,
         SUM(CASE WHEN downloaded = 0 THEN 1 ELSE 0 END) AS remaining
  FROM tracks
  WHERE artist IS NOT NULL AND TRIM(artist) != ''
    AND album IS NOT NULL AND TRIM(album) != ''
  GROUP BY playlist_id
  HAVING remaining > 0
     AND COUNT(DISTINCT artist || '|' || album) = 1
  ORDER BY artist COLLATE NOCASE, album COLLATE NOCASE;
")

if [[ -z "$playlists" ]]; then
    echo -e "${RED}No playlists available for download.${RESET}"
    exit 0
fi

i=1
declare -A IDX_TO_ID
playlist_ids=()

echo -e "Available playlists:\n"
while IFS='|' read -r pid artist album total remaining; do
    echo "$i) $artist - $album"
    IDX_TO_ID[$i]="$pid"
    playlist_ids+=("$pid")
    ((i++))
done <<< "$playlists"

echo "0) Download ALL playlists"

while true; do
    echo -ne "\nChoose playlist to download (number or press Enter to cancel): "
    read -r idx

    if [[ -z "$idx" ]]; then
        exit 0
    elif [[ "$idx" == "0" ]]; then
        selected_ids=("${playlist_ids[@]}")
        break
    elif [[ -n "${IDX_TO_ID[$idx]}" ]]; then
        selected_ids=("${IDX_TO_ID[$idx]}")
        break
    else
        echo "Invalid choice."
    fi
done

for playlist_id in "${selected_ids[@]}"; do
    IFS='|' read -r artist album <<< "$(get_playlist_info "$playlist_id")"
    
    # Sanitize artist and album names for directory creation
    safe_artist=$(sanitize_filename "$artist")
    safe_album=$(sanitize_filename "$album")
    
    # Ensure download directory exists
    mkdir -p "$DOWNLOAD_DIR"
    mkdir -p "$DOWNLOAD_DIR/$safe_artist/$safe_album"

    log_info "$YELLOW" "
Downloading:
$artist
$album"

    thumb_url=$(get_playlist_thumbnail "$playlist_id")
    cover_dir="$DOWNLOAD_DIR/$safe_artist/$safe_album"
    mkdir -p "$cover_dir"

    if [[ ! -f "$cover_dir/folder.jpg" ]] && [[ -n "$thumb_url" ]]; then
        echo "⬇ Downloading album art..."
        track_id=$(get_playlist_first_track "$playlist_id")
        
        if [[ -n "$track_id" ]]; then
            if yt-dlp --write-thumbnail --skip-download --convert-thumbnails jpg \
                     --output "$cover_dir/cover" \
                     "https://www.youtube.com/watch?v=$track_id" >>"$LOG_FILE" 2>&1; then
                echo "  ✓ Downloaded album art"
                # Rename the downloaded file
                if [[ -f "$cover_dir/cover.jpg" ]]; then
                    mv "$cover_dir/cover.jpg" "$cover_dir/folder.jpg"
                fi
            else
                echo "  ✗ Failed to download album art"
                rm -f "$cover_dir/cover.jpg"
            fi
        else
            echo "  ✗ No track ID found for album art download"
        fi
    else
        if [[ -f "$cover_dir/folder.jpg" ]]; then
            echo "✓ Album art already exists"
        fi
    fi

    # Get playlist description for tagging
    playlist_description=$(get_playlist_description "$playlist_id")
    
    sqlite3 -separator '|' "$DB" "
      SELECT track_number, title, id
      FROM tracks
      WHERE playlist_id = '$(sqlite_escape "$playlist_id")' AND downloaded = 0
      ORDER BY track_number;
    " | while IFS='|' read -r idx title vid; do
        printf "${GREEN}[%02d/%s]${RESET} %s\n" "$idx" "$(get_playlist_track_count "$playlist_id")" "$title"
        # Better filename sanitization - replace problematic characters with underscores
        safe_title=$(sanitize_filename "$title")
        filename="$DOWNLOAD_DIR/$safe_artist/$safe_album/$(printf "%02d - %s.opus" "$idx" "$safe_title")"
        
        # Check if file exists in old unsanitized path and move it
        old_filename="$DOWNLOAD_DIR/$artist/$album/$(printf "%02d - %s.opus" "$idx" "$safe_title")"
        if [[ -f "$old_filename" ]] && [[ ! -f "$filename" ]]; then
            mv "$old_filename" "$filename"
        fi

        if [[ -f "$filename" ]]; then
            continue
        fi

        yt-dlp -f bestaudio --extract-audio --audio-format opus \
            --output "$filename" \
            --force-overwrites \
            "https://music.youtube.com/watch?v=$vid" \
            --no-warnings >>"$LOG_FILE" 2>&1

        # Check if file was actually downloaded and has content
        if [[ -s "$filename" ]]; then
            tag_opus_file "$filename" "$title" "$artist" "$album" "$vid" "$playlist_description"
            sqlite3 "$DB" "UPDATE tracks SET downloaded = 1 WHERE id = '$(sqlite_escape "$vid")';"
        else
            # Remove empty file if it exists
            [[ -f "$filename" ]] && rm -f "$filename"
        fi
    done

    # Clean up old unsanitized directories if they're empty
    old_album_dir="$DOWNLOAD_DIR/$artist/$album"
    if [[ -d "$old_album_dir" ]] && [[ -z "$(find "$old_album_dir" -mindepth 1 -print -quit)" ]]; then
        rmdir "$old_album_dir"
    fi
    old_artist_dir="$DOWNLOAD_DIR/$artist"
    if [[ -d "$old_artist_dir" ]] && [[ -z "$(find "$old_artist_dir" -mindepth 1 -print -quit)" ]]; then
        rmdir "$old_artist_dir"
    fi

    # Only run Android-specific command if we're on Android
    if command -v am >/dev/null 2>&1; then
        am broadcast -a net.dinglisch.android.tasker.ACTION_TASK --es task_name "MoveFolders"
    fi

	sleep 2
done

