#!/usr/bin/env bash
set -euo pipefail

SCRIPT_FILE="${1:-}"

if [ -z "$SCRIPT_FILE" ]; then
  echo "Error: No script file specified!"
  echo "Usage: $0 <script_file.sql_or_sh>"
  exit 1
fi

if [ ! -f "$SCRIPT_FILE" ]; then
  echo "Error: Script file '$SCRIPT_FILE' not found!"
  exit 1
fi

SERVER_USER="${SERVER_USER:-deployer}"
SERVER_HOST="${SERVER_HOST:-98.70.45.119}"
CONTAINER_NAME="${CONTAINER_NAME:-landmark-db}"
DB_USER="${DB_USER:-postgres_local}"
DB_NAME="${DB_NAME:-postgres_local}"

SSH_KEY_ARG=""
if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "${SSH_KEY_PATH:-}" ]; then
  SSH_KEY_ARG="-i ${SSH_KEY_PATH}"
fi

SSH_OPTS="${SSH_KEY_ARG} -o StrictHostKeyChecking=no -o ConnectTimeout=10"

echo "==> Target Server    : ${SERVER_USER}@${SERVER_HOST}"
echo "==> Target Container : ${CONTAINER_NAME}"
echo "==> Target Database  : ${DB_NAME} (User: ${DB_USER})"
echo "==> Script File      : ${SCRIPT_FILE}"

echo "==> [1/2] Verifying Docker container status on remote server..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- "$CONTAINER_NAME" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '${CONTAINER_NAME}' is not running on target server!"
  exit 1
fi
echo "Container '${CONTAINER_NAME}' is running."
REMOTE

echo "==> [2/2] Executing script inside container '${CONTAINER_NAME}'..."
if [[ "$SCRIPT_FILE" == *.sh ]]; then
  ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" \
    "docker exec -i '${CONTAINER_NAME}' bash -s" < "$SCRIPT_FILE"
else
  ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" \
    "docker exec -i '${CONTAINER_NAME}' psql -U '${DB_USER}' -d '${DB_NAME}' -v ON_ERROR_STOP=1" < "$SCRIPT_FILE"
fi

echo "==> Script executed successfully!"
