#!/bin/bash

SERVICE_DIR="/usr/share/dbus-1/services"
TEMP_DIR="/tmp/dbus-service-fix"
mkdir -p "$TEMP_DIR"

echo "Search Scanning D-Bus service files in $SERVICE_DIR..."

for file in "$SERVICE_DIR"/*.service; do
  [[ -f "$file" ]] || continue

# Extract Name= from the file
  name=$(grep -E '^Name=' "$file" | cut -d= -f2)

    if [[ -z "$name" ]]; then
      echo "[FAIL] $file is missing 'Name=' key. Skipping."
      continue
    fi

    expected_filename="$SERVICE_DIR/$name.service"

# Check filename mismatch
    if [[ "$(basename "$file")" != "$name.service" ]]; then
      echo "[WARNING] Filename mismatch: $(basename "$file") should be $name.service"
      cp "$file" "$TEMP_DIR/$name.service"
      echo "[PASS] Copied to $TEMP_DIR/$name.service for review"
      fi

# Check for required keys
      has_exec=$(grep -E '^Exec=' "$file")
        has_systemd=$(grep -E '^SystemdService=' "$file")

          if [[ -z "$has_exec" && -z "$has_systemd" ]]; then
            echo "[FAIL] $file is missing both 'Exec=' and 'SystemdService='"
            echo "Documentation Consider adding one of them manually:"
            echo " Exec=/usr/bin/example-command"
            echo " OR"
            echo " SystemdService=example.service"
          fi
        done

        echo "[PASS] Scan complete. Review and move fixed files from $TEMP_DIR back to $SERVICE_DIR if needed."

