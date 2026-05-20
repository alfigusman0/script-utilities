#!/bin/bash

# Log file for cronjob
LOG_FILE="/root/report.txt"
MAX_LOG_SIZE=5242880  # 5MB

# ── Rotate log if too large ──────────────────────────────────────────────────
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -ge "$MAX_LOG_SIZE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d%H%M%S).bak"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ── Load nvm ─────────────────────────────────────────────────────────────────
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm use --lts >> "$LOG_FILE" 2>&1 || { log "ERROR: nvm use --lts failed"; exit 1; }

# Verify node and npm
node -e "console.log('Node OK')" >> "$LOG_FILE" 2>&1
log "Node: $(node --version) | npm: $(npm --version)"
export NODE_OPTIONS=--max-old-space-size=8192

# ── Repository list ──────────────────────────────────────────────────────────
repos=(
    "/var/www/folder/api|NodeJS"
    "/var/www/folder/backend|CI3"
    "/var/www/folder/frontend|ReactJS"
    "/var/www/folder/test|*"
)

log "Starting deploy process for ${#repos[@]} repo(s)"

# ── Main loop ────────────────────────────────────────────────────────────────
for repo_entry in "${repos[@]}"; do
    repo_path="${repo_entry%%|*}"
    repo_type="${repo_entry##*|}"

    log "====== Processing: ${repo_path} (${repo_type}) ======"

    # Validate directory
    if [ ! -d "$repo_path" ]; then
        log "ERROR: Directory not found: ${repo_path}, skipping."
        continue
    fi

    cd "$repo_path" || { log "ERROR: Cannot cd into ${repo_path}"; continue; }

    # ── Git fetch & compare ──────────────────────────────────────────────────
    git fetch origin production >> "$LOG_FILE" 2>&1 || { log "ERROR: git fetch failed for ${repo_path}"; continue; }

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/production 2>/dev/null)

    if [ -z "$REMOTE" ]; then
        log "ERROR: Cannot resolve origin/production for ${repo_path}"
        continue
    fi

    if [ "$LOCAL" = "$REMOTE" ]; then
        log "No updates for ${repo_path}, skipping."
        log "=========================================="
        continue
    fi

    log "Updates found ($LOCAL -> $REMOTE), pulling..."
    git pull origin production >> "$LOG_FILE" 2>&1 || { log "ERROR: git pull failed for ${repo_path}"; continue; }

    CHANGED_FILES=$(git diff --name-only "$LOCAL" "$REMOTE" 2>/dev/null)

    # ── Handle by type ───────────────────────────────────────────────────────
    case "$repo_type" in

    "CI3")
        if echo "$CHANGED_FILES" | grep -qE 'composer\.json'; then
            log "composer.json changed, running composer install & update..."
            COMPOSER_ALLOW_SUPERUSER=1 composer install >> "$LOG_FILE" 2>&1 \
                || { log "ERROR: composer install failed"; continue; }
            COMPOSER_ALLOW_SUPERUSER=1 composer update >> "$LOG_FILE" 2>&1 \
                || { log "ERROR: composer update failed"; continue; }
        else
            log "No composer.json changes, skipping composer."
        fi
        ;;

    "NodeJS")
        if echo "$CHANGED_FILES" | grep -qE 'package\.json'; then
            log "package.json changed, running npm install..."
            npm install >> "$LOG_FILE" 2>&1 || { log "ERROR: npm install failed"; continue; }
            npm update  >> "$LOG_FILE" 2>&1 || { log "ERROR: npm update failed"; continue; }
        else
            log "No package.json changes, skipping npm install."
        fi
        ;;

    "ReactJS")
        # 1. Install dependencies jika package.json berubah
        if echo "$CHANGED_FILES" | grep -qE 'package\.json'; then
            log "package.json changed, running npm install..."
            npm install >> "$LOG_FILE" 2>&1 || { log "ERROR: npm install failed"; continue; }
            npm update  >> "$LOG_FILE" 2>&1 || { log "ERROR: npm update failed"; continue; }
        else
            log "No package.json changes, skipping npm install."
        fi

        # 2. Build (selalu jika ada perubahan apapun)
        if [ -n "$CHANGED_FILES" ]; then
            log "Changes detected, running npm run build..."
            npm run build >> "$LOG_FILE" 2>&1 || { log "ERROR: npm run build failed"; continue; }

            # 3. Reload pm2 agar hasil build langsung aktif tanpa downtime
            log "Build success, reloading pm2..."
            pm2 reload all >> "$LOG_FILE" 2>&1 || log "WARNING: pm2 reload failed (non-fatal)"
        else
            log "No file changes detected, skipping build & pm2 reload."
        fi
        ;;

    *)
        log "Unknown type '${repo_type}', only git pull was performed."
        ;;

    esac

    log "====== Done: ${repo_path} ======"
done

log "Deploy process completed"