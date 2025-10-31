# Renstar-SysAdmin

**Version: 2.1c**

## System Administration Tools for Renstar Global *nix Systems

A modular, configuration-driven system administration toolkit for Ubuntu systems. Designed to make system setup, maintenance, and monitoring consistent across your datacenter infrastructure.

## Features

- **Modular Architecture**: Clean separation of concerns with pluggable modules
- **Profile-Based Configuration**: Different profiles for workstations, servers, and container hosts
- **Comprehensive Package Management**: Installs monitoring, security, networking, and productivity tools
- **Automated Maintenance**: System updates, cleanup, and health checks
- **Health Monitoring**: Daily/weekly system health reports with email notifications
- **Security-Focused**: Includes fail2ban, UFW, unattended-upgrades, and more (manual configuration required)

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/emilgh/renstar-sysadmin.git
cd renstar-sysadmin

# Run with default configuration
./install.sh

# Or use a specific profile
./install.sh --profile server

# Preview what will be installed (dry-run)
./install.sh --dry-run
```

### Maintenance

```bash
# Run system maintenance
./maintenance.sh

# Run maintenance with specific profile
./maintenance.sh --profile server

# Automated (for cron)
./maintenance.sh -y
```

### Health Monitoring

```bash
# Check system health
./system-monitor.sh

# Verbose output
./system-monitor.sh --verbose

# Email report
./system-monitor.sh --email admin@example.com
```

## Scripts

### Main Scripts

- **install.sh**: Install packages and configure system based on profile
- **maintenance.sh**: Run system updates and maintenance tasks
- **system-monitor.sh**: Generate comprehensive system health reports

### Legacy Scripts (Deprecated)

- **host-setup.sh**: Original monolithic installer (use `install.sh` instead)
- **host-update.sh**: Original update script (use `maintenance.sh` instead)

## Configuration

### Profiles

Profiles define different configurations for different use cases:

- **minimal** (`-p minimal`): Basic utilities only, minimal footprint
- **server** (`-p server`): Production server with monitoring and security tools
- **docker-host** (`-p docker-host`): Optimized for container workloads

### Custom Configuration

Create your own configuration:

```bash
# Copy default config
cp config/default.conf config/custom.conf

# Edit settings
nano config/custom.conf

# Use custom config
./install.sh --config config/custom.conf
```

### Key Configuration Options

Edit `config/default.conf` or create a profile:

```bash
# Package categories
ENABLE_CORE_PACKAGES=true
ENABLE_MONITORING=true
ENABLE_SECURITY=true
ENABLE_CONTAINERS=false

# Maintenance settings
MAINTENANCE_APT_UPDATE=true
MAINTENANCE_KERNEL_CLEANUP=true
LOG_RETENTION_DAYS=30

# Security (requires manual setup after install)
UFW_ENABLE=false           # Set to true after manual configuration
FAIL2BAN_ENABLE=false      # Set to true after manual configuration
```

## Architecture

```
renstar-sysadmin/
├── install.sh              # Main installer
├── maintenance.sh          # Maintenance runner
├── system-monitor.sh       # Health monitoring
├── config/                 # Configuration files
│   ├── default.conf        # Default settings
│   └── profiles/           # Pre-configured profiles
├── lib/                    # Shared libraries
│   ├── common.sh           # Common functions
│   └── logging.sh          # Logging utilities
├── modules/                # Modular components
│   ├── packages/           # Package installation
│   ├── maintenance/        # Maintenance tasks
│   └── config/             # Configuration tasks
├── dotfiles/               # User configuration files
│   └── bash/               # Bash configs
└── docs/                   # Documentation
```

---

## Post-Installation Next Steps

After running `install.sh`, your system has various tools installed but **many security and monitoring services require manual configuration and enabling**. Follow these steps to properly secure and configure your system.

### 🔒 Security Configuration (CRITICAL - Do These First)

#### 1. Enable and Configure fail2ban

```bash
# Check if fail2ban is installed
dpkg -l | grep fail2ban

# Enable and start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verify it's running
sudo systemctl status fail2ban
sudo fail2ban-client status

# Check SSH jail status
sudo fail2ban-client status sshd
```

**Configuration:**
Edit `/etc/fail2ban/jail.local` to customize ban times and thresholds:

```bash
sudo nano /etc/fail2ban/jail.local
```

Add:
```ini
[DEFAULT]
bantime = 3600
maxretry = 3
findtime = 600

[sshd]
enabled = true
```

Then restart: `sudo systemctl restart fail2ban`

#### 2. Enable and Configure UFW Firewall

```bash
# Check current status
sudo ufw status verbose

# Set defaults (deny incoming, allow outgoing)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (CRITICAL - do this before enabling!)
sudo ufw allow 22/tcp

# Allow other services as needed:
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 32400/tcp   # Plex (if applicable)
sudo ufw allow 53/tcp      # DNS - Pi-hole (if applicable)
sudo ufw allow 53/udp      # DNS - Pi-hole (if applicable)

# Enable firewall
sudo ufw enable

# Verify
sudo ufw status numbered
```

#### 3. Enable Automatic Security Updates

```bash
# Install unattended-upgrades if not already installed
sudo apt install unattended-upgrades apt-listchanges

# Enable automatic updates
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure (optional)
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Recommended settings:
- Enable automatic security updates: **YES**
- Automatic reboot if required: **Your choice** (servers: usually NO, workstations: YES)
- Reboot time: **03:00** (if enabled)

#### 4. Configure SSH Hardening

```bash
sudo nano /etc/ssh/sshd_config
```

Recommended changes:
```
PermitRootLogin no
PasswordAuthentication no  # Only if you have SSH keys set up!
PubkeyAuthentication yes
Port 22  # Or change to non-standard port
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

**WARNING:** Test these changes before closing your current SSH session!

```bash
# Test SSH config
sudo sshd -t

# Restart SSH
sudo systemctl restart sshd

# Test connection in NEW terminal before closing current session
```

---

### 📊 Monitoring & Health Checks

#### 5. Enable SMART Disk Monitoring

```bash
# Enable smartmontools
sudo systemctl enable smartmontools
sudo systemctl start smartmontools

# Test your disks
sudo smartctl -a /dev/sda  # Replace with your disk

# Check which disks exist
lsblk
```

#### 6. Enable System Statistics Collection (sysstat)

```bash
# Enable sysstat
sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
sudo systemctl enable sysstat
sudo systemctl start sysstat

# Wait 10 minutes, then check:
sar -u  # CPU usage
sar -r  # Memory usage
sar -d  # Disk I/O
```

#### 7. Set Up Log Rotation

```bash
# Verify logrotate is configured
sudo logrotate -d /etc/logrotate.conf

# Configure journal size limits
sudo nano /etc/systemd/journald.conf
```

Recommended:
```ini
SystemMaxUse=500M
MaxRetentionSec=30day
```

Then: `sudo systemctl restart systemd-journald`

---

### 🔍 Initial System Audit

#### 8. Run Security Audit (if lynis installed)

```bash
sudo lynis audit system
```

Review recommendations in: `/var/log/lynis.log`

#### 9. Check for Rootkits (if rkhunter installed)

```bash
# Update database
sudo rkhunter --update

# Run scan
sudo rkhunter --check --skip-keypress
```

#### 10. Initialize AIDE File Integrity (if installed)

```bash
# Initialize database (takes 5-10 minutes)
sudo aideinit

# Move database to correct location
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Set up daily check
sudo nano /etc/cron.daily/aide
```

Add:
```bash
#!/bin/bash
/usr/bin/aide --check | mail -s "AIDE Report for $(hostname)" root
```

Make executable: `sudo chmod +x /etc/cron.daily/aide`

---

### ⚙️ Service-Specific Configuration

#### If Plex is Installed:
- Ensure Plex starts on boot: `sudo systemctl enable plexmediaserver`
- Configure remote access in Plex web UI
- Set up library scanning schedules

#### If Pi-hole is Installed:
- Set admin password: `pihole -a -p`
- Configure upstream DNS servers
- Update gravity: `pihole -g`
- Set up automatic updates

#### If Docker is Installed:
- Enable Docker on boot: `sudo systemctl enable docker`
- Add user to docker group: `sudo usermod -aG docker $USER` (logout/login required)
- Set up log rotation for containers
- Configure Docker daemon: `/etc/docker/daemon.json`

---

### 📧 Set Up Email Notifications (Optional but Recommended)

#### Install and Configure msmtp (lightweight SMTP)

```bash
sudo apt install msmtp msmtp-mta mailutils

# Configure
sudo nano /etc/msmtprc
```

Example (Gmail):
```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-password

account default : gmail
```

Set permissions: `sudo chmod 600 /etc/msmtprc`

Test: `echo "Test email" | mail -s "Test from $(hostname)" your-email@gmail.com`

---

### 🔄 Set Up Automated Maintenance

#### Schedule Weekly Maintenance

```bash
sudo crontab -e
```

Add:
```bash
# Weekly system maintenance (Sundays at 3 AM)
0 3 * * 0 /path/to/renstar-sysadmin/maintenance.sh -y 2>&1 | mail -s "Weekly Maintenance - $(hostname)" admin@example.com

# Daily monitoring report (every day at 8 AM)
0 8 * * * /path/to/renstar-sysadmin/system-monitor.sh --email admin@example.com
```

---

### ✅ Verification Checklist

After completing post-installation, verify:

- [ ] fail2ban is running: `sudo systemctl status fail2ban`
- [ ] UFW is active: `sudo ufw status`
- [ ] SSH is hardened: `sudo sshd -t`
- [ ] Automatic updates enabled: `systemctl status unattended-upgrades`
- [ ] SMART monitoring active: `sudo systemctl status smartmontools`
- [ ] Firewall rules are correct: `sudo ufw status numbered`
- [ ] No failed services: `systemctl --failed`
- [ ] Disk space is adequate: `df -h`
- [ ] Email notifications working: Test email sent successfully
- [ ] Backup system configured (your backup solution)

---

### 📚 Daily/Weekly System Admin Tasks

**Daily:**
- Check `systemctl --failed` for failed services
- Review disk space: `df -h`
- Check authentication logs: `sudo grep "Failed password" /var/log/auth.log | tail -20`
- Run: `./system-monitor.sh`

**Weekly:**
- Run `./maintenance.sh` maintenance script
- Review fail2ban bans: `sudo fail2ban-client status sshd`
- Check disk health: `sudo smartctl -H /dev/sda`
- Review system logs: `sudo journalctl -p err -S "1 week ago"`

**Monthly:**
- Security audit: `sudo lynis audit system`
- Rootkit check: `sudo rkhunter --check`
- Review and archive logs
- Test backup restoration
- Update documentation

---

### 🆘 Troubleshooting

#### SSH Locked Out After UFW Enable
If you enabled UFW and forgot to allow SSH:
1. Access via console/KVM/IPMI
2. Run: `sudo ufw allow 22/tcp && sudo ufw reload`

#### fail2ban Not Banning
Check logs: `sudo tail -f /var/log/fail2ban.log`
Verify jail is active: `sudo fail2ban-client status sshd`

#### Automatic Updates Not Running
Check status: `sudo systemctl status unattended-upgrades`
Check logs: `sudo tail /var/log/unattended-upgrades/unattended-upgrades.log`

---

## Package Lists

### Core Packages
neofetch, inxi, btop, duf, ncdu, mc, micro, fd-find, ripgrep, tree, eza, bat, nala, gping

### Monitoring Tools
iotop, nethogs, iftop, sysstat, smartmontools, lm-sensors, atop

### Security Tools
fail2ban, ufw, lynis, rkhunter, aide, unattended-upgrades, needrestart, debsums, apt-listchanges

### Networking Tools
mtr-tiny, nmap, tcpdump, bind9-dnsutils, net-tools, traceroute, ethtool, iperf3

### Container Tools
docker.io, docker-compose

### Optional/Fun
lolcat, fortune, cowsay, figlet, ansiweather

---

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is designed for internal use at Renstar Global LLC but is shared for reference.

## Support

For questions or issues, please open a GitHub issue.

---

**Remember:** This is infrastructure - test changes on non-production systems first!
