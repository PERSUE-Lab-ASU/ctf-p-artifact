#!/usr/bin/env bash
set -e

echo "[*] Global setup: corporate users, groups, shells, prompts, flags..."

# Setup data export function - ensure rsyslog is running first
WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

# Start rsyslog if not already running (needed for logger command)
if ! pgrep rsyslogd > /dev/null; then
    service rsyslog start
    sleep 1  # Give rsyslog time to start
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

# Create corporate department groups
echo "[*] Creating corporate department groups..."
groupadd -f sysadmin
groupadd -f it
groupadd -f development
groupadd -f hr
groupadd -f finance
groupadd -f management
groupadd -f executive

# --- Corporate user password generation function (BUILD TIME - STATIC) ---
# NOTE: Passwords will be generated at RUNTIME for unique per-participant values

# --- Corporate Users Creation (BUILD TIME - NO PASSWORDS SET) ---
mkdir -p /opt/ctf/data
mkdir -p /opt/ctf/runtime_data
chmod 700 /opt/ctf/runtime_data

echo "[*] Creating corporate user accounts (passwords will be set at runtime)..."

# System Administrator (UID 1000 - First corporate user)
useradd -m -g sysadmin -s /bin/bash asmith
echo "[*] Created asmith (System Administrator - sysadmin group) - UID 1000"

# IT Staff
useradd -m -g it -s /bin/bash mjohnson
echo "[*] Created mjohnson (IT Technician - it group)"

# Development Team
useradd -m -g development -s /bin/bash lgarcia
echo "[*] Created lgarcia (Senior Software Engineer - development group)"

useradd -m -g development -s /bin/bash dwilson
echo "[*] Created dwilson (DevOps Engineer - development group)"

# HR Department
useradd -m -g hr -s /bin/bash swilliams
echo "[*] Created swilliams (HR Manager - hr group)"

useradd -m -g hr -s /bin/bash rdavis
echo "[*] Created rdavis (HR Specialist - hr group)"

# Finance Department
useradd -m -g finance -s /bin/bash kmiller
echo "[*] Created kmiller (Financial Analyst - finance group)"

useradd -m -g finance -s /bin/bash bthompson
echo "[*] Created bthompson (Accounting Manager - finance group)"

# Management
useradd -m -g management -s /bin/bash canderson
echo "[*] Created canderson (Operations Manager - management group)"

# Executive
useradd -m -g executive -s /bin/bash tbrown
echo "[*] Created tbrown (VP Operations - executive group)"

# Entry-level user (jdoe) - Intern (Entry point for participants)
useradd -m -g it -s /bin/bash jdoe
echo "jdoe:welcome123" | chpasswd  # Static password for entry point
echo "[*] Created jdoe (intern in IT department) - Entry point user"

# Root password will be set at runtime
echo "[*] Corporate user accounts created (passwords will be set at runtime)"

# Set pretty prompts and secure home directories for all corporate users
for user in jdoe asmith mjohnson lgarcia dwilson swilliams rdavis kmiller bthompson canderson tbrown; do
    echo 'export PS1="\u@\h:\w\$ "' >> /home/$user/.bashrc
    chown $user:$(id -gn $user) /home/$user/.bashrc
    
    # Secure home directory - only owner can access, but allow traversal for services
    chmod 701 /home/$user
    chown $user:$(id -gn $user) /home/$user
done

# --- Corporate Flag Generation (MOVED TO RUNTIME) ---
echo "[*] Flag and password generation moved to runtime for unique per-participant values"

# Create placeholder files that will be populated at runtime
mkdir -p /home/kmiller
mkdir -p /home/asmith

# Set proper ownership for home directories (flags will be created at runtime)
chown kmiller:finance /home/kmiller
chown asmith:sysadmin /home/asmith

# Create flag template files for runtime generation
echo "# Flags will be generated at runtime" > /opt/ctf/data/flag_template.txt
chmod 600 /opt/ctf/data/flag_template.txt

echo "[*] Corporate environment setup complete!"
