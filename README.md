# nginx-healthcheck

Тестовое задание DevOps: Nginx с простой страницей, firewall (UFW) с открытыми только SSH и HTTP, Bash-скрипт проверки доступности страницы с записью в лог.

## Структура

    setup/01-install-nginx.sh      установка Nginx, страница, security-заголовки
    setup/02-firewall.sh           UFW: deny incoming, limit 22/tcp, allow 80/tcp
    setup/03-healthcheck.sh        установка скрипта, systemd timer, logrotate
    scripts/check_page.sh          скрипт проверки (основной артефакт задания)
    nginx/site.conf                server-блок
    systemd/                       service и timer (запуск раз в минуту)
    logrotate/nginx-healthcheck    ротация лога, 14 файлов
    www/                           index.html, style.css
    docs/WORKLOG.md                журнал работы, в том числе ошибки ИИ
    docs/sample-check.log          пример реального лога

## Запуск

    git clone <repo-url> && cd <repo>
    ./setup/01-install-nginx.sh
    ./setup/02-firewall.sh
    ./setup/03-healthcheck.sh

Скрипты можно запускать повторно.

## Проверка

    curl -i http://localhost/
    curl -s http://localhost/healthz
    sudo ufw status verbose
    sudo systemctl start nginx-healthcheck.service
    sudo tail /var/log/nginx-healthcheck/check.log

## Скрипт проверки

Проверяет HTTP-код 200 и наличие текста на странице. Формат строки лога:

    2026-10-14T11:05:51+07:00 OK url=http://localhost/ http_code=200 time=0.002968s

При сбое статус `FAIL` и поле `reason=`. Код выхода: 0 успех, 1 сбой проверки, 2 лог недоступен для записи. Параметры задаются переменными окружения `CHECK_URL`, `LOG_FILE`, `TIMEOUT`, `EXPECTED`.

## Ограничения

- Проверялось в WSL2 с сетевым режимом NAT, поэтому доступность портов с другой машины в сети не проверялась.
- Проверка страницы идёт через localhost, то есть правила UFW она не проверяет.
- `server_tokens` меняется правкой `/etc/nginx/nginx.conf` из пакета, при обновлении пакета возможен конфликт конфигурации.

Проверено на: Ubuntu 26.04.1 LTS, ядро 6.18.40.1-microsoft-standard-WSL2, nginx 1.28.3.
