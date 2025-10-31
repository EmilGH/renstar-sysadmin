#!/bin/bash
# System Cleanup Module

run_system_cleanup() {
    log_section "System Cleanup"

    local cleaned=0

    # APT cache cleanup
    log_info "Cleaning APT cache..."
    if command_exists nala; then
        run_cmd sudo nala clean
    else
        run_cmd sudo apt clean
    fi
    ((cleaned++))

    # Old kernel cleanup
    if [[ "${MAINTENANCE_KERNEL_CLEANUP:-true}" == "true" ]]; then
        log_info "Cleaning old kernels (keeping ${KEEP_OLD_KERNELS:-2})..."

        # Count installed kernels
        local kernel_count=$(dpkg -l | grep -c "linux-image-[0-9]" || echo "0")

        if [[ $kernel_count -gt ${KEEP_OLD_KERNELS:-2} ]]; then
            log_info "Found $kernel_count kernels, removing old ones..."
            run_cmd sudo apt autoremove --purge -y
            ((cleaned++))
        else
            log_ok "Only $kernel_count kernel(s) installed, no cleanup needed"
        fi
    fi

    # Journal log cleanup
    if [[ "${MAINTENANCE_LOG_CLEANUP:-true}" == "true" ]]; then
        log_info "Cleaning systemd journal logs..."
        log_command "sudo journalctl --vacuum-time=${LOG_RETENTION_DAYS:-30}d"
        run_cmd sudo journalctl --vacuum-time="${LOG_RETENTION_DAYS:-30}d" >/dev/null 2>&1
        log_command "sudo journalctl --vacuum-size=${LOG_MAX_SIZE_MB:-500}M"
        run_cmd sudo journalctl --vacuum-size="${LOG_MAX_SIZE_MB:-500}M" >/dev/null 2>&1
        ((cleaned++))
    fi

    # Thumbnail cache cleanup (user-specific)
    if [[ -d "$HOME/.cache/thumbnails" ]]; then
        log_info "Cleaning thumbnail cache..."
        run_cmd find "$HOME/.cache/thumbnails" -type f -atime +7 -delete 2>/dev/null || true
        ((cleaned++))
    fi

    log_success "System cleanup complete ($cleaned tasks)"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_system_cleanup
fi
