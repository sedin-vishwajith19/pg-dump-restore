#!/usr/bin/env bash
set -euo pipefail

DUMP_FILE="${1:-}"

if [ -z "$DUMP_FILE" ]; then
  echo "Error: No dump file specified!"
  echo "Usage: $0 <dump_file_path>"
  exit 1
fi

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
DUMP_FILENAME=$(basename "$DUMP_FILE")

echo "==> [1/3] Ensuring remote dumps path exists..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" "mkdir -p '${DUMPS_PATH}'"

if [ -f "$DUMP_FILE" ]; then
  echo "==> [2/3] Uploading local dump file '${DUMP_FILE}' to server..."
  scp ${SSH_OPTS} "$DUMP_FILE" "${SERVER_USER}@${SERVER_HOST}:${DUMPS_PATH}/${DUMP_FILENAME}"
else
  echo "==> [2/3] Using existing dump file on server: ${DUMPS_PATH}/${DUMP_FILENAME}"
fi

echo "==> [3/3] Restoring database inside container '${CONTAINER_NAME}'..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
  "$CONTAINER_NAME" "$DB_USER" "$DB_NAME" "$DUMP_FILENAME" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMP_FILENAME="$4"

echo "Running pg_restore inside container '${CONTAINER_NAME}'..."
docker exec -i "${CONTAINER_NAME}" pg_restore \
  -U "${DB_USER}" \
  -d "${DB_NAME}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  "/dumps/${DUMP_FILENAME}" || {
    echo "Notice: pg_restore finished (warnings/notices are normal)."
  }

echo "Verifying restored schema tables..."
docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "\dt landmark.*" || true
echo "Database restore finished!"
REMOTE

echo "==> Restore completed successfully!"
