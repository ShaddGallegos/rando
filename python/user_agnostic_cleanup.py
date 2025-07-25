#!/usr/bin/env python3
"""
User-configurable variables - modify as needed
"""
import os
import getpass

# User configuration
USER = os.getenv('USER', getpass.getuser())
USER_EMAIL = os.getenv('USER_EMAIL', f"{USER}@{os.getenv('COMPANY_DOMAIN', 'example.com')}")
COMPANY_NAME = os.getenv('COMPANY_NAME', 'Your Company')
COMPANY_DOMAIN = os.getenv('COMPANY_DOMAIN', 'example.com')

"""
User-configurable variables - modify as needed
"""
import os
import getpass

# User configuration
USER = os.getenv('USER', getpass.getuser())
USER_EMAIL = os.getenv('USER_EMAIL', f"{USER}@{os.getenv('COMPANY_DOMAIN', 'example.com')}")
COMPANY_NAME = os.getenv('COMPANY_NAME', 'Your Company')
COMPANY_DOMAIN = os.getenv('COMPANY_DOMAIN', 'example.com')

"""
User-Agnostic Cleanup Script
Removes specific user references and empty files across all projects
"""

import os
import re
import glob
import getpass
from pathlib import Path

def get_current_user():
    """Get current system username"""
    return getpass.getuser()

def clean_user_references(text):
    """Remove specific user references and make content user-agnostic"""
    
    # Get current user for dynamic replacement
    current_user = get_current_user()
    
    # Replace specific user references with generic variables
    replacements = {
        # Email addresses
        r'${USER}@${COMPANY_NAME}\.com': '${USER_EMAIL}',
        r'${USER}@${COMPANY_NAME}\.com': '${USER_EMAIL}',
        r'[a-zA-Z0-9._%+-]+@${COMPANY_NAME}\.com': '${USER_EMAIL}',
        
        # Username references
        r'\b${USER}\b': '${USER}',
        r'\bshadd\b': '${USER}',
        
        # Path references
        r'/home/${USER}/': '/home/${USER}/',
        r'/home/${USER}/': '/home/${USER}/',
        
        # Company-specific references
        r'${COMPANY_NAME}\.com': '${COMPANY_DOMAIN}',
        r'${COMPANY_NAME}': '${COMPANY_NAME}',
        r'${COMPANY_NAME}': '${COMPANY_NAME}',
        
        # Author/contact info
        r'Author:.*${USER}.*': 'Author: ${USER}',
        r'Author:.*${USER}.*': 'Author: ${USER}',
        r'Contact:.*${USER}.*': 'Contact: ${USER_EMAIL}',
        r'Contact:.*${USER}.*': 'Contact: ${USER_EMAIL}',
        
        # Git/version control
        r'github\.com/${USER}': 'github.com/${USER}',
        r'github\.com/${USER}': 'github.com/${USER}',
    }
    
    # Apply replacements
    for pattern, replacement in replacements.items():
        text = re.sub(pattern, replacement, text, flags=re.IGNORECASE)
    
    return text

def add_user_variables_header(content, file_extension):
    """Add user variable definitions at the top of files"""
    
    current_user = get_current_user()
    
    if file_extension == '.sh':
        header = f'''#!/bin/bash
# User-configurable variables - modify as needed
USER="{current_user}"
USER_EMAIL="${{USER}}@${{COMPANY_DOMAIN:-example.com}}"
COMPANY_NAME="${{COMPANY_NAME:-Your Company}}"
COMPANY_DOMAIN="${{COMPANY_DOMAIN:-example.com}}"

'''
    elif file_extension == '.py':
        header = f'''#!/usr/bin/env python3
"""
User-configurable variables - modify as needed
"""
import os
import getpass

# User configuration
USER = os.getenv('USER', getpass.getuser())
USER_EMAIL = os.getenv('USER_EMAIL', f"{{USER}}@{{os.getenv('COMPANY_DOMAIN', 'example.com')}}")
COMPANY_NAME = os.getenv('COMPANY_NAME', 'Your Company')
COMPANY_DOMAIN = os.getenv('COMPANY_DOMAIN', 'example.com')

'''
    else:
        return content
    
    # Check if file already has a shebang
    lines = content.split('\n')
    if lines and lines[0].startswith('#!'):
        # Replace shebang line and add variables after
        return header + '\n'.join(lines[1:])
    else:
        # Add header at the beginning
        return header + content

def is_empty_file(file_path):
    """Check if file is empty or contains only whitespace/comments"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().strip()
            
        # Remove comments and whitespace
        lines = content.split('\n')
        non_empty_lines = []
        
        for line in lines:
            line = line.strip()
            # Skip empty lines and comment-only lines
            if line and not line.startswith('#') and not line.startswith('//'):
                non_empty_lines.append(line)
        
        # Check for minimal content
        remaining_content = '\n'.join(non_empty_lines).strip()
        
        # Consider file empty if it has no meaningful content
        if len(remaining_content) < 10:  # Less than 10 chars of actual content
            return True
            
        # Check for common empty file patterns
        empty_patterns = [
            r'^\s*$',  # Only whitespace
            r'^\s*#!/bin/bash\s*$',  # Only shebang
            r'^\s*#!/usr/bin/env\s+python3?\s*$',  # Only python shebang
        ]
        
        for pattern in empty_patterns:
            if re.match(pattern, remaining_content, re.MULTILINE):
                return True
                
        return False
        
    except Exception:
        return False

def clean_file(file_path):
    """Clean a single file of user-specific references"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Clean user references
        cleaned_content = clean_user_references(content)
        
        # Add user variables header for script files
        file_extension = Path(file_path).suffix
        if file_extension in ['.sh', '.py'] and len(cleaned_content.strip()) > 0:
            # Only add header if file has substantial content
            if not is_empty_file(file_path):
                cleaned_content = add_user_variables_header(cleaned_content, file_extension)
        
        # Only write if content changed
        if cleaned_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(cleaned_content)
            return True, "Updated"
        return False, "No changes needed"
    
    except Exception as e:
        return False, f"Error: {e}"

def find_and_remove_empty_files(search_paths):
    """Find and remove empty files"""
    empty_files = []
    
    for search_path in search_paths:
        if os.path.exists(search_path):
            # Find all files
            for pattern in ['**/*.py', '**/*.sh', '**/*.txt', '**/*.md']:
                files = glob.glob(os.path.join(search_path, pattern), recursive=True)
                
                for file_path in files:
                    # Skip backup directories and special files
                    if any(skip in file_path for skip in ['backup', 'venv', '__pycache__', '.git', '.tmp']):
                        continue
                    
                    if is_empty_file(file_path):
                        empty_files.append(file_path)
    
    return empty_files

def main():
    print("User-Agnostic Cleanup Script")
    print("============================")
    print("Making all scripts user-agnostic and removing empty files")
    print()
    
    # Define search paths
    search_paths = [
        '/home/${USER}/Downloads/GIT/BusinessToolsBrowser',
        '/home/${USER}/Downloads/GIT/rando',
        '.'  # Current directory
    ]
    
    # Find all script files
    script_files = []
    for search_path in search_paths:
        if os.path.exists(search_path):
            for pattern in ['**/*.py', '**/*.sh']:
                script_files.extend(glob.glob(os.path.join(search_path, pattern), recursive=True))
    
    # Remove duplicates
    script_files = list(set(script_files))
    
    print(f"Found {len(script_files)} script files to process")
    print()
    
    # Process files
    processed = 0
    updated = 0
    
    for file_path in script_files:
        # Skip backup directories and virtual environments
        if any(skip in file_path for skip in ['backup', 'venv', '__pycache__', '.git']):
            continue
        
        print(f"Processing: {file_path}")
        
        success, message = clean_file(file_path)
        if success:
            updated += 1
            print(f"  {message}")
        else:
            print(f"  {message}")
        
        processed += 1
    
    print()
    print("Finding and removing empty files...")
    empty_files = find_and_remove_empty_files(search_paths)
    
    removed_files = 0
    for empty_file in empty_files:
        try:
            print(f"Removing empty file: {empty_file}")
            os.remove(empty_file)
            removed_files += 1
        except Exception as e:
            print(f"Could not remove {empty_file}: {e}")
    
    print()
    print("User-Agnostic Cleanup Summary:")
    print("==============================")
    print(f"Script files processed: {processed}")
    print(f"Files updated: {updated}")
    print(f"Empty files removed: {removed_files}")
    print()
    print("Changes made:")
    print("- Replaced ${USER}/${USER} with ${USER}")
    print("- Replaced @${COMPANY_DOMAIN} with ${USER_EMAIL}")
    print("- Replaced ${COMPANY_DOMAIN} with ${COMPANY_DOMAIN}")
    print("- Replaced ${COMPANY_NAME} with ${COMPANY_NAME}")
    print("- Added user configuration variables to script headers")
    print("- Removed empty and meaningless files")
    print()
    print("User variables available:")
    print("- USER: Current system username")
    print("- USER_EMAIL: User email address")
    print("- COMPANY_NAME: Company name")
    print("- COMPANY_DOMAIN: Company domain")
    print()
    print("Scripts are now user-agnostic and portable!")

if __name__ == "__main__":
    main()
