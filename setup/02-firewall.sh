#!/usr/bin/env bash
set -euo pipefail

# 1. SSH-сервер: установлен, запущен, в автозапуске
sudo apt-get install -y openssh-server ufw
sudo systemctl enable --now ssh

# 2. Политики по умолчанию: всё входящее запрещено, исходящее разрешено
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Разрешаем только SSH (с ограничением частоты подключений) и HTTP
sudo ufw limit 22/tcp comment 'SSH (rate limited)'
sudo ufw allow 80/tcp comment 'HTTP'

# 4. Включаем без интерактивного вопроса
sudo ufw --force enable

sudo ufw status verbose
echo "OK: firewall configured"
