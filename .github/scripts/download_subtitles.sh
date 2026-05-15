#!/bin/bash

set +e
BACKUP_DIR=$(cat /tmp/backup_dir_path.txt)
REPO_OWNER=$(cat /tmp/yt_repo_owner.txt)
REPO_NAME=$(cat /tmp/yt_repo_name.txt)
BRANCH=$(cat /tmp/yt_branch.txt)
mapfile -t URL_LIST < /tmp/yt_urls.txt

sub_download() {
  local MODE=$1
  local OUT="$2"
  local SURL="$3"
  local SUB_DIR=$(dirname "$OUT")

  sub_count() { find "$SUB_DIR" -type f \( -name "*.vtt" -o -name "*.srt" \) 2>/dev/null | wc -l; }
  fa_count() { find "$SUB_DIR" -type f \( -name "*.fa.vtt" -o -name "*.fa.srt" \) 2>/dev/null | wc -l; }
  en_count() { find "$SUB_DIR" -type f \( -name "*.en.vtt" -o -name "*.en.srt" \) 2>/dev/null | wc -l; }

  sub_flags() {
    case $MODE in
      all) echo "--write-sub --sub-langs fa,en" ;;
      fa-native) echo "--write-sub --sub-langs fa" ;;
      fa-auto) echo "--write-auto-sub --sub-langs fa" ;;
      en-auto) echo "--write-auto-sub --sub-langs en" ;;
      auto-both) echo "--write-auto-sub --sub-langs en,fa" ;;
    esac
  }
  SFLAGS=$(sub_flags)
  COMMON_SUB="--sub-format vtt/srt/best --convert-subs vtt --skip-download --no-playlist --no-check-certificates --output ${OUT}"

  for METHOD in 1 2 3 4 5 6 7 8; do
    echo "  [subtitle] method $METHOD ..."
    case $METHOD in
      1) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=web" --js-runtimes deno --remote-components ejs:github $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      2) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=web" --js-runtimes deno --remote-components ejs:npm $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      3) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=web,mweb,android_vr" --js-runtimes deno --remote-components ejs:github $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      4) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=mweb" $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      5) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=android_vr" $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      6) yt-dlp --extractor-args "youtube:player_client=web" --js-runtimes deno --remote-components ejs:github $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      7) yt-dlp --extractor-args "youtube:player_client=mweb" $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
      8) yt-dlp --proxy "socks5://127.0.0.1:1080" --extractor-args "youtube:player_client=android" $SFLAGS $COMMON_SUB "$SURL" 2>&1 || true ;;
    esac

    if [ "$MODE" = "fa-native" ] || [ "$MODE" = "fa-auto" ]; then
      [ "$(fa_count)" -gt 0 ] && return 0
    elif [ "$MODE" = "en-auto" ]; then
      [ "$(en_count)" -gt 0 ] && return 0
    elif [ "$MODE" = "auto-both" ]; then
      [ "$(en_count)" -gt 0 ] && [ "$(fa_count)" -gt 0 ] && return 0
    else
      [ "$(sub_count)" -gt 0 ] && return 0
    fi
    sleep 1
  done
  return 1
}

URL_INDEX=0
while IFS='|' read -r ORIGINAL_NAME FOLDER_NAME; do
  URL_INDEX=$((URL_INDEX + 1))
  URL="${URL_LIST[$((URL_INDEX - 1))]}"
  [ -z "$FOLDER_NAME" ] && continue

  SUBTITLE_DIR="$BACKUP_DIR/${FOLDER_NAME}/subtitle"
  mkdir -p "$SUBTITLE_DIR"
  OUT_TMPL="${SUBTITLE_DIR}/%(title)s"

  echo ""
  echo "============================================================"
  echo "Downloading subtitles for: $FOLDER_NAME"
  echo "============================================================"

  sub_download "all" "$OUT_TMPL" "$URL" || true
  EN_COUNT=$(find "$SUBTITLE_DIR" -type f \( -name "*.en.vtt" -o -name "*.en.srt" \) 2>/dev/null | wc -l)
  FA_COUNT=$(find "$SUBTITLE_DIR" -type f \( -name "*.fa.vtt" -o -name "*.fa.srt" \) 2>/dev/null | wc -l)

  if [ "$EN_COUNT" -eq 0 ] || [ "$FA_COUNT" -eq 0 ]; then
    sub_download "auto-both" "$OUT_TMPL" "$URL" || true
  fi

  SUB_COUNT=$(find "$SUBTITLE_DIR" -type f 2>/dev/null | wc -l)
  if [ "$SUB_COUNT" -eq 0 ]; then
    rmdir "$SUBTITLE_DIR" 2>/dev/null || true
  else
    ZIP_PATH="$BACKUP_DIR/${FOLDER_NAME}/subtitle.zip"
    (cd "$SUBTITLE_DIR" && zip -j "$ZIP_PATH" ./* 2>&1) && rm -rf "$SUBTITLE_DIR"
    echo "✅ Subtitles saved to $ZIP_PATH"
  fi
done < /tmp/video_info.txt
set -e
echo "✅ Subtitle step completed"