variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR notation (e.g. 105.x.x.x/32). Only this IP can SSH to the nodes."
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair already uploaded to AWS (not the .pem file path)"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI for eu-west-1."
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for the k3s control-plane node"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "Instance type for k3s worker nodes"
  type        = string
  default     = "t3.micro"
}

variable "worker_count" {
  description = "Number of worker nodes. Minimum 2."
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 2
    error_message = "worker_count must be at least 2. A single-node cluster fails the capstone."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB for each node"
  type        = number
  default     = 20
}