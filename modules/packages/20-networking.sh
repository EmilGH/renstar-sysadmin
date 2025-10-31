#!/bin/bash
# Networking Tools Installation Module

install_networking_packages() {
    log_section "Networking Tools Installation"

    if [[ "${ENABLE_NETWORKING:-false}" != "true" ]]; then
        log_skip "Networking tools disabled in config"
        return 0
    fi

    local packages=("${PACKAGES_NETWORKING[@]}")

    log_info "Installing ${#packages[@]} networking package(s)..."

    if ! run_cmd sudo apt install -y "${packages[@]}"; then
        log_warn "Some networking packages may have failed to install"
    fi

    log_success "Networking tools installed"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_networking_packages
fi
