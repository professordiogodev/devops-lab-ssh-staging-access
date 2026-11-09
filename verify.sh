#!/usr/bin/env bash
# Run with: sudo ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify.sh" >&2; exit 1; }
[ -f /var/lib/clippy-lab/student ] || { echo "Run sudo ./setup.sh first"; exit 1; }
S=$(cat /var/lib/clippy-lab/student)
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
cfg() { sshd -T -f /etc/clippy-lab/sshd_config 2>/dev/null | grep -i "^$1 " ; }
as_s() { sudo -u "$S" -H "$@"; }

echo "== Key-based login =="
check "you have a key pair (ed25519 or rsa) in ~/.ssh"          bash -c "ls /home/$S/.ssh/id_ed25519 /home/$S/.ssh/id_rsa 2>/dev/null | grep -q ."
check "your private key is mode 600"                            bash -c "for f in /home/$S/.ssh/id_ed25519 /home/$S/.ssh/id_rsa; do [ -f \$f ] && [ \"\$(stat -c %a \$f)\" = 600 ] && exit 0; done; exit 1"
check "~/.ssh/config has the alias clippy-staging"             bash -c "grep -qi '^Host clippy-staging' /home/$S/.ssh/config"
check "ssh clippy-staging works with NO password (BatchMode)"  as_s ssh -o BatchMode=yes -o ConnectTimeout=5 clippy-staging true
check "the server's .ssh directory is 700 and authorized_keys 600" bash -c "[ \"\$(stat -c %a /home/deploy/.ssh)\" = 700 ] && [ \"\$(stat -c %a /home/deploy/.ssh/authorized_keys)\" = 600 ]"

echo "== Hardening =="
check "password login is disabled in the config"                bash -c "$(declare -f cfg); cfg passwordauthentication | grep -qi ' no'"
check "keyboard-interactive login is disabled too (PAM can bring passwords back)" bash -c "$(declare -f cfg); cfg kbdinteractiveauthentication | grep -qi ' no'"
check "root login is disabled in the config"                    bash -c "$(declare -f cfg); cfg permitrootlogin | grep -qi ' no'"
check "only deploy may log in (AllowUsers)"                     bash -c "$(declare -f cfg); cfg allowusers | grep -qi 'deploy'"
check "X11 forwarding is off"                                   bash -c "$(declare -f cfg); cfg x11forwarding | grep -qi ' no'"
sleep 1
check "the RUNNING daemon refuses passwords (you reloaded it)"  bash -c "for i in 1 2 3; do ssh -o BatchMode=yes -o PubkeyAuthentication=no -o PreferredAuthentications=password -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 deploy@127.0.0.1 true 2>&1 | grep -q 'Permission denied (publickey)' && exit 0; sleep 1; done; exit 1"
check "the config is valid (sshd -t)"                           sshd -t -f /etc/clippy-lab/sshd_config

echo "== Transfer and tunnel =="
check "clippy-1.4.0.tar.gz arrived in ~deploy/uploads intact"  bash -c "[ \"\$(sha256sum /home/deploy/uploads/clippy-1.4.0.tar.gz | cut -d' ' -f1)\" = \"\$(cat /var/lib/clippy-lab/release.sha)\" ]"
check "tunnel.txt contains the dashboard secret"                bash -c "grep -q \"\$(cat /var/lib/clippy-lab/token)\" tunnel.txt"

echo "== Hygiene =="
check "ssh_config_snippet has Host, HostName, Port 2222, User and IdentityFile" bash -c "f=ssh_config_snippet; grep -qi '^Host clippy-staging' \$f && grep -qi HostName \$f && grep -qi 'Port 2222' \$f && grep -qi 'User deploy' \$f && grep -qi IdentityFile \$f"
check "no private key was committed to this repository"         bash -c "! grep -rlE '^-----BEGIN [A-Z ]*PRIVATE KEY-----' . --exclude-dir=.git"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
