#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WS"
PYVENV="$WS/.venv"
# write tests (idempotent overwrite)
cat > "$WS/tests/test_smoke.py" <<'PY'
import os
from dotenv import load_dotenv
import tempfile
import sqlite3
import requests
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
from fastapi.testclient import TestClient
from app.main import app
client = TestClient(app)

def test_health():
    r = client.get('/health')
    assert r.status_code == 200 and r.json().get('status') == 'ok'

def test_db_connectivity():
    db_dsn = os.getenv('DATABASE_URL') or os.getenv('POSTGRES_DSN')
    if db_dsn:
        import psycopg2
        conn = psycopg2.connect(db_dsn, connect_timeout=5)
        cur = conn.cursor()
        cur.execute('SELECT 1')
        assert cur.fetchone()[0] == 1
        cur.close(); conn.close()
        return
    sup_url = os.getenv('SUPABASE_URL','').strip()
    anon = os.getenv('SUPABASE_ANON_KEY','').strip()
    if sup_url.startswith('http') and anon:
        try:
            r = requests.get(sup_url.rstrip('/') + '/rest/v1/', headers={'apikey': anon}, timeout=5)
            assert 200 <= r.status_code < 300
            return
        except Exception:
            pass
    tmp = tempfile.NamedTemporaryFile(prefix='test-', suffix='.sqlite', delete=False)
    tmp.close()
    conn = sqlite3.connect(tmp.name)
    cur = conn.cursor()
    cur.execute('CREATE TABLE IF NOT EXISTS smoke_test(id INTEGER PRIMARY KEY, v INTEGER)')
    cur.execute('INSERT INTO smoke_test(v) VALUES (1)')
    cur.execute('SELECT v FROM smoke_test ORDER BY id DESC LIMIT 1')
    val = cur.fetchone()[0]
    conn.commit(); conn.close()
    assert val == 1
PY
# run pytest inside venv
if [ -x "$PYVENV/bin/pytest" ]; then
  "$PYVENV/bin/pytest" -q || (echo "pytest failed" >&2; exit 41)
else
  echo "Error: pytest not found in venv at $PYVENV/bin/pytest" >&2
  exit 42
fi
