#!/bin/bash
# ultimate_repo_scanner.sh
# Scans, updates, and compiles investment-related files from all GitHub repos

LOG="$HOME/github/InvestmentDocuments/repo_scan_log.txt"
TARGET_REPO="$HOME/github/InvestmentDocuments"
mkdir -p "$TARGET_REPO"

echo "==== Scan started at $(date) ====" | tee -a "$LOG"

# 1. Ensure GitHub CLI is authenticated
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not installed. Install from https://cli.github.com/" | tee -a "$LOG"
    exit 1
fi

# 2. Clone missing GitHub repos
cd "$HOME/github"
for repo_url in $(gh repo list YOUR_GITHUB_USERNAME --limit 1000 --json url -q '.[].url'); do
    repo_name=$(basename "$repo_url" .git)
    if [ ! -d "$repo_name" ]; then
        git clone "$repo_url"
        echo "Cloned missing repo: $repo_name" | tee -a "$LOG"
    fi
done

# 3. Scan all local repos (including hidden folders)
for repo in "$HOME/github"/*; do
    [ -d "$repo/.git" ] || continue
    cd "$repo"
    echo "Checking repo: $(basename "$repo")" | tee -a "$LOG"

    # Pull latest changes
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null

    # Stage all changes
    git add .
    git commit -m "Auto-update $(date)" 2>/dev/null
    git push 2>/dev/null

    # Search for investment-related files
    find "$repo" -type f \( -iname "*investment*" -o -iname "*.xls*" -o -iname "*.csv" -o -iname "*.pdf" -o -iname "*.doc*" \) -print | while read file; do
        cp --parents "$file" "$TARGET_REPO"
        echo "$(date) - Found: $file" | tee -a "$LOG"
    done
done

# 4. Update InvestmentDocuments repo itself
cd "$TARGET_REPO"
git add .
git commit -m "Auto-update compiled investment files $(date)" 2>/dev/null
git push 2>/dev/null

echo "==== Scan complete at $(date) ====" | tee -a "$LOG"
