#!/usr/bin/env bash
# Proves the lab environment is gone. Run with: sudo ./verify-teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify-teardown.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user() { ! id "$1" >/dev/null 2>&1; }
no_group() { ! getent group "$1" >/dev/null 2>&1; }
no_path() { [ ! -e "$1" ]; }
no_proc() { ! pgrep -f "$1" >/dev/null 2>&1; }
no_listener() { ! ss -ltn 2>/dev/null | grep -qE ":$1\\b"; }

S="${SUDO_USER:-}"
check "user deploy is gone" no_user deploy
check "the lab SSH daemon is not running (port 2222 free)" no_listener 2222
check "the private dashboard is stopped" no_proc 'clippy-lab/dashboard.py'
check "/etc/clippy-lab is gone" no_path /etc/clippy-lab
check "/var/lib/clippy-lab is gone" no_path /var/lib/clippy-lab
check "your ~/.ssh/config no longer has the clippy-staging block" bash -c "! grep -qi 'clippy-staging' /home/$S/.ssh/config 2>/dev/null"
check "your known_hosts no longer lists [127.0.0.1]:2222" bash -c "! grep -q '\\[127.0.0.1\\]:2222' /home/$S/.ssh/known_hosts 2>/dev/null"
check "no tunnel to the lab dashboard is left open (port 8000)" no_listener 8000

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
