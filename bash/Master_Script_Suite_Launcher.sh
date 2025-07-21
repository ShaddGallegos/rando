#!/bin/bash

# Master Script Suite Launcher
# Central launcher for all consolidated script suites
# Provides unified access to all system management tools

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                Master Script Suite Launcher                 ║${NC}"
    echo -e "${PURPLE}║         Unified System Management & Administration          ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_main_menu() {
    echo -e "${CYAN}Select a script suite to launch:${NC}"
    echo ""
    echo "🔧 SYSTEM ADMINISTRATION:"
    echo "1. 🩺 System Diagnostics & Repair Suite"
    echo "2. 📺 Display & Graphics Management Suite"
    echo "3. 📦 Package Organization & Migration Suite"
    echo "4. 🛡️  Security & Antivirus Management Suite"
    echo ""
    echo "💻 DEVELOPMENT & APPLICATIONS:"
    echo "5. 📱 Application Installation & Setup Suite"
    echo "6. 🔐 Fingerprint Authentication Management Suite"
    echo "7. 🖥️  Development Environment Configuration Suite"
    echo ""
    echo "📊 MONITORING & FILE MANAGEMENT:"
    echo "8. ⚡ System Performance & Monitoring Suite"
    echo "9. 💿 File & ISO Management Suite"
    echo ""
    echo "⚙️  ADDITIONAL TOOLS:"
    echo "10. 🌐 Network & Repository Management Suite"
    echo "11. 🖥️  Terminal Session & System Management Suite"
    echo ""
    echo "12. ℹ️  Show Suite Information"
    echo "13. 🔄 Update All Suites"
    echo "14. 🚪 Exit"
    echo ""
    read -p "Enter your choice (1-14): " choice
}

launch_suite() {
    local suite_file="$1"
    local suite_name="$2"
    
    if [ -f "$SCRIPT_DIR/$suite_file" ]; then
        echo -e "${GREEN}Launching $suite_name...${NC}"
        bash "$SCRIPT_DIR/$suite_file"
    else
        echo -e "${RED}Error: $suite_file not found in $SCRIPT_DIR${NC}"
        read -p "Press Enter to continue..."
    fi
}

show_suite_information() {
    echo -e "${BLUE}=== Script Suite Information ===${NC}"
    echo ""
    
    local suites=(
        "System_Diagnostics_And_Repair_Suite.sh:System diagnostics, error analysis, freeze fixes, and repair tools"
        "Display_Graphics_Management_Suite.sh:HDMI configuration, graphics drivers, display troubleshooting, and optimization"
        "Package_Organization_And_Migration_Suite.sh:RPM organization, package migration, batch operations, and inventory management"
        "Security_And_Antivirus_Management_Suite.sh:ClamAV setup, virus scanning, firewall configuration, and security auditing"
        "Application_Installation_And_Setup_Suite.sh:VS Code, Flatpak, Podman, fonts, LibreOffice, and development tools"
        "Fingerprint_Authentication_Management_Suite.sh:Biometric authentication setup, enrollment, testing, and troubleshooting"
        "Development_Environment_Configuration_Suite.sh:Programming languages, IDEs, version control, and development tools"
        "System_Performance_And_Monitoring_Suite.sh:Performance monitoring, optimization, benchmarking, and analysis"
        "File_And_ISO_Management_Suite.sh:File organization, ISO operations, backup management, and data migration"
    )
    
    for suite_info in "${suites[@]}"; do
        local suite_file="${suite_info%%:*}"
        local description="${suite_info##*:}"
        
        if [ -f "$SCRIPT_DIR/$suite_file" ]; then
            local size=$(du -sh "$SCRIPT_DIR/$suite_file" | cut -f1)
            local status="${GREEN}Available${NC}"
        else
            local size="N/A"
            local status="${RED}Missing${NC}"
        fi
        
        echo -e "${YELLOW}${suite_file}${NC}"
        echo -e "  Description: $description"
        echo -e "  Size: $size"
        echo -e "  Status: $status"
        echo ""
    done
    
    read -p "Press Enter to continue..."
}

update_all_suites() {
    echo -e "${BLUE}=== Updating All Suites ===${NC}"
    echo ""
    
    # Make all suite files executable
    local updated_count=0
    for suite in "$SCRIPT_DIR"/*_Suite.sh; do
        if [ -f "$suite" ]; then
            chmod +x "$suite"
            echo -e "${GREEN}Updated permissions: $(basename "$suite")${NC}"
            ((updated_count++))
        fi
    done
    
    echo ""
    echo -e "${GREEN}Updated $updated_count script suites${NC}"
    read -p "Press Enter to continue..."
}

main() {
    while true; do
        print_header
        show_main_menu
        
        case $choice in
            1)
                launch_suite "System_Diagnostics_And_Repair_Suite.sh" "System Diagnostics & Repair Suite"
                ;;
            2)
                launch_suite "Display_Graphics_Management_Suite.sh" "Display & Graphics Management Suite"
                ;;
            3)
                launch_suite "Package_Organization_And_Migration_Suite.sh" "Package Organization & Migration Suite"
                ;;
            4)
                launch_suite "Security_And_Antivirus_Management_Suite.sh" "Security & Antivirus Management Suite"
                ;;
            5)
                launch_suite "Application_Installation_And_Setup_Suite.sh" "Application Installation & Setup Suite"
                ;;
            6)
                launch_suite "Fingerprint_Authentication_Management_Suite.sh" "Fingerprint Authentication Management Suite"
                ;;
            7)
                launch_suite "Development_Environment_Configuration_Suite.sh" "Development Environment Configuration Suite"
                ;;
            8)
                launch_suite "System_Performance_And_Monitoring_Suite.sh" "System Performance & Monitoring Suite"
                ;;
            9)
                launch_suite "File_And_ISO_Management_Suite.sh" "File & ISO Management Suite"
                ;;
            10)
                launch_suite "Network_And_Repository_Management_Suite.sh" "Network & Repository Management Suite"
                ;;
            11)
                launch_suite "Terminal_Session_And_System_Management_Suite.sh" "Terminal Session & System Management Suite"
                ;;
            12)
                show_suite_information
                ;;
            13)
                update_all_suites
                ;;
            14)
                echo -e "${GREEN}Thank you for using the Master Script Suite Launcher!${NC}"
                echo -e "${BLUE}All system management tools are now organized into comprehensive suites.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Check if running directly or being sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
