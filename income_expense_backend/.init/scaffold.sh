#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/business-income-and-expense-tracker-40762-40773/income_expense_backend"
cd "$WORKSPACE"
NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 18 ]; then echo "ERROR: node >=18 required" >&2; exit 2; fi
if [ ! -f package.json ]; then
  cat > package.json <<'EOF'
{
  "name":"income-expense-backend",
  "version":"0.1.0",
  "private":true,
  "engines": { "node": ">=18" },
  "scripts": { "start":"node ./functions/http/index.js", "test":"jest --runInBand" },
  "dependencies": { "@supabase/supabase-js":"2.26.0" },
  "devDependencies": { "jest":"29.6.0" }
}
EOF
  npm i --package-lock-only --silent --no-audit --no-fund >/dev/null 2>&1 || true
fi
mkdir -p "$WORKSPACE/functions/http" "$WORKSPACE/migrations"
cat > "$WORKSPACE/functions/http/index.js" <<'EOF'
// Minimal HTTP function for smoke testing
const http = require('http');
const server = http.createServer((req,res)=>{
  if(req.url==='/health') return res.writeHead(200,{'Content-Type':'application/json'}) && res.end(JSON.stringify({ok:true}));
  res.writeHead(404); res.end('not found');
});
if(require.main===module){ const PORT=process.env.PORT||54321; server.listen(PORT,()=>console.log('listening',PORT)); }
module.exports=server;
EOF
cat > "$WORKSPACE/migrations/001_init.sql" <<'EOF'
CREATE TABLE IF NOT EXISTS accounts (id serial PRIMARY KEY, name text NOT NULL, created_at timestamptz DEFAULT now());
CREATE TABLE IF NOT EXISTS transactions (id serial PRIMARY KEY, account_id int REFERENCES accounts(id), amount numeric NOT NULL, type text NOT NULL, created_at timestamptz DEFAULT now());
EOF
