# 🔍 Red Hat Tools Browser

A comprehensive tool for searching, browsing, and managing Red Hat tools database with both GUI and CLI interfaces.

## 📋 Overview

This toolkit provides multiple ways to interact with a database of Red Hat tools and resources:

- **🖥️ GUI Version**: Full-featured graphical interface with search, filtering, and tool management
- **💻 CLI Version**: Command-line interface for terminal users
- **🔧 Data Processing**: Excel/CSV data cleaning and enhancement utilities

## 🚀 Quick Start

### Option 1: Use the Launcher
```bash
python3 tools_launcher.py
```

### Option 2: Direct Access
```bash
# GUI Version
python3 redhat_tools_browser.py

# CLI Version  
python3 redhat_tools_cli.py

# CLI with direct search
python3 redhat_tools_cli.py ansible automation
```

## 📁 Files Structure

```
├── polish_redhat_tools.py        # Data processing script
├── redhat_tools_browser.py       # GUI application
├── redhat_tools_cli.py           # CLI application  
├── tools_launcher.py             # Launcher script
├── Red_Hat_Tools_For_SA_SSP_and_Managers.xlsx  # Source data
├── Cleaned_Tools.csv             # Processed data
└── Tools_Summary.csv             # Category summary
```

## 🖥️ GUI Features

### **Main Interface**
- **Search Bar**: Real-time search across tool names, descriptions, types, and categories
- **Category Filter**: Filter tools by specific categories
- **Results Table**: Sortable table showing tool information
- **Details Panel**: Detailed view of selected tools
- **Statistics**: Live count of total and filtered tools

### **Tool Management**
- **➕ Add Tool**: Add new tools to the database
- **✏️ Edit Tool**: Modify existing tool information
- **🔍 URL Validation**: Verify tool URLs are accessible
- **🎲 Random Tool**: Discover tools randomly

### **Actions**
- **🌐 Open URL**: Launch tools in web browser
- **📋 Copy URL**: Copy tool URLs to clipboard
- **🔄 Refresh**: Reload data from CSV file

## 💻 CLI Features

### **Interactive Menu**
1. **🔎 Search Tools**: Search by keywords with optional category filtering
2. **📂 Browse by Category**: Explore tools organized by category
3. **🎲 Random Tool**: Show a random tool for discovery
4. **📊 Statistics**: Database statistics and summaries
5. **❓ Help**: Detailed help information

### **Direct Search Mode**
```bash
# Search for automation tools
python3 redhat_tools_cli.py automation

# Search for multiple terms
python3 redhat_tools_cli.py ansible playbook
```

## 📊 Categories

The tools are automatically categorized into:

- **🔒 Security**: Authentication, tokens, security tools
- **🎓 Education**: Learning resources, labs, training
- **📊 Diagramming**: Flowcharts, architecture tools
- **🎥 Media Tools**: Video, streaming, recording utilities
- **📂 Code Repositories**: Git repositories, development tools
- **📞 Meetings**: Conference and meeting tools
- **⚙️ Automation**: Ansible, automation platforms
- **💻 CLI Utilities**: Terminal and command-line tools
- **🛠️ General Utilities**: Miscellaneous tools

## 🔧 Data Processing

### Initial Setup
1. Place your Excel file: `Red_Hat_Tools_For_SA_SSP_and_Managers.xlsx`
2. Run the data processor:
   ```bash
   python3 polish_redhat_tools.py
   ```
3. This generates `Cleaned_Tools.csv` and `Tools_Summary.csv`

### Data Enhancement Features
- **URL Validation**: Checks if tool URLs are accessible
- **Category Classification**: Automatic categorization based on descriptions
- **Name Enhancement**: Improved tool names with descriptions
- **Description Standardization**: Enhanced and standardized descriptions
- **Typo Correction**: Fixes common typos in tool types

## 📝 Adding New Tools

### Via GUI
1. Click **"➕ Add Tool"** button
2. Fill in the form:
   - **Name**: Tool name
   - **Tool Type**: Type of tool (External/Internal/etc.)
   - **Category**: Select from dropdown
   - **URL**: Tool's web address
   - **Synopsis**: Description of the tool
3. Click **"🔍 Validate URL"** to check accessibility (optional)
4. Click **"💾 Save"** to add to database

### Via CLI/Direct CSV Edit
1. Open `Cleaned_Tools.csv` in a spreadsheet application
2. Add a new row with required columns:
   - Name, Tool_Type, Category, URL, Enhanced_Synopsis
3. Save the file
4. Refresh the GUI or restart CLI

### Via Excel Source
1. Edit the original Excel file: `Red_Hat_Tools_For_SA_SSP_and_Managers.xlsx`
2. Re-run the data processor: `python3 polish_redhat_tools.py`
3. Refresh the applications

## 🛠️ Technical Requirements

### Dependencies
```bash
pip install pandas requests tkinter openpyxl
```

### System Requirements
- Python 3.6+
- Tkinter (usually included with Python)
- Internet connection for URL validation
- Web browser for opening tool links

## 🎯 Usage Examples

### GUI Workflow
1. **Search**: Type "ansible" in search box
2. **Filter**: Select "Automation" category
3. **Select**: Double-click a tool to open its URL
4. **Add**: Click "➕ Add Tool" to contribute new tools

### CLI Workflow
```bash
# Interactive search
python3 redhat_tools_cli.py
# Choose option 1 (Search)
# Enter: "container"
# Select a tool from results
# Choose action (open URL, copy URL, etc.)

# Direct search
python3 redhat_tools_cli.py security
```

## 📈 Statistics & Analytics

The system provides insights into the tools database:

- **Total Tools**: Current count of tools in database
- **Categories Distribution**: Number of tools per category
- **Tool Types**: Breakdown by tool type (External, Internal, etc.)
- **URL Status**: Health check of tool accessibility

## 🔍 Search Tips

### Effective Search Strategies
- **Specific Keywords**: Use specific terms like "ansible", "openshift", "container"
- **Category Browse**: Explore by category when unsure what to search for
- **Random Discovery**: Use random tool feature to discover new resources
- **Combined Filters**: Use both text search and category filter together

### Search Scope
The search functionality covers:
- Tool names
- Descriptions and synopsis
- Tool types
- Categories
- All text content is case-insensitive

## 🛡️ Data Management

### Data Integrity
- **URL Validation**: Automatic checking of tool accessibility
- **Duplicate Prevention**: Check for existing tools before adding
- **Data Backup**: Original Excel file serves as backup
- **Version Control**: Track changes in CSV files

### Data Updates
- **Manual Updates**: Edit CSV directly for quick changes
- **Bulk Updates**: Use Excel file for major updates
- **Validation**: Re-run data processor to validate and clean data

## 🤝 Contributing

### Adding Tools
1. Verify the tool is relevant to Red Hat technologies
2. Ensure URL is accessible and correct
3. Provide clear, descriptive synopsis
4. Choose appropriate category and type
5. Test the tool entry in both GUI and CLI

### Improving Categories
- Suggest new categories for better organization
- Improve categorization logic in `polish_redhat_tools.py`
- Enhance description standardization rules

## 📞 Support

### Common Issues

**"Data file not found"**
- Run `python3 polish_redhat_tools.py` first
- Ensure Excel file exists in the same directory

**"GUI won't start"**
- Check if tkinter is installed: `python3 -c "import tkinter"`
- On Linux: `sudo apt-get install python3-tk`

**"URL validation fails"**
- Check internet connection
- Some URLs may have restrictions or rate limiting

### Troubleshooting
1. Verify all Python dependencies are installed
2. Check file permissions for CSV files
3. Ensure Excel file format is compatible
4. Test with a small dataset first

---

## 🎉 Features Summary

✅ **Dual Interface**: Both GUI and CLI options  
✅ **Real-time Search**: Instant results as you type  
✅ **Category Filtering**: Organized tool browsing  
✅ **URL Validation**: Check tool accessibility  
✅ **Tool Management**: Add, edit, and organize tools  
✅ **Data Processing**: Clean and enhance Excel data  
✅ **Random Discovery**: Find new tools randomly  
✅ **Statistics**: Database insights and analytics  
✅ **Export/Import**: CSV and Excel compatibility  
✅ **Cross-platform**: Works on Windows, macOS, Linux  

**Happy tool hunting! 🚀**
