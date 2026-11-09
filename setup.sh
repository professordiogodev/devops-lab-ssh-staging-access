#!/usr/bin/env bash
# Creates the "staging server": a second SSH daemon on port 2222. Run with: sudo ./setup.sh (safe to re-run)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
[ -n "${SUDO_USER:-}" ] || { echo "Run it with sudo from your normal user, not from a root shell" >&2; exit 1; }
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq openssh-server openssh-client python3 rsync >/dev/null
./teardown.sh >/dev/null 2>&1 || true

mkdir -p /etc/clipstr-lab /run/sshd /var/lib/clipstr-lab
ssh-keygen -A >/dev/null
cat > /etc/clipstr-lab/sshd_config <<'C'
# Staging server SSH daemon (second instance, port 2222)
Port 2222
ListenAddress 127.0.0.1
HostKey /etc/ssh/ssh_host_ed25519_key
PidFile /run/clipstr-sshd.pid
LogLevel VERBOSE
UsePAM yes
StrictModes yes
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin yes
X11Forwarding yes
AllowTcpForwarding yes
Subsystem sftp internal-sftp
C
# the staging user
id deploy >/dev/null 2>&1 || useradd -m -s /bin/bash deploy
echo 'deploy:clipstr-deploy' | chpasswd
mkdir -p /home/deploy/.ssh /home/deploy/uploads
touch /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh /home/deploy/uploads
chmod 777 /home/deploy/.ssh          # somebody "fixed" a permission problem once
chmod 600 /home/deploy/.ssh/authorized_keys

# a private dashboard that is not meant to be reachable from outside
tok="dash-$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')"
echo "$tok" > /var/lib/clipstr-lab/token; chmod 644 /var/lib/clipstr-lab/token
cat > /var/lib/clipstr-lab/dashboard.py <<'P'
import http.server, socketserver
tok = open("/var/lib/clipstr-lab/token").read().strip()
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        b = f"Clipstr internal dashboard. Secret token: {tok}\n".encode()
        self.send_response(200); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
http.server.HTTPServer(("127.0.0.2", 9000), H).serve_forever()
P
setsid nohup sudo -u deploy python3 /var/lib/clipstr-lab/dashboard.py >/dev/null 2>&1 &
# a release to transfer, owned by the student
mkdir -p "$PWD/release"; head -c 300000 /dev/urandom > release/clipstr-1.4.0.tar.gz
chown -R "$SUDO_USER" release; sha256sum release/clipstr-1.4.0.tar.gz | cut -d' ' -f1 > /var/lib/clipstr-lab/release.sha
echo "$SUDO_USER" > /var/lib/clipstr-lab/student
/usr/sbin/sshd -f /etc/clipstr-lab/sshd_config -E /var/log/clipstr-sshd.log
sleep 1
echo "Staging server is up on 127.0.0.1 port 2222. User: deploy   Password: clipstr-deploy"
echo "Server log: sudo tail -f /var/log/clipstr-sshd.log"
