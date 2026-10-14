#!/usr/bin/env bash
# Проверяет итоговое состояние сервера. Код выхода 0, если всё в порядке.
set -uo pipefail
sudo -v || exit 1

fail=0
t() {
    local desc=$1
    shift
    if "$@" >/dev/null 2>&1; then echo "PASS  $desc"; else echo "FAIL  $desc"; fail=1; fi
}

headers()     { curl -sI http://localhost/; }
http_code()   { [[ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost/)" == 200 ]]; }
no_version()  { ! headers | grep -qi '^server:.*[0-9]'; }
has_headers() {
    local h n
    h="$(headers)"
    for n in X-Content-Type-Options X-Frame-Options Referrer-Policy Content-Security-Policy; do
        grep -qi "^$n:" <<<"$h" || return 1
    done
}
ufw_ports()   { sudo ufw status | awk '/ALLOW|LIMIT/ {print $1}' | sort -u | paste -sd,; }
ufw_only()    { [[ "$(ufw_ports)" == "22/tcp,80/tcp" ]]; }
ufw_deny()    { sudo ufw status verbose | grep -q 'deny (incoming)'; }
ufw_active()  { sudo ufw status | grep -q '^Status: active'; }
last_log_ok() { [[ "$(sudo tail -n1 /var/log/nginx-healthcheck/check.log)" == *" OK "* ]]; }

t "nginx active"                      systemctl is-active --quiet nginx
t "nginx enabled at boot"             systemctl is-enabled --quiet nginx
t "nginx config valid"                sudo nginx -t
t "page returns 200"                  http_code
t "Server header has no version"      no_version
t "security headers present"          has_headers
t "ufw active"                        ufw_active
t "ufw default deny incoming"         ufw_deny
t "ufw opens only 22/tcp and 80/tcp"  ufw_only
t "healthcheck timer active"          systemctl is-active --quiet nginx-healthcheck.timer
t "last log line is OK"               last_log_ok

exit $fail
