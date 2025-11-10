#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
# install deps reproducibly
if [ -f package-lock.json ]; then npm ci --silent --no-audit --no-fund; else npm i --silent --no-audit --no-fund; fi
echo "BUILD_OK"
