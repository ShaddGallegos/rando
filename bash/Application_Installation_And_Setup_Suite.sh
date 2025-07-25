#!/bin/bash

# Application Installation And Setup Suite
# Comprehensive application installation, configuration, and setup toolkit
# Consolidates: Install_Flatpak_And_VSCode.sh, Font_Installation_Manager.sh, Configure_LibreOffice_For_MS_Office_Formats.sh, 
#              Podman_Complete_Setup.sh, Container_Image_Manager.sh, install_common_tools.sh

set -euo pipefail

LOG_FILE="$HOME/application_setup_$(date +'%Y%m%d_%H%M%S').log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo
    echo
    echo
    echo
    echo ""
}

show_main_menu() {
    echo
    echo ""
    echo " DEVELOPMENT TOOLS:"
    echo "1.  Install VS Code & Extensions"
    echo "2.  Setup Flatpak & Applications"
    echo "3.  Complete Podman & Container Setup"
    echo "4.   Install Common Development Tools"
    echo ""
    echo " PRODUCTIVITY & MEDIA:"
    echo "5.  Configure LibreOffice for MS Office"
    echo "6.  Font Installation & Management"
    echo "7.  Multimedia Tools Setup"
    echo "8.   Graphics & Design Tools"
    echo ""
    echo " CONTAINER MANAGEMENT:"
    echo "9.  Container Image Manager"
    echo "10.  Container Registry Setup"
    echo "11.  Container Development Environment"
    echo "12.  Container Troubleshooting Tools"
    echo ""
    echo "  SYSTEM INTEGRATION:"
    echo "13.  Application Desktop Integration"
    echo "14.  Custom Application Profiles"
    echo "15.  Application Backup & Restore"
    echo "16.  Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

check_dependencies() {
    local deps=("$@")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
        return 1
    fi
    return 0
}

install_package() {
    local package="$1"
    local package_manager=""
    
    # Detect package manager
    if command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    elif command -v apt >/dev/null 2>&1; then
        package_manager="apt"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
    else
        log "${RED}No supported package manager found${NC}"
        return 1
    fi
    
    log "Installing $package using $package_manager..."
    
    case $package_manager in
        dnf|yum)
            sudo $package_manager install -y "$package" 2>&1 | tee -a "$LOG_FILE"
            ;;
        apt)
            sudo apt update && sudo apt install -y "$package" 2>&1 | tee -a "$LOG_FILE"
            ;;
        zypper)
            sudo zypper install -y "$package" 2>&1 | tee -a "$LOG_FILE"
            ;;
    esac
}

# ===== DEVELOPMENT TOOLS =====

install_vscode_extensions() {
    log "${BLUE}=== Installing VS Code & Extensions ===${NC}"
    
    # Install VS Code
    if ! command -v code >/dev/null 2>&1; then
        log "Installing Visual Studio Code..."
        
        # Add Microsoft repository
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
        
        install_package "code"
    else
        log "VS Code already installed"
    fi
    
    # Essential extensions
    local extensions=(
        "ms-python.python"
        "ms-vscode.cpptools"
        "redhat.vscode-yaml"
        "ms-vscode.vscode-json"
        "formulahendry.code-runner"
        "ms-vscode.hexeditor"
        "streetsidesoftware.code-spell-checker"
        "ms-vsliveshare.vsliveshare"
        "github.copilot"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode.powershell"
        "redhat.ansible"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-azuretools.vscode-docker"
        "golang.go"
        "rust-lang.rust-analyzer"
    )
    
    echo "Select extensions to install:"
    echo "1. Essential Development Pack (Python, C++, YAML, JSON)"
    echo "2. DevOps Pack (Ansible, Kubernetes, Docker)"
    echo "3. Language Pack (Go, Rust, PowerShell)"
    echo "4. All extensions"
    echo "5. Custom selection"
    read -p "Choose option (1-5): " ext_choice
    
    local selected_extensions=()
    
    case $ext_choice in
        1) selected_extensions=("${extensions[@]:0:8}") ;;
        2) selected_extensions=("${extensions[@]:11:3}") ;;
        3) selected_extensions=("${extensions[@]:14:3}") ;;
        4) selected_extensions=("${extensions[@]}") ;;
        5)
            echo "Available extensions:"
            for i in "${!extensions[@]}"; do
                echo "$((i+1)). ${extensions[i]}"
            done
            read -p "Enter extension numbers (comma-separated): " custom_nums
            IFS=',' read -ra nums <<< "$custom_nums"
            for num in "${nums[@]}"; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#extensions[@]} ]; then
                    selected_extensions+=("${extensions[$((num-1))]}")
                fi
            done
            ;;
    esac
    
    # Install selected extensions
    for extension in "${selected_extensions[@]}"; do
        log "Installing extension: $extension"
        code --install-extension "$extension" 2>&1 | tee -a "$LOG_FILE" || true
    done
    
    # Configure VS Code settings
    local vscode_settings_dir="$HOME/.config/Code/User"
    mkdir -p "$vscode_settings_dir"
    
    cat > "$vscode_settings_dir/settings.json" << EOF
{
    "editor.fontSize": 14,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.wordWrap": "on",
    "files.autoSave": "afterDelay",
    "terminal.integrated.fontSize": 12,
    "workbench.colorTheme": "Default Dark+",
    "python.defaultInterpreterPath": "/usr/bin/python3",
    "editor.minimap.enabled": false,
    "git.autofetch": true,
    "editor.formatOnSave": true
}
EOF
    
    log "${GREEN}VS Code installation and configuration completed${NC}"
}

setup_flatpak_applications() {
    log "${BLUE}=== Setting up Flatpak & Applications ===${NC}"
    
    # Install Flatpak
    if ! command -v flatpak >/dev/null 2>&1; then
        log "Installing Flatpak..."
        install_package "flatpak"
    else
        log "Flatpak already installed"
    fi
    
    # Add Flathub repository
    log "Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Essential Flatpak applications
    local flatpak_apps=(
        "org.mozilla.firefox"
        "org.chromium.Chromium"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
        "org.blender.Blender"
        "com.spotify.Client"
        "com.discordapp.Discord"
        "org.telegram.desktop"
        "org.videolan.VLC"
        "org.audacityteam.Audacity"
        "com.obsproject.Studio"
        "org.inkscape.Inkscape"
        "com.github.johnfactotum.Foliate"
        "org.signal.Signal"
        "com.slack.Slack"
    )
    
    echo "Select application categories to install:"
    echo "1. Browsers (Firefox, Chromium)"
    echo "2. Office Suite (LibreOffice)"
    echo "3. Media & Graphics (GIMP, Blender, VLC, Audacity)"
    echo "4. Communication (Discord, Telegram, Signal, Slack)"
    echo "5. All applications"
    echo "6. Custom selection"
    read -p "Choose option (1-6): " app_choice
    
    local selected_apps=()
    
    case $app_choice in
        1) selected_apps=("${flatpak_apps[@]:0:2}") ;;
        2) selected_apps=("${flatpak_apps[@]:2:1}") ;;
        3) selected_apps=("${flatpak_apps[@]:3:5}") ;;
        4) selected_apps=("${flatpak_apps[@]:8:4}") ;;
        5) selected_apps=("${flatpak_apps[@]}") ;;
        6)
            echo "Available applications:"
            for i in "${!flatpak_apps[@]}"; do
                echo "$((i+1)). ${flatpak_apps[i]}"
            done
            read -p "Enter application numbers (comma-separated): " custom_nums
            IFS=',' read -ra nums <<< "$custom_nums"
            for num in "${nums[@]}"; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#flatpak_apps[@]} ]; then
                    selected_apps+=("${flatpak_apps[$((num-1))]}")
                fi
            done
            ;;
    esac
    
    # Install selected applications
    for app in "${selected_apps[@]}"; do
        log "Installing Flatpak application: $app"
        flatpak install -y flathub "$app" 2>&1 | tee -a "$LOG_FILE" || true
    done
    
    # Update Flatpak applications
    log "Updating Flatpak applications..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE" || true
    
    log "${GREEN}Flatpak setup completed${NC}"
}

complete_podman_setup() {
    log "${BLUE}=== Complete Podman & Container Setup ===${NC}"
    
    # Install Podman and related tools
    local podman_packages=(
        "podman"
        "podman-compose"
        "buildah"
        "skopeo"
        "podman-desktop"
        "crun"
        "slirp4netns"
        "fuse-overlayfs"
    )
    
    log "Installing Podman and container tools..."
    for package in "${podman_packages[@]}"; do
        install_package "$package" || log "${YELLOW}Failed to install $package${NC}"
    done
    
    # Configure Podman for rootless containers
    log "Configuring rootless containers..."
    
    # Set up subuid and subgid
    if ! grep -q "^$USER:" /etc/subuid; then
        echo "$USER:100000:65536" | sudo tee -a /etc/subuid >/dev/null
    fi
    
    if ! grep -q "^$USER:" /etc/subgid; then
        echo "$USER:100000:65536" | sudo tee -a /etc/subgid >/dev/null
    fi
    
    # Configure storage
    mkdir -p "$HOME/.config/containers"
    
    cat > "$HOME/.config/containers/storage.conf" << EOF
[storage]
driver = "overlay"
runroot = "/run/user/$(id -u)"
graphroot = "$HOME/.local/share/containers/storage"

[storage.options]
additionalimagestores = [
]

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF
    
    # Configure registries
    cat > "$HOME/.config/containers/registries.conf" << EOF
[registries.search]
registries = ['docker.io', 'registry.fedoraproject.org', 'quay.io', 'registry.access.redhat.com']

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF
    
    # Enable Podman socket for Docker compatibility
    systemctl --user enable --now podman.socket 2>/dev/null || true
    
    # Test Podman installation
    log "Testing Podman installation..."
    if podman run --rm hello-world 2>&1 | tee -a "$LOG_FILE"; then
        log "${GREEN}Podman test successful${NC}"
    else
        log "${YELLOW}Podman test failed - may need manual troubleshooting${NC}"
    fi
    
    # Install container development tools
    log "Installing container development tools..."
    install_package "docker-compose" || true
    
    # Create useful aliases
    local bashrc_file="$HOME/.bashrc"
    if [ -f "$bashrc_file" ]; then
        if ! grep -q "# Podman aliases" "$bashrc_file"; then
            cat >> "$bashrc_file" << EOF

# Podman aliases
alias docker='podman'
alias docker-compose='podman-compose'
alias dps='podman ps'
alias dimg='podman images'
alias dlog='podman logs'
alias dexec='podman exec -it'
EOF
            log "Added Podman aliases to .bashrc"
        fi
    fi
    
    log "${GREEN}Podman setup completed${NC}"
}

install_common_development_tools() {
    log "${BLUE}=== Installing Common Development Tools ===${NC}"
    
    # Development tools categories
    local base_tools=(
        "git" "curl" "wget" "vim" "nano" "tree" "htop" "tmux" "screen"
        "unzip" "zip" "tar" "rsync" "which" "file" "lsof" "strace"
    )
    
    local programming_tools=(
        "gcc" "g++" "make" "cmake" "autoconf" "automake" "libtool"
        "python3" "python3-pip" "nodejs" "npm" "golang" "rust" "cargo"
    )
    
    local network_tools=(
        "nmap" "netcat" "telnet" "wireshark" "tcpdump" "iperf3"
        "mtr" "dig" "host" "whois" "traceroute"
    )
    
    local system_tools=(
        "systemd-tools" "util-linux" "procps-ng" "psmisc" "bind-utils"
        "net-tools" "iproute" "iotop" "sysstat" "perf"
    )
    
    echo "Select tool categories to install:"
    echo "1. Base Tools (git, curl, vim, htop, etc.)"
    echo "2. Programming Tools (gcc, python, node, go, rust)"
    echo "3. Network Tools (nmap, wireshark, tcpdump, etc.)"
    echo "4. System Tools (systemd, performance monitoring)"
    echo "5. All tools"
    echo "6. Custom selection"
    read -p "Choose option (1-6): " tools_choice
    
    local selected_tools=()
    
    case $tools_choice in
        1) selected_tools=("${base_tools[@]}") ;;
        2) selected_tools=("${programming_tools[@]}") ;;
        3) selected_tools=("${network_tools[@]}") ;;
        4) selected_tools=("${system_tools[@]}") ;;
        5) selected_tools=("${base_tools[@]}" "${programming_tools[@]}" "${network_tools[@]}" "${system_tools[@]}") ;;
        6)
            echo "Available tool categories:"
            echo "1. Base Tools"
            echo "2. Programming Tools"
            echo "3. Network Tools"
            echo "4. System Tools"
            read -p "Enter category numbers (comma-separated): " custom_cats
            IFS=',' read -ra cats <<< "$custom_cats"
            for cat in "${cats[@]}"; do
                case $cat in
                    1) selected_tools+=("${base_tools[@]}") ;;
                    2) selected_tools+=("${programming_tools[@]}") ;;
                    3) selected_tools+=("${network_tools[@]}") ;;
                    4) selected_tools+=("${system_tools[@]}") ;;
                esac
            done
            ;;
    esac
    
    # Install selected tools
    log "Installing selected development tools..."
    for tool in "${selected_tools[@]}"; do
        log "Installing: $tool"
        install_package "$tool" || log "${YELLOW}Failed to install $tool${NC}"
    done
    
    # Set up Python development environment
    if command -v python3 >/dev/null 2>&1; then
        log "Setting up Python development environment..."
        python3 -m pip install --user --upgrade pip setuptools wheel virtualenv pipenv poetry black flake8 pytest
    fi
    
    # Set up Node.js development environment
    if command -v npm >/dev/null 2>&1; then
        log "Setting up Node.js development environment..."
        npm install -g yarn typescript eslint prettier nodemon pm2
    fi
    
    log "${GREEN}Development tools installation completed${NC}"
}

# ===== PRODUCTIVITY & MEDIA =====

configure_libreoffice_ms_office() {
    log "${BLUE}=== Configuring LibreOffice for MS Office Compatibility ===${NC}"
    
    # Install LibreOffice if not present
    if ! command -v libreoffice >/dev/null 2>&1; then
        log "Installing LibreOffice..."
        install_package "libreoffice"
    fi
    
    # Install MS Office compatibility fonts
    log "Installing MS Office compatible fonts..."
    local font_packages=(
        "liberation-fonts"
        "dejavu-fonts-common"
        "google-noto-fonts"
        "google-noto-serif-fonts"
        "google-noto-sans-fonts"
    )
    
    for font_package in "${font_packages[@]}"; do
        install_package "$font_package" || true
    done
    
    # Configure LibreOffice settings
    local libreoffice_config_dir="$HOME/.config/libreoffice/4/user"
    mkdir -p "$libreoffice_config_dir"
    
    # Set default document formats to MS Office
    cat > "$libreoffice_config_dir/registrymodifications.xcu" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <item oor:path="/org.openoffice.Office.Common/Save/Document">
    <prop oor:name="WarnAlienFormat" oor:op="fuse">
      <value>false</value>
    </prop>
  </item>
  <item oor:path="/org.openoffice.Office.Writer/Layout/Other">
    <prop oor:name="MeasureUnit" oor:op="fuse">
      <value>2</value>
    </prop>
  </item>
</oor:items>
EOF
    
    # Install additional language packs and spell checkers
    log "Installing language support..."
    local lang_packages=(
        "libreoffice-langpack-en"
        "hunspell-en-US"
        "hyphen-en"
        "mythes-en"
    )
    
    for lang_package in "${lang_packages[@]}"; do
        install_package "$lang_package" || true
    done
    
    # Configure auto-save and recovery
    local backup_dir="$HOME/Documents/LibreOffice_Backups"
    mkdir -p "$backup_dir"
    
    log "LibreOffice configuration tips:"
    log "1. Set Tools > Options > Load/Save > General > Always create backup copy"
    log "2. Set Tools > Options > Load/Save > Microsoft Office > Load/Save Microsoft Office formats"
    log "3. Consider installing additional fonts for better compatibility"
    
    log "${GREEN}LibreOffice MS Office compatibility configuration completed${NC}"
}

font_installation_management() {
    log "${BLUE}=== Font Installation & Management ===${NC}"
    
    echo "Font management options:"
    echo "1. Install essential font packages"
    echo "2. Install Windows fonts (if available)"
    echo "3. Install Google Fonts collection"
    echo "4. Install development/coding fonts"
    echo "5. Custom font installation"
    echo "6. Font cache management"
    read -p "Choose option (1-6): " font_choice
    
    case $font_choice in
        1)
            log "Installing essential font packages..."
            local essential_fonts=(
                "liberation-fonts"
                "dejavu-fonts-common"
                "dejavu-sans-fonts"
                "dejavu-serif-fonts"
                "dejavu-sans-mono-fonts"
                "google-noto-fonts-common"
                "google-noto-sans-fonts"
                "google-noto-serif-fonts"
                "google-noto-emoji-fonts"
            )
            
            for font in "${essential_fonts[@]}"; do
                install_package "$font" || true
            done
            ;;
        2)
            log "Setting up Windows fonts installation..."
            echo "To install Windows fonts:"
            echo "1. Copy fonts from Windows system (C:\\Windows\\Fonts\\)"
            echo "2. Or download from: https://github.com/corefonts/corefonts"
            echo "3. Place fonts in: $HOME/.local/share/fonts/"
            
            local windows_fonts_dir="$HOME/.local/share/fonts/windows"
            mkdir -p "$windows_fonts_dir"
            
            echo "Would you like to download core Windows fonts? (y/N)"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Download core fonts
                local core_fonts=(
                    "https://downloads.sourceforge.net/corefonts/andale32.exe"
                    "https://downloads.sourceforge.net/corefonts/arial32.exe"
                    "https://downloads.sourceforge.net/corefonts/arialb32.exe"
                    "https://downloads.sourceforge.net/corefonts/comic32.exe"
                    "https://downloads.sourceforge.net/corefonts/courie32.exe"
                    "https://downloads.sourceforge.net/corefonts/georgi32.exe"
                    "https://downloads.sourceforge.net/corefonts/impact32.exe"
                    "https://downloads.sourceforge.net/corefonts/times32.exe"
                    "https://downloads.sourceforge.net/corefonts/trebuc32.exe"
                    "https://downloads.sourceforge.net/corefonts/verdan32.exe"
                    "https://downloads.sourceforge.net/corefonts/webdin32.exe"
                )
                
                install_package "cabextract" || true
                
                for font_url in "${core_fonts[@]}"; do
                    local font_file=$(basename "$font_url")
                    log "Downloading $font_file..."
                    wget -q "$font_url" -O "/tmp/$font_file"
                    cabextract -d "$windows_fonts_dir" "/tmp/$font_file"
                    rm "/tmp/$font_file"
                done
            fi
            ;;
        3)
            log "Installing Google Fonts collection..."
            local google_fonts=(
                "google-roboto-fonts"
                "google-opensans-fonts"
                "google-lato-fonts"
                "google-sourcesanspro-fonts"
                "google-montserrat-fonts"
                "google-oswald-fonts"
            )
            
            for font in "${google_fonts[@]}"; do
                install_package "$font" || true
            done
            ;;
        4)
            log "Installing development/coding fonts..."
            local coding_fonts_dir="$HOME/.local/share/fonts/coding"
            mkdir -p "$coding_fonts_dir"
            
            # Popular coding fonts
            local coding_fonts=(
                "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono.zip"
                "https://github.com/microsoft/cascadia-code/releases/latest/download/CascadiaCode.zip"
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
            )
            
            for font_url in "${coding_fonts[@]}"; do
                local font_name=$(basename "$font_url" .zip)
                log "Installing $font_name..."
                wget -q "$font_url" -O "/tmp/$font_name.zip"
                unzip -q "/tmp/$font_name.zip" -d "$coding_fonts_dir/$font_name/"
                rm "/tmp/$font_name.zip"
            done
            ;;
        5)
            read -p "Enter path to font file or directory: " custom_font_path
            if [ -f "$custom_font_path" ] || [ -d "$custom_font_path" ]; then
                local user_fonts_dir="$HOME/.local/share/fonts/custom"
                mkdir -p "$user_fonts_dir"
                cp -r "$custom_font_path" "$user_fonts_dir/"
                log "Custom font(s) installed"
            else
                log "${RED}Font path not found${NC}"
            fi
            ;;
        6)
            log "Managing font cache..."
            fc-cache -fv
            log "Font cache rebuilt"
            log "Available fonts: $(fc-list | wc -l)"
            ;;
    esac
    
    # Rebuild font cache after installation
    log "Rebuilding font cache..."
    fc-cache -fv >/dev/null 2>&1
    
    log "${GREEN}Font management completed${NC}"
}

multimedia_tools_setup() {
    log "${BLUE}=== Multimedia Tools Setup ===${NC}"
    
    echo "Select multimedia categories:"
    echo "1. Audio tools (Audacity, LAME, FFmpeg)"
    echo "2. Video tools (VLC, OBS Studio, HandBrake)"
    echo "3. Graphics tools (GIMP, Inkscape, Krita)"
    echo "4. Photography tools (RawTherapee, Darktable)"
    echo "5. All multimedia tools"
    read -p "Choose option (1-5): " media_choice
    
    local audio_tools=("audacity" "lame" "ffmpeg" "pulseaudio-utils" "alsa-utils")
    local video_tools=("vlc" "obs-studio" "handbrake-gui" "kdenlive" "openshot")
    local graphics_tools=("gimp" "inkscape" "krita" "blender" "scribus")
    local photo_tools=("rawtherapee" "darktable" "luminance-hdr" "hugin")
    
    local selected_tools=()
    
    case $media_choice in
        1) selected_tools=("${audio_tools[@]}") ;;
        2) selected_tools=("${video_tools[@]}") ;;
        3) selected_tools=("${graphics_tools[@]}") ;;
        4) selected_tools=("${photo_tools[@]}") ;;
        5) selected_tools=("${audio_tools[@]}" "${video_tools[@]}" "${graphics_tools[@]}" "${photo_tools[@]}") ;;
    esac
    
    # Install multimedia codecs
    log "Installing multimedia codecs..."
    local codec_packages=(
        "ffmpeg"
        "gstreamer1-plugins-base"
        "gstreamer1-plugins-good"
        "gstreamer1-plugins-bad-free"
        "gstreamer1-plugins-ugly"
        "gstreamer1-libav"
    )
    
    for codec in "${codec_packages[@]}"; do
        install_package "$codec" || true
    done
    
    # Install selected tools
    for tool in "${selected_tools[@]}"; do
        log "Installing: $tool"
        install_package "$tool" || log "${YELLOW}Failed to install $tool${NC}"
    done
    
    # Configure multimedia settings
    log "Configuring multimedia settings..."
    
    # PulseAudio configuration
    if command -v pulseaudio >/dev/null 2>&1; then
        log "Configuring PulseAudio for better audio quality..."
        local pulse_config="$HOME/.config/pulse/daemon.conf"
        mkdir -p "$(dirname "$pulse_config")"
        
        cat > "$pulse_config" << EOF
# High-quality audio configuration
default-sample-format = float32le
default-sample-rate = 48000
alternate-sample-rate = 44100
default-sample-channels = 2
default-channel-map = front-left,front-right
resample-method = speex-float-5
enable-lfe-remixing = no
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 5
rlimit-rtprio = 9
daemonize = yes
EOF
    fi
    
    log "${GREEN}Multimedia tools setup completed${NC}"
}

graphics_design_tools() {
    log "${BLUE}=== Graphics & Design Tools Setup ===${NC}"
    
    echo "Select design tool categories:"
    echo "1. Vector Graphics (Inkscape, LibreDraw)"
    echo "2. Raster Graphics (GIMP, Krita)"
    echo "3. 3D Modeling (Blender, FreeCAD)"
    echo "4. CAD Tools (FreeCAD, LibreCAD, QCAD)"
    echo "5. Desktop Publishing (Scribus, LibreOffice Draw)"
    echo "6. All design tools"
    read -p "Choose option (1-6): " design_choice
    
    local vector_tools=("inkscape" "libreoffice-draw")
    local raster_tools=("gimp" "krita" "mypaint")
    local modeling_tools=("blender" "freecad" "meshlab")
    local cad_tools=("freecad" "librecad" "qcad")
    local publishing_tools=("scribus" "libreoffice-draw")
    
    local selected_tools=()
    
    case $design_choice in
        1) selected_tools=("${vector_tools[@]}") ;;
        2) selected_tools=("${raster_tools[@]}") ;;
        3) selected_tools=("${modeling_tools[@]}") ;;
        4) selected_tools=("${cad_tools[@]}") ;;
        5) selected_tools=("${publishing_tools[@]}") ;;
        6) selected_tools=("${vector_tools[@]}" "${raster_tools[@]}" "${modeling_tools[@]}" "${cad_tools[@]}" "${publishing_tools[@]}") ;;
    esac
    
    # Install selected tools
    for tool in "${selected_tools[@]}"; do
        log "Installing: $tool"
        install_package "$tool" || log "${YELLOW}Failed to install $tool${NC}"
    done
    
    # Install additional graphics libraries
    log "Installing graphics libraries and plugins..."
    local graphics_libs=(
        "ImageMagick"
        "GraphicsMagick"
        "potrace"
        "optipng"
        "jpegoptim"
        "webp-tools"
    )
    
    for lib in "${graphics_libs[@]}"; do
        install_package "$lib" || true
    done
    
    # Configure GIMP plugins directory
    local gimp_plugins_dir="$HOME/.config/GIMP/2.10/plug-ins"
    mkdir -p "$gimp_plugins_dir"
    
    log "${GREEN}Graphics & design tools setup completed${NC}"
}

# ===== CONTAINER MANAGEMENT =====

container_image_manager() {
    log "${BLUE}=== Container Image Manager ===${NC}"
    
    if ! command -v podman >/dev/null 2>&1; then
        log "${RED}Podman not installed. Please install Podman first.${NC}"
        return 1
    fi
    
    echo "Container Image Management Options:"
    echo "1. List all images"
    echo "2. Pull popular images"
    echo "3. Clean unused images"
    echo "4. Export/Import images"
    echo "5. Image security scanning"
    echo "6. Registry management"
    read -p "Choose option (1-6): " image_choice
    
    case $image_choice in
        1)
            log "Listing all container images..."
            podman images | tee -a "$LOG_FILE"
            echo ""
            log "Image usage summary:"
            podman system df | tee -a "$LOG_FILE"
            ;;
        2)
            log "Pulling popular container images..."
            local popular_images=(
                "registry.fedoraproject.org/fedora:latest"
                "docker.io/library/ubuntu:latest"
                "docker.io/library/alpine:latest"
                "docker.io/library/nginx:latest"
                "docker.io/library/httpd:latest"
                "docker.io/library/mysql:latest"
                "docker.io/library/postgres:latest"
                "docker.io/library/redis:latest"
                "docker.io/library/node:latest"
                "docker.io/library/python:latest"
            )
            
            echo "Select images to pull:"
            for i in "${!popular_images[@]}"; do
                echo "$((i+1)). ${popular_images[i]}"
            done
            echo "$((${#popular_images[@]}+1)). All images"
            read -p "Enter image numbers (comma-separated): " image_nums
            
            if [ "$image_nums" = "$((${#popular_images[@]}+1))" ]; then
                # Pull all images
                for image in "${popular_images[@]}"; do
                    log "Pulling $image..."
                    podman pull "$image" 2>&1 | tee -a "$LOG_FILE" || true
                done
            else
                IFS=',' read -ra nums <<< "$image_nums"
                for num in "${nums[@]}"; do
                    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#popular_images[@]} ]; then
                        local image="${popular_images[$((num-1))]}"
                        log "Pulling $image..."
                        podman pull "$image" 2>&1 | tee -a "$LOG_FILE" || true
                    fi
                done
            fi
            ;;
        3)
            log "Cleaning unused container images..."
            
            # Remove dangling images
            log "Removing dangling images..."
            podman image prune -f 2>&1 | tee -a "$LOG_FILE" || true
            
            # Remove unused images
            echo "Remove all unused images? (y/N)"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                podman image prune -a -f 2>&1 | tee -a "$LOG_FILE" || true
            fi
            
            # System cleanup
            log "Performing system cleanup..."
            podman system prune -f 2>&1 | tee -a "$LOG_FILE" || true
            ;;
        4)
            echo "Export/Import options:"
            echo "1. Export image to tar file"
            echo "2. Import image from tar file"
            echo "3. Save all images"
            read -p "Choose option (1-3): " export_choice
            
            case $export_choice in
                1)
                    read -p "Enter image name to export: " export_image
                    read -p "Enter output file path: " export_path
                    log "Exporting $export_image to $export_path..."
                    podman save -o "$export_path" "$export_image" 2>&1 | tee -a "$LOG_FILE"
                    ;;
                2)
                    read -p "Enter tar file path to import: " import_path
                    if [ -f "$import_path" ]; then
                        log "Importing from $import_path..."
                        podman load -i "$import_path" 2>&1 | tee -a "$LOG_FILE"
                    else
                        log "${RED}File not found: $import_path${NC}"
                    fi
                    ;;
                3)
                    read -p "Enter directory to save all images: " save_dir
                    mkdir -p "$save_dir"
                    podman images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
                        if [ "$image" != "<none>:<none>" ]; then
                            local filename=$(echo "$image" | tr '/' '_' | tr ':' '_')
                            log "Saving $image to $save_dir/$filename.tar..."
                            podman save -o "$save_dir/$filename.tar" "$image"
                        fi
                    done
                    ;;
            esac
            ;;
        5)
            log "Container image security scanning..."
            if command -v skopeo >/dev/null 2>&1; then
                read -p "Enter image to scan: " scan_image
                log "Scanning $scan_image for vulnerabilities..."
                skopeo inspect docker://"$scan_image" 2>&1 | tee -a "$LOG_FILE"
            else
                log "${YELLOW}Skopeo not available for security scanning${NC}"
                log "Consider installing: podman-security or trivy"
            fi
            ;;
        6)
            echo "Registry management options:"
            echo "1. List configured registries"
            echo "2. Add registry"
            echo "3. Login to registry"
            echo "4. Search in registry"
            read -p "Choose option (1-4): " registry_choice
            
            case $registry_choice in
                1)
                    log "Configured registries:"
                    cat "$HOME/.config/containers/registries.conf" 2>/dev/null | grep -E "registries.*=" | tee -a "$LOG_FILE" || log "No registries configured"
                    ;;
                2)
                    read -p "Enter registry URL: " registry_url
                    echo "registries = ['$registry_url']" >> "$HOME/.config/containers/registries.conf"
                    log "Added registry: $registry_url"
                    ;;
                3)
                    read -p "Enter registry URL: " login_registry
                    podman login "$login_registry"
                    ;;
                4)
                    read -p "Enter search term: " search_term
                    podman search "$search_term" | tee -a "$LOG_FILE"
                    ;;
            esac
            ;;
    esac
    
    log "${GREEN}Container image management completed${NC}"
}

container_registry_setup() {
    log "${BLUE}=== Container Registry Setup ===${NC}"
    
    echo "Registry setup options:"
    echo "1. Configure Docker Hub access"
    echo "2. Configure Red Hat Registry"
    echo "3. Configure Quay.io"
    echo "4. Setup local registry"
    echo "5. Configure all registries"
    read -p "Choose option (1-5): " registry_choice
    
    case $registry_choice in
        1)
            log "Configuring Docker Hub access..."
            podman login docker.io
            ;;
        2)
            log "Configuring Red Hat Registry..."
            podman login registry.redhat.io
            ;;
        3)
            log "Configuring Quay.io..."
            podman login quay.io
            ;;
        4)
            log "Setting up local registry..."
            
            # Run local registry
            podman run -d -p 5000:5000 --name local-registry registry:2
            
            # Configure insecure registry
            local registries_conf="$HOME/.config/containers/registries.conf"
            if ! grep -q "localhost:5000" "$registries_conf"; then
                echo "" >> "$registries_conf"
                echo "[registries.insecure]" >> "$registries_conf"
                echo "registries = ['localhost:5000']" >> "$registries_conf"
            fi
            
            log "Local registry started on localhost:5000"
            ;;
        5)
            log "Configuring multiple registries..."
            for registry in "docker.io" "registry.redhat.io" "quay.io"; do
                echo "Login to $registry? (y/N)"
                read -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    podman login "$registry"
                fi
            done
            ;;
    esac
    
    log "${GREEN}Container registry setup completed${NC}"
}

container_development_environment() {
    log "${BLUE}=== Container Development Environment ===${NC}"
    
    echo "Development environment options:"
    echo "1. Setup containerized development tools"
    echo "2. Create development container templates"
    echo "3. Setup container orchestration"
    echo "4. Configure container debugging"
    read -p "Choose option (1-4): " dev_choice
    
    case $dev_choice in
        1)
            log "Setting up containerized development tools..."
            
            # Create development containers
            local dev_containers=(
                "docker.io/library/node:alpine"
                "docker.io/library/python:slim"
                "docker.io/library/golang:alpine"
                "docker.io/library/openjdk:slim"
                "docker.io/library/ruby:alpine"
            )
            
            for container in "${dev_containers[@]}"; do
                log "Pulling development container: $container"
                podman pull "$container" 2>&1 | tee -a "$LOG_FILE" || true
            done
            ;;
        2)
            log "Creating development container templates..."
            local templates_dir="$HOME/.config/containers/templates"
            mkdir -p "$templates_dir"
            
            # Node.js template
            cat > "$templates_dir/nodejs-dev.dockerfile" << 'EOF'
FROM node:alpine
WORKDIR /app
RUN apk add --no-cache git
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
            
            # Python template
            cat > "$templates_dir/python-dev.dockerfile" << 'EOF'
FROM python:slim
WORKDIR /app
RUN apt-get update && apt-get install -y git
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "app.py"]
EOF
            
            log "Container templates created in $templates_dir"
            ;;
        3)
            log "Setting up container orchestration..."
            
            # Install and configure podman-compose
            if ! command -v podman-compose >/dev/null 2>&1; then
                log "Installing podman-compose..."
                python3 -m pip install --user podman-compose
            fi
            
            # Create sample docker-compose.yml
            local compose_dir="$HOME/container-projects"
            mkdir -p "$compose_dir"
            
            cat > "$compose_dir/sample-compose.yml" << 'EOF'
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
  
  database:
    image: postgres:alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF
            
            log "Sample docker-compose.yml created in $compose_dir"
            ;;
        4)
            log "Configuring container debugging..."
            
            # Install debugging tools
            install_package "gdb" || true
            install_package "strace" || true
            
            log "Container debugging tools installed"
            log "Use 'podman exec -it container_name /bin/bash' for interactive debugging"
            ;;
    esac
    
    log "${GREEN}Container development environment setup completed${NC}"
}

container_troubleshooting_tools() {
    log "${BLUE}=== Container Troubleshooting Tools ===${NC}"
    
    echo "Troubleshooting tools:"
    echo "1. Container health diagnostics"
    echo "2. Network troubleshooting"
    echo "3. Storage troubleshooting"
    echo "4. Performance monitoring"
    echo "5. Log analysis tools"
    read -p "Choose option (1-5): " trouble_choice
    
    case $trouble_choice in
        1)
            log "Running container health diagnostics..."
            
            log "System information:"
            podman system info | tee -a "$LOG_FILE"
            
            log "Running containers:"
            podman ps | tee -a "$LOG_FILE"
            
            log "Container resource usage:"
            podman stats --no-stream | tee -a "$LOG_FILE"
            ;;
        2)
            log "Network troubleshooting..."
            
            log "Podman networks:"
            podman network ls | tee -a "$LOG_FILE"
            
            log "Network inspection:"
            podman network ls --format "{{.Name}}" | while read -r network; do
                echo "Network: $network"
                podman network inspect "$network" | tee -a "$LOG_FILE"
            done
            ;;
        3)
            log "Storage troubleshooting..."
            
            log "Storage information:"
            podman system df | tee -a "$LOG_FILE"
            
            log "Volume information:"
            podman volume ls | tee -a "$LOG_FILE"
            
            log "Storage usage by container:"
            podman ps --format "{{.Names}}" | while read -r container; do
                echo "Container: $container"
                podman exec "$container" df -h 2>/dev/null | tee -a "$LOG_FILE" || echo "Could not access container filesystem"
            done
            ;;
        4)
            log "Container performance monitoring..."
            
            if command -v htop >/dev/null 2>&1; then
                log "Install ctop for better container monitoring:"
                log "pip3 install --user ctop"
            fi
            
            log "Current container resource usage:"
            podman stats --no-stream | tee -a "$LOG_FILE"
            ;;
        5)
            log "Log analysis tools..."
            
            echo "Select container for log analysis:"
            podman ps --format "{{.Names}}" | nl
            read -p "Enter container number: " container_num
            local container_name=$(podman ps --format "{{.Names}}" | sed -n "${container_num}p")
            
            if [ -n "$container_name" ]; then
                log "Logs for container: $container_name"
                podman logs "$container_name" | tail -50 | tee -a "$LOG_FILE"
            fi
            ;;
    esac
    
    log "${GREEN}Container troubleshooting completed${NC}"
}

# ===== SYSTEM INTEGRATION =====

application_desktop_integration() {
    log "${BLUE}=== Application Desktop Integration ===${NC}"
    
    echo "Desktop integration options:"
    echo "1. Create custom application launchers"
    echo "2. Configure MIME type associations"
    echo "3. Setup application themes"
    echo "4. Configure application autostart"
    echo "5. Desktop environment optimization"
    read -p "Choose option (1-5): " integration_choice
    
    case $integration_choice in
        1)
            log "Creating custom application launchers..."
            local applications_dir="$HOME/.local/share/applications"
            mkdir -p "$applications_dir"
            
            read -p "Enter application name: " app_name
            read -p "Enter command to execute: " app_command
            read -p "Enter description: " app_description
            read -p "Enter icon path (optional): " app_icon
            
            cat > "$applications_dir/$app_name.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Comment=$app_description
Exec=$app_command
Icon=${app_icon:-application-x-executable}
Terminal=false
Categories=Utility;
EOF
            
            chmod +x "$applications_dir/$app_name.desktop"
            log "Application launcher created: $app_name"
            ;;
        2)
            log "Configuring MIME type associations..."
            
            # Common MIME associations
            local mime_associations=(
                "text/plain=org.gnome.TextEditor.desktop"
                "application/pdf=org.gnome.Evince.desktop"
                "image/jpeg=org.gnome.eog.desktop"
                "image/png=org.gnome.eog.desktop"
                "video/mp4=org.videolan.VLC.desktop"
                "audio/mp3=org.gnome.Totem.desktop"
            )
            
            for association in "${mime_associations[@]}"; do
                IFS='=' read -r mime_type desktop_file <<< "$association"
                xdg-mime default "$desktop_file" "$mime_type" 2>/dev/null || true
                log "Associated $mime_type with $desktop_file"
            done
            ;;
        3)
            log "Setting up application themes..."
            
            # Install theme packages
            local theme_packages=(
                "gnome-themes-extra"
                "gtk-murrine-engine"
                "numix-icon-theme"
                "papirus-icon-theme"
            )
            
            for theme in "${theme_packages[@]}"; do
                install_package "$theme" || true
            done
            
            # Configure GTK themes
            local gtk_config="$HOME/.config/gtk-3.0/settings.ini"
            mkdir -p "$(dirname "$gtk_config")"
            
            cat > "$gtk_config" << EOF
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Papirus
gtk-font-name=Cantarell 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
EOF
            ;;
        4)
            log "Configuring application autostart..."
            local autostart_dir="$HOME/.config/autostart"
            mkdir -p "$autostart_dir"
            
            echo "Common applications to autostart:"
            echo "1. Network Manager"
            echo "2. Bluetooth Manager"
            echo "3. PulseAudio"
            echo "4. Custom application"
            read -p "Choose option (1-4): " autostart_choice
            
            case $autostart_choice in
                1)
                    cat > "$autostart_dir/nm-applet.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=nm-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
                    ;;
                2)
                    cat > "$autostart_dir/bluetooth.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Bluetooth Manager
Exec=blueman-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
                    ;;
                3)
                    cat > "$autostart_dir/pulseaudio.desktop" << EOF
[Desktop Entry]
Type=Application
Name=PulseAudio
Exec=pulseaudio --start
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
                    ;;
                4)
                    read -p "Enter application command: " autostart_command
                    read -p "Enter application name: " autostart_name
                    cat > "$autostart_dir/$autostart_name.desktop" << EOF
[Desktop Entry]
Type=Application
Name=$autostart_name
Exec=$autostart_command
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
                    ;;
            esac
            ;;
        5)
            log "Desktop environment optimization..."
            
            # GNOME optimizations
            if command -v gsettings >/dev/null 2>&1; then
                log "Applying GNOME optimizations..."
                gsettings set org.gnome.desktop.interface enable-animations false
                gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false
                gsettings set org.gnome.desktop.privacy remember-recent-files false
                gsettings set org.gnome.desktop.search-providers disable-external true
            fi
            
            # KDE optimizations
            if command -v kwriteconfig5 >/dev/null 2>&1; then
                log "Applying KDE optimizations..."
                kwriteconfig5 --file kwinrc --group Compositing --key Enabled false
                kwriteconfig5 --file kwinrc --group Effects --key kwin4_effect_fadeEnabled false
            fi
            ;;
    esac
    
    log "${GREEN}Desktop integration completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Application Installation And Setup Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) install_vscode_extensions ;;
            2) setup_flatpak_applications ;;
            3) complete_podman_setup ;;
            4) install_common_development_tools ;;
            5) configure_libreoffice_ms_office ;;
            6) font_installation_management ;;
            7) multimedia_tools_setup ;;
            8) graphics_design_tools ;;
            9) container_image_manager ;;
            10) container_registry_setup ;;
            11) container_development_environment ;;
            12) container_troubleshooting_tools ;;
            13) application_desktop_integration ;;
            14) custom_application_profiles ;;
            15) application_backup_restore ;;
            16) 
                log "${GREEN}Exiting Application Installation Suite${NC}"
                echo
                exit 0
                ;;
            *)
                echo
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Helper functions for remaining menu items
custom_application_profiles() {
    log "${BLUE}=== Custom Application Profiles ===${NC}"
    
    echo "Application profile management:"
    echo "1. Create development profile"
    echo "2. Create multimedia profile"
    echo "3. Create gaming profile"
    echo "4. Create office profile"
    echo "5. Custom profile"
    read -p "Choose option (1-5): " profile_choice
    
    local profile_dir="$HOME/.local/share/application-profiles"
    mkdir -p "$profile_dir"
    
    case $profile_choice in
        1)
            log "Creating development profile..."
            local dev_apps=("code" "git" "docker" "nodejs" "python3")
            echo "${dev_apps[@]}" > "$profile_dir/development.profile"
            ;;
        2)
            log "Creating multimedia profile..."
            local media_apps=("vlc" "gimp" "audacity" "blender" "obs-studio")
            echo "${media_apps[@]}" > "$profile_dir/multimedia.profile"
            ;;
        # Add other profile implementations
    esac
    
    log "${GREEN}Application profiles management completed${NC}"
}

application_backup_restore() {
    log "${BLUE}=== Application Backup & Restore ===${NC}"
    
    echo "Backup/Restore options:"
    echo "1. Backup application configurations"
    echo "2. Restore application configurations"
    echo "3. Export application list"
    echo "4. Import and install from list"
    read -p "Choose option (1-4): " backup_choice
    
    local backup_dir="$HOME/.local/share/app-backups"
    mkdir -p "$backup_dir"
    
    case $backup_choice in
        1)
            log "Backing up application configurations..."
            
            # Backup common config directories
            local config_dirs=(
                ".config/Code"
                ".config/gtk-3.0"
                ".local/share/applications"
                ".config/fontconfig"
            )
            
            local backup_file="$backup_dir/app-config-backup-$(date +'%Y%m%d_%H%M%S').tar.gz"
            
            cd "$HOME"
            tar -czf "$backup_file" "${config_dirs[@]}" 2>/dev/null || true
            
            log "Configuration backup saved to: $backup_file"
            ;;
        2)
            log "Available configuration backups:"
            ls -la "$backup_dir"/*.tar.gz 2>/dev/null | nl || log "No backups found"
            
            read -p "Enter backup file path: " restore_file
            if [ -f "$restore_file" ]; then
                cd "$HOME"
                tar -xzf "$restore_file"
                log "Configuration restored from: $restore_file"
            fi
            ;;
        3)
            log "Exporting application list..."
            local app_list="$backup_dir/installed-apps-$(date +'%Y%m%d').txt"
            
            # Export DNF packages
            dnf list installed > "$app_list"
            
            # Export Flatpak apps
            echo "" >> "$app_list"
            echo "=== FLATPAK APPLICATIONS ===" >> "$app_list"
            flatpak list >> "$app_list" 2>/dev/null || true
            
            log "Application list exported to: $app_list"
            ;;
        4)
            read -p "Enter application list file: " import_file
            if [ -f "$import_file" ]; then
                log "This feature requires manual implementation for your specific needs"
                log "File: $import_file"
            fi
            ;;
    esac
    
    log "${GREEN}Application backup/restore completed${NC}"
}

main "$@"
