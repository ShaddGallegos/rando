# fix_git_permissions.sh
#!/bin/bash

BASE_DIR="/home/sgallego/Downloads/GIT"
USER_NAME="sgallego"
GROUP_NAME="sgallego"

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
