#!/bin/bash
# Run once on the Oracle Cloud VM (Ubuntu 22.04)
# ssh ubuntu@54.204.121.159 "bash -s" < scripts/server-setup.sh

set -e

echo "=== CYBERCOM CyShop Server Setup ==="

# 1. Update & install Nginx
sudo apt-get update -y
sudo apt-get install -y nginx

# 2. Create web root
sudo mkdir -p /var/www/cyshop
sudo chown -R $USER:$USER /var/www/cyshop

# 3. Install Nginx site config
sudo tee /etc/nginx/sites-available/cyshop > /dev/null <<'NGINXCONF'
server {
    listen 80;
    server_name cyshop.cy-com.com;

    root /var/www/cyshop;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 256;
}
NGINXCONF

# 4. Enable site
sudo ln -sf /etc/nginx/sites-available/cyshop /etc/nginx/sites-enabled/cyshop
sudo rm -f /etc/nginx/sites-enabled/default

# 5. Allow passwordless nginx reload for deploy user
echo "$USER ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx" | sudo tee /etc/sudoers.d/nginx-reload

# 6. Test and start Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 7. Open firewall ports (OCI requires both ufw AND OCI Security List)
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

echo ""
echo "=== Setup complete ==="
echo "Now open OCI Console → VCN → Security Lists → add Ingress rule:"
echo "  Port 80  (HTTP)  from 0.0.0.0/0"
echo "  Port 443 (HTTPS) from 0.0.0.0/0"
echo ""
echo "DNS: Add A record  cyshop  →  54.204.121.159  TTL 600"
