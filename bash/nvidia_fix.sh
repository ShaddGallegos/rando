#!/bin/bash

# 🚂 Welcome aboard the Iron GPU Express
echo "🔧 [Initializing Steamworks Engine: GPU Purge Protocol]"

# Step 1: Remove NVIDIA remnants
echo "🧹 [Scouring system for rogue NVIDIA modules...]"
dnf remove -y '*nvidia*'
rm -rf /usr/local/cuda*

# Step 2: Blacklist Nouveau
echo "🕶️ [Deploying blacklisting goggles for Nouveau...]"
cat <<EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# Step 3: Rebuild initramfs
echo "🔁 [Reassembling the initramfs exoskeleton...]"
dracut --force

# Step 4: Install essential build tools
echo "⚙️ [Forging compiler and headers for driver resurrection...]"
dnf install -y kernel-devel kernel-headers gcc make

# Step 5: Ready for NVIDIA driver installation
echo "🚀 [System primed. Please reboot, switch to console (Ctrl+Alt+F3), and run the .run installer]"
echo "Example: sudo bash NVIDIA-Linux-x86_64-*.run"

# Step 6: Final words
echo "🎩 [Mission logged. Reboot to continue your GPU odyssey.]"

