#!/bin/bash
#
# Renstar SysAdmin - Main Maintenance Script
# Performs system updates and maintenance tasks
# Version: 2.1c
#

set -euo pipefail

VERSION="2.1c"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/default.conf"
PROFILE=""
START_TIME=$(date +%s)

# ============================================================================
# USAGE
# ============================================================================

usage() {
    cat << EOF
Renstar SysAdmin - System Maintenance Tool v${VERSION}

Usage: $0 [OPTIONS]

Options:
    -p, --profile PROFILE    Use a specific profile
    -c, --config FILE        Use custom configuration file
    --dry-run                Show what would be done without making changes
    -y, --yes                Skip confirmation prompts
    -v, --verbose            Verbose output
    -h, --help               Show this help message

Examples:
    $0                       Run standard maintenance
    $0 -p server             Run with server profile settings
    $0 --dry-run             Preview maintenance actions
    $0 -y                    Run without prompts (for cron)

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
        exit 1
    fi
fi

# Load libraries
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

# ============================================================================
# MAIN MAINTENANCE
# ============================================================================

main() {
    log_header "Renstar Global LLC - System Maintenance Utility v${VERSION}"

    log_info "Hostname: $(hostname)"
    log_info "Date: $(date)"

    if [[ -n "$PROFILE" ]]; then
        log_info "Profile: $PROFILE"
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
    fi

    # Create log directory
    create_log_dir

    # Run maintenance modules in order
    for module in "${SCRIPT_DIR}"/modules/maintenance/*.sh; do
        [[ -f "$module" ]] || continue

        local module_name=$(basename "$module" .sh)
        log_debug "Loading module: $module_name"

        source "$module"

        # Call the main function for each module
        case "$module_name" in
            00-pre-checks)
                run_pre_checks || {
                    log_error "Pre-checks failed - aborting maintenance"
                    exit 1
                }
                ;;
            10-apt-update)
                run_apt_update
                ;;
            20-snap-update)
                run_snap_update
                ;;
            60-system-cleanup)
                run_system_cleanup
                ;;
            80-service-updates)
                run_service_updates
                ;;
            90-post-checks)
                run_post_checks
                ;;
        esac
    done

    # Completion
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))

    log_header "Maintenance Complete"

    log_success "All maintenance tasks completed"
    log_info "Duration: ${duration} seconds"

    # Check if reboot is required
    if [[ -f /var/run/reboot-required ]]; then
        echo ""
        log_warn "╔════════════════════════════════════════════════════════════╗"
        log_warn "║  SYSTEM REBOOT REQUIRED                                    ║"
        log_warn "╚════════════════════════════════════════════════════════════╝"
        if [[ -f /var/run/reboot-required.pkgs ]]; then
            log_info "Packages requiring reboot:"
            cat /var/run/reboot-required.pkgs | sed 's/^/  - /'
        fi
    fi

    log_info ""
    log_info "Have a _____ day."
    echo ""
}

# Run main function
main
