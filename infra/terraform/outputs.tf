output "control_plane_public_ip" {
  description = "SSH to this IP to reach the control-plane node"
  value       = module.compute.control_plane_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP used by workers to join the k3s cluster"
  value       = module.compute.control_plane_private_ip
}

output "worker_public_ips" {
  description = "Public IPs of all worker nodes"
  value       = module.compute.worker_public_ips
}

output "worker_private_ips" {
  description = "Private IPs of all worker nodes"
  value       = module.compute.worker_private_ips
}

output "ssh_command_control_plane" {
  description = "Ready-to-run SSH command for the control-plane"
  value       = "ssh -i ~/.ssh/<your-key>.pem ubuntu@${module.compute.control_plane_public_ip}"
}