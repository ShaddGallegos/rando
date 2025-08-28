#!/bin/bash

set -e

echo "🔧 Starting KDE/Plasma cleanup for RHEL 9..."

# Step 1: Update system packages
echo "📦 Updating system..."
sudo dnf upgrade --refresh -y

# Step 2: Clean package metadata and cache
echo "🧹 Cleaning DNF cache..."
sudo dnf clean all

# Step 3: Remove orphaned packages
echo "🗑️ Removing unused packages..."
sudo dnf autoremove -y

# Step 4: Clear user-level KDE/Plasma cache
echo "🧼 Clearing user cache..."
rm -rf ~/.cache/*
rm -rf ~/.config/session/*
rm -rf ~/.local/share/kscreen/*

# Step 5: Optionally reset Plasma configs (comment out to preserve layout)
# echo "⚠️ Resetting Plasma configuration..."
# rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc
# rm -f ~/.config/kdeglobals
# rm -f ~/.config/kwinrc
# rm -f ~/.config/ksmserverrc

# Step 6: Restart Plasma shell
echo "🔄 Restarting Plasma shell..."
kquitapp5 plasmashell || true
kstart5 plasmashell &

# Step 7: Restart KWin (window manager)
echo "🔄 Restarting KWin..."
kwin_x11 --replace &

# Step 8: Check for broken packages or missing dependencies
echo "🔍 Verifying installed packages..."
sudo rpm -Va --nofiles --nodigest

echo "✅ KDE/Plasma cleanup complete!"

