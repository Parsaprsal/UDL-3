#!/bin/bash

set -e

# ──────────────────────────────────────────────────────────────────────
# PART 1: SETUP
# ──────────────────────────────────────────────────────────────────────
URLS_RAW="${YT_URLS}"
read -ra URL_LIST <<< "$URLS_RAW"
TOTAL_URLS=${#URL_LIST[@]}

QUALITY="${YT_QUALITY}"
ZIP_PASSWORD="${YT_PASSWORD}"
DOWNLOAD_SUBS="${DOWNLOAD_SUBS:-false}"

# Get tracker filename
TRACKER_FILE=$(cat /tmp/tracker_filename.txt)
RUN_ID=$(echo "$TRACKER_FILE" | sed 's/downloadings\/downloading_\(.*\).md/\1/')

SPLIT_MB=45
SPLIT_BYTES=$(( SPLIT_MB * 1024 * 1024 ))

BACKUP_DIR="/tmp/video_backup_$$"
mkdir -p "$BACKUP_DIR"
echo "$BACKUP_DIR" > /tmp/backup_dir_path.txt

mkdir -p videos
> /tmp/video_info.txt

echo "AVASAM Video Getter"
echo "https://avasam.ir"
echo ""
echo "Total URLs to download: $TOTAL_URLS"
echo "Quality: $QUALITY"
if [ -n "$ZIP_PASSWORD" ]; then
  echo "Password protection: ENABLED"
else
  echo "Password protection: DISABLED"
fi
if [ "$DOWNLOAD_SUBS" = "true" ]; then
  echo "Subtitles: ENABLED (en, fa)"
else
  echo "Subtitles: DISABLED"
fi
echo ""

sanitize_name() {
  echo "$1" | sed 's/ /-/g' | sed 's/　/-/g' | tr -s '-'
}

urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

# ============================================================
# FORMAT STRINGS
# ============================================================
case "$QUALITY" in
  "audio")
    FORMAT="bestaudio/bestaudio*/best"
    ;;
  "best")
    FORMAT="bestvideo+bestaudio/bestvideo*+bestaudio*/best"
    ;;
  "2160"|"4k")
    FORMAT="bestvideo[height<=2160]+bestaudio/bestvideo[height<=2160]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  "1440"|"2k")
    FORMAT="bestvideo[height<=1440]+bestaudio/bestvideo[height<=1440]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  "1080")
    FORMAT="bestvideo[height<=1080]+bestaudio/bestvideo[height<=1080]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  "720")
    FORMAT="bestvideo[height<=720]+bestaudio/bestvideo[height<=720]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  "480")
    FORMAT="bestvideo[height<=480]+bestaudio/bestvideo[height<=480]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  "360")
    FORMAT="bestvideo[height<=360]+bestaudio/bestvideo[height<=360]*+bestaudio*/bestvideo+bestaudio/best"
    ;;
  *)
    FORMAT="bestvideo+bestaudio/bestvideo*+bestaudio*/best"
    ;;
esac

download_video() {
  local METHOD=$1
  local URL=$2
  local TMP_DIR=$3
  echo "Trying download method $METHOD..."

  if [ "$QUALITY" = "audio" ]; then
    COMMON_FLAGS="--extract-audio --audio-format mp3 --audio-quality 0 --write-thumbnail --convert-thumbnails jpg --no-cache-dir --output ${TMP_DIR}/%(title)s.%(ext)s --no-part --no-playlist --retries 5 --fragment-retries 5 --no-check-certificates --concurrent-fragments 8 --buffer-size 16K --http-chunk-size 10M --progress --newline"
  elif [ "$QUALITY" = "best" ]; then
    COMMON_FLAGS="--merge-output-format mp4 --format-sort res,+codec:vp9.1,+size --write-thumbnail --convert-thumbnails jpg --no-cache-dir --output ${TMP_DIR}/%(title)s.%(ext)s --no-part --no-playlist --retries 5 --fragment-retries 5 --no-check-certificates --concurrent-fragments 8 --buffer-size 16K --http-chunk-size 10M --progress --newline"
  else
    COMMON_FLAGS="--merge-output-format mp4 --write-thumbnail --convert-thumbnails jpg --no-cache-dir --output ${TMP_DIR}/%(title)s.%(ext)s --no-part --no-playlist --retries 5 --fragment-retries 5 --no-check-certificates --concurrent-fragments 8 --buffer-size 16K --http-chunk-size 10M --progress --newline"
  fi

  case $METHOD in
    1)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=web" \
        --js-runtimes deno \
        --remote-components ejs:github \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
        --add-header "Accept-Language:en-US,en;q=0.9" \
        "$URL"
      ;;
    2)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=web" \
        --js-runtimes deno \
        --remote-components ejs:npm \
        --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
        --add-header "Accept-Language:en-US,en;q=0.9" \
        "$URL"
      ;;
    3)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=web,mweb,android_vr" \
        --js-runtimes deno \
        --remote-components ejs:github \
        "$URL"
      ;;
    4)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=mweb" \
        "$URL"
      ;;
    5)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=android_vr" \
        "$URL"
      ;;
    6)
      yt-dlp \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=web" \
        --js-runtimes deno \
        --remote-components ejs:github \
        "$URL"
      ;;
    7)
      yt-dlp \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=mweb" \
        "$URL"
      ;;
    8)
      yt-dlp \
        --proxy "socks5://127.0.0.1:1080" \
        --format "$FORMAT" \
        $COMMON_FLAGS \
        --extractor-args "youtube:player_client=android" \
        --user-agent "Mozilla/5.0 (Linux; Android 12; SM-S906N Build/QP1A.190711.020) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36" \
        "$URL"
      ;;
  esac
}

get_random_word() {
  RANDOM_WORDS=("alpha" "beta" "gamma" "delta" "epsilon" "zeta" "theta" "kappa" "lambda" "sigma" "omega" "nova" "star" "moon" "sun" "sky" "cloud" "river" "ocean" "mountain")
  echo "${RANDOM_WORDS[$RANDOM % ${#RANDOM_WORDS[@]}]}_$RANDOM"
}

get_unique_folder() {
  local BASE_PATH="$1"
  local NAME="$2"
  if [ ! -d "$BASE_PATH/$NAME" ] && [ ! -d "$BACKUP_DIR/$NAME" ]; then
    echo "$NAME"; return
  fi
  local RANDOM_SUFFIX=$(get_random_word)
  while [ -d "$BASE_PATH/${NAME}_${RANDOM_SUFFIX}" ] || [ -d "$BACKUP_DIR/${NAME}_${RANDOM_SUFFIX}" ]; do
    RANDOM_SUFFIX=$(get_random_word)
  done
  echo "${NAME}_${RANDOM_SUFFIX}"
}

# Save variables
echo "$FORMAT" > /tmp/yt_format.txt
echo "$QUALITY" > /tmp/yt_quality.txt
echo "$ZIP_PASSWORD" > /tmp/yt_password.txt
echo "$BACKUP_DIR" > /tmp/backup_dir_path.txt
echo "$REPO_OWNER" > /tmp/yt_repo_owner.txt
echo "$REPO_NAME" > /tmp/yt_repo_name.txt
echo "$BRANCH" > /tmp/yt_branch.txt
printf "%s\n" "${URL_LIST[@]}" > /tmp/yt_urls.txt

# ──────────────────────────────────────────────────────────────────────
# PART 2: DOWNLOAD LOOP
# ──────────────────────────────────────────────────────────────────────
normalize_youtube_url() {
  local INPUT_URL="$1"
  if [[ "$INPUT_URL" =~ youtu\.be/([a-zA-Z0-9_-]+) ]]; then
    VIDEO_ID="${BASH_REMATCH[1]}"
    VIDEO_ID="${VIDEO_ID%%\?*}"
    echo "https://www.youtube.com/watch?v=${VIDEO_ID}"
  else
    echo "$INPUT_URL"
  fi
}

URL_INDEX=0
for URL in "${URL_LIST[@]}"; do
  URL_INDEX=$((URL_INDEX + 1))
  URL=$(normalize_youtube_url "$URL")

  echo ""
  echo "============================================================"
  echo "Processing URL $URL_INDEX / $TOTAL_URLS : $URL"
  echo "============================================================"

  TMP_DIR="tmp_downloads_${URL_INDEX}"
  mkdir -p "$TMP_DIR"

  DOWNLOAD_SUCCESS=false
  for METHOD in 1 2 3 4 5 6 7 8; do
    if download_video $METHOD "$URL" "$TMP_DIR"; then
      echo "Download successful with method $METHOD!"

      QUALITY_OK=true
      if [ "$QUALITY" != "best" ] && [ "$QUALITY" != "audio" ]; then
        for DOWNLOADED_FILE in "$TMP_DIR"/*.mp4 "$TMP_DIR"/*.webm "$TMP_DIR"/*.mkv; do
          [ -f "$DOWNLOADED_FILE" ] || continue
          ACTUAL_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$DOWNLOADED_FILE" 2>/dev/null || echo "unknown")
          if [ "$ACTUAL_HEIGHT" != "unknown" ] && [ "$ACTUAL_HEIGHT" -lt $(( QUALITY - 150 )) ] 2>/dev/null; then
            QUALITY_OK=false
            rm -f "$DOWNLOADED_FILE"
          fi
        done
      fi

      if [ "$QUALITY_OK" = true ]; then
        DOWNLOAD_SUCCESS=true
        
        # PROCESS DOWNLOADED FILE
        for DOWNLOADED_FILE in "$TMP_DIR"/*.mp4 "$TMP_DIR"/*.webm "$TMP_DIR"/*.mkv "$TMP_DIR"/*.mp3; do
          [ -f "$DOWNLOADED_FILE" ] || continue
          
          SIZE=$(stat -c%s "$DOWNLOADED_FILE")
          BASENAME=$(basename "$DOWNLOADED_FILE")
          FILENAME_NO_EXT="${BASENAME%.*}"
          EXT="${BASENAME##*.}"
          
          SANITIZED_NAME=$(sanitize_name "$FILENAME_NO_EXT")
          
          FINAL_FOLDER="videos/${SANITIZED_NAME}"
          mkdir -p "$FINAL_FOLDER"
          
          # Handle split files if size > limit
          if [ "$SIZE" -gt "$SPLIT_BYTES" ]; then
            echo "Splitting $BASENAME into ${SPLIT_MB}MB parts..."
            ARCHIVE_BASE="$BACKUP_DIR/${SANITIZED_NAME}/${SANITIZED_NAME}"
            mkdir -p "$BACKUP_DIR/${SANITIZED_NAME}"
            
            if [ -n "$ZIP_PASSWORD" ]; then
              7z a -tzip -v${SPLIT_MB}m -p"${ZIP_PASSWORD}" -mx=0 "${ARCHIVE_BASE}.zip" "$DOWNLOADED_FILE"
            else
              zip -0 -s ${SPLIT_MB}m "${ARCHIVE_BASE}.zip" "$DOWNLOADED_FILE"
            fi
            
            cp "$BACKUP_DIR/${SANITIZED_NAME}"/* "$FINAL_FOLDER/"
            
            DOWNLOAD_LINKS_MD=""
            LINK_NUM=0
            FOLDER_ENCODED=$(urlencode "${SANITIZED_NAME}")
            for part_file in $(ls "$FINAL_FOLDER"/*.zip "$FINAL_FOLDER"/*.z[0-9]* 2>/dev/null | sort -V); do
              PART_BASENAME=$(basename "$part_file")
              PART_ENCODED=$(urlencode "${PART_BASENAME}")
              RAW_LINK="https://github.com/${REPO_OWNER}/${REPO_NAME}/raw/${BRANCH}/videos/${FOLDER_ENCODED}/${PART_ENCODED}"
              LINK_NUM=$((LINK_NUM + 1))
              DOWNLOAD_LINKS_MD="${DOWNLOAD_LINKS_MD}| ${LINK_NUM} | \`${PART_BASENAME}\` | [Download](${RAW_LINK}) |"$'\n'
            done
            
            TOTAL_SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
            PART_COUNT=$LINK_NUM
            
            cat > "$FINAL_FOLDER/README.md" << EOF
# ${SANITIZED_NAME}

---

## Video Information

| Property | Value |
|----------|-------|
| **Video Name** | \`${SANITIZED_NAME}\` |
| **Original Link** | [YouTube Video](${URL}) |
| **Total Size** | **${PART_COUNT} parts** - **${TOTAL_SIZE_MB} MB** |
| **Quality** | **${QUALITY}** |
| **Status** | **Complete (100%)** |
| **Password Protected** | **$([ -n "$ZIP_PASSWORD" ] && echo "YES" || echo "NO")** |

---

## Download Links

> ⬇️ Download **all parts**, then open \`${SANITIZED_NAME}.zip\`

| # | File | Link |
|---|------|------|
${DOWNLOAD_LINKS_MD}
---

*This tool created by [avasam.ir](https://avasam.ir)*
EOF
          else
            cp "$DOWNLOADED_FILE" "$FINAL_FOLDER/${SANITIZED_NAME}.${EXT}"
            SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
            FOLDER_ENCODED=$(urlencode "${SANITIZED_NAME}")
            FILE_ENCODED=$(urlencode "${SANITIZED_NAME}.${EXT}")
            RAW_LINK="https://github.com/${REPO_OWNER}/${REPO_NAME}/raw/${BRANCH}/videos/${FOLDER_ENCODED}/${FILE_ENCODED}"
            
            cat > "$FINAL_FOLDER/README.md" << EOF
# ${SANITIZED_NAME}

---

## Video Information

| Property | Value |
|----------|-------|
| **Video Name** | \`${SANITIZED_NAME}\` |
| **Original Link** | [YouTube Video](${URL}) |
| **Total Size** | **1 file** - **${SIZE_MB} MB** |
| **Quality** | **${QUALITY}** |
| **Status** | **Complete (100%)** |
| **Password Protected** | **$([ -n "$ZIP_PASSWORD" ] && echo "YES" || echo "NO")** |

---

## Download Link

| # | File | Link |
|---|------|------|
| 1 | \`${SANITIZED_NAME}.${EXT}\` | [Download](${RAW_LINK}) |

---

Ready to use — no extraction needed!

---

*This tool created by [avasam.ir](https://avasam.ir)*
EOF
          fi
          
          THUMB_FILE=$(ls "$TMP_DIR"/*.jpg 2>/dev/null | head -1)
          if [ -n "$THUMB_FILE" ] && [ -f "$THUMB_FILE" ]; then
            cp "$THUMB_FILE" "$FINAL_FOLDER/thumbnail.jpg"
            echo "✅ Thumbnail saved"
          fi
          
          # Also copy to BACKUP_DIR for final push
          mkdir -p "$BACKUP_DIR/${SANITIZED_NAME}"
          cp -r "$FINAL_FOLDER"/* "$BACKUP_DIR/${SANITIZED_NAME}/"
          
          echo "${SANITIZED_NAME}|${SANITIZED_NAME}" >> /tmp/video_info.txt
          echo "✅ Video saved to: $FINAL_FOLDER and backed up to $BACKUP_DIR/${SANITIZED_NAME}"
          break
        done
        
        # Remove from tracking file
       # Remove from tracking file
        # Remove from tracking file
        # Remove from tracking file with better conflict handling
        
# Remove from tracking file
        RANDOM_ID=$(grep "^$URL|" "/tmp/url_ids_${RUN_ID}.txt" 2>/dev/null | cut -d'|' -f2)
        if [ -n "$RANDOM_ID" ]; then
          # Remove the line from tracker file
          sed -i "\@\"$URL\",\"$RANDOM_ID\"@d" "$TRACKER_FILE"
          
          # Stash, pull, pop
          git stash push -m "temp_${RANDOM_ID}" || true
          git pull origin $GITHUB_REF_NAME --rebase || true
          git stash pop || true
          
          # Add and commit
          git add downloadings/
          git add "$TRACKER_FILE"
          if ! git diff --cached --quiet; then
            git commit -m "Complete download: $RANDOM_ID for run $RUN_ID" || true
          fi
          
          # Push with retry
          for attempt in 1 2 3 4 5; do
            git pull origin $GITHUB_REF_NAME --rebase || true
            if git push origin $GITHUB_REF_NAME; then
              echo "✅ Removed tracking entry for $RANDOM_ID from $TRACKER_FILE"
              break
            else
              echo "Push failed, attempt $attempt/5, retrying in 2 seconds..."
              sleep 2
            fi
          done
        fi
        break
      fi
    else
      sleep 3
    fi
  done

  if [ "$DOWNLOAD_SUCCESS" = false ]; then
    echo "❌ All download methods failed for URL: $URL — skipping."
  fi
  
  rm -rf "$TMP_DIR"
  echo "✅ Finished URL $URL_INDEX / $TOTAL_URLS"
done

echo ""
echo "===== Backup folder contents ====="
find "$BACKUP_DIR" -type f | head -50
echo "===== Video info file ====="
cat /tmp/video_info.txt
echo "===== Download completed ====="