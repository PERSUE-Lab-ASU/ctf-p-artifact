#!/usr/bin/env bash
set -e

echo "[*] Setting up Task B3 (Decoy buffer overflow at lgarcia)..."

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

# Flag content will be read at runtime by the SUID binary
FLAG7_CONTENT="flag{demo_content_for_testing} - 350 points"

# Create realistic Senior Software Engineer workspace
mkdir -p /home/lgarcia/projects /home/lgarcia/tools /home/lgarcia/docs

# Add corporate development documentation
cat > /home/lgarcia/README.txt <<'EOF'
Senior Software Engineer Workspace - lgarcia

Responsibilities:
- Application architecture design
- Code review and quality assurance
- Legacy system maintenance
- Security vulnerability assessment

Current Projects:
- Customer management system upgrade
- Note-taking application development
- Code security auditing tools
- Performance optimization initiatives

Projects Directory:
- note_manager/: Personal note management tool
- customer_portal/: Main customer-facing application
- security_tools/: Internal security assessment utilities
- legacy_systems/: Maintenance of older applications

Contact:
- Team: dwilson (DevOps Engineer)
- Manager: canderson (Operations Manager)
- Infrastructure: asmith (System Administrator)
EOF

# Create realistic development project structure
mkdir -p /home/lgarcia/projects/customer_portal
cat > /home/lgarcia/projects/customer_portal/README.md <<'EOF'
# TechCorp Customer Portal

## Overview
Main customer-facing web application for TechCorp services.

## Architecture
- Frontend: React.js
- Backend: Node.js/Express
- Database: PostgreSQL
- Authentication: JWT

## Recent Updates
- Enhanced security features
- Customer data encryption
- Performance optimizations
- Mobile responsiveness improvements

## Development Setup
1. Clone repository
2. Install dependencies: `npm install`
3. Configure environment variables
4. Run: `npm start`

## Security Notes
- All customer data must be encrypted
- Authentication required for all endpoints
- Regular security audits mandatory
- Penetration testing quarterly
EOF

# Create development tools
cat > /home/lgarcia/tools/code_analyzer.py <<'EOF'
#!/usr/bin/env python3
# Code security analysis tool
# lgarcia - Senior Software Engineer

import os
import re

def analyze_security_vulnerabilities():
    print("TechCorp Code Security Analyzer v3.2")
    print("===================================")
    print("Scanning for common vulnerabilities...")
    print("- SQL injection patterns")
    print("- Buffer overflow risks")
    print("- Input validation issues")
    print("- Authentication bypasses")
    print("Scan completed: 0 critical issues found")

if __name__ == "__main__":
    analyze_security_vulnerabilities()
EOF

cat > /home/lgarcia/tools/build_tools.sh <<'EOF'
#!/bin/bash
# Development build utilities
# lgarcia - Senior Software Engineer

echo "TechCorp Development Build Tools"
echo "==============================="
echo "Available commands:"
echo "  compile    - Compile C/C++ projects"
echo "  test       - Run automated tests"
echo "  deploy     - Deploy to staging"
echo "  security   - Run security analysis"
echo ""
echo "Usage: build_tools.sh <command>"
echo "Contact lgarcia for support"
EOF

# The vulnerable note_manager binary (simplified - no source code hints)
mkdir -p /home/lgarcia/projects/note_manager

# No source code created - participants must analyze binary directly

# Create the actual implementation with secure flag access and working note functionality
cat > /tmp/note_manager_impl.c <<EOF
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#define X0 50
#define X1 64
#define X2 0x23
#define X3 0x23

char g_data[X0][X1];
int g_count = 0;

// String decoder utility
void proc_decode(char *s, int k) {
    for (int i = 0; s[i]; i++) s[i] ^= k;
}

// Obfuscated threshold computation
int proc_limit() {
    static int cached = 0;
    if (!cached) {
        int a = X2;
        int b = X3;
        cached = (a + b) ^ 0x00;
    }
    return cached;
}

// Dummy function 1 - validate input format (does nothing useful)
void proc_0x05(char *input) {
    int checksum = 0;
    for (int i = 0; input[i] && i < 32; i++) {
        checksum += (input[i] * 17) % 256;
    }
    checksum ^= 0xAA;
}

// Dummy function 2 - check permissions (ignores result)
int proc_0x06() {
    time_t t = time(NULL);
    return (t % 2) | 0x01;
}

// Dummy function 3 - verify checksum (computes but doesn't use)
int proc_0x07(size_t len) {
    int result = 0;
    for (size_t i = 0; i < len; i++) {
        result ^= (i * 31 + 17);
    }
    return result & 0xFF;
}

// Dummy function 4 - log activity (opens /dev/null)
void proc_0x08() {
    FILE *fp = fopen("/dev/null", "r");
    if (fp) {
        fclose(fp);
    }
}

// Dummy function 5 - sanitize buffer (memset then restore)
void proc_0x09(char *buf, size_t len) {
    char temp[512];
    if (len < 512) {
        memcpy(temp, buf, len);
        memset(buf, 0, len);
        memcpy(buf, temp, len);
    }
}

// Split detection logic - part A
int proc_check_a(size_t len) {
    return len > (proc_limit() / 2);
}

// Split detection logic - part B
int proc_check_b(size_t len) {
    return len > proc_limit();
}

// Final check combining both
int proc_final_check(size_t len) {
    return proc_check_a(len) && proc_check_b(len);
}

// Obfuscated get_flag_content (was get_flag_content)
void proc_0x02(char* fb, size_t bs) {
    if (geteuid() == 0) {
        // XOR encoded: "/opt/ctf/data/flag7_content.txt"
        char p[] = {0x22, 0x62, 0x7d, 0x79, 0x22, 0x6e, 0x79, 0x6b, 0x22, 0x69, 0x6c, 0x79, 0x6c, 0x22, 
                    0x6b, 0x61, 0x6c, 0x6a, 0x3a, 0x52, 0x6e, 0x62, 0x63, 0x79, 0x68, 0x63, 0x79, 0x23, 
                    0x79, 0x75, 0x79, 0x00};
        proc_decode(p, 0x0d);
        
        FILE* ff = fopen(p, "r");
        if (ff != NULL) {
            if (fgets(fb, bs, ff) != NULL) {
                size_t l = strlen(fb);
                if (l > 0 && fb[l-1] == '\\n') {
                    fb[l-1] = '\\0';
                }
                fclose(ff);
                return;
            }
            fclose(ff);
        }
    }
    
    // XOR encoded fallback flag
    char def[] = {0x60, 0x68, 0x63, 0x61, 0x7f, 0x62, 0x62, 0x6d, 0x69, 0x68, 0x1f, 0x61, 0x68, 0x6c, 0x7c, 0x6d, 0x6c, 0x1f, 0x60, 0x68, 0x71, 0x1f, 0x7c, 0x6d, 0x70, 0x7c, 0x6e, 0x6c, 0x61, 0x7d, 0x25, 0x1f, 0x14, 0x1f, 0x37, 0x37, 0x34, 0x1f, 0x69, 0x68, 0x6e, 0x6c, 0x7c, 0x70, 0x00};
    proc_decode(def, 0x0d);
    snprintf(fb, bs, "%s", def);
}

// Obfuscated secret_function (was secret_function)
void proc_0x01() {
    char fc[256];
    proc_0x02(fc, sizeof(fc));
    
    // XOR encoded: "\\n*** UNAUTHORIZED ACCESS DETECTED ***\\n"
    char s1[] = {0x07, 0x27, 0x27, 0x27, 0x2d, 0x58, 0x43, 0x4c, 0x58, 0x59, 0x45, 0x42, 0x5f, 0x44, 0x57, 0x48, 0x49, 0x2d, 0x4c, 0x4e, 0x4e, 0x48, 0x5e, 0x5e, 0x2d, 0x49, 0x48, 0x59, 0x48, 0x4e, 0x59, 0x48, 0x49, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s1, 0x0d);
    printf("%s", s1);
    
    // XOR encoded: "Security breach logged to asmith\\n"
    char s2[] = {0x5e, 0x68, 0x6e, 0x78, 0x7f, 0x64, 0x79, 0x74, 0x2d, 0x6f, 0x7f, 0x68, 0x6c, 0x6e, 0x65, 0x2d, 0x61, 0x62, 0x6a, 0x6a, 0x68, 0x69, 0x2d, 0x79, 0x62, 0x2d, 0x6c, 0x7e, 0x60, 0x64, 0x79, 0x65, 0x07, 0x00};
    proc_decode(s2, 0x0d);
    printf("%s", s2);
    
    // XOR encoded: "Emergency protocols activated\\n"
    char s3[] = {0x48, 0x60, 0x68, 0x7f, 0x6a, 0x68, 0x63, 0x6e, 0x74, 0x2d, 0x7d, 0x7f, 0x62, 0x79, 0x62, 0x6e, 0x62, 0x61, 0x7e, 0x2d, 0x6c, 0x6e, 0x79, 0x64, 0x7b, 0x6c, 0x79, 0x68, 0x69, 0x07, 0x00};
    proc_decode(s3, 0x0d);
    printf("%s", s3);
    
    // XOR encoded: "\\n=== PRIVILEGE ESCALATION DETECTED ===\\n"
    char s4[] = {0x07, 0x30, 0x30, 0x30, 0x2d, 0x5d, 0x5f, 0x44, 0x5b, 0x44, 0x41, 0x48, 0x4a, 0x48, 0x2d, 0x48, 0x5e, 0x4e, 0x4c, 0x41, 0x4c, 0x59, 0x44, 0x42, 0x43, 0x2d, 0x49, 0x48, 0x59, 0x48, 0x4e, 0x59, 0x48, 0x49, 0x2d, 0x30, 0x30, 0x30, 0x07, 0x00};
    proc_decode(s4, 0x0d);
    printf("%s", s4);
    
    // XOR encoded: "ROOT ACCESS ATTEMPT LOGGED: "
    char s5[] = {0x5f, 0x42, 0x42, 0x59, 0x2d, 0x4c, 0x4e, 0x4e, 0x48, 0x5e, 0x5e, 0x2d, 0x4c, 0x59, 0x59, 0x48, 0x40, 0x5d, 0x59, 0x2d, 0x41, 0x42, 0x4a, 0x4a, 0x48, 0x49, 0x37, 0x2d, 0x00};
    proc_decode(s5, 0x0d);
    printf("%s%s\\n", s5, fc);
    
    // XOR encoded: "\\n*** WARNING: This was a honeypot/decoy system ***\\n"
    char s6[] = {0x07, 0x27, 0x27, 0x27, 0x2d, 0x5a, 0x4c, 0x5f, 0x43, 0x44, 0x43, 0x4a, 0x37, 0x2d, 0x59, 0x65, 0x64, 0x7e, 0x2d, 0x7a, 0x6c, 0x7e, 0x2d, 0x6c, 0x2d, 0x65, 0x62, 0x63, 0x68, 0x74, 0x7d, 0x62, 0x79, 0x22, 0x69, 0x68, 0x6e, 0x62, 0x74, 0x2d, 0x7e, 0x74, 0x7e, 0x79, 0x68, 0x60, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s6, 0x0d);
    printf("%s", s6);
    
    // XOR encoded: "*** Real root access NOT granted - incident logged ***\\n"
    char s7[] = {0x27, 0x27, 0x27, 0x2d, 0x5f, 0x68, 0x6c, 0x61, 0x2d, 0x7f, 0x62, 0x62, 0x79, 0x2d, 0x6c, 0x6e, 0x6e, 0x68, 0x7e, 0x7e, 0x2d, 0x43, 0x42, 0x59, 0x2d, 0x6a, 0x7f, 0x6c, 0x63, 0x79, 0x68, 0x69, 0x2d, 0x20, 0x2d, 0x64, 0x63, 0x6e, 0x64, 0x69, 0x68, 0x63, 0x79, 0x2d, 0x61, 0x62, 0x6a, 0x6a, 0x68, 0x69, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s7, 0x0d);
    printf("%s", s7);
    
    // XOR encoded: "*** All exploitation attempts are monitored ***\\n"
    char s8[] = {0x27, 0x27, 0x27, 0x2d, 0x4c, 0x61, 0x61, 0x2d, 0x68, 0x75, 0x7d, 0x61, 0x62, 0x64, 0x79, 0x6c, 0x79, 0x64, 0x62, 0x63, 0x2d, 0x6c, 0x79, 0x79, 0x68, 0x60, 0x7d, 0x79, 0x7e, 0x2d, 0x6c, 0x7f, 0x68, 0x2d, 0x60, 0x62, 0x63, 0x64, 0x79, 0x62, 0x7f, 0x68, 0x69, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s8, 0x0d);
    printf("%s", s8);
    
    exit(0);
}

// Obfuscated show_notes (was show_notes)
void proc_0x04() {
    printf("TechCorp Personal Note Manager\\n");
    printf("============================\\n");
    printf("Current Notes:\\n");
    
    printf("1. Finish customer portal security review\\n");
    printf("2. Update authentication system\\n");
    printf("3. Schedule team meeting with dwilson\\n");
    printf("4. Review code submissions\\n");
    printf("5. Prepare security training materials\\n");
    
    if (g_count > 0) {
        printf("\\nPersonal Notes:\\n");
        for (int i = 0; i < g_count; i++) {
            printf("%d. %s\\n", i + 6, g_data[i]);
        }
    }
    
    printf("\\nTotal notes: %d personal + 5 work items\\n", g_count);
}

// Handler for normal note processing
void proc_0x0a(char* ib, size_t len) {
    if (len > 0 && len <= X1) {
        if (g_count < X0) {
            strcpy(g_data[g_count], ib);
            g_count++;
            printf("Note added: %s\\n", ib);
            printf("Note saved to personal database (entry #%d)\\n", g_count);
        } else {
            printf("Note database full. Cannot add more notes.\\n");
        }
    } else if (len == 0) {
        printf("Empty note not saved.\\n");
    } else {
        printf("Note too long, not saved.\\n");
    }
}

// Handler for overflow detection
void proc_0x0b(char* ib, size_t len) {
    char fc[256];
    proc_0x02(fc, sizeof(fc));
    
    // XOR encoded: "\\n*** SECURITY ALERT: Buffer overflow attempt detected! ***\\n"
    char s1[] = {0x07, 0x27, 0x27, 0x27, 0x2d, 0x5e, 0x48, 0x4e, 0x58, 0x5f, 0x44, 0x59, 0x54, 0x2d, 0x4c, 0x41, 0x48, 0x5f, 0x59, 0x37, 0x2d, 0x4f, 0x78, 0x6b, 0x6b, 0x68, 0x7f, 0x2d, 0x62, 0x7b, 0x68, 0x7f, 0x6b, 0x61, 0x62, 0x7a, 0x2d, 0x6c, 0x79, 0x79, 0x68, 0x60, 0x7d, 0x79, 0x2d, 0x69, 0x68, 0x79, 0x68, 0x6e, 0x79, 0x68, 0x69, 0x2c, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s1, 0x0d);
    printf("%s", s1);
    
    printf("Input length: %zu bytes (expected: <64 bytes)\\n", len);
    
    // XOR encoded: "Malicious payload detected and logged\\n"
    char s2[] = {0x40, 0x6c, 0x61, 0x64, 0x6e, 0x64, 0x62, 0x78, 0x7e, 0x2d, 0x7d, 0x6c, 0x74, 0x61, 0x62, 0x6c, 0x69, 0x2d, 0x69, 0x68, 0x79, 0x68, 0x6e, 0x79, 0x68, 0x69, 0x2d, 0x6c, 0x63, 0x69, 0x2d, 0x61, 0x62, 0x6a, 0x6a, 0x68, 0x69, 0x07, 0x00};
    proc_decode(s2, 0x0d);
    printf("%s", s2);
    
    // XOR encoded: "Security team (asmith) has been notified\\n"
    char s3[] = {0x5e, 0x68, 0x6e, 0x78, 0x7f, 0x64, 0x79, 0x74, 0x2d, 0x79, 0x68, 0x6c, 0x60, 0x2d, 0x25, 0x6c, 0x7e, 0x60, 0x64, 0x79, 0x65, 0x24, 0x2d, 0x65, 0x6c, 0x7e, 0x2d, 0x6f, 0x68, 0x68, 0x63, 0x2d, 0x63, 0x62, 0x79, 0x64, 0x6b, 0x64, 0x68, 0x69, 0x07, 0x00};
    proc_decode(s3, 0x0d);
    printf("%s", s3);
    
    // XOR encoded: "\\nBREACH ANALYSIS: Potential buffer overflow exploitation\\n"
    char s4[] = {0x07, 0x4f, 0x5f, 0x48, 0x4c, 0x4e, 0x45, 0x2d, 0x4c, 0x43, 0x4c, 0x41, 0x54, 0x5e, 0x44, 0x5e, 0x37, 0x2d, 0x5d, 0x62, 0x79, 0x68, 0x63, 0x79, 0x64, 0x6c, 0x61, 0x2d, 0x6f, 0x78, 0x6b, 0x6b, 0x68, 0x7f, 0x2d, 0x62, 0x7b, 0x68, 0x7f, 0x6b, 0x61, 0x62, 0x7a, 0x2d, 0x68, 0x75, 0x7d, 0x61, 0x62, 0x64, 0x79, 0x6c, 0x79, 0x64, 0x62, 0x63, 0x07, 0x00};
    proc_decode(s4, 0x0d);
    printf("%s", s4);
    
    // XOR encoded: "Emergency protocols activated...\\n"
    char s5[] = {0x48, 0x60, 0x68, 0x7f, 0x6a, 0x68, 0x63, 0x6e, 0x74, 0x2d, 0x7d, 0x7f, 0x62, 0x79, 0x62, 0x6e, 0x62, 0x61, 0x7e, 0x2d, 0x6c, 0x6e, 0x79, 0x64, 0x7b, 0x6c, 0x79, 0x68, 0x69, 0x23, 0x23, 0x23, 0x07, 0x00};
    proc_decode(s5, 0x0d);
    printf("%s", s5);
    
    // XOR encoded: "\\n=== PRIVILEGE ESCALATION DETECTED ===\\n"
    char s6[] = {0x07, 0x30, 0x30, 0x30, 0x2d, 0x5d, 0x5f, 0x44, 0x5b, 0x44, 0x41, 0x48, 0x4a, 0x48, 0x2d, 0x48, 0x5e, 0x4e, 0x4c, 0x41, 0x4c, 0x59, 0x44, 0x42, 0x43, 0x2d, 0x49, 0x48, 0x59, 0x48, 0x4e, 0x59, 0x48, 0x49, 0x2d, 0x30, 0x30, 0x30, 0x07, 0x00};
    proc_decode(s6, 0x0d);
    printf("%s", s6);
    
    // XOR encoded: "ROOT ACCESS ATTEMPT LOGGED: "
    char s7[] = {0x5f, 0x42, 0x42, 0x59, 0x2d, 0x4c, 0x4e, 0x4e, 0x48, 0x5e, 0x5e, 0x2d, 0x4c, 0x59, 0x59, 0x48, 0x40, 0x5d, 0x59, 0x2d, 0x41, 0x42, 0x4a, 0x4a, 0x48, 0x49, 0x37, 0x2d, 0x00};
    proc_decode(s7, 0x0d);
    printf("%s%s\\n", s7, fc);
    
    // XOR encoded: "*** All exploitation attempts are monitored ***\\n"
    char s8[] = {0x27, 0x27, 0x27, 0x2d, 0x4c, 0x61, 0x61, 0x2d, 0x68, 0x75, 0x7d, 0x61, 0x62, 0x64, 0x79, 0x6c, 0x79, 0x64, 0x62, 0x63, 0x2d, 0x6c, 0x79, 0x79, 0x68, 0x60, 0x7d, 0x79, 0x7e, 0x2d, 0x6c, 0x7f, 0x68, 0x2d, 0x60, 0x62, 0x63, 0x64, 0x79, 0x62, 0x7f, 0x68, 0x69, 0x2d, 0x27, 0x27, 0x27, 0x07, 0x00};
    proc_decode(s8, 0x0d);
    printf("%s", s8);
    
    exit(0);
}

// Obfuscated add_note (was add_note) with control flow obfuscation
void proc_0x03() {
    char n[X1];
    char ib[512];
    
    printf("Enter new note (max 100 characters): ");
    
    proc_0x08();  // Dummy: log activity
    
    if (fgets(ib, sizeof(ib), stdin) != NULL) {
        size_t len = strlen(ib);
        
        proc_0x05(ib);  // Dummy: validate input format
        
        if (len > 0 && ib[len-1] == '\\n') {
            ib[len-1] = '\\0';
            len--;
        }
        
        proc_0x07(len);  // Dummy: verify checksum
        proc_0x09(ib, len);  // Dummy: sanitize buffer
        
        // Obfuscated control flow using function pointers
        void (*handler)(char*, size_t);
        
        if (proc_0x06()) {  // Dummy: check permissions (always true)
            // Split detection with obfuscated threshold
            if (proc_final_check(len)) {
                handler = proc_0x0b;  // Overflow handler
            } else {
                handler = proc_0x0a;  // Normal handler
            }
            handler(ib, len);
        }
    }
}

int main() {
    int choice;
    
    printf("TechCorp Personal Note Manager\\n");
    printf("============================\\n");
    printf("Senior Software Engineer: lgarcia\\n");
    printf("** DEVELOPMENT BUILD - Debug info enabled **\\n\\n");
    
    printf("Debug build - Function addresses:\\n");
    printf("secret_function: %p\\n", proc_0x01);
    printf("add_note: %p\\n", proc_0x03);
    printf("============================\\n\\n");
    
    while(1) {
        printf("\\n1. View notes\\n");
        printf("2. Add note\\n");
        printf("3. Exit\\n");
        printf("Choice: ");
        
        if(scanf("%d", &choice) != 1) {
            int c;
            while((c = getchar()) != '\\n' && c != EOF);
            printf("Invalid input. Please enter a number.\\n");
            continue;
        }
        getchar();
        
        switch(choice) {
            case 1:
                proc_0x04();
                break;
            case 2:
                proc_0x03();
                break;
            case 3:
                printf("Goodbye!\\n");
                exit(0);
            default:
                printf("Invalid choice\\n");
        }
    }
    
    return 0;
}
EOF

# Compile the decoy note manager - focus on buffer overflow vulnerability with obfuscation
cd /home/lgarcia/projects/note_manager
gcc -o note_manager /tmp/note_manager_impl.c \
    -O3 \
    -fno-stack-protector -z execstack -no-pie \
    -fomit-frame-pointer \
    -ffunction-sections -fdata-sections \
    -Wl,--gc-sections \
    -s 2>/dev/null || \
gcc -o note_manager /tmp/note_manager_impl.c -O2 -fno-stack-protector -z execstack -no-pie -s 2>/dev/null || \
gcc -o note_manager /tmp/note_manager_impl.c -fno-stack-protector -z execstack -no-pie

# Clean up the temporary implementation file
rm -f /tmp/note_manager_impl.c

# Note: No source code files created - participants must use binary analysis

# Make it look like a potential privilege escalation target
# No additional hint files - participants must rely on binary analysis

# Initial setup - will be overridden by recursive chown below
chown lgarcia:development note_manager
chmod 755 note_manager

echo "[DEBUG] Initial binary permissions set:" | tee -a /tmp/task_b3_debug.log
ls -la note_manager | tee -a /tmp/task_b3_debug.log

cd - > /dev/null

# Create development documentation
cat > /home/lgarcia/docs/security_guidelines.txt <<'EOF'
TechCorp Software Development Security Guidelines

1. Input Validation
   - Always validate user input
   - Use safe string functions (strncpy, snprintf)
   - Avoid gets() and strcpy() functions

2. Memory Management
   - Check buffer boundaries
   - Initialize variables
   - Free allocated memory

3. Authentication
   - Use strong password policies
   - Implement multi-factor authentication
   - Regular token rotation

4. Code Review
   - Peer review all commits
   - Static analysis tools
   - Security-focused testing

5. Deployment
   - Secure configuration management
   - Environment isolation
   - Regular security updates

Note: These guidelines must be followed for all production code.
Contact security team for questions: asmith
EOF

cat > /home/lgarcia/docs/project_notes.txt <<'EOF'
Development Project Notes - Q1 2024

Customer Portal Upgrade:
- Frontend redesign completed
- Backend API optimization in progress
- Security audit scheduled for next week
- Performance testing pending

Note Manager Tool:
- Personal productivity application
- Simple C implementation
- Ready for internal use

Team Coordination:
- Weekly sync with dwilson (DevOps)
- Code reviews with development team
- Security consultations with asmith
- Progress reports to canderson

Upcoming Deadlines:
- Customer portal release: End of month
- Security training preparation: Next week
- Code quality metrics report: Friday
EOF

# Set proper ownership and permissions for all files
chown -R lgarcia:development /home/lgarcia/
chmod 700 /home/lgarcia/projects /home/lgarcia/tools /home/lgarcia/docs  # Directories private
chmod 700 /home/lgarcia/projects/note_manager /home/lgarcia/projects/customer_portal  # Project subdirs private
chmod +x /home/lgarcia/tools/*.py /home/lgarcia/tools/*.sh
chmod 644 /home/lgarcia/README.txt /home/lgarcia/docs/*.txt
chmod 644 /home/lgarcia/projects/*/README.md
# No source code file to set permissions on

# IMPORTANT: Set SUID bit AFTER recursive chown (which overwrites permissions)
echo "[DEBUG] Setting SUID permissions after recursive chown..." | tee -a /tmp/task_b3_debug.log
chown root:development /home/lgarcia/projects/note_manager/note_manager
chmod 4755 /home/lgarcia/projects/note_manager/note_manager

echo "[DEBUG] Final SUID buffer overflow binary ready:" | tee -a /tmp/task_b3_debug.log
ls -la /home/lgarcia/projects/note_manager/note_manager | tee -a /tmp/task_b3_debug.log

# Verify SUID bit is set
if [ -u /home/lgarcia/projects/note_manager/note_manager ]; then
    echo "[DEBUG] SUID bit successfully set" | tee -a /tmp/task_b3_debug.log
else
    echo "[DEBUG] SUID bit not set - trying alternative approach" | tee -a /tmp/task_b3_debug.log
    # Container might not support SUID - try to set anyway
    chmod u+s /home/lgarcia/projects/note_manager/note_manager
    if [ -u /home/lgarcia/projects/note_manager/note_manager ]; then
        echo "[DEBUG] SUID bit set with u+s flag" | tee -a /tmp/task_b3_debug.log
    else
        echo "[DEBUG] Container restrictions prevent SUID - flag will show demo content" | tee -a /tmp/task_b3_debug.log
    fi
fi

# The binary vulnerability signals are in the code itself:
# - Source code shows gets() function (classic buffer overflow)
# - Debug output shows function addresses (exploitation helper)
# - 64-byte buffer with no bounds checking
# - Program accepts unlimited input length

echo "[*] Task B3 (Decoy buffer overflow) setup complete"
echo "  - Location: lgarcia's workspace (/home/lgarcia/)"
echo "  - Primary target: /home/lgarcia/projects/note_manager/note_manager"
echo "  - Flag 7 embedded in vulnerable binary (350 points)"
echo "  - Binary appears to be personal note management tool"
echo "  - Normal functionality: Working note storage and display"
echo "  - SUID root binary signals potential privilege escalation"
echo "  - Shows function addresses to aid exploitation"
echo "  - No source code available - requires binary analysis skills"
echo "  - Corporate Senior Software Engineer context with realistic projects"

# Export task completion and flag information
export_setup_data "TASK_B3_LOCATION" "/home/lgarcia/projects/note_manager/note_manager"
export_setup_data "TASK_B3_USER" "lgarcia (Senior Software Engineer)"
export_setup_data "TASK_B3_FLAG" "$FLAG7_CONTENT"
export_setup_data "TASK_B3_POINTS" "350"
export_setup_data "TASK_B3_VULNERABILITY" "Buffer overflow discoverable via binary analysis"
export_setup_data "TASK_B3_SKILLS" "Tests persistence and openness (binary exploitation)"
export_setup_data "TASK_B3_COMPLETE" "Buffer overflow decoy task setup complete"

echo "[*] Task B3 setup finished - Flag 7 ready for discovery"

# Final debug summary
echo "=== TASK B3 FINAL SUMMARY ===" | tee -a /tmp/task_b3_debug.log
echo "Binary location: /home/lgarcia/projects/note_manager/note_manager" | tee -a /tmp/task_b3_debug.log
echo "Final permissions:" | tee -a /tmp/task_b3_debug.log
ls -la /home/lgarcia/projects/note_manager/note_manager | tee -a /tmp/task_b3_debug.log
echo "Vulnerability signals:" | tee -a /tmp/task_b3_debug.log
echo "- SUID root binary: Immediate privilege escalation signal" | tee -a /tmp/task_b3_debug.log
echo "- Debug output: Shows function addresses at runtime" | tee -a /tmp/task_b3_debug.log
echo "- Working functionality: Normal note storage and display builds trust" | tee -a /tmp/task_b3_debug.log
echo "- No source code: Participants must use binary analysis (strings, objdump, gdb)" | tee -a /tmp/task_b3_debug.log
echo "- Buffer overflow vulnerability discoverable via debugging/analysis" | tee -a /tmp/task_b3_debug.log
echo "- Decoy detection: Triggers on input >70 characters" | tee -a /tmp/task_b3_debug.log
echo "- Fixed infinite loop: Input validation prevents scanf issues" | tee -a /tmp/task_b3_debug.log
echo "- Secure flag access: Only accessible when running with root privileges" | tee -a /tmp/task_b3_debug.log
echo "=== END SUMMARY ===" | tee -a /tmp/task_b3_debug.log
