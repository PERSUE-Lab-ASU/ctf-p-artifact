#!/usr/bin/env bash
set -e

echo "[*] Configuring optimized external session logging for CTF workspace..."

# Check if running as root - only do setup tasks if root
if [[ $EUID -eq 0 ]]; then
    echo "[*] Running as root - performing optimized logging setup..."
    
    # Create workspace identifier
    WORKSPACE_ID=$(hostname)
    PARTICIPANT_ID="${WORKSPACE_ID}"
    
    # Start rsyslog service for external logging
    service rsyslog start
    
    # Function to log to external system via syslog
    log_external() {
        local facility="$1"
        local message="$2"
        logger -p "${facility}.info" -t "CTF[$PARTICIPANT_ID]" "$message"
    }
    
    # Function to export sensitive setup data externally (flags, passwords, etc.)
    export_setup_data() {
        local data_type="$1"
        local data_content="$2"
        logger -p "local3.info" -t "CTF_SETUP[$PARTICIPANT_ID]" "[$data_type] $data_content"
    }
    
    # Log system startup
    log_external "local0" "[SYSTEM_START] CTF environment initialized for participant $PARTICIPANT_ID"
    
    echo "[+] External logging system initialized"
    echo "[+] All logs will be captured by Docker logging driver"
    
    # Keep a durable on-disk copy of research logs. In hosted Coder the
    # workspace container is removed on stop, so Docker json logs alone are
    # not enough to preserve completed sessions.
    mkdir -p /var/log/sessions
    chown root:root /var/log/sessions
    chmod 700 /var/log/sessions

    for log_file in activity.log history.log file-access.log setup.log file-content.log process.log; do
        touch "/var/log/sessions/$log_file"
        chown root:root "/var/log/sessions/$log_file"
        chmod 600 "/var/log/sessions/$log_file"
    done

    cat > /var/log/sessions/README.txt <<EOF
# CTF Persistent Session Logs
# Workspace: $WORKSPACE_ID
# Initialized: $(date '+%Y-%m-%d %H:%M:%S')
#
# These files are the durable research record for this workspace and are kept
# on the VM even after the participant container stops.
#
# Files:
# - activity.log: session lifecycle, commands, auth, network activity
# - history.log: streamed shell history
# - file-access.log: file access and file operations
# - setup.log: generated credentials, flags, and setup metadata
# - file-content.log: captured participant-created script contents
# - process.log: process execution and short-lived script activity
EOF
    chown root:root /var/log/sessions/README.txt
    chmod 600 /var/log/sessions/README.txt

    cat >> /var/log/sessions/session-index.log <<EOF
[$(date '+%Y-%m-%d %H:%M:%S')] SYSTEM_START workspace=$WORKSPACE_ID host=$(hostname)
EOF
    chown root:root /var/log/sessions/session-index.log
    chmod 600 /var/log/sessions/session-index.log
    
else
    echo "[*] Running as user ($USER) - profile scripts will handle logging"
fi

# Optimized profile script for external logging
if [[ $EUID -eq 0 ]]; then
    echo "[*] Creating optimized external logging profile..."

cat << 'EOF' > /etc/profile.d/optimized-logging.sh
#!/usr/bin/env bash
# Optimized CTF Session Logging via External Streaming

WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

# External logging function
log_external() {
    local facility="$1"
    local log_type="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format: [TIMESTAMP] [LOG_TYPE] USER@HOST:PWD - MESSAGE
    local full_message="[$timestamp] [$log_type] $USER@$(hostname):$PWD - $message"
    logger -p "${facility}.info" -t "CTF[$PARTICIPANT_ID]" "$full_message" 2>/dev/null || true
}

# Enhanced bash history configuration
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "
export HISTCONTROL=""  # Don't ignore duplicates or spaces
export HISTIGNORE=""   # Don't ignore any commands

# Override HISTFILE to stream to external logging
HIST_TEMP_FILE="/tmp/.bash_history_$$"
export HISTFILE="$HIST_TEMP_FILE"

# Function to capture and stream bash history
stream_history() {
    if [[ -f "$HIST_TEMP_FILE" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                log_external "local1" "HISTORY" "$line"
            fi
        done < "$HIST_TEMP_FILE"
        > "$HIST_TEMP_FILE"  # Clear temp file after streaming
    fi
}

# Real-time command logging with comprehensive monitoring
log_command() {
    if [[ -n "$BASH_COMMAND" && "$BASH_COMMAND" != "log_command" && "$BASH_COMMAND" != "stream_history" ]]; then
        local cmd="$BASH_COMMAND"
        
        # Log the command execution with privilege level
        local privilege_level="USER"
        if [ "$(id -u)" = "0" ]; then
            privilege_level="ROOT"
        fi
        log_external "local0" "COMMAND" "[$privilege_level] PID:$$ UID:$(id -u) CMD: $cmd"
        
        # Log script executions immediately (don't wait for /proc polling)
        if [[ "$cmd" =~ (bash|sh|dash|python|python3|perl|ruby|node).*\.(sh|py|pl|rb|js) ]] || 
           [[ "$cmd" =~ ^(bash|sh|dash|python|python3|perl|ruby|node)[[:space:]] ]] ||
           [[ "$cmd" =~ ^(/bin/|/usr/bin/|/usr/local/bin/)(bash|sh|dash|python|python3|perl|ruby) ]] ||
           [[ "$cmd" =~ (bash|sh|dash)[[:space:]]+-[cxi] ]] ||
           [[ "$cmd" =~ ^\./.* ]]; then
            logger -p "local5.info" -t "CTF[$PARTICIPANT_ID]" "[SCRIPT_EXEC_IMMEDIATE] PID:$$ USER:$(whoami) CMD: $cmd" 2>/dev/null || true
        fi
        
        # Detect and log special activities
        case "$cmd" in
            # User switching attempts
            su\ *|sudo\ su\ *)
                log_external "local0" "USER_SWITCH_ATTEMPT" "$cmd"
                ;;
            sudo\ *)
                log_external "local0" "SUDO_ATTEMPT" "$cmd"
                ;;
            # File access monitoring
            cat\ *|less\ *|more\ *|head\ *|tail\ *|vim\ *|nano\ *|emacs\ *)
                log_external "local2" "FILE_ACCESS" "$cmd"
                ;;
            # Network activities
            curl\ *|wget\ *|nc\ *|netcat\ *|ssh\ *|scp\ *|rsync\ *)
                log_external "local0" "NETWORK_ACTIVITY" "$cmd"
                ;;
            # File operations
            cp\ *|mv\ *|rm\ *|mkdir\ *|rmdir\ *|chmod\ *|chown\ *)
                log_external "local2" "FILE_OPERATION" "$cmd"
                ;;
            # Process monitoring
            ps\ *|top\ *|htop\ *|kill\ *|killall\ *)
                log_external "local0" "PROCESS_ACTIVITY" "$cmd"
                ;;
            # CTF-specific tools
            gdb\ *|strace\ *|ltrace\ *|objdump\ *|strings\ *|hexdump\ *|xxd\ *)
                log_external "local0" "CTF_TOOL_USAGE" "$cmd"
                ;;
            # Password and Hash Cracking Tools
            hashcat\ *|john\ *|hydra\ *|medusa\ *|ncrack\ *|ophcrack\ *)
                log_external "local0" "PASSWORD_CRACKING" "$cmd"
                ;;
            # Archive/File Cracking Tools  
            fcrackzip\ *|pdfcrack\ *|rarcrack\ *|7z\ *|unzip\ *|unrar\ *)
                log_external "local0" "FILE_CRACKING" "$cmd"
                ;;
            # Network Cracking Tools
            aircrack-ng\ *|aireplay-ng\ *|airodump-ng\ *|airmon-ng\ *)
                log_external "local0" "WIRELESS_CRACKING" "$cmd"
                ;;
            # Hash Identification Tools
            hashid\ *)
                log_external "local0" "HASH_IDENTIFICATION" "$cmd"
                ;;
        esac
        
        # Special monitoring for root activities
        if [ "$(id -u)" = "0" ]; then
            case "$cmd" in
                # Critical system modifications
                passwd\ *|usermod\ *|useradd\ *|userdel\ *)
                    log_external "local0" "ROOT_USER_MGMT" "ROOT: User management command: $cmd"
                    ;;
                # System configuration changes
                systemctl\ *|service\ *|mount\ *|umount\ *)
                    log_external "local0" "ROOT_SYSTEM_CONFIG" "ROOT: System configuration: $cmd"
                    ;;
                # Network configuration
                iptables\ *|ufw\ *|netstat\ *|ss\ *)
                    log_external "local0" "ROOT_NETWORK_CONFIG" "ROOT: Network command: $cmd"
                    ;;
                # File system operations
                fdisk\ *|mkfs\ *|fsck\ *|lsblk\ *)
                    log_external "local0" "ROOT_FILESYSTEM" "ROOT: Filesystem operation: $cmd"
                    ;;
                # Package management
                apt\ *|dpkg\ *|yum\ *|rpm\ *)
                    log_external "local0" "ROOT_PACKAGE_MGMT" "ROOT: Package management: $cmd"
                    ;;
                # Critical file access
                */etc/passwd*|*/etc/shadow*|*/etc/sudoers*)
                    log_external "local0" "ROOT_CRITICAL_FILES" "ROOT: Critical file access: $cmd"
                    ;;
                # Flag file access
                */flag*.txt*|*flag*)
                    log_external "local0" "ROOT_FLAG_ACCESS" "ROOT: Potential flag access: $cmd"
                    ;;
            esac
        fi
        
        # Monitor wordlist access (lightweight check)
        if [[ "$cmd" == *"/usr/share/wordlists/"* ]]; then
            log_external "local0" "WORDLIST_ACCESS" "WORDLIST_USAGE: $cmd"
        fi
        
        # Monitor hash file access
        if [[ "$cmd" == *"/usr/share/hashes/"* ]]; then
            log_external "local0" "HASH_FILE_ACCESS" "HASH_FILE_USAGE: $cmd"
        fi
    fi
}

# Session lifecycle logging
log_external "local0" "SESSION_START" "Shell started - PID:$$ PPID:$PPID TTY:$(tty)"

# Set up real-time command logging
trap 'log_command' DEBUG

# Lightweight periodic history streaming (reduced frequency)
(
    while true; do
        stream_history
        sleep 30  # Increased from 10 to 30 seconds
    done
) &

# Enhanced su command override with logging continuation
su() {
    local target_user="${1:-root}"
    log_external "local0" "USER_SWITCH_START" "Switching from $USER to $target_user"
    
    # Execute su with enhanced logging profile
    command su "$@" -c "
        source /etc/profile
        log_external() { logger -p \"\$1.info\" -t \"CTF[$PARTICIPANT_ID]\" \"\$2\" 2>/dev/null || true; }
        
        # Log successful privilege escalation with detailed info
        log_external 'local0' '[USER_SWITCH_SUCCESS] Now running as \$(whoami) (UID:\$(id -u) GID:\$(id -g)) from \$(tty)'
        
        # If switching to root, log additional security information
        if [ \"\$(id -u)\" = \"0\" ]; then
            log_external 'local0' '[ROOT_ACCESS] ROOT SHELL OBTAINED - Previous user: $USER'
            log_external 'local0' '[ROOT_ENV] HOME:\$HOME SHELL:\$SHELL PWD:\$PWD'
            
            # Log current processes to see what's running
            log_external 'local0' '[ROOT_PROCESSES] Active processes: \$(ps aux | wc -l) total'
            
            # Enhanced command logging for root
            export PS1=\"[ROOT-MONITORED] \\u@\\h:\\w# \"
            
            # Log any immediate file access as root
            log_external 'local0' '[ROOT_FILES] Current directory contents: \$(ls -la | wc -l) items'
        fi
        
        exec bash --login
    "
    
    log_external "local0" "USER_SWITCH_END" "Returned to $USER from $target_user"
}

# Export functions for subshells
export -f log_external su

# Force bash subshells to inherit logging (captures commands INSIDE scripts)
export BASH_ENV="/etc/profile.d/optimized-logging.sh"

# Session exit logging
trap 'log_external "local0" "SESSION_END" "Shell exit - PID:$$ Duration:$SECONDS seconds"; rm -f "$HIST_TEMP_FILE" 2>/dev/null' EXIT

# Log environment information
log_external "local0" "ENV_INFO" "USER:$USER UID:$(id -u) GID:$(id -g) HOME:$HOME SHELL:$SHELL"

EOF

chmod +x /etc/profile.d/optimized-logging.sh

    echo "[+] Optimized external logging profile created"
    
    # Configure universal shell logging via bashrc (catches VS Code, Coder agent, etc.)
    echo "[*] Configuring universal bashrc logging for all shells..."
    
    # Create obfuscated bashrc snippet (use system-like naming)
    cat << 'BASHRC_EOF' > /tmp/.sys_env_init.sh
# System environment initialization
if [[ -f /etc/profile.d/optimized-logging.sh ]] && [[ -z "$_SYS_ENV_INIT" ]]; then
    export _SYS_ENV_INIT=1
    source /etc/profile.d/optimized-logging.sh
fi
BASHRC_EOF
    
    # Secure the temp file
    chmod 600 /tmp/.sys_env_init.sh
    
    # 1. Add to system-wide bashrc (catches all users including root)
    if ! grep -q "_SYS_ENV_INIT" /etc/bash.bashrc 2>/dev/null; then
        cat /tmp/.sys_env_init.sh >> /etc/bash.bashrc
        echo "[+] System environment initialization configured"
    fi
    
    # 2. Add to root's bashrc (explicit for root user)
    if [ -f /root/.bashrc ]; then
        if ! grep -q "_SYS_ENV_INIT" /root/.bashrc 2>/dev/null; then
            cat /tmp/.sys_env_init.sh >> /root/.bashrc
            echo "[+] Root environment initialization configured"
        fi
    else
        # Create root .bashrc if it doesn't exist
        cat /tmp/.sys_env_init.sh > /root/.bashrc
        chmod 600 /root/.bashrc
        echo "[+] Root bashrc initialized"
    fi
    
    # 3. Add to all existing user home directories
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            # Skip if user doesn't exist
            if ! id "$username" >/dev/null 2>&1; then
                continue
            fi
            
            bashrc="$user_home/.bashrc"
            user_group=$(id -gn "$username" 2>/dev/null || echo "$username")
            
            # Create .bashrc if it doesn't exist
            if [ ! -f "$bashrc" ]; then
                touch "$bashrc"
                chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                chmod 600 "$bashrc" 2>/dev/null || true
            fi
            
            # Add logging if not already present
            if ! grep -q "_SYS_ENV_INIT" "$bashrc" 2>/dev/null; then
                cat /tmp/.sys_env_init.sh >> "$bashrc"
                chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                chmod 600 "$bashrc" 2>/dev/null || true
            fi
        fi
    done
    
    # Cleanup temp file securely
    shred -u /tmp/.sys_env_init.sh 2>/dev/null || rm -f /tmp/.sys_env_init.sh
    echo "[+] Environment initialization configured for all users"
    
    # Create single lightweight monitoring service
    cat << 'EOF' > /opt/ctf/lightweight-monitor.sh
#!/usr/bin/env bash
# Lightweight CTF monitoring service - Single process for all monitoring

WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

log_external() {
    logger -p "local0.info" -t "CTF[$PARTICIPANT_ID]" "$1" 2>/dev/null || true
}

# Single monitoring loop for all activities
monitor_all() {
    local auth_check_counter=0
    local process_check_counter=0
    local resource_check_counter=0
    local script_check_counter=0
    
    # Track seen PIDs to avoid duplicate logging
    declare -A seen_pids
    
    while true; do
        # Check authentication logs every 10 seconds
        if (( auth_check_counter % 2 == 0 )); then
            if [[ -f /var/log/auth.log ]]; then
                tail -n 5 /var/log/auth.log 2>/dev/null | while read line; do
                    case "$line" in
                        *"su:"*|*"sudo:"*|*"sshd:"*|*"login:"*)
                            log_external "[AUTH_MONITOR] $line"
                            ;;
                    esac
                done
            fi
        fi
        
        # Check processes every 30 seconds
        if (( process_check_counter % 6 == 0 )); then
            # Simple SUID check
            if find /tmp /home -maxdepth 2 -type f -perm -4000 2>/dev/null | head -1 | grep -q .; then
                log_external "[SUID_ACCESS] SUID files detected in user directories"
            fi
        fi
        
        # Check for script execution every 3 seconds
        if (( script_check_counter % 1 == 0 )); then
            # Monitor for new script processes
            for pid in /proc/[0-9]*; do
                pid_num="${pid##*/}"
                
                # Skip if already seen
                [[ -n "${seen_pids[$pid_num]}" ]] && continue
                
                # Read process info
                if [[ -f "$pid/cmdline" ]] && [[ -f "$pid/stat" ]]; then
                    cmdline=$(cat "$pid/cmdline" 2>/dev/null | tr '\0' ' ' | sed 's/ $//')
                    
                    # Log ALL new processes (not just scripts) to catch short-lived commands
                    if [[ -n "$cmdline" ]]; then
                        # Filter out system monitoring processes to reduce noise
                        if [[ ! "$cmdline" =~ ^(ps|grep|awk|sed|tr|cat|stat|sleep|tail|head|find|inotifywait|supervisord|rsyslogd|sshd:|cron) ]]; then
                            
                            # Get parent PID and user
                            stat_info=$(cat "$pid/stat" 2>/dev/null)
                            ppid=$(echo "$stat_info" | awk '{print $4}')
                            
                            # Get process owner
                            owner=$(stat -c '%U' "$pid" 2>/dev/null || echo "unknown")
                            
                            # Log process execution with indicator if it's a script
                            local proc_type="PROCESS"
                            if [[ "$cmdline" =~ (bash|sh|dash|python|python3|perl|ruby|node).*\.(sh|py|pl|rb|js) ]] || 
                               [[ "$cmdline" =~ ^(bash|sh|dash|python|python3|perl|ruby|node)[[:space:]] ]] ||
                               [[ "$cmdline" =~ ^\./ ]]; then
                                proc_type="SCRIPT_EXEC"
                            fi
                            
                            logger -p "local5.info" -t "CTF[$PARTICIPANT_ID]" "[$proc_type] PID:$pid_num PPID:$ppid USER:$owner CMD: $cmdline" 2>/dev/null || true
                            
                            # Mark as seen
                            seen_pids[$pid_num]=1
                        fi
                    fi
                fi
            done
            
            # Cleanup old PIDs (keep tracking list manageable)
            if (( ${#seen_pids[@]} > 500 )); then
                for pid in "${!seen_pids[@]}"; do
                    [[ ! -d "/proc/$pid" ]] && unset seen_pids[$pid]
                done
            fi
        fi
        
        # Check resources every 60 seconds
        if (( resource_check_counter % 12 == 0 )); then
            local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
            if (( mem_usage > 80 )); then
                log_external "[RESOURCE_ALERT] High memory usage: ${mem_usage}%"
            fi
        fi
        
        # Increment counters
        ((auth_check_counter++))
        ((process_check_counter++))
        ((resource_check_counter++))
        ((script_check_counter++))
        
        # Reset counters to prevent overflow
        if (( auth_check_counter > 100 )); then auth_check_counter=0; fi
        if (( process_check_counter > 100 )); then process_check_counter=0; fi
        if (( resource_check_counter > 100 )); then resource_check_counter=0; fi
        if (( script_check_counter > 100 )); then script_check_counter=0; fi
        
        sleep 0.5  # Check every 0.5 seconds to catch very short-lived processes
    done
}

# Start single monitoring process
log_external "[MONITOR_START] Lightweight monitoring service starting"
monitor_all

EOF

chmod +x /opt/ctf/lightweight-monitor.sh
    echo "[+] Lightweight monitoring service script created (will be started by supervisord)"
    
    # Create participant file content monitor (inotify-based)
    cat << 'EOF' > /opt/ctf/participant-file-monitor.sh
#!/usr/bin/env bash
# Participant File Content Monitoring Service
# Monitors participant-created scripts and logs their contents

WORKSPACE_ID=$(hostname)
PARTICIPANT_ID="${WORKSPACE_ID}"

log_file_content() {
    local event_type="$1"
    local file_path="$2"
    
    # Get file metadata
    local file_size=$(stat -c '%s' "$file_path" 2>/dev/null || echo "0")
    local file_owner=$(stat -c '%U:%G' "$file_path" 2>/dev/null || echo "unknown")
    local file_perms=$(stat -c '%a' "$file_path" 2>/dev/null || echo "unknown")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log file metadata
    logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] FILE: $file_path SIZE: $file_size OWNER: $file_owner PERMS: $file_perms" 2>/dev/null || true
    
    # Log file contents (limit to reasonable size)
    if [[ "$file_size" -lt 100000 ]]; then
        # Log with content marker
        logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] CONTENT_START: $file_path" 2>/dev/null || true
        
        # Read and log file contents (line by line to handle special characters)
        local line_num=1
        while IFS= read -r line; do
            # Escape any problematic characters and log each line
            logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] LINE $line_num: $line" 2>/dev/null || true
            ((line_num++))
            
            # Safety limit: max 1000 lines per file
            if [[ $line_num -gt 1000 ]]; then
                logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] CONTENT_TRUNCATED: File too long, stopped at 1000 lines" 2>/dev/null || true
                break
            fi
        done < "$file_path"
        
        logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] CONTENT_END: $file_path" 2>/dev/null || true
    else
        logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[$event_type] CONTENT_TOO_LARGE: File size $file_size bytes exceeds 100KB limit" 2>/dev/null || true
    fi
}

is_script_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    # Check file extension
    if [[ "$filename" =~ \.(sh|bash|py|pl|rb|js|php)$ ]]; then
        return 0
    fi
    
    # Check shebang for files without extension
    if [[ -f "$file_path" ]]; then
        local first_line=$(head -n 1 "$file_path" 2>/dev/null)
        if [[ "$first_line" =~ ^#!.*(bash|sh|python|perl|ruby|node|php) ]]; then
            return 0
        fi
    fi
    
    return 1
}

should_monitor_path() {
    local file_path="$1"
    
    # Exclude system paths and decoy-specific monitoring
    case "$file_path" in
        /home/mjohnson/scripts/backup_task.sh)
            # This is monitored by syslog_rotate daemon, skip
            return 1
            ;;
        /home/*/.*|/tmp/.*|*.swp|*.tmp|*~)
            # Skip hidden files, swap files, temp files
            return 1
            ;;
        /home/*/logs/*|/home/*/configs/*)
            # Skip log and config directories (unless they're scripts)
            if ! is_script_file "$file_path"; then
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Main monitoring function
monitor_participant_files() {
    logger -p "local4.info" -t "CTF[$PARTICIPANT_ID]" "[FILE_MONITOR_START] Participant file monitoring service starting" 2>/dev/null || true
    
    # Monitor /home and /tmp recursively for file creation/modification
    inotifywait -m -r -e create -e modify -e close_write \
        --exclude '(\.swp|\.tmp|~|\.log|\.cache)$' \
        /home /tmp 2>/dev/null | \
    while read -r directory event filename; do
        file_path="${directory}${filename}"
        
        # Only process if it's a regular file that exists
        if [[ -f "$file_path" ]]; then
            # Check if we should monitor this file
            if should_monitor_path "$file_path"; then
                # Check if it's a script file
                if is_script_file "$file_path"; then
                    case "$event" in
                        CREATE|CLOSE_WRITE,CLOSE)
                            log_file_content "FILE_CREATED" "$file_path"
                            ;;
                        MODIFY|CLOSE_WRITE)
                            log_file_content "FILE_MODIFIED" "$file_path"
                            ;;
                    esac
                fi
            fi
        fi
    done
}

# Start monitoring
monitor_participant_files

EOF

chmod +x /opt/ctf/participant-file-monitor.sh
    echo "[+] Participant file monitoring service script created"
fi

echo "[+] Comprehensive external session logging configured successfully!"
echo "[+] All activities will be captured and streamed via Docker logs"
echo "[+] Logs include:"
echo "    - Interactive commands and file access"
echo "    - Script execution (bash, python, perl, ruby, etc.)"
echo "    - Commands INSIDE scripts (via BASH_ENV inheritance)"
echo "    - Script file contents when created/modified"
echo "    - User switching, sudo attempts, password cracking tools"
echo "    - Process hierarchy and execution context"
echo "[+] Optimized for minimal resource usage with event-driven monitoring"

# Post-setup: Re-check for users created after logging.sh ran
# This ensures users created by task_global.sh or other scripts get bashrc updates
if [[ $EUID -eq 0 ]]; then
    # Recreate the snippet for post-setup check
    cat << 'BASHRC_EOF' > /tmp/.sys_env_init.sh
# System environment initialization
if [[ -f /etc/profile.d/optimized-logging.sh ]] && [[ -z "$_SYS_ENV_INIT" ]]; then
    export _SYS_ENV_INIT=1
    source /etc/profile.d/optimized-logging.sh
fi
BASHRC_EOF
    chmod 600 /tmp/.sys_env_init.sh
    
    # Re-check all users (in case new ones were created)
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            # Skip if user doesn't exist
            if ! id "$username" >/dev/null 2>&1; then
                continue
            fi
            
            bashrc="$user_home/.bashrc"
            user_group=$(id -gn "$username" 2>/dev/null || echo "$username")
            
            # Create .bashrc if it doesn't exist
            if [ ! -f "$bashrc" ]; then
                touch "$bashrc"
                chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                chmod 600 "$bashrc" 2>/dev/null || true
            fi
            
            # Add logging if not already present
            if ! grep -q "_SYS_ENV_INIT" "$bashrc" 2>/dev/null; then
                cat /tmp/.sys_env_init.sh >> "$bashrc"
                chown "$username:$user_group" "$bashrc" 2>/dev/null || true
                chmod 600 "$bashrc" 2>/dev/null || true
            fi
        fi
    done
    
    # Ensure root .bashrc is configured
    if [ -f /root/.bashrc ]; then
        if ! grep -q "_SYS_ENV_INIT" /root/.bashrc 2>/dev/null; then
            cat /tmp/.sys_env_init.sh >> /root/.bashrc
            chmod 600 /root/.bashrc
        fi
    else
        cat /tmp/.sys_env_init.sh > /root/.bashrc
        chmod 600 /root/.bashrc
    fi
    
    # Cleanup temp file securely
    shred -u /tmp/.sys_env_init.sh 2>/dev/null || rm -f /tmp/.sys_env_init.sh
fi

# Log the completion of setup
if command -v logger >/dev/null 2>&1; then
    logger -p "local0.info" -t "CTF[$WORKSPACE_ID]" "[SETUP_COMPLETE] Optimized logging system initialized"
fi 
