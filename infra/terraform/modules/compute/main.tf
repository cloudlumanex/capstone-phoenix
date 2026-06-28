resource "aws_instance" "control_plane" {
  ami                    = var.ami_id
  instance_type          = var.control_plane_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "phoenix-control-plane"
    Role = "control-plane"
  }
}

resource "aws_instance" "workers" {
  count = var.worker_count

  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "phoenix-worker-${count.index + 1}"
    Role = "worker"
  }
}
