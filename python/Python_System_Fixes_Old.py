#!/usr/bin/env python3

"""
Script: Python_System_Fixes.py
Purpose: Analyze and fix system issues from JSON insights data
Author: System Administrator
Date: 2025-07-18
"""

import json
import sys
from datetime import datetime, timedelta

def analyze_system_issues(data):
    """
    Analyze system issues from insights data
    
    Args:
        data (dict): JSON data containing system insights
        
    Returns:
        dict: Analysis results with recommendations
    """
    results = {
        "critical_issues": [],
        "warnings": [],
        "recommendations": [],
        "summary": {}
    }
    
    print(" Analyzing system issues from insights data...")
    
    if not isinstance(data, dict) or "details" not in data:
        results["critical_issues"].append("Invalid data format - missing 'details' key")
        return results
    
    details = data.get("details", {})
    
    # Analyze each issue
    for issue_key, issue_data in details.items():
        issue_type = issue_data.get("type", "unknown")
        error_key = issue_data.get("error_key", "")
        
        print(f" Processing issue: {issue_key}")
        
        # Handle specific issues
        if "ANSIBLE_ENGINE_TO_CORE_WARN" in error_key:
            results["warnings"].append({
                "issue": "Ansible Engine to Core Warning",
                "description": "Ansible Engine is deprecated, migrate to Ansible Core",
                "current_version": issue_data.get("ansible_ver", "unknown"),
                "rhel_version": issue_data.get("rhel_version", "unknown"),
                "recommendation": "Update to ansible-core package"
            })
            
        elif "TUNED_SERVICE_CANNOT_START_UNDER_GRAPHIC_TARGET_MODE" in error_key:
            results["critical_issues"].append({
                "issue": "Tuned Service Failed",
                "description": "Tuned service cannot start in graphical mode",
                "rhel_version": issue_data.get("rhel", "unknown"),
                "recommendation": "Check tuned service configuration and dependencies"
            })
            
        elif "JDK_EOL_ERROR" in error_key:
            if "product" in issue_data:
                for product in issue_data["product"]:
                    eol_date = product.get("eol", "")
                    days_left = product.get("days", 0)
                    
                    if days_left < 90:  # Less than 90 days
                        results["critical_issues"].append({
                            "issue": "Java EOL Warning",
                            "description": f"Java version approaching EOL in {days_left} days",
                            "eol_date": eol_date,
                            "product_name": product.get("name", "unknown"),
                            "recommendation": "Plan Java version upgrade"
                        })
                    else:
                        results["warnings"].append({
                            "issue": "Java EOL Notice",
                            "description": f"Java version will reach EOL in {days_left} days",
                            "eol_date": eol_date,
                            "product_name": product.get("name", "unknown"),
                            "recommendation": "Monitor and plan for upgrade"
                        })
    
    # Generate summary
    results["summary"] = {
        "total_issues": len(details),
        "critical_count": len(results["critical_issues"]),
        "warning_count": len(results["warnings"]),
        "analysis_date": datetime.now().isoformat()
    }
    
    return results

def generate_fix_commands(results):
    """
    Generate shell commands to fix identified issues
    
    Args:
        results (dict): Analysis results
        
    Returns:
        list: List of shell commands to execute
    """
    commands = []
    
    print("\n Generating fix commands...")
    
    # Generate commands for each issue
    for issue in results["critical_issues"]:
        if "Ansible Engine to Core" in issue["issue"]:
            commands.append("# Fix Ansible Engine to Core issue")
            commands.append("sudo dnf remove ansible")
            commands.append("sudo dnf install ansible-core")
            commands.append("ansible-galaxy collection install ansible.posix")
            
        elif "Tuned Service Failed" in issue["issue"]:
            commands.append("# Fix Tuned service issue")
            commands.append("sudo systemctl status tuned")
            commands.append("sudo systemctl restart tuned")
            commands.append("sudo systemctl enable tuned")
            
        elif "Java EOL Warning" in issue["issue"]:
            commands.append("# Address Java EOL issue")
            commands.append("java -version")
            commands.append("sudo dnf list installed | grep java")
            commands.append("sudo dnf install java-11-openjdk java-11-openjdk-devel")
    
    return commands

def main():
    """Main function to run the system fixes analysis"""
    print(" Python System Fixes - Red Hat Insights Analysis")
    print("=" * 50)
    
    # Sample input JSON data
    sample_data = {
        "id": "af935949-db8d-4b5a-ab99-6ec39f2ecb01",
        "insights_id": "93a83f9a-5781-4270-aee5-1ca8dc00760e",
        "details": {
            "ansible_engine_to_core|ANSIBLE_ENGINE_TO_CORE_WARN": {
                "type": "rule",
                "error_key": "ANSIBLE_ENGINE_TO_CORE_WARN",
                "ansible_ver": "ansible-7.7.0-1.el9",
                "rhel_version": "9.6"
            },
            "tuned_failed_to_start_in_graphical_mode|TUNED_SERVICE_CANNOT_START_UNDER_GRAPHIC_TARGET_MODE": {
                "rhel": "9.6",
                "type": "rule",
                "error_key": "TUNED_SERVICE_CANNOT_START_UNDER_GRAPHIC_TARGET_MODE"
            },
            "openjdk_eol|JDK_EOL_ERROR": {
                "type": "rule",
                "brief": {
                    "Red Hat build of OpenJDK": "https://access.redhat.com/articles/1299013"
                },
                "product": [
                    {
                        "eol": "2024-10-31",
                        "days": 251,
                        "name": "Red Hat build of OpenJDK",
                        "phase": "Full Support",
                    "policy": "https://access.redhat.com/articles/1299013",
                    "version": "11"
                }
            ],
            "error_key": "JDK_EOL_ERROR"
        }
    }
}

# Fix suggestions
def suggest_fixes(details):
    for key, issue in details.items():
        print(f"\n Issue: {key}")
        error_key = issue.get("error_key", "Unknown")

        if error_key == "ANSIBLE_ENGINE_TO_CORE_WARN":
            print(" Ansible Engine is deprecated in favor of Ansible Core.")
            print(f" Installed version: {issue['ansible_ver']}")
            print(" Suggested Fix: Migrate to Ansible Core. See: https://docs.ansible.com/ansible/latest/reference_appendices/release_and_maintenance.html")

        elif error_key == "TUNED_SERVICE_CANNOT_START_UNDER_GRAPHIC_TARGET_MODE":
            print(" Tuned service cannot start under graphical.target.")
            print(" Suggested Fix: Change the system target to multi-user.target or configure tuned to run in graphical mode if needed.")
            print(" Command: `sudo systemctl set-default multi-user.target`")

        elif error_key == "JDK_EOL_ERROR":
            product = issue.get("product", [])[0]
            eol_date = product.get("eol")
            days_left = product.get("days")
            print(f" {product['name']} version {product['version']} is nearing end-of-life.")
            print(f" EOL Date: {eol_date} ({days_left} days left)")
            print(f" Suggested Fix: Upgrade to a supported JDK version. Policy: {product['policy']}")

        else:
            print("ℹ No specific fix available for this issue.")

# Run the suggestions
suggest_fixes(data["details"])

