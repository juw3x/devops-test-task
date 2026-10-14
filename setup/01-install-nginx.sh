#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo apt-get update
sudo apt-get install -y nginx

sudo install -d -m 755 /var/www/site
sudo install -m 644 "$REPO_DIR/www/index.html" "$REPO_DIR/www/style.css" /var/www/site/
sudo install -m 644 "$REPO_DIR/nginx/site.conf" /etc/nginx/sites-available/site.conf

sudo ln -sf /etc/nginx/sites-available/site.conf /etc/nginx/sites-enabled/site.conf
sudo rm -f /etc/nginx/sites-enabled/default

sudo sed -i "s/^\([[:space:]]*\)server_tokens build;/\1server_tokens off;/" /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx
echo "OK: nginx configured"
