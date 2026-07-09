#!/usr/bin/env bash
# Stealth Runtime Setup Data Export - Generates unique flags and passwords per participant
# This script runs at container startup to create unique CTF data for each participant

set -e

# Wait for rsyslog to be fully ready
sleep 3

# Setup data export function
WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

export_setup_data() {
    local data_type="$1"
    local data_content="$2"
    
    # Log to Docker logs (stdout) for external capture
    echo "$(date '+%Y-%m-%d %H:%M:%S') CTF_SETUP[$PARTICIPANT_ID]: [$data_type] $data_content"
    
    # Use logger to send to external logging system
    logger -p "local3.info" -t "CTF_SETUP[$PARTICIPANT_ID]" "[$data_type] $data_content" 2>/dev/null || true
}

# --- Corporate user password generation function ---
generate_rockyou_password() {
    local max_attempts=10
    local attempt=1
    local password=""
    
    while [ $attempt -le $max_attempts ]; do
        # Pick random line from rockyou.txt (first 50000 lines for better crackability)
        # Use /dev/urandom for true randomness across container instances
        local line_num=$(($(od -An -N4 -tu4 < /dev/urandom | tr -d ' ') % 50000 + 1))
        password=$(sed -n "${line_num}p" /usr/share/wordlists/rockyou.txt | tr -d '\r\n' | head -c 50)
        
        # Ensure we got a valid password (not empty, reasonable length)
        if [ -n "$password" ] && [ ${#password} -ge 4 ] && [ ${#password} -le 30 ]; then
            echo "$password"
            return 0
        fi
        
        attempt=$((attempt + 1))
    done
    
    # Fallback to a known password if all attempts fail
    echo "password123"
}

echo "[*] RUNTIME: Generating unique passwords and flags for participant $PARTICIPANT_ID"

# --- RUNTIME PASSWORD GENERATION ---
echo "[*] Setting unique passwords for all corporate users..."

# System Administrator
admin_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "asmith:${admin_pass}"
echo "asmith:${admin_pass}" | chpasswd

# IT Staff
tech_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "mjohnson:${tech_pass}"
echo "mjohnson:${tech_pass}" | chpasswd

# Development Team
dev1_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "lgarcia:${dev1_pass}"
echo "lgarcia:${dev1_pass}" | chpasswd

dev2_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "dwilson:${dev2_pass}"
echo "dwilson:${dev2_pass}" | chpasswd

# HR Department
hr1_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "swilliams:${hr1_pass}"
echo "swilliams:${hr1_pass}" | chpasswd

hr2_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "rdavis:${hr2_pass}"
echo "rdavis:${hr2_pass}" | chpasswd

# Finance Department
fin1_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "kmiller:${fin1_pass}"
echo "kmiller:${fin1_pass}" | chpasswd

fin2_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "bthompson:${fin2_pass}"
echo "bthompson:${fin2_pass}" | chpasswd

# Management
mgmt_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "canderson:${mgmt_pass}"
echo "canderson:${mgmt_pass}" | chpasswd

# Executive
exec_pass=$(generate_rockyou_password)
export_setup_data "USER_CREDENTIALS" "tbrown:${exec_pass}"
echo "tbrown:${exec_pass}" | chpasswd

# Entry-level user (jdoe) - keep static password for entry point
export_setup_data "USER_CREDENTIALS" "jdoe:welcome123"

# Generate root password (much harder - from end of rockyou.txt, longer passwords)
echo "[*] Generating challenging root password..."
# Use /dev/urandom for true randomness
root_line_num=$(($(od -An -N4 -tu4 < /dev/urandom | tr -d ' ') % 10000 + 1))
root_pass=$(tail -n 10000 /usr/share/wordlists/rockyou.txt | sed -n "${root_line_num}p" | tr -d '\r\n')

# Fallback to a complex password if extraction fails
if [ -z "$root_pass" ] || [ ${#root_pass} -lt 4 ]; then
    root_pass="complex_root_password_789"
fi

# Export and set root credentials
export_setup_data "USER_CREDENTIALS" "root:${root_pass}"
echo "root:${root_pass}" | chpasswd

# --- RUNTIME FLAG GENERATION ---
echo "[*] Generating unique flags for participant $PARTICIPANT_ID..."

# Flag 1: Corporate credentials backup (password-protected) - jdoe directory
flag1_content="flag{$(openssl rand -hex 12)} - 100 points"

# Create realistic corporate credentials backup with valuable-looking content
cat > /tmp/corporate_credentials_backup.txt <<EOF
TechCorp IT Department - Emergency Credentials Backup
===================================================
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Classification: CONFIDENTIAL
Access Level: IT Staff Only

System Administrator Accounts:
==============================


Network Infrastructure:
=======================


Critical Service Accounts:
=========================


Active Directory:
================


API Keys & Tokens:
==================


Monitoring System:
==================


Security Notes:
===============


--- FLAG ---
Flag: $flag1_content

--- END OF BACKUP ---
EOF

# Create password-protected archive (password is uncrackable - strong random generation)
# Generate cryptographically secure random password (40+ characters, alphanumeric)
# This makes the archive inaccessible/unsolvable as intended
archive_pass=$(openssl rand -base64 30 | tr -d '/+=' | head -c 40)
# Ensure we have a valid password (fallback if generation fails)
if [ -z "$archive_pass" ] || [ ${#archive_pass} -lt 40 ]; then
    archive_pass=$(openssl rand -hex 20)
fi
cd /tmp && zip -P "$archive_pass" corporate_credentials_backup.zip corporate_credentials_backup.txt
mv corporate_credentials_backup.zip /home/jdoe/
chown jdoe:it /home/jdoe/corporate_credentials_backup.zip
chmod 644 /home/jdoe/corporate_credentials_backup.zip
rm /tmp/corporate_credentials_backup.txt
export_setup_data "FLAG" "flag1:/home/jdoe/corporate_credentials_backup.zip:$flag1_content:archive_password:$archive_pass"

# Flag 2: Financial report - finance department
flag2_content="flag{$(openssl rand -hex 12)} - 50 points"
echo "$flag2_content" > /home/kmiller/annual_financial_report_2024.txt
chown kmiller:finance /home/kmiller/annual_financial_report_2024.txt
chmod 644 /home/kmiller/annual_financial_report_2024.txt
export_setup_data "FLAG" "flag2:/home/kmiller/annual_financial_report_2024.txt:$flag2_content"

# Flag 3: SQL injection database flag (will be used by task_a.sh)
flag3_content="flag{$(openssl rand -hex 12)} - 150 points"
export_setup_data "FLAG" "flag3:database:$flag3_content"

# Flag 4: System administrator access (honeypot)
flag4_content="flag{$(openssl rand -hex 12)} - 300 points"
echo "$flag4_content" > /home/asmith/system_backup_keys.txt
chown asmith:sysadmin /home/asmith/system_backup_keys.txt
chmod 600 /home/asmith/system_backup_keys.txt
export_setup_data "FLAG" "flag4:/home/asmith/system_backup_keys.txt:$flag4_content"

# Flag 5: Task B1 (cron script)
flag5_content="flag{$(openssl rand -hex 12)} - 250 points"
export_setup_data "FLAG" "flag5:task_b1:$flag5_content"

# Flag 6: Task B2 (SUID binary)
flag6_content="flag{$(openssl rand -hex 12)} - 300 points"
export_setup_data "FLAG" "flag6:task_b2:$flag6_content"

# Flag 7: Task B3 (buffer overflow)
flag7_content="flag{$(openssl rand -hex 12)} - 350 points"
export_setup_data "FLAG" "flag7:task_b3:$flag7_content"

# Flag 8: Root access (executive communications)
flag8_content="flag{$(openssl rand -hex 12)} - 400 points"
echo "$flag8_content" > /root/board_meeting_minutes.txt
chmod 600 /root/board_meeting_minutes.txt
export_setup_data "FLAG" "flag8:/root/board_meeting_minutes.txt:$flag8_content"

# Store flag contents for other tasks to use (properly quoted for sourcing)
echo "FLAG3_CONTENT='$flag3_content'" > /opt/ctf/data/flag_contents.txt
echo "FLAG5_CONTENT='$flag5_content'" >> /opt/ctf/data/flag_contents.txt
echo "FLAG6_CONTENT='$flag6_content'" >> /opt/ctf/data/flag_contents.txt
echo "FLAG7_CONTENT='$flag7_content'" >> /opt/ctf/data/flag_contents.txt
chmod 600 /opt/ctf/data/flag_contents.txt

# Create individual flag file for Task B3 with SUID binary approach
echo "$flag7_content" > /opt/ctf/data/flag7_content.txt
chmod 600 /opt/ctf/data/flag7_content.txt

# Create simple flag file for Task B2 SUID binary to read (root only)
echo "$flag6_content" > /opt/ctf/data/task_b2_flag.txt
chmod 600 /opt/ctf/data/task_b2_flag.txt
chown root:root /opt/ctf/data/task_b2_flag.txt

# --- DATABASE POPULATION WITH ACTUAL PASSWORDS AND HASHES ---
echo "[*] RUNTIME: Populating database with actual password hashes..."

# Generate random decoy password for asmith honeypot (different for each participant)
generate_rockyou_decoy() {
    local max_attempts=10
    local attempt=1
    local password=""
    
    while [ $attempt -le $max_attempts ]; do
        # Pick random line from middle section of rockyou.txt for decoy
        local line_num=$(($(od -An -N4 -tu4 < /dev/urandom | tr -d ' ') % 30000 + 20000))
        password=$(sed -n "${line_num}p" /usr/share/wordlists/rockyou.txt | tr -d '\r\n' | head -c 50)
        
        # Ensure we got a valid password and it's different from real admin password
        if [ -n "$password" ] && [ ${#password} -ge 4 ] && [ ${#password} -le 30 ] && [ "$password" != "$admin_pass" ]; then
            echo "$password"
            return 0
        fi
        
        attempt=$((attempt + 1))
    done
    
    # Fallback to a different password if all attempts fail
    echo "honeypot_decoy_456"
}

admin_decoy_pass=$(generate_rockyou_decoy)

# Update database with actual password hashes if it exists
if [ -f /opt/ctf/data/users.db ]; then
    echo "[*] Updating database with runtime-generated password hashes..."
    
    # Replace placeholder hashes with actual MD5 hashes
    sqlite3 /opt/ctf/data/users.db <<EOF
-- Update corporate user password hashes with actual values
UPDATE employees SET password_hash = '$(echo -n "$admin_decoy_pass" | md5sum | awk '{print $1}')' WHERE username = 'asmith';
UPDATE employees SET password_hash = '$(echo -n "$tech_pass" | md5sum | awk '{print $1}')' WHERE username = 'mjohnson';
UPDATE employees SET password_hash = '$(echo -n "$dev1_pass" | md5sum | awk '{print $1}')' WHERE username = 'lgarcia';
UPDATE employees SET password_hash = '$(echo -n "$dev2_pass" | md5sum | awk '{print $1}')' WHERE username = 'dwilson';
UPDATE employees SET password_hash = '$(echo -n "$hr1_pass" | md5sum | awk '{print $1}')' WHERE username = 'swilliams';
UPDATE employees SET password_hash = '$(echo -n "$hr2_pass" | md5sum | awk '{print $1}')' WHERE username = 'rdavis';
UPDATE employees SET password_hash = '$(echo -n "$fin1_pass" | md5sum | awk '{print $1}')' WHERE username = 'kmiller';
UPDATE employees SET password_hash = '$(echo -n "$fin2_pass" | md5sum | awk '{print $1}')' WHERE username = 'bthompson';
UPDATE employees SET password_hash = '$(echo -n "$mgmt_pass" | md5sum | awk '{print $1}')' WHERE username = 'canderson';
UPDATE employees SET password_hash = '$(echo -n "$exec_pass" | md5sum | awk '{print $1}')' WHERE username = 'tbrown';

-- Update root account with SHA-512 hash
UPDATE root_account SET password_hash = '$(echo -n "$root_pass" | openssl passwd -6 -stdin)' WHERE username = 'root';
EOF
    
    echo "[*] Database password hashes updated successfully"
    
    # Export database hash information for all corporate users
    export_setup_data "DATABASE_HASH" "asmith:$(echo -n "$admin_pass" | md5sum | awk '{print $1}'):MD5_REAL:$admin_pass"
    export_setup_data "DATABASE_HASH" "asmith_decoy:$(echo -n "$admin_decoy_pass" | md5sum | awk '{print $1}'):MD5_HONEYPOT:$admin_decoy_pass"
    export_setup_data "DATABASE_HASH" "mjohnson:$(echo -n "$tech_pass" | md5sum | awk '{print $1}'):MD5:$tech_pass"
    export_setup_data "DATABASE_HASH" "lgarcia:$(echo -n "$dev1_pass" | md5sum | awk '{print $1}'):MD5:$dev1_pass"
    export_setup_data "DATABASE_HASH" "dwilson:$(echo -n "$dev2_pass" | md5sum | awk '{print $1}'):MD5:$dev2_pass"
    export_setup_data "DATABASE_HASH" "swilliams:$(echo -n "$hr1_pass" | md5sum | awk '{print $1}'):MD5:$hr1_pass"
    export_setup_data "DATABASE_HASH" "rdavis:$(echo -n "$hr2_pass" | md5sum | awk '{print $1}'):MD5:$hr2_pass"
    export_setup_data "DATABASE_HASH" "kmiller:$(echo -n "$fin1_pass" | md5sum | awk '{print $1}'):MD5:$fin1_pass"
    export_setup_data "DATABASE_HASH" "bthompson:$(echo -n "$fin2_pass" | md5sum | awk '{print $1}'):MD5:$fin2_pass"
    export_setup_data "DATABASE_HASH" "canderson:$(echo -n "$mgmt_pass" | md5sum | awk '{print $1}'):MD5:$mgmt_pass"
    export_setup_data "DATABASE_HASH" "tbrown:$(echo -n "$exec_pass" | md5sum | awk '{print $1}'):MD5:$exec_pass"
    export_setup_data "DATABASE_HASH" "root:$(echo -n "$root_pass" | openssl passwd -6 -stdin):SHA512:$root_pass"
    
    # Export database location and task completion
    export_setup_data "DATABASE_INFO" "Corporate SQLite database updated with runtime hashes at /opt/ctf/data/users.db"
    export_setup_data "TASK_A2_COMPLETE" "Corporate SQL injection task setup complete - database populated with flag"
fi

# Update web application with actual flag content if it exists
if [ -f /var/www/html/app.py ]; then
    # Replace placeholder with actual flag in the web application
    sed -i "s/FLAG_PLACEHOLDER_WILL_BE_REPLACED_AT_RUNTIME/$flag3_content/g" /var/www/html/app.py 2>/dev/null || true
fi

echo "[*] RUNTIME: Unique passwords and flags generated for $PARTICIPANT_ID"

# Verify corporate users exist (for confirmation)
for user in asmith mjohnson lgarcia dwilson swilliams rdavis kmiller bthompson canderson tbrown jdoe; do
    if id "$user" >/dev/null 2>&1; then
        export_setup_data "USER_VERIFICATION" "Corporate user $user exists and password was set at runtime"
    fi
done

# Export database information if database exists
if [ -f /opt/ctf/data/users.db ]; then
    export_setup_data "DATABASE_INFO" "SQLite database exists at /opt/ctf/data/users.db"
    
    # Extract database contents
    if command -v sqlite3 >/dev/null 2>&1; then
        # Extract employees table (corporate database)
        sqlite3 /opt/ctf/data/users.db "SELECT username, password_hash FROM employees;" 2>/dev/null | while IFS='|' read -r username hash; do
            if [ -n "$username" ] && [ -n "$hash" ]; then
                export_setup_data "DATABASE_HASH" "$username:$hash:MD5:UNKNOWN_PLAINTEXT"
            fi
        done
    fi
fi

# Export completion status
export_setup_data "RUNTIME_EXPORT_COMPLETE" "All available setup data exported at runtime"

# === STEALTH CLEANUP - REMOVE ALL TRACES ===

# 1. Remove this script itself and runtime data
SCRIPT_PATH="$0"
rm -f "$SCRIPT_PATH" 2>/dev/null || true
rm -f /opt/ctf/runtime_export.sh 2>/dev/null || true
rm -f /opt/ctf/stealth_runtime_export.sh 2>/dev/null || true
rm -rf /opt/ctf/runtime_data 2>/dev/null || true

# 2. Clear any temporary export logs
rm -f /tmp/ctf_setup_export.log 2>/dev/null || true
rm -f /tmp/*export* 2>/dev/null || true

# 3. Clear bash history
history -c 2>/dev/null || true
unset HISTFILE 2>/dev/null || true

# 4. Clear system logs that might contain traces
> /var/log/auth.log 2>/dev/null || true
> /var/log/syslog 2>/dev/null || true
> /var/log/daemon.log 2>/dev/null || true
> /var/log/messages 2>/dev/null || true

# 5. Remove supervisord program entry for this script
if [ -f /etc/supervisor/supervisord.conf ]; then
    # Create a temporary config without the export program
    grep -v "ctf-runtime-export" /etc/supervisor/supervisord.conf > /tmp/supervisord_clean.conf 2>/dev/null || true
    # Remove the entire program block
    sed '/\[program:ctf-runtime-export\]/,/^$/d' /tmp/supervisord_clean.conf > /tmp/supervisord_final.conf 2>/dev/null || true
    mv /tmp/supervisord_final.conf /etc/supervisor/supervisord.conf 2>/dev/null || true
    rm -f /tmp/supervisord_clean.conf /tmp/supervisord_final.conf 2>/dev/null || true
fi

# 6. Clear environment variables
unset WORKSPACE_ID PARTICIPANT_ID SCRIPT_PATH 2>/dev/null || true

# 7. Final log cleanup - remove any mention of this script from logs
sed -i '/stealth_runtime_export/d' /var/log/* 2>/dev/null || true
sed -i '/runtime_export/d' /var/log/* 2>/dev/null || true

# 8. Clear process information
ps aux | grep -v grep | grep -E "(runtime_export|stealth)" | awk '{print $2}' | xargs kill -9 2>/dev/null || true

# Final export to confirm cleanup
export_setup_data "STEALTH_CLEANUP_COMPLETE" "All export traces removed - system clean"

# Self-destruct - this should be the last command
exec rm -f "$0" 2>/dev/null || true 