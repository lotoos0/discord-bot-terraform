variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Free tier
}

variable "ssm_token_name" {
  description = "SSM parameter name containing the Discord bot token"
  type        = string
}

variable "bot_image" {
  description = "Docker image for the Discord bot"
  type        = string
}

