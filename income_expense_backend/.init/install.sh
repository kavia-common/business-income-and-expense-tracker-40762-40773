#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
# Ensure we're not blocked by supabase CLI install failures: SKIP_SUPABASE_INSTALL=1 recommended in restricted networks
if [ "${SKIP_SUPABASE_INSTALL:-0}" != "1" ]; then
  # quick non-fatal check for supabase; do not fail if unreachable
  if ! command -v supabase >/dev/null 2>&1; then echo "INFO: supabase CLI not present; continuing without it" >&2; fi
fi
# Install node deps reproducibly
if [ -f package-lock.json ]; then npm ci --silent --no-audit --no-fund; else npm i --silent --no-audit --no-fund; fi
# Optional PDF library
if [ "${ENABLE_PDF:-0}" = "1" ]; then npm i --silent --no-audit --no-fund pdfkit@0.13.0; fi
# Verify jest installed locally
if [ ! -x node_modules/.bin/jest ]; then echo "ERROR: project-local jest not installed" >&2; exit 6; fi
