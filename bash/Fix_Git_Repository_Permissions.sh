# fix_git_permissions.sh
#!/bin/bash

# Get current user and group dynamically
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)

# Use environment variables or defaults
BASE_DIR="${GIT_BASE_DIR:-$HOME/Downloads/GIT}"
USER_NAME="${GIT_USER:-$CURRENT_USER}"
GROUP_NAME="${GIT_GROUP:-$CURRENT_GROUP}"

echo "🔍 Searching for Git repositories in $BASE_DIR..."

find "$BASE_DIR" -type d -name ".git" | while read -r git_dir; do
    echo "📁 Checking $git_dir..."
    
    # Check for root-owned files
    root_owned=$(find "$git_dir" \! -user "$USER_NAME")

    if [ -n "$root_owned" ]; then
        echo "⚠️ Found files owned by root in $git_dir. Fixing permissions..."
        sudo chown -R "$USER_NAME:$GROUP_NAME" "$git_dir"
        echo "✅ Permissions fixed for $git_dir"
    else
        echo "👍 No permission issues in $git_dir"
    fi
done

echo "🎉 All repositories checked and fixed!"
