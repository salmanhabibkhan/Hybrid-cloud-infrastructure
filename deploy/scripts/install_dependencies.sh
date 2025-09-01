#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y openjdk-17-jre apache2 awscli curl

# Ensure app dir exists for the JAR
mkdir -p /opt/joget_app
chown -R root:root /opt/joget_app

systemctl enable apache2
systemctl start apache2

# Create a basic health page so ALB health checks pass during deployment
mkdir -p /var/www/html
echo "OK" >/var/www/html/health || true