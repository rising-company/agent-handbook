#!/usr/bin/env bash
# Tests for totp.mjs against RFC 6238's SHA-1 vectors (last 6 digits).
# Run: bash skills/pre-push-ui-review/scripts/totp.test.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
key=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ   # base32("12345678901234567890")
pass=0; fail=0
check() { local got; got=$(node "$here/totp.mjs" "$key" "$1" 2>&1); [[ "$got" == "$2" ]] && { pass=$((pass+1)); echo "ok   - t=$1"; } || { fail=$((fail+1)); echo "FAIL - t=$1 got $got want $2"; }; }
check 59 287082
check 1111111109 081804
check 1234567890 005924
check 2000000000 279037
out=$(node "$here/totp.mjs" 2>&1); rc=$?
[[ $rc == 2 ]] && { pass=$((pass+1)); echo "ok   - no key is a usage error"; } || { fail=$((fail+1)); echo "FAIL - no key rc=$rc"; }
echo "pass=$pass fail=$fail"; [[ $fail == 0 ]]
