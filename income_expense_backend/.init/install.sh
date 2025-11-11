#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WS"
PYVENV="$WS/.venv"
[ -d "$PYVENV" ] || python3 -m venv "$PYVENV"
"$PYVENV/bin/pip" install --upgrade pip setuptools wheel -q
TMPLOG=$(mktemp)
if ! "$PYVENV/bin/pip" install -r "$WS/requirements.txt" -q >"$TMPLOG" 2>&1; then
  # retry with system build deps for psycopg2 if wheel build failed
  sudo apt-get update -q && sudo apt-get install -y --no-install-recommends libpq-dev gcc -qq >/dev/null 2>&1 || true
  "$PYVENV/bin/pip" install -r "$WS/requirements.txt" >"$TMPLOG" 2>&1 || { cat "$TMPLOG" >&2; rm -f "$TMPLOG"; exit 31; }
fi
rm -f "$TMPLOG"
# ensure sqlite data file exists
mkdir -p "$WS/data" && touch "$WS/data/dev.sqlite"
# optional node installs: only when package.json exists with deps or NODE_INSTALL=yes
if [ -f "$WS/package.json" ]; then
  has_deps=$(node -e "const p=require('$WS/package.json'); console.log((p.dependencies&&Object.keys(p.dependencies).length)||(p.devDependencies&&Object.keys(p.devDependencies).length) ? 1:0)" || printf 0)
  if [ "$has_deps" != "0" ] || [ "${NODE_INSTALL:-false}" = "true" ]; then
    npm --prefix "$WS/.local" i --no-audit --no-fund --silent --no-save || { echo "npm install failed" >&2; exit 33; }
    mkdir -p "$WS/.local/bin"
    # safely link any installed node helper bins (guard globs)
    shopt -s nullglob
    for f in "$WS/.local/lib/node_modules/.bin"/*; do ln -sf "$f" "$WS/.local/bin/$(basename "$f")"; done
    shopt -u nullglob
  fi
fi
# verify venv uvicorn binary and version matches pinned uvicorn
if [ -x "$PYVENV/bin/uvicorn" ]; then
  UV_BIN="$PYVENV/bin/uvicorn"
  UV_V=$("$UV_BIN" --version 2>&1 | sed -n 's/.*\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p' | head -n1 || true)
  if [ -z "$UV_V" ]; then echo "could not determine venv uvicorn version" >&2; exit 34; fi
  if [ "$UV_V" != "0.22.0" ]; then echo "venv uvicorn version $UV_V does not match pinned 0.22.0" >&2; exit 35; fi
else
  echo "uvicorn missing from venv; ensure pip install succeeded" >&2; exit 36
fi
