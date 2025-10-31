#!/bin/bash
#
# Renstar SysAdmin - Main Installation Script
# Installs packages and configures system based on profile
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/default.conf"
PROFILE=""
START_TIME=$(date +%s)

# ============================================================================
# USAGE
# ============================================================================

usage() {
    cat << EOF
Renstar SysAdmin - System Installation Tool

Usage: $0 [OPTIONS]

Options:
    -p, --profile PROFILE    Use a specific profile (minimal, server, docker-host, etc.)
    -c, --config FILE        Use custom configuration file
    --dry-run                Show what would be done without making changes
    -y, --yes                Skip confirmation prompts
    -v, --verbose            Verbose output
    -h, --help               Show this help message

Examples:
    $0                       Install with default configuration
    $0 -p server             Install with server profile
    $0 --dry-run             Preview what would be installed
    $0 -p minimal -y         Install minimal profile without prompts

Profiles:
    minimal                  Basic utilities only
    server                   Production server configuration
    docker-host              Container workload optimized

EOF
    exit 0
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes)
            UNATTENDED=true
            shift
            ;;
        -v|--verbose)
            LOG_VERBOSITY="verbose"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

# Load default configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Load profile if specified
if [[ -n "$PROFILE" ]]; then
    PROFILE_FILE="${SCRIPT_DIR}/config/profiles/${PROFILE}.conf"
    if [[ -f "$PROFILE_FILE" ]]; then
        source "$PROFILE_FILE"
    else
        echo "ERROR: Profile not found: $PROFILE"
        echo "Available profiles:"
        ls -1 "${SCRIPT_DIR}/config/profiles/" | sed 's/.conf$//' | sed 's/^/  /'
        exit 1
    fi
fi

# Load libraries
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

main() {
    log_header "Renstar Global LLC - System Installation Utility"

    if [[ -n "$PROFILE" ]]; then
        log_info "Profile: $PROFILE"
    fi
    log_info "Configuration: $CONFIG_FILE"
    log_info "Installation mode: ${INSTALL_MODE:-standard}"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
    fi

    # Show what will be installed
    log_section "Installation Plan"

    local install_count=0

    if [[ "${ENABLE_CORE_PACKAGES:-true}" == "true" ]]; then
        log_info "✓ Core packages (${#PACKAGES_CORE[@]} + ${#PACKAGES_MODERN_CLI[@]} packages)"
        ((install_count++))
    fi

    if [[ "${ENABLE_MONITORING:-false}" == "true" ]]; then
        log_info "✓ Monitoring tools (${#PACKAGES_MONITORING[@]} packages)"
        ((install_count++))
    fi

    if [[ "${ENABLE_NETWORKING:-false}" == "true" ]]; then
        log_info "✓ Networking tools (${#PACKAGES_NETWORKING[@]} packages)"
        ((install_count++))
    fi

    if [[ "${ENABLE_SECURITY:-false}" == "true" ]]; then
        log_info "✓ Security packages (${#PACKAGES_SECURITY[@]} packages)"
        ((install_count++))
    fi

    if [[ "${ENABLE_CONTAINERS:-false}" == "true" ]]; then
        log_info "✓ Container tools (${#PACKAGES_CONTAINERS[@]} packages)"
        ((install_count++))
    fi

    if [[ "${ENABLE_OPTIONAL:-false}" == "true" ]]; then
        log_info "✓ Optional packages (${#PACKAGES_OPTIONAL[@]} packages)"
        ((install_count++))
    fi

    if [[ "${INSTALL_BASH_ALIASES:-true}" == "true" ]]; then
        log_info "✓ Dotfiles configuration"
        ((install_count++))
    fi

    if [[ $install_count -eq 0 ]]; then
        log_error "No installation tasks enabled in configuration"
        exit 1
    fi

    # Confirmation prompt
    if [[ "${UNATTENDED:-false}" != "true" ]] && [[ "${DRY_RUN:-false}" != "true" ]]; then
        echo ""
        read -p "Proceed with installation? [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi

    # Create log directory
    create_log_dir

    # Run package installation modules
    log_header "Package Installation"

    for module in "${SCRIPT_DIR}"/modules/packages/*.sh; do
        [[ -f "$module" ]] || continue

        local module_name=$(basename "$module" .sh)
        log_debug "Loading module: $module_name"

        source "$module"

        # Call the main function (convention: install_<category>_packages)
        case "$module_name" in
            00-core)
                install_core_packages
                ;;
            10-monitoring)
                install_monitoring_packages
                ;;
            20-networking)
                install_networking_packages
                ;;
            30-security)
                install_security_packages
                ;;
            40-containers)
                install_container_packages
                ;;
        esac
    done

    # Run configuration modules
    log_header "System Configuration"

    for module in "${SCRIPT_DIR}"/modules/config/*.sh; do
        [[ -f "$module" ]] || continue

        local module_name=$(basename "$module" .sh)
        log_debug "Loading module: $module_name"

        source "$module"

        case "$module_name" in
            00-dotfiles)
                install_dotfiles
                ;;
        esac
    done

    # Completion
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    log_header "Installation Complete"

    log_success "Installation finished successfully"
    log_info "Duration: ${duration} seconds"

    # Post-installation notes
    if [[ "${ENABLE_SECURITY:-false}" == "true" ]]; then
        echo ""
        log_warn "IMPORTANT: Security packages installed but NOT enabled"
        log_info "See README.md section 'Post-Installation Next Steps' for:"
        log_info "  - Configuring and enabling fail2ban"
        log_info "  - Setting up UFW firewall"
        log_info "  - Enabling automatic security updates"
        log_info "  - SSH hardening steps"
    fi

    log_info ""
    log_info "Have a _____ day."
    echo ""
}

# Run main function
main
