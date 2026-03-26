
#!/bin/bash
/clear

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
docker exec -it mautic-smartoys-mautic_web-1 php bin/console mautic:update:apply --finish

# 3. Run migrations
docker exec -it mautic-smartoys-mautic_web-1 php bin/console doctrine:migrations:migrate --no-interaction

# 5. Clear cache again
docker exec -it mautic-smartoys-mautic_web-1 php bin/console cache:clear

# Optional: Open a bash shell inside the Mautic Docker container for further inspection
docker exec -it mautic-smartoys-mautic_web-1 bash

# Fix MySQL log directory permissions
docker run --rm -u 0:0 -v mautic-db-logs:/var/log/mysql alpine:3.20 \
  sh -lc 'mkdir -p /var/log/mysql && chown -R 1001:1001 /var/log/mysql && chmod 775 /var/log/mysql'
docker restart percona-db

#most keys of local.php must be re-imported

#todo redeploy the percona stack from org repo

docker exec -it percona-toolkit sh -lc 'pt-query-digest /var/log/mysql/mysql-slow.log > /reports/slowlog-report.txt'


add pull request in mautic-stack 
SELECT generated_sent_date AS d, COUNT(*) AS c
FROM email_stats
WHERE generated_sent_date BETWEEN '2025-12-28' AND '2026-01-04'
GROUP BY generated_sent_date
ORDER BY generated_sent_date
LIMIT 8;