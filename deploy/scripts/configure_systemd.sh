#!/bin/bash
set -euxo pipefail

APP_DIR="/opt/joget_app"
APP_JAR="$APP_DIR/app.jar"
APP_PORT="${APP_PORT:-8080}"

# Fetch DB secrets from SSM Parameter Store (must exist)
DB_URL=$(aws ssm get-parameter --name "/hybrid-demo/db_url" --with-decryption --query 'Parameter.Value' --output text || true)
DB_USER=$(aws ssm get-parameter --name "/hybrid-demo/db_user" --with-decryption --query 'Parameter.Value' --output text || true)
DB_PASS=$(aws ssm get-parameter --name "/hybrid-demo/db_password" --with-decryption --query 'Parameter.Value' --output text || true)

cat >/etc/joget_app.env <<EOF
APP_ENV=aws
DB_URL=${DB_URL}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
APP_PORT=${APP_PORT}
JAVA_OPTS=-Xms256m -Xmx512m
EOF
chmod 600 /etc/joget_app.env

cat >/etc/systemd/system/joget-app.service <<EOF
[Unit]
Description=Joget Java App
After=network.target apache2.service
Wants=apache2.service

[Service]
Type=simple
EnvironmentFile=/etc/joget_app.env
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/java \$JAVA_OPTS -jar ${APP_JAR} --server.port=\${APP_PORT}
Restart=always
RestartSec=5
User=root
StandardOutput=append:/var/log/joget-app.log
StandardError=append:/var/log/joget-app.err

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable joget-app.service