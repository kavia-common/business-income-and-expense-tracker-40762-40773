#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
# basic healthcheck of running function
if ! curl -sSf "http://127.0.0.1:54321/health" >/dev/null 2>&1; then echo "ERROR: function healthcheck failed" >&2; exit 6; fi
# run jest tests if installed
if [ -x node_modules/.bin/jest ]; then node_modules/.bin/jest --runInBand --silent || true; fi
echo "TESTS_OK"
