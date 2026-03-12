output "ec2_instance_ids" {
  value = aws_instance.this[*].id
}

output "ec2_public_ips" {
  value = aws_instance.this[*].public_ip
}

output "ec2_private_ips" {
  value = aws_instance.this[*].private_ip
}

output "security_group_id" {
  value = aws_security_group.ec2.id
}
