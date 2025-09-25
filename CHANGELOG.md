# Changelog
All notable changes to this project will be documented in this file.

# Changelog
All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-09-25
### Added
- `iam.tf`: introduced dedicated IAM role, least-privilege SSM policy, and instance profile for EC2
- IAM role trust policy allowing EC2 to assume the role
- IAM policy granting only `ssm:GetParameter` (with decryption) on `/discord/bot/*`
- Instance profile attachment to EC2 instance for runtime credentials

### Changed
- `user_data.sh`: 
  - added logging via `tee` to `/var/log/user_data.log`
  - cleaned up token handling (`unset DISCORD_TOKEN` after container start)
  - ensured Docker auto-restart (`--restart unless-stopped`)
- `main.tf`: 
  - enabled `user_data_replace_on_change = true` to force instance replacement on script changes
  - attached IAM instance profile to EC2 instance
- `.gitignore`: updated to ignore `.tfstate`, `.terraform/`, and sensitive files (`terraform.tfvars`)
- added `examples/terraform.tfvars.example` with placeholders for variables (`aws_region`, `ssm_token_name`, `bot_image`, `instance_type`)

### Documentation
- Updated README to reflect architecture and security hardening:
  - ASCII diagram of Dev → CI/CD → Terraform → AWS → Bot
  - Security notes: SSM for secrets, IAM least privilege, egress-only SG, no SSH (Session Manager only)
  - Cost & Security section with guidance on AWS resource usage
  - Deployment steps (`terraform init/plan/apply/destroy`) and verification steps (`aws ssm start-session`, `docker ps`, logs)
- Added recommendations for future improvements (CloudWatch Logs integration, GitLab CI image scanning, ECS/EKS migration)



