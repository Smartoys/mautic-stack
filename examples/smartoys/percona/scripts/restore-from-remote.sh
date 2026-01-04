
#!/bin/bash

# Dump the remote database to a local SQL file
mysqldump -h 192.168.81.48 -u root -pg9uL5mCWTk1YIq92 --single-transaction --quick mailing | pv > mailing_dump.sql


# Drop all tables in the target database

docker exec -i percona-db mysql -u root -pv2j2qrqvtv mautic_db_smartoys -e "
SET FOREIGN_KEY_CHECKS = 0;
SET @tables = NULL;
SELECT GROUP_CONCAT(table_name) INTO @tables FROM information_schema.tables WHERE table_schema = 'mautic_db_smartoys';
SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables);
PREPARE stmt FROM @tables;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET FOREIGN_KEY_CHECKS = 1;
"

# Restore the database from the SQL dump file

(
  echo "SET FOREIGN_KEY_CHECKS=0; SET UNIQUE_CHECKS=0; SET AUTOCOMMIT=0; SET SESSION sql_log_bin=0;"
  cat mailing_dump.sql
  echo "COMMIT; SET FOREIGN_KEY_CHECKS=1; SET UNIQUE_CHECKS=1;"
) | pv -pterba -s $(stat -c%s mailing_dump.sql) | docker exec -i percona-db mysql -u root -pv2j2qrqvtv --max_allowed_packet=512M mautic_db_smartoys


# Run Mautic migrations inside the Mautic Docker container
# 1. Clear cache first (important!)
docker exec -it mautic-smartoys-mautic_web-1 php bin/console cache:clear

# 2. Check migration status (see what's pending)
docker exec -it mautic-smartoys-mautic_web-1 php bin/console doctrine:migrations:status

# 3. Run migrations
docker exec -it mautic-smartoys-mautic_web-1 php bin/console doctrine:migrations:migrate --no-interaction

# 4. Update Mautic-specific schema
docker exec -it mautic-smartoys-mautic_web-1 php bin/console mautic:update:apply --force

# 5. Clear cache again
docker exec -it mautic-smartoys-mautic_web-1 php bin/console cache:clear

