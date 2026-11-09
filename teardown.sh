#!/usr/bin/env bash
# Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
[ -f /run/clipstr-sshd.pid ] && kill "$(cat /run/clipstr-sshd.pid)" 2>/dev/null
pkill -f '/var/lib/clipstr-lab/dashboard.py' 2>/dev/null
userdel -r deploy 2>/dev/null
rm -rf /etc/clipstr-lab /var/lib/clipstr-lab /var/log/clipstr-sshd.log /run/clipstr-sshd.pid
echo "Lab environment removed. (Your own keys in ~/.ssh were not touched.)"
