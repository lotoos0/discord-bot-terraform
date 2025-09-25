# Discord Bot AWS Deployment (Terraform)

#### This project uses an existing [DISCORD-BOT](https://github.com/lotoos0/discord-bot)  - Source code and Docker image.
---
This project provisions an **EC2 instance on AWS** with **Terraform** to run a Discord music bot inside Docker.  
Infrastructure follows: SSM Session Manager for access (no SSH), secure token storage in SSM Parameter Store, and IAM roles for least privilege. 

---

## Architecture

```txt
Developer ──▶ GitLab CI (build + scan) ──▶ Docker Registry (Hub/ECR)
      │
      └──▶ Terraform ─────────────────────▶ AWS
                                           ├─ EC2 (Docker runtime)
                                           ├─ IAM Role (SSM + least privilege to SSM param)
                                           └─ SSM Parameter Store (SecureString: DISCORD_TOKEN)

EC2 (container):
  discord-bot  ◀── pulls image ◀── Registry
  DISCORD_TOKEN ◀── ssm:GetParameter (with decryption)
```

Terraform provisions the following resources:

- **VPC & Subnet (default)** - reuses AWS default VPC and subnets  
- **Security Group** - egress-only (internet access, no inbound ports)  
- **IAM Role & Instance Profile** -  
  - `AmazonSSMManagedInstanceCore` -> allows SSM Session Manager access  
  - Custom policy -> allows reading the bot token from SSM Parameter Store  
- **EC2 Instance** -  
  - Amazon Linux 2 with Docker + AWS CLI installed via `user_data.sh`  
  - Automatically pulls bot token from SSM and runs container from Docker Hub  
- **Outputs** - instance ID and public IP

---

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5  
- AWS account with IAM user/role configured  
- AWS CLI installed and configured (`aws configure`)  
- Docker image of bot published on Docker Hub (e.g. `lotoos0/discord-bot:latest`)  
- Discord token stored in **AWS SSM Parameter Store**, e.g.:  

```bash
aws ssm put-parameter \
  --name "/discord/bot/token" \
  --value "YOUR_TOKEN" \
  --type SecureString
```
## Setup 

```bash
git clone https://github.com/<your-username>/discord-bot-aws-tf.git
cd discord-bot-aws-tf
```
1. Initialize Terraform
```bash
terraform init
```
2. Check plan
```bash
terraform plan
```
3. Apply changes
```bash
terraform apply
```

4. Cleanup lab
```bash
terraform destroy
```
## Configuration

Copy `examples/terraform.tfvars.example` to `terraform.tfvars` and fill in your values:
```hcl
aws_region     = "your-aws-region"          
ssm_token_name = "your-ssm-token-path"      
bot_image      = "your-docker-image:tag"    
instance_type  = "your-instance-type"       
```
Don't commit terraform.tfvars!

## Access the Instance

No SSH needed. Use AWS SSM Session Manager:
```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```
Check logs and container:
```bash
sudo tail -n +1 /var/log/cloud-init-output.log
sudo tail -n +1 /var/log/user_data.log
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.RestartCount}}"
docker logs -n 100 discord-bot
```
## Cost & Security

- Security:
  - No ingress: only egress traffic, no SSH (Session Manager only)
  - Secrets stored in SSM Parameter Store as SecureString
  - IAM least privilege: EC2 can only `ssm:GetParameter` on `/discord/bot/*`

- Cost:
  - Instance type: `t3.micro` (eligible for free tier)
  - Storage: gp3 EBS volume
  - Outbound network transfer billed normally

## Cost & Reliability

- Auto-stop/start: use cron on EC2 to stop instance at night and start in the morning:
```
crontab -e
0 1 * * * aws ec2 stop-instances --instance-ids <id> --region eu-central-1
0 7 * * * aws ec2 start-instances --instance-ids <id> --region eu-central-1
```
This avoids paying for unused hours.

## Files
- `main.tf` - resources (EC2, IAM, SG, AMI)
- `variables.tf` - input variables
- `outputs.tf` - exposed outputs
- `provider.tf` - provider config (AWS)
- `user_data.sh` - instance bootstrap (Docker, AWS CLI, run bot)

## Notes
- The bot runs fully automated on EC2 via Terraform.
- No inbound ports are required (safe setup).
- Logs available on instance (`/var/log/user_data.log`).

## Changelog
See [CHANGELOG.md](/CHANGELOG.md) for detailed history. 

## License

Licensed under the MIT license.
