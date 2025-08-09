CREATE DATABASE joget_db;

USE joget_db;

CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO users (name, email) VALUES ('salman', 'salman@example.com');
INSERT INTO users (name, email) VALUES ('habib', 'habib@example.com');

---------------
#!/bin/bash
set -e

# 1. Setup Static IP (assuming netplan)
cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses: [192.168.10.10/24]
      gateway4: 192.168.10.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
EOF

sudo netplan apply
echo "Static IP configured."

# 2. Setup firewall with UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22
sudo ufw allow 80
# Allow MySQL only from subnet or add your AWS EC2 public IP
sudo ufw allow from 192.168.10.0/24 to any port 3306
sudo ufw enable
echo "Firewall configured."

# 3. Install Java (OpenJDK 17)
sudo apt update
sudo apt install -y openjdk-17-jdk
echo "Java installed."

# 4. Install MySQL server
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
echo "MySQL installed and running."

# 5. Secure MySQL Installation (basic, manual input required)
echo "Run 'sudo mysql_secure_installation' to secure MySQL."

# 6. Clone your app code from GitHub (replace repo URL)
if [ ! -d ~/joget_app ]; then
  git clone https://github.com/yourusername/joget_app.git ~/joget_app
else
  cd ~/joget_app && git pull
fi
echo "App code cloned."

# 7. Build your Java app (assuming Maven installed)
cd ~/joget_app
mvn clean package
echo "App built."

# 8. Run your Java app (adjust as needed)
java -jar target/joget_app-1.0-SNAPSHOT.jar &
echo "App started."

echo "Setup complete."

---------------------
chmod +x setup_onprem.sh
./setup_onprem.sh