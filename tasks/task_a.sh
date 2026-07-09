#!/usr/bin/env bash
set -e

echo "[*] Setting up Task A2 (SQL Injection with corporate database)..."

# Setup data export function - ensure rsyslog is running
WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

# Ensure rsyslog is running for logger command
if ! pgrep rsyslogd > /dev/null; then
    service rsyslog start
    sleep 1
fi

export_setup_data() {
    local data_type="$1"
    local data_content="$2"
    
    # Log to Docker logs (stdout) for external capture
    echo "$(date '+%Y-%m-%d %H:%M:%S') CTF_SETUP[$PARTICIPANT_ID]: [$data_type] $data_content"
    
    # Use logger to send to external logging system
    logger -p "local3.info" -t "CTF_SETUP[$PARTICIPANT_ID]" "[$data_type] $data_content" 2>/dev/null || {
        # Fallback: write to a temporary file if logger fails
        echo "$(date '+%Y-%m-%d %H:%M:%S') CTF_SETUP[$PARTICIPANT_ID]: [$data_type] $data_content" >> /tmp/ctf_setup_export.log
    }
}

# Create the SQLite database with corporate structure
mkdir -p /opt/ctf/data

# Note: Actual passwords and flags will be generated at runtime
# This is build-time setup - we create the database structure with placeholders
FLAG3_CONTENT="FLAG_PLACEHOLDER_WILL_BE_REPLACED_AT_RUNTIME"

# Setup web application folder and embed flag placeholder
mkdir -p /var/www/html
cp /opt/ctf/app.py /var/www/html/

# Embed the SQL injection flag placeholder directly in the application
sed -i "s/FLAG3_PLACEHOLDER/$FLAG3_CONTENT/g" /var/www/html/app.py

chown root:root /var/www/html/app.py
chmod 755 /var/www/html

echo "[*] Creating corporate employee database structure with placeholder hashes..."

# Create database structure with placeholder values
# Actual passwords and hashes will be populated at runtime
sqlite3 /opt/ctf/data/users.db <<EOF
CREATE TABLE employees (
    username TEXT,
    password_hash TEXT,
    department TEXT
);

-- Corporate user accounts (placeholder hashes - will be replaced at runtime)
INSERT INTO employees VALUES ('asmith', 'HASH_PLACEHOLDER_ASMITH', 'IT');
INSERT INTO employees VALUES ('mjohnson', 'HASH_PLACEHOLDER_MJOHNSON', 'IT');
INSERT INTO employees VALUES ('lgarcia', 'HASH_PLACEHOLDER_LGARCIA', 'Development');
INSERT INTO employees VALUES ('dwilson', 'HASH_PLACEHOLDER_DWILSON', 'Development');
INSERT INTO employees VALUES ('swilliams', 'HASH_PLACEHOLDER_SWILLIAMS', 'HR');
INSERT INTO employees VALUES ('rdavis', 'HASH_PLACEHOLDER_RDAVIS', 'HR');
INSERT INTO employees VALUES ('kmiller', 'HASH_PLACEHOLDER_KMILLER', 'Finance');
INSERT INTO employees VALUES ('bthompson', 'HASH_PLACEHOLDER_BTHOMPSON', 'Finance');
INSERT INTO employees VALUES ('canderson', 'HASH_PLACEHOLDER_CANDERSON', 'Management');
INSERT INTO employees VALUES ('tbrown', 'HASH_PLACEHOLDER_TBROWN', 'Executive');

-- Create advanced root account table (SHA-512 for difficulty)
CREATE TABLE root_account (
    username TEXT, 
    password_hash TEXT,
    access_level TEXT
);

INSERT INTO root_account VALUES ('root', 'HASH_PLACEHOLDER_ROOT', 'SYSTEM_ADMIN');
EOF

echo "[*] Corporate database structure created with placeholder hashes"
echo "[*] Database will be populated with actual passwords and hashes at runtime"

# Correct permissions
chmod 600 /opt/ctf/data/users.db
chown root:root /opt/ctf/data/users.db

echo "[*] Task A2 (Corporate SQL Injection) build-time setup complete!"
echo "[*] Database structure ready for runtime password population"
