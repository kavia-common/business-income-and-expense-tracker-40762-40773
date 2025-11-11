#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WS"
mkdir -p "$WS/app" "$WS/tests" "$WS/data"
if [ ! -f "$WS/app/main.py" ]; then cat > "$WS/app/main.py" <<'PY'
from fastapi import FastAPI
app = FastAPI()
@app.get('/health')
def health():
    return {'status':'ok'}
PY
fi
# requirements (explicitly include requests)
if [ ! -f "$WS/requirements.txt" ]; then cat > "$WS/requirements.txt" <<'TXT'
fastapi==0.100.0
uvicorn==0.22.0
python-dotenv==1.0.1
psycopg2-binary==2.9.7
pytest==7.4.0
requests==2.31.0
TXT
fi
# .env.example
if [ ! -f "$WS/.env.example" ]; then cat > "$WS/.env.example" <<'ENV'
# Supabase connection variables - copy to .env for local dev
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
DATABASE_URL=
SQLITE_FILE=data/dev.sqlite
ENV
fi
# Create .env from example for non-interactive CI if missing (does not populate secrets)
if [ ! -f "$WS/.env" ]; then cp "$WS/.env.example" "$WS/.env"; fi
# minimal package.json for optional node helpers
if [ ! -f "$WS/package.json" ]; then cat > "$WS/package.json" <<'JSON'
{"name":"income-expense-backend","version":"0.1.0","private":true}
JSON
fi
# README with absolute path references
cat > "$WS/README_SUPABASE.md" <<MD
Workspace-local supabase CLI expected at $WS/.local/bin/supabase or $WS/.local/lib/node_modules/.bin/supabase. To persist PATH for this workspace set EXPORT_GLOBAL_ENV=true before running env install.
MD
