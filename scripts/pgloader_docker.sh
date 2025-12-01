#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./scripts/pgloader_docker.sh /path/to/development.sqlite3 postgres://user:pass@host:5432/dbname
# Example (local dev -> remote DB):
# ./scripts/pgloader_docker.sh db/development.sqlite3 "postgres://postgres:pass@localhost:5432/red_tape_reporter_production"

SQLITE_PATH=${1:-}
PG_URL=${2:-}

if [[ -z "$SQLITE_PATH" || -z "$PG_URL" ]]; then
  echo "Usage: $0 /path/to/sqlite.db postgres://user:pass@host:5432/dbname"
  exit 2
fi

if [[ ! -f "$SQLITE_PATH" ]]; then
  echo "SQLite file not found: $SQLITE_PATH"
  exit 2
fi

# Run pgloader in Docker, mounting the working directory so the sqlite file is accessible
PWD_DIR=$(pwd)

docker run --rm \
  -v "$PWD_DIR":"/data" \
  dimitri/pgloader:latest \
  pgloader "sqlite:///data/${SQLITE_PATH#./}" "$PG_URL"

echo "pgloader finished. Verify the target DB before switching production traffic."
