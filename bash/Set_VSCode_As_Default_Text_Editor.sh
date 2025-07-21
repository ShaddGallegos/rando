#!/bin/bash

# Ensure VSCode is installed
if ! command -v code &> /dev/null; then
    echo "VSCode is not installed. Installing..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf install -y code
fi

# Set VSCode as default for common text MIME types
mime_types=(
    text/plain
    text/x-python
    text/x-shellscript
    text/x-csrc
    text/x-c++
    text/x-java
    text/html
    text/css
    application/json
    application/xml
    application/x-sh
    application/x-yaml
    text/yaml
)

for mime in "${mime_types[@]}"; do
    xdg-mime default code.desktop "$mime"
done

# Add shebang to .sh files and make them executable
find "$HOME" -type f -name "*.sh" | while read -r file; do
    if ! grep -q "^#!/bin/bash" "$file"; then
        sed -i '1i#!/bin/bash' "$file"
        echo "Added shebang to $file"
    fi
    chmod +x "$file"
    echo "Made $file executable"
done

echo "VSCode set as default editor and .sh files updated with shebang and executable permissions."

