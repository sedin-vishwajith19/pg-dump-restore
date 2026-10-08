#!/usr/bin/env bash
set -euo pipefail

# Configuration with environment defaults
SERVER_USER="${SERVER_USER:-deployer}"
SERVER_HOST="${SERVER_HOST:-98.70.45.119}"
CONTAINER_NAME="${CONTAINER_NAME:-landmark-db}"
DB_USER="${DB_USER:-postgres_local}"
DB_NAME="${DB_NAME:-postgres_local}"
DUMPS_PATH="${DUMPS_PATH:-/var/www/dkapp/DS_audit/dumps}"
LOCAL_DUMP_DIR="${LOCAL_DUMP_DIR:-./dumps}"

# Handle SSH key if provided by Jenkins
SSH_KEY_ARG=""
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "${SSH_KEY_PATH:-}" ]; then
  SSH_KEY_ARG="-i ${SSH_KEY_PATH}"
fi

SSH_OPTS="${SSH_KEY_ARG} -o StrictHostKeyChecking=no -o ConnectTimeout=10"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILENAME="${DB_NAME}_${TIMESTAMP}.dump"

echo "==> [1/3] Creating PostgreSQL dump on remote server (${SERVER_HOST})..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
  "$CONTAINER_NAME" "$DB_USER" "$DB_NAME" "$DUMPS_PATH" "$DUMP_FILENAME" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMPS_PATH="$4"
DUMP_FILENAME="$5"

mkdir -p "${DUMPS_PATH}"
echo "Running pg_dump inside Docker container '${CONTAINER_NAME}'..."
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc -f "/dumps/${DUMP_FILENAME}"
echo "Dump created successfully: ${DUMPS_PATH}/${DUMP_FILENAME}"
REMOTE

echo "==> [2/3] Fetching dump file to workspace (${LOCAL_DUMP_DIR})..."
mkdir -p "${LOCAL_DUMP_DIR}"
scp ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}:${DUMPS_PATH}/${DUMP_FILENAME}" "${LOCAL_DUMP_DIR}/${DUMP_FILENAME}"

echo "==> [3/3] Done! Dump saved to: ${LOCAL_DUMP_DIR}/${DUMP_FILENAME}"
