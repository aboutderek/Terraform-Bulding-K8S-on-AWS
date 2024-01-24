output "instance_msr_public_ip" {
  description = "Public address IP of master"
  value       = aws_instance.ec2_instance_msr.public_ip
}

output "instance_wrks_public_ip" {
  description = "Public address IP of worker"
  value       = aws_instance.ec2_instance_wrk.*.public_ip
}