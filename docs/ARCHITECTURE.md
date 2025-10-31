# Architecture Documentation

## Overview

Renstar SysAdmin uses a modular architecture with clear separation of concerns. This document describes the design principles and structure.

## Design Principles

1. **Modularity**: Each component has a single, well-defined responsibility
2. **Configuration-Driven**: Behavior controlled by config files, not code
3. **Reusability**: Modules can be used independently or combined
4. **Extensibility**: Easy to add new modules without modifying existing code
5. **Testability**: Each module can be tested in isolation

## Directory Structure

```
renstar-sysadmin/
├── install.sh              # Main installer orchestrator
├── maintenance.sh          # Maintenance orchestrator
├── system-monitor.sh       # Health monitoring tool
│
├── config/                 # Configuration layer
│   ├── default.conf        # Default configuration
│   └── profiles/           # Pre-built profiles
│
├── lib/                    # Shared libraries
│   ├── common.sh           # Utility functions
│   └── logging.sh          # Logging framework
│
├── modules/                # Pluggable modules
│   ├── packages/           # Package installation
│   ├── maintenance/        # Maintenance tasks
│   └── config/             # System configuration
│
├── dotfiles/               # User configuration files
└── docs/                   # Documentation
```

## Module System

### Package Modules

Located in `modules/packages/`, numbered for execution order:

- `00-core.sh` - Essential system utilities
- `10-monitoring.sh` - Monitoring tools
- `20-networking.sh` - Network utilities
- `30-security.sh` - Security packages
- `40-containers.sh` - Docker and container tools

### Maintenance Modules

Located in `modules/maintenance/`, numbered for execution order:

- `00-pre-checks.sh` - Pre-flight validation
- `10-apt-update.sh` - APT/Nala updates
- `20-snap-update.sh` - Snap package updates
- `60-system-cleanup.sh` - Cleanup tasks
- `80-service-updates.sh` - Service-specific updates
- `90-post-checks.sh` - Post-maintenance verification

### Configuration Modules

Located in `modules/config/`:

- `00-dotfiles.sh` - User configuration file deployment

## Configuration System

### Configuration Hierarchy

1. **Default Configuration** (`config/default.conf`)
   - Base settings for all installations
   - Defines all available options

2. **Profile Configuration** (`config/profiles/*.conf`)
   - Overrides defaults for specific use cases
   - Sources default.conf first, then overrides

3. **Custom Configuration** (user-created)
   - For per-host customization
   - Can source profiles or defaults

### Adding New Configuration Options

1. Define the option in `config/default.conf` with documentation
2. Use the option in relevant modules
3. Add to profile configurations as needed

## Adding New Modules

### Package Module

```bash
# Create new module
nano modules/packages/50-custom.sh

# Template:
#!/bin/bash
install_custom_packages() {
    log_section "Custom Package Installation"

    if [[ "${ENABLE_CUSTOM:-false}" != "true" ]]; then
        log_skip "Custom packages disabled"
        return 0
    fi

    local packages=("${PACKAGES_CUSTOM[@]}")

    run_cmd sudo apt install -y "${packages[@]}"

    log_success "Custom packages installed"
}

# Make executable
chmod +x modules/packages/50-custom.sh
```

### Maintenance Module

```bash
# Create new module
nano modules/maintenance/70-custom.sh

# Template:
#!/bin/bash
run_custom_maintenance() {
    log_section "Custom Maintenance"

    if [[ "${MAINTENANCE_CUSTOM:-false}" != "true" ]]; then
        log_skip "Custom maintenance disabled"
        return 0
    fi

    # Maintenance logic here

    log_success "Custom maintenance complete"
}

# Make executable
chmod +x modules/maintenance/70-custom.sh
```

## Library Functions

### common.sh

Provides utility functions:
- `command_exists` - Check if command is available
- `package_installed` - Check if package is installed
- `run_cmd` - Execute command (respects dry-run mode)
- `backup_file` - Backup file before modification
- `disk_space_check` - Verify adequate disk space
- `check_reboot_required` - Check if reboot needed

### logging.sh

Provides logging framework:
- `log_header` - Major section header
- `log_section` - Subsection header
- `log_ok` - Success message
- `log_warn` - Warning message
- `log_error` - Error message
- `log_info` - Informational message
- `log_debug` - Debug message (when verbose)

## Execution Flow

### Installation (install.sh)

1. Parse command-line arguments
2. Load configuration (default + profile/custom)
3. Load libraries
4. Display installation plan
5. Confirm with user (unless -y)
6. Execute package modules in order
7. Execute configuration modules in order
8. Display completion summary

### Maintenance (maintenance.sh)

1. Parse command-line arguments
2. Load configuration
3. Load libraries
4. Execute pre-checks
5. Execute maintenance modules in order
6. Execute post-checks
7. Display summary and reboot status

## Best Practices

1. **Always source libraries**: Every module should source common.sh and logging.sh
2. **Check configuration**: Respect ENABLE_* flags before doing work
3. **Use logging functions**: Never use raw echo, use log_* functions
4. **Handle errors gracefully**: Check return codes, provide useful error messages
5. **Support dry-run**: Use `run_cmd` for system-modifying commands
6. **Document configuration**: Add comments to config files
7. **Test independently**: Each module should work standalone for testing

## Future Enhancements

- [ ] Rollback capability for failed installations
- [ ] State tracking (what was installed when)
- [ ] Dependency management between modules
- [ ] Plugin system for third-party modules
- [ ] Web UI for configuration management
- [ ] Integration with Ansible/Salt/Chef
