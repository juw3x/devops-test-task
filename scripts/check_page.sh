#!/usr/bin/env bash
# Проверяет доступность страницы и пишет результат в лог.
# Код выхода: 0 = OK, 1 = страница недоступна или содержимое не то, 2 = лог недоступен для записи.
set -uo pipefail

URL="${CHECK_URL:-http://localhost/}"
LOG_FILE="${LOG_FILE:-/var/log/nginx-healthcheck/check.log}"
TIMEOUT="${TIMEOUT:-5}"
EXPECTED="${EXPECTED:-Hello from Nginx}"

body="$(mktemp)"
trap 'rm -f "$body"' EXIT

out="$(curl -s -o "$body" --max-time "$TIMEOUT" -w '%{http_code} %{time_total}' "$URL")"
curl_rc=$?
read -r code time_total <<<"$out"

status="FAIL"
reason=""
if [[ $curl_rc -ne 0 ]]; then
    reason="curl_exit=$curl_rc"
elif [[ "$code" != "200" ]]; then
    reason="unexpected_http_code"
elif ! grep -qF -- "$EXPECTED" "$body"; then
    reason="unexpected_content"
else
    status="OK"
fi

line="$(date --iso-8601=seconds) $status url=$URL http_code=$code time=${time_total}s${reason:+ reason=$reason}"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
if ! echo "$line" >> "$LOG_FILE"; then
    echo "ERROR: cannot write to $LOG_FILE" >&2
    echo "$line"
    exit 2
fi

echo "$line"
[[ "$status" == "OK" ]]
