# CTF Corporate Environment - Tasks Documentation

## Overview

This CTF implementation creates a realistic corporate environment for personality profiling research, measuring four key traits: **persistence**, **resilience**, **risk-taking**, and **openness**. The system uses a two-phase approach: build-time structure creation and runtime secret generation.

## Architecture: Build-time vs Runtime

### Build-time (Docker Image Creation)
- Creates user accounts and file structures
- Sets up challenge frameworks and databases
- Installs tools and configures services
- **No secrets or flags generated** (prevents shared answers)

### Runtime (Container Startup)
- Generates unique passwords and flags per participant
- Populates databases with actual password hashes
- Exports all data to external logging systems
- Self-destructs to remove traces

---

## Script Execution Flow

### Phase 1: Build-time Scripts (Dockerfile)

#### 1. `setup.sh` - Master Setup Orchestrator
**Execution**: Docker build (Step 91-92)
**Purpose**: Coordinates all build-time setup tasks
**Functions**:
- Calls all task setup scripts in sequence
- Handles error management and logging
- Performs final cleanup of sensitive build data

```bash
# Execution order in setup.sh:
./tasks/task_global.sh      # Corporate structure
./tasks/task_a1.sh          # Password cracking setup
./tasks/task_a.sh           # SQL injection setup  
./tasks/task_b1.sh          # Cron script setup
./tasks/task_b2.sh          # SUID binary setup
./tasks/task_b3.sh          # Buffer overflow setup
```

#### 2. `task_global.sh` - Corporate Environment Creation
**Execution**: First in setup.sh
**Purpose**: Creates realistic corporate user structure
**Runtime**: ~2-3 seconds

**Corporate Users Created**:
- `asmith` (UID 1000) - System Administrator
- `mjohnson` - IT Technician
- `lgarcia` - Senior Software Engineer
- `dwilson` - DevOps Engineer
- `swilliams` - HR Manager
- `rdavis` - HR Specialist
- `kmiller` - Finance Manager
- `bthompson` - Finance Analyst
- `canderson` - Management
- `tbrown` - Executive
- `jdoe` (highest UID) - Entry point user

**Groups Created**:
- `sysadmin`, `it`, `development`, `hr`, `finance`, `management`, `executive`

**Key Features**:
- Home directories with proper permissions (700)
- Corporate file structures and documentation
- Placeholder files for realistic environment

#### 3. `task_a1.sh` - Password Cracking Challenge Setup
**Execution**: After task_global.sh
**Purpose**: Creates password file cracking challenge (Flag 1)
**Runtime**: ~1-2 seconds

**Build-time Actions**:
- Creates challenge structure in `/home/jdoe/`
- Sets up corporate documentation and IT guides
- Prepares framework for runtime archive creation

**Challenge Details**:
- **Flag**: Flag 1 (100 points)
- **Location**: `/home/jdoe/corporate_credentials_backup.zip`
- **Skills Tested**: Persistence, Openness
- **Method**: Password cracking with rockyou.txt

#### 4. `task_a.sh` - SQL Injection Challenge Setup  
**Execution**: After task_a1.sh
**Purpose**: Creates corporate database for SQL injection (Flag 3)
**Runtime**: ~2-3 seconds

**Build-time Actions**:
- Creates SQLite database structure at `/opt/ctf/data/users.db`
- Sets up web application framework at `/var/www/html/app.py`
- Creates `employees` and `root_account` tables with placeholder hashes

**Database Structure**:
```sql
employees (username, password_hash, department)
root_account (username, password_hash, access_level)
```

**Challenge Details**:
- **Flag**: Flag 3 (250 points)
- **Location**: Embedded in application response
- **Skills Tested**: Risk-taking, Persistence
- **Method**: Targeted SQL injection for corporate users

#### 5. `task_b1.sh` - Cron Script Exploitation Setup
**Execution**: After task_a.sh  
**Purpose**: Creates privilege escalation via cron script (Flag 5)
**Runtime**: ~1-2 seconds

**Build-time Actions**:
- Creates exploitable backup script in `/home/mjohnson/scripts/`
- Sets up cron job framework for root execution
- Prepares corporate IT infrastructure simulation

**Challenge Details**:
- **Flag**: Flag 5 (300 points)
- **Location**: `/root/backup_flag.txt` (accessible only via exploitation)
- **Skills Tested**: Persistence, Resilience
- **Method**: Script modification + cron exploitation

#### 6. `task_b2.sh` - SUID Binary Exploitation Setup
**Execution**: After task_b1.sh
**Purpose**: Creates SUID binary privilege escalation (Flag 6)
**Runtime**: ~2-3 seconds

**Build-time Actions**:
- Compiles vulnerable SUID binary at `/home/dwilson/tools/vim.basic`
- Creates development workspace with corporate tools
- Sets up proper SUID permissions and ownership

**Vulnerability**: Command injection via `system()` call
**Challenge Details**:
- **Flag**: Flag 6 (350 points)
- **Location**: `/root/suid_flag.txt` (accessible only via exploitation)
- **Skills Tested**: Persistence, Risk-taking
- **Method**: SUID binary exploitation

#### 7. `task_b3.sh` - Buffer Overflow Challenge Setup
**Execution**: Last in setup.sh
**Purpose**: Creates buffer overflow exploitation challenge (Flag 7)
**Runtime**: ~2-3 seconds

**Build-time Actions**:
- Compiles vulnerable note manager at `/home/lgarcia/projects/note_manager/`
- Creates development environment with debugging tools
- Sets up corporate software development workspace
- Configures SUID root binary for privilege escalation
- Implements working note storage functionality for realism

**Vulnerability**: Buffer overflow via `gets()` function with detection mechanism
**Technical Implementation**:
- **Binary Type**: SUID root executable (`-rwsr-xr-x 1 root development`)
- **Normal Functionality**: Working note manager (add/view personal notes)
- **Debug Information**: Shows function addresses to aid exploitation
- **Detection Threshold**: Triggers on input >70 characters
- **Security Context**: Reads flag only when running with root privileges

**Challenge Details**:
- **Flag**: Flag 7 (400 points)
- **Location**: `/opt/ctf/data/flag7_content.txt` (accessible only via SUID exploitation)
- **Skills Tested**: Persistence, Openness, Binary Analysis
- **Method**: Buffer overflow detection triggers flag revelation
- **Decoy Mechanism**: Appears as legitimate development tool with known vulnerabilities

### Phase 2: Runtime Scripts (Container Startup)

#### 8. `stealth_runtime_export.sh` - Runtime Secret Generation
**Execution**: Container startup via supervisord (priority 20)
**Purpose**: Generates unique passwords, flags, and populates databases
**Runtime**: ~10-15 seconds
**Self-destructs**: Yes (removes all traces)

**Runtime Actions**:

##### Password Generation
- Generates unique passwords for all corporate users from rockyou.txt
- Creates challenging root password from end of rockyou.txt
- Uses `/dev/urandom` for true randomness across containers
- Sets all user passwords via `chpasswd`

##### Flag Generation  
- **Flag 1**: Creates password-protected corporate_credentials_backup.zip
- **Flag 2**: Places in `/home/kmiller/annual_financial_report_2024.txt`
- **Flag 3**: Stores for database injection response
- **Flag 4**: Places in `/home/asmith/system_backup_keys.txt` (honeypot)
- **Flag 5**: Stores for cron script task
- **Flag 6**: Stores for SUID binary task  
- **Flag 7**: Stores for buffer overflow task
- **Flag 8**: Places in `/root/board_meeting_minutes.txt`

##### Database Population
- Updates SQLite database with actual MD5 password hashes
- Creates honeypot asmith hash (different from real password)
- Updates root account with SHA-512 hash
- Embeds Flag 3 in web application

##### Data Export
All data exported to external logging system with labels:
- `[USER_CREDENTIALS]`: All user passwords
- `[FLAG]`: All flag locations and content
- `[DATABASE_HASH]`: All password hashes with plaintext
- `[TASK_*]`: Challenge completion data

##### Security Cleanup
- Removes script itself and all runtime data
- Clears bash history and system logs
- Removes supervisord program entry
- Ensures no traces remain for participants

---

## Flag Distribution & Scoring

| Flag | Points | Location | Challenge Type | Skills Tested |
|------|--------|----------|----------------|---------------|
| Flag 1 | 100 | `/home/jdoe/corporate_credentials_backup.zip` | Password Cracking | Persistence, Openness |
| Flag 2 | 200 | `/home/kmiller/annual_financial_report_2024.txt` | Lateral Movement | Risk-taking |
| Flag 3 | 250 | Database/Application Response | SQL Injection | Risk-taking, Persistence |
| Flag 4 | 450 | `/home/asmith/system_backup_keys.txt` | Honeypot Access | All traits |
| Flag 5 | 300 | `/root/backup_flag.txt` | Cron Exploitation | Persistence, Resilience |
| Flag 6 | 350 | `/root/suid_flag.txt` | SUID Binary | Persistence, Risk-taking |
| Flag 7 | 400 | SUID Binary Detection | Buffer Overflow | Persistence, Openness |
| Flag 8 | 500 | `/root/board_meeting_minutes.txt` | Root Access | All traits |

**Total Points**: 2,550

---

## Task B3: Buffer Overflow Walkthrough

### Discovery Phase (Without Source Code Access)

#### 1. Initial Access and Enumeration
After gaining access to the `lgarcia` account (Senior Software Engineer):

```bash
# Access lgarcia account via previous exploit (e.g., SQL injection)
su lgarcia

# Enumerate user's workspace
ls -la /home/lgarcia/
cd projects/
ls -la
```

**Expected Findings**:
- `note_manager/` directory suggesting a development project
- Multiple project directories indicating active development work

#### 2. Binary Discovery and Analysis
```bash
cd /home/lgarcia/projects/note_manager/
ls -la

# Key observations:
# -rwsr-xr-x 1 root development  note_manager  <- SUID bit set!
# -rw-r--r-- 1 lgarcia development note_manager.c
# -rw-r--r-- 1 lgarcia development README.md
# -rw-r--r-- 1 lgarcia development TODO.txt
# -rw-r--r-- 1 lgarcia development INSTALL_NOTES.txt
```

**Critical Discovery**: SUID root binary owned by root but executable by development group.

#### 3. Information Gathering
```bash
# Read supporting documentation
cat README.md        # Shows compilation flags and basic functionality
cat TODO.txt         # Reveals known security issues and pending fixes
cat INSTALL_NOTES.txt # Indicates production deployment requires SUID

# Examine source code for vulnerabilities
cat note_manager.c   # Shows gets() function usage (classic vulnerability)
```

**Key Intelligence Gathered**:
- Binary compiled with disabled protections (`-fno-stack-protector -z execstack -no-pie`)
- TODO reveals buffer overflow vulnerability in `add_note()` function
- Source shows `gets()` function (unsafe input handling)
- SUID installation planned for production access

#### 4. Binary Analysis Without Source
If source code wasn't available, participants would use:

```bash
# Basic file analysis
file note_manager
# note_manager: setuid ELF 64-bit LSB executable, ... not stripped

# String analysis
strings note_manager | grep -i "function\|address\|debug"
# Shows: "Debug build - Function addresses:"
# Shows: "secret_function: %p"

# Disassembly (if available)
objdump -d note_manager | grep -A 10 -B 10 "gets\|strcpy"
# Would reveal unsafe function usage

# Runtime information gathering
./note_manager
# Shows debug output with function addresses
```

### Exploitation Phase

#### 5. Normal Functionality Testing
```bash
# Test normal operation to understand behavior
./note_manager

# Try adding normal notes
# Choice: 2
# Enter new note: "Test note"
# Result: Note saved successfully

# Verify note storage
# Choice: 1
# Result: Shows work notes + personal notes including "Test note"
```

**Observation**: Binary has working functionality, making it appear legitimate.

#### 6. Vulnerability Testing
```bash
# Test for buffer overflow
./note_manager

# Choice: 2 (Add note)
# Enter new note: [Long string > 70 characters]
python3 -c "print('A' * 80)"

# Input: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

#### 7. Successful Exploitation
**Expected Output**:
```
*** SECURITY ALERT: Buffer overflow attempt detected! ***
Input length: 80 bytes (expected: <64 bytes)
Malicious payload detected and logged
Security team (asmith) has been notified

BREACH ANALYSIS: Potential buffer overflow exploitation
Emergency protocols activated...

=== PRIVILEGE ESCALATION DETECTED ===
ROOT ACCESS ATTEMPT LOGGED: flag{a1b2c3d4e5f6} - 400 points

*** WARNING: This was a honeypot/decoy system ***
*** Real root access NOT granted - incident logged ***
*** All exploitation attempts are monitored ***
```

### Alternative Discovery Methods

#### Without Source Code Access
1. **Binary String Analysis**:
   ```bash
   strings note_manager | grep -E "(gets|strcpy|scanf)"
   ```

2. **Dynamic Analysis**:
   ```bash
   strace ./note_manager  # Trace system calls
   ltrace ./note_manager  # Trace library calls
   ```

3. **Debugging with GDB**:
   ```bash
   gdb ./note_manager
   (gdb) disas main
   (gdb) disas add_note
   (gdb) info functions
   ```

4. **Fuzzing Approach**:
   ```bash
   # Send progressively longer inputs
   for i in {10..100..10}; do
       echo "2" | timeout 5 ./note_manager << EOF
   $(python3 -c "print('A' * $i)")
   EOF
   done
   ```

### Skills Measured

**Persistence**: 
- Systematic enumeration of lgarcia's workspace
- Reading all available documentation
- Testing different input lengths

**Openness**:
- Willingness to analyze unfamiliar binary
- Using debugging/analysis tools
- Experimenting with buffer overflow techniques

**Technical Skills**:
- SUID binary recognition
- Source code vulnerability analysis
- Buffer overflow concept understanding
- Command-line tool proficiency

### Research Insights

This challenge measures:
- **Time spent analyzing**: How long participants examine the binary and documentation
- **Tool usage**: Whether they use strings, objdump, gdb, or other analysis tools
- **Systematic approach**: Do they test normal functionality before attempting exploitation
- **Risk assessment**: Understanding that SUID binaries can provide privilege escalation

---

## Corporate Environment Structure

### Department Hierarchy
```
Executive Level
├── tbrown (Executive)
└── canderson (Management)

Operational Departments  
├── Sysadmin: asmith
├── IT: mjohnson, jdoe (intern)
├── Development: lgarcia, dwilson
├── HR: swilliams, rdavis
└── Finance: kmiller, bthompson
```

### Entry Points
1. **Primary**: SSH as `jdoe` with password `welcome123`
2. **Discovery**: Service enumeration and corporate user identification
3. **Progression**: Lateral movement through corporate departments

### Realistic Corporate Assets
- Employee handbook and IT documentation
- Financial reports and corporate communications
- Development tools and code repositories  
- System backup procedures and admin tools
- Executive meeting minutes and strategic documents

---

## Research Data Collection

### Logging Labels Captured
- **User Activity**: `[USER_CREDENTIALS]`, `[USER_VERIFICATION]`
- **Challenge Progress**: `[TASK_A1_*]`, `[TASK_B*_*]` 
- **Security Data**: `[DATABASE_HASH]`, `[FLAG]`
- **System Status**: `[DATABASE_INFO]`, `[RUNTIME_EXPORT_COMPLETE]`

### Personality Trait Measurement
- **Persistence**: Password cracking attempts, repeated exploitation tries
- **Resilience**: Recovery from failed attempts, alternative approach usage
- **Risk-taking**: SQL injection experimentation, binary exploitation attempts
- **Openness**: Tool usage willingness, unconventional solution exploration

### External System Integration
- **Coder**: Workspace management and container orchestration
- **Promtail**: Log collection and parsing from Docker containers
- **Loki**: Time-series log storage and indexing
- **Grafana**: Real-time dashboards and research analytics

---

## Security Considerations

### Build-time Security
- No secrets generated during image creation
- Placeholder values prevent information leakage
- Clean separation between structure and content

### Runtime Security  
- Unique secrets per participant prevent answer sharing
- Self-destructing setup script removes all traces
- External logging captures research data without container access
- Database permissions prevent direct file access

### Research Integrity
- True randomization via `/dev/urandom` ensures unique experiences
- Honeypot admin account tests thorough enumeration
- Multiple exploitation paths accommodate different skill levels
- Comprehensive logging captures all participant actions

---

## Troubleshooting

### Build Issues
- Ensure all task scripts are executable (`chmod +x`)
- Check Docker build context includes all necessary files
- Verify rockyou.txt wordlist is available

### Runtime Issues  
- Check supervisord configuration for script execution
- Verify external logging system connectivity
- Ensure proper Docker container labeling for log collection

### Research Data Issues
- Confirm Promtail parsing rules match log format
- Verify Grafana dashboard queries use correct labels
- Check Loki retention settings for long-term studies

---

## Development Guidelines

### Adding New Challenges
1. Create build-time setup script in `tasks/`
2. Add runtime secret generation to `stealth_runtime_export.sh`
3. Update documentation with new flag and scoring
4. Add logging labels for research data collection

### Modifying Corporate Structure
1. Update user creation in `task_global.sh`
2. Adjust group memberships and permissions
3. Update file ownership and directory structures
4. Document changes for research context

### Security Updates
1. Review secret generation methods for randomness
2. Audit cleanup procedures for trace removal
3. Verify external logging captures necessary data
4. Test multi-participant isolation

This documentation serves as the complete reference for understanding, maintaining, and extending the CTF corporate environment for personality profiling research. 