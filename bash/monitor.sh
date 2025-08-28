#!/bin/bash

INSTALLER="/home/sgallego/Downloads/NVIDIA-Linux-x86_64-*.run"

echo "🔧 Starting NVIDIA troubleshooting and install prep..."

# Step 1: Kernel Version Check
KERNEL=$(uname -r)
echo -e "\n🧠 Kernel Version: $KERNEL"

if [[ "$KERNEL" == 5.14.0-362.8.1* ]]; then
    echo "⚠️ Warning: Kernel $KERNEL is known to cause issues with NVIDIA driver 550.54.14 on RHEL 9.3."
    echo "Refer to: https://access.redhat.com/solutions/7074441"
fi

# Step 2: Secure Boot Check
echo -e "\n🔐 Secure Boot Status:"
if command -v mokutil &> /dev/null; then
    mokutil --sb-state
else
    echo "mokutil not installed. Run: sudo dnf install mokutil"
fi

# Step 3: DKMS Check
echo -e "\n🧪 Checking for DKMS:"
if command -v dkms &> /dev/null; then
    echo "✅ DKMS is installed."
    dkms status || echo "No DKMS modules currently registered."
else
    echo "❌ DKMS not found. Run: sudo dnf install dkms"
fi

# Step 4: NVIDIA Driver Status
echo -e "\n📦 NVIDIA Driver Status:"
if command -v nvidia-smi &> /dev/null; then
    echo "✅ NVIDIA driver is installed."
    nvidia-smi
else
    echo "❌ No NVIDIA driver detected."
fi

# Step 5: Display Detection
echo -e "\n📺 Connected Displays:"
xrandr | grep " connected" || echo "No connected displays detected."

echo -e "\n📐 Display Modes:"
xrandr | grep -E " connected|[0-9]+x[0-9]+"

# Step 6: GPU Info
echo -e "\n🧠 NVIDIA GPU Info:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
else
    echo "nvidia-smi not available."
fi

# Step 7: Environment Check for nvidia-settings
echo -e "\n🛡️ Checking environment for nvidia-settings..."

if [[ -z "$DISPLAY" ]]; then
    echo "❌ DISPLAY variable not set. You're not in a graphical session."
else
    echo "✅ DISPLAY is set to $DISPLAY"
fi

if [[ -z "$XDG_RUNTIME_DIR" ]]; then
    echo "❌ XDG_RUNTIME_DIR not set. Attempting to set it..."
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    echo "✅ XDG_RUNTIME_DIR set to $XDG_RUNTIME_DIR"
fi

# Step 8: Launch nvidia-settings safely
echo -e "\n🖥️ Attempting to launch nvidia-settings..."
if command -v nvidia-settings &> /dev/null; then
    if [[ -n "$DISPLAY" ]]; then
        echo "Launching nvidia-settings..."
        nvidia-settings &
    else
        echo "⚠️ Cannot launch nvidia-settings: not in a graphical session."
    fi
else
    echo "❌ nvidia-settings not found. Run: sudo dnf install nvidia-settings"
fi

# Step 9: NVIDIA Installer Instructions
echo -e "\n🚀 NVIDIA Driver Install Instructions:"
echo "Installer path: $INSTALLER"
echo "To install:"
echo "1. Switch to TTY (Ctrl+Alt+F3) and log in."
echo "2. Stop graphical session:"
echo "   sudo systemctl isolate multi-user.target"
echo "3. Run installer:"
echo "   sudo bash $INSTALLER"
echo "4. Reboot:"
echo "   sudo reboot"

echo -e "\n✅ Script complete. Follow the install steps above if needed."

