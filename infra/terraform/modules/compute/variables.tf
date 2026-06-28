variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for the control-plane node"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
}

variable "subnet_id" {
  description = "Subnet to launch instances into"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "security_group_id" {
  description = "Security group to attach to all instances"
  type        = string
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
}
