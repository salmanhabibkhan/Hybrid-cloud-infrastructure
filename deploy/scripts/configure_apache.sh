#!/bin/bash
set -euxo pipefail

APP_PORT="${APP_PORT:-8080}"

a2enmod proxy proxy_http headers rewrite

cat >/etc/apache2/sites-available/app.conf <<EOF
<VirtualHost *:80>
    ServerName _
    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass /app http://127.0.0.1:${APP_PORT}/
    ProxyPassReverse /app http://127.0.0.1:${APP_PORT}/

    # Static health endpoint
    Alias /health /var/www/html/health

    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/app_error.log
    CustomLog \${APACHE_LOG_DIR}/app_access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite app.conf
systemctl reload apache2