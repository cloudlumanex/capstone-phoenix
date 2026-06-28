variable "vpc_id" {
  description = "VPC to attach the security group to"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR notation"
  type        = string
}
