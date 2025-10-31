#!/bin/bash
# Dotfiles Installation Module

install_dotfiles() {
    log_section "Dotfiles Installation"

    local installed=0
    local script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

    # Bash aliases
    if [[ "${INSTALL_BASH_ALIASES:-true}" == "true" ]]; then
        log_info "Installing bash aliases..."
        local src="${script_root}/dotfiles/bash/bash_aliases"
        local dst="$HOME/.bash_aliases"

        if [[ -f "$dst" ]] && [[ "${BACKUP_EXISTING_CONFIGS:-true}" == "true" ]]; then
            backup_file "$dst"
        fi

        if run_cmd cp "$src" "$dst"; then
            run_cmd chmod 644 "$dst"
            log_ok "bash_aliases installed"
            ((installed++))
        fi
    fi

    # Bash logout
    if [[ "${INSTALL_BASH_LOGOUT:-true}" == "true" ]]; then
        log_info "Installing bash logout script..."
        local src="${script_root}/dotfiles/bash/bash_logout"
        local dst="$HOME/.bash_logout"

        if [[ -f "$dst" ]] && [[ "${BACKUP_EXISTING_CONFIGS:-true}" == "true" ]]; then
            backup_file "$dst"
        fi

        if run_cmd cp "$src" "$dst"; then
            run_cmd chmod 644 "$dst"
            log_ok "bash_logout installed"
            ((installed++))
        fi
    fi

    # Fortune login script
    if [[ "${INSTALL_FORTUNE_LOGIN:-true}" == "true" ]]; then
        log_info "Installing fortune login script..."
        local src="${script_root}/dotfiles/bash/profile.d/renstar_fortune.sh"
        local dst="/etc/profile.d/renstar_fortune.sh"

        if run_cmd sudo cp "$src" "$dst"; then
            run_cmd sudo chmod 755 "$dst"
            log_ok "Fortune login script installed"
            ((installed++))
        fi
    fi

    # Plan file
    log_info "Installing .plan file..."
    local src="${script_root}/dotfiles/misc/plan"
    local dst="$HOME/.plan"

    if [[ -f "$dst" ]] && [[ "${BACKUP_EXISTING_CONFIGS:-true}" == "true" ]]; then
        backup_file "$dst"
    fi

    if run_cmd cp "$src" "$dst"; then
        run_cmd chmod 644 "$dst"
        log_ok ".plan file installed"
        ((installed++))
    fi

    log_success "$installed dotfile(s) installed"
    log_info "Logout and login again to see changes"

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    install_dotfiles
fi
