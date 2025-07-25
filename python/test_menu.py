#!/usr/bin/env python3
"""Test script to demonstrate the new numeric menu system"""

from business_tools.business_tools import BusinessToolsManager
import pandas as pd

# Create sample data
data = {
    'Name': ['Smith, John', 'Johnson, Mary', 'Brown, David', 'Wilson, Sarah'],
    'Department': ['Engineering', 'Marketing', 'Sales', 'Engineering'],
    'Position': ['Senior Developer', 'Marketing Manager', 'Sales Rep', 'Team Lead']
}

df = pd.DataFrame(data)

# Create manager and test data processor
manager = BusinessToolsManager()
processor = manager.data_processor

print("🚀 Testing the new numeric menu system:")
print("=" * 50)

# Display the table format
processor.display_data_table(df)

print("\n✅ Numeric menu test completed!")
print("Real usage: python3 business_tools.py view sample_data.csv")
