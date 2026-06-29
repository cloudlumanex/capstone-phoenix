resource "aws_security_group" "nodes" {
  name        = "phoenix-nodes-sg"
  description = "Shared security group for all k3s cluster nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "phoenix-nodes-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.nodes.id
  description       = "SSH from operator IP only"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidr
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.nodes.id
  description       = "HTTP - redirects to HTTPS via ingress controller"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.nodes.id
  description       = "HTTPS - ingress controller terminates TLS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "internal_tcp" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "All TCP between cluster nodes"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.nodes.id
}

resource "aws_vpc_security_group_ingress_rule" "internal_udp" {
  security_group_id            = aws_security_group.nodes.id
  description                  = "All UDP between cluster nodes"
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "udp"
  referenced_security_group_id = aws_security_group.nodes.id
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.nodes.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "k8s_api" {
  security_group_id = aws_security_group.nodes.id
  description       = "Kubernetes API - operator IP only"
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidr
}
