#!/bin/bash
# Common utility functions for Renstar SysAdmin
# Version: 2.1c

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_cmd() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        echo "[DRY-RUN] $*"
        return 0
    else
        "$@"
        return $?
    fi
}

package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

check_reboot_required() {
    if [[ -f /var/run/reboot-required ]]; then
        log_warn "System reboot required!"
        if [[ -f /var/run/reboot-required.pkgs ]]; then
            log_info "Packages requiring reboot:"
            cat /var/run/reboot-required.pkgs | while read line; do
                log_info "  - $line"
            done
        fi

        if [[ "${AUTO_REBOOT_IF_REQUIRED:-false}" == "true" ]]; then
            log_warn "Auto-reboot scheduled for ${AUTO_REBOOT_TIME:-03:00}"
            echo "sudo reboot" | at "${AUTO_REBOOT_TIME:-03:00}" 2>/dev/null || true
        fi
    fi
}

get_distro_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    fi
}

get_distro_codename() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_CODENAME"
    fi
}

is_root() {
    [[ $EUID -eq 0 ]]
}

require_root() {
    if ! is_root; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

require_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 1
    fi
}

disk_space_check() {
    local threshold="${1:-85}"
    local alerts=()

    while IFS= read -r line; do
        local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        local mount=$(echo "$line" | awk '{print $6}')

        if [[ $usage -gt $threshold ]]; then
            alerts+=("$mount is ${usage}% full")
        fi
    done < <(df -h | grep '^/dev/')

    if [[ ${#alerts[@]} -gt 0 ]]; then
        log_warn "Disk space alerts:"
        printf '%s\n' "${alerts[@]}" | while read alert; do
            log_warn "  $alert"
        done
        return 1
    fi

    return 0
}

service_enabled() {
    local service="$1"
    local var="SERVICE_${service^^}_ENABLED"
    [[ "${!var:-false}" == "true" ]]
}

service_is_active() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

service_is_enabled() {
    local service="$1"
    systemctl is-enabled --quiet "$service" 2>/dev/null
}

backup_file() {
    local file="$1"
    local suffix="${BACKUP_SUFFIX:-.backup}"

    if [[ -f "$file" ]]; then
        local backup="${file}${suffix}.$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

create_log_dir() {
    local log_dir="${LOG_DIR:-/var/log/renstar-sysadmin}"

    # Try to create system log directory if running with sudo
    if [[ ! -d "$log_dir" ]] && sudo -n true 2>/dev/null; then
        sudo mkdir -p "$log_dir" 2>/dev/null || true
        sudo chmod 755 "$log_dir" 2>/dev/null || true
    fi

    # If system log dir isn't writable, use user's home directory
    if [[ ! -w "$log_dir" ]]; then
        local user_log_dir="$HOME/.local/share/renstar-sysadmin/logs"
        mkdir -p "$user_log_dir" 2>/dev/null || true

        if [[ -w "$user_log_dir" ]]; then
            log_debug "Using user log directory: $user_log_dir"
        fi
    fi
}

get_cpu_cores() {
    nproc
}

get_total_memory() {
    free -h | awk '/^Mem:/ {print $2}'
}

detect_virtualization() {
    if command_exists systemd-detect-virt; then
        systemd-detect-virt
    else
        echo "unknown"
    fi
}
