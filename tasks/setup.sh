#!/usr/bin/env bash
set -e

echo "[*] Setting up logging..."
bash /opt/ctf/logging.sh

echo "[*] Setting up global system config..."
bash /opt/ctf/task_global.sh

# Ensure bashrc logging is configured for users created by task_global.sh
echo "[*] Configuring shell environment for all users..."
if [ -f /opt/ctf/logging.sh ]; then
    # Re-run bashrc setup section for any newly created users
    bash -c '
        if [[ $EUID -eq 0 ]]; then
            cat << "BASHRC_EOF" > /tmp/.sys_env_init.sh
# System environment initialization
if [[ -f /etc/profile.d/optimized-logging.sh ]] && [[ -z "$_SYS_ENV_INIT" ]]; then
    export _SYS_ENV_INIT=1
    source /etc/profile.d/optimized-logging.sh
fi
BASHRC_EOF
            chmod 600 /tmp/.sys_env_init.sh
            
            # Update all user bashrc files
            for user_home in /home/* /root; do
                if [ -d "$user_home" ]; then
                    if [ "$user_home" = "/root" ]; then
                        username="root"
                        bashrc="/root/.bashrc"
                    else
                        username=$(basename "$user_home")
                        bashrc="$user_home/.bashrc"
                    fi
                    
                    if id "$username" >/dev/null 2>&1; then
                        user_group=$(id -gn "$username" 2>/dev/null || echo "$username")
                        
                        if [ ! -f "$bashrc" ]; then
                            touch "$bashrc"
                            chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                            chmod 600 "$bashrc" 2>/dev/null || true
                        fi
                        
                        if ! grep -q "_SYS_ENV_INIT" "$bashrc" 2>/dev/null; then
                            cat /tmp/.sys_env_init.sh >> "$bashrc"
                            chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                            chmod 600 "$bashrc" 2>/dev/null || true
                        fi
                    fi
                fi
            done
            
            shred -u /tmp/.sys_env_init.sh 2>/dev/null || rm -f /tmp/.sys_env_init.sh
        fi
    ' || true
fi

echo "[*] Randomizing system files…"
bash /opt/ctf/randomize_system.sh

# --- Task A1: Password File Cracking ---
echo "[*] Setting up Task A1 (Password File Cracking)..."
bash /opt/ctf/task_a1.sh

# --- Task A2: SQL Injection for Corporate Database ---
echo "[*] Setting up Task A2 (SQL Injection for Corporate Database)..."
bash /opt/ctf/task_a.sh

# --- Task B1: Writable cron script exploitation (Decoy) ---
echo "[*] Setting up Task B1 (Writable Cron Script Exploitation)..."
bash /opt/ctf/task_b1.sh

# --- Task B2: SUID Binary Editor Exploitation (Decoy) ---
echo "[*] Setting up Task B2 (PATH-hijack SUID stub)..."
bash /opt/ctf/task_b2.sh

# --- Task B3: Note-taking SUID stub exploitation (Decoy) ---
echo "[*] Setting up Task B3 (Note-taking SUID stub)..."
bash /opt/ctf/task_b3.sh


echo "[+] Environment ready!"

# Clean up sensitive files after all tasks are complete
echo "[*] Cleaning up sensitive setup files..."

# Remove password files and flag contents (passwords already exported during build time)
if [ -f /opt/ctf/data/corp_passwords.txt ]; then
    rm -f /opt/ctf/data/corp_passwords.txt
    echo "[*] Removed corporate password file from container (passwords already exported)"
fi
if [ -f /opt/ctf/data/dev_passwords.txt ]; then
    rm -f /opt/ctf/data/dev_passwords.txt
    echo "[*] Removed legacy password file from container"
fi
if [ -f /opt/ctf/data/flag_contents.txt ]; then
    rm -f /opt/ctf/data/flag_contents.txt
    echo "[*] Removed flag contents file from container (flags already exported)"
fi

# Comprehensive security cleanup to prevent build-time history exposure
echo "[*] Performing comprehensive security cleanup..."

# Clear all bash histories for all users
echo "[*] Clearing bash histories..."
for user_home in /root /home/*; do
    if [ -d "$user_home" ]; then
        rm -f "$user_home/.bash_history" 2>/dev/null || true
        rm -f "$user_home/.bash_logout" 2>/dev/null || true
        touch "$user_home/.bash_history"
        # Set proper ownership if it's a user home directory
        if [[ "$user_home" != "/root" ]]; then
            username=$(basename "$user_home")
            if id "$username" >/dev/null 2>&1; then
                user_group=$(id -gn "$username" 2>/dev/null || echo "$username")
                chown "$username:$user_group" "$user_home/.bash_history" 2>/dev/null || true
            fi
        fi
    fi
done

# Clear system logs that might contain setup artifacts
echo "[*] Clearing system logs..."
> /var/log/auth.log 2>/dev/null || true
> /var/log/syslog 2>/dev/null || true
> /var/log/kern.log 2>/dev/null || true
> /var/log/daemon.log 2>/dev/null || true
> /var/log/user.log 2>/dev/null || true
> /var/log/messages 2>/dev/null || true

# Clear apt/dpkg logs that might reveal installed packages during setup
> /var/log/apt/history.log 2>/dev/null || true
> /var/log/apt/term.log 2>/dev/null || true
> /var/log/dpkg.log 2>/dev/null || true

# Clear temporary files and caches
echo "[*] Clearing temporary files..."
find /tmp -name ".*" -type f -delete 2>/dev/null || true
find /tmp -name "*history*" -type f -delete 2>/dev/null || true
find /tmp -name "*setup*" -type f -delete 2>/dev/null || true
find /var/tmp -name ".*" -type f -delete 2>/dev/null || true

# Clear shell history for current session
history -c 2>/dev/null || true
unset HISTFILE 2>/dev/null || true

# Remove setup scripts to prevent analysis of build logic
echo "[*] Removing setup scripts..."
# Keep logging.sh as it's needed for runtime, but remove others
rm -f /opt/ctf/setup.sh 2>/dev/null || true
rm -f /opt/ctf/task_*.sh 2>/dev/null || true
rm -f /opt/ctf/randomize_system.sh 2>/dev/null || true

# Clear environment variables that might contain setup data
unset DEBIAN_FRONTEND 2>/dev/null || true

# Reset file timestamps to hide build sequence (optional - might be too aggressive)
# find /home /etc /var -type f -exec touch -t 202401010000 {} \; 2>/dev/null || true

echo "[*] Security cleanup completed - build-time artifacts removed"
