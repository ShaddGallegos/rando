#!/bin/bash
# filepath: /home/sgallego/Downloads/GIT/rando/fix_nvidia.sh

echo "=== Checking NVIDIA driver and kernel ==="

# 1. Check current kernel version and NVIDIA module
uname -r
lsmod | grep nvidia && echo "NVIDIA kernel module loaded." || echo "NVIDIA kernel module NOT loaded."

# 2. Check for NVIDIA driver package
if command -v nvidia-smi &>/dev/null; then
  echo "nvidia-smi found:"
  nvidia-smi
else
  echo "nvidia-smi not found. NVIDIA driver may not be installed."
fi

# 3. Check for conflicting nouveau module
lsmod | grep nouveau && echo "WARNING: nouveau (open-source NVIDIA) driver loaded. This can conflict with NVIDIA's driver."

# 4. Suggest fixes
echo
echo "=== Suggested Fixes ==="
echo "1. If you recently updated your kernel, reinstall the NVIDIA driver."
echo "2. Remove the 'nouveau' driver if present (blacklist it)."
echo "3. Reboot after reinstalling the NVIDIA driver."
echo "4. If you use Secure Boot, ensure it is disabled or NVIDIA modules are signed."
echo
echo "To reinstall NVIDIA driver on Fedora/RHEL:"
echo "  sudo dnf reinstall akmod-nvidia xorg-x11-drv-nvidia"
echo "  sudo akmods --force"
echo "  sudo dracut --force"
echo "  sudo reboot"
echo
echo "If you use a different distro, use the appropriate package manager."
echo
echo "If you see 'libva' errors and do not use Intel graphics, you can ignore them."