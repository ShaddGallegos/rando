#!/bin/bash
# User-configurable variables - modify as needed
USER="${USER}"
USER_EMAIL="${USER}@${COMPANY_DOMAIN:-example.com}"
COMPANY_NAME="${COMPANY_NAME:-Your Company}"
COMPANY_DOMAIN="${COMPANY_DOMAIN:-example.com}"

# User-configurable variables - modify as needed
USER="${USER}"
USER_EMAIL="${USER}@${COMPANY_DOMAIN:-example.com}"
COMPANY_NAME="${COMPANY_NAME:-Your Company}"
COMPANY_DOMAIN="${COMPANY_DOMAIN:-example.com}"

# User-configurable variables - modify as needed
USER="${USER}"
USER_EMAIL="${USER}@${COMPANY_DOMAIN:-example.com}"
COMPANY_NAME="${COMPANY_NAME:-Your Company}"
COMPANY_DOMAIN="${COMPANY_DOMAIN:-example.com}"


# Script: Set_VLC_As_Default_Media_Player.sh
# Purpose: Set VLC as default media player for various formats
# Exit on error
set -e

echo " Setting VLC as default media player..."

# Check if VLC is installed
if ! command -v vlc &> /dev/null; then
    echo " VLC is not installed. Installing VLC..."
    
    # Detect package manager and install VLC
    if command -v dnf &> /dev/null; then
        sudo dnf install -y vlc
    elif command -v yum &> /dev/null; then
        sudo yum install -y vlc
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y vlc
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm vlc
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y vlc
    else
        echo " No supported package manager found. Please install VLC manually."
        exit 1
    fi
    
    echo " VLC installed successfully"
else
    echo " VLC is already installed"
fi

echo " Configuring VLC as default media player..."

# Set VLC as default for common video MIME types
video_mime_types=(
    video/mp4
    video/x-matroska
    video/x-msvideo
    video/x-ms-wmv
    video/webm
    video/ogg
    video/mpeg
    video/quicktime
    video/x-flv
    video/3gpp
)

# Set VLC as default for common audio MIME types
audio_mime_types=(
    audio/mpeg
    audio/x-wav
    audio/ogg
    audio/x-vorbis+ogg
    audio/x-flac
    audio/mp4
    audio/x-m4a
    audio/x-ms-wma
)

echo " Setting video format associations..."
for mime in "${video_mime_types[@]}"; do
    xdg-mime default vlc.desktop "$mime"
    echo "   $mime -> VLC"
done

echo " Setting audio format associations..."
for mime in "${audio_mime_types[@]}"; do
    xdg-mime default vlc.desktop "$mime"
    echo "   $mime -> VLC"
done

echo " VLC has been set as the default media player!"
echo " Supported video formats: MP4, MKV, AVI, WMV, WebM, OGG, MPEG, MOV, FLV, 3GP"
echo " Supported audio formats: MP3, WAV, OGG, FLAC, M4A, WMA"

