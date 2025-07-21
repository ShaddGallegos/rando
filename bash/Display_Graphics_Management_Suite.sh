#!/bin/bash

# Display Graphics Management Suite
# Comprehensive display configuration, troubleshooting, and graphics management
# Consolidates: Configure_HDMI_Display.sh, display_fix.sh, Get_and_configure_displays.sh

set -euo pipefail

LOG_FILE="$HOME/display_management_$(date +'%Y%m%d_%H%M%S').log"

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
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           Display Graphics Management Suite                 ║${NC}"
    echo -e "${PURPLE}║     Comprehensive Display & Graphics Configuration Tool     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${CYAN}Select display management option:${NC}"
    echo ""
    echo "🖥️  DISPLAY CONFIGURATION:"
    echo "1. 📺 HDMI Display Setup & Configuration"
    echo "2. 🔧 Auto-Configure All Displays"
    echo "3. 🎛️  Custom Display Layout"
    echo "4. 📐 Display Resolution Management"
    echo ""
    echo "🔍 DIAGNOSTICS:"
    echo "5. 📊 Display & Graphics Information"
    echo "6. 🔍 Troubleshoot Display Issues"
    echo "7. 🎮 Graphics Driver Status"
    echo "8. 🖼️  Test Display Capabilities"
    echo ""
    echo "🔧 REPAIR & OPTIMIZATION:"
    echo "9. 🚨 Fix Display Problems"
    echo "10. ⚙️  Graphics Driver Management"
    echo "11. 🔄 Reset Display Configuration"
    echo "12. 🎯 Performance Optimization"
    echo ""
    echo "⚙️  ADVANCED:"
    echo "13. 🐧 Custom X11 Configuration"
    echo "14. 🔧 Wayland/X11 Session Management"
    echo "15. 💾 Backup/Restore Display Settings"
    echo "16. 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

detect_graphics_hardware() {
    log "${CYAN}=== Graphics Hardware Detection ===${NC}"
    
    # PCI graphics devices
    local pci_graphics=$(lspci | grep -i vga)
    log "Graphics Controllers:"
    echo "$pci_graphics" | tee -a "$LOG_FILE"
    
    # 3D controllers (like NVIDIA discrete cards)
    local pci_3d=$(lspci | grep -i "3d controller")
    if [ -n "$pci_3d" ]; then
        log "3D Controllers:"
        echo "$pci_3d" | tee -a "$LOG_FILE"
    fi
    
    # Check for NVIDIA
    if lspci | grep -i nvidia >/dev/null; then
        log "${GREEN}NVIDIA graphics detected${NC}"
        if command -v nvidia-smi >/dev/null 2>&1; then
            log "NVIDIA driver status:"
            nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits | tee -a "$LOG_FILE"
        else
            log "${YELLOW}NVIDIA hardware found but nvidia-smi not available${NC}"
        fi
    fi
    
    # Check for Intel
    if lspci | grep -i intel | grep -i graphics >/dev/null; then
        log "${GREEN}Intel graphics detected${NC}"
    fi
    
    # Check for AMD
    if lspci | grep -i amd >/dev/null || lspci | grep -i radeon >/dev/null; then
        log "${GREEN}AMD graphics detected${NC}"
    fi
}

get_current_displays() {
    log "${CYAN}=== Current Display Configuration ===${NC}"
    
    if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xrandr --listmonitors | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        xrandr | grep -E "(connected|disconnected)" | tee -a "$LOG_FILE"
    else
        log "${YELLOW}xrandr not available or no X11 session${NC}"
        
        # Try Wayland detection
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
            log "Running under Wayland session"
            if command -v wlr-randr >/dev/null 2>&1; then
                wlr-randr | tee -a "$LOG_FILE"
            else
                log "Install wlr-randr for Wayland display management"
            fi
        fi
    fi
}

check_display_drivers() {
    log "${CYAN}=== Display Driver Status ===${NC}"
    
    # Loaded graphics modules
    log "Loaded graphics kernel modules:"
    lsmod | grep -E "(nvidia|nouveau|intel|i915|radeon|amdgpu)" | tee -a "$LOG_FILE" || log "No graphics modules found"
    
    # Check for conflicts
    local nvidia_loaded=$(lsmod | grep nvidia | wc -l)
    local nouveau_loaded=$(lsmod | grep nouveau | wc -l)
    
    if [ "$nvidia_loaded" -gt 0 ] && [ "$nouveau_loaded" -gt 0 ]; then
        log "${RED}WARNING: Both NVIDIA and Nouveau drivers loaded - conflict detected${NC}"
    fi
    
    # DRM devices
    if [ -d /dev/dri ]; then
        log "DRM devices:"
        ls -la /dev/dri/ | tee -a "$LOG_FILE"
    fi
    
    # Graphics libraries
    log "Graphics library status:"
    ldconfig -p | grep -E "(libGL|libEGL|libvdpau)" | head -10 | tee -a "$LOG_FILE"
}

# ===== HDMI DISPLAY CONFIGURATION =====

hdmi_display_setup() {
    log "${BLUE}=== HDMI Display Setup & Configuration ===${NC}"
    
    if ! command -v xrandr >/dev/null 2>&1 || [ -z "${DISPLAY:-}" ]; then
        log "${RED}xrandr not available or no X11 session. Cannot configure HDMI.${NC}"
        return 1
    fi
    
    # Detect all connected displays
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    local hdmi_displays=$(echo "$displays" | grep -i hdmi || true)
    
    if [ -z "$hdmi_displays" ]; then
        log "${YELLOW}No HDMI displays detected. Checking for other external displays...${NC}"
        
        # Check for other display types
        local external_displays=$(echo "$displays" | grep -vE "(eDP|LVDS|DSI)" || true)
        if [ -n "$external_displays" ]; then
            log "External displays found:"
            echo "$external_displays" | tee -a "$LOG_FILE"
            hdmi_displays="$external_displays"
        else
            log "${RED}No external displays found${NC}"
            return 1
        fi
    fi
    
    log "Found HDMI/external displays:"
    echo "$hdmi_displays" | tee -a "$LOG_FILE"
    
    # Get laptop/internal display
    local internal_display=$(echo "$displays" | grep -E "(eDP|LVDS|DSI)" | head -1)
    if [ -z "$internal_display" ]; then
        internal_display=$(echo "$displays" | head -1)
    fi
    
    log "Internal display: $internal_display"
    
    # HDMI configuration menu
    echo ""
    echo "HDMI Configuration Options:"
    echo "1. Extend display (laptop + HDMI)"
    echo "2. Mirror displays"
    echo "3. HDMI only (disable laptop screen)"
    echo "4. Auto-configure optimal setup"
    echo "5. Custom configuration"
    echo ""
    read -p "Choose configuration (1-5): " hdmi_choice
    
    local hdmi_output=$(echo "$hdmi_displays" | head -1)
    
    case $hdmi_choice in
        1)
            # Extend display
            log "Configuring extended display setup..."
            xrandr --output "$internal_display" --auto --output "$hdmi_output" --auto --right-of "$internal_display"
            ;;
        2)
            # Mirror displays
            log "Configuring mirrored display setup..."
            xrandr --output "$internal_display" --auto --output "$hdmi_output" --auto --same-as "$internal_display"
            ;;
        3)
            # HDMI only
            log "Configuring HDMI-only display..."
            xrandr --output "$internal_display" --off --output "$hdmi_output" --auto
            ;;
        4)
            # Auto-configure
            log "Auto-configuring optimal display setup..."
            auto_configure_displays
            ;;
        5)
            # Custom configuration
            custom_display_configuration
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Verify configuration
    sleep 2
    log "New display configuration:"
    xrandr --listmonitors | tee -a "$LOG_FILE"
    
    # Fix common HDMI issues
    fix_hdmi_audio
    fix_display_scaling
    
    log "${GREEN}HDMI display configuration completed${NC}"
}

fix_hdmi_audio() {
    log "${CYAN}=== Configuring HDMI Audio ===${NC}"
    
    if command -v pactl >/dev/null 2>&1; then
        # List audio sinks
        local hdmi_sinks=$(pactl list short sinks | grep -i hdmi | head -1 | awk '{print $2}')
        
        if [ -n "$hdmi_sinks" ]; then
            log "Setting HDMI as default audio sink: $hdmi_sinks"
            pactl set-default-sink "$hdmi_sinks"
        else
            log "${YELLOW}No HDMI audio sinks found${NC}"
        fi
    else
        log "${YELLOW}PulseAudio not available for HDMI audio configuration${NC}"
    fi
}

fix_display_scaling() {
    log "${CYAN}=== Adjusting Display Scaling ===${NC}"
    
    # Detect high DPI displays
    local displays_info=$(xrandr | grep -E " connected")
    
    while IFS= read -r line; do
        local display=$(echo "$line" | awk '{print $1}')
        local resolution=$(echo "$line" | grep -o '[0-9]\+x[0-9]\+' | head -1)
        
        if [ -n "$resolution" ]; then
            local width=$(echo "$resolution" | cut -dx -f1)
            local height=$(echo "$resolution" | cut -dx -f2)
            
            # Check if display is high DPI (>1080p)
            if [ "$width" -gt 1920 ] || [ "$height" -gt 1080 ]; then
                log "High DPI display detected: $display ($resolution)"
                
                # Set appropriate scaling
                if [ "$width" -ge 3840 ]; then
                    # 4K display
                    xrandr --output "$display" --scale 0.5x0.5
                    log "Applied 4K scaling to $display"
                elif [ "$width" -ge 2560 ]; then
                    # QHD display
                    xrandr --output "$display" --scale 0.75x0.75
                    log "Applied QHD scaling to $display"
                fi
            fi
        fi
    done <<< "$displays_info"
}

# ===== AUTO CONFIGURATION =====

auto_configure_displays() {
    log "${BLUE}=== Auto-Configuring All Displays ===${NC}"
    
    if ! command -v xrandr >/dev/null 2>&1 || [ -z "${DISPLAY:-}" ]; then
        log "${RED}xrandr not available${NC}"
        return 1
    fi
    
    # Get all connected displays
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    local display_count=$(echo "$displays" | wc -l)
    
    log "Found $display_count connected display(s):"
    echo "$displays" | tee -a "$LOG_FILE"
    
    # Identify display types
    local internal_displays=$(echo "$displays" | grep -E "(eDP|LVDS|DSI)")
    local external_displays=$(echo "$displays" | grep -vE "(eDP|LVDS|DSI)")
    
    case $display_count in
        1)
            # Single display - just ensure it's enabled
            local display=$(echo "$displays" | head -1)
            log "Configuring single display: $display"
            xrandr --output "$display" --auto
            ;;
        2)
            # Dual display setup
            if [ -n "$internal_displays" ] && [ -n "$external_displays" ]; then
                local internal=$(echo "$internal_displays" | head -1)
                local external=$(echo "$external_displays" | head -1)
                
                log "Configuring dual display: $internal (internal) + $external (external)"
                xrandr --output "$internal" --auto --output "$external" --auto --right-of "$internal"
            else
                # Two external displays
                local primary=$(echo "$displays" | head -1)
                local secondary=$(echo "$displays" | tail -1)
                
                log "Configuring dual external displays: $primary + $secondary"
                xrandr --output "$primary" --auto --primary --output "$secondary" --auto --right-of "$primary"
            fi
            ;;
        *)
            # Multiple displays - arrange in a line
            log "Configuring multiple display setup..."
            local previous_display=""
            
            while IFS= read -r display; do
                if [ -z "$previous_display" ]; then
                    xrandr --output "$display" --auto --primary
                    previous_display="$display"
                else
                    xrandr --output "$display" --auto --right-of "$previous_display"
                    previous_display="$display"
                fi
                log "Configured: $display"
            done <<< "$displays"
            ;;
    esac
    
    # Apply common fixes
    sleep 2
    fix_display_scaling
    
    log "${GREEN}Auto-configuration completed${NC}"
    xrandr --listmonitors | tee -a "$LOG_FILE"
}

# ===== CUSTOM CONFIGURATION =====

custom_display_layout() {
    log "${BLUE}=== Custom Display Layout Configuration ===${NC}"
    
    if ! command -v xrandr >/dev/null 2>&1 || [ -z "${DISPLAY:-}" ]; then
        log "${RED}xrandr not available${NC}"
        return 1
    fi
    
    # Show current setup
    echo "Current display configuration:"
    xrandr | grep -E "(connected|disconnected)"
    echo ""
    
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    local display_array=($displays)
    
    echo "Available displays:"
    local i=1
    for display in "${display_array[@]}"; do
        echo "$i. $display"
        ((i++))
    done
    echo ""
    
    # Primary display selection
    read -p "Select primary display (1-${#display_array[@]}): " primary_choice
    if [ "$primary_choice" -lt 1 ] || [ "$primary_choice" -gt ${#display_array[@]} ]; then
        log "${RED}Invalid selection${NC}"
        return 1
    fi
    
    local primary_display="${display_array[$((primary_choice-1))]}"
    log "Primary display: $primary_display"
    
    # Configure primary display
    xrandr --output "$primary_display" --auto --primary
    
    # Configure additional displays
    for display in "${display_array[@]}"; do
        if [ "$display" != "$primary_display" ]; then
            echo ""
            echo "Configure display: $display"
            echo "1. Right of $primary_display"
            echo "2. Left of $primary_display"
            echo "3. Above $primary_display"
            echo "4. Below $primary_display"
            echo "5. Same as $primary_display (mirror)"
            echo "6. Disable"
            echo ""
            read -p "Choose position for $display (1-6): " position
            
            case $position in
                1) xrandr --output "$display" --auto --right-of "$primary_display" ;;
                2) xrandr --output "$display" --auto --left-of "$primary_display" ;;
                3) xrandr --output "$display" --auto --above "$primary_display" ;;
                4) xrandr --output "$display" --auto --below "$primary_display" ;;
                5) xrandr --output "$display" --auto --same-as "$primary_display" ;;
                6) xrandr --output "$display" --off ;;
                *) log "${YELLOW}Invalid choice, skipping $display${NC}" ;;
            esac
        fi
    done
    
    log "${GREEN}Custom display layout configured${NC}"
    xrandr --listmonitors | tee -a "$LOG_FILE"
}

# ===== RESOLUTION MANAGEMENT =====

display_resolution_management() {
    log "${BLUE}=== Display Resolution Management ===${NC}"
    
    if ! command -v xrandr >/dev/null 2>&1 || [ -z "${DISPLAY:-}" ]; then
        log "${RED}xrandr not available${NC}"
        return 1
    fi
    
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    
    echo "Connected displays:"
    local i=1
    for display in $displays; do
        echo "$i. $display"
        ((i++))
    done
    echo ""
    
    read -p "Select display to configure (1-$(echo "$displays" | wc -l)): " display_choice
    local selected_display=$(echo "$displays" | sed -n "${display_choice}p")
    
    if [ -z "$selected_display" ]; then
        log "${RED}Invalid display selection${NC}"
        return 1
    fi
    
    log "Configuring resolution for: $selected_display"
    
    # Show available resolutions
    echo "Available resolutions for $selected_display:"
    xrandr | sed -n "/$selected_display connected/,/^[^ ]/p" | grep -E "^ " | nl
    echo ""
    
    echo "Options:"
    echo "1. Set specific resolution"
    echo "2. Set auto (preferred) resolution"
    echo "3. Add custom resolution"
    echo "4. Set refresh rate"
    echo ""
    read -p "Choose option (1-4): " res_choice
    
    case $res_choice in
        1)
            read -p "Enter resolution (e.g., 1920x1080): " resolution
            xrandr --output "$selected_display" --mode "$resolution"
            ;;
        2)
            xrandr --output "$selected_display" --auto
            ;;
        3)
            read -p "Enter custom resolution (e.g., 1920x1080): " custom_res
            read -p "Enter refresh rate (e.g., 60): " refresh_rate
            
            # Calculate modeline
            local modeline=$(cvt $(echo "$custom_res" | tr 'x' ' ') "$refresh_rate" | grep Modeline | cut -d' ' -f2-)
            local mode_name=$(echo "$modeline" | awk '{print $1}' | tr -d '"')
            
            xrandr --newmode $modeline
            xrandr --addmode "$selected_display" "$mode_name"
            xrandr --output "$selected_display" --mode "$mode_name"
            ;;
        4)
            read -p "Enter refresh rate (e.g., 60): " refresh_rate
            local current_mode=$(xrandr | grep "$selected_display" | grep -o '[0-9]\+x[0-9]\+' | head -1)
            xrandr --output "$selected_display" --mode "$current_mode" --rate "$refresh_rate"
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    log "${GREEN}Resolution configuration completed${NC}"
}

# ===== DIAGNOSTICS =====

display_graphics_info() {
    log "${BLUE}=== Display & Graphics Information ===${NC}"
    
    # Hardware detection
    detect_graphics_hardware
    echo "" | tee -a "$LOG_FILE"
    
    # Display configuration
    get_current_displays
    echo "" | tee -a "$LOG_FILE"
    
    # Driver status
    check_display_drivers
    echo "" | tee -a "$LOG_FILE"
    
    # Session information
    log "${CYAN}=== Session Information ===${NC}"
    log "Session Type: ${XDG_SESSION_TYPE:-unknown}"
    log "Display: ${DISPLAY:-not set}"
    log "Wayland Display: ${WAYLAND_DISPLAY:-not set}"
    
    # Desktop environment
    log "Desktop Environment: ${XDG_CURRENT_DESKTOP:-unknown}"
    log "Window Manager: ${WINDOWMANAGER:-unknown}"
    
    # OpenGL information
    if command -v glxinfo >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        log "${CYAN}=== OpenGL Information ===${NC}"
        glxinfo | grep -E "(OpenGL vendor|OpenGL renderer|OpenGL version)" | tee -a "$LOG_FILE"
    fi
    
    log "${GREEN}Display and graphics information completed${NC}"
}

troubleshoot_display_issues() {
    log "${BLUE}=== Troubleshooting Display Issues ===${NC}"
    
    # Check for common issues
    log "${CYAN}=== Common Issue Detection ===${NC}"
    
    # No external display detected
    local connected_displays=$(xrandr 2>/dev/null | grep " connected" | wc -l || echo "0")
    if [ "$connected_displays" -eq 1 ]; then
        log "${YELLOW}Only one display detected - check cable connections${NC}"
    fi
    
    # Driver conflicts
    local nvidia_loaded=$(lsmod | grep nvidia | wc -l)
    local nouveau_loaded=$(lsmod | grep nouveau | wc -l)
    
    if [ "$nvidia_loaded" -gt 0 ] && [ "$nouveau_loaded" -gt 0 ]; then
        log "${RED}CONFLICT: Both NVIDIA and Nouveau drivers loaded${NC}"
        log "Recommendation: Disable nouveau driver"
    fi
    
    # Check for HDMI audio issues
    if command -v pactl >/dev/null 2>&1; then
        local hdmi_sinks=$(pactl list short sinks | grep -i hdmi | wc -l)
        if [ "$hdmi_sinks" -eq 0 ] && echo "$displays" | grep -i hdmi >/dev/null; then
            log "${YELLOW}HDMI display detected but no HDMI audio sink found${NC}"
        fi
    fi
    
    # Check for resolution issues
    if [ -n "${DISPLAY:-}" ]; then
        local max_res=$(xrandr | grep -E "^\s*[0-9]+x[0-9]+" | sort -t'x' -k1,1n -k2,2n | tail -1 | awk '{print $1}')
        log "Maximum available resolution: $max_res"
    fi
    
    # Check kernel messages for display issues
    log "${CYAN}=== Kernel Messages ===${NC}"
    dmesg | grep -i -E "(drm|display|monitor|hdmi|dp)" | tail -10 | tee -a "$LOG_FILE"
    
    log "${GREEN}Display troubleshooting completed${NC}"
}

graphics_driver_status() {
    log "${BLUE}=== Graphics Driver Status ===${NC}"
    
    # Check loaded modules
    log "${CYAN}=== Loaded Graphics Modules ===${NC}"
    lsmod | grep -E "(nvidia|nouveau|intel|i915|radeon|amdgpu)" | tee -a "$LOG_FILE"
    
    # Check driver packages
    log "${CYAN}=== Installed Driver Packages ===${NC}"
    rpm -qa | grep -E "(nvidia|mesa|intel)" | sort | tee -a "$LOG_FILE"
    
    # NVIDIA specific checks
    if lsmod | grep nvidia >/dev/null; then
        log "${CYAN}=== NVIDIA Driver Information ===${NC}"
        if command -v nvidia-smi >/dev/null 2>&1; then
            nvidia-smi | tee -a "$LOG_FILE"
        fi
        
        if [ -f /proc/driver/nvidia/version ]; then
            log "NVIDIA driver version:"
            cat /proc/driver/nvidia/version | tee -a "$LOG_FILE"
        fi
    fi
    
    # Mesa information
    if command -v glxinfo >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        log "${CYAN}=== Mesa/OpenGL Information ===${NC}"
        glxinfo | grep -E "(Mesa|OpenGL)" | head -10 | tee -a "$LOG_FILE"
    fi
    
    log "${GREEN}Graphics driver status check completed${NC}"
}

test_display_capabilities() {
    log "${BLUE}=== Testing Display Capabilities ===${NC}"
    
    if ! command -v xrandr >/dev/null 2>&1 || [ -z "${DISPLAY:-}" ]; then
        log "${RED}xrandr not available${NC}"
        return 1
    fi
    
    # Test each connected display
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    
    for display in $displays; do
        log "${CYAN}Testing display: $display${NC}"
        
        # Get display properties
        local display_info=$(xrandr | sed -n "/$display connected/,/^[^ ]/p")
        local resolutions=$(echo "$display_info" | grep -E "^ " | awk '{print $1}' | wc -l)
        local max_res=$(echo "$display_info" | grep -E "^ " | head -1 | awk '{print $1}')
        
        log "Available resolutions: $resolutions"
        log "Maximum resolution: $max_res"
        
        # Test if display responds
        if timeout 5 xrandr --output "$display" --auto >/dev/null 2>&1; then
            log "${GREEN}Display $display responds to configuration${NC}"
        else
            log "${RED}Display $display not responding${NC}"
        fi
        
        # Get physical size if available
        local physical_size=$(echo "$display_info" | grep -o '[0-9]\+mm x [0-9]\+mm')
        if [ -n "$physical_size" ]; then
            log "Physical size: $physical_size"
        fi
        
        echo "" | tee -a "$LOG_FILE"
    done
    
    # Test OpenGL if available
    if command -v glxgears >/dev/null 2>&1; then
        log "${CYAN}OpenGL rendering test available (run 'glxgears' manually)${NC}"
    fi
    
    log "${GREEN}Display capability testing completed${NC}"
}

# ===== REPAIR & OPTIMIZATION =====

fix_display_problems() {
    log "${BLUE}=== Fixing Display Problems ===${NC}"
    
    # Reset display configuration
    log "${CYAN}Resetting display configuration...${NC}"
    if [ -n "${DISPLAY:-}" ]; then
        xrandr --auto 2>/dev/null || true
    fi
    
    # Fix driver conflicts
    local nvidia_loaded=$(lsmod | grep nvidia | wc -l)
    local nouveau_loaded=$(lsmod | grep nouveau | wc -l)
    
    if [ "$nvidia_loaded" -gt 0 ] && [ "$nouveau_loaded" -gt 0 ]; then
        log "${YELLOW}Attempting to resolve NVIDIA/Nouveau conflict...${NC}"
        
        # Create nouveau blacklist
        sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << EOF
blacklist nouveau
options nouveau modeset=0
EOF
        
        log "Nouveau blacklisted. Reboot required for full effect."
    fi
    
    # Regenerate Xorg configuration if needed
    if [ ! -f /etc/X11/xorg.conf ] && [ "$nvidia_loaded" -gt 0 ]; then
        log "Generating NVIDIA X11 configuration..."
        sudo nvidia-xconfig 2>/dev/null || log "nvidia-xconfig not available"
    fi
    
    # Fix common HDMI issues
    log "${CYAN}Applying HDMI fixes...${NC}"
    
    # Force HDMI detection
    for output in $(xrandr 2>/dev/null | grep disconnected | grep HDMI | awk '{print $1}'); do
        xrandr --output "$output" --auto 2>/dev/null || true
    done
    
    # Reset audio configuration
    if command -v pulseaudio >/dev/null 2>&1; then
        pulseaudio -k 2>/dev/null || true
        sleep 2
        pulseaudio --start 2>/dev/null || true
        log "Audio system restarted"
    fi
    
    # Clear font cache (can fix display rendering issues)
    fc-cache -fv >/dev/null 2>&1 || true
    
    log "${GREEN}Display problem fixes applied${NC}"
    log "${YELLOW}You may need to log out and back in for all changes to take effect${NC}"
}

graphics_driver_management() {
    log "${BLUE}=== Graphics Driver Management ===${NC}"
    
    echo "Graphics Driver Management Options:"
    echo "1. Install NVIDIA drivers (if NVIDIA hardware detected)"
    echo "2. Install Mesa drivers (open source)"
    echo "3. Switch to Intel graphics (if hybrid system)"
    echo "4. Remove conflicting drivers"
    echo "5. Reinstall display drivers"
    echo ""
    read -p "Choose option (1-5): " driver_choice
    
    case $driver_choice in
        1)
            if lspci | grep -i nvidia >/dev/null; then
                log "Installing NVIDIA drivers..."
                sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda 2>&1 | tee -a "$LOG_FILE"
                
                # Blacklist nouveau
                sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << EOF
blacklist nouveau
options nouveau modeset=0
EOF
                log "NVIDIA drivers installed. Reboot required."
            else
                log "${RED}No NVIDIA hardware detected${NC}"
            fi
            ;;
        2)
            log "Installing Mesa drivers..."
            sudo dnf install -y mesa-dri-drivers mesa-libGL mesa-libEGL 2>&1 | tee -a "$LOG_FILE"
            ;;
        3)
            # Switch to Intel (disable discrete GPU)
            log "Configuring Intel graphics preference..."
            echo 'integrated' | sudo tee /sys/kernel/debug/vgaswitcheroo/switch >/dev/null 2>&1 || true
            ;;
        4)
            log "Removing conflicting drivers..."
            sudo dnf remove -y xorg-x11-drv-nouveau 2>/dev/null || true
            sudo modprobe -r nouveau 2>/dev/null || true
            ;;
        5)
            log "Reinstalling display drivers..."
            sudo dnf reinstall -y xorg-x11-server-Xorg xorg-x11-drv-* 2>&1 | tee -a "$LOG_FILE"
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            ;;
    esac
    
    log "${GREEN}Graphics driver management completed${NC}"
}

reset_display_configuration() {
    log "${BLUE}=== Resetting Display Configuration ===${NC}"
    
    echo -e "${RED}WARNING: This will reset all display settings!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "${YELLOW}Reset cancelled by user${NC}"
        return 0
    fi
    
    # Remove X11 configuration files
    log "Removing X11 configuration files..."
    sudo rm -f /etc/X11/xorg.conf /etc/X11/xorg.conf.d/* 2>/dev/null || true
    
    # Reset xrandr to auto
    if [ -n "${DISPLAY:-}" ]; then
        log "Resetting xrandr configuration..."
        xrandr --auto 2>/dev/null || true
    fi
    
    # Reset GNOME display settings (if applicable)
    if command -v gsettings >/dev/null 2>&1; then
        log "Resetting GNOME display settings..."
        gsettings reset-recursively org.gnome.mutter 2>/dev/null || true
        gsettings reset-recursively org.gnome.settings-daemon.plugins.xsettings 2>/dev/null || true
    fi
    
    # Reset KDE display settings (if applicable)
    if [ -n "${KDE_FULL_SESSION:-}" ]; then
        log "Resetting KDE display settings..."
        rm -f ~/.config/kscreenrc ~/.local/share/kscreen/* 2>/dev/null || true
    fi
    
    log "${GREEN}Display configuration reset completed${NC}"
    log "${YELLOW}Log out and back in for changes to take effect${NC}"
}

display_performance_optimization() {
    log "${BLUE}=== Display Performance Optimization ===${NC}"
    
    # Enable performance governor
    log "Setting performance governor..."
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    
    # Optimize for graphics
    if lsmod | grep nvidia >/dev/null; then
        log "Applying NVIDIA optimizations..."
        
        # Set GPU performance mode
        nvidia-smi -pm 1 >/dev/null 2>&1 || true
        nvidia-smi -ac 2505,875 >/dev/null 2>&1 || true
        
        # Disable GPU power management
        echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX nvidia.NVreg_PreserveVideoMemoryAllocations=1"' | sudo tee -a /etc/default/grub >/dev/null 2>&1 || true
    fi
    
    # Optimize for Intel graphics
    if lsmod | grep i915 >/dev/null; then
        log "Applying Intel graphics optimizations..."
        
        # Enable GuC and HuC
        echo 'options i915 enable_guc=2' | sudo tee /etc/modprobe.d/i915.conf >/dev/null 2>&1 || true
    fi
    
    # Optimize compositor settings
    if command -v gsettings >/dev/null 2>&1; then
        log "Optimizing GNOME compositor..."
        gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null || true
    fi
    
    # Disable unnecessary visual effects
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
    fi
    
    log "${GREEN}Display performance optimization completed${NC}"
}

# ===== ADVANCED FUNCTIONS =====

custom_x11_configuration() {
    log "${BLUE}=== Custom X11 Configuration ===${NC}"
    
    echo "X11 Configuration Options:"
    echo "1. Generate NVIDIA X11 config"
    echo "2. Create multi-monitor X11 config"
    echo "3. Configure display scaling in X11"
    echo "4. Set custom refresh rates"
    echo "5. Manual X11 configuration edit"
    echo ""
    read -p "Choose option (1-5): " x11_choice
    
    case $x11_choice in
        1)
            if command -v nvidia-xconfig >/dev/null 2>&1; then
                log "Generating NVIDIA X11 configuration..."
                sudo nvidia-xconfig --multigpu=on --sli=off
                log "NVIDIA X11 config generated at /etc/X11/xorg.conf"
            else
                log "${RED}nvidia-xconfig not available${NC}"
            fi
            ;;
        2)
            log "Creating multi-monitor X11 configuration..."
            generate_multimonitor_xorg_conf
            ;;
        3)
            read -p "Enter scaling factor (e.g., 1.5): " scale_factor
            log "Configuring display scaling: $scale_factor"
            configure_x11_scaling "$scale_factor"
            ;;
        4)
            configure_custom_refresh_rates
            ;;
        5)
            if [ -f /etc/X11/xorg.conf ]; then
                sudo ${EDITOR:-nano} /etc/X11/xorg.conf
            else
                log "${YELLOW}No X11 configuration file found${NC}"
            fi
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            ;;
    esac
    
    log "${GREEN}X11 configuration completed${NC}"
}

generate_multimonitor_xorg_conf() {
    local displays=$(xrandr | grep " connected" | awk '{print $1}')
    
    sudo tee /etc/X11/xorg.conf > /dev/null << EOF
Section "ServerLayout"
    Identifier     "MultiMonitor"
EOF
    
    local i=0
    for display in $displays; do
        echo "    Screen     $i \"Screen$i\" RightOf \"Screen$((i-1))\"" | sudo tee -a /etc/X11/xorg.conf >/dev/null
        ((i++))
    done
    
    echo 'EndSection' | sudo tee -a /etc/X11/xorg.conf >/dev/null
    
    i=0
    for display in $displays; do
        cat << EOF | sudo tee -a /etc/X11/xorg.conf >/dev/null

Section "Screen"
    Identifier     "Screen$i"
    Device         "Device$i"
    Monitor        "Monitor$i"
EndSection

Section "Device"
    Identifier     "Device$i"
    Driver         "nvidia"
EndSection

Section "Monitor"
    Identifier     "Monitor$i"
EndSection
EOF
        ((i++))
    done
    
    log "Multi-monitor X11 configuration generated"
}

wayland_x11_session_management() {
    log "${BLUE}=== Wayland/X11 Session Management ===${NC}"
    
    log "Current session type: ${XDG_SESSION_TYPE:-unknown}"
    
    echo "Session Management Options:"
    echo "1. Switch to X11 session"
    echo "2. Switch to Wayland session"
    echo "3. Install Wayland support"
    echo "4. Install X11 support"
    echo "5. Configure session preferences"
    echo ""
    read -p "Choose option (1-5): " session_choice
    
    case $session_choice in
        1)
            log "Configuring X11 session preference..."
            # Set GDM to prefer X11
            echo -e "[daemon]\nWaylandEnable=false" | sudo tee /etc/gdm/custom.conf >/dev/null
            log "X11 session will be used after next logout"
            ;;
        2)
            log "Configuring Wayland session preference..."
            sudo sed -i 's/WaylandEnable=false/WaylandEnable=true/' /etc/gdm/custom.conf 2>/dev/null || true
            log "Wayland session will be preferred after next logout"
            ;;
        3)
            log "Installing Wayland support..."
            sudo dnf install -y wayland-devel libwayland-client libwayland-server 2>&1 | tee -a "$LOG_FILE"
            ;;
        4)
            log "Installing X11 support..."
            sudo dnf install -y xorg-x11-server-Xorg xorg-x11-xinit 2>&1 | tee -a "$LOG_FILE"
            ;;
        5)
            log "Current session configuration:"
            cat /etc/gdm/custom.conf 2>/dev/null | grep -E "(Wayland|DefaultSession)" || log "No custom configuration found"
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            ;;
    esac
    
    log "${GREEN}Session management completed${NC}"
}

backup_restore_display_settings() {
    log "${BLUE}=== Backup/Restore Display Settings ===${NC}"
    
    local backup_dir="$HOME/.display_backups"
    mkdir -p "$backup_dir"
    
    echo "Backup/Restore Options:"
    echo "1. Backup current display settings"
    echo "2. Restore display settings"
    echo "3. List available backups"
    echo "4. Delete backup"
    echo ""
    read -p "Choose option (1-4): " backup_choice
    
    case $backup_choice in
        1)
            local backup_name="display_backup_$(date +'%Y%m%d_%H%M%S')"
            local backup_path="$backup_dir/$backup_name"
            
            log "Creating backup: $backup_name"
            mkdir -p "$backup_path"
            
            # Backup xrandr configuration
            if [ -n "${DISPLAY:-}" ]; then
                xrandr > "$backup_path/xrandr.txt" 2>/dev/null || true
            fi
            
            # Backup X11 configuration
            [ -f /etc/X11/xorg.conf ] && sudo cp /etc/X11/xorg.conf "$backup_path/" 2>/dev/null || true
            
            # Backup GNOME settings
            if command -v dconf >/dev/null 2>&1; then
                dconf dump /org/gnome/settings-daemon/plugins/xsettings/ > "$backup_path/gnome_display.dconf" 2>/dev/null || true
            fi
            
            log "Backup created: $backup_path"
            ;;
        2)
            echo "Available backups:"
            ls -1 "$backup_dir" 2>/dev/null | nl || log "No backups found"
            echo ""
            read -p "Enter backup name to restore: " restore_name
            
            local restore_path="$backup_dir/$restore_name"
            if [ -d "$restore_path" ]; then
                log "Restoring from: $restore_name"
                
                # Restore X11 configuration
                [ -f "$restore_path/xorg.conf" ] && sudo cp "$restore_path/xorg.conf" /etc/X11/ 2>/dev/null || true
                
                # Restore GNOME settings
                [ -f "$restore_path/gnome_display.dconf" ] && dconf load /org/gnome/settings-daemon/plugins/xsettings/ < "$restore_path/gnome_display.dconf" 2>/dev/null || true
                
                log "Restore completed"
            else
                log "${RED}Backup not found: $restore_name${NC}"
            fi
            ;;
        3)
            log "Available backups:"
            ls -la "$backup_dir" 2>/dev/null || log "No backups found"
            ;;
        4)
            echo "Available backups:"
            ls -1 "$backup_dir" 2>/dev/null | nl || log "No backups found"
            echo ""
            read -p "Enter backup name to delete: " delete_name
            
            local delete_path="$backup_dir/$delete_name"
            if [ -d "$delete_path" ]; then
                rm -rf "$delete_path"
                log "Backup deleted: $delete_name"
            else
                log "${RED}Backup not found: $delete_name${NC}"
            fi
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            ;;
    esac
    
    log "${GREEN}Backup/restore operation completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Display Graphics Management Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) hdmi_display_setup ;;
            2) auto_configure_displays ;;
            3) custom_display_layout ;;
            4) display_resolution_management ;;
            5) display_graphics_info ;;
            6) troubleshoot_display_issues ;;
            7) graphics_driver_status ;;
            8) test_display_capabilities ;;
            9) fix_display_problems ;;
            10) graphics_driver_management ;;
            11) reset_display_configuration ;;
            12) display_performance_optimization ;;
            13) custom_x11_configuration ;;
            14) wayland_x11_session_management ;;
            15) backup_restore_display_settings ;;
            16) 
                log "${GREEN}Exiting Display Graphics Management Suite${NC}"
                echo -e "${GREEN}Log file saved to: $LOG_FILE${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Install required packages if missing
install_dependencies() {
    local deps_needed=()
    
    command -v xrandr >/dev/null 2>&1 || deps_needed+=("xorg-x11-server-utils")
    command -v glxinfo >/dev/null 2>&1 || deps_needed+=("mesa-demos")
    command -v cvt >/dev/null 2>&1 || deps_needed+=("xorg-x11-server-utils")
    
    if [ ${#deps_needed[@]} -gt 0 ]; then
        log "${YELLOW}Installing required dependencies: ${deps_needed[*]}${NC}"
        sudo dnf install -y "${deps_needed[@]}" 2>/dev/null || true
    fi
}

# Install dependencies and start
install_dependencies
main "$@"
