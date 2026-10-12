#!/usr/bin/env bash
set -euo pipefail

SCRIPT_OR_DUMP_FILE="${1:-}"

if [ -z "$SCRIPT_OR_DUMP_FILE" ]; then
  echo "Error: No file specified!"
  echo "Usage: $0 <file.sql_or_dump>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If it is a SQL or SH script, run it via run-script.sh
if [[ "$SCRIPT_OR_DUMP_FILE" == *.sql || "$SCRIPT_OR_DUMP_FILE" == *.sh ]]; then
  "${SCRIPT_DIR}/run-script.sh" "$SCRIPT_OR_DUMP_FILE"
  exit 0
fi

# Otherwise, handle as full pg_restore dump file
SERVER_USER="${SERVER_USER:-deployer}"
SERVER_HOST="${SERVER_HOST:-98.70.45.119}"
CONTAINER_NAME="${CONTAINER_NAME:-landmark-db}"
DB_USER="${DB_USER:-postgres_local}"
DB_NAME="${DB_NAME:-postgres_local}"
DUMPS_PATH="${DUMPS_PATH:-/var/www/dkapp/DS_audit/dumps}"

SSH_KEY_ARG=""
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "${SSH_KEY_PATH:-}" ]; then
  SSH_KEY_ARG="-i ${SSH_KEY_PATH}"
fi

SSH_OPTS="${SSH_KEY_ARG} -o StrictHostKeyChecking=no -o ConnectTimeout=10"
DUMP_FILENAME=$(basename "$SCRIPT_OR_DUMP_FILE")

echo "==> Ensuring remote dumps path exists..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" "mkdir -p '${DUMPS_PATH}'"

if [ -f "$SCRIPT_OR_DUMP_FILE" ]; then
  echo "==> Uploading local dump file '${SCRIPT_OR_DUMP_FILE}' to server..."
  scp ${SSH_OPTS} "$SCRIPT_OR_DUMP_FILE" "${SERVER_USER}@${SERVER_HOST}:${DUMPS_PATH}/${DUMP_FILENAME}"
fi

echo "==> Restoring database inside container '${CONTAINER_NAME}'..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
  "$CONTAINER_NAME" "$DB_USER" "$DB_NAME" "$DUMP_FILENAME" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMP_FILENAME="$4"

docker exec -i "${CONTAINER_NAME}" pg_restore \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  "/dumps/${DUMP_FILENAME}" || {
    echo "Notice: pg_restore completed with warnings/notices."
  }

docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "\dt landmark.*" || true
REMOTE

echo "==> Restore completed successfully!"
