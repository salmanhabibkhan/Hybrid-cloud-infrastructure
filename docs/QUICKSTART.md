# QuickStart: Hybrid Cloud Joget – Infra + CI/CD

This guide mirrors the top-level README and walks you through:
- Standing up cloud infrastructure with Terraform
- Optional on-prem simulator
- CI/CD with GitHub Actions + CodeDeploy
- Optional RDS via AWS CDK (CloudFormation)
- Optional Direct Connect + DMS replication

Region assumptions:
- Cloud: us-west-1
- On-Prem simulator: us-east-1 (optional)

Prerequisites
- Terraform >= 1.6
- AWS CLI with credentials configured
- GitHub repository (this repo) with Actions secrets configured
- SSM Parameter Store entries for DB config (created below)
- Optional (for RDS via CDK): Node.js, npm, AWS CDK CLI

1) Deploy Cloud Infrastructure (us-west-1)
- cd infrastructure
- terraform init
- terraform plan -var="project_name=hybrid-cloud-joget" -var="admin_ip=YOUR_PUBLIC_IP/32"
- terraform apply -var="project_name=hybrid-cloud-joget" -var="admin_ip=YOUR_PUBLIC_IP/32"
After apply, note outputs:
- alb_dns_name
- artifact_bucket (S3 bucket for CI/CD artifacts)

2) Create DB Secrets in SSM Parameter Store (us-west-1)
Create the following parameters (type SecureString recommended):
- /hybrid-cloud-joget/db_url      Value: jdbc:mysql://YOUR_RDS_OR_ONPREM:3306/joget_db
- /hybrid-cloud-joget/db_user     Value: jogetuser
- /hybrid-cloud-joget/db_password Value: StrongPassword123!
Instances read these during deployment; no DB secrets live in Terraform or user data.

3) Configure GitHub Actions Secrets (Repo Settings > Secrets and variables > Actions)
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION = us-west-1
- ARTIFACT_BUCKET = (exact value of the Terraform output artifact_bucket)
- CD_APP_NAME = hybrid-cloud-joget-codedeploy-app
- CD_DEPLOYMENT_GROUP = hybrid-cloud-joget-codedeploy-dg
Optional: Add any additional environment or build variables required by your app.

4) Push Code to Trigger CI/CD
- Commit your Java app under joget_app/ along with appspec.yml and deployment scripts.
- Push to main (or merge a PR into main).
The workflow will:
- Build the app with Maven
- Package the JAR + appspec.yml + scripts
- Upload the artifact to the S3 artifact_bucket
- Trigger an AWS CodeDeploy in-place deployment to the two EC2 instances behind the ALB

5) Open the App
- Health: http://ALB_DNS_NAME/health
- App (proxied via Apache): http://ALB_DNS_NAME/app
Replace ALB_DNS_NAME with the actual terraform output.

6) Optional: On-Prem Simulator (us-east-1)
This mimics an on-prem server on a separate VPC/region with a single EC2 instance that runs Apache + Joget + local MySQL.
- Provision an EC2 in us-east-1 (manually or from your own Terraform).
- SSH to the instance and prepare the installer script:
  - Open scripts/onprem_setup.sh from this repo (Hybrid-cloud-infrastructure/scripts/onprem_setup.sh)
  - Copy its contents into a file named onprem_setup.sh on the instance
  - export GITHUB_PAT="ghp_xxx" (GitHub token if pulling private code)
  - sudo -E bash onprem_setup.sh
- Access via http://YOUR_ONPREM_PUBLIC_IP:80

7) Optional: AWS Direct Connect + DMS (On-Prem → Cloud)
Use Direct Connect for private connectivity between your on-prem network and the AWS VPC. Use AWS DMS to replicate from on-prem MySQL to Amazon RDS MySQL over that private link.
- Follow docs/direct-connect-dms.md for step-by-step creation of:
  - Direct Connect connection and virtual interface (DXGW/VGW attachment to VPC)
  - DMS replication instance (in VPC private subnets)
  - DMS source endpoint (On-Prem MySQL over DX) and target endpoint (RDS)
  - Migration task (Full Load + CDC as needed)

8) Optional: RDS via AWS CDK (CloudFormation)
RDS and DMS are not in Terraform. You can stand up RDS using the provided CDK code.
- cd rds-cluster-instance
- Install dependencies (see rds-cluster-instance/README.md)
- Fill settings in settings.py
- cdk synth
- cdk bootstrap
- cdk deploy

9) Troubleshooting
- CodeDeploy Console: inspect deployment events and lifecycle hook logs
- Instance logs:
  - /var/log/cloud-init-output.log
  - /var/log/aws/codedeploy-agent/codedeploy-agent.log
  - /var/log/apache2/*
  - journalctl -u joget-app
- ALB targets unhealthy:
  - First deployment can take a few minutes
  - Ensure health endpoint /health returns HTTP 200
  - Verify Security Groups:
    - ALB SG: 80/443 from internet
    - App SG: 80 only from ALB SG
    - RDS SG: 3306 from App SG (and DMS if used)
- Connectivity:
  - Private instances require NAT for package installs unless you use VPC Endpoints
  - For DMS over DX, allow 3306 from DMS to on-prem MySQL on the on-prem firewall

10) Teardown
- On-Prem first: Remove on-prem simulator resources and stop services
- Cloud next:
  - cd infrastructure
  - terraform destroy

11) Security Notes
- No DB credentials in Terraform or user data; use SSM Parameter Store
- Instance role limited to ssm:GetParameter on /hybrid-cloud-joget/*
- ALB in public subnets; EC2 and RDS in private subnets
- Use ACM + HTTPS on ALB for production traffic
- Consider WAF on ALB and CloudWatch Agent for centralized logs

References
- docs/direct-connect-dms.md – Direct Connect + DMS guide
- rds-cluster-instance/README.md – RDS via AWS CDK