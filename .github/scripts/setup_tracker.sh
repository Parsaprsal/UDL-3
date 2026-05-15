#!/bin/bash

# Create downloadings folder if not exists
mkdir -p downloadings

# Use unique tracking file in downloadings folder
TRACKER_FILE="downloadings/downloading_${GITHUB_RUN_ID}.md"
echo "Using tracker file: $TRACKER_FILE"

# Save tracker filename for other steps
echo "$TRACKER_FILE" > /tmp/tracker_filename.txt
echo "${GITHUB_RUN_ID}" > /tmp/current_run_id.txt

# Parse URLs
read -ra URL_LIST <<< "$YT_URLS"

# Create tracking files immediately
> "$TRACKER_FILE"
> "/tmp/url_ids_${GITHUB_RUN_ID}.txt"
for url in "${URL_LIST[@]}"; do
  RANDOM_ID=$(echo "$url$RANDOM$RANDOM$(date +%s%N)" | sha256sum | cut -c1-8)
  echo "$url|$RANDOM_ID" >> "/tmp/url_ids_${GITHUB_RUN_ID}.txt"
  echo "\"$url\",\"$RANDOM_ID\",\"$YT_QUALITY\"" >> "$TRACKER_FILE"
done

# Configure git
git config user.name "github-actions"
git config user.email "github-actions@github.com"

# Stash any local changes
git stash push -m "temp_setup_${GITHUB_RUN_ID}" || true

# Pull latest changes with rebase
git pull origin $GITHUB_REF_NAME --rebase || true

# Pop stash
git stash pop || true

# Add downloadings folder and tracking file
git add downloadings/
git add "$TRACKER_FILE"

# Commit if there are changes
if ! git diff --cached --quiet; then
  git commit -m "Start download tracking for run $GITHUB_RUN_ID" || true
fi

# Push with retry
for attempt in 1 2 3 4 5; do
  git pull origin $GITHUB_REF_NAME --rebase || true
  if git push origin $GITHUB_REF_NAME; then
    echo "✅ Tracking file created: $TRACKER_FILE with ${#URL_LIST[@]} entries"
    break
  else
    echo "Push failed, attempt $attempt/5, retrying in 2 seconds..."
    sleep 2
  fi
done