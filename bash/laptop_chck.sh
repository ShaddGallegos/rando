
#!/bin/bash

echo "🧠 SysScope: Retro Diagnostic & Auto-Fix Scanner 🚀"
echo "----------------------------------------"

# Check for deprecated/unmaintained drivers
echo -e "\n🔎 Checking for deprecated drivers..."
journalctl -xb | grep -Ei 'Deprecated Driver|Unmaintained driver' | tee /tmp/sysscope_drivers.txt

# Check for Bluetooth issues
echo -e "\n📡 Scanning Bluetooth logs..."
journalctl -xb | grep -Ei 'bluetooth|hci0|Set device flags|avrcp|Invalid Parameters' | tee /tmp/sysscope_bluetooth.txt

# Check for DBus service file conflicts
echo -e "\n🧩 Reviewing DBus service file warnings..."
journalctl -xb | grep -Ei 'org.freedesktop.FileManager1|Invalid service file' | tee /tmp/sysscope_dbus.txt

# Check for DNF makecache failures
echo -e "\n🛒 Checking DNF cache health..."
journalctl -u dnf-makecache.service | tail -n 20 | tee /tmp/sysscope_dnf.txt

# Check and refresh subscription-manager
echo -e "\n🔑 Checking Red Hat subscription status..."
sudo subscription-manager status
sudo subscription-manager refresh
sudo subscription-manager repos --list-enabled
sudo dnf clean all
sudo dnf repolist

# Check NVIDIA driver status
echo -e "\n🖥️ Checking NVIDIA driver and kernel module status..."
sudo dmesg | grep -i nvidia | tee /tmp/sysscope_nvidia_dmesg.txt
lsmod | grep nvidia | tee /tmp/sysscope_nvidia_lsmod.txt
nvidia-smi || echo "nvidia-smi failed. Consider reinstalling the NVIDIA driver."

# Check SELinux status and recent denials
echo -e "\n🔒 Checking SELinux status and recent denials..."
getenforce | tee /tmp/sysscope_selinux_status.txt
sudo sealert -a /var/log/audit/audit.log | tail -n 20 | tee /tmp/sysscope_selinux_denials.txt

# Clean DNF cache and refresh repos
echo -e "\n🛒 Cleaning DNF/YUM cache and refreshing repos..."
sudo dnf clean all
sudo dnf repolist
sudo dnf update

# Create missing NVIDIA config file if needed
echo -e "\n🛠️ Creating missing NVIDIA IMEX config file if needed..."
if [ ! -f /etc/nvidia-imex/nodes_config.cfg ]; then
  sudo touch /etc/nvidia-imex/nodes_config.cfg
  sudo chmod 644 /etc/nvidia-imex/nodes_config.cfg
  echo "# Created empty config file for NVIDIA IMEX" | sudo tee /etc/nvidia-imex/nodes_config.cfg
fi

echo -e "\n📝 Summary:"
echo "Deprecated Drivers  → $(wc -l < /tmp/sysscope_drivers.txt) issues"
echo "Bluetooth Quirks    → $(wc -l < /tmp/sysscope_bluetooth.txt) issues"
echo "DBus Conflicts      → $(wc -l < /tmp/sysscope_dbus.txt) issues"
echo "DNF Cache Failures  → $(wc -l < /tmp/sysscope_dnf.txt) entries"
echo "NVIDIA dmesg        → $(wc -l < /tmp/sysscope_nvidia_dmesg.txt) entries"
echo "NVIDIA lsmod        → $(wc -l < /tmp/sysscope_nvidia_lsmod.txt) entries"
echo "SELinux Denials     → $(wc -l < /tmp/sysscope_selinux_denials.txt) entries"

echo -e "\n🎯 Report saved in /tmp/sysscope_*.txt for review."
echo "----------------------------------------"
echo "👾 Stay frosty, sys ops detective!"
