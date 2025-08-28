#!/bin/bash
# filepath: /home/sgallego/Downloads/GIT/rando/fix_nvidia_auto.sh

set -e

echo "=== Enabling EPEL and RPM Fusion repositories ==="
sudo dnf install -y epel-release
sudo dnf install -y \
  https://download1.rpmfusion.org/free/el/rpmfusion-free-release-9.noarch.rpm \
  https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-9.noarch.rpm

echo "=== Enabling required RHEL 9 repositories ==="
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms || true
sudo subscription-manager repos --enable rhel-9-for-$(arch)-baseos-rpms || true
sudo subscription-manager repos --enable rhel-9-for-$(arch)-appstream-rpms || true

echo "=== Disabling unnecessary, source, debug, beta, and test repositories ==="
# Disable CUDA and NVIDIA repos
sudo dnf config-manager --set-disabled cuda-rhel9-x86_64 || true
sudo dnf config-manager --set-disabled cuda* || true
sudo dnf config-manager --set-disabled nvidia* || true
# Disable all source, debug, beta, and test repos
for repo in $(dnf repolist all | awk '/enabled|disabled/ {print $1}' | grep -E 'source|debug|test|beta'); do
  sudo dnf config-manager --set-disabled "$repo" || true
done
# Disable RPM Fusion testing repos
sudo dnf config-manager --set-disabled rpmfusion-free-updates-testing || true
sudo dnf config-manager --set-disabled rpmfusion-nonfree-updates-testing || true

echo "=== Cleaning DNF metadata and updating system ==="
sudo dnf clean all
sudo dnf makecache
sudo dnf update -y

echo "=== Blacklisting nouveau driver ==="
cat <<EOF | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

echo "Regenerating initramfs to apply nouveau blacklist..."
sudo dracut --force

echo "=== Installing NVIDIA drivers (akmod-nvidia) ==="
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia --nobest

echo "Forcing akmods to rebuild NVIDIA kernel modules..."
sudo akmods --force

echo "Regenerating initramfs again for NVIDIA modules..."
sudo dracut --force

echo "=== All steps complete ==="
echo "Please reboot your system to apply changes:"
echo "  sudo reboot"