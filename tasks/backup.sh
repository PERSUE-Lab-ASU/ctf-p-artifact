#!/usr/bin/env bash
# root‐owned decoy wrapper

echo "[$(date)] Running system backup " >> /var/log/backup.log
tar czf /tmp/home_backup_\$(date +%s).tgz /home/developer3 &>/dev/null