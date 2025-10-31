#!/bin/bash
# Container Tools Installation Module

install_container_packages() {
    log_section "Container Tools Installation"

    if [[ "${ENABLE_CONTAINERS:-false}" != "true" ]]; then
        log_skip "Container tools disabled in config"
        return 0
    fi

    local packages=("${PACKAGES_CONTAINERS[@]}")

    log_info "Installing ${#packages[@]} container package(s)..."

    if ! run_cmd sudo apt install -y "${packages[@]}"; then
        log_error "Failed to install container packages"
        return 1
    fi

    # Enable Docker if requested
    if [[ "${SERVICE_DOCKER_ENABLED:-false}" == "true" ]] && package_installed docker.io; then
        log_info "Enabling Docker service..."
        run_cmd sudo systemctl enable docker
        run_cmd sudo systemctl start docker

        if service_is_active docker; then
            log_ok "Docker is running"
        else
            log_warn "Docker failed to start"
        fi
    else
        log_warn "Docker installed but NOT enabled (enable in config or manually)"
    fi

    log_success "Container tools installed"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_container_packages
fi
