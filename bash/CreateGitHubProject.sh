#!/bin/bash
echo " Create a Project in your GitHub repository "

read -p "Enter full path to your local project directory: " project_path
read -p "Enter your GitHub username: " gh_user
read -s -p "Enter your GitHub personal access token: " gh_token
echo

# Extract repo name from the last folder in the path
repo_name=$(basename "$project_path")
repo_url="https://github.com/$gh_user/$repo_name.git"

# Navigate to the project directory
cd "$project_path" || { echo "Directory not found."; exit 1; }

# Initialize Git repo if not already
if [ ! -d ".git" ]; then
    git init
fi

# Add files and commit
git add .
git commit -m "Initial commit"

# Create repo on GitHub using API
curl -u "$gh_user:$gh_token" https://api.github.com/user/repos -d "{\"name\":\"$repo_name\"}"

# Add remote and push
git remote add origin "$repo_url"
git branch -M main
git push -u origin main

echo " Project '$repo_name' has been pushed to GitHub!"
