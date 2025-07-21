#!/usr/bin/env python3
import json
import os
import sys
import subprocess
from pathlib import Path

def run_command(command, cwd=None):
    """run command and return success status"""
    try:
        result = subprocess.run(command, shell=True, cwd=cwd, capture_output=True, text=True)
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        return result.returncode == 0
    except Exception as e:
        print(f"error running command: {e}", file=sys.stderr)
        return False

def check_workspace_exists(workspace):
    """check if workspace exists"""
    result = subprocess.run("terraform workspace list", shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        return False
    return workspace in result.stdout or (workspace == "default" and "default" in result.stdout)

def get_resource_count():
    """get number of resources in state"""
    result = subprocess.run("terraform state list", shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        return 0
    return len([line for line in result.stdout.split('\n') if line.strip()])

def confirm(prompt="are you sure you want to destroy the infrastructure? (yes/no): "):
    """get user confirmation with enhanced safety"""
    ans = input(prompt).lower().strip()
    return ans in ['yes', 'y']

def confirm_production(workspace):
    """extra confirmation for production environments"""
    if workspace.lower() in ['prod', 'production']:
        print(f"\nwarning: You're about to destroy PRODUCTION environment!")
        print(f"Workspace: {workspace}")
        
        prod_confirm = input("type 'destroy-production' to confirm: ").strip()
        return prod_confirm == "destroy-production"
    return True

def destroy(config_path, workspace):
    """simplified destroy function with essential safety checks"""
    terraform_dir = Path(__file__).parent.parent
    
    print(f"starting destruction process...")
    print(f"Config: {config_path}")
    print(f"Workspace: {workspace}")
    
    # Change to terraform directory
    os.chdir(terraform_dir)
    
    # Check if terraform is initialized
    if not Path(".terraform").exists():
        print("terraform not initialized. Run 'terraform init' first.")
        return False
    
    # Check workspace exists
    if not check_workspace_exists(workspace):
        print(f"workspace '{workspace}' does not exist")
        return False
    
    # Switch to workspace
    if workspace != "default":
        if not run_command(f"terraform workspace select {workspace}"):
            print(f"failed to switch to workspace: {workspace}")
            return False
    
    # Check if there are resources to destroy
    resource_count = get_resource_count()
    if resource_count == 0:
        print("no resources found. Nothing to destroy.")
        return True
    
    print(f"found {resource_count} resources to destroy")
    
    # Show plan
    print("planning destruction...")
    if not run_command("terraform plan -destroy"):
        print("failed to create destruction plan")
        return False
    
    # Get confirmations
    if not confirm(f"\ndestroy {resource_count} resources in '{workspace}' workspace? (yes/no): "):
        print("destroy aborted.")
        return False
    
    if not confirm_production(workspace):
        print("production destroy aborted.")
        return False
    
    # Execute destruction
    print("destroying infrastructure...")
    if run_command("terraform destroy -auto-approve"):
        print(:"infrastructure destroyed successfully!")
        return True
    else:
        print("❌ Destruction failed!")
        return False

def show_help():
    """Show usage information"""
    print("Usage: python destroy.py <config_path> <workspace>")
    print()
    print("Examples:")
    print("  python destroy.py example-project.yaml dev")
    print("  python destroy.py my-config.yaml production")
    print()
    print("Safety features:")
    print("  - Workspace validation")
    print("  - Resource count check")
    print("  - Destruction plan preview")
    print("  - Production environment extra confirmation")

# CLI
if __name__ == "__main__":
    if len(sys.argv) < 3:
        show_help()
        sys.exit(1)
    
    config_path = sys.argv[1]
    workspace = sys.argv[2]
    
    try:
        success = destroy(config_path, workspace)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("interrupted by user")
        sys.exit(1)
    except Exception as e:
        print("uUnexpected error: {e}")
        sys.exit(1)
