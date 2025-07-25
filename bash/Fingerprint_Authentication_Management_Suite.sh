#!/bin/bash

# Fingerprint Authentication Management Suite
# Comprehensive fingerprint authentication and biometric security toolkit
# Consolidates: setup_fingerprint_auth.sh, biometric_config.sh, auth_troubleshoot.sh

set -euo pipefail

LOG_FILE="$HOME/fingerprint_auth_$(date +'%Y%m%d_%H%M%S').log"

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
    echo " SETUP & CONFIGURATION:"
    echo "1.  Install Fingerprint Authentication"
    echo "2.   Configure Biometric Settings"
    echo "3.  Enroll Fingerprints"
    echo "4.  Update Fingerprint Database"
    echo ""
    echo " TESTING & VERIFICATION:"
    echo "5.  Test Fingerprint Authentication"
    echo "6.  Verify Reader Hardware"
    echo "7.  Authentication Status Check"
    echo "8.  Calibrate Fingerprint Reader"
    echo ""
    echo "  TROUBLESHOOTING:"
    echo "9.  Diagnose Authentication Issues"
    echo "10.  Fix Common Problems"
    echo "11.   Reset Fingerprint Configuration"
    echo "12.  Generate Diagnostic Report"
    echo ""
    echo " SECURITY MANAGEMENT:"
    echo "13.   Configure Security Policies"
    echo "14.  Manage User Enrollments"
    echo "15.  View Authentication Logs"
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

detect_fingerprint_reader() {
    log "Detecting fingerprint readers..."
    
    # Check USB devices for fingerprint readers
    local usb_readers=$(lsusb | grep -i -E "fingerprint|biometric|validity|synaptics|elan|goodix|fpc|egis" || true)
    
    # Check with fprintd if available
    local fprintd_devices=""
    if command -v fprintd-list >/dev/null 2>&1; then
        fprintd_devices=$(fprintd-list 2>/dev/null || true)
    fi
    
    # Check libfprint devices
    local libfprint_devices=""
    if [ -d /sys/bus/usb/drivers/usbhid ]; then
        libfprint_devices=$(find /sys/bus/usb/drivers/usbhid -name "*:*" -exec basename {} \; 2>/dev/null | head -5 || true)
    fi
    
    log "${CYAN}=== Fingerprint Reader Detection Results ===${NC}"
    
    if [ -n "$usb_readers" ]; then
        log "${GREEN}USB Fingerprint Readers Found:${NC}"
        echo "$usb_readers" | tee -a "$LOG_FILE"
    else
        log "${YELLOW}No USB fingerprint readers detected${NC}"
    fi
    
    if [ -n "$fprintd_devices" ]; then
        log "${GREEN}fprintd Detected Devices:${NC}"
        echo "$fprintd_devices" | tee -a "$LOG_FILE"
    else
        log "${YELLOW}No fprintd devices found${NC}"
    fi
    
    return 0
}

check_dependencies() {
    log "Checking fingerprint authentication dependencies..."
    
    local required_packages=(
        "fprintd"
        "fprintd-pam"
        "libfprint"
        "pam_fprintd"
    )
    
    local missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if ! rpm -q "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log "${YELLOW}Missing packages: ${missing_packages[*]}${NC}"
        return 1
    else
        log "${GREEN}All required packages are installed${NC}"
        return 0
    fi
}

# ===== SETUP & CONFIGURATION =====

install_fingerprint_authentication() {
    log "${BLUE}=== Installing Fingerprint Authentication ===${NC}"
    
    if ! check_root_required; then
        return 1
    fi
    
    # Detect fingerprint reader first
    detect_fingerprint_reader
    
    # Install required packages
    log "Installing fingerprint authentication packages..."
    
    local packages=(
        "fprintd"
        "fprintd-pam"
        "libfprint"
        "libfprint-devel"
        "pam_fprintd"
        "python3-validity"
    )
    
    for package in "${packages[@]}"; do
        install_package_if_missing "$package" || log "${YELLOW}Failed to install $package (may not be available)${NC}"
    done
    
    # Enable and start fprintd service
    log "Configuring fprintd service..."
    systemctl enable fprintd.service
    systemctl start fprintd.service
    
    # Check service status
    if systemctl is-active --quiet fprintd.service; then
        log "${GREEN}fprintd service is running${NC}"
    else
        log "${YELLOW}fprintd service failed to start${NC}"
        systemctl status fprintd.service | tee -a "$LOG_FILE"
    fi
    
    # Configure PAM for fingerprint authentication
    log "Configuring PAM for fingerprint authentication..."
    
    # Backup original PAM configurations
    local pam_files=(
        "/etc/pam.d/login"
        "/etc/pam.d/gdm-fingerprint"
        "/etc/pam.d/sudo"
        "/etc/pam.d/su"
    )
    
    for pam_file in "${pam_files[@]}"; do
        if [ -f "$pam_file" ]; then
            cp "$pam_file" "$pam_file.backup.$(date +%Y%m%d)" 2>/dev/null || true
        fi
    done
    
    # Configure GDM for fingerprint authentication
    if [ -f /etc/pam.d/gdm-fingerprint ]; then
        log "Configuring GDM fingerprint authentication..."
        tee /etc/pam.d/gdm-fingerprint > /dev/null << 'EOF'
#%PAM-1.0
auth     required       pam_env.so
auth     required       pam_faillock.so preauth silent audit deny=4 unlock_time=1200
auth     sufficient     pam_fprintd.so
auth     sufficient     pam_unix.so try_first_pass nullok
auth     required       pam_faillock.so authfail audit deny=4 unlock_time=1200
auth     required       pam_deny.so

account  required       pam_unix.so
account  sufficient     pam_localuser.so
account  sufficient     pam_succeed_if.so uid < 1000 quiet
account  required       pam_permit.so

password required       pam_deny.so

session  required       pam_selinux.so close
session  required       pam_loginuid.so
session  optional       pam_console.so
session  required       pam_selinux.so open
session  optional       pam_keyinit.so force revoke
session  required       pam_namespace.so
session  optional       pam_gnome_keyring.so auto_start
session  required       pam_unix.so
EOF
    fi
    
    # Configure sudo for fingerprint authentication
    log "Configuring sudo for fingerprint authentication..."
    
    # Add fingerprint authentication to sudo
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo 2>/dev/null; then
        sed -i '1a auth       sufficient   pam_fprintd.so' /etc/pam.d/sudo
        log "Added fingerprint authentication to sudo"
    fi
    
    # Configure polkit for fingerprint authentication
    log "Configuring polkit for fingerprint authentication..."
    
    mkdir -p /etc/polkit-1/localauthority/50-local.d/
    
    tee /etc/polkit-1/localauthority/50-local.d/fingerprint-auth.pkla > /dev/null << 'EOF'
[Fingerprint Authentication]
Identity=unix-group:wheel
Action=org.freedesktop.policykit.exec
ResultAny=auth_self_keep
ResultInactive=auth_self_keep
ResultActive=auth_self_keep
AuthorizeAnyway=yes
EOF
    
    # Set up systemd-logind for fingerprint
    log "Configuring systemd-logind for fingerprint..."
    
    if [ -f /etc/systemd/logind.conf ]; then
        cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup.$(date +%Y%m%d)
        
        # Enable fingerprint for login
        if ! grep -q "^HandleLidSwitch=" /etc/systemd/logind.conf; then
            echo "HandleLidSwitch=suspend" >> /etc/systemd/logind.conf
        fi
        
        systemctl restart systemd-logind
    fi
    
    # Test installation
    log "Testing fingerprint installation..."
    
    if command -v fprintd-list >/dev/null 2>&1; then
        log "Available fingerprint devices:"
        fprintd-list 2>&1 | tee -a "$LOG_FILE" || log "${YELLOW}No devices found or fprintd not working${NC}"
    fi
    
    # Create fingerprint management script
    log "Creating fingerprint management script..."
    
    tee /usr/local/bin/fingerprint-manager > /dev/null << 'EOF'
#!/bin/bash
# Simple fingerprint management script

case "$1" in
    enroll)
        echo "Enrolling fingerprint for user: $USER"
        fprintd-enroll
        ;;
    verify)
        echo "Verifying fingerprint for user: $USER"
        fprintd-verify
        ;;
    delete)
        echo "Deleting fingerprints for user: $USER"
        fprintd-delete "$USER"
        ;;
    list)
        echo "Listing enrolled users:"
        fprintd-list
        ;;
    *)
        echo "Usage: $0 {enroll|verify|delete|list}"
        echo "  enroll - Enroll new fingerprint"
        echo "  verify - Verify fingerprint"
        echo "  delete - Delete user fingerprints"
        echo "  list   - List enrolled users"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/fingerprint-manager
    
    log "${GREEN}Fingerprint authentication installation completed${NC}"
    log "Use 'fingerprint-manager enroll' to enroll your fingerprints"
    log "Reboot or restart display manager for changes to take effect"
}

configure_biometric_settings() {
    log "${BLUE}=== Configuring Biometric Settings ===${NC}"
    
    echo "Biometric configuration options:"
    echo "1. Configure authentication thresholds"
    echo "2. Set security policies"
    echo "3. Configure timeout settings"
    echo "4. Manage device-specific settings"
    echo "5. Configure fallback authentication"
    read -p "Choose option (1-5): " config_choice
    
    case $config_choice in
        1)
            log "Configuring authentication thresholds..."
            
            echo "Fingerprint matching sensitivity:"
            echo "1. High security (strict matching)"
            echo "2. Balanced (recommended)"
            echo "3. High convenience (relaxed matching)"
            read -p "Choose sensitivity (1-3): " sensitivity
            
            local threshold_value=""
            case $sensitivity in
                1) threshold_value="90" ;;
                2) threshold_value="70" ;;
                3) threshold_value="50" ;;
                *) threshold_value="70" ;;
            esac
            
            # Configure libfprint settings if available
            if [ -d /etc/libfprint ]; then
                mkdir -p /etc/libfprint
                echo "threshold=$threshold_value" > /etc/libfprint/device.conf
                log "Fingerprint threshold set to $threshold_value%"
            fi
            ;;
        2)
            log "Configuring security policies..."
            
            echo "Security policy options:"
            echo "1. Require fingerprint + password (most secure)"
            echo "2. Fingerprint OR password (convenient)"
            echo "3. Fingerprint only (least secure)"
            read -p "Choose policy (1-3): " policy_choice
            
            case $policy_choice in
                1)
                    log "Setting up two-factor authentication"
                    # Modify PAM to require both
                    if [ -f /etc/pam.d/sudo ]; then
                        sed -i 's/sufficient.*pam_fprintd.so/required   pam_fprintd.so/' /etc/pam.d/sudo
                    fi
                    ;;
                2)
                    log "Setting up OR authentication (default)"
                    # Ensure PAM uses sufficient
                    if [ -f /etc/pam.d/sudo ]; then
                        sed -i 's/required.*pam_fprintd.so/sufficient pam_fprintd.so/' /etc/pam.d/sudo
                    fi
                    ;;
                3)
                    log "${YELLOW}Fingerprint-only authentication is not recommended${NC}"
                    read -p "Are you sure? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        log "Configuring fingerprint-only authentication"
                    else
                        log "Keeping current configuration"
                    fi
                    ;;
            esac
            ;;
        3)
            log "Configuring timeout settings..."
            
            read -p "Enter fingerprint scan timeout (seconds, 5-30): " timeout
            if [[ "$timeout" =~ ^[0-9]+$ ]] && [ "$timeout" -ge 5 ] && [ "$timeout" -le 30 ]; then
                # Configure fprintd timeout
                if [ -f /etc/fprintd.conf ]; then
                    sed -i "s/^timeout.*/timeout=$timeout/" /etc/fprintd.conf
                else
                    echo "timeout=$timeout" > /etc/fprintd.conf
                fi
                log "Fingerprint timeout set to $timeout seconds"
            else
                log "${RED}Invalid timeout value${NC}"
            fi
            ;;
        4)
            log "Managing device-specific settings..."
            
            if command -v fprintd-list >/dev/null 2>&1; then
                log "Available devices:"
                fprintd-list | tee -a "$LOG_FILE"
                
                echo "Device configuration options:"
                echo "1. Reset device"
                echo "2. Update device firmware"
                echo "3. Calibrate device"
                read -p "Choose option (1-3): " device_choice
                
                case $device_choice in
                    1)
                        log "Resetting fingerprint device..."
                        systemctl restart fprintd.service
                        log "Device reset completed"
                        ;;
                    2)
                        log "Checking for firmware updates..."
                        if command -v fwupdmgr >/dev/null 2>&1; then
                            fwupdmgr refresh
                            fwupdmgr get-updates | grep -i fingerprint || log "No fingerprint firmware updates available"
                        else
                            log "${YELLOW}fwupdmgr not available for firmware updates${NC}"
                        fi
                        ;;
                    3)
                        log "Device calibration is automatic for most devices"
                        log "If experiencing issues, try re-enrolling fingerprints"
                        ;;
                esac
            else
                log "${RED}fprintd not available for device management${NC}"
            fi
            ;;
        5)
            log "Configuring fallback authentication..."
            
            echo "Fallback options when fingerprint fails:"
            echo "1. Always allow password fallback"
            echo "2. Require admin intervention"
            echo "3. Lock account after failures"
            read -p "Choose fallback (1-3): " fallback_choice
            
            case $fallback_choice in
                1)
                    log "Configuring automatic password fallback"
                    # Ensure password auth is available
                    if [ -f /etc/pam.d/sudo ]; then
                        if ! grep -q "pam_unix.so" /etc/pam.d/sudo; then
                            echo "auth    sufficient    pam_unix.so try_first_pass" >> /etc/pam.d/sudo
                        fi
                    fi
                    ;;
                2)
                    log "Configuring admin intervention requirement"
                    log "${YELLOW}This requires manual PAM configuration${NC}"
                    ;;
                3)
                    log "Configuring account lockout on failures"
                    # Configure pam_faillock
                    if ! grep -q "pam_faillock.so" /etc/pam.d/sudo; then
                        sed -i '1a auth    required    pam_faillock.so preauth audit deny=3 unlock_time=600' /etc/pam.d/sudo
                    fi
                    ;;
            esac
            ;;
    esac
    
    log "${GREEN}Biometric settings configuration completed${NC}"
}

enroll_fingerprints() {
    log "${BLUE}=== Enrolling Fingerprints ===${NC}"
    
    if ! command -v fprintd-enroll >/dev/null 2>&1; then
        log "${RED}fprintd-enroll not found. Please install fingerprint authentication first.${NC}"
        return 1
    fi
    
    # Check for available devices
    log "Checking for fingerprint devices..."
    if ! fprintd-list >/dev/null 2>&1; then
        log "${RED}No fingerprint devices found${NC}"
        return 1
    fi
    
    echo "Fingerprint enrollment options:"
    echo "1. Enroll for current user ($USER)"
    echo "2. Enroll for specific user"
    echo "3. Enroll multiple fingers"
    echo "4. Re-enroll existing fingerprints"
    read -p "Choose option (1-4): " enroll_choice
    
    case $enroll_choice in
        1)
            log "Enrolling fingerprints for user: $USER"
            
            echo "Available fingers:"
            echo "1. Right thumb"
            echo "2. Right index finger"
            echo "3. Right middle finger"
            echo "4. Right ring finger"
            echo "5. Right little finger"
            echo "6. Left thumb"
            echo "7. Left index finger"
            echo "8. Left middle finger"
            echo "9. Left ring finger"
            echo "10. Left little finger"
            
            read -p "Choose finger (1-10): " finger_choice
            
            local finger_names=(
                "right-thumb"
                "right-index-finger"
                "right-middle-finger"
                "right-ring-finger"
                "right-little-finger"
                "left-thumb"
                "left-index-finger"
                "left-middle-finger"
                "left-ring-finger"
                "left-little-finger"
            )
            
            if [ "$finger_choice" -ge 1 ] && [ "$finger_choice" -le 10 ]; then
                local finger_name="${finger_names[$((finger_choice-1))]}"
                log "Enrolling $finger_name..."
                
                echo "Please place your finger on the scanner when prompted."
                echo "You will need to lift and place your finger multiple times."
                
                if fprintd-enroll -f "$finger_name"; then
                    log "${GREEN}Fingerprint enrolled successfully for $finger_name${NC}"
                else
                    log "${RED}Fingerprint enrollment failed${NC}"
                fi
            else
                log "${RED}Invalid finger selection${NC}"
            fi
            ;;
        2)
            read -p "Enter username to enroll: " target_user
            
            if id "$target_user" >/dev/null 2>&1; then
                log "Enrolling fingerprints for user: $target_user"
                
                # Note: This requires appropriate privileges
                if sudo -u "$target_user" fprintd-enroll; then
                    log "${GREEN}Fingerprint enrolled successfully for $target_user${NC}"
                else
                    log "${RED}Fingerprint enrollment failed for $target_user${NC}"
                fi
            else
                log "${RED}User not found: $target_user${NC}"
            fi
            ;;
        3)
            log "Enrolling multiple fingerprints..."
            
            echo "How many fingers would you like to enroll?"
            read -p "Enter number (1-10): " num_fingers
            
            if [[ "$num_fingers" =~ ^[0-9]+$ ]] && [ "$num_fingers" -ge 1 ] && [ "$num_fingers" -le 10 ]; then
                for ((i=1; i<=num_fingers; i++)); do
                    echo ""
                    log "Enrolling finger $i of $num_fingers"
                    
                    if fprintd-enroll; then
                        log "${GREEN}Finger $i enrolled successfully${NC}"
                    else
                        log "${RED}Failed to enroll finger $i${NC}"
                        break
                    fi
                done
            else
                log "${RED}Invalid number of fingers${NC}"
            fi
            ;;
        4)
            log "Re-enrolling existing fingerprints..."
            
            echo "This will delete existing fingerprints and enroll new ones."
            echo
            read -p "Continue? (y/N): " -n 1 -r
            echo
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Delete existing fingerprints
                log "Deleting existing fingerprints..."
                fprintd-delete "$USER" 2>/dev/null || true
                
                # Enroll new fingerprints
                log "Enrolling new fingerprints..."
                if fprintd-enroll; then
                    log "${GREEN}Re-enrollment completed successfully${NC}"
                else
                    log "${RED}Re-enrollment failed${NC}"
                fi
            else
                log "Re-enrollment cancelled"
            fi
            ;;
    esac
    
    # Show enrollment status
    log "${CYAN}=== Current Enrollment Status ===${NC}"
    if command -v fprintd-list >/dev/null 2>&1; then
        fprintd-list 2>&1 | tee -a "$LOG_FILE"
    fi
    
    log "${GREEN}Fingerprint enrollment completed${NC}"
}

# ===== MAIN EXECUTION =====

main() {
    print_header
    log "${GREEN}=== Fingerprint Authentication Management Suite Started ===${NC}"
    log "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
    
    while true; do
        show_main_menu
        
        case $choice in
            1) install_fingerprint_authentication ;;
            2) configure_biometric_settings ;;
            3) enroll_fingerprints ;;
            4) update_fingerprint_database ;;
            5) test_fingerprint_authentication ;;
            6) verify_reader_hardware ;;
            7) authentication_status_check ;;
            8) calibrate_fingerprint_reader ;;
            9) diagnose_authentication_issues ;;
            10) fix_common_problems ;;
            11) reset_fingerprint_configuration ;;
            12) generate_diagnostic_report ;;
            13) configure_security_policies ;;
            14) manage_user_enrollments ;;
            15) view_authentication_logs ;;
            16) 
                log "${GREEN}Exiting Fingerprint Authentication Management Suite${NC}"
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
update_fingerprint_database() {
    log "${BLUE}=== Updating Fingerprint Database ===${NC}"
    log "This feature will update fingerprint templates and database"
    log "Implementation: Update enrolled fingerprints, clean database, optimize"
}

test_fingerprint_authentication() {
    log "${BLUE}=== Testing Fingerprint Authentication ===${NC}"
    log "This feature will test fingerprint authentication"
    log "Implementation: Verify enrolled fingerprints, test PAM integration"
}

verify_reader_hardware() {
    log "${BLUE}=== Verifying Reader Hardware ===${NC}"
    log "This feature will verify fingerprint reader hardware"
    log "Implementation: Hardware diagnostics, driver status, connectivity"
}

authentication_status_check() {
    log "${BLUE}=== Authentication Status Check ===${NC}"
    log "This feature will check authentication system status"
    log "Implementation: Service status, PAM config, enrollment status"
}

calibrate_fingerprint_reader() {
    log "${BLUE}=== Calibrating Fingerprint Reader ===${NC}"
    log "This feature will calibrate the fingerprint reader"
    log "Implementation: Reader calibration, sensitivity adjustment"
}

diagnose_authentication_issues() {
    log "${BLUE}=== Diagnosing Authentication Issues ===${NC}"
    log "This feature will diagnose authentication problems"
    log "Implementation: Log analysis, common issue detection, solutions"
}

fix_common_problems() {
    log "${BLUE}=== Fixing Common Problems ===${NC}"
    log "This feature will fix common fingerprint authentication problems"
    log "Implementation: Service restart, permission fixes, config repair"
}

reset_fingerprint_configuration() {
    log "${BLUE}=== Resetting Fingerprint Configuration ===${NC}"
    log "This feature will reset fingerprint configuration to defaults"
    log "Implementation: Remove configs, reset PAM, clean database"
}

generate_diagnostic_report() {
    log "${BLUE}=== Generating Diagnostic Report ===${NC}"
    log "This feature will generate comprehensive diagnostic report"
    log "Implementation: System info, config status, troubleshooting data"
}

configure_security_policies() {
    log "${BLUE}=== Configuring Security Policies ===${NC}"
    log "This feature will configure fingerprint security policies"
    log "Implementation: Timeout settings, failure handling, access control"
}

manage_user_enrollments() {
    log "${BLUE}=== Managing User Enrollments ===${NC}"
    log "This feature will manage user fingerprint enrollments"
    log "Implementation: Bulk enrollment, user management, access control"
}

view_authentication_logs() {
    log "${BLUE}=== Viewing Authentication Logs ===${NC}"
    log "This feature will show authentication logs and statistics"
    log "Implementation: PAM logs, fprintd logs, success/failure analysis"
}

main "$@"
