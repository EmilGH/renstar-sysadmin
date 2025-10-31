#!/bin/bash
# Logging functions for Renstar SysAdmin
# Version: 2.1c

# Colors
if [[ "${COLOR_OUTPUT:-true}" == "true" ]]; then
    COLOR_RED='\033[0;31m'
    COLOR_YELLOW='\033[1;33m'
    COLOR_GREEN='\033[0;32m'
    COLOR_BLUE='\033[0;34m'
    COLOR_CYAN='\033[0;36m'
    COLOR_MAGENTA='\033[0;35m'
    COLOR_BOLD='\033[1m'
    COLOR_RESET='\033[0m'
else
    COLOR_RED=''
    COLOR_YELLOW=''
    COLOR_GREEN=''
    COLOR_BLUE=''
    COLOR_CYAN=''
    COLOR_MAGENTA=''
    COLOR_BOLD=''
    COLOR_RESET=''
fi

# Log level
LOG_LEVEL="${LOG_VERBOSITY:-normal}"

log_to_file() {
    local message="$1"
    local log_dir="${LOG_DIR:-/var/log/renstar-sysadmin}"
    local log_file="$log_dir/renstar-$(date +%Y-%m-%d).log"

    # Try system log directory first
    if [[ -d "$log_dir" ]] && [[ -w "$log_dir" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$log_file" 2>/dev/null || true
        return
    fi

    # Fallback to user's home directory
    local user_log_dir="$HOME/.local/share/renstar-sysadmin/logs"
    local user_log_file="$user_log_dir/renstar-$(date +%Y-%m-%d).log"

    if [[ ! -d "$user_log_dir" ]]; then
        mkdir -p "$user_log_dir" 2>/dev/null || return
    fi

    if [[ -w "$user_log_dir" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$user_log_file" 2>/dev/null || true
    fi
}

log_header() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}$1${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}================================================================================${COLOR_RESET}"
    echo ""
    log_to_file "HEADER: $1"
}

log_section() {
    echo ""
    echo -e "${COLOR_CYAN}>>> $1${COLOR_RESET}"
    log_to_file "SECTION: $1"
}

log_ok() {
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $1"
    log_to_file "OK: $1"
}

log_success() {
    echo -e "${COLOR_GREEN}✓ $1${COLOR_RESET}"
    log_to_file "SUCCESS: $1"
}

log_info() {
    echo -e "  $1"
    log_to_file "INFO: $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}⚠ $1${COLOR_RESET}"
    log_to_file "WARN: $1"
}

log_error() {
    echo -e "${COLOR_RED}✗ $1${COLOR_RESET}" >&2
    log_to_file "ERROR: $1"
}

log_debug() {
    if [[ "$LOG_LEVEL" == "debug" ]]; then
        echo -e "${COLOR_MAGENTA}[DEBUG] $1${COLOR_RESET}"
        log_to_file "DEBUG: $1"
    fi
}

log_skip() {
    if [[ "$LOG_LEVEL" != "quiet" ]]; then
        echo -e "${COLOR_CYAN}⊘ $1${COLOR_RESET}"
        log_to_file "SKIP: $1"
    fi
}

log_indent() {
    while IFS= read -r line; do
        echo "    $line"
    done
}

log_progress() {
    local current=$1
    local total=$2
    local item=$3
    echo -e "${COLOR_CYAN}[$current/$total]${COLOR_RESET} $item"
    log_to_file "PROGRESS: [$current/$total] $item"
}

log_command() {
    local cmd="$1"
    if [[ "$LOG_LEVEL" == "verbose" ]] || [[ "$LOG_LEVEL" == "debug" ]]; then
        echo -e "${COLOR_MAGENTA}↳ $cmd${COLOR_RESET}"
        log_to_file "CMD: $cmd"
    fi
}
