# Ansible Playbooks Collection

This directory contains Ansible playbooks that replicate and enhance the functionality of the bash, powershell, and python scripts in this repository.

## 📋 Available Playbooks

### 🚀 Main Entry Point
- **`main_system_setup.yml`** - Interactive master playbook with multiple setup modes

### 🔧 Development Environment
- **`ansible_dev_setup.yml`** - Complete Ansible development environment setup
- **`python_system_fixes.yml`** - Python-based system analysis and automated fixes

### 🧹 System Maintenance  
- **`analyze_and_fix_system_errors.yml`** - Comprehensive system error analysis and fixes
- **`container_image_manager.yml`** - Podman/Docker image cleanup and management
- **`font_installation_manager.yml`** - Complete font installation and management

### 📱 Applications
- **`install_flatpak_and_vscode.yml`** - Flatpak and VS Code installation
- **`podman_complete_setup.yml`** - Complete Podman container platform setup
- **`configure_libreoffice_msoffice.yml`** - LibreOffice MS Office format configuration

## 🎯 Quick Start

### Run Interactive Setup
```bash
ansible-playbook yaml/main_system_setup.yml
```

### Run Individual Playbooks
```bash
# Development environment
ansible-playbook yaml/ansible_dev_setup.yml

# System maintenance
ansible-playbook yaml/analyze_and_fix_system_errors.yml

# Application setup
ansible-playbook yaml/install_flatpak_and_vscode.yml
```

### Setup Modes
1. **Full Setup** - All components (development, maintenance, applications)
2. **Development Only** - Ansible and Python development tools
3. **System Maintenance** - Error analysis, cleanup, optimization
4. **Applications Only** - Flatpak, VS Code, Podman, LibreOffice
5. **Custom Selection** - Choose specific playbooks

## 🔍 Playbook Features

### Advanced Capabilities
- **Error Handling** - Graceful failure handling with detailed reporting
- **Idempotency** - Safe to run multiple times
- **Interactive Prompts** - User-guided configuration
- **Comprehensive Logging** - Detailed execution reports
- **Cross-Platform** - RHEL/CentOS/Fedora support
- **Automatic Cleanup** - Removes temporary files and optimizes system

### Enhanced Functionality
- **Parallel Execution** - Where possible for faster completion
- **Dependency Management** - Automatic prerequisite installation
- **Configuration Validation** - Verify successful setup
- **Rollback Support** - Undo problematic changes (where applicable)
- **Security Hardening** - Apply security best practices

## 📊 Monitoring and Reporting

Each playbook generates detailed reports including:
- Execution summary with timestamps
- Success/failure status for each task
- System information and statistics
- Recommendations for optimization
- Troubleshooting information

Reports are saved to `/var/log/` with descriptive filenames.

## 🔧 Prerequisites

```bash
# Install Ansible
sudo dnf install ansible-core

# Install required collections
ansible-galaxy collection install community.general
ansible-galaxy collection install containers.podman
```

## 🎛️ Customization

### Variables
Most playbooks support customization through variables:

```yaml
# Example: Custom Podman setup
ansible-playbook yaml/podman_complete_setup.yml -e "podman_user=myuser"

# Example: Custom font selection
ansible-playbook yaml/font_installation_manager.yml -e "install_ms_fonts=false"
```

### Tags
Use tags for selective execution:

```bash
# Only install packages, skip configuration
ansible-playbook yaml/ansible_dev_setup.yml --tags "packages"

# Only cleanup, skip analysis
ansible-playbook yaml/analyze_and_fix_system_errors.yml --tags "cleanup"
```

## 🔐 Security Notes

- Playbooks require root privileges for system-level changes
- Sensitive information (tokens, passwords) collected via encrypted prompts
- All downloaded content verified where possible
- Temporary files cleaned up automatically

## 🐛 Troubleshooting

### Common Issues
1. **Permission denied** - Ensure user has sudo access
2. **Collection not found** - Install required collections first
3. **Network timeouts** - Check internet connectivity
4. **Service failures** - Review individual task logs

### Debug Mode
```bash
ansible-playbook yaml/main_system_setup.yml -vvv
```

### Dry Run
```bash
ansible-playbook yaml/main_system_setup.yml --check --diff
```

## 📈 Advantages Over Shell Scripts

1. **Idempotency** - Safe to re-run without side effects
2. **Error Handling** - Robust failure recovery
3. **Reporting** - Comprehensive execution logs
4. **Modularity** - Mix and match functionality
5. **Scalability** - Can target multiple hosts
6. **Validation** - Built-in configuration verification
7. **Documentation** - Self-documenting YAML format
8. **Community** - Leverage Ansible Galaxy modules

## 🤝 Contributing

When adding new playbooks:
1. Follow existing naming conventions
2. Include comprehensive error handling
3. Add appropriate documentation
4. Test on clean systems
5. Update this README
