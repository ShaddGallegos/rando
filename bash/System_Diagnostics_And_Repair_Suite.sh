#!/bin/bash

# System Diagnostics And Repair Suite
# Comprehensive system troubleshooting, diagnostics, and repair toolkit
# Consolidates: Analyze_And_Fix_System_Errors.sh, fix_system_freezes.sh, freeze_diagnose.sh, Disk_scan_and_repair.sh

set -euo pipefail

LOG_FILE="$HOME/system_diagnostics_$(date +'%Y%m%d_%H%M%S').log"

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
    echo -e "${PURPLE}║            System Diagnostics And Repair Suite              ║${NC}"
    echo -e "${PURPLE}║        Comprehensive System Troubleshooting Tool            ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${CYAN}Select diagnostic and repair option:${NC}"
    echo ""
    echo "🔍 DIAGNOSTICS:"
    echo "1. 📊 Full System Diagnostic Report"
    echo "2. ❄️  System Freeze Analysis"
    echo "3. 🖥️  Hardware & Driver Status Check"
    echo "4. 💾 Memory & Storage Analysis"
    echo ""
    echo "🔧 REPAIRS:"
    echo "5. 🚨 Fix System Freezes & Hung Tasks"
    echo "6. 💿 Disk Scan & Filesystem Repair"
    echo "7. 🔄 I/O Performance Optimization"
    echo "8. 🛠️  General System Error Fixes"
    echo ""
    echo "⚙️  ADVANCED:"
    echo "9. 🔍 Custom Diagnostic Session"
    echo "10. 📋 Generate System Health Report"
    echo "11. 🔄 Reset All System Configurations"
    echo "12. 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-12): " choice
}

# ===== DIAGNOSTIC FUNCTIONS =====

full_system_diagnostic() {
    log "${BLUE}=== Starting Full System Diagnostic ===${NC}"
    
    # System Information
    log "${CYAN}=== System Information ===${NC}"
    log "Hostname: $(hostname)"
    log "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2 2>/dev/null || echo 'Unknown')"
    log "Kernel: $(uname -r)"
    log "Uptime: $(uptime)"
    
    # Memory Status
    log "${CYAN}=== Memory Status ===${NC}"
    free -h | tee -a "$LOG_FILE"
    
    # CPU Information
    log "${CYAN}=== CPU Information ===${NC}"
    lscpu | grep -E "(Model name|CPU\(s\)|Thread|Architecture)" | tee -a "$LOG_FILE"
    
    # Load Average
    log "${CYAN}=== System Load ===${NC}"
    if command -v vmstat >/dev/null 2>&1; then
        vmstat 1 5 | tee -a "$LOG_FILE"
    else
        log "vmstat not available"
    fi
    
    # Disk Usage
    log "${CYAN}=== Disk Usage ===${NC}"
    df -h | tee -a "$LOG_FILE"
    
    # Running Processes
    log "${CYAN}=== Top CPU Processes ===${NC}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -20 | tee -a "$LOG_FILE"
    
    # Network Status
    log "${CYAN}=== Network Connections ===${NC}"
    ss -tuln | head -20 | tee -a "$LOG_FILE"
    
    # System Services
    log "${CYAN}=== Failed Services ===${NC}"
    systemctl --failed | tee -a "$LOG_FILE"
    
    log "${GREEN}Full system diagnostic completed. Check log: $LOG_FILE${NC}"
}

system_freeze_analysis() {
    log "${BLUE}=== System Freeze Analysis ===${NC}"
    
    # Check for hung tasks
    log "${CYAN}Checking for hung tasks...${NC}"
    if [ -r /proc/sys/kernel/hung_task_timeout_secs ]; then
        log "Hung task timeout: $(cat /proc/sys/kernel/hung_task_timeout_secs) seconds"
    fi
    
    # Check for tasks in D state
    local hung_tasks=$(ps axo pid,stat,comm | awk '$2 ~ /D/ {print $1 " " $3}')
    if [ -n "$hung_tasks" ]; then
        log "${YELLOW}Found tasks in uninterruptible sleep:${NC}"
        echo "$hung_tasks" | while read -r pid comm; do
            log "PID $pid: $comm"
        done
    else
        log "${GREEN}No hung tasks found${NC}"
    fi
    
    # Check I/O wait
    log "${CYAN}Checking I/O performance...${NC}"
    if command -v iostat >/dev/null 2>&1; then
        iostat -x 1 3 | tee -a "$LOG_FILE"
    else
        log "iostat not available (install sysstat package)"
    fi
    
    # Check for mount issues
    log "${CYAN}Checking mount points...${NC}"
    mount | grep -E "(ntfs|fuse)" | while read -r line; do
        local mountpoint=$(echo "$line" | awk '{print $3}')
        if ! timeout 5 ls "$mountpoint" >/dev/null 2>&1; then
            log "${YELLOW}Unresponsive mount: $mountpoint${NC}"
        fi
    done
    
    # Check kernel messages
    log "${CYAN}Recent kernel messages related to hangs/freezes:${NC}"
    dmesg | grep -i -E "(hung|freeze|blocked|deadlock)" | tail -20 | tee -a "$LOG_FILE"
    
    # Check journal for hung tasks
    if command -v journalctl >/dev/null 2>&1; then
        log "${CYAN}Journal entries for hung tasks:${NC}"
        journalctl -k | grep -i hung | tail -10 | tee -a "$LOG_FILE"
    fi
    
    log "${GREEN}Freeze analysis completed${NC}"
}

hardware_driver_check() {
    log "${BLUE}=== Hardware & Driver Status Check ===${NC}"
    
    # PCI devices
    log "${CYAN}=== PCI Devices ===${NC}"
    lspci | tee -a "$LOG_FILE"
    
    # USB devices
    log "${CYAN}=== USB Devices ===${NC}"
    lsusb | tee -a "$LOG_FILE"
    
    # Graphics information
    log "${CYAN}=== Graphics Information ===${NC}"
    lspci | grep -i vga | tee -a "$LOG_FILE"
    lspci | grep -i nvidia | tee -a "$LOG_FILE"
    
    # Check for proprietary drivers
    if command -v nvidia-smi >/dev/null 2>&1; then
        log "${CYAN}NVIDIA Driver Status:${NC}"
        nvidia-smi | tee -a "$LOG_FILE"
    fi
    
    # Check loaded modules
    log "${CYAN}=== Graphics Modules Loaded ===${NC}"
    lsmod | grep -E "(nvidia|nouveau|intel|radeon|amdgpu)" | tee -a "$LOG_FILE"
    
    # Check firmware issues
    log "${CYAN}=== Firmware Messages ===${NC}"
    dmesg | grep -i firmware | tail -10 | tee -a "$LOG_FILE"
    
    log "${GREEN}Hardware & driver check completed${NC}"
}

memory_storage_analysis() {
    log "${BLUE}=== Memory & Storage Analysis ===${NC}"
    
    # Detailed memory info
    log "${CYAN}=== Memory Information ===${NC}"
    cat /proc/meminfo | tee -a "$LOG_FILE"
    
    # Memory usage by process
    log "${CYAN}=== Top Memory Consumers ===${NC}"
    ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -20 | tee -a "$LOG_FILE"
    
    # Storage devices
    log "${CYAN}=== Storage Devices ===${NC}"
    lsblk | tee -a "$LOG_FILE"
    
    # Filesystem information
    log "${CYAN}=== Filesystem Types ===${NC}"
    mount | awk '{print $1 " " $3 " " $5}' | column -t | tee -a "$LOG_FILE"
    
    # Check for drive health if smartctl is available
    if command -v smartctl >/dev/null 2>&1; then
        log "${CYAN}=== Drive Health Check ===${NC}"
        for device in /dev/sd[a-z]; do
            if [ -b "$device" ]; then
                log "Checking $device:"
                smartctl -H "$device" 2>/dev/null | grep -E "(SMART overall-health|PASSED|FAILED)" | tee -a "$LOG_FILE"
            fi
        done
    fi
    
    log "${GREEN}Memory & storage analysis completed${NC}"
}

# ===== REPAIR FUNCTIONS =====

fix_system_freezes() {
    log "${BLUE}=== Fixing System Freezes & Hung Tasks ===${NC}"
    
    # Kill hung NTFS mount processes
    local hung_pids=$(ps aux | grep '[m]ount.ntfs' | awk '{print $2}')
    if [ -n "$hung_pids" ]; then
        log "${YELLOW}Found hung NTFS mount processes: $hung_pids${NC}"
        for pid in $hung_pids; do
            sudo kill -9 "$pid" 2>/dev/null && log "Killed hung mount.ntfs process: $pid"
        done
    fi
    
    # Fix FUSE mounts
    local fuse_mounts=$(mount | grep fuse)
    if [ -n "$fuse_mounts" ]; then
        echo "$fuse_mounts" | while read -r line; do
            local mountpoint=$(echo "$line" | awk '{print $3}')
            if ! timeout 5 ls "$mountpoint" >/dev/null 2>&1; then
                log "${YELLOW}Fixing unresponsive FUSE mount: $mountpoint${NC}"
                sudo fusermount -uz "$mountpoint" 2>/dev/null || true
            fi
        done
    fi
    
    # Reset hung task timeout
    echo 0 | sudo tee /proc/sys/kernel/hung_task_timeout_secs >/dev/null 2>&1 || true
    sleep 2
    echo 120 | sudo tee /proc/sys/kernel/hung_task_timeout_secs >/dev/null 2>&1 || true
    
    # Apply kernel performance tweaks
    sudo tee /etc/sysctl.d/99-freeze-fix.conf > /dev/null << EOF
# Reduce hung task timeout
kernel.hung_task_timeout_secs = 60
# Improve I/O performance  
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.vfs_cache_pressure = 50
vm.swappiness = 10
EOF
    
    sudo sysctl -p /etc/sysctl.d/99-freeze-fix.conf 2>/dev/null || true
    
    log "${GREEN}System freeze fixes applied${NC}"
}

disk_scan_repair() {
    log "${BLUE}=== Disk Scan & Filesystem Repair ===${NC}"
    
    if [ "$EUID" -ne 0 ]; then
        log "${RED}Disk repair requires root privileges. Please run with sudo.${NC}"
        return 1
    fi
    
    # Install required tools
    local tools_to_install=()
    command -v fsck >/dev/null 2>&1 || tools_to_install+=("e2fsprogs")
    command -v xfs_repair >/dev/null 2>&1 || tools_to_install+=("xfsprogs")
    command -v ntfsfix >/dev/null 2>&1 || tools_to_install+=("ntfs-3g")
    
    if [ ${#tools_to_install[@]} -gt 0 ]; then
        log "Installing required tools: ${tools_to_install[*]}"
        dnf install -y "${tools_to_install[@]}" 2>/dev/null || true
    fi
    
    # Find mounted filesystems
    local mount_points=()
    while IFS= read -r line; do
        local mount_point=$(echo "$line" | awk '{print $2}')
        if [[ "$mount_point" == /run/media/* ]]; then
            mount_points+=("$mount_point")
        fi
    done < <(mount | grep -E "^/dev/")
    
    if [ ${#mount_points[@]} -eq 0 ]; then
        log "${YELLOW}No external drives found to repair${NC}"
        return 0
    fi
    
    for mount_point in "${mount_points[@]}"; do
        local device=$(mount | grep " $mount_point " | awk '{print $1}')
        local fs_type=$(mount | grep " $mount_point " | awk '{print $5}')
        
        log "${CYAN}Processing: $device ($fs_type) at $mount_point${NC}"
        
        # Unmount filesystem
        if umount "$mount_point" 2>/dev/null; then
            log "Unmounted $mount_point"
            
            # Repair based on filesystem type
            case "$fs_type" in
                ext2|ext3|ext4)
                    log "Running fsck on $device..."
                    fsck -y "$device" 2>&1 | tee -a "$LOG_FILE"
                    ;;
                xfs)
                    log "Running xfs_repair on $device..."
                    xfs_repair "$device" 2>&1 | tee -a "$LOG_FILE"
                    ;;
                ntfs)
                    log "Running ntfsfix on $device..."
                    ntfsfix "$device" 2>&1 | tee -a "$LOG_FILE"
                    ;;
                *)
                    log "${YELLOW}Unsupported filesystem: $fs_type${NC}"
                    ;;
            esac
            
            # Remount
            mount "$device" "$mount_point" 2>/dev/null && log "Remounted $device"
        else
            log "${YELLOW}Could not unmount $mount_point, skipping${NC}"
        fi
    done
    
    log "${GREEN}Disk scan and repair completed${NC}"
}

io_performance_optimization() {
    log "${BLUE}=== I/O Performance Optimization ===${NC}"
    
    # Sync and drop caches
    log "Syncing filesystems..."
    sync
    
    log "Dropping filesystem caches..."
    echo 1 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    echo 2 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true  
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null 2>&1 || true
    
    # Set I/O scheduler
    for disk in /sys/block/sd*/queue/scheduler; do
        if [ -f "$disk" ]; then
            echo mq-deadline | sudo tee "$disk" >/dev/null 2>&1 || true
            log "Set I/O scheduler for $(dirname "$disk" | cut -d'/' -f4)"
        fi
    done
    
    # Install diagnostic tools if missing
    if ! command -v iostat >/dev/null 2>&1; then
        log "Installing sysstat for I/O monitoring..."
        sudo dnf install -y sysstat 2>/dev/null || true
    fi
    
    log "${GREEN}I/O performance optimization completed${NC}"
}

general_system_fixes() {
    log "${BLUE}=== General System Error Fixes ===${NC}"
    
    # Update package database
    log "Updating package database..."
    sudo dnf check-update 2>&1 | tee -a "$LOG_FILE" || true
    
    # Fix broken packages
    log "Checking for broken packages..."
    sudo dnf autoremove -y 2>&1 | tee -a "$LOG_FILE" || true
    
    # Clean package cache
    log "Cleaning package cache..."
    sudo dnf clean all 2>&1 | tee -a "$LOG_FILE" || true
    
    # Fix SELinux context issues
    if command -v restorecon >/dev/null 2>&1; then
        log "Restoring SELinux contexts..."
        sudo restorecon -R /home 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Update initramfs
    log "Updating initramfs..."
    sudo dracut -f 2>&1 | tee -a "$LOG_FILE" || true
    
    # Fix systemd issues
    log "Reloading systemd..."
    sudo systemctl daemon-reload
    
    log "${GREEN}General system fixes completed${NC}"
}

# ===== ADVANCED FUNCTIONS =====

custom_diagnostic_session() {
    log "${BLUE}=== Custom Diagnostic Session ===${NC}"
    
    echo "Select diagnostic components:"
    echo "1. Memory analysis"
    echo "2. CPU analysis" 
    echo "3. Disk I/O analysis"
    echo "4. Network analysis"
    echo "5. Process analysis"
    echo "6. Hardware analysis"
    echo ""
    read -p "Enter components (e.g., 1,3,5): " components
    
    IFS=',' read -ra selected <<< "$components"
    for component in "${selected[@]}"; do
        case "$component" in
            1) 
                log "${CYAN}=== Memory Analysis ===${NC}"
                free -h && cat /proc/meminfo | head -20
                ;;
            2)
                log "${CYAN}=== CPU Analysis ===${NC}"
                lscpu && top -b -n 1 | head -20
                ;;
            3)
                log "${CYAN}=== Disk I/O Analysis ===${NC}"
                df -h && lsblk
                command -v iostat >/dev/null && iostat -x 1 3
                ;;
            4)
                log "${CYAN}=== Network Analysis ===${NC}"
                ip addr show && ss -tuln | head -20
                ;;
            5)
                log "${CYAN}=== Process Analysis ===${NC}"
                ps aux --sort=-%cpu | head -20
                ;;
            6)
                log "${CYAN}=== Hardware Analysis ===${NC}"
                lspci && lsusb
                ;;
        esac
    done | tee -a "$LOG_FILE"
    
    log "${GREEN}Custom diagnostic session completed${NC}"
}

generate_health_report() {
    log "${BLUE}=== Generating System Health Report ===${NC}"
    
    local report_file="$HOME/system_health_report_$(date +'%Y%m%d_%H%M%S').html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>System Health Report - $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ccc; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .error { color: red; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>System Health Report</h1>
        <p>Generated: $(date)</p>
        <p>Hostname: $(hostname)</p>
        <p>OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null)</p>
    </div>
    
    <div class="section">
        <h2>System Overview</h2>
        <pre>$(uptime)</pre>
        <pre>$(free -h)</pre>
        <pre>$(df -h)</pre>
    </div>
    
    <div class="section">
        <h2>Hardware Information</h2>
        <pre>$(lscpu | head -10)</pre>
        <pre>$(lsblk)</pre>
    </div>
    
    <div class="section">
        <h2>System Status</h2>
        <pre>$(systemctl --failed)</pre>
    </div>
    
    <div class="section">
        <h2>Top Processes</h2>
        <pre>$(ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -15)</pre>
    </div>
    
</body>
</html>
EOF
    
    log "${GREEN}Health report generated: $report_file${NC}"
    echo -e "${CYAN}You can open the report with: firefox $report_file${NC}"
}

reset_system_configurations() {
    log "${BLUE}=== Resetting System Configurations ===${NC}"
    
    echo -e "${RED}WARNING: This will reset various system configurations!${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "${YELLOW}Reset cancelled by user${NC}"
        return 0
    fi
    
    # Reset network configuration
    log "Resetting network configuration..."
    sudo systemctl restart NetworkManager 2>/dev/null || true
    
    # Reset font cache
    log "Rebuilding font cache..."
    fc-cache -fv 2>/dev/null || true
    
    # Reset systemd
    log "Reloading systemd configuration..."
    sudo systemctl daemon-reload
    
    # Reset user sessions
    log "Resetting user sessions..."
    loginctl terminate-user "$USER" 2>/dev/null || true
    
    log "${GREEN}System configuration reset completed${NC}"
    log "${YELLOW}You may need to log out and back in for all changes to take effect${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== System Diagnostics And Repair Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) full_system_diagnostic ;;
            2) system_freeze_analysis ;;
            3) hardware_driver_check ;;
            4) memory_storage_analysis ;;
            5) fix_system_freezes ;;
            6) disk_scan_repair ;;
            7) io_performance_optimization ;;
            8) general_system_fixes ;;
            9) custom_diagnostic_session ;;
            10) generate_health_report ;;
            11) reset_system_configurations ;;
            12) 
                log "${GREEN}Exiting System Diagnostics Suite${NC}"
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

# Check if running as root for some operations
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}Running as root - all repair functions available${NC}"
else
    echo -e "${YELLOW}Running as user - some repair functions will require sudo${NC}"
fi

main "$@"
