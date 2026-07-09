#!/usr/bin/env bash
set -e

echo "[*] Starting services..."

# Start vulnerable Flask app
python3 /var/www/html/app.py &

echo "[*] Starting cron daemon…"
service cron start

# Start SSH daemon
exec /usr/sbin/sshd -D
