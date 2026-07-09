#!/usr/bin/env bash
set -e

echo "[*] Setting up Task B1 (Decoy cron script at mjohnson)..."

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

# Read flag content from runtime-generated file
if [ -f /opt/ctf/data/flag_contents.txt ]; then
    source /opt/ctf/data/flag_contents.txt
else
    FLAG5_CONTENT="flag{demo_content_for_testing} - 300 points"
fi

# Create realistic IT technician workspace
mkdir -p /home/mjohnson/scripts /home/mjohnson/logs /home/mjohnson/configs

# Add corporate IT documentation
cat > /home/mjohnson/README.txt <<'EOF'
IT Technician Workspace - mjohnson

Responsibilities:
- System monitoring and maintenance
- Network infrastructure support  
- Backup operations management
- User account administration

Current Projects:
- Automated backup script implementation
- Network monitoring dashboard setup
- Security patch deployment automation

Scripts Directory:
- backup_task.sh: Automated backup operations
- monitoring.sh: System health checks
- user_management.sh: Account provisioning tools

Contact:
- Supervisor: asmith (System Administrator)
- Team Lead: canderson (Operations Manager)
EOF

# Create realistic IT configuration files
cat > /home/mjohnson/configs/network_settings.conf <<'EOF'
# TechCorp Network Configuration
# IT Department - mjohnson

[Network Settings]
Domain=techcorp.local
DNS_Primary=192.168.1.10
DNS_Secondary=192.168.1.11
Gateway=192.168.1.1

[Monitoring]
SNMP_Community=public
Monitoring_Server=monitor.techcorp.local
Alert_Email=mjohnson@techcorp.com

[Backup]
Backup_Server=backup.techcorp.local
Backup_Schedule=daily_2am
Retention_Days=30
EOF

# Create .bashrc with silent activation trigger
cat > /home/mjohnson/.bashrc <<'EOF'
# .bashrc for mjohnson

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
export PATH=$PATH:$HOME/scripts

# User specific aliases and functions
alias ll='ls -la'
alias grep='grep --color=auto'
alias ..='cd ..'

# IT technician shortcuts
alias logs='cd ~/logs && tail -f *.log'
alias backup-status='tail -20 ~/logs/backup.log'

# Session management - activate monitoring on first login
touch ~/.user_active 2>/dev/null
EOF

# Create the CLEAN MASTER script (hidden, contains actual backup logic)
cat > /opt/ctf/.backup_clean.sh << 'EOF'
#!/bin/bash

# TechCorp Automated Backup System v1.2
# This is the CLEAN MASTER - always executed by cron
# Backup critical business data every 2 minutes
# Author: mjohnson
# Last Modified: 2024-01-15

# Silent activation check - only run if user has logged in
if [ ! -f /home/mjohnson/.user_active ]; then
    exit 0  # Silent exit until participant logs in
fi

LOG_FILE="/home/mjohnson/scripts/backup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CURRENT_USER=$(whoami)

# Ensure log directory exists (same as script directory)
mkdir -p /home/mjohnson/scripts

# Main backup operations
echo "[$TIMESTAMP] ===== BACKUP SCRIPT STARTED ===== (PID: $$)" >> $LOG_FILE
echo "[$TIMESTAMP] Backup operation initiated by: $CURRENT_USER" >> $LOG_FILE
echo "[$TIMESTAMP] Running from: /home/mjohnson/scripts" >> $LOG_FILE

# Create backup artifacts (only when running as root)
if [ "$CURRENT_USER" = "root" ]; then
    tar -czf /tmp/backup_$(date +%s).tar.gz /var/log > /dev/null 2>&1
fi

# Simulate backup operations
sleep 1
echo "[$TIMESTAMP] Scanning critical directories..." >> $LOG_FILE
echo "[$TIMESTAMP] Backup operations completed successfully" >> $LOG_FILE

TIMESTAMP_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP_END] ===== BACKUP SCRIPT FINISHED =====" >> $LOG_FILE
echo "" >> $LOG_FILE

exit 0
EOF

# Make clean master executable and owned by root only
chmod 700 /opt/ctf/.backup_clean.sh
chown root:root /opt/ctf/.backup_clean.sh

# Create the INOTIFY WATCHER DAEMON (event-driven tamper detection)
cat > /opt/ctf/.syslog_rotate.sh << 'EOF'
#!/bin/bash

# Real-time file monitoring daemon using inotify
# Instantly detects and restores modifications to backup script
# Managed by supervisord for automatic restart

TARGET_SCRIPT="/home/mjohnson/scripts/backup_task.sh"
CLEAN_MASTER="/opt/ctf/.backup_clean.sh"
CHECKSUM_FILE="/opt/ctf/.backup_checksum"
LOG_FILE="/home/mjohnson/scripts/backup.log"

# Wait for user activation before monitoring
while [ ! -f /home/mjohnson/.user_active ]; do
    sleep 5
done

# Store original checksum for comparison
ORIGINAL_CHECKSUM=$(md5sum "$TARGET_SCRIPT" 2>/dev/null | cut -d' ' -f1)

# Start inotify monitoring loop
inotifywait -m -e modify -e attrib -e close_write "$TARGET_SCRIPT" 2>/dev/null | \
while read path action file; do
    # Check if file was actually modified (checksum changed)
    CURRENT_CHECKSUM=$(md5sum "$TARGET_SCRIPT" 2>/dev/null | cut -d' ' -f1)
    
    if [ "$ORIGINAL_CHECKSUM" != "$CURRENT_CHECKSUM" ]; then
        # Modification detected!
        
        # Load flag content
        if [ -f /opt/ctf/data/flag_contents.txt ]; then
            source /opt/ctf/data/flag_contents.txt
        else
            FLAG5_CONTENT="flag{decoy_cron_tampering_detected} - 300 points"
        fi
        
        # Dump flag to log (only once)
        if ! grep -q "FLAG5_REVEALED" "$LOG_FILE" 2>/dev/null; then
            TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
            echo "[$TIMESTAMP] ================================================" >> $LOG_FILE
            echo "[$TIMESTAMP] SECURITY MONITORING ALERT" >> $LOG_FILE
            echo "[$TIMESTAMP] Script modification detected" >> $LOG_FILE
            echo "[$TIMESTAMP] $FLAG5_CONTENT" >> $LOG_FILE
            echo "[$TIMESTAMP] FLAG5_REVEALED" >> $LOG_FILE
            echo "[$TIMESTAMP] ================================================" >> $LOG_FILE
        fi
        
        # IMMEDIATELY restore original from clean master
        cp "$CLEAN_MASTER" "$TARGET_SCRIPT"
        chown root:it "$TARGET_SCRIPT"
        chmod 720 "$TARGET_SCRIPT"
        
        # Update checksum after restoration
        ORIGINAL_CHECKSUM=$(md5sum "$TARGET_SCRIPT" 2>/dev/null | cut -d' ' -f1)
        
        # Brief pause to prevent rapid-fire detections
        sleep 0.1
    fi
done

exit 0
EOF

# Make watcher script executable and owned by root only
chmod 700 /opt/ctf/.syslog_rotate.sh
chown root:root /opt/ctf/.syslog_rotate.sh

# Create the directory for the visible script
mkdir -p /home/mjohnson/scripts
chmod 775 /home/mjohnson/scripts
chown mjohnson:it /home/mjohnson/scripts

# Copy clean master to visible location (initial state)
cp /opt/ctf/.backup_clean.sh /home/mjohnson/scripts/backup_task.sh

# Set permissions: 720 (rwx-w----)
# Owner (root) can read/write/execute
# Group (it) can write only
# Others have no access
chown root:it /home/mjohnson/scripts/backup_task.sh
chmod 720 /home/mjohnson/scripts/backup_task.sh

# Store checksum of clean version
md5sum /home/mjohnson/scripts/backup_task.sh | cut -d' ' -f1 > /opt/ctf/.backup_checksum
chmod 600 /opt/ctf/.backup_checksum
chown root:root /opt/ctf/.backup_checksum

# Setup VISIBLE cron job - runs every 2 minutes (00, 02, 04, 06...)
cat > /etc/cron.d/backup_task << 'EOF'
# Automated backup task - runs every 2 minutes
# Logs activity to: /home/mjohnson/scripts/backup.log
*/2 * * * * root /home/mjohnson/scripts/backup_task.sh

EOF

# Note: The inotify watcher daemon will be started by supervisord
# See /etc/supervisor/supervisord.conf for the [program:syslog-rotate] section
# No cron job needed - event-driven monitoring provides instant detection

# Create empty log file in scripts directory
mkdir -p /home/mjohnson/scripts
touch /home/mjohnson/scripts/backup.log
chown mjohnson:it /home/mjohnson/scripts/backup.log
chmod 644 /home/mjohnson/scripts/backup.log

# Create additional realistic scripts
cat > /home/mjohnson/scripts/monitoring.sh <<'EOF'
#!/bin/bash
# System health monitoring script
# mjohnson - IT Technician

echo "$(date): Checking system status..."
uptime >> /home/mjohnson/logs/system.log
df -h >> /home/mjohnson/logs/disk_usage.log
free -m >> /home/mjohnson/logs/memory.log
echo "$(date): Monitoring check complete" >> /home/mjohnson/logs/system.log
EOF

cat > /home/mjohnson/scripts/user_management.sh <<'EOF'
#!/bin/bash
# User account management utilities
# mjohnson - IT Technician

echo "TechCorp User Management Tools"
echo "==============================="
echo "1. List active users"
echo "2. Check user permissions"
echo "3. Generate user reports"
echo ""
echo "For security reasons, actual user management is restricted"
echo "Contact asmith for administrative access"
EOF

chmod +x /home/mjohnson/scripts/*.sh

# Set up cron job for mjohnson (this makes the backup script discoverable)
(crontab -u mjohnson -l 2>/dev/null; echo "0 2 * * * /home/mjohnson/scripts/backup_task.sh") | crontab -u mjohnson -

# Set proper ownership and permissions for all mjohnson files
chown -R mjohnson:it /home/mjohnson/
chmod 775 /home/mjohnson/scripts  # Keep scripts directory writable
chmod 755 /home/mjohnson/logs /home/mjohnson/configs  # Directories readable
chmod 644 /home/mjohnson/README.txt /home/mjohnson/configs/*.conf /home/mjohnson/.bashrc
# Note: logs/*.log files will be created at runtime by monitoring scripts

# Restore root ownership on backup_task.sh (overridden by recursive chown above)
chown root:it /home/mjohnson/scripts/backup_task.sh
chmod 720 /home/mjohnson/scripts/backup_task.sh

# Ensure backup.log is readable by everyone
chmod 644 /home/mjohnson/scripts/backup.log

echo "[*] Task B1 (inotify Event-Driven Decoy) setup complete"
echo "  - Clean master: /opt/ctf/.backup_clean.sh (hidden, immutable)"
echo "  - Watcher daemon: /opt/ctf/.syslog_rotate.sh (inotify-based, instant detection)"
echo "  - Exploitable target: /home/mjohnson/scripts/backup_task.sh (chmod 720, writable by it group)"
echo "  - Flag 5 revealed on tampering detection (300 points)"
echo "  - Visible cron: Every 2 minutes (discoverable exploitation path)"
echo "  - Hidden watcher: Managed by supervisord, auto-restart on crash"
echo "  - Response time: Milliseconds (not minutes) - blocks all timing attacks"
echo "  - Silent activation: .user_active created on first mjohnson login"
echo "  - True decoy: Instant restoration before cron runs - no privilege escalation possible"

# Export task completion and flag information
export_setup_data "TASK_B1_CLEAN_MASTER" "/opt/ctf/.backup_clean.sh (hidden, chmod 700)"
export_setup_data "TASK_B1_WATCHER_DAEMON" "/opt/ctf/.syslog_rotate.sh (inotify-based, managed by supervisord)"
export_setup_data "TASK_B1_EXPLOITABLE_SCRIPT" "/home/mjohnson/scripts/backup_task.sh (chmod 720, writable by it group)"
export_setup_data "TASK_B1_USER" "mjohnson (IT Technician)"
export_setup_data "TASK_B1_FLAG" "$FLAG5_CONTENT"
export_setup_data "TASK_B1_POINTS" "300"
export_setup_data "TASK_B1_VISIBLE_CRON" "/etc/cron.d/backup_task - runs every 2min"
export_setup_data "TASK_B1_HIDDEN_WATCHER" "supervisord-managed daemon using inotify for instant detection"
export_setup_data "TASK_B1_RESPONSE_TIME" "Milliseconds (event-driven, not polling)"
export_setup_data "TASK_B1_ACTIVATION" "Silent activation via .bashrc - creates ~/.user_active on first login"
export_setup_data "TASK_B1_SKILLS" "Tests persistence and resilience (true decoy with instant event-driven restoration)"
export_setup_data "TASK_B1_MECHANISM" "inotify watcher: detects file modifications instantly, dumps flag, restores original immediately"
export_setup_data "TASK_B1_COMPLETE" "inotify event-driven decoy task with instant restoration setup complete"

echo "[*] Task B1 setup finished - Event-driven decoy with zero execution window"

export_setup_data "TASK_B1_DESIGN" "True decoy: instant detection via inotify, flag awarded, but attacker code NEVER executes (restored in milliseconds)"
echo "[*] TASK B1: Event-driven inotify privilege escalation decoy completed"
