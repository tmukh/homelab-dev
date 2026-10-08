variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-north-1"
}
variable "my_ip" {
  description = "The public IP address of the machine running Terraform"
  type        = string
  # defined in the terraform.tfvars file

}