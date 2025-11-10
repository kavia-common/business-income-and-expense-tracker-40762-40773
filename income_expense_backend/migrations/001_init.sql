CREATE TABLE IF NOT EXISTS accounts (id serial PRIMARY KEY, name text NOT NULL, created_at timestamptz DEFAULT now());
CREATE TABLE IF NOT EXISTS transactions (id serial PRIMARY KEY, account_id int REFERENCES accounts(id), amount numeric NOT NULL, type text NOT NULL, created_at timestamptz DEFAULT now());
