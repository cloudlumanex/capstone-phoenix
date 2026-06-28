output "security_group_id" {
  description = "ID of the shared node security group"
  value       = aws_security_group.nodes.id
}
