#!/bin/bash
# Post-Maintenance System Verification

run_post_checks() {
    log_section "Post-Maintenance Verification"

    local issues=0

    # Check for failed services
    local failed=$(systemctl --failed --no-pager --no-legend 2>/dev/null | wc -l)
    if [[ $failed -gt 0 ]]; then
        log_error "$failed service(s) failed after maintenance"
        systemctl --failed --no-pager
        ((issues++))
    else
        log_ok "No failed services"
    fi

    # Check disk space again
    if ! disk_space_check "${DISK_ALERT_THRESHOLD:-85}"; then
        ((issues++))
    fi

    # Check for reboot requirement
    if [[ -f /var/run/reboot-required ]]; then
        log_warn "System reboot is required"
        if [[ -f /var/run/reboot-required.pkgs ]]; then
            log_info "Packages requiring reboot:"
            cat /var/run/reboot-required.pkgs | while read pkg; do
                log_info "  - $pkg"
            done
        fi
        ((issues++))
    else
        log_ok "No reboot required"
    fi

    if [[ $issues -eq 0 ]]; then
        log_success "All post-checks passed"
    else
        log_warn "$issues issue(s) found in post-checks"
    fi

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_post_checks
fi
