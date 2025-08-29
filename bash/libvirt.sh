#!/usr/bin/env bash
#
# configure-virt-manager-tray.sh
# =================================
# Run as root on RHEL9/KDE to:
# 1) Grant user 'sgallego' full libvirt rights
# 2) Install a Polkit rule for passwordless libvirt management
# 3) Autostart virt-manager with tray icon in KDE

set -euo pipefail

USERNAME="sgallego"
POLKIT_RULE_FILE="/etc/polkit-1/rules.d/60-libvirt-manage.rules"
AUTOSTART_DIR="/home/${USERNAME}/.config/autostart"
DESKTOP_FILE="${AUTOSTART_DIR}/virt-manager-tray.desktop"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: must be run as root" >&2
  exit 1
fi

# 1) Add 'sgallego' to libvirt and kvm groups
usermod -aG libvirt,kvm "${USERNAME}"

# 2) Create Polkit rule to allow virsh/virt-manager control
cat > "${POLKIT_RULE_FILE}" <<EOF
polkit.addRule(function(action, subject) {
  if (subject.user == "${USERNAME}" && action.id == "org.libvirt.unix.manage") {
    return polkit.Result.YES;
  }
});
EOF
chmod 0644 "${POLKIT_RULE_FILE}"

# 3) Drop a KDE autostart entry for virt-manager tray icon
mkdir -p "${AUTOSTART_DIR}"
cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Type=Application
Name=Virt Manager Tray
Comment=Launch virt-manager and display its tray icon
Exec=virt-manager
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=KDE;
Icon=virt-manager
EOF
chown -R "${USERNAME}:${USERNAME}" "${AUTOSTART_DIR}"
chmod 0644 "${DESKTOP_FILE}"

echo "Done. Have ${USERNAME} log out and back in to pick up new group memberships and autostart."

