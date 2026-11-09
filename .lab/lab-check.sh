#!/usr/bin/env bash
rc=0
[ -s ssh_config_snippet ] && grep -qi '^Host clipstr-staging' ssh_config_snippet && echo "- ✅ ssh_config_snippet has the clipstr-staging block" || { echo "- ❌ ssh_config_snippet is missing or lacks 'Host clipstr-staging'"; rc=1; }
[ -s tunnel.txt ] && grep -qi 'token' tunnel.txt && echo "- ✅ tunnel.txt has the dashboard response" || { echo "- ❌ tunnel.txt must contain the dashboard response (with the secret token)"; rc=1; }
if grep -rl 'BEGIN OPENSSH PRIVATE KEY\|BEGIN RSA PRIVATE KEY' . --exclude-dir=.git --exclude=verify.sh --exclude=LAB.md --exclude=README.md --exclude=SUBMISSION.md 2>/dev/null | grep -q .; then echo "- ❌ a PRIVATE KEY is committed in this repo. Remove it and rotate the key"; rc=1; else echo "- ✅ no private key found in the repository"; fi
grep -q 'ALL CHECKS PASSED' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
