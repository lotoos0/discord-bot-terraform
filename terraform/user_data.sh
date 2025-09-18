#!/bin/bash
set -euo pipefail

if command -v dnf >/dev/null 2>&1; then PM=dnf; else PM=yum; fi

$PM update -y
$PM install -y docker awscli
systemctl enable --now docker

# Take token from SSM
DISCORD_TOKEN=$(aws ssm get-parameter \
  --name "${ssm_token_name}" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "${aws_region}")

# Remove old container if exists
docker rm -f discord-bot 2>/dev/null || true

# Create logs dir
mkdir -p /var/log/discord-bot

# Start bot (log output redirected to file on host)
docker run -d --restart unless-stopped \
  --name discord-bot \
  -e DISCORD_TOKEN="$DISCORD_TOKEN" \
  -v /var/log/discord-bot:/logs \
  "${bot_image}" \
  > /var/log/discord-bot/container_id.log 2>&1

# Also save timestamp that script finished
echo "User data finished at $(date)" >> /var/log/user_data.log
