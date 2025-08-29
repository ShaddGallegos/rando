#!/bin/bash
# filepath: /home/sgallego/Downloads/GIT/rando/login_check.sh

user="sgallego"
echo "=== Diagnosing Slow Login Issues ==="

# 1. Check DNS resolution speed
echo -n "Testing DNS resolution for localhost... "
  getent hosts localhost >/dev/null && echo "OK" || echo "FAILED"

  MYIP=$(hostname -I | awk '{print $1}')
    echo -n "Testing reverse DNS for your IP ($MYIP)... "
      getent hosts $MYIP >/dev/null && echo "OK" || echo "FAILED"

# 2. Check for network mounts in /etc/fstab
      echo "Checking for network mounts in /etc/fstab:"
        grep -E 'nfs|cifs|smb' /etc/fstab || echo " No network mounts found."

# 3. Check for problematic PAM modules
        echo "Checking for problematic PAM modules (pam_lastlog, pam_motd, pam_systemd):"
          grep -E 'pam_lastlog|pam_motd|pam_systemd' /etc/pam.d/*

# 4. Check for slow commands in shell profile files
          echo "Checking for slow commands in ~/.bashrc and ~/.profile:"
            grep -E 'sleep|ping|curl|wget|systemctl|mount' ~/.bashrc ~/.profile 2>/dev/null

# 5. Check home directory permissions
            echo "Checking home directory permissions:"
            ls -ld ~

# 6. KDE/Plasma-specific: Disable Baloo file indexer
            if command -v balooctl &>/dev/null; then
              echo "Disabling KDE Baloo file indexer..."
              balooctl disable
            fi

# 7. Clean up user cache
            echo "Cleaning up user cache..."
            rm -rf ~/.cache/*

# 8. Add hostname to /etc/hosts for fast local DNS
            if ! grep -q "$(hostname)" /etc/hosts; then
              echo "Adding hostname to /etc/hosts for fast local DNS..."
                sudo sh -c "echo '127.0.0.1 $(hostname)' >> /etc/hosts"
              else
                echo "Hostname already present in /etc/hosts."
              fi

              echo "=== Review the output above for possible issues. ==="
                echo "Common fixes applied:"
                echo "- Disabled Baloo file indexer (if present)."
                echo "- Cleaned up user cache."
                echo "- Ensured hostname is in /etc/hosts."
                echo
                echo "If login is still slow, check system logs with:"
                echo " journalctl -b | grep -i error"
                echo "or for user session issues:"
                  echo " journalctl -b | grep -i sgallego"
