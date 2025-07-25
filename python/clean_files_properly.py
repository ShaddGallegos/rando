#!/usr/bin/env python3
import os
import re
import glob

def clean_file_content(content):
    # Remove emojis using regex patterns
    emoji_patterns = [
        r'[🎉🚀📁📊🎯✅❌⚠️🔍🧹📋🔄🎊💻🖥️🚪👋💾🔧🎨📖🏁📦🔒📞🌟💡🛠️🏢📄🔗]',
        r'[📌📍🔴🟢🟡⚪⚫🔵🟣🟠🟤]',
        r'[▶️⏸️⏹️⏭️⏮️🔄🔁🔀]',
        r'[⬆️⬇️⬅️➡️↗️↘️↙️↖️]'
    ]
    
    for pattern in emoji_patterns:
        content = re.sub(pattern, '', content)
    
    # Remove hard-coded paths
    content = content.replace('/home/sgallego/Downloads/GIT/rando/BusinessToolsBrowser', '.')
    content = content.replace('/home/sgallego/Downloads/GIT/BusinessToolsBrowser', '.')
    content = content.replace('/home/sgallego/Downloads/GIT/rando/python/BusinessTools', '.')
    
    # Replace specific filename
    content = content.replace('Red_Hat_Tools_For_SA_SSP_and_Managers.xlsx', '*.xlsx')
    
    # Clean up extra spaces
    content = re.sub(r'  +', ' ', content)
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)
    
    return content

# Process files
for pattern in ['*.py', '*.sh', '*.md']:
    for filepath in glob.glob(pattern):
        if filepath.endswith('.backup'):
            continue
        print(f"Processing: {filepath}")
        try:
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            cleaned = clean_file_content(content)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f"  Cleaned: {filepath}")
        except Exception as e:
            print(f"  Error: {e}")

# Process subdirectories
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith(('.py', '.sh', '.md')) and not file.endswith('.backup'):
            filepath = os.path.join(root, file)
            if not filepath.startswith('./'):
                continue
            print(f"Processing: {filepath}")
            try:
                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                cleaned = clean_file_content(content)
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(cleaned)
                print(f"  Cleaned: {filepath}")
            except Exception as e:
                print(f"  Error: {e}")

print("Cleanup complete!")
