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

import glob
from pathlib import Path


def find_excel_file():
    """Find the first Excel file in the current directory or data subdirectory"""
    # Check current directory first
    for ext in ['*.xlsx', '*.xls']:
        files = glob.glob(ext)
        if files:
            return files[0]
    
    # Check data subdirectory
    data_dir = Path('data')
    if data_dir.exists():
        for ext in ['*.xlsx', '*.xls']:
            files = list(data_dir.glob(ext))
            if files:
                return str(files[0])
    
    return None

"""
Comprehensive file cleaner - removes emojis, fixes paths, and makes filenames generic
"""

import os
import re
import shutil
import glob
from pathlib import Path
import datetime

def clean_text(text):
    """Remove emojis and special characters from text"""
    
    # Remove common emojis and special Unicode characters
    emoji_pattern = re.compile(
        "["
        "\U0001F600-\U0001F64F"  # emoticons
        "\U0001F300-\U0001F5FF"  # symbols & pictographs
        "\U0001F680-\U0001F6FF"  # transport & map symbols
        "\U0001F1E0-\U0001F1FF"  # flags (iOS)
        "\U00002700-\U000027BF"  # dingbats
        "\U0001f926-\U0001f937"
        "\U00010000-\U0010ffff"
        "\u2640-\u2642"
        "\u2600-\u2B55"
        "\u200d"
        "\u23cf"
        "\u23e9"
        "\u231a"
        "\ufe0f"  # dingbats
        "\u3030"
        "]+", flags=re.UNICODE)
    
    text = emoji_pattern.sub('', text)
    
    # Remove specific common symbols
    symbols_to_remove = ['', '', '', '', '', '', '', '', '', 
                        '', '', '', '', '', '', '', '', '',
                        '', '', '', '', '', '', '', '', '']
    
    for symbol in symbols_to_remove:
        text = text.replace(symbol, '')
    
    # Fix hard-coded paths
    text = re.sub(r'.', '.', text)
    text = re.sub(r'.', '.', text)
    text = re.sub(r'.', '.', text)
    
    # Make Excel filename generic
    text = re.sub(r'Red_Hat_Tools_For_SA_SSP_and_Managers\.xlsx', 'business_tools_data.xlsx', text)
    
    # Clean up echo statements with emojis
    text = re.sub(r'echo -e "\$\{[A-Z_]*\}.*\$\{NC\}"', 'echo', text)
    
    # Clean up print statements with emojis
    text = re.sub(r'print\(".*[].*"\)', 'print("")', text)
    
    return text

def find_excel_file_function():
    """Generate a function to find Excel files dynamically"""
    return '''
def find_excel_file():
    """Find the first Excel file in the current directory or data subdirectory"""
    # Check current directory first
    for ext in ['*.xlsx', '*.xls']:
        files = glob.glob(ext)
        if files:
            return files[0]
    
    # Check data subdirectory
    data_dir = Path('data')
    if data_dir.exists():
        for ext in ['*.xlsx', '*.xls']:
            files = list(data_dir.glob(ext))
            if files:
                return str(files[0])
    
    return None
'''

def clean_file(file_path):
    """Clean a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        cleaned_content = clean_text(content)
        
        # Add Excel file finder function to Python files
        if file_path.endswith('.py') and 'SOURCE_FILE' in content:
            # Add the function at the top after imports
            import_section = ''
            code_section = cleaned_content
            
            if 'import ' in cleaned_content:
                lines = cleaned_content.split('\n')
                import_end = 0
                for i, line in enumerate(lines):
                    if line.strip() and not line.startswith('#') and not line.startswith('import') and not line.startswith('from'):
                        import_end = i
                        break
                
                import_section = '\n'.join(lines[:import_end])
                code_section = '\n'.join(lines[import_end:])
            
            # Add missing imports if needed
            if 'import glob' not in import_section:
                import_section += '\nimport glob'
            if 'from pathlib import Path' not in import_section:
                import_section += '\nfrom pathlib import Path'
            
            # Add the function
            cleaned_content = import_section + '\n' + find_excel_file_function() + '\n' + code_section
            
            # Replace SOURCE_FILE assignment
            cleaned_content = re.sub(
                r'SOURCE_FILE = find_excel_file() or "business_tools_data.xlsx"]*"',
                'SOURCE_FILE = find_excel_file() or "business_tools_data.xlsx"',
                cleaned_content
            )
        
        # Only write if content changed
        if cleaned_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(cleaned_content)
            return True
        return False
    
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    print("Comprehensive Project Cleanup")
    print("============================")
    print("Removing emojis, hard-coded paths, and filename dependencies")
    print()
    
    # Create backup directory
    backup_dir = f"cleanup_backups_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}"
    os.makedirs(backup_dir, exist_ok=True)
    
    # Find all Python and shell script files
    script_files = []
    
    # Look in common locations
    search_paths = [
        '.',
        '.',
        '.'  # Current directory
    ]
    
    for search_path in search_paths:
        if os.path.exists(search_path):
            for pattern in ['**/*.py', '**/*.sh']:
                script_files.extend(glob.glob(os.path.join(search_path, pattern), recursive=True))
    
    # Remove duplicates
    script_files = list(set(script_files))
    
    print(f"Found {len(script_files)} script files to process")
    print()
    
    processed = 0
    changed = 0
    
    for file_path in script_files:
        # Skip backup directories and virtual environments
        if any(skip in file_path for skip in ['backup', 'venv', '__pycache__', '.git']):
            continue
        
        print(f"Processing: {file_path}")
        
        # Create backup
        backup_path = os.path.join(backup_dir, os.path.basename(file_path))
        try:
            shutil.copy2(file_path, backup_path)
        except:
            pass  # Continue even if backup fails
        
        # Clean the file
        if clean_file(file_path):
            changed += 1
            print(f"  Updated: {file_path}")
        else:
            print(f"  No changes: {file_path}")
        
        processed += 1
    
    print()
    print("Cleanup Summary:")
    print("===============")
    print(f"Files processed: {processed}")
    print(f"Files changed: {changed}")
    print(f"Backups created in: {backup_dir}")
    print()
    print("Changes made:")
    print("- Removed all emojis and special Unicode characters")
    print("- Converted hard-coded paths to relative paths")
    print("- Made Excel filename generic with auto-detection")
    print("- Added dynamic Excel file finder function")
    print("- Cleaned up console output formatting")
    print()
    print("Cleanup complete!")

if __name__ == "__main__":
    main()
