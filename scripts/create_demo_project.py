#!/usr/bin/env python3
"""
Azure DevOps Demo Project Creator
Creates a comprehensive demo project with Epics, Features, PBIs, Tasks, Tests, and Bugs
with proper relationships between work items.
"""

import requests
import base64
import json
from datetime import datetime, timedelta
import sys

# Configuration
ORGANIZATION = "hygieia-devops"
PROJECT = "DevOps-Turkiye"
TEAM = "DevOps-Turkiye Team"
BASE_URL = f"https://dev.azure.com/{ORGANIZATION}/{PROJECT}"
API_VERSION = "7.0"
TOKEN = "AI9TJm5RCCifo7r0YeyoMAHZuXxuUS6vAQxQyVpRsklnr5C9wSx0JQQJ99BLACAAAAAAAAAAAAASAZDO1YxI"

def get_auth_header():
    """Create Basic Auth header with PAT token"""
    credentials = f":{TOKEN}"
    encoded = base64.b64encode(credentials.encode()).decode()
    return {"Authorization": f"Basic {encoded}"}

def get_headers():
    """Get request headers"""
    headers = get_auth_header()
    headers["Content-Type"] = "application/json-patch+json"
    return headers

def create_work_item(wi_type, title, description, fields=None, relations=None):
    """Create a work item"""
    url = f"{BASE_URL}/_apis/wit/workitems/${wi_type}?api-version={API_VERSION}"
    
    patch_document = []
    
    # Title
    patch_document.append({
        "op": "add",
        "path": "/fields/System.Title",
        "value": title
    })
    
    # Description
    if description:
        patch_document.append({
            "op": "add",
            "path": "/fields/System.Description",
            "value": description
        })
    
    # Additional fields
    if fields:
        for field_path, field_value in fields.items():
            patch_document.append({
                "op": "add",
                "path": f"/fields/{field_path}",
                "value": field_value
            })
    
    # Relations (parent, child, related)
    if relations:
        for relation in relations:
            patch_document.append({
                "op": "add",
                "path": "/relations/-",
                "value": relation
            })
    
    try:
        response = requests.patch(url, headers=get_headers(), json=patch_document)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error creating work item '{title}': {e}")
        if hasattr(e.response, 'text'):
            print(f"Response: {e.response.text}")
        return None

def create_relation(target_id, relation_type="System.Links.Related"):
    """Create a relation object"""
    return {
        "rel": relation_type,
        "url": f"{BASE_URL}/_apis/wit/workitems/{target_id}"
    }

def create_parent_relation(target_id):
    """Create a parent relation"""
    return create_relation(target_id, "System.Links.Hierarchy-Forward")

def create_child_relation(target_id):
    """Create a child relation"""
    return create_relation(target_id, "System.Links.Hierarchy-Reverse")

def main():
    print("🚀 Azure DevOps Demo Project Creator")
    print(f"Organization: {ORGANIZATION}")
    print(f"Project: {PROJECT}")
    print(f"Team: {TEAM}")
    print()
    
    created_items = {}
    
    # 1. Create Epic 1: Mobile App Development
    print("📦 Creating Epic 1: Mobile App Development...")
    epic1 = create_work_item(
        "Epic",
        "Mobile Application Development Platform",
        "Complete mobile application development platform for Azure DevOps integration",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        }
    )
    if epic1:
        epic1_id = epic1["id"]
        created_items["epic1"] = epic1_id
        print(f"   ✅ Created Epic: {epic1_id}")
    
    # 2. Create Epic 2: CI/CD Pipeline
    print("📦 Creating Epic 2: CI/CD Pipeline...")
    epic2 = create_work_item(
        "Epic",
        "CI/CD Pipeline Implementation",
        "Implement comprehensive CI/CD pipeline for automated builds and deployments",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        }
    )
    if epic2:
        epic2_id = epic2["id"]
        created_items["epic2"] = epic2_id
        print(f"   ✅ Created Epic: {epic2_id}")
    
    # 3. Create Feature 1: User Authentication
    print("🔧 Creating Feature 1: User Authentication...")
    feature1 = create_work_item(
        "Feature",
        "User Authentication & Authorization",
        "Implement secure user authentication with PAT and AD authentication support",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        },
        [create_parent_relation(epic1_id)] if epic1 else None
    )
    if feature1:
        feature1_id = feature1["id"]
        created_items["feature1"] = feature1_id
        print(f"   ✅ Created Feature: {feature1_id}")
    
    # 4. Create Feature 2: Work Item Management
    print("🔧 Creating Feature 2: Work Item Management...")
    feature2 = create_work_item(
        "Feature",
        "Work Item Management",
        "Complete work item management system with CRUD operations",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        },
        [create_parent_relation(epic1_id)] if epic1 else None
    )
    if feature2:
        feature2_id = feature2["id"]
        created_items["feature2"] = feature2_id
        print(f"   ✅ Created Feature: {feature2_id}")
    
    # 5. Create Feature 3: Build Automation
    print("🔧 Creating Feature 3: Build Automation...")
    feature3 = create_work_item(
        "Feature",
        "Build Automation Pipeline",
        "Automated build pipeline with Android and iOS support",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        },
        [create_parent_relation(epic2_id)] if epic2 else None
    )
    if feature3:
        feature3_id = feature3["id"]
        created_items["feature3"] = feature3_id
        print(f"   ✅ Created Feature: {feature3_id}")
    
    # 6. Create PBI 1: Login Screen
    print("📋 Creating PBI 1: Login Screen...")
    pbi1 = create_work_item(
        "Product Backlog Item",
        "Login Screen Implementation",
        "Design and implement login screen with PAT and AD authentication options",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}",
            "Microsoft.VSTS.Common.Priority": "1",
            "Microsoft.VSTS.Common.StoryPoints": "5"
        },
        [create_parent_relation(feature1_id)] if feature1 else None
    )
    if pbi1:
        pbi1_id = pbi1["id"]
        created_items["pbi1"] = pbi1_id
        print(f"   ✅ Created PBI: {pbi1_id}")
    
    # 7. Create PBI 2: Work Item List
    print("📋 Creating PBI 2: Work Item List...")
    pbi2 = create_work_item(
        "Product Backlog Item",
        "Work Item List View",
        "Implement work item list view with filtering and sorting capabilities",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}",
            "Microsoft.VSTS.Common.Priority": "1",
            "Microsoft.VSTS.Common.StoryPoints": "8"
        },
        [create_parent_relation(feature2_id)] if feature2 else None
    )
    if pbi2:
        pbi2_id = pbi2["id"]
        created_items["pbi2"] = pbi2_id
        print(f"   ✅ Created PBI: {pbi2_id}")
    
    # 8. Create Tasks for PBI 1
    print("📝 Creating Tasks for Login Screen...")
    task1 = create_work_item(
        "Task",
        "Design Login UI",
        "Create UI mockups and design for login screen",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}",
            "Microsoft.VSTS.Common.Activity": "Design"
        },
        [create_parent_relation(pbi1_id)] if pbi1 else None
    )
    if task1:
        created_items["task1"] = task1["id"]
        print(f"   ✅ Created Task: {task1['id']}")
    
    task2 = create_work_item(
        "Task",
        "Implement PAT Authentication",
        "Implement Personal Access Token authentication flow",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}",
            "Microsoft.VSTS.Common.Activity": "Development"
        },
        [create_parent_relation(pbi1_id)] if pbi1 else None
    )
    if task2:
        created_items["task2"] = task2["id"]
        print(f"   ✅ Created Task: {task2['id']}")
    
    # 9. Create Test Case 1
    print("🧪 Creating Test Case 1...")
    test1 = create_work_item(
        "Test Case",
        "Login Screen Test: Valid PAT",
        "Test login with valid Personal Access Token",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}"
        },
        [create_relation(pbi1_id, "Microsoft.VSTS.Common.TestedBy-Forward")] if pbi1 else None
    )
    if test1:
        created_items["test1"] = test1["id"]
        print(f"   ✅ Created Test Case: {test1['id']}")
    
    # 10. Create Bug 1
    print("🐛 Creating Bug 1...")
    bug1 = create_work_item(
        "Bug",
        "Login screen crashes on invalid token",
        "Application crashes when user enters invalid token format",
        {
            "System.AreaPath": f"{PROJECT}\\{TEAM}",
            "System.IterationPath": f"{PROJECT}\\{TEAM}",
            "Microsoft.VSTS.Common.Severity": "2 - High",
            "Microsoft.VSTS.Common.Priority": "1"
        },
        [create_relation(pbi1_id)] if pbi1 else None
    )
    if bug1:
        created_items["bug1"] = bug1["id"]
        print(f"   ✅ Created Bug: {bug1['id']}")
    
    print()
    print("✅ Demo project creation completed!")
    print(f"Created {len(created_items)} work items")
    print()
    print("📊 Created Work Items Summary:")
    for key, item_id in created_items.items():
        print(f"   {key}: {item_id}")
    
    print()
    print(f"🔗 View in Azure DevOps: {BASE_URL}/_workitems")

if __name__ == "__main__":
    main()
