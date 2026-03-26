#!/bin/bash
set -e

DB_SRC_HOST="192.168.81.48"
DB_SRC_USER="root"
DB_SRC_PASS="g9uL5mCWTk1YIq92"
DB_SRC_NAME="mailing"

DB_DST_USER="root"
DB_DST_PASS="v2j2qrqvtv"
DB_DST_NAME="mautic_db_smartoys"
CONTAINER="percona-db"

echo "==> Dropping and recreating target database..."
docker exec "$CONTAINER" mysql -u "$DB_DST_USER" -p"$DB_DST_PASS" -e "DROP DATABASE IF EXISTS $DB_DST_NAME; CREATE DATABASE $DB_DST_NAME;"

echo "==> Dumping and importing..."
mysqldump -h "$DB_SRC_HOST" -u "$DB_SRC_USER" -p"$DB_SRC_PASS" \
  --single-transaction --quick --compression-algorithms=zlib \
  --routines --triggers --net-buffer-length=32768 \
  "$DB_SRC_NAME" \
  | pv \
  | (echo "SET FOREIGN_KEY_CHECKS=0; SET UNIQUE_CHECKS=0; SET AUTOCOMMIT=0;" && cat && echo "COMMIT; SET FOREIGN_KEY_CHECKS=1; SET UNIQUE_CHECKS=1;") \
  | docker exec -i "$CONTAINER" mysql -u "$DB_DST_USER" -p"$DB_DST_PASS" "$DB_DST_NAME"

echo "==> Done!"
