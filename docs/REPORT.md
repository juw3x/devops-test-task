# Отчёт

Репозиторий: https://github.com/juw3x/devops-test-task
Скрипт проверки: `scripts/check_page.sh`. Журнал работы с вводом и выводом команд: `docs/WORKLOG.md`. Пример лога: `docs/sample-check.log`.

## Среда
Ubuntu в WSL2, сеть NAT (`wslinfo --networking-mode`: nat), ядро `6.18.40.1-microsoft-standard-WSL2`, nginx 1.28.3. Это не классическая ВМ, ограничения описаны в конце.

## Что сделано
1. **Nginx и страница** (`setup/01-install-nginx.sh`): отдельный server-блок `nginx/site.conf`, страница и CSS в `/var/www/site`, заголовки безопасности (X-Content-Type-Options, X-Frame-Options, Referrer-Policy, CSP), `/healthz`, `server_tokens off`. Скрипт идемпотентный.
2. **Firewall** (`setup/02-firewall.sh`): UFW, `default deny incoming`, `limit 22/tcp`, `allow 80/tcp`, IPv4 и IPv6.
3. **Проверка доступности** (`scripts/check_page.sh`, `setup/03-healthcheck.sh`): проверяет код 200 и текст на странице, пишет строку с датой ISO 8601 в `/var/log/nginx-healthcheck/check.log`. Запуск раз в минуту через systemd timer, ротация через logrotate (14 файлов).
4. **Качество**: тесты скрипта (`tests/test_check_page.sh`), самопроверка сервера (`scripts/verify.sh`), ShellCheck, `Makefile`, GitHub Actions (runner закреплён на ubuntu-24.04).

## Основные команды
    ./setup/01-install-nginx.sh
    ./setup/02-firewall.sh
    ./setup/03-healthcheck.sh
    sudo systemctl start nginx-healthcheck.service
    sudo tail /var/log/nginx-healthcheck/check.log
    make lint test verify

## Как проверено (факты из вывода команд)
- Страница: `curl -i` (200), `curl -sI` (4 заголовка безопасности, `Server: nginx` без версии), `/healthz` отвечает `ok`.
- UFW: `ufw status verbose`
