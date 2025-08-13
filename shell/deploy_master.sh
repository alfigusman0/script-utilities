#!/bin/bash

# Log file for cronjob
LOG_FILE="/root/report.txt"

# Load nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use --lts >> "$LOG_FILE" 2>&1

# Verify node and npm
node -e "console.log('hello')" >> "$LOG_FILE" 2>&1
node --version >> "$LOG_FILE" 2>&1
npm --version >> "$LOG_FILE" 2>&1
export NODE_OPTIONS=--max-old-space-size=8192

# Define repositories and their types
repos=(
    "/var/www/folder/api|NodeJS"
    "/var/www/folder/backend|CI3"
    "/var/www/folder/frontend|ReactJS"
)

echo "[$(date)] Starting update and deploy process for ${#repos[@]} repositories" >> "$LOG_FILE"

for repo_entry in "${repos[@]}"
do
    # Split repo path and type
    repo_path=$(echo "$repo_entry" | cut -d'|' -f1)
    repo_type=$(echo "$repo_entry" | cut -d'|' -f2)

    echo "[$(date)] ****** Processing repository: ${repo_path} (Type: ${repo_type}) ******" >> "$LOG_FILE"
    cd "${repo_path}" || { echo "[$(date)] Failed to change to ${repo_path}" >> "$LOG_FILE"; exit 1; }

    # Fetch latest changes without merging
    git fetch origin master >> "$LOG_FILE" 2>&1


    # Check if local branch is behind origin/master
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/master)
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "[$(date)] Updates available, pulling changes from origin/master" >> "$LOG_FILE"
        git pull origin master >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Git pull failed for ${repo_path}" >> "$LOG_FILE"; exit 1; }

        # Handle based on repository type
        case "$repo_type" in
        "CI3")
            # Check for changes in composer.json
            if git diff --name-only "$LOCAL" "$REMOTE" | grep -E 'composer.json'; then
                echo "[$(date)] Changes detected in composer.json, running composer update..." >> "$LOG_FILE"
                COMPOSER_ALLOW_SUPERUSER=1 composer install >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Composer update failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
                COMPOSER_ALLOW_SUPERUSER=1 composer update >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Composer update failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
            else
                echo "[$(date)] No changes in composer.json, skipping composer update." >> "$LOG_FILE"
            fi
            ;;
        "NodeJS")
            # Check for changes in package.json
            if git diff --name-only "$LOCAL" "$REMOTE" | grep -E 'package.json'; then
                echo "[$(date)] Changes detected in package.json, running npm update..." >> "$LOG_FILE"
                npm install >> "$LOG_FILE" 2>&1 || { echo "[$(date)] npm install failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
                npm update >> "$LOG_FILE" 2>&1 || { echo "[$(date)] npm update failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
            else
                echo "[$(date)] No changes in package.json, skipping npm update." >> "$LOG_FILE"
            fi
            ;;
        "ReactJS")
            # Check for changes in package.json
            if git diff --name-only "$LOCAL" "$REMOTE" | grep -E 'package.json'; then
                echo "[$(date)] Changes detected in package.json, running npm install..." >> "$LOG_FILE"
                npm install >> "$LOG_FILE" 2>&1 || { echo "[$(date)] npm install failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
                npm update >> "$LOG_FILE" 2>&1 || { echo "[$(date)] npm update failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
            else
                echo "[$(date)] No changes in package.json, skipping npm install." >> "$LOG_FILE"
            fi

            # Check for any changes in the frontend directory
            if git diff --name-only "$LOCAL" "$REMOTE"; then
                echo "[$(date)] Changes detected in ${repo_path}, running npm run build..." >> "$LOG_FILE"
                npm run build >> "$LOG_FILE" 2>&1 || { echo "[$(date)] Build failed in ${repo_path}" >> "$LOG_FILE"; exit 1; }
            else
                echo "[$(date)] No changes in ${repo_path}, skipping npm run build." >> "$LOG_FILE"
            fi
            ;;
        *)
            echo "[$(date)] Unknown repository type: ${repo_type}, skipping processing." >> "$LOG_FILE"
            ;;
        esac
    else
        echo "[$(date)] No updates available for ${repo_path}, skipping pull and processing." >> "$LOG_FILE"
    fi
        echo "[$(date)] ******************************************" >> "$LOG_FILE"
done

echo "[$(date)] Update and deploy process completed" >> "$LOG_FILE"