# Base image
FROM debian:bullseye-slim

# Configure apt to handle signature issues in Docker
RUN echo 'Acquire::AllowInsecureRepositories "true";' > /etc/apt/apt.conf.d/99allow-insecure && \
    echo 'APT::Get::AllowUnauthenticated "true";' >> /etc/apt/apt.conf.d/99allow-insecure

# Install core system tools
RUN apt-get update && apt-get install -y \
    openssh-server \
    gosu \
    sudo \
    less \
    vim \
    curl \
    cron \
    python3 \
    python3-pip \
    sqlite3 \
    gdb \
    checksec \
    supervisor \
    net-tools \
    binutils \
    wget \
    rsyslog \
    inotify-tools \
    strace \
    && pip3 install flask  \
    && rm -rf /var/lib/apt/lists/*

# Install CTF security tools
RUN for i in 1 2 3; do \
      apt-get update && \
      apt-get install -y --allow-unauthenticated \
        hashcat \
        fcrackzip \
        zip \
        unzip \
        p7zip-full \
        hashid \
        hydra \
        medusa \
        ncrack \
        ophcrack \
        aircrack-ng \
        pdfcrack \
        rarcrack \
        nmap \
        sqlmap \
        default-mysql-client \
        xxd \
        build-essential \
        libssl-dev \
        zlib1g-dev \
      && break; \
      echo "apt-get install failed, retrying..."; \
      sleep 5; \
    done && \
    rm -rf /var/lib/apt/lists/*

# Install password cracking tools - keep it simple
RUN apt-get update && \
    # Install basic john (for general password cracking)
    apt-get install -y --allow-unauthenticated john john-data && \
    # Link john binary
    ln -sf /usr/sbin/john /usr/local/bin/john && \
    rm -rf /var/lib/apt/lists/*

# Install additional terminal-based CTF tools
RUN apt-get update && apt-get install -y --allow-unauthenticated \
    # Web application testing
    dirb \
    # Network tools
    netcat-traditional \
    socat \
    tcpdump \
    dnsutils \
    whois \
    # SMB/Windows enumeration
    smbclient \
    smbmap \
    # Binary analysis (complement to existing gdb)
    ltrace \
    file \
    # Misc utilities
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install tools from Python/pip that aren't in Debian repos
RUN pip3 install --no-cache-dir wfuzz

# Install Python-based CTF tools
RUN pip3 install --no-cache-dir \
    pwntools \
    requests \
    beautifulsoup4 \
    impacket

# Download privilege escalation enumeration scripts
RUN mkdir -p /opt/privesc-tools && \
    wget -q https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O /opt/privesc-tools/linpeas.sh && \
    wget -q https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O /opt/privesc-tools/linenum.sh && \
    chmod +x /opt/privesc-tools/*.sh

# Download additional enumeration tools not in Debian repos
RUN mkdir -p /opt/enum-tools && \
    wget -q https://raw.githubusercontent.com/CiscoCXSecurity/enum4linux/master/enum4linux.pl -O /opt/enum-tools/enum4linux && \
    chmod +x /opt/enum-tools/enum4linux && \
    ln -s /opt/enum-tools/enum4linux /usr/local/bin/enum4linux

# Create wordlists directory and download password cracking resources
RUN mkdir -p /usr/share/wordlists /usr/share/hashcat/rules && \
    # Download rockyou.txt (primary wordlist)
    wget -q https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O /usr/share/wordlists/rockyou.txt && \
    # Create additional wordlists
    echo -e "password\n123456\nadmin\nroot\nuser\ntest\npassword123\nqwerty\nletmein\nwelcome\n" > /usr/share/wordlists/common-passwords.txt && \
    echo -e "admin\nroot\nuser\ntest\nguest\nadministrator\noperator\nservice\n" > /usr/share/wordlists/common-users.txt && \
    # Download hashcat rules
    wget -q https://raw.githubusercontent.com/hashcat/hashcat/master/rules/best64.rule -O /usr/share/hashcat/rules/best64.rule 2>/dev/null || echo "# Basic rules" > /usr/share/hashcat/rules/best64.rule && \
    # Create hash example files for practice
    mkdir -p /usr/share/hashes && \
    echo "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8" > /usr/share/hashes/sha256-password.txt && \
    echo "e99a18c428cb38d5f260853678922e03" > /usr/share/hashes/md5-password.txt && \
    echo "\$2b\$12\$K0zyHmhFihq0dv4Z8GfhmuP2MhIUgOBFGOQ1vJHG9Ur6FWaRe5m5m" > /usr/share/hashes/bcrypt-password.txt

# Permit ptrace so gdb can attach to SUID binaries
RUN echo "kernel.yama.ptrace_scope = 0" > /etc/sysctl.d/10-ctf-ptrace.conf

# Setup SSH and runtime
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'DenyUsers root' >> /etc/ssh/sshd_config

# Create helpful aliases for CTF tools
RUN echo 'alias ll="ls -la"' >> /etc/bash.bashrc && \
    echo 'alias linpeas="/opt/privesc-tools/linpeas.sh"' >> /etc/bash.bashrc && \
    echo 'alias linenum="/opt/privesc-tools/linenum.sh"' >> /etc/bash.bashrc && \
    echo 'alias nc="netcat"' >> /etc/bash.bashrc && \
    echo 'export PATH="/opt/enum-tools:$PATH"' >> /etc/bash.bashrc

# Configure rsyslog for external logging plus durable session files
RUN mkdir -p /var/log/sessions && \
    echo '$ModLoad imuxsock' > /etc/rsyslog.d/50-ctf-logging.conf && \
    echo '$ModLoad imklog' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo '$FileOwner root' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo '$FileGroup root' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo '$FileCreateMode 0600' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo '$DirCreateMode 0700' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local0.* /var/log/sessions/activity.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local1.* /var/log/sessions/history.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local2.* /var/log/sessions/file-access.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local3.* /var/log/sessions/setup.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local4.* /var/log/sessions/file-content.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local5.* /var/log/sessions/process.log' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local0.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local1.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local2.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local3.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local4.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf && \
    echo 'local5.* /proc/1/fd/1' >> /etc/rsyslog.d/50-ctf-logging.conf

# === Root password will be set by task_global.sh ===
# Password will be generated and stored in /opt/ctf/data/dev_passwords.txt

# Copy all setup scripts
COPY tasks/ /opt/ctf/
RUN chmod -R 700 /opt/ctf && \
    chown -R root:root /opt/ctf

# Run the CTF environment setup
# Force rebuild with updated export functions
RUN /opt/ctf/setup.sh

# Expose SSH
EXPOSE 22 8000

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Add logging labels for Docker
LABEL logging="ctf-session"
LABEL log_type="comprehensive"

# Change entrypoint
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
