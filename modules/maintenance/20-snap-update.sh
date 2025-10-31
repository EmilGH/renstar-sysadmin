#!/bin/bash
# Snap Package Updates

run_snap_update() {
    log_section "Snap Package Updates"

    if [[ "${MAINTENANCE_SNAP_UPDATE:-false}" != "true" ]]; then
        log_skip "Snap updates disabled in config"
        return 0
    fi

    if ! command_exists snap; then
        log_skip "Snap not installed"
        return 0
    fi

    log_info "Refreshing snap packages..."
    log_command "sudo snap refresh"
    if ! run_cmd sudo snap refresh; then
        log_warn "Snap refresh completed with warnings"
    else
        log_success "Snap packages updated"
    fi

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_snap_update
fi
