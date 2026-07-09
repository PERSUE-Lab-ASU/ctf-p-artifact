#!/usr/bin/env bash
set -e

echo "[*] Setting up Task A1 (Password File Cracking)..."

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

# Create additional content in jdoe's directory to simulate a realistic environment
mkdir -p /home/jdoe/Documents /home/jdoe/Desktop

# Add some realistic files to make jdoe's directory feel more authentic
cat > /home/jdoe/Documents/onboarding_notes.txt <<'EOF'
Welcome to TechCorp Internship Program

Your login credentials:
- Username: jdoe
- Password: welcome123
- Employee ID: INT-2024-001
- Department: IT (Intern)
- Supervisor: mjohnson

Important:
- Please review the Employee Handbook before starting
- All company policies are documented in the secure archive
- Contact HR for any questions about benefits or policies

Next Steps:
1. Review corporate credentials backup (corporate_credentials_backup.zip)
2. Complete mandatory security training
3. Meet with your supervisor
EOF

cat > /home/jdoe/Documents/project_assignments.txt <<'EOF'
IT Internship Projects - Q1 2024

Current Assignments:
- Network documentation update
- Asset inventory verification
- Security audit support (read-only access)

Training Modules:
- System administration basics
- Network security fundamentals
- Corporate compliance requirements

Resources:
- Internal wiki: wiki.techcorp.local
- Employee directory: Available in corporate database
- IT helpdesk: ext. 5555
EOF

# Create a decoy file to add realism
cat > /home/jdoe/Desktop/meeting_schedule.txt <<'EOF'
Weekly Schedule - Intern John Doe

Monday 9:00 AM - Team standup (Conference Room B)
Tuesday 2:00 PM - Security training (Online)
Wednesday 10:00 AM - One-on-one with supervisor
Thursday 3:00 PM - Department meeting (Conference Room A)
Friday 1:00 PM - Intern feedback session

Contact Information:
- Supervisor: mjohnson@techcorp.com
- HR Representative: swilliams@techcorp.com
- IT Support: support@techcorp.com
EOF

# Set proper ownership and permissions for all jdoe files
chown -R jdoe:it /home/jdoe/Documents /home/jdoe/Desktop
chmod 700 /home/jdoe/Documents /home/jdoe/Desktop  # Directories private to user
chmod 644 /home/jdoe/Documents/*.txt /home/jdoe/Desktop/*.txt

# Note: The corporate_credentials_backup.zip will be created at runtime by stealth_runtime_export.sh
# This ensures each participant gets a unique flag and archive password

echo "[*] Task A1 setup information:"
echo "  - Corporate credentials backup archive will be created at runtime: /home/jdoe/corporate_credentials_backup.zip"
echo "  - Archive will contain unique Flag 1 (100 points) for each participant"
echo "  - Password will be from rockyou.txt (first 1000 lines for crackability)"
echo "  - Supporting documentation created in jdoe's directories"

# Add a hint file for participants who might need guidance
cat > /home/jdoe/Documents/it_tools_guide.txt <<'EOF'
IT Intern Quick Reference - Common Tools

Password Recovery:
- zip2john: Extract password hashes from archives
- john: John the Ripper password cracker
- hashcat: Advanced password recovery
- rockyou.txt: Common password wordlist (/usr/share/wordlists/)

Network Scanning:
- nmap: Network discovery and security auditing
- netstat: Display network connections
- ss: Socket statistics

File Analysis:
- file: Determine file type
- strings: Extract printable strings from files
- hexdump: Display file contents in hexadecimal

Database Tools:
- sqlite3: SQLite database interaction
- mysql: MySQL database client
- sqlmap: Automated SQL injection testing

Note: Always follow company policies when using these tools.
Use only for authorized security testing and learning purposes.
EOF

chown jdoe:it /home/jdoe/Documents/it_tools_guide.txt
chmod 644 /home/jdoe/Documents/it_tools_guide.txt

# Export task completion information
export_setup_data "TASK_A1_SETUP" "Password cracking challenge ready in /home/jdoe/corporate_credentials_backup.zip"
export_setup_data "TASK_A1_TARGET" "Participants must crack password-protected archive to obtain Flag 1"
export_setup_data "TASK_A1_SKILLS" "Tests persistence and openness (willingness to use cracking tools)"
export_setup_data "TASK_A1_COMPLETE" "Password file cracking task setup complete"

echo "[*] Task A1 (Password File Cracking) setup complete!"
echo "[*] Participants can use tools like zip2john + john or fcrackzip with rockyou.txt" 