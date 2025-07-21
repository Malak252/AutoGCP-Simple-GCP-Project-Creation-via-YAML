#!/usr/bin/env python3
"""
deploy.py - Convert YAML configuration to Terraform variables and deploy infrastructure
"""

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

    # Initialize default structure
    terraform_vars = {
        "project_name": config.get("project_name", "unnamed-project"),
        "tags": config.get("tags", {}),
        "aws": {
            "enabled": False,
            "region": "us-east-1",
            "eks": {"enabled": False, "cluster_name": ""},
            "lambda": {"enabled": False, "functions": []},
            "s3": {"enabled": False, "buckets": []},
            "cloudwatch": {"enabled": False, "log_groups": []}
        },
        "gcp": {
            "enabled": False,
            "project_id": "",
            "region": "us-central1",
            "kubernetes": {"enabled": False, "cluster_name": ""},
            "cloud_function": {"enabled": False, "functions": []},
            "storage": {"enabled": False, "buckets": []},
            "monitoring": {"enabled": False, "alert_policies": []}
        }
    }

    # Process AWS configuration
    if "aws" in config:
        aws_config = config["aws"]
        terraform_vars["aws"]["enabled"] = aws_config.get("enabled", False)
        terraform_vars["aws"]["region"] = aws_config.get("region", "us-east-1")

        # EKS
        if "eks" in aws_config and aws_config["eks"].get("enabled", False):
            terraform_vars["aws"]["eks"] = aws_config["eks"]

        # Lambda
        if "lambda" in aws_config and aws_config["lambda"].get("enabled", False):
            terraform_vars["aws"]["lambda"] = aws_config["lambda"]

        # S3
        if "s3" in aws_config and aws_config["s3"].get("enabled", False):
            terraform_vars["aws"]["s3"] = aws_config["s3"]

        # CloudWatch
        if "cloudwatch" in aws_config and aws_config["cloudwatch"].get("enabled", False):
            terraform_vars["aws"]["cloudwatch"] = aws_config["cloudwatch"]

    # Process GCP configuration
    if "gcp" in config:
        gcp_config = config["gcp"]
        terraform_vars["gcp"]["enabled"] = gcp_config.get("enabled", False)
        terraform_vars["gcp"]["project_id"] = gcp_config.get("project_id", "")
        terraform_vars["gcp"]["region"] = gcp_config.get("region", "us-central1")

