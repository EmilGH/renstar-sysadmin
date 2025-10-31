#!/bin/bash
# Monitoring Tools Installation Module

install_monitoring_packages() {
    log_section "Monitoring Tools Installation"

    if [[ "${ENABLE_MONITORING:-false}" != "true" ]]; then
        log_skip "Monitoring tools disabled in config"
        return 0
    fi

    local packages=("${PACKAGES_MONITORING[@]}")

    log_info "Installing ${#packages[@]} monitoring package(s)..."

    if ! run_cmd sudo apt install -y "${packages[@]}"; then
        log_error "Failed to install monitoring packages"
        return 1
    fi

    # Enable smartmontools if installed
    if package_installed smartmontools; then
        log_info "Enabling smartmontools service..."
        run_cmd sudo systemctl enable smartmontools 2>/dev/null || true
        run_cmd sudo systemctl start smartmontools 2>/dev/null || true

        if service_is_active smartmontools; then
            log_ok "smartmontools is running"
        fi
    fi

    # Enable sysstat if installed
    if package_installed sysstat; then
        log_info "Enabling sysstat data collection..."
        run_cmd sudo sed -i 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat 2>/dev/null || true
        run_cmd sudo systemctl enable sysstat 2>/dev/null || true
        run_cmd sudo systemctl start sysstat 2>/dev/null || true

        if service_is_active sysstat; then
            log_ok "sysstat is running"
        fi
    fi

    log_success "Monitoring tools installed"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_monitoring_packages
fi
