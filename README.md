# Hybrid-cloud-infrastructure

This is a Hybrid Infrastructure which is setup on On-Prem & AWS

Joget App Deployment & AWS RDS Setup



export APP_ENV=aws
chmod +x deploy.sh
./deploy.sh

tail -f ~/joget_app/app.log
------------

# Hybrid Cloud: Infra with Terraform + CI/CD via GitHub Actions and CodeDeploy

This repo provisions cloud infrastructure in us-west-1 and a simulated on-prem EC2 in us-east-1 using Terraform. Application deployment is handled by a CI/CD pipeline (GitHub Actions) that builds your Java app and deploys it to two EC2 instances via AWS CodeDeploy. No application configuration is performed by Terraform.

Key points:
- Cloud (us-west-1): VPC, 2 public + 2 private subnets, NAT, ALB, 2 EC2 app servers (via ASG), Security Groups, NACLs, IAM, S3 artifacts, CodeDeploy, CloudWatch alarms.
- On-Prem (us-east-1): VPC + single EC2 for simulation (no automation).
- Pipeline: GitHub Actions builds from this repo, uploads artifact to S3, triggers CodeDeploy to deploy to the two EC2 instances.
- RDS and DMS are NOT in Terraform. Direct Connect + DMS steps are in docs/direct-connect-dms.md.

Architecture diagram: diagrams/architecture.mmd (Mermaid).

Prerequisites:
- Terraform >= 1.6
- AWS account and credentials (Administrator for initial setup)
- GitHub repo (this repo) with secrets configured (see CI/CD Setup below)
- SSM Parameter Store entries for DB config (so no secrets in code):
  - /hybrid-demo/db_url
  - /hybrid-demo/db_user
  - /hybrid-demo/db_password

Deploy (Cloud):
- cd terraform/cloud
- terraform init
- terraform apply -var="project_name=hybrid-demo" -var="admin_ip=YOUR_PUBLIC_IP/32"
- After apply, note output alb_dns_name

Deploy (On-Prem simulator):
- cd terraform/onprem
- terraform init
- terraform apply -var="project_name=hybrid-demo" -var="admin_ip=YOUR_PUBLIC_IP/32"

CI/CD Setup:
1) Create SSM Parameters in us-west-1 (SecureString recommended):
   - Name: /hybrid-demo/db_url      Value: jdbc:mysql://YOUR_RDS_OR_ONPREM:3306/joget_db
   - Name: /hybrid-demo/db_user     Value: jogetuser
   - Name: /hybrid-demo/db_password Value: StrongPassword123!
2) In GitHub repo settings > Secrets and variables > Actions, add:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_REGION = us-west-1
   - CD_APP_NAME = hybrid-demo-codedeploy-app
   - CD_DEPLOYMENT_GROUP = hybrid-demo-codedeploy-dg
   - ARTIFACT_BUCKET = (copy terraform output artifact_bucket)
3) Push to main (or open a PR and merge). The workflow:
   - Builds the Java app (joget_app) with Maven
   - Packages appspec.yml + scripts + built JAR
   - Uploads artifact zip to S3
   - Triggers a CodeDeploy in-place deployment to the two EC2 instances

Open the app:
- Health: http://ALB_DNS_NAME/health
- App (proxied): http://ALB_DNS_NAME/app

Teardown:
- Destroy on-prem first: cd terraform/onprem && terraform destroy
- Then cloud: cd terraform/cloud && terraform destroy

Docs:
- docs/QUICKSTART.md: Beginner steps for infra + pipeline
- docs/direct-connect-dms.md: Direct Connect + DMS guide

Security:
- No app secrets in Terraform or user data
- Instance role can read only /hybrid-demo/* SSM parameters (least privilege)
- ALB SG allows 80 from Internet; App SG allows 80 only from ALB SG; Private subnets have no public ingress
- Use ACM + HTTPS on ALB for production
