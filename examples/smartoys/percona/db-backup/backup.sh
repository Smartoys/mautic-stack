#!/bin/bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_PORT:=3306}"
: "${DB_NAME:?}"
: "${DB_USER:?}"
: "${DB_PASSWORD:?}"
: "${SSH_HOST:?}"
: "${SSH_PORT:=22}"
: "${SSH_USER:?}"
: "${SSH_KEY:?}"
: "${REMOTE_PATH:?}"

log() { echo "[$(date -u +%FT%TZ)] $*"; }

TS=$(date -u +%Y%m%d_%H%M%S)
FILE="${DB_NAME}_${TS}.sql.gz"
TMP="/tmp/$FILE"
ERR=/tmp/dump.err

log "dump $DB_NAME -> $FILE"

set +e
mariadb-dump \
  -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" "-p$DB_PASSWORD" \
  --ssl=0 \
  --single-transaction --quick --lock-tables=false \
  --routines --triggers \
  --max-allowed-packet=1G \
  --no-tablespaces \
  "$DB_NAME" 2>"$ERR" | gzip --best > "$TMP"
RC=${PIPESTATUS[0]}
set -e

if [ "$RC" -ne 0 ]; then
  log "ERROR mysqldump rc=$RC"
  cat "$ERR" >&2
  exit "$RC"
fi

SIZE=$(stat -c %s "$TMP")
log "dump done size=${SIZE}"

BATCH=$(mktemp)
cat > "$BATCH" <<EOF
cd $REMOTE_PATH
put $TMP $FILE
EOF

set +e
sftp -i "$SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  -o UserKnownHostsFile=/root/.ssh/known_hosts \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -P "$SSH_PORT" \
  -b "$BATCH" \
  "$SSH_USER@$SSH_HOST"
RC=$?
set -e
rm -f "$BATCH"

if [ "$RC" -ne 0 ]; then
  log "ERROR sftp rc=$RC -- keeping local: $TMP"
  exit "$RC"
fi

log "upload OK"
rm -f "$TMP" "$ERR"
log "DONE"
