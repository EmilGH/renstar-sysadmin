# Configuration Guide

## Quick Start

### Using Profiles

```bash
# Minimal installation
./install.sh --profile minimal

# Server installation
./install.sh --profile server

# Docker host installation
./install.sh --profile docker-host
```

### Creating Custom Configuration

```bash
# Copy default or profile as starting point
cp config/default.conf config/myserver.conf

# Edit configuration
nano config/myserver.conf

# Use custom configuration
./install.sh --config config/myserver.conf
```

## Configuration File Structure

Configuration files are bash scripts that set variables. They are sourced in this order:

1. `config/default.conf` (always loaded)
2. Profile or custom config (overrides defaults)

## Configuration Options

### Package Categories

Control which package groups are installed:

```bash
ENABLE_CORE_PACKAGES=true      # Essential utilities
ENABLE_MONITORING=true         # Monitoring tools
ENABLE_NETWORKING=true         # Network diagnostics
ENABLE_SECURITY=true           # Security packages
ENABLE_CONTAINERS=false        # Docker, docker-compose
ENABLE_DEVELOPMENT=false       # Git, vim, tmux, etc.
ENABLE_OPTIONAL=true           # Fun packages (lolcat, fortune)
```

### Package Lists

Customize which packages are installed in each category:

```bash
PACKAGES_CORE=(
    "neofetch"
    "inxi"
    "btop"
    "duf"
    # Add more packages here
)

PACKAGES_MONITORING=(
    "iotop"
    "nethogs"
    "smartmontools"
)

# Similar for other categories...
```

### Maintenance Options

Control which maintenance tasks run:

```bash
MAINTENANCE_APT_UPDATE=true        # APT package updates
MAINTENANCE_SNAP_UPDATE=true       # Snap package updates
MAINTENANCE_FLATPAK_UPDATE=false   # Flatpak updates
MAINTENANCE_DOCKER_CLEANUP=false   # Docker cleanup
MAINTENANCE_FIRMWARE_UPDATE=false  # Firmware updates
MAINTENANCE_KERNEL_CLEANUP=true    # Old kernel removal
MAINTENANCE_LOG_CLEANUP=true       # Log file cleanup
MAINTENANCE_SECURITY_CHECKS=true   # Security audits
```

### Maintenance Thresholds

Fine-tune maintenance behavior:

```bash
LOG_RETENTION_DAYS=30              # Journal log retention
LOG_MAX_SIZE_MB=500                # Maximum journal size
DISK_ALERT_THRESHOLD=85            # Disk usage warning level
KEEP_OLD_KERNELS=2                 # Number of old kernels to keep
DOCKER_IMAGE_PRUNE=false           # Aggressively prune Docker images
```

### Service Detection

Enable/disable service-specific maintenance:

```bash
SERVICE_PLEX_ENABLED=true          # Update Plex Media Server
SERVICE_PIHOLE_ENABLED=true        # Update Pi-hole
SERVICE_HOMEBRIDGE_ENABLED=true    # Update Homebridge
SERVICE_DOCKER_ENABLED=false       # Manage Docker
SERVICE_NGINX_ENABLED=false        # Manage Nginx
SERVICE_APACHE_ENABLED=false       # Manage Apache
```

### Dotfile Options

Control which configuration files are deployed:

```bash
INSTALL_BASH_ALIASES=true          # Install .bash_aliases
INSTALL_BASH_LOGOUT=true           # Install .bash_logout
INSTALL_FORTUNE_LOGIN=true         # Install login banner
INSTALL_VIM_CONFIG=false           # Install .vimrc
INSTALL_TMUX_CONFIG=false          # Install .tmux.conf
INSTALL_GIT_CONFIG=false           # Install .gitconfig

BACKUP_EXISTING_CONFIGS=true       # Backup before overwriting
BACKUP_SUFFIX=".renstar.backup"    # Backup file suffix
```

### Login Customization

Customize the login experience:

```bash
SHOW_WEATHER=true                  # Show weather at login
WEATHER_LOCATION="upper saddle river,us"  # Weather location
WEATHER_UNITS="imperial"           # imperial or metric
SHOW_FORTUNE=true                  # Show fortune cookie
SHOW_NEOFETCH=true                 # Show system info
SHOW_DISK_INFO=true                # Show disk information
```

### Email Notifications

Configure email alerts:

```bash
ENABLE_EMAIL_NOTIFICATIONS=false   # Enable email
EMAIL_TO="admin@example.com"       # Recipient address
EMAIL_FROM="server@example.com"    # Sender address
SMTP_SERVER="smtp.example.com"     # SMTP server
SMTP_PORT=587                      # SMTP port

NOTIFY_ON_UPDATES=true             # Email after updates
NOTIFY_ON_ERRORS=true              # Email on errors
NOTIFY_ON_SECURITY=true            # Email security alerts
NOTIFY_ON_REBOOT_REQUIRED=true     # Email if reboot needed
```

### Logging Options

Control logging behavior:

```bash
LOG_DIR="/var/log/renstar-sysadmin"  # Log directory
LOG_RETENTION_DAYS=90                # Keep logs this many days
LOG_VERBOSITY="normal"               # quiet, normal, verbose, debug
```

### Security Options

**IMPORTANT**: These options control WHETHER services should be enabled.
Services are NOT automatically enabled - you must manually configure them first!

```bash
UFW_ENABLE=false                   # Enable UFW firewall
UFW_DEFAULT_DENY_INCOMING=true     # Deny incoming by default
UFW_ALLOWED_PORTS=(22 80 443)      # Allowed ports

FAIL2BAN_ENABLE=false              # Enable fail2ban
FAIL2BAN_BANTIME=3600              # Ban duration (seconds)
FAIL2BAN_MAXRETRY=5                # Failed attempts before ban

AUTO_SECURITY_UPDATES=false        # Automatic security updates
AUTO_REBOOT_IF_REQUIRED=false      # Auto-reboot if needed
AUTO_REBOOT_TIME="03:00"           # Reboot time (if enabled)
```

### Advanced Options

```bash
PARALLEL_INSTALLS=false            # Install packages in parallel
MAX_PARALLEL_JOBS=4                # Max parallel operations

DRY_RUN=false                      # Preview without changes
UNATTENDED=false                   # Skip prompts
COLOR_OUTPUT=true                  # Colorized output
```

## Profile Examples

### Minimal Profile

For systems where you only want basic utilities:

```bash
INSTALL_MODE="minimal"

ENABLE_CORE_PACKAGES=true
ENABLE_MONITORING=false
ENABLE_NETWORKING=false
ENABLE_SECURITY=false
ENABLE_CONTAINERS=false
ENABLE_DEVELOPMENT=false
ENABLE_OPTIONAL=false

PACKAGES_CORE=(
    "neofetch"
    "btop"
    "ncdu"
    "micro"
)
```

### Server Profile

Production server with full monitoring and security:

```bash
INSTALL_MODE="full"

ENABLE_CORE_PACKAGES=true
ENABLE_MONITORING=true
ENABLE_NETWORKING=true
ENABLE_SECURITY=true
ENABLE_CONTAINERS=false
ENABLE_DEVELOPMENT=false
ENABLE_OPTIONAL=false

UFW_ENABLE=true
FAIL2BAN_ENABLE=true
AUTO_SECURITY_UPDATES=true

LOG_RETENTION_DAYS=15
KEEP_OLD_KERNELS=1
```

### Docker Host Profile

Optimized for running containers:

```bash
INSTALL_MODE="full"

ENABLE_CONTAINERS=true
ENABLE_MONITORING=true
ENABLE_SECURITY=true

SERVICE_DOCKER_ENABLED=true
MAINTENANCE_DOCKER_CLEANUP=true
DOCKER_IMAGE_PRUNE=true

LOG_RETENTION_DAYS=15
```

## Environment-Specific Configuration

### Development Environment

```bash
# config/dev.conf
source "$(dirname "${BASH_SOURCE[0]}")/default.conf"

ENABLE_DEVELOPMENT=true
ENABLE_OPTIONAL=true

PACKAGES_DEVELOPMENT+=(
    "build-essential"
    "python3-pip"
    "nodejs"
    "npm"
)
```

### Production Environment

```bash
# config/prod.conf
source "$(dirname "${BASH_SOURCE[0]}")/profiles/server.conf"

# Stricter security
FAIL2BAN_MAXRETRY=3
FAIL2BAN_BANTIME=7200

# Email notifications
ENABLE_EMAIL_NOTIFICATIONS=true
EMAIL_TO="ops-team@example.com"

# Aggressive cleanup
LOG_RETENTION_DAYS=7
KEEP_OLD_KERNELS=1
```

## Testing Configuration

### Dry Run

Test configuration without making changes:

```bash
./install.sh --config config/myserver.conf --dry-run
```

### Verbose Mode

See exactly what's happening:

```bash
./install.sh --config config/myserver.conf --verbose
```

## Configuration Best Practices

1. **Start with a profile**: Use a profile as your base, then customize
2. **Document changes**: Add comments explaining why you changed settings
3. **Version control**: Keep configurations in git
4. **Test before production**: Always dry-run on test systems first
5. **Security first**: Never auto-enable security services without testing
6. **Environment-specific**: Create separate configs for dev/staging/prod
7. **Regular review**: Review and update configurations quarterly
