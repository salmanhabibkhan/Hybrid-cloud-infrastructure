#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y openjdk-17-jre apache2 awscli

systemctl enable apache2
systemctl start apache2

# Create a basic health page if not present
mkdir -p /var/www/html
echo "OK" >/var/www/html/health || true