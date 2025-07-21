import yaml
import json
import subprocess
import sys
import os
import argparse
import shutil
from pathlib import Path
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from enum import Enum

class ModuleType(Enum):
    LOCAL = "local"
    REGISTRY = "registry"
    GIT = "git"
    HTTP = "http"

@dataclass
class ModuleConfig:
    name: str
    enabled: bool = True
    source: str = ""
    version: Optional[str] = None
    module_type: ModuleType = ModuleType.LOCAL
    depends_on: List[str] = field(default_factory=list)
    variables: Dict[str, Any] = field(default_factory=dict)
    outputs: List[str] = field(default_factory=list)

@dataclass
class TerraformConfig:
    terraform_version: str = ">= 1.0"
    required_providers: Dict[str, Dict[str, str]] = field(default_factory=dict)
    backend: Optional[Dict[str, Any]] = None

class EnhancedTerraformAutomator:
    def __init__(self, config_file: str, terraform_dir: str = ".", template_dir: str = "templates", preserve_tfvars: bool = True):
        self.config_file = config_file
        self.terraform_dir = Path(terraform_dir)
        self.template_dir = Path(template_dir)
        self.generated_dir = self.terraform_dir / "generated"
        self.tfvars_file = self.terraform_dir / "terraform.tfvars"
        self.preserve_tfvars = preserve_tfvars
        
        self.generated_dir.mkdir(parents=True, exist_ok=True)
        
        self.config = {}
        self.modules = {}
        self.terraform_config = TerraformConfig()
        
    def read_yaml_config(self) -> Dict[str, Any]:
        try:
            with open(self.config_file, 'r') as file:
                config = yaml.safe_load(file)
                print(f"✓ Successfully loaded configuration from {self.config_file}")
                return config
        except FileNotFoundError:
            print(f"❌ Error: Configuration file '{self.config_file}' not found")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"❌ Error parsing YAML file: {e}")
            sys.exit(1)
    
    def parse_module_configs(self, config: Dict[str, Any]) -> Dict[str, ModuleConfig]:
        modules = {}
        
        if 'modules' not in config:
            print("⚠️  No modules configuration found in YAML")
            return modules
        
        for module_name, module_data in config['modules'].items():
            if not isinstance(module_data, dict):
                continue
                
            source = module_data.get('source', '')
            
            if source.startswith('./') or source.startswith('../'):
                module_type = ModuleType.LOCAL
                if source.startswith('./'):
                    source = '../' + source[2:]
                elif source.startswith('../'):
                    source = '../' + source
            elif source.startswith('git::'):
                module_type = ModuleType.GIT
            elif source.startswith('http'):
                module_type = ModuleType.HTTP
            else:
                module_type = ModuleType.REGISTRY
            
            module_config = ModuleConfig(
                name=module_name,
                enabled=module_data.get('enabled', True),
                source=source,
                version=module_data.get('version'),
                module_type=module_type,
                depends_on=module_data.get('depends_on', []),
                variables=module_data.get('variables', {}),
                outputs=module_data.get('outputs', [])
            )
            
            modules[module_name] = module_config
        
        print(f"✓ Parsed {len(modules)} module configurations")
        return modules
    
    def parse_terraform_config(self, config: Dict[str, Any]) -> TerraformConfig:
        terraform_config = TerraformConfig()
        
        if 'terraform' in config:
            tf_config = config['terraform']
            terraform_config.terraform_version = tf_config.get('version', ">= 1.0")
            terraform_config.required_providers = tf_config.get('required_providers', {})
            terraform_config.backend = tf_config.get('backend')
        
        return terraform_config
    
    def validate_module_dependencies(self, modules: Dict[str, ModuleConfig]) -> List[str]:
        enabled_modules = {name: config for name, config in modules.items() if config.enabled}
        ordered_modules = []
        processed = set()
        
        def process_module(module_name: str, visiting: set = None):
            if visiting is None:
                visiting = set()
            
            if module_name in visiting:
                raise ValueError(f"Circular dependency detected involving module: {module_name}")
            
            if module_name in processed:
                return
            
            if module_name not in enabled_modules:
                raise ValueError(f"Module '{module_name}' is referenced but not enabled")
            
            visiting.add(module_name)
            
            for dep in enabled_modules[module_name].depends_on:
                process_module(dep, visiting)
            
            visiting.remove(module_name)
            processed.add(module_name)
            ordered_modules.append(module_name)
        
        for module_name in enabled_modules:
            process_module(module_name)
        
        print(f"✓ Validated module dependencies. Order: {' → '.join(ordered_modules)}")
        return ordered_modules
    
    def generate_terraform_config(self) -> str:
        config_lines = [
            "terraform {",
            f'  required_version = "{self.terraform_config.terraform_version}"'
        ]
        
        if self.terraform_config.required_providers:
            config_lines.append("  required_providers {")
            for provider, config in self.terraform_config.required_providers.items():
                config_lines.append(f"    {provider} = {{")
                for key, value in config.items():
                    config_lines.append(f'      {key} = "{value}"')
                config_lines.append("    }")
            config_lines.append("  }")
        
        if self.terraform_config.backend:
            backend_type = self.terraform_config.backend.get('type', 'local')
            config_lines.append(f"  backend \"{backend_type}\" {{")
            for key, value in self.terraform_config.backend.items():
                if key != 'type':
                    if isinstance(value, str):
                        config_lines.append(f'    {key} = "{value}"')
                    else:
                        config_lines.append(f'    {key} = {str(value).lower()}')
            config_lines.append("  }")
        
        config_lines.append("}")
        return "\n".join(config_lines)
    
    def generate_provider_config(self) -> str:
        providers = []
        
        for provider, config in self.terraform_config.required_providers.items():
            provider_lines = [f"provider \"{provider}\" {{"]
            
            if f"{provider}_config" in self.config:
                provider_config = self.config[f"{provider}_config"]
                for key, value in provider_config.items():
                    if isinstance(value, str):
                        if value.startswith('var.'):
                            provider_lines.append(f'  {key} = {value}')
                        else:
                            provider_lines.append(f'  {key} = "{value}"')
                    else:
                        provider_lines.append(f'  {key} = {str(value).lower()}')
            
            if provider == "google":
                if "project" not in [line.split('=')[0].strip() for line in provider_lines if '=' in line]:
                    if "project_id" in self.config:
                        provider_lines.append('  project = var.project_id')
                    elif "project" in self.config:
                        provider_lines.append('  project = var.project')
                
                if "region" not in [line.split('=')[0].strip() for line in provider_lines if '=' in line]:
                    if "region" in self.config:
                        provider_lines.append('  region = var.region')
            
            elif provider == "aws":
                if "region" not in [line.split('=')[0].strip() for line in provider_lines if '=' in line]:
                    if "aws_region" in self.config:
                        provider_lines.append('  region = var.aws_region')
                    elif "region" in self.config:
                        provider_lines.append('  region = var.region')
            
            provider_lines.append("}")
            providers.append("\n".join(provider_lines))
        
        return "\n\n".join(providers)
    
    def generate_module_block(self, module_name: str, module_config: ModuleConfig) -> str:
        lines = [f"module \"{module_name}\" {{"]
        
        lines.append(f'  source = "{module_config.source}"')
        
        if module_config.version:
            lines.append(f'  version = "{module_config.version}"')
        
        common_vars = ['project_id', 'project', 'region', 'zone', 'environment', 'name_prefix']
        
        for common_var in common_vars:
            if (common_var in self.config and 
                common_var not in module_config.variables):
                if 'variables' in self.config and common_var in self.config['variables']:
                    lines.append(f"  {common_var} = var.{common_var}")
        
        for var_name, var_value in module_config.variables.items():
            lines.append(f"  {var_name} = {self._format_terraform_value(var_value)}")
        
        if module_config.depends_on:
            depends_list = ', '.join([f'module.{dep}' for dep in module_config.depends_on])
            lines.append(f"  depends_on = [{depends_list}]")
        
        lines.append("}")
        return "\n".join(lines)
    
    def generate_data_sources(self) -> str:
        data_sources = []
        
        if 'data_sources' in self.config:
            for data_source in self.config['data_sources']:
                ds_type = data_source.get('type')
                ds_name = data_source.get('name')
                ds_config = data_source.get('config', {})
                
                lines = [f"data \"{ds_type}\" \"{ds_name}\" {{"]
                for key, value in ds_config.items():
                    lines.append(f"  {key} = {self._format_terraform_value(value)}")
                lines.append("}")
                
                data_sources.append("\n".join(lines))
        
        return "\n\n".join(data_sources)
    
    def generate_outputs(self, ordered_modules: List[str]) -> str:
        outputs = []
        
        for module_name in ordered_modules:
            module_config = self.modules[module_name]
            
            for output_name in module_config.outputs:
                output_block = [
                    f"output \"{module_name}_{output_name}\" {{",
                    f"  description = \"{output_name} from {module_name} module\"",
                    f"  value = module.{module_name}.{output_name}",
                    "}"
                ]
                outputs.append("\n".join(output_block))
        
        if 'outputs' in self.config:
            for output_name, output_config in self.config['outputs'].items():
                output_block = [
                    f"output \"{output_name}\" {{",
                    f"  description = \"{output_config.get('description', output_name)}\"",
                    f"  value = {output_config.get('value', 'null')}"
                ]
                
                if output_config.get('sensitive', False):
                    output_block.append("  sensitive = true")
                
                output_block.append("}")
                outputs.append("\n".join(output_block))
        
        return "\n\n".join(outputs)
    
    def generate_locals(self) -> str:
        if 'locals' not in self.config:
            return ""
        
        lines = ["locals {"]
        for key, value in self.config['locals'].items():
            lines.append(f"  {key} = {self._format_terraform_value(value)}")
        lines.append("}")
        
        return "\n".join(lines)
    
    def _format_terraform_value(self, value: Any) -> str:
        if isinstance(value, str):
            if any(value.startswith(prefix) for prefix in ['var.', 'local.', 'data.', 'module.']):
                return value
            return f'"{value}"'
        elif isinstance(value, bool):
            return str(value).lower()
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, list):
            items = [self._format_terraform_value(item) for item in value]
            return f"[{', '.join(items)}]"
        elif isinstance(value, dict):
            items = [f"{k} = {self._format_terraform_value(v)}" for k, v in value.items()]
            return "{\n  " + '\n  '.join(items) + "\n}"
        else:
            return f'"{value}"'
    
    def generate_main_tf(self, ordered_modules: List[str]) -> str:
        sections = []
        
        sections.append(self.generate_terraform_config())
        
        provider_config = self.generate_provider_config()
        if provider_config:
            sections.append(provider_config)
        
        locals_config = self.generate_locals()
        if locals_config:
            sections.append(locals_config)
        
        data_sources = self.generate_data_sources()
        if data_sources:
            sections.append(data_sources)
        
        module_blocks = []
        for module_name in ordered_modules:
            module_config = self.modules[module_name]
            module_blocks.append(self.generate_module_block(module_name, module_config))
        
        if module_blocks:
            sections.append("\n\n".join(module_blocks))
        
        return "\n\n".join(sections)
    
    def generate_variables_tf(self) -> str:
        variables = []
        
        common_variable_defaults = {
            'project_id': {
                'description': 'The GCP project ID',
                'type': 'string'
            },
            'project': {
                'description': 'The project name',
                'type': 'string'
            },
            'region': {
                'description': 'The region for resources',
                'type': 'string',
                'default': 'us-central1'
            },
            'zone': {
                'description': 'The zone for resources',
                'type': 'string'
            },
            'environment': {
                'description': 'Environment name (dev, staging, prod)',
                'type': 'string',
                'default': 'dev'
            },
            'name_prefix': {
                'description': 'Prefix for resource names',
                'type': 'string'
            }
        }
        
        config_variables = self.config.get('variables', {})
        
        for var_name, var_defaults in common_variable_defaults.items():
            if var_name in self.config and var_name not in config_variables:
                config_variables[var_name] = var_defaults.copy()
                if 'default' not in var_defaults:
                    config_variables[var_name]['default'] = self.config[var_name]
        
        for var_name, var_config in config_variables.items():
            var_block = [f"variable \"{var_name}\" {{"]
            
            if 'description' in var_config:
                var_block.append(f'  description = "{var_config["description"]}"')
            
            if 'type' in var_config:
                var_block.append(f'  type = {var_config["type"]}')
            
            if 'default' in var_config:
                var_block.append(f'  default = {self._format_terraform_value(var_config["default"])}')
            
            if var_config.get('sensitive', False):
                var_block.append('  sensitive = true')
            
            if 'validation' in var_config:
                validation = var_config['validation']
                var_block.append('  validation {')
                var_block.append(f'    condition     = {validation.get("condition", "true")}')
                var_block.append(f'    error_message = "{validation.get("error_message", "Invalid value")}"')
                var_block.append('  }')
            
            var_block.append("}")
            variables.append("\n".join(var_block))
        
        return "\n\n".join(variables)
    
    def generate_terraform_files(self) -> None:
        print(" Generating Terraform files...")
        
        self.config = self.read_yaml_config()
        self.modules = self.parse_module_configs(self.config)
        self.terraform_config = self.parse_terraform_config(self.config)
        
        ordered_modules = self.validate_module_dependencies(self.modules)
        
        main_tf_content = self.generate_main_tf(ordered_modules)
        with open(self.generated_dir / "main.tf", 'w') as f:
            f.write(main_tf_content)
        print(f"✓ Generated {self.generated_dir / 'main.tf'}")
        
        variables_tf_content = self.generate_variables_tf()
        if variables_tf_content:
            with open(self.generated_dir / "variables.tf", 'w') as f:
                f.write(variables_tf_content)
            print(f"✓ Generated {self.generated_dir / 'variables.tf'}")
        
        outputs_tf_content = self.generate_outputs(ordered_modules)
        if outputs_tf_content:
            with open(self.generated_dir / "outputs.tf", 'w') as f:
                f.write(outputs_tf_content)
            print(f"✓ Generated {self.generated_dir / 'outputs.tf'}")
        
        if self.preserve_tfvars or not self.tfvars_file.exists():
            self.convert_to_tfvars()
        else:
            print(f" Skipping tfvars generation to preserve existing {self.tfvars_file}")
    
    def convert_to_tfvars(self) -> None:
        tfvars_content = []
        
        existing_tfvars = {}
        if self.preserve_tfvars and self.tfvars_file.exists():
            try:
                with open(self.tfvars_file, 'r') as file:
                    existing_content = file.read()
                    for line in existing_content.split('\n'):
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            existing_tfvars[key.strip()] = value.strip()
                print(f"✓ Preserved {len(existing_tfvars)} existing variables from {self.tfvars_file}")
            except Exception as e:
                print(f"⚠️  Warning: Could not parse existing tfvars file: {e}")
        
        skip_sections = {'modules', 'terraform', 'variables', 'outputs', 'locals', 'data_sources'}
        
        if 'variables' in self.config:
            defined_variables = set(self.config['variables'].keys())
            
            for key, value in self.config.items():
                if key in skip_sections:
                    continue
                
                if key.endswith('_config'):
                    continue
                
                if key in defined_variables:
                    tfvars_content.append(f'{key} = {self._format_terraform_value(value)}')
        
        for key, value in existing_tfvars.items():
            var_line = f'{key} = {value}'
            if not any(line.startswith(f'{key} =') for line in tfvars_content):
                tfvars_content.append(var_line)
        
        if tfvars_content:
            with open(self.tfvars_file, 'w') as file:
                file.write('\n'.join(tfvars_content))
            print(f"✓ Generated {self.tfvars_file} with {len(tfvars_content)} variables")
        else:
            print("ℹ  No variables to write to tfvars file")
    
    def run_terraform_command(self, command: List[str]) -> bool:
        try:
            print(f" Running: {' '.join(command)}")
            result = subprocess.run(
                command,
                cwd=self.generated_dir,
                capture_output=True,
                text=True,
                check=True
            )
            
            if result.stdout:
                print(result.stdout)
            
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Command failed: {' '.join(command)}")
            print(f"Exit code: {e.returncode}")
            if e.stdout:
                print(f"STDOUT:\n{e.stdout}")
            if e.stderr:
                print(f"STDERR:\n{e.stderr}")
            return False
    
    def terraform_init(self) -> bool:
        print(" Initializing Terraform...")
        return self.run_terraform_command(["terraform", "init"])
    
    def terraform_plan(self) -> bool:
        print(" Running Terraform plan...")
        return self.run_terraform_command(["terraform", "plan", f"-var-file=../{self.tfvars_file.name}"])
    
    def terraform_apply(self, auto_approve: bool = False) -> bool:
        print(" Applying Terraform configuration...")
        command = ["terraform", "apply", f"-var-file=../{self.tfvars_file.name}", "-auto-approve"]
        
        if auto_approve:
            command.append("-auto-approve")
        
        return self.run_terraform_command(command)
    
    def terraform_destroy(self, auto_approve: bool = False) -> bool:
        print("  Destroying Terraform infrastructure...")
        command = ["terraform", "destroy", f"-var-file=../{self.tfvars_file.name}"]
        
        if auto_approve:
            command.append("-auto-approve")
        
        return self.run_terraform_command(command)
    
    def deploy(self, plan_only: bool = False, auto_approve: bool = False) -> bool:
        print(" Starting enhanced Terraform deployment workflow...")
        
        self.generate_terraform_files()
        
        if not self.terraform_init():
            return False
        
        if not self.terraform_plan():
            return False
        
        if plan_only:
            print("✓ Plan completed successfully (plan-only mode)")
            return True
        
        if not self.terraform_apply(auto_approve):
            return False
        
        print("🎉 Enhanced deployment completed successfully!")
        return True

def main():
    parser = argparse.ArgumentParser(description="Enhanced Terraform Automation with Module Reusability")
    parser.add_argument("config", help="Path to YAML configuration file")
    parser.add_argument("-d", "--terraform-dir", default=".", help="Terraform directory path")
    parser.add_argument("-t", "--template-dir", default="templates", help="Template directory path")
    parser.add_argument("-p", "--plan-only", action="store_true", help="Only run plan, don't apply")
    parser.add_argument("-a", "--auto-approve", action="store_true", help="Auto-approve apply/destroy")
    parser.add_argument("--destroy", action="store_true", help="Destroy infrastructure instead of creating")
    parser.add_argument("--no-preserve-tfvars", action="store_true", help="Don't preserve existing terraform.tfvars file")
    parser.add_argument("--generate-only", action="store_true", help="Only generate files, don't run terraform")
    
    args = parser.parse_args()
    
    automator = EnhancedTerraformAutomator(
        args.config, 
        args.terraform_dir, 
        args.template_dir,
        preserve_tfvars=not args.no_preserve_tfvars
    )
    
    if args.generate_only:
        automator.generate_terraform_files()
        print("✓ Files generated successfully")
        sys.exit(0)
    
    if args.destroy:
        automator.generate_terraform_files()
        success = automator.terraform_destroy(args.auto_approve)
    else:
        success = automator.deploy(args.plan_only, args.auto_approve)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()