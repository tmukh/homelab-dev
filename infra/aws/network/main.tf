resource "aws_vpc" "lab" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "homelab-lab"
  }
}
resource "aws_security_group" "lab" {
  name        = "homelab-lab"
  description = "Security group for homelab VPC"
  vpc_id      = aws_vpc.lab.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.my_ip
  security_group_id = aws_security_group.lab.id
}