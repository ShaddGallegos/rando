#!/bin/bash

# Ensure KDE is running
if [ -z "$XDG_CURRENT_DESKTOP" ] || [[ "$XDG_CURRENT_DESKTOP" != *"KDE"* ]]; then
  echo "This script must be run inside a KDE Plasma session."
  exit 1
fi

echo "Installation Installing Windows 10-style themes and icons..."

# Install dependencies
sudo dnf install -y git curl unzip

# Create temp directory
mkdir -p ~/win10-kde-setup
cd ~/win10-kde-setup

# Download Windows 10 global theme
git clone https://github.com/B00merang-Project/Windows-10.git
mkdir -p ~/.local/share/plasma/look-and-feel
cp -r Windows-10/* ~/.local/share/plasma/look-and-feel/

# Download Windows 10 icon theme
git clone https://github.com/B00merang-Artwork/Windows-10-Icons.git
mkdir -p ~/.local/share/icons
cp -r Windows-10-Icons/* ~/.local/share/icons/

# Download Windows 10 wallpaper
curl -L -o ~/Pictures/win10-wallpaper.jpg https://wallpapercave.com/wp/wp2552010.jpg

# Apply wallpaper (via config file)
plasma_version=$(plasmashell --version | grep -oP '\d+\.\d+')
  if [[ "$plasma_version" < "5.27" ]]; then
    echo "[WARNING] Plasma version too old for wallpaper automation. Please set it manually."
    else
      qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
      var allDesktops = desktops();
      for (i=0;i<allDesktops.length;i++) {
        d = allDesktops[i];
        d.wallpaperPlugin = 'org.kde.image';
        d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
        d.writeConfig('Image', 'file:///home/$USER/Pictures/win10-wallpaper.jpg');
      }
      "
    fi

# Apply theme and icons (requires user confirmation)
    echo "[PASS] Themes and icons installed!"
    echo " Open System Settings → Appearance → Global Theme and select 'Windows 10'"
    echo " Then go to Icons and select 'Windows 10 Icons'"
    echo " Set wallpaper manually if needed: ~/Pictures/win10-wallpaper.jpg"

# Cleanup
      cd ~
      rm -rf ~/win10-kde-setup

      echo " Done! Your KDE desktop is ready to look like Windows 10."

