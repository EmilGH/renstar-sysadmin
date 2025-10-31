#!/bin/bash
# Security Package Installation & Configuration Module

install_security_packages() {
    log_section "Security Package Installation"

    if [[ "${ENABLE_SECURITY:-false}" != "true" ]]; then
        log_skip "Security packages disabled in config"
        return 0
    fi

    local packages=("${PACKAGES_SECURITY[@]}")

    log_info "Installing ${#packages[@]} security package(s)..."

    if ! run_cmd sudo apt install -y "${packages[@]}"; then
        log_error "Failed to install security packages"
        return 1
    fi

    log_success "Security packages installed"

    # NOTE: Services are NOT auto-enabled for security reasons
    # User must manually configure via post-installation steps
    log_warn "Security packages installed but NOT enabled"
    log_info "See README.md for post-installation configuration steps:"
    log_info "  - fail2ban configuration and enabling"
    log_info "  - UFW firewall setup"
    log_info "  - Automatic security updates"
    log_info "  - AIDE file integrity monitoring"

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_security_packages
fi
