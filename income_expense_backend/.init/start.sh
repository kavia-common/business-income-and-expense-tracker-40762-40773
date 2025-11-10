#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
# Start function in background and write log
mkdir -p /tmp
node functions/http/index.js >/tmp/income_expense_func.log 2>&1 &
echo $! >/tmp/income_expense_func.pid
# wait for function to print listening or port open
RETRY=0; MAX=10
while [ $RETRY -lt $MAX ]; do
  if grep -qi listening /tmp/income_expense_func.log 2>/dev/null || nc -z 127.0.0.1 54321 >/dev/null 2>&1; then break; fi
  sleep 1; RETRY=$((RETRY+1))
done
if [ $RETRY -ge $MAX ]; then
  echo "ERROR: function failed to start" >&2
  pkill -F /tmp/income_expense_func.pid 2>/dev/null || true
  exit 5
fi
echo "START_OK"
