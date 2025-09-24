data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "bot_ec2_role" {
  name               = "discord-bot-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "bot_ssm_policy" {
  name        = "discord-bot-ssm-policy"
  description = "Least privilege for Discord Bot EC2"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadBotToken",
      "Effect": "Allow",
      "Action": ["ssm:GetParameter"],
      "Resource": "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/discord/bot/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bot_attach_ssm" {
  role       = aws_iam_role.bot_ec2_role.name
  policy_arn = aws_iam_policy.bot_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "bot_attach_ssm_core" {
  role       = aws_iam_role.bot_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "bot_profile" {
  name = "discord-bot-instance-profile"
  role = aws_iam_role.bot_ec2_role.name
}

