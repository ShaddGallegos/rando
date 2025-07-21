# Rando Scripts Collection

A collection of utility scripts for system administration, development environment setup, and various Linux/Windows automation tasks.

## 📁 Script Categories

### 🔧 System Setup & Configuration

#### `Install_Flatpak_And_VSCode.sh`
- **Purpose**: Installs Flatpak and Visual Studio Code, checks Red Hat Enterprise Linux 8 connectivity
- **Usage**: `./Install_Flatpak_And_VSCode.sh`
- **Dependencies**: DNF package manager, internet connection
- **Description**: Automatically installs Flatpak if not present, sets up Flathub repository, installs VS Code via Flatpak, and checks for RHEL8 CSB package availability

#### `Enable_Podman.sh`
- **Purpose**: Installs and configures Podman container engine with Ansible Core
- **Usage**: `./Enable_Podman.sh`
- **Dependencies**: DNF package manager, systemd
- **Description**: Installs Podman, starts and enables Podman socket service, and sets up Ansible Core for container management

#### `Fix_Podman_Rootless_Issues.sh`
- **Purpose**: Fixes Podman rootless configuration issues
- **Usage**: `./Fix_Podman_Rootless_Issues.sh [--dry-run] [--check-only]`
- **Options**:
  - `--dry-run`: Show what would be done without making changes
  - `--check-only`: Only check current configuration
- **Description**: Diagnoses and fixes common Podman rootless setup problems

#### `Apply_SELinux_Context_Fixes.sh`
- **Purpose**: Applies SELinux context fixes for common issues
- **Usage**: `./Apply_SELinux_Context_Fixes.sh`
- **Dependencies**: SELinux tools
- **Description**: Fixes SELinux contexts for various system components

### 🎨 Application Configuration

#### `Configure_LibreOffice_For_MS_Office_Formats.sh`
- **Purpose**: Configures LibreOffice to save documents in Microsoft Office formats by default
- **Usage**: `./Configure_LibreOffice_For_MS_Office_Formats.sh`
- **Dependencies**: xmlstarlet (automatically installed)
- **Description**: Modifies LibreOffice configuration to default to Word, Excel, and PowerPoint formats instead of ODF formats

#### `Install_Microsoft_Fonts.sh`
- **Purpose**: Installs Microsoft TrueType fonts on RHEL 9
- **Usage**: `./Install_Microsoft_Fonts.sh`
- **Dependencies**: EPEL repository, internet connection
- **Description**: Installs Microsoft fonts (Arial, Times New Roman, etc.) for better document compatibility

#### `Install_Missing_Fonts.sh`
- **Purpose**: Checks for missing fonts on RHEL 9 and installs them if needed
- **Usage**: `./Install_Missing_Fonts.sh`
- **Dependencies**: fontconfig, package manager (dnf/yum)
- **Description**: Comprehensive font checker that detects missing fonts and installs essential font packages including Liberation, DejaVu, GNU Free, Google Noto, international fonts, and emoji fonts. Skips on errors and provides detailed font statistics.

#### `Analyze_And_Fix_System_Errors.sh`
- **Purpose**: Analyzes system logs for common errors and attempts automated fixes
- **Usage**: `sudo ./Analyze_And_Fix_System_Errors.sh`
- **Dependencies**: journald or /var/log/messages, root privileges
- **Description**: Comprehensive system error analysis tool that scans logs for service failures, disk space issues, network problems, and memory issues. Automatically attempts fixes where possible and generates detailed reports. Supports both journald and traditional syslog.

#### `Set_VLC_As_Default_Media_Player.sh`
- **Purpose**: Sets VLC as the default media player
- **Usage**: `./Set_VLC_As_Default_Media_Player.sh`
- **Description**: Configures system to use VLC Media Player as default for media files

#### `Set_VSCode_As_Default_Text_Editor.sh`
- **Purpose**: Sets Visual Studio Code as the default text editor
- **Usage**: `./Set_VSCode_As_Default_Text_Editor.sh`
- **Description**: Configures system to use VS Code as default text editor

### 🗂️ File Organization & Management

#### `Find_and_move_iso.sh`
- **Purpose**: Finds and moves OS ISO files to organized storage location
- **Usage**: `./Find_and_move_iso.sh`
- **Dependencies**: None
- **Description**: Searches the entire system for operating system ISO files (RHEL, CentOS, Fedora, Ubuntu, Windows, etc.) and moves them to `/run/media/sgallego/SD_Card/OS/`. Filters out non-OS ISOs like application installers or games, only targeting legitimate operating system installation media.

#### `Copy_iso_files_back.sh`
- **Purpose**: Copies non-OS ISO files back from SD card to working locations
- **Usage**: `./Copy_iso_files_back.sh`
- **Dependencies**: None
- **Description**: Interactive script that copies back non-OS ISO files from the SD card storage, allowing you to choose destination folders for each file. Excludes OS ISOs to keep them organized on the SD card. Includes option to remove files from source after copying.

#### `Organize_package_files.sh`
- **Purpose**: Comprehensive package file organization system for RPM, DEB, and other installation files
- **Usage**: `./Organize_package_files.sh`
- **Dependencies**: None
- **Description**: Advanced file organization tool that searches `/run/media/sgallego/` for package files and organizes them into a structured hierarchy at `/run/media/sgallego/SD_Card/OS/`. Supports:
  - **RPM packages**: Organized by OS version (RHEL5-10, Fedora_Core30-44) and architecture (x86_64, noarch, aarch64, etc.)
  - **DEB packages**: Organized by distribution (Ubuntu, Debian, Mint) and architecture
  - **Windows installers**: EXE and MSI files organized by type
  - **Other formats**: Flatpak, Snap, AppImage, macOS packages, and compressed archives
  - **comps.xml handling**: Combines all comps.xml files into a single master file
  - **Cleanup**: Automatically removes empty directories after organization

### 🧹 Maintenance & Cleanup

#### `Remove_Unused_Scripts.sh`
- **Purpose**: Finds and removes unused scripts from the project
- **Usage**: `./Remove_Unused_Scripts.sh`
- **Description**: Scans for script references in build files and removes unreferenced scripts

#### `Remove_Dangling_Container_Images.sh`
- **Purpose**: Removes dangling container images
- **Usage**: `./Remove_Dangling_Container_Images.sh`
- **Description**: Cleans up unused Docker/Podman images to free disk space

#### `Remove_Container_Images_By_Tag.sh`
- **Purpose**: Removes container images with specific tags
- **Usage**: `./Remove_Container_Images_By_Tag.sh`
- **Description**: Removes container images matching specified tags

#### `Optimize_System_Performance.sh`
- **Purpose**: System optimization script
- **Usage**: `./Optimize_System_Performance.sh`
- **Description**: Performs various system optimizations

### 🔍 Monitoring & Diagnostics

#### `System_Resource_Monitor.sh`
- **Purpose**: System monitoring and alerting
- **Usage**: `./System_Resource_Monitor.sh`
- **Description**: Monitors system resources and provides alerts

#### `Fix_Git_Repository_Permissions.sh`
- **Purpose**: Fixes Git repository permissions
- **Usage**: `./Fix_Git_Repository_Permissions.sh`
- **Description**: Corrects file permissions in Git repositories

#### `Configure_HDMI_Display.sh`
- **Purpose**: HDMI display configuration
- **Usage**: `./Configure_HDMI_Display.sh`
- **Description**: Configures HDMI display settings

#### `Fix_Slack_Application_Issues.sh`
- **Purpose**: Fixes Slack application issues
- **Usage**: `./Fix_Slack_Application_Issues.sh`
- **Description**: Resolves common Slack application problems

### 🛠️ Development Tools

#### `Download_And_Convert_HTML_To_Markdown.py`
- **Purpose**: Downloads HTML content and converts to Markdown
- **Usage**: `python3 Download_And_Convert_HTML_To_Markdown.py`
- **Dependencies**: Python 3, required Python packages
- **Description**: Web scraping tool that converts HTML pages to Markdown format

#### `Python_System_Fixes.py`
- **Purpose**: Python-based system fix utility
- **Usage**: `python3 Python_System_Fixes.py`
- **Dependencies**: Python 3
- **Description**: Python script for various system fixes

#### `Display_Podman_Image_Information.py`
- **Purpose**: Displays detailed Podman image information
- **Usage**: `python3 Display_Podman_Image_Information.py`
- **Dependencies**: Python 3, Podman
- **Description**: Analyzes and displays comprehensive information about Podman images

#### `Launch_Tmux_Sessions_And_Wait.sh`
- **Purpose**: Launches tmux sessions and waits for completion
- **Usage**: `./Launch_Tmux_Sessions_And_Wait.sh`
- **Dependencies**: tmux
- **Description**: Manages tmux sessions with wait functionality

### 🪟 Windows Integration

#### `Fix_WSL_Network_Issues.ps1`
- **Purpose**: Fixes WSL networking issues on Windows
- **Usage**: PowerShell script for Windows systems
- **Dependencies**: Windows Subsystem for Linux (WSL)
- **Description**: Resolves common WSL networking problems

### 📋 Configuration Files

#### `Setup_ClamAV_Daemon.sh` & `Setup_ClamAV_Daemon_Alt.sh`
- **Purpose**: ClamAV daemon configuration scripts
- **Usage**: `./Setup_ClamAV_Daemon.sh` or `./Setup_ClamAV_Daemon_Alt.sh`
- **Dependencies**: ClamAV
- **Description**: Configure and manage ClamAV antivirus daemon

#### `Apply_General_System_Fixes.sh`
- **Purpose**: General system fix script
- **Usage**: `./Apply_General_System_Fixes.sh`
- **Description**: Applies various system fixes

#### `Push_Repository_To_GitHub.sh`
- **Purpose**: Git repository push automation
- **Usage**: `./Push_Repository_To_GitHub.sh`
- **Description**: Automates Git push operations to GitHub

### 📄 Documentation & Configuration

#### `site.yml` & `test.yml`
- **Purpose**: Ansible playbooks for system configuration
- **Usage**: `ansible-playbook site.yml` or `ansible-playbook test.yml`
- **Dependencies**: Ansible
- **Description**: Ansible playbooks for automated system setup and testing

#### `TOC_Inventory_of_Directory.yml`
- **Purpose**: Directory inventory in YAML format
- **Usage**: Reference file for directory structure
- **Description**: Maintains table of contents for directory organization

#### `Windows_Host_Config.md`
- **Purpose**: Windows host configuration documentation
- **Usage**: Reference document
- **Description**: Comprehensive guide for Windows host configuration

#### `imgui.ini`
- **Purpose**: ImGui configuration file
- **Usage**: Configuration file for ImGui applications
- **Description**: Settings for ImGui-based applications

#### `json`
- **Purpose**: Large JSON data file (20MB+)
- **Usage**: Data file for various applications
- **Description**: Contains JSON data for processing

## 🚀 Quick Start

1. **Make scripts executable**:
   ```bash
   chmod +x *.sh
   ```

2. **Run system setup**:
   ```bash
   ./Install_Flatpak_And_VSCode.sh
   ./Enable_Podman.sh
   ```

3. **Organize files and media**:
   ```bash
   ./Find_and_move_iso.sh              # Move OS ISOs to organized storage
   ./Organize_package_files.sh         # Organize RPM/DEB packages by OS and architecture
   ./Copy_iso_files_back.sh            # Copy non-OS ISOs back when needed
   ```

4. **Configure applications**:
   ```bash
   ./Configure_LibreOffice_For_MS_Office_Formats.sh
   ./Install_Microsoft_Fonts.sh
   ./Set_VSCode_As_Default_Text_Editor.sh
   ```

5. **System maintenance**:
   ```bash
   ./Remove_Unused_Scripts.sh
   ./Remove_Dangling_Container_Images.sh
   ```

## ⚠️ Prerequisites

- **Operating System**: Red Hat Enterprise Linux 9 / Fedora / CentOS
- **Package Manager**: DNF/YUM
- **Privileges**: Most scripts require sudo access
- **Network**: Internet connection for package downloads

## 📝 Notes

- Scripts are designed primarily for RHEL-based systems
- Some scripts automatically install dependencies
- Review scripts before running in production environments
- Most scripts include error handling and status messages

## 🤝 Contributing

Feel free to contribute improvements, bug fixes, or new scripts to this collection.

## 📜 License

These scripts are provided as-is for educational and administrative purposes.
