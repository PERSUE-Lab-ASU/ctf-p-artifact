#!/usr/bin/env bash
set -e

echo "[*] Setting up Task B2 (Decoy SUID binary at dwilson)..."

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

# Read flag content from global setup
# Note: Flag contents will be generated at runtime
FLAG6_CONTENT="FLAG_PLACEHOLDER_WILL_BE_REPLACED_AT_RUNTIME"

# Create realistic DevOps engineer workspace
mkdir -p /home/dwilson/tools /home/dwilson/configs /home/dwilson/projects

# Add corporate DevOps documentation
cat > /home/dwilson/README.txt <<'EOF'
DevOps Engineer Workspace - dwilson

Responsibilities:
- CI/CD pipeline management
- Infrastructure automation
- Container orchestration
- System monitoring and deployment

Current Projects:
- Docker container optimization
- Kubernetes cluster management
- Automated deployment scripts
- Performance monitoring tools

Tools Directory:
- vim.basic: Custom vim configuration tool
- deploy.sh: Automated deployment scripts
- monitor.py: System monitoring utilities
- config_check.sh: Configuration validation tools

Contact:
- Team Lead: lgarcia (Senior Software Engineer)
- Manager: canderson (Operations Manager)
- Infrastructure: asmith (System Administrator)
EOF

# Create realistic DevOps configuration files
cat > /home/dwilson/configs/deployment.yaml <<'EOF'
# TechCorp Deployment Configuration
# DevOps Team - dwilson

apiVersion: apps/v1
kind: Deployment
metadata:
  name: techcorp-web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: techcorp-web
  template:
    metadata:
      labels:
        app: techcorp-web
    spec:
      containers:
      - name: web-app
        image: techcorp/web-app:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          value: "postgres://db.techcorp.local:5432/webapp"
        - name: REDIS_URL
          value: "redis://cache.techcorp.local:6379"
EOF

cat > /home/dwilson/configs/monitoring.conf <<'EOF'
# TechCorp Monitoring Configuration
# DevOps Engineer: dwilson

[Grafana]
Host=grafana.techcorp.local
Port=3000
Database=techcorp_metrics

[Prometheus]
Host=prometheus.techcorp.local
Port=9090
Scrape_Interval=15s

[AlertManager]
Host=alerts.techcorp.local
Port=9093
Webhook_URL=https://slack.techcorp.com/hooks/monitoring

[Services]
Web_App=http://app.techcorp.local:8080/health
Database=postgres://db.techcorp.local:5432
Cache=redis://cache.techcorp.local:6379
EOF

# Create legitimate looking deployment scripts
cat > /home/dwilson/projects/deploy.sh <<'EOF'
#!/bin/bash
# TechCorp Automated Deployment Script
# DevOps Engineer: dwilson

echo "TechCorp Production Deployment Pipeline"
echo "========================================"

# Environment validation
if [ "$ENVIRONMENT" != "production" ] && [ "$ENVIRONMENT" != "staging" ]; then
    echo "Error: Invalid environment. Use 'production' or 'staging'"
    exit 1
fi

echo "Deploying to $ENVIRONMENT environment..."
echo "Validating configuration files..."
echo "Building Docker images..."
echo "Pushing to container registry..."
echo "Updating Kubernetes manifests..."
echo "Rolling out deployment..."
echo "Deployment completed successfully!"
EOF

# Create a vulnerable SUID binary that delivers flag when exploited (decoy)
cat > /tmp/vim_source.c <<EOF
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

#define XK 0x5A

static void dx(char* s, int l) {
    int i; unsigned char k = XK;
    for(i = 0; i < l; i++) {
        s[i] ^= k; k = (k * 31 + 17) & 0xFF;
    }
}

static char* gs(int id) {
    static char b[512];
    int i;
    switch(id) {
        case 0: { char x[] = {0x0e,0x92,0x99,0x3f,0xd9,0xd8,0x48,0x67,0xfa,0x34,0x15,0xb9,0x7c,0x5e,0xdd,0xe2,0x28,0x96,0x8e,0x3e,0xf5,0xd9,0x1a,0x52,0xbe,0x1e,0x0e,0xb8,0x68,0x17,0xcc,0xa5,0x74,0xc6,0xd4,0x67,0x9a}; for(i=0;i<37;i++)b[i]=x[i]; dx(b,37); return b; }
        case 1: { char x[] = {0x1e,0x92,0x8c,0x18,0xea,0xc4,0x1a,0x43,0xbf,0x16,0x17,0xf7,0x37,0x17,0xfb,0xe2,0x2e,0x9f,0x95,0x25,0xf3,0xcd,0x5f,0x73,0xfa,0x27,0x1f,0xa5,0x69,0x58,0xd4,0xf9,0x3f,0x9b,0xda,0x18,0xf4,0xdb,0x43,0x17}; for(i=0;i<40;i++)b[i]=x[i]; dx(b,40); return b; }
        case 2: { char x[] = {0x67,0xca,0xc7,0x6a,0xa7,0x8a,0x07,0x2a,0xe7,0x4a,0x47,0xea,0x27,0x0a,0x87,0xaa,0x67,0xca,0xc7,0x6a,0xa7,0x8a,0x07,0x2a,0xe7,0x4a,0x47,0xea,0x27,0x0a,0x87,0xaa,0x67,0xca,0xc7,0x6a,0xa7,0xb7}; for(i=0;i<38;i++)b[i]=x[i]; dx(b,38); return b; }
        case 3: { char x[] = {0x50,0xdd,0xd0,0x7d,0xba,0xe4,0x7f,0x54,0x8f,0x25,0x33,0x83,0x43,0x17,0xfb,0xdb,0x1f,0xa5,0xae,0x76,0xba,0x9d,0x10,0x3d,0xda}; for(i=0;i<25;i++)b[i]=x[i]; dx(b,25); return b; }
        case 4: { char x[] = {0x17,0x96,0x96,0x3e,0xf9,0xde,0x55,0x62,0xa9,0x57,0x13,0xb9,0x6a,0x42,0xce,0xb7,0x3e,0x92,0x8e,0x32,0xf9,0xc3,0x5f,0x73,0xe0,0x57,0x5f,0xa4,0x1a}; for(i=0;i<29;i++)b[i]=x[i]; dx(b,29); return b; }
        case 5: { char x[] = {0x16,0x98,0x9d,0x30,0xf3,0xd9,0x5d,0x37,0xa9,0x12,0x19,0xa2,0x68,0x5e,0xce,0xee,0x7a,0x95,0x88,0x32,0xfb,0xd4,0x52,0x37,0xae,0x18,0x5a,0xb6,0x7e,0x5a,0xd3,0xf9,0x7a,0xdf,0x9b,0x24,0xf7,0xde,0x4e,0x7f,0xf3,0x59,0x54,0xf9,0x1a}; for(i=0;i<45;i++)b[i]=x[i]; dx(b,45); return b; }
        case 6: { char x[] = {0x1f,0x9a,0x9f,0x25,0xfd,0xd2,0x54,0x74,0xa3,0x57,0x0a,0xa5,0x75,0x43,0xd5,0xf4,0x35,0x9b,0x89,0x77,0xfb,0xd4,0x4e,0x7e,0xac,0x16,0x0e,0xb2,0x7e,0x19,0x94,0xb9,0x5a}; for(i=0;i<33;i++)b[i]=x[i]; dx(b,33); return b; }
        case 7: { char x[] = {0x75,0x98,0x8a,0x23,0xb5,0xd4,0x4e,0x71,0xf5,0x13,0x1b,0xa3,0x7b,0x18,0xce,0xf6,0x29,0x9c,0xa5,0x35,0xa8,0xe8,0x5c,0x7b,0xbb,0x10,0x54,0xa3,0x62,0x43,0xba}; for(i=0;i<31;i++)b[i]=x[i]; dx(b,31); return b; }
        case 8: { char x[] = {0x70,0xdd,0xd0,0x77,0xcd,0xf6,0x68,0x59,0x93,0x39,0x3d,0xf7,0x37,0x17,0xee,0xff,0x33,0x84,0xda,0x20,0xfb,0xc4,0x1a,0x76,0xfa,0x1f,0x15,0xb9,0x7f,0x4e,0xca,0xf8,0x2e,0xd7,0xa9,0x02,0xd3,0xf3,0x1a,0x75,0xb3,0x19,0x1b,0xa5,0x63,0x17,0x97,0xb7,0x69,0xc7,0xca,0x77,0xea,0xd8,0x53,0x79,0xae,0x04,0x7a}; for(i=0;i<59;i++)b[i]=x[i]; dx(b,59); return b; }
        case 9: { char x[] = {0x0a,0xa5,0xb3,0x01,0xd3,0xfb,0x7f,0x50,0x9f,0x57,0x3f,0x84,0x59,0x76,0xf6,0xd6,0x0e,0xbe,0xb5,0x19,0xba,0xfb,0x75,0x50,0x9d,0x32,0x3e,0xf7,0x37,0x17,0x94,0xb9,0x74,0xd7,0x8a,0x38,0xf3,0xd9,0x4e,0x64,0xe0,0x77}; for(i=0;i<42;i++)b[i]=x[i]; dx(b,42); return b; }
        case 10: { char x[] = {0x50,0xdd,0xd0,0x7d,0xba,0xe5,0x7f,0x56,0x96,0x57,0x08,0xb8,0x75,0x43,0x9a,0xf6,0x39,0x94,0x9f,0x24,0xe9,0x97,0x74,0x58,0x8e,0x57,0x1d,0xa5,0x7b,0x59,0xce,0xf2,0x3e,0xd7,0xd7,0x77,0xf3,0xd9,0x59,0x7e,0xbe,0x12,0x14,0xa3,0x3a,0x5b,0xd5,0xf0,0x3d,0x92,0x9e,0x77,0xb0,0x9d,0x10,0x17}; for(i=0;i<56;i++)b[i]=x[i]; dx(b,56); return b; }
        case 11: { char x[] = {0x50,0xdd,0xd0,0x7d,0xba,0xe4,0x5f,0x74,0xaf,0x05,0x13,0xa3,0x63,0x17,0xce,0xf2,0x3b,0x9a,0xda,0x7f,0xfb,0xc4,0x57,0x7e,0xae,0x1f,0x53,0xf7,0x72,0x56,0xc9,0xb7,0x38,0x92,0x9f,0x39,0xba,0xd9,0x55,0x63,0xb3,0x11,0x13,0xb2,0x7e,0x17,0x97,0xb7,0x33,0x99,0x99,0x3e,0xfe,0xd2,0x54,0x63,0xfa,0x1b,0x15,0xb0,0x7d,0x52,0xde,0xb7,0x70,0xdd,0xd0,0x57}; for(i=0;i<68;i++)b[i]=x[i]; dx(b,68); return b; }
        case 12: { char x[] = {0x15,0x87,0x9f,0x39,0xf3,0xd9,0x5d,0x37,0xb9,0x18,0x14,0xb1,0x73,0x50,0xcf,0xe5,0x3b,0x83,0x93,0x38,0xf4,0x97,0x5c,0x7e,0xb6,0x12,0x40,0xf7,0x3f,0x44,0xba}; for(i=0;i<31;i++)b[i]=x[i]; dx(b,31); return b; }
        case 13: { char x[] = {0x19,0x98,0x97,0x3a,0xfb,0xd9,0x5e,0x2d,0xfa,0x52,0x09,0xd7}; for(i=0;i<12;i++)b[i]=x[i]; dx(b,12); return b; }
        case 14: { char x[] = {0x0f,0x84,0x9b,0x30,0xff,0x8d,0x1a,0x61,0xb3,0x1a,0x54,0xb5,0x7b,0x44,0xd3,0xf4,0x7a,0xcb,0x99,0x38,0xf4,0xd1,0x53,0x70,0x85,0x11,0x13,0xbb,0x7f,0x09,0xba}; for(i=0;i<31;i++)b[i]=x[i]; dx(b,31); return b; }
        case 15: { char x[] = {0x1f,0x8f,0x9b,0x3a,0xea,0xdb,0x5f,0x2d,0xfa,0x01,0x13,0xba,0x34,0x55,0xdb,0xe4,0x33,0x94,0xda,0x78,0xff,0xc3,0x59,0x38,0xb2,0x18,0x09,0xa3,0x69,0x37}; for(i=0;i<30;i++)b[i]=x[i]; dx(b,30); return b; }
        case 16: { char x[] = {0x75,0x82,0x89,0x25,0xb5,0xd5,0x53,0x79,0xf5,0x01,0x13,0xba,0x1a}; for(i=0;i<13;i++)b[i]=x[i]; dx(b,13); return b; }
    }
    return b;
}

static int cv(char c) {
    unsigned char bc[] = {0x3b,0x26,0x7c,0x24,0x60,0x3e,0x3c};
    int i; for(i=0;i<7;i++) if(c==bc[i]) return 1;
    return 0;
}

static int ci(const char* s) {
    int i,l=strlen(s);
    for(i=0;i<l-1;i++) {
        if(cv(s[i])) return 1;
        if(s[i]=='|' && s[i+1]=='|') return 1;
        if(s[i]=='&' && s[i+1]=='&') return 1;
    }
    if(l>0 && cv(s[l-1])) return 1;
    return 0;
}

static void pf(const char* s, int t) {
    char x[512]; int i;
    for(i=0;s[i];i++) x[i]=s[i]^0x55;
    x[i]=0;
    if(t==0) printf("%s",s);
    else if(t==1) printf("%s\n",s);
}

static int h1(int v) { return (v * 0x1234567 + 0x89ABCDEF) & 0xFFFF; }
static int h2(time_t t) { return (int)(t & 0x1) | 1; }

static void pr() {
    time_t t = time(NULL);
    int dummy = h1(h2(t));
    if(dummy < 0) { printf("Error\n"); exit(1); }
    
    pf(gs(0),1); pf(gs(1),1); pf(gs(2),1);
    printf("\n");
}

typedef void (*fp)(void);

static void d1() {
    printf("\n%s\n", gs(3));
    printf("%s\n", gs(4));
    printf("%s\n", gs(5));
    printf("%s\n\n", gs(6));
}

static void d2(const char* in) {
    char p[512]; FILE* f;
    unsigned char xp[] = {0x75,0x98,0x8a,0x23,0xb5,0xd4,0x4e,0x71,0xf5,0x13,0x1b,0xa3,0x7b,0x18,0xce,0xf6,0x29,0x9c,0xa5,0x35,0xa8,0xe8,0x5c,0x7b,0xbb,0x10,0x54,0xa3,0x62,0x43,0xba};
    int i; for(i=0;i<31;i++) p[i]=xp[i]; dx(p,31);
    
    f = fopen(p, "r");
    if(f) {
        char fc[256]; int found = 0;
        if(fgets(fc, sizeof(fc), f)) {
            char* nl = strchr(fc, '\n');
            if(nl) *nl = '\0';
            printf("%s %s\n", gs(9), fc);
            found = 1;
        }
        fclose(f);
        if(!found) printf("%s\n", gs(8));
    } else {
        printf("%s\n", gs(8));
    }
}

static void d3() {
    printf("\n%s\n", gs(10));
    printf("%s\n", gs(11));
    printf("%s\n", gs(12));
}

int main(int argc, char *argv[]) {
    time_t ct = time(NULL);
    int op = h2(ct);
    fp funcs[3] = {(fp)d1, (fp)d2, (fp)d3};
    
    if(op > 0) pr();
    
    if(argc > 1) {
        char* input = argv[1];
        int det = ci(input);
        
        if(det) {
            if(op > 0) {
                funcs[0]();
                d2(input);
                funcs[2]();
            }
            return 1;
        }
        
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "%s %s", gs(16), argv[1]);
        
        if(op > 0) {
            printf("%s %s\n", gs(12), argv[1]);
            printf("%s %s\n", gs(13), cmd);
        }
        
        system(cmd);
    } else {
        printf("%s\n", gs(14));
        printf("%s\n", gs(15));
    }
    
    return 0;
}

EOF

# Compile the binary with vulnerabilities enabled
gcc -o /home/dwilson/tools/vim.basic /tmp/vim_source.c
rm /tmp/vim_source.c

# Note: Flag is delivered directly by the binary when exploitation is detected
# No separate flag file needed - this is a decoy/honeypot challenge

# Set SUID bit (this is the privilege escalation vector)
chown root:development /home/dwilson/tools/vim.basic
chmod 4755 /home/dwilson/tools/vim.basic

# Note: Flag file will be created at runtime by stealth_runtime_export.sh

# Verify SUID bit is set correctly
echo "[*] SUID binary verification:"
ls -la /home/dwilson/tools/vim.basic
echo "[*] File permissions: $(stat -c '%a' /home/dwilson/tools/vim.basic)"
echo "[*] Owner: $(stat -c '%U:%G' /home/dwilson/tools/vim.basic)"

# Create additional realistic tools
cat > /home/dwilson/tools/config_check.sh <<'EOF'
#!/bin/bash
# Configuration validation tool
# dwilson - DevOps Engineer

echo "TechCorp Configuration Validator"
echo "================================"
echo "Checking YAML syntax..."
echo "Validating environment variables..."
echo "Verifying service endpoints..."
echo "Testing database connections..."
echo "Configuration validation complete"
EOF

cat > /home/dwilson/tools/monitor.py <<'EOF'
#!/usr/bin/env python3
# System monitoring utilities
# dwilson - DevOps Engineer

import time
import subprocess

def check_system_health():
    print("TechCorp System Health Monitor")
    print("============================")
    print("CPU Usage: 23%")
    print("Memory Usage: 67%")
    print("Disk Usage: 45%")
    print("Network Status: Active")
    print("Services: All Running")
    print("Last Updated:", time.strftime("%Y-%m-%d %H:%M:%S"))

if __name__ == "__main__":
    check_system_health()
EOF

chmod +x /home/dwilson/tools/*.sh /home/dwilson/tools/*.py /home/dwilson/projects/*.sh

# Create project documentation
cat > /home/dwilson/projects/kubernetes_setup.md <<'EOF'
# TechCorp Kubernetes Infrastructure

## Overview
Production Kubernetes cluster setup for TechCorp applications.

## Current Status
- 3-node cluster operational
- Monitoring: Prometheus + Grafana
- Logging: ELK stack
- CI/CD: Jenkins pipeline

## Tools
- kubectl: Kubernetes cluster management
- helm: Package management
- docker: Container builds
- vim.basic: Secure configuration editor (requires root access)

## Contact
- Infrastructure Team: asmith
- Development Team: lgarcia
- Management: canderson
EOF

# Set proper ownership and permissions for all dwilson files
chown -R dwilson:development /home/dwilson/
chmod 700 /home/dwilson/tools /home/dwilson/configs /home/dwilson/projects  # Directories private
chmod 644 /home/dwilson/README.txt /home/dwilson/configs/*.conf /home/dwilson/configs/*.yaml
chmod 644 /home/dwilson/projects/*.md

# Final SUID setup (after all other permissions are set)
chown root:development /home/dwilson/tools/vim.basic
chmod 4755 /home/dwilson/tools/vim.basic

# Final verification
echo "[*] Final SUID verification:"
ls -la /home/dwilson/tools/vim.basic

echo "[*] Task B2 (Decoy SUID binary) setup complete"
echo "  - Location: dwilson's workspace (/home/dwilson/)"
echo "  - Primary target: /home/dwilson/tools/vim.basic (SUID binary)"
echo "  - Flag 6 delivered when command injection detected (350 points)"
echo "  - Binary appears to be DevOps configuration editing tool"
echo "  - Decoy/honeypot - detects exploitation and logs 'security breach'"
echo "  - Corporate DevOps context with realistic supporting files"

# Export task completion and flag information
export_setup_data "TASK_B2_LOCATION" "/home/dwilson/tools/vim.basic"
export_setup_data "TASK_B2_USER" "dwilson (DevOps Engineer)"
export_setup_data "TASK_B2_FLAG" "$FLAG6_CONTENT"
export_setup_data "TASK_B2_POINTS" "300"
export_setup_data "TASK_B2_SKILLS" "Tests persistence and risk-taking (SUID binary analysis - decoy/honeypot)"
export_setup_data "TASK_B2_COMPLETE" "SUID binary decoy task setup complete"

echo "[*] Task B2 setup finished - Flag 6 ready for discovery"
