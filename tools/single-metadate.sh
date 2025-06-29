#!/usr/bin/env bash
# quick-track-meta.sh

set -euo pipefail

source "lib/config.sh"
source "lib/functions.sh"

URL="https://music.youtube.com/watch?v=JOcUinX5-WY&si=rBMglX5NhmC69C79"

yt-dlp --dump-single-json "$URL" | jq . | less
