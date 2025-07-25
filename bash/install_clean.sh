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

# Business Tools Browser Installer for RHEL 9 (Clean Version)
# No emojis, relative paths, generic Excel file support

set -e

# Configuration
APP_NAME="Business Tools Browser"
INSTALL_DIR="."
DESKTOP_FILE="business-tools-browser.desktop"
MENU_DIR="/usr/share/applications"
BIN_DIR="/usr/local/bin"

echo "========================================"
echo "    Business Tools Browser Installer   "
echo "========================================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run as root (use sudo)"
   exit 1
fi

# Check RHEL version
if ! grep -q "${COMPANY_NAME} Enterprise Linux.*9" /etc/${COMPANY_NAME}-release 2>/dev/null; then
    echo "WARNING: This installer is designed for RHEL 9"
    echo "Your system may not be RHEL 9, but continuing anyway..."
    echo
fi

# Function to print status
print_status() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

# Check if Python 3 is installed
print_status "Checking Python 3 installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    echo "Installing Python 3..."
    dnf install -y python3 python3-pip python3-tkinter
else
    print_status "Python 3 is installed"
fi

# Check and install required Python packages
print_status "Installing Python dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install pandas requests openpyxl

# Create installation directory
print_status "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/resources"

# Get the script directory (where installer is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy application files
print_status "Installing application files..."

# Copy main application
if [ -f "$SCRIPT_DIR/src/business_tools_app.py" ]; then
    cp "$SCRIPT_DIR/src/business_tools_app.py" "$INSTALL_DIR/src/"
    chmod +x "$INSTALL_DIR/src/business_tools_app.py"
elif [ -f "$SCRIPT_DIR/business_tools_app_clean.py" ]; then
    cp "$SCRIPT_DIR/business_tools_app_clean.py" "$INSTALL_DIR/src/business_tools_app.py"
    chmod +x "$INSTALL_DIR/src/business_tools_app.py"
else
    print_error "Main application file not found"
    exit 1
fi

# Copy launcher
if [ -f "$SCRIPT_DIR/business_tools.py" ]; then
    cp "$SCRIPT_DIR/business_tools.py" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/business_tools.py"
else
    # Create launcher if it doesn't exist
    cat > "$INSTALL_DIR/business_tools.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple launcher script for Business Tools Browser
"""
import os
import sys
from pathlib import Path

# Get application directory
APP_DIR = Path(__file__).parent

# Change to app directory and run
os.chdir(APP_DIR)
sys.path.insert(0, str(APP_DIR / "src"))

from src.business_tools_app import main

if __name__ == "__main__":
    main()
EOF
    chmod +x "$INSTALL_DIR/business_tools.py"
fi

# Create desktop file
print_status "Creating desktop menu entry..."
cat > "$INSTALL_DIR/resources/$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Business Tools Browser
Comment=Browse and search business tools database
Exec=$INSTALL_DIR/business_tools.py
Icon=$INSTALL_DIR/resources/business_tools.png
Terminal=false
Categories=Office;Database;Utility;
EOF

# Create a simple icon if one doesn't exist
ICON_FILE="$INSTALL_DIR/resources/business_tools.png"
if [ ! -f "$ICON_FILE" ]; then
    print_status "Creating default icon..."
    # Create a simple placeholder icon file
    touch "$ICON_FILE"
fi

# Install desktop file to system menu
print_status "Installing desktop menu entry..."
cp "$INSTALL_DIR/resources/$DESKTOP_FILE" "$MENU_DIR/"
chmod 644 "$MENU_DIR/$DESKTOP_FILE"

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$MENU_DIR"
fi

# Create symbolic link for command line access
print_status "Creating command line launcher..."
ln -sf "$INSTALL_DIR/business_tools.py" "$BIN_DIR/business-tools"
chmod +x "$BIN_DIR/business-tools"

# Set proper permissions
print_status "Setting permissions..."
chown -R root:root "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod 644 "$INSTALL_DIR/resources/$DESKTOP_FILE"

# Create uninstaller
print_status "Creating uninstaller..."
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
# Business Tools Browser Uninstaller

echo "Uninstalling Business Tools Browser..."

# Remove installation directory
rm -rf .

# Remove desktop file
rm -f /usr/share/applications/business-tools-browser.desktop

# Remove command line launcher
rm -f /usr/local/bin/business-tools

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications
fi

echo "Business Tools Browser has been uninstalled."
EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

# Copy any existing data files
print_status "Setting up data directory..."
if [ -f "$SCRIPT_DIR/data/"*.xlsx ]; then
    print_status "Found Excel data files, copying..."
    cp "$SCRIPT_DIR/data/"*.xlsx "$INSTALL_DIR/data/" 2>/dev/null || true
fi

if [ -f "$SCRIPT_DIR/data/"*.csv ]; then
    print_status "Found CSV data files, copying..."
    cp "$SCRIPT_DIR/data/"*.csv "$INSTALL_DIR/data/" 2>/dev/null || true
fi

# Create documentation
print_status "Creating documentation..."
cat > "$INSTALL_DIR/README.md" << 'EOF'
# Business Tools Browser

A comprehensive application for browsing and searching business tools databases.

## Features

- GUI Interface: User-friendly graphical interface with search and filtering
- CLI Interface: Command-line interface for terminal users
- Data Processing: Import and process Excel files with tool information
- Access Control: Classify tools as Internal or Public
- Search & Filter: Search by name, description, category, and access level

## Usage

### GUI Mode (Default)
```bash
business-tools
# or
./business_tools.py
```

### CLI Mode
```bash
business-tools --cli
# or
./business_tools.py --cli
```

### Process Excel File
```bash
business-tools --process /path/to/file.xlsx
```

## Data Location

- Application data is stored in: `./data/`
- Processed data files: `Cleaned_Tools.csv` and `Tools_Summary.csv`
- Supports any Excel file with columns: Name, URL, Synopsis, Tool_Type

## Uninstallation

To uninstall the application:
```bash
sudo ./uninstall.sh
```

## Support

For issues or questions, contact your system administrator.
EOF

print_status "Installation completed successfully!"
echo
echo "========================================"
echo "    Installation Summary               "
echo "========================================"
echo "Application installed to: $INSTALL_DIR"
echo "Menu entry added to: Applications > Office"
echo "Command line access: business-tools"
echo "Documentation: $INSTALL_DIR/README.md"
echo
echo "To start the application:"
echo "  - Use the Applications menu (Office > Business Tools Browser)"
echo "  - Or run: business-tools"
echo "  - For CLI mode: business-tools --cli"
echo
echo "To uninstall:"
echo "  - Run: sudo $INSTALL_DIR/uninstall.sh"
echo
print_status "You can now close this terminal and start using Business Tools Browser!"
