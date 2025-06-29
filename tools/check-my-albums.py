#!/data/data/com.termux/files/usr/bin/python

from rapidfuzz import fuzz
import sqlite3
import os
import subprocess
import time
import sys

# === CONFIGURATION ===
DB_PATH = os.path.expanduser("~/bin/Youtube-Playlist-Manager/ytdata/metadata.db")
MYALBUMS_PATH = os.path.expanduser("~/storage/shared/Documents/MyAlbums.txt")
FUZZY_THRESHOLD = 85

GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
RESET = "\033[0m"

def normalize(text):
    return text.replace("：", ":").replace("–", "-").replace("—", "-").strip().lower()

def colorize(text, color):
    return f"{color}{text}{RESET}"

def wait_for_file_ready(path, timeout=10):
    """Waits until file exists, is non-empty, and stops changing in size."""
    last_size = -1
    for _ in range(timeout * 10):  # check every 0.1 seconds
        if os.path.exists(path):
            size = os.path.getsize(path)
            if size > 0 and size == last_size:
                return True
            last_size = size
        time.sleep(0.1)
    return False

# === LOAD DATABASE ===
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()
cur.execute("""
    SELECT DISTINCT artist, album, playlist_id
    FROM tracks
    WHERE artist IS NOT NULL AND album IS NOT NULL
""")
db_entries = cur.fetchall()

normalized_db = [
    (normalize(artist), normalize(album), artist, album, pid)
    for artist, album, pid in db_entries
]

# === DELETE old MyAlbums.txt ===
if os.path.exists(MYALBUMS_PATH):
    os.remove(MYALBUMS_PATH)

# === CREATE MyAlbums.txt ===
subprocess.run([
    "am", "broadcast",
    "-a", "net.dinglisch.android.tasker.ACTION_TASK",
    "--es", "task_name", "ListAlbumFolders"
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Creating MyAlbums.txt...")
if not wait_for_file_ready(MYALBUMS_PATH, timeout=10):
    print(f"{RED}Timed out waiting for MyAlbums.txt to be ready.{RESET}")
    sys.exit(1)

# === PROCESS MYALBUMS.TXT ===
with open(MYALBUMS_PATH, encoding="utf-8") as f:
    lines = sorted(
        [line.strip() for line in f if '/' in line],
        key=lambda l: l.lower()
    )

exact_matches = 0
fuzzy_matches = 0
no_matches = 0

for line in lines:
    if '/' not in line:
        continue

    raw_artist, raw_album = line.strip().split('/', 1)
    input_artist = raw_artist.strip()
    input_album = raw_album.strip()
    input_artist_norm = normalize(input_artist)
    input_album_norm = normalize(input_album)
    input_line_display = f"{input_artist}/{input_album}"

    # Check for exact match
    matching_playlist_ids = [
        pid for db_artist_norm, db_album_norm, _, _, pid in normalized_db
        if input_artist_norm == db_artist_norm and input_album_norm == db_album_norm
    ]

    if matching_playlist_ids:
        # print(colorize(input_line_display, GREEN))  # Suppressed exact match output
        cur.execute(f"""
            UPDATE tracks
            SET downloaded = 1, tagged = 1
            WHERE playlist_id IN ({','.join(['?'] * len(matching_playlist_ids))})
        """, matching_playlist_ids)
        conn.commit()
        exact_matches += 1
        continue

    # Look for fuzzy matches
    matches = []
    for db_artist_norm, db_album_norm, db_artist, db_album, pid in normalized_db:
        if input_album_norm in db_album_norm:
            matches.append((db_artist, db_album, pid, "substring"))
        else:
            score_artist = fuzz.partial_ratio(input_artist_norm, db_artist_norm)
            score_album = fuzz.partial_ratio(input_album_norm, db_album_norm)
            avg_score = (score_artist + score_album) / 2
            if avg_score >= FUZZY_THRESHOLD:
                matches.append((db_artist, db_album, pid, f"fuzzy:{avg_score:.1f}"))

    if matches:
        print(colorize(input_line_display, YELLOW))
        for db_artist, db_album, pid, reason in matches:
            print(f" → DB: {db_artist} - {db_album}")
        fuzzy_matches += 1
        continue

    # No matches at all
    print(f"{colorize(input_line_display + ' ✗', RED)}")
    no_matches += 1

conn.close()

# === SUMMARY ===
print("\nDone.")
print(f"{GREEN}Exact Matches: {exact_matches}{RESET}")
print(f"{YELLOW}Fuzzy Matches: {fuzzy_matches}{RESET}")
print(f"{RED}No Matches: {no_matches}{RESET}")
