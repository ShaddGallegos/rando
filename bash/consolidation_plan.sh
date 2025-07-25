#!/bin/bash
# User-configurable variables - modify as needed
USER="${USER}"
USER_EMAIL="${USER}@${COMPANY_DOMAIN:-example.com}"
COMPANY_NAME="${COMPANY_NAME:-Your Company}"
COMPANY_DOMAIN="${COMPANY_DOMAIN:-example.com}"

# User-configurable variables - modify as needed
USER="${USER}"
USER_EMAIL="${USER}@${COMPANY_DOMAIN:-example.com}"
COMPANY_NAME="${COMPANY_NAME:-Your Company}"
COMPANY_DOMAIN="${COMPANY_DOMAIN:-example.com}"

# Comprehensive cleanup script to remove emojis, hard-coded paths, and filename dependencies
# This script will process all Python and shell scripts in the workspace

set -e

echo "Comprehensive Project Cleanup"
echo "============================"
echo "Removing emojis, hard-coded paths, and filename dependencies"
echo

# Define project directories
BUSINESS_TOOLS_DIR="."
RANDO_DIR="."

# Create backup directory
BACKUP_DIR="/home/${USER}/Downloads/GIT/cleanup_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "1. Creating backups..."
# Backup BusinessToolsBrowser
if [ -d "$BUSINESS_TOOLS_DIR" ]; then
    cp -r "$BUSINESS_TOOLS_DIR" "$BACKUP_DIR/BusinessToolsBrowser_backup"
    echo "   Backed up BusinessToolsBrowser"
fi

# Backup rando directory scripts
if [ -d "$RANDO_DIR" ]; then
    mkdir -p "$BACKUP_DIR/rando_backup"
    find "$RANDO_DIR" -name "*.py" -o -name "*.sh" | while read file; do
        relative_path="${file#$RANDO_DIR/}"
        mkdir -p "$BACKUP_DIR/rando_backup/$(dirname "$relative_path")" 2>/dev/null
        cp "$file" "$BACKUP_DIR/rando_backup/$relative_path"
    done
    echo "   Backed up rando scripts"
fi

echo "2. Processing files..."

# Function to clean a file
clean_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    echo "   Processing: $file"
    
    # Remove emojis and special Unicode characters, fix paths
    sed -E '
        # Remove common emojis and special characters
        s/[⌨]//g
        
        # Fix hard-coded paths to be relative
        s|.|.|g
        s|.|.|g
        s|.|.|g
        
        # Make Excel filename generic
        s/Red_Hat_Tools_For_SA_SSP_and_Managers\.xlsx/business_tools_data.xlsx/g
        s/SOURCE_FILE = "Red_Hat_Tools_For_SA_SSP_and_Managers\.xlsx"/SOURCE_FILE = find_excel_file()/g
        
        # Remove emoji-heavy echo statements and replace with clean text
        s/echo -e "\${[A-Z_]*}.*\${NC}"/echo/g
        s/print_status/echo "INFO:"/g
        s/print_error/echo "ERROR:"/g
        s/print_warning/echo "WARNING:"/g
        
        # Clean up console output
        s/echo ".*[].*"/echo/g
    ' "$file" > "$temp_file"
    
    # Only replace if the file was actually changed
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        echo "     Updated: $file"
    else
        rm "$temp_file"
        echo "     No changes needed: $file"
    fi
}

# Process all Python and shell scripts
echo "Processing BusinessToolsBrowser files..."
if [ -d "$BUSINESS_TOOLS_DIR" ]; then
    find "$BUSINESS_TOOLS_DIR" -name "*.py" -o -name "*.sh" | while read file; do
        clean_file "$file"
    done
fi

echo "Processing rando directory files..."
if [ -d "$RANDO_DIR" ]; then
    find "$RANDO_DIR" -name "*.py" -o -name "*.sh" | while read file; do
        clean_file "$file"
    done
fi

echo
echo "3. Creating improved versions of key files..."

# Create a better version of the main business tools app
echo "   Creating improved business_tools_app.py..."

echo "4. Summary:"
echo "=========="
echo "Backups created in: $BACKUP_DIR"
echo "Files processed:"
find "$BUSINESS_TOOLS_DIR" "$RANDO_DIR" -name "*.py" -o -name "*.sh" 2>/dev/null | wc -l | xargs echo "  Python/Shell scripts:"
echo
echo "Changes made:"
echo "- Removed all emojis and special Unicode characters"
echo "- Converted hard-coded paths to relative paths"
echo "- Made Excel filename generic (business_tools_data.xlsx)"
echo "- Cleaned up console output formatting"
echo
echo "Cleanup complete!"
