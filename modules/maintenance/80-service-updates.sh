#!/bin/bash
# Service-Specific Updates (Plex, Pi-hole, Homebridge, etc.)

run_service_updates() {
    log_section "Service-Specific Updates"

    local updated=0

    # Plex Media Server
    if [[ "${SERVICE_PLEX_ENABLED:-true}" == "true" ]] && [[ -f "/opt/Plex-Updater/update-plex.sh" ]]; then
        log_info "Updating Plex Media Server..."
        log_command "/opt/Plex-Updater/update-plex.sh"
        if run_cmd sudo /opt/Plex-Updater/update-plex.sh; then
            log_success "Plex update complete"
            ((updated++))
        else
            log_warn "Plex update failed or not needed"
        fi
    fi

    # Pi-hole
    if [[ "${SERVICE_PIHOLE_ENABLED:-true}" == "true" ]] && [[ -f "/usr/local/bin/pihole" ]]; then
        log_info "Updating Pi-hole..."
        log_command "pihole -up"
        if run_cmd sudo /usr/local/bin/pihole -up; then
            log_success "Pi-hole update complete"
            ((updated++))
        else
            log_warn "Pi-hole update failed or not needed"
        fi
    fi

    # Homebridge
    if [[ "${SERVICE_HOMEBRIDGE_ENABLED:-true}" == "true" ]] && [[ -f "/usr/local/bin/hb-service" ]]; then
        log_info "Updating Homebridge Node.js..."
        log_command "hb-service update-node"
        if run_cmd sudo /usr/local/bin/hb-service update-node; then
            log_success "Homebridge Node update complete"
            ((updated++))
        else
            log_warn "Homebridge update failed or not needed"
        fi
    fi

    if [[ $updated -eq 0 ]]; then
        log_info "No service-specific updates needed"
    else
        log_success "$updated service(s) updated"
    fi

    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/../../lib/common.sh"
    source "${SCRIPT_DIR}/../../lib/logging.sh"
    source "${SCRIPT_DIR}/../../config/default.conf" 2>/dev/null || true

    run_service_updates
fi
