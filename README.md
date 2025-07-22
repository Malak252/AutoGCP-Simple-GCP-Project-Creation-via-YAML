# AutoGCP-Simple-GCP-Project-Creation-via-YAML
This project automates the creation of Google Cloud Platform (GCP) and AWS infrastructure using Terraform, all driven by a single YAML configuration file. It's built to make cloud provisioning flexible, fast, and maintainable — without touching Terraform every time.

📦 Features
🌐 Multi-cloud support (GCP + AWS)

🔄 Workspace-aware logic (separate resources per environment)

🧾 YAML-driven configuration – write once, deploy anywhere

🧱 Modular Terraform – reusable, dynamic, and scalable

🔐 Secret-safe – uses environment variables for credentials

🧼 Cleanup tool – destroy everything via a single command

🚀 Getting Started
1. Clone the Repo
bash
Copy
Edit
git clone https://github.com/Malak252/AutoGCP-Simple-GCP-Project-Creation-via-YAML.git
cd AutoGCP-Simple-GCP-Project-Creation-via-YAML
2. Install Requirements
Terraform: Install Terraform

Python 3.x

Python dependencies:

bash
Copy
Edit
pip install -r requirements.txt
3. Set Up Credentials
Create a .env file (or export variables directly) with your credentials:

env
Copy
Edit
GOOGLE_CREDENTIALS_PATH=path/to/your/service_account.json
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
✅ If you're only using one cloud provider, you can set dummy values for the other.

4. Configure Your Project in YAML
Edit the example-project.yaml file:

yaml
Copy
Edit
cloud_provider: gcp
project_name: my-sample-project
region: us-central1
5. Deploy Infrastructure
bash
Copy
Edit
python deploy.py
terraform init
terraform apply
🧹 Destroy Resources
bash
Copy
Edit
python destroy.py
terraform destroy
📁 Project Structure
bash
Copy
Edit
AutoGCP/
├── main.tf                
├── variables.tf
├── outputs.tf
├── example-project.yaml       # User-defined cloud config
├── terraform/
│   ├── destroy.py                 # Cleans up resources
│   ├── deploy.py                 # Converts YAML to tfvars
│   └── modules/
│       ├── gcp_resources/
│       └── aws_resources/
├── .env                       # (Untracked) Cloud credentials
└── README.md
🌍 Supported Resources
✅ GCP
Project creation

IAM roles

Service accounts

🟡 AWS (WIP)
S3 buckets

IAM users

💡 How It Works
deploy.py reads your YAML config and current Terraform workspace.

It generates .auto.tfvars.json with only relevant cloud inputs.

Terraform loads your cloud-specific module automatically.

You apply or destroy as usual.

👩‍💻 Authors
Built with ❤️ by:

Malak Wagieh – GCP & DevOps Logic, YAML Parser, Terraform GCP Modules

Shahd Samir – Terraform AWS Modules, Cleanup Scripting, Testing Support

🛡️ License
MIT License © Malak Wagieh & Shahd Samir
