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

## [1.1.0] - 2025-09-25
### Added
- README: Cost & Reliability section
- README: Cost & Security section
- Auto-stop/start instructions with cron + AWS CLI (cost optimization)
- Container restart policy (`--restart=always`) with verification via `docker ps`
- Documentation notes on how to reduce costs outside usage hours

### Changed
- README: improved deployment and verification flow
- README: updated ASCII architecture diagram (now its super clean)
- README: improved Configuration section 
- README: adjusted section headings (e.g. Access the Instance)
- README: removed Outputs section
