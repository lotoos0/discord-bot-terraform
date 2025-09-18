output "instance_id" { value = aws_instance.bot.id }

output "instance_public_ip" { value = aws_instance.bot.public_ip }

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.bot.public_ip
}

