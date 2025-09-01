#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y ruby wget snapd

# Install SSM Agent (bastionless access)
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Install CodeDeploy agent
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region || \
        (curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}'))
cd /tmp
wget "https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install" -O codedeploy-install
chmod +x codedeploy-install
./codedeploy-install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Default health page for ALB checks until first deployment
mkdir -p /var/www/html
echo "OK" > /var/www/html/health