# SnEnum - Advanced Linux Enumeration & Privilege Escalation Tool

## 📋 Overview

**SnEnum v1.0.0** is a comprehensive Linux enumeration script designed for security assessments, penetration testing, and privilege escalation discovery. Built from the ground up with modern security features, SnEnum automates the discovery of sensitive information, misconfigurations, and potential attack vectors on Linux systems.

## 🎯 Key Features

### Core Enumeration Features
- **System Information** - Kernel version, OS details, architecture, hostname
- **User Enumeration** - Current user, groups, sudo permissions, user accounts
- **Network Configuration** - Interfaces, routing, DNS, active connections
- **Service Discovery** - Running processes, listening ports, installed software
- **File System Analysis** - SUID/SGID files, writable directories, sensitive files
- **Cron Jobs & Scheduled Tasks** - System and user crontabs, systemd timers

### 🔥 Advanced Security Features

#### 1. **Browser Data Extraction**
Extracts sensitive data from installed web browsers:
- **Supported Browsers:** Chrome, Firefox, Edge, Opera, Brave
- **Data Types:** Cookies, login data, history, bookmarks
- **Encryption Keys:** Master keys and encrypted credentials
- **Storage Locations:** User profiles and system-wide installations

#### 2. **Password Hunter**
Deep pattern-based credential discovery:
- Database credentials (MySQL, PostgreSQL, MongoDB, etc.)
- API keys and tokens (AWS, Azure, Google Cloud, GitHub)
- Application passwords (WordPress, Drupal, Laravel)
- Cloud provider credentials
- FTP/SFTP credentials
- Email server passwords
- Private keys and certificates

#### 3. **Database Connection String Finder**
Identifies database credentials across 11+ database types:
- MySQL, PostgreSQL, MongoDB, Redis
- Microsoft SQL Server, Oracle, SQLite
- Elasticsearch, CouchDB, Cassandra
- JDBC connection strings

#### 4. **Communication Platform Token Finder**
Discovers authentication tokens for:
- **Slack:** Bot tokens, user tokens, webhooks, app tokens
- **Discord:** Bot tokens, webhooks
- **Telegram:** Bot tokens
- **Microsoft Teams:** Webhooks
- **Mattermost:** Tokens

#### 5. **HTML Report Generation**
Beautiful, interactive web-based reports:
- Tabbed interface for organized viewing
- Search functionality across all findings
- Color-coded severity levels
- Progress statistics and metrics
- Exportable and shareable format
- **Usage:** `./snenum.sh -H`

#### 6. **Recommendations Engine**
Intelligent exploitation guidance:
- SUID/SGID binary exploitation techniques
- Sudo misconfiguration abuse
- Docker/LXD container escape methods
- Kernel exploit suggestions
- Writable service/timer exploitation
- Database privilege escalation
- NFS share mounting attacks
- Path hijacking opportunities
- Cron job manipulation
- Weak file permission exploitation

#### 7. **Stealth Mode**
Minimizes detection during enumeration:
- RAM-based storage (uses /dev/shm)
- Low I/O priority operations
- Automatic cleanup on exit
- Minimal disk footprint
- **Usage:** `./snenum.sh -S`

#### 8. **Progress Bar**
Real-time scan progress tracking:
- 14-step enumeration process
- Animated progress indicator
- Percentage completion display
- Step-by-step status updates
- **Usage:** `./snenum.sh -p`

#### 9. **Quiet Mode**
Focused output showing only critical findings:
- HIGH-VALUE markers for important discoveries
- Suppressed informational output
- Finding counter for quick assessment
- Ideal for quick scans
- **Usage:** `./snenum.sh -q`

#### 10. **Writable Service Files Detection**
Identifies systemd privilege escalation vectors:
- Writable systemd service files
- Writable service unit directories
- Weak permission detection (world/group writable)
- Writable timer files and socket files
- Drop-in directory vulnerabilities
- Running service configuration analysis
- Systemd configuration file checks

#### 11. **Polkit Vulnerability Checks**
Comprehensive Polkit/pkexec security assessment:
- pkexec SUID detection
- CVE-2021-4034 (PwnKit) vulnerability testing
- CVE-2021-3560 vulnerability checking
- Writable polkit configuration files
- Writable polkit rules directories
- Password-less authentication detection
- Polkit version analysis
- Helper binary permission checks

#### 12. **Systemd Timer Abuse Detection**
Enhanced timer-based privilege escalation:
- Writable timer file detection
- Active/enabled timer enumeration
- Timer-associated service analysis
- Timer schedule configuration display
- Weak permission detection
- Drop-in directory checks
- Non-root owned timer identification

#### 13. **Internal Port Scanner**
Quick localhost port scanning:
- Scans 27 common service ports
- Service identification (SSH, HTTP, MySQL, PostgreSQL, Redis, MongoDB, etc.)
- Fast connection-based detection
- No external tools required

#### 14. **Active Connections Analysis**
Network connection monitoring:
- Established connections with process names
- Remote IP enumeration
- Connection statistics
- Process-to-connection mapping

#### 15. **Firewall Rules Display**
Comprehensive firewall enumeration:
- iptables/ip6tables rules (including NAT)
- nftables ruleset
- UFW status and configuration
- firewalld zones and rules
- Inactive/missing firewall detection
- Permissive rule identification

#### 16. **Network Share Enumeration**
Enhanced NFS/SMB/CIFS discovery:
- NFS exports with insecure option detection
- Mounted NFS/SMB shares
- Samba configuration analysis
- Guest access detection
- SMB credential file discovery
- AutoFS configuration
- Credentials in fstab detection

## 📖 Usage

### Basic Usage
```bash
./snenum.sh
```

### Command-Line Options

| Flag | Description |
|------|-------------|
| `-k` | Keyword search mode - search for specific strings in files |
| `-e` | Export mode - save findings to organized directory structure |
| `-s` | Thorough scan - includes additional time-consuming checks |
| `-t` | Include thorough tests (file system enumeration) |
| `-r [report]` | Generate report in specific directory |
| `-H` | Generate interactive HTML report |
| `-S` | Stealth mode - use RAM storage and low I/O priority |
| `-p` | Show progress bar during enumeration |
| `-q` | Quiet mode - only show high-value findings |
| `-h` | Display help message |

### Usage Examples

#### Standard Enumeration
```bash
./snenum.sh
```

#### Generate HTML Report
```bash
./snenum.sh -H
# Opens snenum-report.html in browser
```

#### Export All Findings
```bash
./snenum.sh -e -r /tmp/audit
# Saves findings to /tmp/audit/snenum-export-YYYY-MM-DD/
```

#### Stealth Mode with Quiet Output
```bash
./snenum.sh -S -q
# Minimal detection, shows only HIGH-VALUE findings
```

#### Thorough Scan with Progress Bar
```bash
./snenum.sh -s -t -p
# Complete enumeration with visual progress
```

#### Keyword Search
```bash
./snenum.sh -k password
# Searches for "password" in configuration files
```

#### Complete Assessment
```bash
./snenum.sh -s -t -e -H -p -r /tmp/results
# Full scan with HTML report, export, and progress tracking
```

## 🎯 High-Value Findings

SnEnum automatically identifies and marks critical security issues:

### Privilege Escalation Vectors
- ✅ SUID/SGID binaries (especially with GTFOBins exploits)
- ✅ Sudo misconfigurations (NOPASSWD entries)
- ✅ Writable systemd service/timer files
- ✅ Polkit vulnerabilities (CVE-2021-4034, CVE-2021-3560)
- ✅ Docker socket access
- ✅ Writable cron jobs
- ✅ Weak PATH configurations

### Credential Discovery
- ✅ Browser stored passwords and cookies
- ✅ Database connection strings with passwords
- ✅ API keys and tokens (AWS, Azure, GitHub, etc.)
- ✅ Slack/Discord/Teams authentication tokens
- ✅ SSH private keys with weak permissions
- ✅ SMB/NFS credential files
- ✅ Application configuration passwords

### Network Exploitation
- ✅ Inactive/missing firewall
- ✅ Insecure NFS exports (no_root_squash)
- ✅ Samba guest access enabled
- ✅ Open internal services (databases, Redis, etc.)
- ✅ SMB credentials in fstab

### System Misconfigurations
- ✅ World-writable files and directories
- ✅ Weak file permissions on sensitive files
- ✅ Running services with root privileges
- ✅ Outdated kernel versions
- ✅ Writable systemd configurations

## 📂 Export Structure

When using `-e` flag, SnEnum creates organized directories:

```
snenum-export-YYYY-MM-DD/
├── browsers/              # Browser data extracts
├── writable-services/     # Writable systemd files
├── polkit-configs/        # Polkit configuration files
├── systemd-timers/        # Timer unit files
├── network-shares/        # NFS/SMB configurations
├── ps-export/             # Process binaries
└── [additional files]     # Other exported data
```

## 🔍 What SnEnum Checks

### System Information
- Operating system and kernel version
- System architecture and hostname
- Environment variables
- Installed packages (dpkg, rpm, snap)
- Available compilers and development tools

### User & Group Enumeration
- Current user and group memberships
- Sudo permissions and sudoers file
- All user accounts and home directories
- Password policies and shadow file access
- Recently logged-in users
- SSH key discovery

### Network Analysis
- Network interfaces and IP addresses
- Routing table and DNS configuration
- ARP cache
- Listening TCP/UDP ports
- Active established connections
- Internal port scanning (27 common ports)
- Firewall rules (iptables, nftables, UFW, firewalld)

### Service & Process Discovery
- Running processes with full command lines
- Process binary permissions
- Services from inetd/xinetd
- Systemd units and timers
- Init scripts
- Software versions (MySQL, PostgreSQL, Apache, nginx, etc.)

### File System Security
- SUID/SGID files
- World-writable files and directories
- Writable /etc files
- Home directory permissions
- Sensitive configuration files
- Log file access
- Recently modified files
- Writable systemd service files
- Writable timer files

### Scheduled Tasks
- System and user crontabs
- Cron job permissions
- Systemd timer units
- Anacron jobs
- At jobs

### Credential Hunting
- Browser cookies and passwords (5 browsers)
- Database connection strings (11+ DB types)
- API keys and cloud credentials
- Communication platform tokens
- SSH private keys
- Configuration file passwords
- Environment variable credentials

### Container & Virtualization
- Docker socket and group membership
- LXD/LXC access
- Container detection
- VM detection

### Privilege Escalation Checks
- Sudo version and configuration
- Polkit/pkexec vulnerabilities
- Kernel exploit suggestions
- Writable service files
- Docker escape opportunities
- NFS no_root_squash
- Path hijacking possibilities

## ⚠️ Important Notes

### Legal & Ethical Use
- **Authorization Required:** Only use SnEnum on systems you own or have explicit permission to test
- **Security Assessments:** Ideal for penetration testing, security audits, and CTF challenges
- **Educational Purpose:** Designed for learning Linux security and enumeration techniques
- **Compliance:** Ensure usage complies with local laws and organizational policies

### Operational Considerations
- **System Impact:** Thorough mode (`-s -t`) can be resource-intensive
- **Detection:** Standard mode may be logged by security tools; use `-S` for stealth
- **Permissions:** Some checks require elevated privileges for complete results
- **Export Size:** `-e` flag can create large export directories with file copies
- **Runtime:** Full enumeration can take 5-15 minutes depending on system size

### Best Practices
1. **Start Simple:** Run basic scan first: `./snenum.sh`
2. **Review Output:** Check for HIGH-VALUE markers in quiet mode: `./snenum.sh -q`
3. **Generate Reports:** Use HTML reports for better analysis: `./snenum.sh -H`
4. **Stealth Operations:** Use RAM storage for minimal footprint: `./snenum.sh -S`
5. **Export Findings:** Save results for offline analysis: `./snenum.sh -e`
6. **Follow Recommendations:** Use the recommendations engine for exploitation guidance

### Technical Requirements
- **Shell:** Bash (tested on version 4.0+)
- **Privileges:** Works with any user; more findings with root/sudo
- **Dependencies:** Uses standard Linux utilities (most are pre-installed)
  - Core: `find`, `grep`, `ps`, `netstat`/`ss`, `systemctl`
  - Optional: `iptables`, `nft`, `showmount`, `smbclient`
- **Storage:** 
  - Standard mode: Minimal (output only)
  - Export mode: 10MB-500MB depending on system
  - Stealth mode: Uses /dev/shm (RAM)

## 🚀 Advanced Tips

### Finding Quick Wins
```bash
# Focus on privilege escalation vectors only
./snenum.sh -q | grep "HIGH-VALUE"
```

### Comprehensive Assessment
```bash
# Full scan with all features
./snenum.sh -s -t -e -H -p -r /tmp/audit
```

### Stealth Reconnaissance
```bash
# Minimal detection, RAM-based storage
./snenum.sh -S -q -r /dev/shm/tmp
```

### Searching for Specific Credentials
```bash
# Look for database passwords
./snenum.sh -k "password\|passwd\|pwd" | grep -i "mysql\|postgres"
```

### Analyzing HTML Report
```bash
# Generate and open in browser
./snenum.sh -H
firefox snenum-report.html
```

## 📊 Output Interpretation

### Color Coding
- **🔴 Red (`[-]`)** - Information headers and scan status
- **🟡 Yellow (`[+]`)** - Findings and discovered items
- **🟢 Green** - Normal/expected conditions
- **🔵 Blue (`[!]`)** - Recommendations and exploitation tips
- **🟡 HIGH-VALUE** - Critical security findings

### Priority Levels
1. **HIGH-VALUE** - Immediate privilege escalation opportunities
2. **Yellow [+]** - Interesting findings requiring investigation
3. **Red [-]** - Standard enumeration results
4. **Recommendations** - Suggested exploitation techniques

## 🛡️ Defensive Recommendations

If SnEnum finds vulnerabilities on your system, consider:

1. **SUID/SGID Files:** Review and remove unnecessary SUID bits
2. **Sudo Permissions:** Restrict NOPASSWD entries, use sudoers policies
3. **Systemd Services:** Protect service files with proper permissions (644 root:root)
4. **Polkit:** Update to patched versions, review polkit rules
5. **Credentials:** Remove hardcoded passwords, use secret management tools
6. **Firewall:** Enable and properly configure firewall rules
7. **NFS/SMB:** Remove no_root_squash, disable guest access, use authentication
8. **Docker:** Restrict docker group membership, use user namespaces
9. **File Permissions:** Fix world-writable files, protect sensitive configurations
10. **Cron Jobs:** Secure cron files, validate cron job scripts

## 📝 Version History

### v1.0.0 (Current)
- Complete rebranding from LinEnum to SnEnum
- Added 16 advanced security features
- HTML report generation with interactive UI
- Stealth mode with RAM-based storage
- Progress bar and quiet mode
- Comprehensive privilege escalation checks
- Browser data extraction (5 browsers)
- Password hunter with pattern matching
- Database connection string finder (11+ DBs)
- Communication platform token finder
- Recommendations engine with exploitation tips
- Polkit vulnerability checks (CVE-2021-4034, CVE-2021-3560)
- Enhanced systemd timer abuse detection
- Internal port scanner (27 common ports)
- Active connections analysis with process mapping
- Firewall rules display (iptables, nftables, UFW, firewalld)
- Network share enumeration (NFS/SMB/CIFS)

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Additional credential patterns
- More privilege escalation checks
- Container/cloud platform enumeration
- Additional export formats (JSON, XML)
- Plugin/module system

## 📄 License

SnEnum is provided for educational and authorized security testing purposes only.

## ⚡ Quick Reference Card

```bash
# Basic Commands
./snenum.sh                    # Standard enumeration
./snenum.sh -q                 # Quick high-value findings only
./snenum.sh -H                 # Generate HTML report
./snenum.sh -S                 # Stealth mode (RAM-based)
./snenum.sh -p                 # Show progress bar
./snenum.sh -e                 # Export findings to directory

# Combined Usage
./snenum.sh -s -t -H -p        # Thorough scan with HTML & progress
./snenum.sh -S -q -e           # Stealth mode with quiet output & export
./snenum.sh -k password -e     # Keyword search with export
./snenum.sh -s -t -e -H -p -r /tmp/results  # Full assessment

# Flags Summary
-k [keyword]   Search for keyword in files
-e             Export findings to directory
-s             Thorough scan (slower but comprehensive)
-t             Include thorough tests
-r [path]      Report directory location
-H             HTML report generation
-S             Stealth mode (RAM storage, low I/O)
-p             Progress bar display
-q             Quiet mode (HIGH-VALUE only)
-h             Help message
```

## 🎓 Learning Resources

To learn more about the techniques used by SnEnum:
- **GTFOBins:** https://gtfobins.github.io/ - SUID/sudo exploitation
- **PEASS-ng:** Linux privilege escalation tools and techniques
- **HackTricks:** https://book.hacktricks.xyz/ - Comprehensive pentesting guide
- **PayloadsAllTheThings:** Privilege escalation cheatsheets

---

**SnEnum v1.0.0** - Advanced Linux Enumeration & Privilege Escalation Tool
