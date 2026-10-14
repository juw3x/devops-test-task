#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo install -m 755 "$REPO_DIR/scripts/check_page.sh" /usr/local/bin/nginx-healthcheck
sudo install -m 644 "$REPO_DIR/systemd/nginx-healthcheck.service" /etc/systemd/system/
sudo install -m 644 "$REPO_DIR/systemd/nginx-healthcheck.timer" /etc/systemd/system/
sudo install -m 644 "$REPO_DIR/logrotate/nginx-healthcheck" /etc/logrotate.d/nginx-healthcheck

sudo systemctl daemon-reload
sudo systemctl enable --now nginx-healthcheck.timer

systemctl list-timers nginx-healthcheck.timer --no-pager
echo "OK: healthcheck installed"
