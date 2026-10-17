# Настройка Nginx и Reverse Proxy (Локальная среда)

## Архитектура
Для проекта была выбрана архитектура разделения ролей внутри одного конфигурационного файла Nginx. Мы создали два виртуальных сервера:
1. **Backend ("Работяга" на порту 8080):** Отвечает за чтение файлов (HTML/CSS/JS) из директории проекта и формирование страниц.
2. **Reverse Proxy ("Курьер" на порту 80):** Принимает все внешние запросы из интернета и прозрачно перенаправляет их на порт 8080. Сам файлы не читает.

## 1. Конфигурация Nginx (`site.conf`)
Файл конфигурации хранится прямо в директории проекта (например, `~/devops-test-task/nginx/site.conf`). 

В нем прописаны оба сервера:

```nginx
# ==========================================================
# 1. Reverse Proxy: принимает внешние запросы на порт 80
# ==========================================================
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Заголовки безопасности
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Content-Security-Policy "default-src 'self'" always;

    # Проксирование трафика на локальный порт 8080
    location / {
        proxy_pass [http://127.0.0.1:8080](http://127.0.0.1:8080);

        # Передача оригинальных заголовков клиента бэкенду
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# ==========================================================
# 2. Локальный сервер: слушает порт 8080 и отдает файлы
# ==========================================================
server {
    listen 8080;
    listen [::]:8080;
    server_name localhost;

    # Путь к физическим файлам сайта
    root /home/juwex/devops-test-task/www; 
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
2. Активация конфигурации
Для того чтобы Nginx увидел конфигурацию из папки проекта, создается символическая ссылка в системную директорию sites-enabled:

Bash
# Удаляем старые дефолтные ссылки, если есть
sudo rm /etc/nginx/sites-enabled/*

# Создаем новую ссылку (симлинк)
sudo ln -s /home/juwex/devops-test-task/nginx/site.conf /etc/nginx/sites-enabled/site.conf
3. Выдача прав и перезапуск
Nginx работает от системного пользователя, поэтому ему нужны права на чтение директории с проектом:

Bash
chmod -R 755 /home/juwex/devops-test-task
Проверка конфигурации на ошибки и перезапуск службы веб-сервера:

Bash
sudo nginx -t
sudo systemctl restart nginx
4. Проброс в интернет (Туннелирование)
Чтобы локальный сервер был доступен извне (без покупки статического IP и проброса портов на роутере), используется Cloudflare Tunnel.

Запуск туннеля на основной порт Nginx:

Bash
cloudflared tunnel --url http://localhost:80
В консоли появится публичная HTTPS-ссылка вида https://...trycloudflare.com. Запрос по ней пойдет на порт 80 (Reverse Proxy), а оттуда Nginx сам перекинет его на 8080.

Важно: Пока используется локальная машина, компьютер должен быть включен, а процесс cloudflared запущен в терминале. Для работы в режиме 24/7 эту же конфигурацию необходимо развернуть на арендованном VPS-сервере.
