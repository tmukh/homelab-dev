variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}

variable "my_ip" {
  description = "The public IP address of the machine running Terraform, as a /32"
  type        = string
  # defined in the terraform.tfvars file
}

variable "instance_type" {
  description = "EC2 type for the k3s node. x86 only: the ghcr images are amd64."
  type        = string
  default     = "t3.small"
}

variable "k3s_version" {
  description = "Same k3s version as the laptop cluster"
  type        = string
  default     = "v1.36.4+k3s1"
}

variable "ssh_public_key_path" {
  description = "Public half of the SSH key used to log in"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
