#!/bin/bash

# Start script that will wait for mautic to be installed before setting up cron jobs
/startup/wait_for_mautic_install.sh

mkdir -p /opt/mautic/cron

# Seed cron file from the baked-in template.
# Set DOCKER_MAUTIC_RESET_CRON=true to force overwrite from /templates/mautic_cron
# on every start (useful when the image template has been updated and you want
# to adopt the new schedule). A timestamped backup is kept beside the file.
if [ "${DOCKER_MAUTIC_RESET_CRON:-false}" = "true" ] && [ -f /opt/mautic/cron/mautic ]; then
  cp -p /opt/mautic/cron/mautic "/opt/mautic/cron/mautic.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  cp -p /templates/mautic_cron /opt/mautic/cron/mautic
  echo "[entrypoint_mautic_cron] DOCKER_MAUTIC_RESET_CRON=true — overwrote /opt/mautic/cron/mautic from template (backup saved)"
elif [ ! -f /opt/mautic/cron/mautic ]; then
  cp -p /templates/mautic_cron /opt/mautic/cron/mautic
fi

# register the crontab file for the www-data user
crontab -u www-data /opt/mautic/cron/mautic

# if /tmp/stdout exists clear it out
if [ ! -p /tmp/stdout ]; then
  rm -f /tmp/stdout
fi
# create the fifo file to be able to redirect cron output for non-root users
mkfifo /tmp/stdout
chmod 777 /tmp/stdout

# Re-export container env to cron jobs via BASH_ENV=/tmp/cron.env (set in the
# crontab header). Cron strips its children's env by design, but local.php
# reads MAUTIC_DB_* at runtime via getenv(); without this dump, every job
# crashes with `Path must not be empty` on the file_get_contents() fallback.
#
# declare -p emits `declare -x KEY="VALUE"` lines with safe quoting, so values
# containing spaces or special characters source cleanly (unlike `env >`).
declare -p \
  | grep -E '^declare -[ax]+ (PHP_INI_VALUE_|MAUTIC_|DOCKER_MAUTIC|RABBITMQ_|MYSQL_|APP_|SYMFONY_|MAILER_)' \
  > /tmp/cron.env

# run cron and print the output
cron -f | tail -f /tmp/stdout
