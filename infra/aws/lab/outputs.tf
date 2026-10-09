output "vpc_id" {
  value = aws_vpc.lab.id
}

output "security_group_id" {
  value = aws_security_group.lab.id
}

output "public_ip" {
  value = aws_instance.k3s.public_ip
}

output "ssh" {
  value = "ssh ubuntu@${aws_instance.k3s.public_ip}"
}
