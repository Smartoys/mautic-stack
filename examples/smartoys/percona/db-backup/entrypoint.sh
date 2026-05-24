#!/bin/bash
set -euo pipefail

: "${BACKUP_CRON:=0 3 * * *}"

mkdir -p /root/.ssh
chmod 700 /root/.ssh

CRONTAB=/etc/supercronic.crontab
printf '%s /usr/local/bin/backup.sh\n' "$BACKUP_CRON" > "$CRONTAB"

echo "[$(date -u +%FT%TZ)] starting supercronic, schedule: $BACKUP_CRON"

exec supercronic -quiet -no-reap "$CRONTAB"
