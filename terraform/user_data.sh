#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/user_data.log) 2>&1

echo "[user_data] start: $(date)"

if command -v dnf >/dev/null 2>&1; then PM=dnf; else PM=yum; fi

echo "[user_data] updating system and installing docker+awscli via $PM"
$PM update -y
$PM install -y docker awscli

echo "[user_data] enabling docker"
systemctl enable --now docker

AWS_REGION="${aws_region}"
SSM_PARAM="${ssm_token_name}"
IMAGE="${bot_image}"

echo "[user_data] pulling token from SSM path: $SSM_PARAM (region: $AWS_REGION)"
# Take token from SSM
DISCORD_TOKEN=$(aws ssm get-parameter \
  --name "$SSM_PARAM" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "$AWS_REGION")

echo "[user_data] pulling docker image: $IMAGE"
docker pull "$IMAGE"

echo "[user_data] (re)starting container"
# Remove old container if exists
docker rm -f discord-bot 2>/dev/null || true

# Create logs dir
mkdir -p /var/log/discord-bot

# Start bot (log output redirected to file on host)
docker run -d --name discord-bot \
  --restart=unless-stopped \
  -e DISCORD_TOKEN="$DISCORD_TOKEN" \
  "$IMAGE"

unset DISCORD_TOKEN

# Also save timestamp that script finished
echo "[user_data] finished: $(date)" >>/var/log/user_data.log
