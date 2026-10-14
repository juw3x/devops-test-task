#!/usr/bin/env bash
# Тесты scripts/check_page.sh на временном локальном веб-сервере (root не нужен).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

SCRIPT=scripts/check_page.sh
srv=""
tmp="$(mktemp -d)"
trap '[[ -n "$srv" ]] && kill "$srv" 2>/dev/null; rm -rf "$tmp"' EXIT

mkdir "$tmp/www"
echo "Hello from Nginx" > "$tmp/www/index.html"
port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmp/www" >/dev/null 2>&1 &
srv=$!
for _ in $(seq 25); do
    curl -s -o /dev/null "http://127.0.0.1:$port/" && break
    sleep 0.2
done

fail=0
# check <имя> <ожидаемый код выхода> <regexp в логе или -> [VAR=значение ...]
check() {
    local name=$1 want_rc=$2 want_re=$3
    shift 3
    local log="$tmp/$name.log"
    env LOG_FILE="$log" TIMEOUT=2 "$@" "$SCRIPT" >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq $want_rc ]] && { [[ $want_re == - ]] || grep -Eq -- "$want_re" "$log"; }; then
        echo "PASS  $name"
    else
        echo "FAIL  $name (exit=$rc)"
        fail=1
    fi
}

base="http://127.0.0.1:$port"
check ok               0 ' OK .*http_code=200'          CHECK_URL="$base/"
check wrong_content    1 'reason=unexpected_content'    CHECK_URL="$base/" EXPECTED="no such text"
check http_404         1 'reason=unexpected_http_code'  CHECK_URL="$base/missing"
check connection_refused 1 'reason=curl_exit=7'         CHECK_URL="http://127.0.0.1:1/"
check log_not_writable 2 -                              CHECK_URL="$base/" LOG_FILE=/proc/nonexistent/x.log

exit $fail
