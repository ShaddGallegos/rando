#!/bin/bash

echo "🔧 Setting up Copilot, Gmail, and Google Calendar launchers on RHEL 9..."

APPS=(
    "Copilot|https://copilot.microsoft.com"
    "Gmail|https://mail.google.com"
    "Google Calendar|https://calendar.google.com"
)

LAUNCHER_DIR="$HOME/.local/share/applications"

mkdir -p "$LAUNCHER_DIR"

for app in "${APPS[@]}"; do
    NAME="${app%%|*}"
    URL="${app##*|}"
    FILE="$LAUNCHER_DIR/${NAME,,}.desktop"

    echo "📝 Creating launcher for $NAME..."

    cat <<EOF > "$FILE"
[Desktop Entry]
Name=$NAME
Exec=google-chrome --app=$URL
Icon=chrome
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOF

    chmod +x "$FILE"
done

echo "✅ Launchers created! You can find them in your Activities menu."

echo "🔐 Opening Chrome windows for sign-in..."

for app in "${APPS[@]}"; do
    URL="${app##*|}"
    google-chrome --app="$URL" &
done

echo "🚀 All apps launched. Log in as needed and pin them via GNOME panel if desired."

