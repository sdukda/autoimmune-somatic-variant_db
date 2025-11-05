#!/usr/bin/env bash
set -euo pipefail

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_NAME="autoimmune_db"
DB_USER="root"

read -rsp "MySQL password for ${DB_USER}: " DB_PASS; echo

# (optional) create DB if you keep a create_database.sql
if [[ -f "sql/create_database.sql" ]]; then
  mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" < sql/create_database.sql
fi

# migrations in lexical order
for f in sql/migrations/*.sql; do
  echo ">> applying $f"
  mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$f"
done

# seeds (reference only)
for f in sql/seeds/*.sql; do
  echo ">> seeding $f"
  mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$f"
done

echo "done."
