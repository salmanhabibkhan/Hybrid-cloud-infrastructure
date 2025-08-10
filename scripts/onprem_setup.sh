#!/bin/bash
set -e

# ---------------------------
# 1. Install System Packages
# ---------------------------
echo "[INFO] Updating system and installing packages..."
sudo apt update && sudo apt install -y openjdk-17-jdk maven mysql-server git ufw

# ---------------------------
# 2. Configure Firewall
# ---------------------------
echo "[INFO] Configuring UFW firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 3306  # MySQL
sudo ufw --force enable

# ---------------------------
# 3. Start and Secure MySQL
# ---------------------------
echo "[INFO] Starting MySQL..."
sudo systemctl start mysql
sudo systemctl enable mysql

echo "[INFO] Securing MySQL and creating database, user, and table..."
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

# ---------------------------
# 4. Clone Java App from GitHub (Private Repo via PAT)
# ---------------------------
GITHUB_PAT="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"   # <-- 🔒 REPLACE THIS
GITHUB_REPO="salmanhabibkhan/Hybrid-cloud-infrastructure"

echo "[INFO] Cloning Java application from GitHub..."
if [ -d ~/joget_app ]; then
  echo "[INFO] Directory exists. Pulling latest changes..."
  cd ~/joget_app/joget_app && git pull
else
  git clone https://${GITHUB_PAT}@github.com/${GITHUB_REPO}.git ~/joget_app/joget_app
fi

# ---------------------------
# 6. Build Java App with Maven
# ---------------------------
echo "[INFO] Building Java application..."
mvn clean package

# ---------------------------
# 7. Run the App in Background
# ---------------------------
echo "[INFO] Running Java application in background..."
nohup java -jar target/joget_app-1.0-SNAPSHOT.jar > ~/joget_app/app.log 2>&1 &

echo "[✅] Setup complete. Application is running."
