#!/usr/bin/env python3
import json
import yaml 
import argparse 
import subprocess 
import sys
import os
from pathlib import Path

def load_yaml_config(config_path):
    """Load YAML configuration file"""
    try:
        with open(config_path, 'r') as file:
            return yaml.safe_load(file)
    except FileNotFoundError:
        print(f"❌ Configuration file not found: {config_path}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"❌ Error parsing YAML file: {e}")
        sys.exit(1)

def convert_to_terraform_vars(config):
    """Convert YAML config to Terraform variables format"""
    
    # Extract basic project info
    project_info = config.get("project", {})
    project_name = project_info.get("name", "unnamed-project")
    environment = project_info.get("environment", "dev")
    
    # Determine which cloud provider to use and services to deploy
    services = []
    cloud_provider = None
    
    # Check AWS configuration
    aws_config = config.get("aws", {})
    if aws_config.get("enabled", False):
        cloud_provider = "aws"
        if aws_config.get("eks", {}).get("enabled", False):
            services.append("kubernetes")
        if aws_config.get("lambda", {}).get("enabled", False):
            services.append("lambda")
        if aws_config.get("s3", {}).get("enabled", False):
            services.append("storage")
        if aws_config.get("cloudwatch", {}).get("enabled", False):
            services.append("monitoring")
    
    # Check GCP configuration
    gcp_config = config.get("gcp", {})
    if gcp_config.get("enabled", False):
        # If both are enabled, prefer the first one found or GCP
        if not cloud_provider:
            cloud_provider = "gcp"
        if gcp_config.get("kubernetes", {}).get("enabled", False):
            services.append("kubernetes")
        if gcp_config.get("cloud_function", {}).get("enabled", False):
            services.append("cloud_function")
        if gcp_config.get("storage", {}).get("enabled", False):
            services.append("storage")
        if gcp_config.get("monitoring", {}).get("enabled", False):
            services.append("monitoring")
    
    if not cloud_provider:
        print("❌ No cloud provider enabled in configuration")
        sys.exit(1)
    
    # Build terraform variables
    terraform_vars = {
        "cloud_provider": cloud_provider,
        "services": list(set(services)),  # Remove duplicates
        "environment": environment,
        "project_name": project_name,
        "labels": config.get("tags", {})
    }
    
    # Add AWS configuration if using AWS
    if cloud_provider == "aws" and aws_config:
        region = project_info.get("region", {}).get("aws", "us-west-2")
        
        aws_tf_config = {
            "region": region
        }
        
        # EKS configuration
        if aws_config.get("eks", {}).get("enabled", False):
            eks_data = aws_config["eks"]
            clusters = eks_data.get("clusters", [])
            if clusters:
                cluster = clusters[0]  # Use first cluster
                aws_tf_config["eks"] = {
                    "cluster_name": cluster.get("name", "default-cluster"),
                    "node_group_name": "default-workers",
                    "instance_types": cluster.get("node_groups", [{}])[0].get("instance_types", ["t3.medium"]),
                    "desired_capacity": cluster.get("node_groups", [{}])[0].get("desired_size", 2),
                    "max_capacity": cluster.get("node_groups", [{}])[0].get("max_size", 3),
                    "min_capacity": cluster.get("node_groups", [{}])[0].get("min_size", 1)
                }
        
        # Lambda configuration
        if aws_config.get("lambda", {}).get("enabled", False):
            lambda_data = aws_config["lambda"]
            functions = lambda_data.get("functions", [])
            if functions:
                func = functions[0]  # Use first function
                aws_tf_config["lambda"] = {
                    "function_name": func.get("name", "default-function"),
                    "runtime": func.get("runtime", "python3.9"),
                    "handler": func.get("handler", "main.handler"),
                    "source_file": func.get("filename", "function.zip")
                }
        
        # S3 configuration
        if aws_config.get("s3", {}).get("enabled", False):
            s3_data = aws_config["s3"]
            buckets = s3_data.get("buckets", [])
            if buckets:
                bucket = buckets[0]  # Use first bucket
                aws_tf_config["s3"] = {
                    "bucket_name": f"{project_name}-{bucket.get('name', 'default')}-{environment}"
                }
        
        # CloudWatch configuration
        if aws_config.get("cloudwatch", {}).get("enabled", False):
            cw_data = aws_config["cloudwatch"]
            log_groups = cw_data.get("log_groups", [])
            if log_groups:
                aws_tf_config["cloudwatch"] = {
                    "log_group": log_groups[0].get("name", f"/aws/lambda/{project_name}")
                }
        
        terraform_vars["aws_config"] = aws_tf_config
    
    # Add GCP configuration if using GCP
    if cloud_provider == "gcp" and gcp_config:
        region = project_info.get("region", {}).get("gcp", "us-central1")
        
        gcp_tf_config = {
            "project_id": gcp_config.get("project_id", ""),
            "region": region
        }
        
        # Kubernetes configuration
        if gcp_config.get("kubernetes", {}).get("enabled", False):
            k8s_data = gcp_config["kubernetes"]
            clusters = k8s_data.get("clusters", [])
            if clusters:
                cluster = clusters[0]  # Use first cluster
                gcp_tf_config["kubernetes"] = {
                    "cluster_name": cluster.get("name", "default-cluster"),
                    "node_count": cluster.get("initial_node_count", 1),
                    "machine_type": cluster.get("node_config", {}).get("machine_type", "e2-medium")
                }
        
        # Cloud Function configuration
        if gcp_config.get("cloud_function", {}).get("enabled", False):
            cf_data = gcp_config["cloud_function"]
            functions = cf_data.get("functions", [])
            if functions:
                func = functions[0]  # Use first function
                gcp_tf_config["cloud_function"] = {
                    "function_name": func.get("name", "default-function"),
                    "runtime": func.get("runtime", "python39"),
                    "entry_point": func.get("entry_point", "main"),
                    "source_archive": func.get("source_archive_object", "function-source.zip")
                }
        
        # Storage configuration
        if gcp_config.get("storage", {}).get("enabled", False):
            storage_data = gcp_config["storage"]
            buckets = storage_data.get("buckets", [])
            if buckets:
                bucket = buckets[0]  # Use first bucket
                gcp_tf_config["storage"] = {
                    "bucket_name": f"{project_name}-{bucket.get('name', 'default')}-{environment}",
                    "storage_class": "STANDARD"
                }
        
        # Monitoring configuration
        if gcp_config.get("monitoring", {}).get("enabled", False):
            gcp_tf_config["monitoring"] = {
                "notification_channel": "default-channel"
            }
        
        terraform_vars["gcp_config"] = gcp_tf_config
    
    return terraform_vars

def write_tfvars(terraform_vars, output_path="terraform.tfvars.json"):
    """Write terraform variables to JSON file"""
    try:
        with open(output_path, 'w') as f:
            json.dump(terraform_vars, f, indent=2)
        print(f"✅ Generated {output_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to write {output_path}: {e}")
        return False

def run_terraform_command(command, cwd=None):
    """Run terraform command and return success status"""
    try:
        print(f"🔄 Running: {command}")
        result = subprocess.run(command, shell=True, cwd=cwd, capture_output=True, text=True)
        
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
            
        return result.returncode == 0
    except Exception as e:
        print(f"❌ Error running command: {e}")
        return False

def deploy(config_path, workspace=None, auto_approve=False):
    """Main deployment function"""
    print(f"🚀 Starting deployment...")
    print(f"📋 Config: {config_path}")
    
    # Load and convert configuration
    config = load_yaml_config(config_path)
    terraform_vars = convert_to_terraform_vars(config)
    
    # Use environment from config as default workspace
    if not workspace:
        workspace = terraform_vars.get("environment", "dev")
    
    print(f"🏗️  Cloud Provider: {terraform_vars['cloud_provider']}")
    print(f"📦 Services: {', '.join(terraform_vars['services'])}")
    print(f"🌍 Workspace: {workspace}")
    
    # Write terraform variables
    if not write_tfvars(terraform_vars):
        return False
    
    # Change to terraform directory (assuming script is in terraform/ subdirectory)
    terraform_dir = Path(__file__).parent.parent
    os.chdir(terraform_dir)
    
    # Initialize terraform
    if not run_terraform_command("terraform init"):
        print("❌ Terraform initialization failed")
        return False
    
    # Create/select workspace
    if workspace != "default":
        # Try to create workspace (will fail if exists, that's ok)
        run_terraform_command(f"terraform workspace new {workspace}")
        # Select workspace
        if not run_terraform_command(f"terraform workspace select {workspace}"):
            print(f"❌ Failed to select workspace: {workspace}")
            return False
    
    # Validate configuration
    if not run_terraform_command("terraform validate"):
        print("❌ Terraform validation failed")
        return False
    
    # Plan deployment
    print("📋 Creating deployment plan...")
    if not run_terraform_command("terraform plan -out=tfplan"):
        print("❌ Terraform planning failed")
        return False
    
    # Apply deployment
    if auto_approve:
        apply_cmd = "terraform apply tfplan"
    else:
        apply_cmd = "terraform apply tfplan"
        print("🔍 Review the plan above. Press Ctrl+C to cancel or Enter to continue...")
        try:
            input()
        except KeyboardInterrupt:
            print("\n❌ Deployment cancelled by user")
            return False
    
    print("🔨 Applying deployment...")
    if run_terraform_command(apply_cmd):
        print("✅ Deployment completed successfully!")
        
        # Show outputs
        print("\n📊 Deployment Outputs:")
        run_terraform_command("terraform output")
        return True
    else:
        print("❌ Deployment failed!")
        return False

def show_help():
    """Show usage information"""
    print("Usage: python deploy.py <config_path> [workspace] [--auto-approve]")
    print()
    print("Examples:")
    print("  python deploy.py example-project.yaml")
    print("  python deploy.py my-config.yaml production")
    print("  python deploy.py my-config.yaml dev --auto-approve")
    print()
    print("Arguments:")
    print("  config_path    Path to YAML configuration file")
    print("  workspace      Terraform workspace (defaults to environment from config)")
    print("  --auto-approve Skip confirmation prompts")

# CLI
if __name__ == "__main__":
    if len(sys.argv) < 2:
        show_help()
        sys.exit(1)
    
    config_path = sys.argv[1]
    workspace = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    auto_approve = "--auto-approve" in sys.argv
    
    try:
        success = deploy(config_path, workspace, auto_approve)
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n❌ Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)
