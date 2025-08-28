 
#!/bin/bash

echo "🔄 Resetting Strawberry Media Player to default settings..."

# Kill any running instance
pkill -x strawberry

# Remove Strawberry's configuration directory
rm -rf "$HOME/.config/strawberry"
rm -rf "$HOME/.local/share/strawberry"
rm -rf "$HOME/.cache/strawberry"

# Optional: reset dconf settings if Strawberry uses them
if command -v dconf >/dev/null; then
  dconf reset -f /org/strawberry/
fi

# Launch with GStreamer backend override to avoid bs2b
GST_PLUGIN_FEATURE_RANK=bs2b:0 strawberry &

echo "✅ Strawberry has been reset to defaults and launched without bs2b."
