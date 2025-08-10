#!/bin/bash
set -e

# -------------------------------
# Configuration: Edit as needed
# -------------------------------
APP_ENV="${APP_ENV:-local}"  # Change to "aws" for RDS, or export before running
APP_DIR=~/joget_app
GITHUB_PAT="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"
GITHUB_REPO="salmanhabibkhan/Hybrid-cloud-infrastructure"

# -------------------------------
# DB Config Based on Environment
# -------------------------------
if [ "$APP_ENV" == "aws" ]; then
  export DB_URL="jdbc:mysql://java-application-database.c5uk4wgsw6a3.us-east-2.rds.amazonaws.com:3306/joget_db"
  export DB_USER="jogetuser"
  export DB_PASS='StrongPassword123!'  # Consider using AWS SSM or Secrets Manager
  echo "[INFO] Environment: AWS (RDS)"
else
  export DB_URL="jdbc:mysql://localhost:3306/joget_db"
  export DB_USER="jogetuser"
  export DB_PASS='StrongPassword123!'
  echo "[INFO] Environment: Local"
fi

# -------------------------------
# 1. Install Required Packages
# -------------------------------
echo "[INFO] Installing system packages..."
sudo apt update && sudo apt install -y openjdk-17-jdk maven mysql-server git ufw

# -------------------------------
# 2. Configure UFW
# -------------------------------
echo "[INFO] Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 3306
sudo ufw --force enable

# -------------------------------
# 3. Start MySQL (only local)
# -------------------------------
if [ "$APP_ENV" == "local" ]; then
  echo "[INFO] Starting and configuring local MySQL..."
  sudo systemctl start mysql
  sudo systemctl enable mysql

  sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS joget_db;

CREATE USER IF NOT EXISTS 'jogetuser'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON joget_db.* TO 'jogetuser'@'localhost';
FLUSH PRIVILEGES;

USE joget_db;

CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT IGNORE INTO users (name, email) VALUES ('salman', 'salman@example.com');
INSERT IGNORE INTO users (name, email) VALUES ('habib', 'habib@example.com');
EOF
fi

# -------------------------------
# 4. Clone App Repo
# -------------------------------
echo "[INFO] Cloning Java application..."
if [ ! -d "$APP_DIR/.git" ]; then
  rm -rf /tmp/joget_repo
  git clone https://${GITHUB_PAT}@github.com/${GITHUB_REPO}.git /tmp/joget_repo

  echo "[INFO] Moving nested joget_app folder to $APP_DIR"
  rm -rf "$APP_DIR"
  mv /tmp/joget_repo/joget_app "$APP_DIR"
  rm -rf /tmp/joget_repo
else
  echo "[INFO] Pulling latest changes..."
  cd "$APP_DIR"
  git pull
fi

# -------------------------------
# 5. Build the Java App
# -------------------------------
echo "[INFO] Building the app..."
cd "$APP_DIR"
mvn clean package

# -------------------------------
# 6. Run App in Background
# -------------------------------
JAR_FILE=$(find target -name "*.jar" | grep -v original | head -n 1)

if [ -f "$JAR_FILE" ]; then
  echo "[INFO] Running the app in background..."
  nohup java -jar "$JAR_FILE" > "$APP_DIR/app.log" 2>&1 &
  echo "[✅] App started. Check logs with: tail -f $APP_DIR/app.log"
else
  echo "[❌] JAR not found. Build might have failed."
  exit 1
fi
