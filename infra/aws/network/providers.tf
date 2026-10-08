provider "aws" {
  region  = var.region
  profile = "homelab"
  default_tags {
    tags = {
      Project   = "Homelab"
      ManagedBy = "Terraform"
    }
  }
}