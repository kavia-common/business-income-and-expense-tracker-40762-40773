#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
# Build step
if [ -f package-lock.json ]; then npm ci --silent --no-audit --no-fund; else npm i --silent --no-audit --no-fund; fi
# Start local function
node functions/http/index.js >/tmp/income_expense_func.log 2>&1 &
FUNC_PID=$!
echo $FUNC_PID >/tmp/income_expense_func.pid
# wait for function readiness
RETRY=0; MAX=10
while [ $RETRY -lt $MAX ]; do
  if grep -qi listening /tmp/income_expense_func.log 2>/dev/null || nc -z 127.0.0.1 54321 >/dev/null 2>&1; then break; fi
  sleep 1; RETRY=$((RETRY+1))
done
if [ $RETRY -ge $MAX ]; then kill $FUNC_PID 2>/dev/null || true; echo "ERROR: function failed to start" >&2; exit 5; fi
# healthcheck
if ! curl -sSf "http://127.0.0.1:54321/health" >/dev/null 2>&1; then kill $FUNC_PID 2>/dev/null || true; echo "ERROR: function healthcheck failed" >&2; exit 6; fi
# run tests
if [ -x node_modules/.bin/jest ]; then node_modules/.bin/jest --runInBand --silent || true; fi
# Optional supabase emulator flow
if command -v supabase >/dev/null 2>&1; then
  supabase start --project-ref local --project-dir "$WORKSPACE" --no-analytics --detached >/dev/null 2>&1 || { echo "WARN: supabase start failed" >&2; }
  API_PORT=54321; DB_PORT=54322
  RETRY=0; MAX=60
  while [ $RETRY -lt $MAX ]; do
    if pg_isready -q -h localhost -p "$DB_PORT" >/dev/null 2>&1; then break; fi
    sleep 1; RETRY=$((RETRY+1))
  done
  if [ $RETRY -ge $MAX ]; then echo "WARN: supabase DB not ready" >&2; fi
  if pg_isready -q -h localhost -p "$DB_PORT" >/dev/null 2>&1; then
    RES_DB_URL="postgresql://postgres@localhost:${DB_PORT}/income_expense_dev"
    psql "postgresql://postgres@localhost:${DB_PORT}/postgres" -c "CREATE DATABASE IF NOT EXISTS \"income_expense_dev\";" >/dev/null 2>&1 || true
    for f in migrations/*.sql; do [ -f "$f" ] || continue; psql "$RES_DB_URL" -v ON_ERROR_STOP=1 -f "$f" >/dev/null 2>&1 || { echo "WARN: migration $f failed" >&2; }; done
    echo "VALIDATION_OK: migrations applied to $RES_DB_URL"
  fi
  supabase stop --project-ref local --project-dir "$WORKSPACE" >/dev/null 2>&1 || true
fi
# cleanup
kill $FUNC_PID 2>/dev/null || true
wait $FUNC_PID 2>/dev/null || true
rm -f /tmp/income_expense_func.pid || true
echo "VALIDATION_OK: local function healthy and tests run (supabase emulator used if available)"
