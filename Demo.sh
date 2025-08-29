#!/bin/bash

# Exit on any error
set -e

# Variables
BASTION_HOST="ansible-1.z4dpp.sandbox1106.opentlc.com"
SATELLITE_HOST="satellite.z4dpp.sandbox1106.opentlc.com"
BASTION_USER="student"
SATELLITE_USER="student"
SSH_KEY="$HOME/.ssh/id_rsa"
SSH_CONFIG="$HOME/.ssh/config"
INVENTORY_FILE="$HOME/ansible_inventory.ini"
PLAYBOOK_FILE="$HOME/sample_playbook.yml"

# Prompt for password
read -s -p "Enter SSH password for $BASTION_USER@$BASTION_HOST: " SSH_PASSWORD
  echo

# Check for sshpass
  if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if ! (sudo apt-get install -y sshpass || sudo dnf install -y sshpass || sudo yum install -y sshpass); then
      echo "ERROR: Failed to install sshpass. Please install it manually."
      exit 1
    fi
  fi

# Generate SSH key if needed
  if [ ! -f "$SSH_KEY" ]; then
    echo "Generating SSH key..."
    if ! ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""; then
      echo "ERROR: Failed to generate SSH key."
      exit 1
    fi
  fi

# Copy SSH key to bastion
  echo "Copying SSH key to bastion..."
  if ! sshpass -p "$SSH_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i "$SSH_KEY.pub" "$BASTION_USER@$BASTION_HOST"; then
    echo "ssh-copy-id failed, trying manual method..."
# Fallback: try manual method
    if ! sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$BASTION_USER@$BASTION_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"; then
      echo "ERROR: Failed to create .ssh directory on bastion."
      exit 1
    fi

    if ! sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no "$SSH_KEY.pub" "$BASTION_USER@$BASTION_HOST:~/.ssh/temp_key.pub"; then
      echo "ERROR: Failed to copy SSH key to bastion."
      exit 1
    fi

    if ! sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$BASTION_USER@$BASTION_HOST" "cat ~/.ssh/temp_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm ~/.ssh/temp_key.pub"; then
      echo "ERROR: Failed to install SSH key on bastion."
      exit 1
    fi
    echo "SSH key installed on bastion using manual method."
  fi

# Copy SSH key to satellite via bastion
  echo "Copying SSH key to satellite via bastion..."
  if ! sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -J "$BASTION_USER@$BASTION_HOST" "$SATELLITE_USER@$SATELLITE_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"; then
    echo "ERROR: Failed to create .ssh directory on satellite."
    exit 1
  fi

  if ! sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no -o ProxyJump="$BASTION_USER@$BASTION_HOST" "$SSH_KEY.pub" "$SATELLITE_USER@$SATELLITE_HOST:~/.ssh/temp_key.pub"; then
    echo "ERROR: Failed to copy SSH key to satellite."
    exit 1
  fi

  if ! sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no -J "$BASTION_USER@$BASTION_HOST" "$SATELLITE_USER@$SATELLITE_HOST" "cat ~/.ssh/temp_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && rm ~/.ssh/temp_key.pub"; then
    echo "ERROR: Failed to install SSH key on satellite."
    exit 1
  fi

# Update SSH config
  echo "Updating SSH config..."
  if ! mkdir -p "$HOME/.ssh"; then
    echo "ERROR: Failed to create .ssh directory."
    exit 1
  fi

  if ! chmod 700 "$HOME/.ssh"; then
    echo "ERROR: Failed to set permissions on .ssh directory."
    exit 1
  fi

# Remove existing entries if they exist
  sed -i '/^Host bastion$/,/^$/d' "$SSH_CONFIG" 2>/dev/null
  sed -i '/^Host satellite$/,/^$/d' "$SSH_CONFIG" 2>/dev/null

  cat <<EOF >> "$SSH_CONFIG"

  Host bastion
  HostName $BASTION_HOST
  User $BASTION_USER
  StrictHostKeyChecking no

  Host satellite
  HostName $SATELLITE_HOST
  User $SATELLITE_USER
  ProxyJump bastion
  StrictHostKeyChecking no
  EOF

  chmod 600 "$SSH_CONFIG"

# Create Ansible inventory
  echo "Creating Ansible inventory..."
  cat <<EOF > "$INVENTORY_FILE"
  [satellites]
  satellite-host ansible_host=$SATELLITE_HOST ansible_user=$SATELLITE_USER

  [all:vars]
  ansible_ssh_common_args='-o ProxyJump=$BASTION_USER@$BASTION_HOST -o StrictHostKeyChecking=no'
  EOF

# Create sample playbook
  echo "Creating sample playbook..."
  cat <<EOF > "$PLAYBOOK_FILE"
  ---
  - name: Sample Playbook
  hosts: satellites
  become: true
  tasks:
  - name: Ensure curl is installed
  package:
  name: curl
  state: present

  - name: Test connectivity
  ping:
  EOF

# Run the playbook
  echo "Running Ansible playbook..."
  if ! ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"; then
    echo "ERROR: Ansible playbook execution failed."
    exit 1
  fi

  echo "Setup complete - All steps successful!"
