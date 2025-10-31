#!/bin/bash
# APT/Nala Package Updates

run_apt_update() {
    log_section "APT Package Updates"

    if [[ "${MAINTENANCE_APT_UPDATE:-true}" != "true" ]]; then
        log_skip "APT updates disabled in config"
        return 0
    fi

    # Check if nala is available, fallback to apt
    if command_exists nala; then
        PKG_MANAGER="nala"
    else
        PKG_MANAGER="apt"
        log_info "Using apt (nala not installed)"
    fi

    log_info "Updating package lists..."
    log_command "sudo $PKG_MANAGER update"
    if ! run_cmd sudo "$PKG_MANAGER" update; then
        log_error "Failed to update package lists"
        return 1
    fi

    log_info "Upgrading packages..."
    log_command "sudo $PKG_MANAGER upgrade -y"
    if ! run_cmd sudo "$PKG_MANAGER" upgrade -y; then
        log_error "Failed to upgrade packages"
        return 1
    fi

    log_info "Removing unnecessary packages..."
    log_command "sudo $PKG_MANAGER autoremove -y"
    if ! run_cmd sudo "$PKG_MANAGER" autoremove -y; then
        log_warn "Autoremove completed with warnings"
    fi

    log_success "APT updates complete"

    # Check if reboot required
    check_reboot_required

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_apt_update
fi
