data "aws_caller_identity" "me" {}

# default VPC i subnety
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG: tylko egress (SSM i pull obrazów)
resource "aws_security_group" "bot_sg" {
  name        = "discord-bot-sg"
  description = "Egress only"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Rola dla EC2: SSM + odczyt naszego parametru
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "discord-bot-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ssm_read" {
  statement {
    actions = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.me.account_id}:parameter${var.ssm_token_name}"
    ]
  }
  # uproszczenie: pozwól na decrypt dowolnym kluczem SSM KMS
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_read" {
  name   = "discord-bot-ssm-read"
  policy = data.aws_iam_policy_document.ssm_read.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_read_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "discord-bot-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# AMI: Amazon Linux 2 (ma SSM agent)
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  user_data = templatefile("${path.module}/user_data.sh", {
    ssm_token_name = var.ssm_token_name
    aws_region     = var.aws_region
    bot_image      = var.bot_image
  })
}

resource "aws_instance" "bot" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = "t3.micro"
  subnet_id                   = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids      = [aws_security_group.bot_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.bot_profile.name
  user_data                   = local.user_data
  user_data_replace_on_change = true



  associate_public_ip_address = true # prosto: internet na SSM i pull obrazu

  tags = { Name = "discord-bot" }
}

