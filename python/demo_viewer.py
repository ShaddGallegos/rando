#!/usr/bin/env python3
"""
Demo script showing the new numeric menu system for data viewing
"""

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from business_tools.business_tools import BusinessToolsManager, print_success, print_status, CYAN, NC

def main():
    print(" Business Tools - Interactive Data Viewer Demo")
    print("=" * 50)
    print()
    
    print_status("Key Features of the Numeric Menu System:")
    print(f"  {CYAN}1-N{NC}: Sort by column number (1, 2, 3, etc.)")
    print(f"  {CYAN}s{NC}:   Search data by keyword")
    print(f"  {CYAN}a{NC}:   Show all rows (for large datasets)")
    print(f"  {CYAN}r{NC}:   Reset to original data")
    print(f"  {CYAN}e{NC}:   Export current filtered/sorted data")
    print(f"  {CYAN}q{NC}:   Quit viewer")
    print()
    
    print_status("How to use:")
    print("1. Run: python3 business_tools.py view sample_data.csv")
    print("2. You'll see a table with numbered columns")
    print("3. Type a column number (1-4) to sort by that column")
    print("4. Choose 1 for A-Z or 2 for Z-A sorting")
    print("5. Type 's' to search for specific keywords")
    print("6. Type 'q' when finished")
    print()
    
    print_status("Example workflow:")
    print("• Type '1' → Sort by Name column")
    print("• Type '2' → Choose A-Z or Z-A")
    print("• Type 's' → Search for 'Engineering'")
    print("• Type 'e' → Export filtered results")
    print("• Type 'q' → Exit viewer")
    print()
    
    print_success("✅ The numeric menu makes data manipulation much easier!")
    print("✅ You can now sort columns and search data like in a spreadsheet!")

if __name__ == "__main__":
    main()
