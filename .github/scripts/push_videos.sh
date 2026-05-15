#!/bin/bash

set -e

BRANCH="${GITHUB_REF_NAME}"
REPO_OWNER="${REPO_OWNER}"
REPO_NAME="${REPO_NAME}"

echo "AVASAM (https://avasam.ir) - Incremental Push Mode"

# خواندن BACKUP_DIR از فایل ذخیره شده
if [ -f /tmp/backup_dir_path.txt ]; then
  BACKUP_DIR=$(cat /tmp/backup_dir_path.txt)
  echo "Backup directory: $BACKUP_DIR"
else
  echo "ERROR: backup_dir_path.txt not found!"
  exit 1
fi

# بررسی وجود فایل‌های ویدیو در BACKUP_DIR
if [ -d "$BACKUP_DIR" ]; then
  VIDEO_COUNT=$(find "$BACKUP_DIR" -type f \( -name "*.mp4" -o -name "*.mp3" -o -name "*.webm" -o -name "*.mkv" -o -name "*.zip" \) 2>/dev/null | wc -l)
  echo "Found $VIDEO_COUNT media files in backup"
  
  if [ "$VIDEO_COUNT" -eq 0 ]; then
    echo "No videos to push. Exiting."
    exit 0
  fi
else
  echo "No backup directory found. Exiting."
  exit 0
fi

urlencode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$1"
}

regenerate_master_readme() {
  MASTER_README="videos/README.md"
  { echo "# DOWNLOADED VIDEOS LIST :"; echo ""; echo "----"; echo ""; } > "$MASTER_README"
  VIDEO_EMOJIS=("🎬" "🎥" "📽️" "🎞️" "📺" "🎦" "▶️")
  NUM=0
  for folder in videos/*/; do
    [ -d "$folder" ] || continue
    FOLDER_NAME=$(basename "$folder")
    [ -f "$folder/README.md" ] || continue
    NUM=$((NUM + 1))
    RANDOM_EMOJI="${VIDEO_EMOJIS[$RANDOM % ${#VIDEO_EMOJIS[@]}]}"
    FOLDER_ENCODED=$(urlencode "$FOLDER_NAME")
    FOLDER_LINK="https://github.com/${REPO_OWNER}/${REPO_NAME}/tree/${BRANCH}/videos/${FOLDER_ENCODED}"
    printf -- "- %s - %s [%s](%s)\n" "$NUM" "$RANDOM_EMOJI" "$FOLDER_NAME" "$FOLDER_LINK" >> "$MASTER_README"
  done
}

# گرفتن آخرین تغییرات
git fetch origin "$BRANCH"
git reset --hard origin/"$BRANCH" || true

# اطمینان از وجود پوشه videos
mkdir -p videos

# کپی فایل‌ها از BACKUP_DIR به videos
if [ -d "$BACKUP_DIR" ]; then
  cp -rf "$BACKUP_DIR"/* videos/ 2>/dev/null || true
  echo "Files copied from $BACKUP_DIR to videos/"
fi

# نمایش محتویات videos برای دیباگ
echo "Contents of videos directory:"
ls -la videos/

git add -A videos/
regenerate_master_readme
git add videos/README.md

if ! git diff --cached --quiet; then
  git commit -m "[AVASAM] YouTube download [skip ci]"
  PUSH_RETRY=0
  while [ $PUSH_RETRY -lt 10 ]; do
    PUSH_RETRY=$((PUSH_RETRY + 1))
    if timeout 300 git push origin HEAD:"$BRANCH"; then
      echo "Push successful!"
      break
    else
      echo "Push failed, retry $PUSH_RETRY/10..."
      sleep 5
      git fetch origin "$BRANCH"
      git reset --hard origin/"$BRANCH" || true
      mkdir -p videos
      cp -rf "$BACKUP_DIR"/* videos/ 2>/dev/null || true
      git add -A videos/
      regenerate_master_readme
      git add videos/README.md
      git diff --cached --quiet || git commit -m "[AVASAM] YouTube download [skip ci]"
    fi
  done
else
  echo "No changes to commit"
fi

# Cleanup
rm -rf "$BACKUP_DIR" 2>/dev/null || true

echo "=========================================="
echo "All files pushed successfully!"
echo "made in AVASAM (https://avasam.ir)"
echo "=========================================="