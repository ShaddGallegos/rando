#!/bin/bash

# Satellite Deployment Impact Assessment Script
# Shows what changes were made by the deployment that can be undone

echo "======================================================================="
echo "        SATELLITE DEPLOYMENT IMPACT ASSESSMENT"
echo "======================================================================="
echo ""
echo "Checking what changes were made to your local system..."
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CHANGES_FOUND=0

# Check hostname
echo "🔍 HOSTNAME CHANGES:"
CURRENT_HOSTNAME=$(hostname)
if [[ "$CURRENT_HOSTNAME" == "satellite" ]]; then
    echo -e "  ${YELLOW}FOUND${NC}: Hostname changed to 'satellite'"
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: Hostname unchanged ($CURRENT_HOSTNAME)"
fi

# Check /etc/hosts
echo ""
echo "🔍 /ETC/HOSTS MODIFICATIONS:"
if grep -q "satellite\|10\.168\.128\.102\|satellite\.prod\.spg" /etc/hosts 2>/dev/null; then
    echo -e "  ${YELLOW}FOUND${NC}: Satellite entries in /etc/hosts"
    grep "satellite\|10\.168\.128\.102\|satellite\.prod\.spg" /etc/hosts | while read line; do
        echo "    - $line"
    done
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: No Satellite entries in /etc/hosts"
fi

# Check admin user
echo ""
echo "🔍 USER ACCOUNT CHANGES:"
if id "admin" &>/dev/null; then
    echo -e "  ${YELLOW}FOUND${NC}: Admin user exists"
    if [[ -f "/etc/sudoers.d/admin" ]]; then
        echo -e "  ${YELLOW}FOUND${NC}: Admin sudo configuration exists"
    fi
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: No admin user found"
fi

# Check SSH keys
echo ""
echo "🔍 SSH KEY CHANGES:"
if [[ -f "/root/.ssh/id_rsa" ]]; then
    KEY_AGE=$(find /root/.ssh/id_rsa -mtime -1 2>/dev/null)
    if [[ -n "$KEY_AGE" ]]; then
        echo -e "  ${YELLOW}FOUND${NC}: Recent root SSH key (created within 24 hours)"
        ((CHANGES_FOUND++))
    else
        echo -e "  ${GREEN}OK${NC}: Root SSH key appears pre-existing"
    fi
else
    echo -e "  ${GREEN}OK${NC}: No root SSH key found"
fi

# Check packages
echo ""
echo "🔍 INSTALLED PACKAGES:"
SATELLITE_PACKAGES=("satellite" "dhcp-server" "tftp-server" "syslinux-tftpboot" "bind" "bind-utils")
INSTALLED_PACKAGES=()
for package in "${SATELLITE_PACKAGES[@]}"; do
    if rpm -q "$package" &>/dev/null; then
        INSTALLED_PACKAGES+=("$package")
    fi
done

if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
    echo -e "  ${YELLOW}FOUND${NC}: Satellite packages installed:"
    for package in "${INSTALLED_PACKAGES[@]}"; do
        echo "    - $package"
    done
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: No Satellite packages found"
fi

# Check directories
echo ""
echo "🔍 CREATED DIRECTORIES:"
SATELLITE_DIRS=(
    "/var/satellite-backups"
    "/var/lib/tftpboot/pxelinux.cfg"
    "/opt/satellite-deployment"
)

DIR_COUNT=0
for dir in "${SATELLITE_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "  ${YELLOW}FOUND${NC}: $dir"
        ((DIR_COUNT++))
    fi
done

if [[ $DIR_COUNT -eq 0 ]]; then
    echo -e "  ${GREEN}OK${NC}: No Satellite directories found"
else
    ((CHANGES_FOUND++))
fi

# Check TFTP files
echo ""
echo "🔍 TFTP BOOT FILES:"
TFTP_FILES=("/var/lib/tftpboot/pxelinux.0" "/var/lib/tftpboot/ldlinux.c32" "/var/lib/tftpboot/menu.c32")
TFTP_COUNT=0
for file in "${TFTP_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        ((TFTP_COUNT++))
    fi
done

if [[ $TFTP_COUNT -gt 0 ]]; then
    echo -e "  ${YELLOW}FOUND${NC}: $TFTP_COUNT TFTP boot files installed"
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: No TFTP boot files found"
fi

# Check firewall
echo ""
echo "🔍 FIREWALL CHANGES:"
SATELLITE_SERVICES=("tftp" "dhcp" "dns")
FIREWALL_CHANGES=0
for service in "${SATELLITE_SERVICES[@]}"; do
    if firewall-cmd --query-service="$service" 2>/dev/null >/dev/null; then
        if [[ $FIREWALL_CHANGES -eq 0 ]]; then
            echo -e "  ${YELLOW}FOUND${NC}: Satellite services in firewall:"
        fi
        echo "    - $service"
        ((FIREWALL_CHANGES++))
    fi
done

if [[ $FIREWALL_CHANGES -eq 0 ]]; then
    echo -e "  ${GREEN}OK${NC}: No Satellite firewall rules found"
else
    ((CHANGES_FOUND++))
fi

# Check management scripts
echo ""
echo "🔍 MANAGEMENT SCRIPTS:"
SCRIPTS=("/usr/local/bin/satellite_backup.sh" "/usr/local/bin/satellite_maintenance.sh" "/usr/local/bin/satellite_monitor.sh")
SCRIPT_COUNT=0
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        ((SCRIPT_COUNT++))
    fi
done

if [[ $SCRIPT_COUNT -gt 0 ]]; then
    echo -e "  ${YELLOW}FOUND${NC}: $SCRIPT_COUNT Satellite management scripts"
    ((CHANGES_FOUND++))
else
    echo -e "  ${GREEN}OK${NC}: No management scripts found"
fi

# Check services
echo ""
echo "🔍 SYSTEM SERVICES:"
SERVICES=("dhcpd" "tftp" "named")
SERVICE_COUNT=0
for service in "${SERVICES[@]}"; do
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        if [[ $SERVICE_COUNT -eq 0 ]]; then
            echo -e "  ${YELLOW}FOUND${NC}: Enabled Satellite services:"
        fi
        echo "    - $service"
        ((SERVICE_COUNT++))
    fi
done

if [[ $SERVICE_COUNT -eq 0 ]]; then
    echo -e "  ${GREEN}OK${NC}: No Satellite services enabled"
else
    ((CHANGES_FOUND++))
fi

# Summary
echo ""
echo "======================================================================="
echo "                            ASSESSMENT SUMMARY"
echo "======================================================================="

if [[ $CHANGES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ NO CHANGES DETECTED${NC}"
    echo ""
    echo "Your system appears to be in its original state."
    echo "No Satellite deployment changes were found."
else
    echo -e "${YELLOW}⚠️  CHANGES DETECTED: $CHANGES_FOUND categories affected${NC}"
    echo ""
    echo "The undo script can reverse these changes:"
    echo ""
    echo "To undo all changes, run:"
    echo "  sudo ./satellite_undo_changes.sh"
    echo ""
    echo "This will restore your system to its pre-deployment state."
fi

echo "======================================================================="
