#!/bin/bash

set -euo pipefail

# Re-exec as root if needed
if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

# Config override via env before running
GITHUB_REPO="${GITHUB_REPO:-salmanhabibkhan/Hybrid-cloud-infrastructure}"
GITHUB_BRANCH="${GITHUB_BRANCH:-}"         # e.g. "main" if you need a specific branch
APP_DIR="${APP_DIR:-/opt/joget_app}"
APP_PORT="${APP_PORT:-8080}"
BIND_ADDRESS="${BIND_ADDRESS:-127.0.0.1}"  # bind app locally; Apache proxies from port 80
JAVA_OPTS="${JAVA_OPTS:-"-Xms256m -Xmx512m"}"

# If any DB var is missing, we install+use local MySQL and seed a sample table
DB_URL="${DB_URL:-}"
DB_USER="${DB_USER:-}"
DB_PASS="${DB_PASS:-}"
SEED_SAMPLE_DATA="${SEED_SAMPLE_DATA:-true}"

log()  { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
err()  { echo "[ERROR] $*" >&2; }

wait_for_port() {
  local host="$1" port="$2" timeout="${3:-60}"
  local start ts
  start=$(date +%s)
  while true; do
    if timeout 1 bash -lc "</dev/tcp/${host}/${port}" 2>/dev/null; then
      return 0
    fi
    ts=$(($(date +%s)-start))
    if (( ts >= timeout )); then
      return 1
    fi
    sleep 1
  done
}

# Packages install
export DEBIAN_FRONTEND=noninteractive
log "Installing Java, Maven, Git, Apache..."
apt-get update -y
apt-get install -y openjdk-17-jdk maven git curl jq apache2

# Database local if external not provided
USE_LOCAL_DB="false"
if [[ -z "$DB_URL" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
  USE_LOCAL_DB="true"
  log "No external DB creds provided; installing local MySQL and preparing database"
  apt-get install -y mysql-server
  systemctl enable --now mysql

  # Create DB + user
  mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS joget_db;
CREATE USER IF NOT EXISTS 'jogetuser'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON joget_db.* TO 'jogetuser'@'localhost';
FLUSH PRIVILEGES;
SQL

  if [[ "$SEED_SAMPLE_DATA" == "true" ]]; then
    mysql joget_db <<'SQL'
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  email VARCHAR(100)
);
INSERT IGNORE INTO users (id, name, email) VALUES
  (1, 'salman', 'salman@example.com'),
  (2, 'habib',  'habib@example.com');
SQL
  fi

  DB_URL="jdbc:mysql://localhost:3306/joget_db"
  DB_USER="jogetuser"
  DB_PASS="StrongPassword123!"
else
  log "Using provided external DB configuration"
fi

# ------------ Clone repository ------------
SRC_DIR="$(mktemp -d)"
if [[ -n "${GITHUB_PAT:-}" ]]; then
  log "Cloning ${GITHUB_REPO} with GitHub PAT"
  git clone "https://${GITHUB_PAT}@github.com/${GITHUB_REPO}.git" "$SRC_DIR"
else
  log "GITHUB_PAT not set. Attempting anonymous clone (repo must be public)."
  git clone "https://github.com/${GITHUB_REPO}.git" "$SRC_DIR"
fi

if [[ -n "$GITHUB_BRANCH" ]]; then
  (cd "$SRC_DIR" && git checkout -q "$GITHUB_BRANCH")
fi

# Detect project directory (prefer nested joget_app/, else repo root if has pom.xml)
PROJECT_DIR="$SRC_DIR/joget_app"
if [[ ! -f "$PROJECT_DIR/pom.xml" ]]; then
  if [[ -f "$SRC_DIR/pom.xml" ]]; then
    PROJECT_DIR="$SRC_DIR"
  else
    err "No pom.xml found in ${PROJECT_DIR} or repo root."
    exit 1
  fi
fi
log "Project directory: $PROJECT_DIR"

# Build with Maven
log "Building the application..."
pushd "$PROJECT_DIR" >/dev/null
mvn -q -DskipTests clean package
JAR_FILE="$(find target -maxdepth 1 -type f -name '*.jar' ! -name '*original*' | head -n 1 || true)"
popd >/dev/null

if [[ -z "${JAR_FILE}" || ! -f "$PROJECT_DIR/${JAR_FILE}" ]]; then
  err "Build failed; no runnable JAR found in target/. Ensure Spring Boot 'repackage' creates an executable jar."
  exit 1
fi

# Install application
log "Installing to ${APP_DIR}"
mkdir -p "$APP_DIR"
cp "$PROJECT_DIR/${JAR_FILE}" "$APP_DIR/app.jar"
chown -R root:root "$APP_DIR"
chmod 755 "$APP_DIR"

# Environment file
ENV_FILE="/etc/joget_app.env"
log "Writing environment file ${ENV_FILE}"
cat > "$ENV_FILE" <<EOF
APP_ENV=onprem
DB_URL=${DB_URL}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
APP_PORT=${APP_PORT}
BIND_ADDRESS=${BIND_ADDRESS}
JAVA_OPTS="${JAVA_OPTS}"
EOF
chmod 600 "$ENV_FILE"

# systemd service 
SERVICE_FILE="/etc/systemd/system/joget-app.service"
log "Creating systemd unit ${SERVICE_FILE}"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Joget Java App (On-Prem)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
EnvironmentFile=${ENV_FILE}
WorkingDirectory=${APP_DIR}
# exec so systemd tracks Java PID; bind to 127.0.0.1 for Apache proxy
ExecStart=/bin/bash -lc 'exec /usr/bin/java \$JAVA_OPTS -jar ${APP_DIR}/app.jar --server.port=\${APP_PORT:-8080} --server.address=\${BIND_ADDRESS:-127.0.0.1}'
Restart=always
RestartSec=5
User=root
StandardOutput=append:/var/log/joget-app.log
StandardError=append:/var/log/joget-app.err

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable joget-app
systemctl restart joget-app

# Apache reverse proxy on port 80
log "Configuring Apache reverse proxy on port 80"
a2enmod proxy proxy_http >/dev/null
APACHE_SITE="/etc/apache2/sites-available/joget.conf"
cat > "$APACHE_SITE" <<EOF
<VirtualHost *:80>
  ServerName _default_
  ProxyPreserveHost On
  ProxyPass        / http://127.0.0.1:${APP_PORT}/
  ProxyPassReverse / http://127.0.0.1:${APP_PORT}/
  ErrorLog \${APACHE_LOG_DIR}/joget_error.log
  CustomLog \${APACHE_LOG_DIR}/joget_access.log combined
</VirtualHost>
EOF

# Disable default site, enable our site, reload Apache
a2dissite 000-default >/dev/null 2>&1 || true
a2ensite joget >/dev/null
systemctl reload apache2

log "Apache virtual hosts:"
apache2ctl -S || true

# Verify startup
log "Waiting for app to listen on 127.0.0.1:${APP_PORT} (up to 60s)..."
if wait_for_port "127.0.0.1" "${APP_PORT}" 60; then
  log "App port is open."
else
  warn "Port ${APP_PORT} not open after 60s. Showing last logs:"
  journalctl -u joget-app -n 120 --no-pager || true
fi

log "Smoke tests:"
set +e
echo "- Direct app (loopback):"
curl -fsS "http://127.0.0.1:${APP_PORT}/" | head -n 1 || echo "Failed"
curl -fsS "http://127.0.0.1:${APP_PORT}/users" | head -n 1 || echo "Failed"

echo "- Via Apache (port 80):"
curl -fsS "http://127.0.0.1/" | head -n 1 || echo "Failed"
set -e

log "Service status (summary):"
systemctl --no-pager --full status joget-app || true

log "Done. Access your app at: http://<server_public_ip>/"
log "Logs: /var/log/joget-app.log and /var/log/joget-app.err"