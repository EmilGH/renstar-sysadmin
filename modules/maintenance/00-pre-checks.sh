#!/bin/bash
# Pre-Maintenance System Checks

run_pre_checks() {
    log_section "Pre-Maintenance System Checks"

    local warnings=0

    # Check disk space
    log_info "Checking disk space..."
    if ! disk_space_check "${DISK_ALERT_THRESHOLD:-85}"; then
        ((warnings++))
    fi

    # Check if system is up
    log_info "System uptime: $(uptime -p)"

    # Check for failed services
    local failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
    if [[ $failed -gt 0 ]]; then
        log_warn "$failed service(s) currently failed"
        systemctl --failed --no-pager --no-legend
        ((warnings++))
    else
        log_ok "No failed services"
    fi

    # Check internet connectivity
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log_ok "Internet connectivity verified"
    else
        log_error "No internet connectivity - updates will fail"
        return 1
    fi

    if [[ $warnings -gt 0 ]]; then
        log_warn "$warnings pre-check warning(s) found"
    else
        log_success "All pre-checks passed"
    fi

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_pre_checks
fi
