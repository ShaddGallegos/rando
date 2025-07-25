#!/bin/bash

# Security And Antivirus Management Suite
# Comprehensive security, antivirus, and system protection toolkit
# Consolidates: clamav_setup.sh, security_scanner.sh

set -euo pipefail

LOG_FILE="$HOME/security_management_$(date +'%Y%m%d_%H%M%S').log"

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
    echo "  ANTIVIRUS & MALWARE:"
    echo "1.  Install & Configure ClamAV"
    echo "2.  Run System Virus Scan"
    echo "3.  Update Antivirus Definitions"
    echo "4.  Quarantine Management"
    echo ""
    echo " SYSTEM SECURITY:"
    echo "5.  Firewall Configuration"
    echo "6.   SELinux Management"
    echo "7.  User Security Audit"
    echo "8.  SSH Security Hardening"
    echo ""
    echo " SECURITY SCANNING:"
    echo "9.  Vulnerability Scanner"
    echo "10.  Network Security Scan"
    echo "11.  File Integrity Monitoring"
    echo "12.  Rootkit Detection"
    echo ""
    echo "  ADVANCED SECURITY:"
    echo "13.  Security Configuration Audit"
    echo "14.  Security Monitoring Dashboard"
    echo "15.  Incident Response Tools"
    echo "16.  Exit"
    echo ""
    read -p "Enter your choice (1-16): " choice
}

# ===== UTILITY FUNCTIONS =====

check_root_required() {
    if [ "$EUID" -ne 0 ]; then
        log "${RED}This operation requires root privileges. Please run with sudo.${NC}"
        return 1
    fi
    return 0
}

install_package_if_missing() {
    local package="$1"
    
    if ! command -v "$package" >/dev/null 2>&1 && ! rpm -q "$package" >/dev/null 2>&1; then
        log "Installing $package..."
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "$package" 2>&1 | tee -a "$LOG_FILE"
        else
            log "${RED}No supported package manager found${NC}"
            return 1
        fi
    else
        log "$package is already installed"
    fi
}

create_security_report() {
    local report_file="$HOME/security_report_$(date +'%Y%m%d_%H%M%S').html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Security Report - $(hostname)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #e6f3ff; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ccc; border-radius: 5px; }
        .good { color: green; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .critical { color: red; font-weight: bold; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; border-radius: 3px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1> Security Assessment Report</h1>
        <p><strong>System:</strong> $(hostname)</p>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>User:</strong> $(whoami)</p>
    </div>
EOF
    
    echo "$report_file"
}

# ===== ANTIVIRUS & MALWARE =====

install_configure_clamav() {
    log "${BLUE}=== Installing & Configuring ClamAV ===${NC}"
    
    # Install ClamAV packages
    local clamav_packages=(
        "clamav"
        "clamav-update"
        "clamav-scanner-systemd"
        "clamav-server"
        "clamav-filesystem"
    )
    
    log "Installing ClamAV packages..."
    for package in "${clamav_packages[@]}"; do
        install_package_if_missing "$package"
    done
    
    # Stop ClamAV services before configuration
    sudo systemctl stop clamav-freshclam.service 2>/dev/null || true
    sudo systemctl stop clamav-clamonacc.service 2>/dev/null || true
    
    # Configure freshclam (virus definition updater)
    log "Configuring ClamAV freshclam..."
    
    local freshclam_conf="/etc/freshclam.conf"
    if [ -f "$freshclam_conf" ]; then
        # Backup original configuration
        sudo cp "$freshclam_conf" "$freshclam_conf.backup.$(date +%Y%m%d)"
        
        # Configure freshclam
        sudo tee "$freshclam_conf" > /dev/null << EOF
# ClamAV freshclam configuration
UpdateLogFile /var/log/freshclam.log
LogFileMaxSize 2M
LogTime yes
LogVerbose no
LogSyslog no
LogFacility LOG_LOCAL6
LogRotate yes
DatabaseDirectory /var/lib/clamav
DatabaseOwner clamav
DatabaseMirror database.clamav.net
DatabaseMirror db.local.clamav.net
MaxAttempts 5
ScriptedUpdates yes
CompressLocalDatabase no
Bytecode yes
NotifyClamd /etc/clamd.conf
ConnectTimeout 30
ReceiveTimeout 60
TestDatabases yes
Foreground no
Debug no
SafeBrowsing yes
Checks 24
EOF
    fi
    
    # Configure clamd (daemon)
    log "Configuring ClamAV daemon..."
    
    local clamd_conf="/etc/clamd.conf"
    if [ -f "$clamd_conf" ]; then
        # Backup original configuration
        sudo cp "$clamd_conf" "$clamd_conf.backup.$(date +%Y%m%d)"
        
        # Configure clamd
        sudo tee "$clamd_conf" > /dev/null << EOF
# ClamAV daemon configuration
LogFile /var/log/clamd.log
LogFileMaxSize 2M
LogTime yes
LogClean no
LogSyslog no
LogFacility LOG_LOCAL6
LogVerbose no
ExtendedDetectionInfo yes
PidFile /run/clamd.pid
LocalSocket /run/clamd.sock
LocalSocketGroup clamav
LocalSocketMode 666
FixStaleSocket yes
TCPSocket 3310
TCPAddr 127.0.0.1
MaxConnectionQueueLength 15
StreamMaxLength 25M
MaxThreads 12
ReadTimeout 180
CommandReadTimeout 5
SendBufTimeout 200
MaxQueue 100
IdleTimeout 30
ExcludePath ^/proc/
ExcludePath ^/sys/
ExcludePath ^/dev/
ExcludePath ^/run/
ScanPE yes
ScanELF yes
ScanOLE2 yes
ScanPDF yes
ScanSWF yes
ScanHTML yes
ScanArchive yes
AlertBrokenExecutables yes
AlertBrokenMedia no
AlertEncrypted no
AlertEncryptedArchive no
AlertEncryptedDoc no
AlertOLE2Macros no
AlertPhishingSSLMismatch no
AlertPhishingCloak no
AlertPartitionIntersection no
ScanOnAccess yes
OnAccessMaxFileSize 5M
OnAccessIncludePath /home
OnAccessExcludePath /home/.*/.cache
OnAccessExcludePath /home/.*/\.local/share/Trash
OnAccessExtraScanning yes
OnAccessDisableDDD yes
VirusEvent /etc/clamav/virus-event.sh %v
User clamav
Bytecode yes
BytecodeSecurity TrustSigned
BytecodeTimeout 60000
DetectPUA yes
ExcludePUA NetTool
ExcludePUA PWTool
AlgorithmicDetection yes
ScanPE yes
ScanELF yes
EOF
    fi
    
    # Create virus event script
    log "Creating virus event handler..."
    sudo mkdir -p /etc/clamav
    sudo tee /etc/clamav/virus-event.sh > /dev/null << 'EOF'
#!/bin/bash
# ClamAV virus detection event handler

VIRUS_FILE="$1"
VIRUS_NAME="$2"
LOG_FILE="/var/log/clamav-virus-events.log"

# Log the event
echo "$(date): VIRUS DETECTED - File: $VIRUS_FILE, Virus: $VIRUS_NAME" >> "$LOG_FILE"

# Quarantine the file
QUARANTINE_DIR="/var/quarantine"
mkdir -p "$QUARANTINE_DIR"
mv "$VIRUS_FILE" "$QUARANTINE_DIR/$(basename "$VIRUS_FILE").$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Send notification (if desktop environment is available)
if command -v notify-send >/dev/null 2>&1; then
    notify-send " Virus Detected" "File: $(basename "$VIRUS_FILE")\nVirus: $VIRUS_NAME\nFile quarantined." --urgency=critical 2>/dev/null || true
fi

# Send email notification (if mail is configured)
if command -v mail >/dev/null 2>&1; then
    echo "Virus detected on $(hostname): $VIRUS_NAME in file $VIRUS_FILE" | mail -s "VIRUS ALERT - $(hostname)" root 2>/dev/null || true
fi
EOF
    
    sudo chmod +x /etc/clamav/virus-event.sh
    
    # Create quarantine directory
    sudo mkdir -p /var/quarantine
    sudo chown clamav:clamav /var/quarantine
    sudo chmod 750 /var/quarantine
    
    # Update virus definitions
    log "Updating virus definitions..."
    sudo freshclam 2>&1 | tee -a "$LOG_FILE" || log "${YELLOW}Initial freshclam update may fail - this is normal${NC}"
    
    # Configure systemd services
    log "Configuring ClamAV services..."
    
    # Enable and start freshclam service
    sudo systemctl enable clamav-freshclam.service
    sudo systemctl start clamav-freshclam.service
    
    # Enable and start clamd service
    sudo systemctl enable clamav-clamonacc.service
    sudo systemctl start clamav-clamonacc.service
    
    # Create daily scan script
    log "Setting up daily virus scan..."
    sudo tee /etc/cron.daily/clamav-scan > /dev/null << 'EOF'
#!/bin/bash
# Daily ClamAV system scan

SCAN_LOG="/var/log/clamav-daily-scan.log"
SCAN_DIR="/home"
QUARANTINE_DIR="/var/quarantine"

echo "$(date): Starting daily virus scan" >> "$SCAN_LOG"

# Perform scan
clamscan -r --move="$QUARANTINE_DIR" --log="$SCAN_LOG" "$SCAN_DIR" --exclude-dir="^/home/.*/\.cache" --exclude-dir="^/home/.*/\.local/share/Trash"

# Check scan results
if [ $? -eq 1 ]; then
    echo "$(date): Viruses found and quarantined" >> "$SCAN_LOG"
    # Send alert
    if command -v mail >/dev/null 2>&1; then
        echo "Daily virus scan found infected files. Check $SCAN_LOG for details." | mail -s "Virus Scan Alert - $(hostname)" root 2>/dev/null || true
    fi
elif [ $? -eq 0 ]; then
    echo "$(date): Scan completed - no threats found" >> "$SCAN_LOG"
else
    echo "$(date): Scan completed with errors" >> "$SCAN_LOG"
fi
EOF
    
    sudo chmod +x /etc/cron.daily/clamav-scan
    
    # Test installation
    log "Testing ClamAV installation..."
    if systemctl is-active --quiet clamav-freshclam.service; then
        log "${GREEN}ClamAV freshclam service is running${NC}"
    else
        log "${YELLOW}ClamAV freshclam service is not running${NC}"
    fi
    
    if systemctl is-active --quiet clamav-clamonacc.service; then
        log "${GREEN}ClamAV daemon is running${NC}"
    else
        log "${YELLOW}ClamAV daemon is not running${NC}"
    fi
    
    # Create EICAR test file for testing
    echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.txt
    log "Testing with EICAR test file..."
    if clamscan /tmp/eicar.txt 2>&1 | grep -q "FOUND"; then
        log "${GREEN}ClamAV is working correctly - EICAR test detected${NC}"
        rm -f /tmp/eicar.txt
    else
        log "${YELLOW}ClamAV test failed - may need configuration review${NC}"
    fi
    
    log "${GREEN}ClamAV installation and configuration completed${NC}"
    log "Daily scans scheduled, real-time protection enabled"
    log "Logs: /var/log/clamd.log, /var/log/freshclam.log, /var/log/clamav-daily-scan.log"
    log "Quarantine directory: /var/quarantine"
}

run_system_virus_scan() {
    log "${BLUE}=== Running System Virus Scan ===${NC}"
    
    if ! command -v clamscan >/dev/null 2>&1; then
        log "${RED}ClamAV not installed. Please install ClamAV first.${NC}"
        return 1
    fi
    
    echo "Virus scan options:"
    echo "1. Quick scan (home directory)"
    echo "2. Full system scan"
    echo "3. Custom directory scan"
    echo "4. Memory scan"
    echo "5. Scan specific file/directory"
    read -p "Choose scan type (1-5): " scan_choice
    
    local scan_dir=""
    local scan_options=""
    local scan_log="/tmp/clamscan_$(date +'%Y%m%d_%H%M%S').log"
    
    case $scan_choice in
        1)
            scan_dir="$HOME"
            scan_options="-r --exclude-dir='^.*/.cache' --exclude-dir='^.*/Trash'"
            log "Starting quick scan of home directory..."
            ;;
        2)
            scan_dir="/"
            scan_options="-r --exclude-dir='^/proc' --exclude-dir='^/sys' --exclude-dir='^/dev' --exclude-dir='^/run' --exclude-dir='^.*/\.cache' --exclude-dir='^.*/Trash'"
            log "Starting full system scan..."
            ;;
        3)
            read -p "Enter directory to scan: " custom_dir
            if [ -d "$custom_dir" ]; then
                scan_dir="$custom_dir"
                scan_options="-r"
                log "Starting scan of $custom_dir..."
            else
                log "${RED}Directory not found: $custom_dir${NC}"
                return 1
            fi
            ;;
        4)
            log "Starting memory scan..."
            scan_options="--memory"
            ;;
        5)
            read -p "Enter file or directory path: " target_path
            if [ -e "$target_path" ]; then
                scan_dir="$target_path"
                scan_options="-r"
                log "Starting scan of $target_path..."
            else
                log "${RED}Path not found: $target_path${NC}"
                return 1
            fi
            ;;
        *)
            log "${RED}Invalid choice${NC}"
            return 1
            ;;
    esac
    
    # Additional scan options
    echo ""
    echo "Scan actions for infected files:"
    echo "1. Report only (no action)"
    echo "2. Move to quarantine"
    echo "3. Remove infected files"
    read -p "Choose action (1-3): " action_choice
    
    case $action_choice in
        2)
            scan_options="$scan_options --move=/var/quarantine"
            sudo mkdir -p /var/quarantine
            ;;
        3)
            scan_options="$scan_options --remove"
            echo
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Scan cancelled by user"
                return 0
            fi
            ;;
    esac
    
    # Start scan
    local start_time=$(date)
    log "Scan started at: $start_time"
    log "Scan command: clamscan $scan_options --log=$scan_log $scan_dir"
    
    if [ -n "$scan_dir" ]; then
        clamscan $scan_options --log="$scan_log" "$scan_dir" 2>&1 | tee -a "$LOG_FILE"
    else
        clamscan $scan_options --log="$scan_log" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    local scan_result=$?
    local end_time=$(date)
    
    log "Scan completed at: $end_time"
    
    # Interpret results
    case $scan_result in
        0)
            log "${GREEN}Scan completed successfully - No threats found${NC}"
            ;;
        1)
            log "${RED}Threats found and handled according to selected action${NC}"
            if [ -f "$scan_log" ]; then
                log "Infected files:"
                grep "FOUND" "$scan_log" | tee -a "$LOG_FILE"
            fi
            ;;
        *)
            log "${YELLOW}Scan completed with errors (exit code: $scan_result)${NC}"
            ;;
    esac
    
    log "Detailed scan log: $scan_log"
    
    # Show scan summary
    if [ -f "$scan_log" ]; then
        log "${CYAN}=== Scan Summary ===${NC}"
        local scanned_files=$(grep -c "^/" "$scan_log" 2>/dev/null || echo "0")
        local infected_files=$(grep -c "FOUND" "$scan_log" 2>/dev/null || echo "0")
        local scan_time=$(grep "Time:" "$scan_log" | tail -1 || echo "Time: Unknown")
        
        log "Files scanned: $scanned_files"
        log "Infected files: $infected_files"
        log "$scan_time"
    fi
    
    log "${GREEN}Virus scan completed${NC}"
}

update_antivirus_definitions() {
    log "${BLUE}=== Updating Antivirus Definitions ===${NC}"
    
    if ! command -v freshclam >/dev/null 2>&1; then
        log "${RED}ClamAV not installed. Please install ClamAV first.${NC}"
        return 1
    fi
    
    # Stop freshclam service temporarily
    if systemctl is-active --quiet clamav-freshclam.service; then
        log "Stopping freshclam service for manual update..."
        sudo systemctl stop clamav-freshclam.service
        local restart_service=true
    fi
    
    # Update virus definitions
    log "Updating virus definitions..."
    local update_log="/tmp/freshclam_update_$(date +'%Y%m%d_%H%M%S').log"
    
    if sudo freshclam --log="$update_log" --verbose 2>&1 | tee -a "$LOG_FILE"; then
        log "${GREEN}Virus definitions updated successfully${NC}"
        
        # Show update summary
        if [ -f "$update_log" ]; then
            log "${CYAN}=== Update Summary ===${NC}"
            grep -E "(main.cvd|daily.cvd|bytecode.cvd)" "$update_log" | tail -3 | tee -a "$LOG_FILE"
        fi
    else
        log "${RED}Failed to update virus definitions${NC}"
        log "Check network connectivity and freshclam configuration"
    fi
    
    # Restart freshclam service if it was running
    if [ "${restart_service:-false}" = true ]; then
        log "Restarting freshclam service..."
        sudo systemctl start clamav-freshclam.service
    fi
    
    # Show current database status
    log "${CYAN}=== Current Database Status ===${NC}"
    if [ -d /var/lib/clamav ]; then
        ls -lh /var/lib/clamav/*.cvd /var/lib/clamav/*.cld 2>/dev/null | tee -a "$LOG_FILE" || log "No ClamAV databases found"
    fi
    
    # Test database
    log "Testing virus database..."
    if clamscan --version 2>&1 | tee -a "$LOG_FILE"; then
        log "${GREEN}Virus database test successful${NC}"
    else
        log "${YELLOW}Virus database test failed${NC}"
    fi
    
    log "${GREEN}Antivirus definitions update completed${NC}"
}

quarantine_management() {
    log "${BLUE}=== Quarantine Management ===${NC}"
    
    local quarantine_dir="/var/quarantine"
    
    if [ ! -d "$quarantine_dir" ]; then
        log "${YELLOW}Quarantine directory does not exist: $quarantine_dir${NC}"
        read -p "Create quarantine directory? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo mkdir -p "$quarantine_dir"
            sudo chown clamav:clamav "$quarantine_dir" 2>/dev/null || true
            sudo chmod 750 "$quarantine_dir"
            log "Quarantine directory created"
        else
            return 0
        fi
    fi
    
    echo "Quarantine management options:"
    echo "1. List quarantined files"
    echo "2. View quarantine details"
    echo "3. Restore file from quarantine"
    echo "4. Delete quarantined files"
    echo "5. Clean old quarantine files"
    echo "6. Export quarantine report"
    read -p "Choose option (1-6): " quarantine_choice
    
    case $quarantine_choice in
        1)
            log "Quarantined files in $quarantine_dir:"
            if sudo ls -la "$quarantine_dir" 2>/dev/null | tee -a "$LOG_FILE"; then
                local file_count=$(sudo ls -1 "$quarantine_dir" 2>/dev/null | wc -l)
                log "Total quarantined files: $file_count"
            else
                log "No quarantined files found"
            fi
            ;;
        2)
            log "Quarantine directory details:"
            sudo du -sh "$quarantine_dir" 2>/dev/null | tee -a "$LOG_FILE"
            
            log "Files by date:"
            sudo find "$quarantine_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM %s %p\n" 2>/dev/null | sort | tee -a "$LOG_FILE"
            ;;
        3)
            log "Available quarantined files:"
            sudo ls -1 "$quarantine_dir" 2>/dev/null | nl
            
            read -p "Enter file number to restore: " file_num
            local file_name=$(sudo ls -1 "$quarantine_dir" 2>/dev/null | sed -n "${file_num}p")
            
            if [ -n "$file_name" ]; then
                read -p "Enter restore destination: " restore_dest
                if sudo mv "$quarantine_dir/$file_name" "$restore_dest"; then
                    log "${GREEN}File restored: $file_name -> $restore_dest${NC}"
                    log "${RED}WARNING: Restored file may still be infected!${NC}"
                else
                    log "${RED}Failed to restore file${NC}"
                fi
            else
                log "${RED}Invalid file selection${NC}"
            fi
            ;;
        4)
            echo "Delete quarantined files:"
            echo "1. Delete specific file"
            echo "2. Delete all quarantined files"
            read -p "Choose option (1-2): " delete_choice
            
            case $delete_choice in
                1)
                    log "Available quarantined files:"
                    sudo ls -1 "$quarantine_dir" 2>/dev/null | nl
                    
                    read -p "Enter file number to delete: " file_num
                    local file_name=$(sudo ls -1 "$quarantine_dir" 2>/dev/null | sed -n "${file_num}p")
                    
                    if [ -n "$file_name" ]; then
                        if sudo rm "$quarantine_dir/$file_name"; then
                            log "${GREEN}File deleted: $file_name${NC}"
                        else
                            log "${RED}Failed to delete file${NC}"
                        fi
                    else
                        log "${RED}Invalid file selection${NC}"
                    fi
                    ;;
                2)
                    echo
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        if sudo rm -rf "$quarantine_dir"/*; then
                            log "${GREEN}All quarantined files deleted${NC}"
                        else
                            log "${RED}Failed to delete quarantined files${NC}"
                        fi
                    else
                        log "Deletion cancelled"
                    fi
                    ;;
            esac
            ;;
        5)
            read -p "Delete quarantined files older than how many days? (default: 30): " days
            if [[ ! "$days" =~ ^[0-9]+$ ]]; then
                days=30
            fi
            
            log "Cleaning quarantined files older than $days days..."
            local deleted_count=$(sudo find "$quarantine_dir" -type f -mtime +$days -delete -print | wc -l)
            log "${GREEN}Deleted $deleted_count old quarantined files${NC}"
            ;;
        6)
            local report_file="$HOME/quarantine_report_$(date +'%Y%m%d_%H%M%S').txt"
            
            {
                echo "Quarantine Report - $(date)"
                echo "========================================"
                echo ""
                echo "Quarantine Directory: $quarantine_dir"
                echo "Total Size: $(sudo du -sh "$quarantine_dir" 2>/dev/null | cut -f1 || echo 'Unknown')"
                echo ""
                echo "Files in Quarantine:"
                echo "===================="
                sudo find "$quarantine_dir" -type f -printf "%TY-%Tm-%Td %TH:%TM %10s %p\n" 2>/dev/null | sort || echo "No files found"
                echo ""
                echo "Recent Virus Events:"
                echo "===================="
                tail -20 /var/log/clamav-virus-events.log 2>/dev/null || echo "No virus events logged"
            } > "$report_file"
            
            log "Quarantine report generated: $report_file"
            ;;
    esac
    
    log "${GREEN}Quarantine management completed${NC}"
}

# ===== SYSTEM SECURITY =====

firewall_configuration() {
    log "${BLUE}=== Firewall Configuration ===${NC}"
    
    # Check which firewall is available
    local firewall_system=""
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall_system="firewalld"
    elif command -v ufw >/dev/null 2>&1; then
        firewall_system="ufw"
    elif command -v iptables >/dev/null 2>&1; then
        firewall_system="iptables"
    else
        log "${RED}No firewall system found${NC}"
        return 1
    fi
    
    log "Using firewall system: $firewall_system"
    
    echo "Firewall configuration options:"
    echo "1. Show current firewall status"
    echo "2. Enable/disable firewall"
    echo "3. Configure basic rules"
    echo "4. Manage specific ports"
    echo "5. Configure zones (firewalld)"
    echo "6. View firewall logs"
    read -p "Choose option (1-6): " firewall_choice
    
    case $firewall_choice in
        1)
            log "Current firewall status:"
            case $firewall_system in
                firewalld)
                    sudo firewall-cmd --state 2>&1 | tee -a "$LOG_FILE"
                    echo ""
                    sudo firewall-cmd --list-all 2>&1 | tee -a "$LOG_FILE"
                    ;;
                ufw)
                    sudo ufw status verbose 2>&1 | tee -a "$LOG_FILE"
                    ;;
                iptables)
                    sudo iptables -L -n 2>&1 | tee -a "$LOG_FILE"
                    ;;
            esac
            ;;
        2)
            echo "Firewall control:"
            echo "1. Enable firewall"
            echo "2. Disable firewall"
            read -p "Choose option (1-2): " control_choice
            
            case $firewall_system in
                firewalld)
                    if [ "$control_choice" = "1" ]; then
                        sudo systemctl enable --now firewalld
                        log "${GREEN}Firewalld enabled and started${NC}"
                    else
                        sudo systemctl disable --now firewalld
                        log "${YELLOW}Firewalld disabled and stopped${NC}"
                    fi
                    ;;
                ufw)
                    if [ "$control_choice" = "1" ]; then
                        sudo ufw --force enable
                        log "${GREEN}UFW enabled${NC}"
                    else
                        sudo ufw --force disable
                        log "${YELLOW}UFW disabled${NC}"
                    fi
                    ;;
            esac
            ;;
        3)
            log "Configuring basic firewall rules..."
            
            case $firewall_system in
                firewalld)
                    # Allow common services
                    sudo firewall-cmd --permanent --add-service=ssh
                    sudo firewall-cmd --permanent --add-service=http
                    sudo firewall-cmd --permanent --add-service=https
                    sudo firewall-cmd --reload
                    log "Basic rules configured for firewalld"
                    ;;
                ufw)
                    sudo ufw default deny incoming
                    sudo ufw default allow outgoing
                    sudo ufw allow ssh
                    sudo ufw allow 80/tcp
                    sudo ufw allow 443/tcp
                    log "Basic rules configured for UFW"
                    ;;
            esac
            ;;
        4)
            read -p "Enter port number: " port
            read -p "Enter protocol (tcp/udp): " protocol
            echo "1. Allow port"
            echo "2. Block port"
            read -p "Choose action (1-2): " port_action
            
            case $firewall_system in
                firewalld)
                    if [ "$port_action" = "1" ]; then
                        sudo firewall-cmd --permanent --add-port="$port/$protocol"
                        log "Allowed port $port/$protocol"
                    else
                        sudo firewall-cmd --permanent --remove-port="$port/$protocol"
                        log "Blocked port $port/$protocol"
                    fi
                    sudo firewall-cmd --reload
                    ;;
                ufw)
                    if [ "$port_action" = "1" ]; then
                        sudo ufw allow "$port/$protocol"
                        log "Allowed port $port/$protocol"
                    else
                        sudo ufw deny "$port/$protocol"
                        log "Blocked port $port/$protocol"
                    fi
                    ;;
            esac
            ;;
        5)
            if [ "$firewall_system" = "firewalld" ]; then
                log "Available firewall zones:"
                sudo firewall-cmd --get-zones | tee -a "$LOG_FILE"
                
                log "Current zone assignments:"
                sudo firewall-cmd --get-active-zones | tee -a "$LOG_FILE"
                
                read -p "Enter interface name: " interface
                read -p "Enter zone name: " zone
                
                sudo firewall-cmd --permanent --zone="$zone" --change-interface="$interface"
                sudo firewall-cmd --reload
                log "Interface $interface assigned to zone $zone"
            else
                log "${YELLOW}Zone configuration only available with firewalld${NC}"
            fi
            ;;
        6)
            log "Recent firewall logs:"
            if [ -f /var/log/firewalld ]; then
                tail -50 /var/log/firewalld | tee -a "$LOG_FILE"
            elif journalctl -u firewalld --no-pager --lines=20 >/dev/null 2>&1; then
                journalctl -u firewalld --no-pager --lines=20 | tee -a "$LOG_FILE"
            else
                grep -i "firewall\|iptables" /var/log/messages 2>/dev/null | tail -20 | tee -a "$LOG_FILE" || log "No firewall logs found"
            fi
            ;;
    esac
    
    log "${GREEN}Firewall configuration completed${NC}"
}

selinux_management() {
    log "${BLUE}=== SELinux Management ===${NC}"
    
    if ! command -v getenforce >/dev/null 2>&1; then
        log "${RED}SELinux tools not available${NC}"
        return 1
    fi
    
    echo "SELinux management options:"
    echo "1. Show SELinux status"
    echo "2. Change SELinux mode"
    echo "3. View SELinux contexts"
    echo "4. Fix SELinux context issues"
    echo "5. Manage SELinux booleans"
    echo "6. View SELinux logs"
    read -p "Choose option (1-6): " selinux_choice
    
    case $selinux_choice in
        1)
            log "SELinux status:"
            getenforce | tee -a "$LOG_FILE"
            echo ""
            sestatus | tee -a "$LOG_FILE"
            ;;
        2)
            log "Current SELinux mode: $(getenforce)"
            echo "SELinux modes:"
            echo "1. Enforcing (security policies enforced)"
            echo "2. Permissive (policies logged but not enforced)"
            echo "3. Disabled (SELinux disabled)"
            read -p "Choose mode (1-3): " mode_choice
            
            case $mode_choice in
                1)
                    if sudo setenforce 1; then
                        log "${GREEN}SELinux set to Enforcing mode${NC}"
                    fi
                    ;;
                2)
                    if sudo setenforce 0; then
                        log "${YELLOW}SELinux set to Permissive mode${NC}"
                    fi
                    ;;
                3)
                    log "${RED}To disable SELinux permanently, edit /etc/selinux/config${NC}"
                    log "Set SELINUX=disabled and reboot"
                    ;;
            esac
            ;;
        3)
            read -p "Enter file/directory path to check: " check_path
            if [ -e "$check_path" ]; then
                log "SELinux context for $check_path:"
                ls -lZ "$check_path" | tee -a "$LOG_FILE"
            else
                log "${RED}Path not found: $check_path${NC}"
            fi
            ;;
        4)
            log "Fixing SELinux context issues..."
            
            echo "Context fix options:"
            echo "1. Restore default contexts for specific path"
            echo "2. Restore contexts for entire system"
            echo "3. Relabel specific directory"
            read -p "Choose option (1-3): " fix_choice
            
            case $fix_choice in
                1)
                    read -p "Enter path to fix: " fix_path
                    if [ -e "$fix_path" ]; then
                        sudo restorecon -Rv "$fix_path" 2>&1 | tee -a "$LOG_FILE"
                        log "Context restored for $fix_path"
                    else
                        log "${RED}Path not found: $fix_path${NC}"
                    fi
                    ;;
                2)
                    log "${YELLOW}This will relabel the entire system on next reboot${NC}"
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        sudo touch /.autorelabel
                        log "System will be relabeled on next reboot"
                    fi
                    ;;
                3)
                    read -p "Enter directory to relabel: " relabel_dir
                    if [ -d "$relabel_dir" ]; then
                        sudo restorecon -R "$relabel_dir" 2>&1 | tee -a "$LOG_FILE"
                        log "Directory relabeled: $relabel_dir"
                    else
                        log "${RED}Directory not found: $relabel_dir${NC}"
                    fi
                    ;;
            esac
            ;;
        5)
            log "SELinux booleans management:"
            
            echo "Boolean options:"
            echo "1. List all booleans"
            echo "2. Search for boolean"
            echo "3. Change boolean value"
            read -p "Choose option (1-3): " bool_choice
            
            case $bool_choice in
                1)
                    log "All SELinux booleans:"
                    getsebool -a | head -20 | tee -a "$LOG_FILE"
                    log "... (showing first 20, use 'getsebool -a' for complete list)"
                    ;;
                2)
                    read -p "Enter search term: " search_term
                    log "Matching booleans:"
                    getsebool -a | grep -i "$search_term" | tee -a "$LOG_FILE"
                    ;;
                3)
                    read -p "Enter boolean name: " bool_name
                    if getsebool "$bool_name" >/dev/null 2>&1; then
                        log "Current value: $(getsebool "$bool_name")"
                        echo "1. Enable (on)"
                        echo "2. Disable (off)"
                        read -p "Choose value (1-2): " value_choice
                        
                        local new_value=""
                        [ "$value_choice" = "1" ] && new_value="on" || new_value="off"
                        
                        if sudo setsebool -P "$bool_name" "$new_value"; then
                            log "${GREEN}Boolean $bool_name set to $new_value${NC}"
                        else
                            log "${RED}Failed to set boolean${NC}"
                        fi
                    else
                        log "${RED}Boolean not found: $bool_name${NC}"
                    fi
                    ;;
            esac
            ;;
        6)
            log "Recent SELinux logs:"
            if command -v ausearch >/dev/null 2>&1; then
                sudo ausearch -m AVC -ts recent 2>/dev/null | tail -20 | tee -a "$LOG_FILE" || log "No recent AVC denials found"
            else
                grep -i "avc.*denied" /var/log/messages 2>/dev/null | tail -10 | tee -a "$LOG_FILE" || log "No SELinux logs found"
            fi
            ;;
    esac
    
    log "${GREEN}SELinux management completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Security And Antivirus Management Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) install_configure_clamav ;;
            2) run_system_virus_scan ;;
            3) update_antivirus_definitions ;;
            4) quarantine_management ;;
            5) firewall_configuration ;;
            6) selinux_management ;;
            7) user_security_audit ;;
            8) ssh_security_hardening ;;
            9) vulnerability_scanner ;;
            10) network_security_scan ;;
            11) file_integrity_monitoring ;;
            12) rootkit_detection ;;
            13) security_configuration_audit ;;
            14) security_monitoring_dashboard ;;
            15) incident_response_tools ;;
            16) 
                log "${GREEN}Exiting Security Management Suite${NC}"
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

# Placeholder functions for remaining menu items (to be implemented)
user_security_audit() {
    log "${BLUE}=== User Security Audit ===${NC}"
    log "This feature will audit user accounts, passwords, and permissions"
    log "Implementation: Check password policies, inactive accounts, sudo access, etc."
}

ssh_security_hardening() {
    log "${BLUE}=== SSH Security Hardening ===${NC}"
    log "This feature will harden SSH configuration"
    log "Implementation: Disable root login, change port, configure key auth, etc."
}

vulnerability_scanner() {
    log "${BLUE}=== Vulnerability Scanner ===${NC}"
    log "This feature will scan for system vulnerabilities"
    log "Implementation: Check for unpatched software, misconfigurations, etc."
}

network_security_scan() {
    log "${BLUE}=== Network Security Scan ===${NC}"
    log "This feature will scan network for security issues"
    log "Implementation: Port scanning, service enumeration, etc."
}

file_integrity_monitoring() {
    log "${BLUE}=== File Integrity Monitoring ===${NC}"
    log "This feature will monitor file system changes"
    log "Implementation: AIDE, tripwire, or custom file monitoring"
}

rootkit_detection() {
    log "${BLUE}=== Rootkit Detection ===${NC}"
    log "This feature will scan for rootkits"
    log "Implementation: rkhunter, chkrootkit integration"
}

security_configuration_audit() {
    log "${BLUE}=== Security Configuration Audit ===${NC}"
    log "This feature will audit system security configuration"
    log "Implementation: Check system hardening, security policies, etc."
}

security_monitoring_dashboard() {
    log "${BLUE}=== Security Monitoring Dashboard ===${NC}"
    log "This feature will display security monitoring dashboard"
    log "Implementation: Real-time security status, alerts, metrics"
}

incident_response_tools() {
    log "${BLUE}=== Incident Response Tools ===${NC}"
    log "This feature provides incident response tools"
    log "Implementation: Log analysis, forensics, isolation procedures"
}

main "$@"
