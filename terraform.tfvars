project_name     = "test-app"
environment      = "dev"
cloud_provider   = "aws"
services         = ["storage", "monitoring"]

aws_config = {
  region = "us-west-2"
}
/*
gcp_config = {
  project_id       = "your-gcp-project-id"
  region           = "us-central1"
  credentials_file = "path/to/gcp-credentials.json"
}
*/
labels = {
  Project     = "test-app"
  Owner       = "platform-team"
  Environment = "dev"
}
