#!/bin/bash
#
# Renstar Global LLC - System Health Monitor
# Run daily/weekly to check system health and generate reports
# Version: 2.1c
#
# Usage: ./system-monitor.sh [--email admin@example.com] [--verbose]

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_VERSION="2.1c"
HOSTNAME=$(hostname)
REPORT_FILE="/tmp/system-report-$(date +%Y%m%d-%H%M%S).txt"
SEND_EMAIL=false
EMAIL_TO=""
VERBOSE=false

# Thresholds
DISK_WARN_THRESHOLD=80
DISK_CRIT_THRESHOLD=90
MEM_WARN_THRESHOLD=80
CPU_WARN_THRESHOLD=80
LOAD_MULTIPLIER=2  # Warn if load > (cores * multiplier)

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --email)
            SEND_EMAIL=true
            EMAIL_TO="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--email admin@example.com] [--verbose]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_header() {
    echo -e "\n${BLUE}========================================${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}========================================${NC}" | tee -a "$REPORT_FILE"
}

log_section() {
    echo -e "\n${BLUE}>>> $1${NC}" | tee -a "$REPORT_FILE"
}

log_ok() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$REPORT_FILE"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$REPORT_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$REPORT_FILE"
}

log_info() {
    echo "  $1" | tee -a "$REPORT_FILE"
}

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

check_system_info() {
    log_section "System Information"

    log_info "Hostname: $HOSTNAME"
    log_info "Date: $(date)"
    log_info "Uptime: $(uptime -p)"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_info "OS: $PRETTY_NAME"
    fi

    log_info "Kernel: $(uname -r)"
    log_info "Architecture: $(uname -m)"
}

check_disk_space() {
    log_section "Disk Space"

    local alerts=0

    while IFS= read -r line; do
        local filesystem=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local used=$(echo "$line" | awk '{print $3}')
        local avail=$(echo "$line" | awk '{print $4}')
        local percent=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')

        if [ "$percent" -ge "$DISK_CRIT_THRESHOLD" ]; then
            log_error "$mount is ${percent}% full (${used}/${size}) - CRITICAL"
            ((alerts++))
        elif [ "$percent" -ge "$DISK_WARN_THRESHOLD" ]; then
            log_warn "$mount is ${percent}% full (${used}/${size})"
            ((alerts++))
        else
            log_ok "$mount is ${percent}% full (${avail} available)"
        fi
    done < <(df -h | grep '^/dev/')

    return $alerts
}

check_memory() {
    log_section "Memory Usage"

    local total=$(free -h | awk '/^Mem:/ {print $2}')
    local used=$(free -h | awk '/^Mem:/ {print $3}')
    local free=$(free -h | awk '/^Mem:/ {print $4}')
    local percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

    log_info "Total: $total | Used: $used | Free: $free"

    if [ "$percent" -ge "$MEM_WARN_THRESHOLD" ]; then
        log_warn "Memory usage at ${percent}%"
        return 1
    else
        log_ok "Memory usage at ${percent}%"
        return 0
    fi
}

check_swap() {
    log_section "Swap Usage"

    local swap_total=$(free -h | awk '/^Swap:/ {print $2}')
    local swap_used=$(free -h | awk '/^Swap:/ {print $3}')

    if [ "$swap_total" = "0B" ]; then
        log_warn "No swap configured"
        return 1
    fi

    local swap_percent=$(free | awk '/^Swap:/ {if ($2 > 0) printf "%.0f", $3/$2 * 100; else print "0"}')

    log_info "Total: $swap_total | Used: $swap_used"

    if [ "$swap_percent" -ge 50 ]; then
        log_warn "Swap usage at ${swap_percent}% (may indicate memory pressure)"
        return 1
    else
        log_ok "Swap usage at ${swap_percent}%"
        return 0
    fi
}

check_cpu_load() {
    log_section "CPU Load Average"

    local load1=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local load5=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $2}' | sed 's/,//')
    local load15=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $3}')
    local cores=$(nproc)
    local threshold=$(echo "$cores * $LOAD_MULTIPLIER" | bc)

    log_info "Load: $load1, $load5, $load15 (${cores} cores)"

    if (( $(echo "$load1 > $threshold" | bc -l) )); then
        log_warn "High load average: $load1 (threshold: $threshold)"
        return 1
    else
        log_ok "Load average normal"
        return 0
    fi
}

check_failed_services() {
    log_section "Failed Services"

    local failed=$(systemctl --failed --no-pager --no-legend | wc -l)

    if [ "$failed" -gt 0 ]; then
        log_error "$failed failed service(s):"
        systemctl --failed --no-pager | tee -a "$REPORT_FILE"
        return 1
    else
        log_ok "No failed services"
        return 0
    fi
}

check_critical_services() {
    log_section "Critical Services Status"

    local critical_services=("ssh" "fail2ban" "ufw" "cron")
    local alerts=0

    for service in "${critical_services[@]}"; do
        if systemctl list-unit-files | grep -q "^${service}.service"; then
            if systemctl is-active --quiet "$service"; then
                log_ok "$service is running"
            else
                log_error "$service is NOT running"
                ((alerts++))
            fi
        else
            if [ "$VERBOSE" = true ]; then
                log_info "$service not installed"
            fi
        fi
    done

    return $alerts
}

check_disk_health() {
    log_section "Disk Health (SMART)"

    if ! command -v smartctl &> /dev/null; then
        log_warn "smartmontools not installed - skipping disk health check"
        return 0
    fi

    local alerts=0

    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -e "$disk" ]; then
            local health=$(sudo smartctl -H "$disk" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')

            if [ "$health" = "PASSED" ]; then
                log_ok "$(basename $disk): $health"
            else
                log_error "$(basename $disk): $health"
                ((alerts++))
            fi
        fi
    done

    if [ $alerts -eq 0 ] && [ "$VERBOSE" = false ]; then
        log_ok "All disks healthy"
    fi

    return $alerts
}

check_security_bans() {
    log_section "Security: fail2ban Status"

    if ! command -v fail2ban-client &> /dev/null; then
        log_warn "fail2ban not installed"
        return 0
    fi

    if ! systemctl is-active --quiet fail2ban; then
        log_error "fail2ban is not running!"
        return 1
    fi

    local total_banned=0
    local jails=$(sudo fail2ban-client status | grep "Jail list" | sed 's/.*://; s/,//g')

    for jail in $jails; do
        local banned=$(sudo fail2ban-client status "$jail" | grep "Currently banned" | awk '{print $NF}')
        total_banned=$((total_banned + banned))

        if [ "$banned" -gt 0 ]; then
            log_warn "$jail: $banned currently banned"
        elif [ "$VERBOSE" = true ]; then
            log_ok "$jail: 0 banned"
        fi
    done

    if [ $total_banned -eq 0 ]; then
        log_ok "fail2ban active, no current bans"
    else
        log_info "Total IPs banned across all jails: $total_banned"
    fi

    return 0
}

check_firewall_status() {
    log_section "Firewall Status"

    if ! command -v ufw &> /dev/null; then
        log_warn "UFW not installed"
        return 0
    fi

    local status=$(sudo ufw status | grep "Status:" | awk '{print $2}')

    if [ "$status" = "active" ]; then
        log_ok "UFW firewall is active"

        if [ "$VERBOSE" = true ]; then
            echo "" | tee -a "$REPORT_FILE"
            sudo ufw status numbered | tee -a "$REPORT_FILE"
        fi
        return 0
    else
        log_error "UFW firewall is INACTIVE!"
        return 1
    fi
}

check_recent_logins() {
    log_section "Recent Login Activity"

    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | wc -l)

    if [ $failed_logins -gt 0 ]; then
        log_warn "$failed_logins recent failed login attempts"

        if [ "$VERBOSE" = true ]; then
            echo "" | tee -a "$REPORT_FILE"
            grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | tee -a "$REPORT_FILE"
        fi
    else
        log_ok "No recent failed login attempts"
    fi

    # Show successful logins
    if [ "$VERBOSE" = true ]; then
        log_info "Recent successful logins:"
        last -n 5 | tee -a "$REPORT_FILE"
    fi
}

check_updates_available() {
    log_section "Available Updates"

    sudo apt update -qq 2>&1 | tee -a "$REPORT_FILE" >/dev/null

    local updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

    if [ $updates -gt 0 ]; then
        log_warn "$updates package(s) can be updated"

        if [ "$VERBOSE" = true ]; then
            apt list --upgradable 2>/dev/null | grep upgradable | tee -a "$REPORT_FILE"
        fi

        # Check for security updates specifically
        local security=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l || true)
        if [ $security -gt 0 ]; then
            log_error "$security SECURITY update(s) available!"
        fi

        return 1
    else
        log_ok "System is up to date"
        return 0
    fi
}

check_reboot_required() {
    log_section "Reboot Status"

    if [ -f /var/run/reboot-required ]; then
        log_warn "System reboot required"

        if [ -f /var/run/reboot-required.pkgs ]; then
            log_info "Packages requiring reboot:"
            cat /var/run/reboot-required.pkgs | sed 's/^/    /' | tee -a "$REPORT_FILE"
        fi
        return 1
    else
        log_ok "No reboot required"
        return 0
    fi
}

check_database_sizes() {
    log_section "Database & Application Sizes"

    # MySQL/MariaDB
    if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mariadb 2>/dev/null; then
        log_info "MySQL/MariaDB databases:"
        sudo du -sh /var/lib/mysql/* 2>/dev/null | sort -hr | head -5 | sed 's/^/  /' | tee -a "$REPORT_FILE"
    fi

    # PostgreSQL
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        log_info "PostgreSQL databases:"
        sudo du -sh /var/lib/postgresql/* 2>/dev/null | sort -hr | head -5 | sed 's/^/  /' | tee -a "$REPORT_FILE"
    fi

    # Plex
    if [ -d "/var/lib/plexmediaserver" ]; then
        local plex_size=$(sudo du -sh /var/lib/plexmediaserver 2>/dev/null | awk '{print $1}')
        log_info "Plex database: $plex_size"
    fi

    # Pi-hole
    if [ -f "/etc/pihole/gravity.db" ]; then
        local pihole_size=$(sudo du -sh /etc/pihole/gravity.db 2>/dev/null | awk '{print $1}')
        log_info "Pi-hole gravity: $pihole_size"
    fi
}

check_docker_status() {
    log_section "Docker Status"

    if ! command -v docker &> /dev/null; then
        if [ "$VERBOSE" = true ]; then
            log_info "Docker not installed"
        fi
        return 0
    fi

    if systemctl is-active --quiet docker; then
        log_ok "Docker service is running"

        local containers_running=$(sudo docker ps -q | wc -l)
        local containers_total=$(sudo docker ps -aq | wc -l)
        local images=$(sudo docker images -q | wc -l)

        log_info "Containers: $containers_running running / $containers_total total"
        log_info "Images: $images"

        if [ "$VERBOSE" = true ]; then
            echo "" | tee -a "$REPORT_FILE"
            sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" | tee -a "$REPORT_FILE"
        fi

        # Check for stopped containers
        local stopped=$(sudo docker ps -aqf "status=exited" | wc -l)
        if [ $stopped -gt 0 ]; then
            log_warn "$stopped stopped container(s) - consider cleanup"
        fi
    else
        log_warn "Docker installed but not running"
    fi
}

check_largest_files() {
    log_section "Largest Files (Top 10)"

    log_info "Finding largest files in /var and /home (this may take a moment)..."

    sudo find /var /home -type f -size +100M -exec ls -lh {} \; 2>/dev/null | \
        awk '{print $5 " " $9}' | \
        sort -hr | \
        head -10 | \
        sed 's/^/  /' | \
        tee -a "$REPORT_FILE" || log_info "No files >100MB found"
}

check_log_sizes() {
    log_section "Log File Sizes"

    log_info "Largest log files:"
    sudo du -sh /var/log/* 2>/dev/null | sort -hr | head -10 | sed 's/^/  /' | tee -a "$REPORT_FILE"

    # Journal size
    local journal_size=$(sudo journalctl --disk-usage | awk '{print $7" "$8}')
    log_info "Systemd journal: $journal_size"
}

check_network_connections() {
    log_section "Network Connections"

    local established=$(sudo ss -antu | grep ESTAB | wc -l)
    local listening=$(sudo ss -antu | grep LISTEN | wc -l)

    log_info "Established: $established | Listening: $listening"

    if [ "$VERBOSE" = true ]; then
        log_info "Listening services:"
        sudo ss -tulpn | grep LISTEN | sed 's/^/  /' | tee -a "$REPORT_FILE"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_header "System Health Report - $HOSTNAME"
    log_info "Generated: $(date)"
    log_info "Script Version: $SCRIPT_VERSION"

    local total_errors=0
    local total_warnings=0

    # Run all checks
    check_system_info

    check_disk_space || ((total_warnings++))
    check_memory || ((total_warnings++))
    check_swap || ((total_warnings++))
    check_cpu_load || ((total_warnings++))

    check_failed_services || ((total_errors++))
    check_critical_services || ((total_errors++))

    check_disk_health || ((total_warnings++))
    check_security_bans
    check_firewall_status || ((total_errors++))
    check_recent_logins

    check_updates_available || ((total_warnings++))
    check_reboot_required || ((total_warnings++))

    check_database_sizes
    check_docker_status

    if [ "$VERBOSE" = true ]; then
        check_largest_files
        check_log_sizes
        check_network_connections
    fi

    # Summary
    log_header "Summary"

    if [ $total_errors -eq 0 ] && [ $total_warnings -eq 0 ]; then
        log_ok "All systems operational"
    else
        if [ $total_errors -gt 0 ]; then
            log_error "$total_errors critical issue(s) found"
        fi
        if [ $total_warnings -gt 0 ]; then
            log_warn "$total_warnings warning(s) found"
        fi
    fi

    log_info "Full report saved to: $REPORT_FILE"

    # Send email if requested
    if [ "$SEND_EMAIL" = true ] && [ -n "$EMAIL_TO" ]; then
        local subject="System Health Report: $HOSTNAME"
        if [ $total_errors -gt 0 ]; then
            subject="[CRITICAL] $subject"
        elif [ $total_warnings -gt 0 ]; then
            subject="[WARNING] $subject"
        else
            subject="[OK] $subject"
        fi

        if command -v mail &> /dev/null; then
            cat "$REPORT_FILE" | mail -s "$subject" "$EMAIL_TO"
            log_ok "Report emailed to $EMAIL_TO"
        else
            log_warn "mail command not found - cannot send email"
        fi
    fi

    echo ""
}

# Run main function
main

# Exit with error code if critical issues found
[ $total_errors -eq 0 ]
