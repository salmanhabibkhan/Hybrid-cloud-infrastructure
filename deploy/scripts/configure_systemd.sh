#!/bin/bash
set -euxo pipefail

APP_DIR="/opt/joget_app"
APP_JAR="$APP_DIR/app.jar"
APP_PORT="${APP_PORT:-8080}"
AWS_REGION="${AWS_REGION:-us-west-1}"
REQUIRE_DB_PARAMS="${REQUIRE_DB_PARAMS:-false}"  # set to true to fail deploy if DB params missing

# Default DB credentials if SSM params missing
DEFAULT_DB_URL="jdbc:mysql://joget-application-test-db.ci3uqk0e23dz.us-east-1.rds.amazonaws.com:3306/joget_db"
DEFAULT_DB_USER="jogetuser"
DEFAULT_DB_PASS="StrongPassword123!"

# Helper to fetch SSM param (tries SecureString first)
get_param() {
  local name="$1"
  aws ssm get-parameter --name "$name" --with-decryption --query 'Parameter.Value' --output text --region "$AWS_REGION" 2>/dev/null || \
  aws ssm get-parameter --name "$name" --query 'Parameter.Value' --output text --region "$AWS_REGION"
}

DB_URL="$(get_param "/hybrid-cloud-joget/db_url" || true)"
DB_USER="$(get_param "/hybrid-cloud-joget/db_user" || true)"
DB_PASS="$(get_param "/hybrid-cloud-joget/db_password" || true)"

# Use default values if params are empty
DB_URL="${DB_URL:-$DEFAULT_DB_URL}"
DB_USER="${DB_USER:-$DEFAULT_DB_USER}"
DB_PASS="${DB_PASS:-$DEFAULT_DB_PASS}"

if [ "$REQUIRE_DB_PARAMS" = "true" ]; then
  if [ -z "$DB_URL" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    echo "ERROR: Required DB SSM parameters are missing. Aborting." >&2
    exit 1
  fi
fi

# Write environment file (keep JAVA_OPTS on a single quoted line)
cat >/etc/joget_app.env <<EOF
APP_ENV=aws
DB_URL=${DB_URL}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
APP_PORT=${APP_PORT}
JAVA_OPTS="-Xms256m -Xmx512m"
EOF
chmod 600 /etc/joget_app.env

# Systemd unit; use a shell so \${APP_PORT} expands at runtime
cat >/etc/systemd/system/joget-app.service <<'EOF'
[Unit]
Description=Joget Java App
After=network.target apache2.service
Wants=apache2.service

[Service]
Type=simple
EnvironmentFile=/etc/joget_app.env
WorkingDirectory=/opt/joget_app
ExecStart=/bin/bash -lc '/usr/bin/java $JAVA_OPTS -jar /opt/joget_app/app.jar --server.port=${APP_PORT:-8080}'
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

# Apache reverse proxy to the app on current APP_PORT
a2enmod proxy proxy_http || true
cat >/etc/apache2/sites-available/app-proxy.conf <<EOF
<VirtualHost *:80>
  ProxyPreserveHost On
  ProxyPass /app http://127.0.0.1:${APP_PORT}/
  ProxyPassReverse /app http://127.0.0.1:${APP_PORT}/
  ErrorLog \${APACHE_LOG_DIR}/app_error.log
  CustomLog \${APACHE_LOG_DIR}/app_access.log combined
</VirtualHost>
EOF

a2ensite app-proxy || true
systemctl reload apache2
