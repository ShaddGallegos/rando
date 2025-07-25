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

import pandas as pd
import requests
from urllib.parse import urlparse
import os

# === CONFIGURATION ===
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

SOURCE_FILE = find_excel_file() or "business_tools_data.xlsx"
SHEET_NAME = None  # set to specific sheet name if needed
TEMP_CSV = "tools_temp.csv"
CLEANED_CSV = "Cleaned_Tools.csv"
SUMMARY_CSV = "Tools_Summary.csv"

# Check if source file exists
if not os.path.exists(SOURCE_FILE):
    print(f" Error: Source file '{SOURCE_FILE}' not found!")
    print(" Current directory contents:")
    for file in os.listdir('.'):
        if file.endswith(('.xlsx', '.xls', '.csv')):
            print(f"   - {file}")
    exit(1)

# === STEP 1: CONVERT XLSX TO CSV ===
try:
    if SHEET_NAME is None:
        # Read all sheets and use the first one, or combine if multiple
        xls_dict = pd.read_excel(SOURCE_FILE, sheet_name=None)
        if len(xls_dict) == 1:
            # Single sheet, use it
            xls = list(xls_dict.values())[0]
        else:
            # Multiple sheets, list them and use the first one
            sheet_names = list(xls_dict.keys())
            print(f" Found multiple sheets: {sheet_names}")
            print(f" Using first sheet: '{sheet_names[0]}'")
            xls = xls_dict[sheet_names[0]]
    else:
        # Read specific sheet
        xls = pd.read_excel(SOURCE_FILE, sheet_name=SHEET_NAME)
    
    xls.to_csv(TEMP_CSV, index=False)
    print(" Excel file converted to CSV.")
except Exception as e:
    print(" Failed to convert Excel file:", e)
    exit(1)

# === STEP 2: LOAD AND CLEAN ===
df = pd.read_csv(TEMP_CSV)

# Debug: Show original columns
print(" Original columns found:", list(df.columns))

# Fix column names
df.columns = [col.strip().title().replace(" ", "_") for col in df.columns]

# Debug: Show cleaned columns
print(" Cleaned columns:", list(df.columns))

# Check if required columns exist
required_cols = ['URL', 'Name', 'Synopsis', 'Tool_Type']
missing_cols = [col for col in required_cols if col not in df.columns]

if missing_cols:
    print(f" Missing required columns: {missing_cols}")
    print(" Available columns:", list(df.columns))
    print(" Please check the Excel file structure or update column names in the script.")
    # Try to map common variations
    column_mapping = {
        'Url': 'URL',  # Handle the lowercase 'url' case
        'Link': 'URL',
        'Links': 'URL', 
        'Web_Link': 'URL',
        'Tool_Name': 'Name',
        'Title': 'Name',
        'Description': 'Synopsis',
        'Type': 'Tool_Type',
        'Category': 'Tool_Type'
    }
    
    for old_name, new_name in column_mapping.items():
        if old_name in df.columns and new_name not in df.columns:
            df.rename(columns={old_name: new_name}, inplace=True)
            print(f" Mapped '{old_name}' → '{new_name}'")
    
    # Check again after mapping
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        print(f" Still missing columns after mapping: {missing_cols}")
        exit(1)

# Normalize types and fix known typos
if 'Tool_Type' in df.columns:
    fix_typos = {
        "colaboration": "Collaboration",
        "auth": "Authentication",
        "authentcation": "Authentication",
        "applcation": "Application",
        "informaton": "Information",
        "Demo Tool": "Demo",
        "Video Editing": "Media Tool"
    }
    df["Tool_Type"] = df["Tool_Type"].replace(fix_typos)

# Strip whitespace from URLs
if 'URL' in df.columns:
    df["URL"] = df["URL"].astype(str).str.strip()

# Check URL status
def check_url(url):
    try:
        response = requests.head(url, allow_redirects=True, timeout=6)
        if response.status_code == 200:
            return "OK"
        elif response.status_code == 403:
            return "Restricted"
        else:
            return f"Error {response.status_code}"
    except:
        return "Invalid"

if 'URL' in df.columns:
    print(" Validating URLs (this may take a minute)...")
    df["URL_Status"] = df["URL"].apply(check_url)
    
    # Filter only valid URLs
    df = df[df["URL_Status"] == "OK"]
    print(f" Found {len(df)} tools with valid URLs")
else:
    print(" No URL column found, skipping URL validation")

# === STEP 3: ENHANCE NAMES & DESCRIPTIONS ===
def enhance_name(name):
    name_map = {
        "Draw.io": "Draw.io – Web Diagramming Tool",
        "Doitlive": "Doitlive – Terminal Demo Simulator",
        "Skype": "Skype – Web-Based Video & Voice Communication",
        "Trello": "Trello – Visual Project Management Boards",
        "Lucidchart": "Lucidchart – Intelligent Diagramming Platform",
        "Jupyterlab": "JupyterLab – Interactive Data Science Environment"
    }
    return name_map.get(name, name)

def enhance_description(row):
    synopsis_col = 'Synopsis' if 'Synopsis' in df.columns else 'Description' if 'Description' in df.columns else None
    if synopsis_col is None:
        return "Tool description not available"
    
    synopsis = str(row[synopsis_col]).lower()
    if "diagram" in synopsis:
        return "Tool for creating flowcharts, architecture maps, and process diagrams."
    elif "learning" in synopsis or "labs" in synopsis:
        return "Interactive learning tools and environments for ${COMPANY_NAME} technologies."
    elif "authentic" in synopsis or "token" in synopsis:
        return "Authentication and identity tools for secure access control."
    elif "stream" in synopsis or "video" in synopsis:
        return "Utilities for recording, streaming, and multimedia editing."
    elif "terminal" in synopsis:
        return "CLI tools for sysadmin workflows and shell automation."
    elif "git" in synopsis:
        return "Repositories or tools for managing source code and collaboration."
    return row[synopsis_col] if synopsis_col in row else "Tool description not available"

if 'Name' in df.columns:
    df["Name"] = df["Name"].apply(enhance_name)
else:
    print(" No Name column found")

df["Enhanced_Synopsis"] = df.apply(enhance_description, axis=1)

# === STEP 4: CATEGORIZE ===
def categorize(row):
    desc = str(row["Enhanced_Synopsis"]).lower()
    if "authentication" in desc or "token" in desc:
        return "Security"
    elif "learning" in desc or "labs" in desc or "training" in desc:
        return "Education"
    elif "diagram" in desc:
        return "Diagramming"
    elif "stream" in desc or "video" in desc or "recording" in desc:
        return "Media Tools"
    elif "git" in desc or "repository" in desc:
        return "Code Repositories"
    elif "meeting" in desc or "conference" in desc:
        return "Meetings"
    elif "automation" in desc or "ansible" in desc:
        return "Automation"
    elif "terminal" in desc:
        return "CLI Utilities"
    return "General Utilities"

df["Category"] = df.apply(categorize, axis=1)

# === STEP 5: EXPORT RESULTS ===
df.to_csv(CLEANED_CSV, index=False)
summary = df["Category"].value_counts().reset_index()
summary.columns = ["Category", "Tool_Count"]
summary.to_csv(SUMMARY_CSV, index=False)

# Cleanup temp file
os.remove(TEMP_CSV)

print(f" Cleanup complete!\n- Saved cleaned tools to: {CLEANED_CSV}\n- Summary saved to: {SUMMARY_CSV}")
