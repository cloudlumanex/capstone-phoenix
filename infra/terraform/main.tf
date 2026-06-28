module "network" {
  source = "./modules/network"

  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "compute" {
  source = "./modules/compute"

  ami_id                      = var.ami_id
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  worker_count                = var.worker_count
  subnet_id                   = module.network.public_subnet_id
  key_pair_name               = var.key_pair_name
  security_group_id           = module.security_group.security_group_id
  root_volume_size_gb         = var.root_volume_size_gb
}