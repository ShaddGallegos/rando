#!/bin/bash

# KDE RHEL 7 Emulation Script for RHEL 9
# Run as root or with sudo

echo "🔧 Updating system..."
dnf update -y

echo "🖥️ Installing KDE Plasma Desktop (if not already installed)..."
dnf groupinstall -y "KDE Plasma Workspaces"

echo "🎨 Installing GTK themes and icon packs..."
dnf install -y arc-theme numix-gtk-theme papirus-icon-theme

echo "🔤 Ensuring Cantarell font is installed..."
dnf install -y cantarell-fonts

echo "🖼️ Downloading RHEL 7 wallpaper..."
WALLPAPER_URL="https://raw.githubusercontent.com/linuxmint-art/wallpapers/master/rhel7-default.jpg"
WALLPAPER_PATH="$HOME/Pictures/rhel7-wallpaper.jpg"
curl -L "$WALLPAPER_URL" -o "$WALLPAPER_PATH"

echo "🖼️ Setting wallpaper (via Plasma config)..."
plasma-apply-wallpaperimage "$WALLPAPER_PATH"

echo "🔧 Configuring GTK apps to use Adwaita theme..."
mkdir -p ~/.config/gtk-3.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Cantarell 11
EOF

echo "🎨 Setting KDE Plasma theme and fonts..."
kwriteconfig5 --file kdeglobals --group General --key ColorScheme "Breeze"
kwriteconfig5 --file kdeglobals --group General --key Name "RHEL7-Style"
kwriteconfig5 --file kdeglobals --group General --key font "Cantarell,11,-1,5,50,0,0,0,0,0"

echo "🧱 Setting up traditional panel layout..."
echo "⚠️ Please manually configure panels via KDE's panel settings to match RHEL 7 layout:"
echo "   - Top panel with Application Menu and System Tray"
echo "   - Bottom panel with Task Manager and Pager"

echo "✅ KDE RHEL 7-style setup complete!"


