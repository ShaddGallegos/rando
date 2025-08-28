#!/bin/bash

echo "🔍 Detecting GPU..."

# 1. Detect video card
gpu_info=$(lspci | grep -i 'vga\|3d\|2d')
echo "[+] GPU Info: $gpu_info"

# 2. Check if it's NVIDIA
if echo "$gpu_info" | grep -iq "nvidia"; then
    echo "[+] NVIDIA GPU detected."

    # 3. Extract device string
    device=$(echo "$gpu_info" | grep -oP 'NVIDIA.*')

    # 4. Fetch driver recommendation from NVIDIA's CLI tool
    if command -v nvidia-detect &>/dev/null; then
        echo "[+] Using nvidia-detect..."
        nvidia-detect
    else
        echo "[!] nvidia-detect not installed. Attempting manual scrape."

        # 5. Get PCI ID
        pci_id=$(lspci -nn | grep -i "nvidia" | grep -oP '

\[\K[0-9a-fA-F]{4}:[0-9a-fA-F]{4}')
        echo "[+] PCI ID: $pci_id"

        # 6. Scrape NVIDIA's driver list using PCI ID
        echo "[+] Searching NVIDIA site for recommended driver..."

        curl -s "https://www.nvidia.com/Download/Find.aspx?lang=en-us" | \
            grep -i "$pci_id" | \
            grep -Eo 'https://download\.nvidia\.com/[^"]+' | \
            head -n 1
    fi
else
    echo "[!] No NVIDIA GPU found. This script only supports NVIDIA cards."
    exit 1
fi

echo "✅ Done."
