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


# Slack UI Installer for RHEL 9
# This script downloads and installs Slack from the official RPM,
# then launches it for use with your Slack channels.

echo " Checking system compatibility..."
if ! grep -q "${COMPANY_NAME} Enterprise Linux release 9" /etc/${COMPANY_NAME}-release; then
  echo " This script is intended for RHEL 9 only."
  exit 1
fi

echo " Downloading latest Slack RPM..."
cd /tmp
SLACK_URL="https://downloads.slack-edge.com/linux_releases/slack-4.38.121-0.1.fc21.x86_64.rpm"
wget -q --show-progress "$SLACK_URL" -O slack.rpm

echo " Installing Slack..."
sudo dnf install -y ./slack.rpm

echo " Launching Slack UI..."
nohup slack &>/dev/null &

echo " Slack is now running in UI mode. Enjoy your channels!"

