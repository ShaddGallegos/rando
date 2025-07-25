#!/bin/bash
# rpm_cleanup.sh — Automated cleanup for stubborn RPM directories

TARGET_DIR="RPM"

echo "🔍 Checking mount status..."
mount | grep "$TARGET_DIR" && {
    echo "⚠️ Detected mount. Attempting to unmount..."
    sudo umount "$TARGET_DIR" || echo "❌ Failed to unmount $TARGET_DIR"
}

echo "🧠 Resolving device for filesystem check..."
DEVICE=$(df "$TARGET_DIR" | tail -1 | awk '{print $1}')
if [[ "$DEVICE" == /dev/* ]]; then
    echo "🔧 Running fsck on $DEVICE..."
    sudo fsck -y "$DEVICE"
else
    echo "⚠️ Could not determine block device for $TARGET_DIR"
fi

echo "🧼 Starting file deletion..."
sudo find "$TARGET_DIR" -type f -exec rm -f {} \;

echo "🚪 Clearing out directories..."
sudo find "$TARGET_DIR" -depth -type d -exec rmdir {} 2>/dev/null \;

echo "🔒 Checking for open files..."
sudo lsof +D "$TARGET_DIR" | awk 'NR>1 {print $2}' | sort -u | while read -r pid; do
    echo "❌ Killing locked PID: $pid"
    sudo kill -9 "$pid"
done

echo "🧾 Reviewing file attributes..."
sudo lsattr -R "$TARGET_DIR" 2>/dev/null | grep -v '\-\-\-\-\-\-\-\-' | while read -r attrs file; do
    if [[ "$attrs" == *i* ]]; then
        echo "🔧 Removing immutable flag: $file"
        sudo chattr -i "$file"
    fi
done

echo "✅ Cleanup complete. You may re-run this script if residuals persist."
