#!/bin/bash
# Core Package Installation Module

install_core_packages() {
    log_section "Core Package Installation"

    if [[ "${ENABLE_CORE_PACKAGES:-true}" != "true" ]]; then
        log_skip "Core packages disabled in config"
        return 0
    fi

    # Combine core and modern CLI packages
    local all_packages=()
    all_packages+=("${PACKAGES_CORE[@]}")
    all_packages+=("${PACKAGES_MODERN_CLI[@]}")

    if [[ "${ENABLE_OPTIONAL:-false}" == "true" ]]; then
        all_packages+=("${PACKAGES_OPTIONAL[@]}")
    fi

    log_info "Installing ${#all_packages[@]} core package(s)..."

    # Update package lists first
    log_command "apt update"
    if ! run_cmd sudo apt update; then
        log_error "Failed to update package lists"
        return 1
    fi

    # Install all packages
    log_command "apt install ${all_packages[*]}"
    if ! run_cmd sudo apt install -y "${all_packages[@]}"; then
        log_warn "Some packages may have failed to install"
    fi

    log_success "Core packages installed"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_core_packages
fi
