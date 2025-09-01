# QuickStart: Infra + CI/CD

Goal: Infra via Terraform; App via CI/CD. No app config in Terraform.

1) Deploy Cloud Infra (us-west-1)
- cd terraform/cloud
- terraform init
- terraform apply -var="project_name=hybrid-demo" -var="admin_ip=YOUR_PUBLIC_IP/32"
- Save outputs:
  - alb_dns_name
  - artifact_bucket

2) Create DB Secrets in SSM Parameter Store (us-west-1)
- /hybrid-demo/db_url      jdbc:mysql://YOUR_RDS_OR_ONPREM:3306/joget_db
- /hybrid-demo/db_user     jogetuser
- /hybrid-demo/db_password StrongPassword123!
Type: SecureString recommended.

3) Configure GitHub Actions Secrets
- In repo Settings > Secrets and variables > Actions:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  - AWS_REGION = us-west-1
  - ARTIFACT_BUCKET = (terraform output)
  - CD_APP_NAME = hybrid-demo-codedeploy-app
  - CD_DEPLOYMENT_GROUP = hybrid-demo-codedeploy-dg

4) Deploy On-Prem Simulator (optional)
- cd terraform/onprem
- terraform init
- terraform apply -var="project_name=hybrid-demo" -var="admin_ip=YOUR_PUBLIC_IP/32"

5) Push Code to Trigger CI/CD
- Commit/push your Java app under joget_app/
- On push to main:
  - Build with Maven
  - Package JAR + appspec.yml + scripts
  - Upload to S3
  - CodeDeploy rolls out to the two EC2s

6) Open the App
- Health: http://ALB_DNS_NAME/health (returns OK)
- App:    http://ALB_DNS_NAME/app

7) Troubleshooting
- CodeDeploy Console: view deployment logs
- Instance logs:
  - /var/log/cloud-init-output.log
  - /var/log/aws/codedeploy-agent/codedeploy-agent.log
  - /var/log/apache2/*
  - journalctl -u joget-app
- ALB targets unhealthy:
  - First deploy may take a few minutes
  - Ensure Security Group of RDS allows ingress 3306 from App SG (if using RDS)

8) Change DB Target (after DMS cutover)
- Update SSM parameters (db_url etc.)
- Re-deploy (push to main) to have instances read new values during deployment