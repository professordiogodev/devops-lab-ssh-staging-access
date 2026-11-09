#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
[ -f /run/clippy-sshd.pid ] && kill "$(cat /run/clippy-sshd.pid)" 2>/dev/null
pkill -f '/var/lib/clippy-lab/dashboard.py' 2>/dev/null
pkill -KILL -u deploy 2>/dev/null; sleep 1
userdel -rf deploy 2>/dev/null
rm -rf /etc/clippy-lab /var/lib/clippy-lab /var/log/clippy-sshd.log /run/clippy-sshd.pid
echo "Lab environment removed. (Your own keys in ~/.ssh were not touched.)"
