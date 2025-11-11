#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WS"
PYVENV="$WS/.venv"
if [ -x "$PYVENV/bin/uvicorn" ]; then UV_BIN="$PYVENV/bin/uvicorn"; else echo "uvicorn missing from venv" >&2; exit 50; fi
LOGFILE=$(mktemp)
# start uvicorn in its own process group via setsid
setsid "$UV_BIN" app.main:app --host 127.0.0.1 --port 8000 --log-level warning >"$LOGFILE" 2>&1 &
PID=$!
PGID=$(ps -o pgid= -p "$PID" | tr -d ' ')
trap 'if [ -n "${PGID:-}" ]; then sudo kill -TERM -"$PGID" >/dev/null 2>&1 || true; fi; rm -f "$LOGFILE"' EXIT
# readiness: bounded total timeout
TOTAL_TIMEOUT=30; SLEEP=0.5; ELAPSED=0
while true; do
  if curl -sS -f http://127.0.0.1:8000/health >/dev/null 2>&1; then break; fi
  if (( $(echo "$ELAPSED >= $TOTAL_TIMEOUT" | bc -l) )); then echo "server failed to become ready within ${TOTAL_TIMEOUT}s" >&2; echo "--- uvicorn log (tail) ---" >&2; tail -n 200 "$LOGFILE" >&2; sudo kill -TERM -"$PGID" >/dev/null 2>&1 || true; exit 51; fi
  sleep $SLEEP
  ELAPSED=$(echo "$ELAPSED + $SLEEP" | bc -l)
  SLEEP=$(python3 - <<PY
s=$SLEEP
s=s*2
print(s if s<=5 else 5)
PY
)
done
# perform a health check and print response
curl -sS http://127.0.0.1:8000/health || true
# stop server cleanly by killing the process group
sudo kill -TERM -"$PGID" >/dev/null 2>&1 || true
wait "$PID" 2>/dev/null || true
rm -f "$LOGFILE"
echo "validation successful"
