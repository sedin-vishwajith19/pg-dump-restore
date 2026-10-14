#!/usr/bin/env bash
set -euo pipefail

SCRIPT_FILE="${1:-}"

if [ -z "$SCRIPT_FILE" ] || [ ! -f "$SCRIPT_FILE" ]; then
  echo "Error: SQL script file '$SCRIPT_FILE' not found!"
  echo "Usage: $0 <script.sql>"
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

echo "==> Executing SQL script inside container '${CONTAINER_NAME}' on '${SERVER_HOST}'..."
ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" \
  "docker exec -i '${CONTAINER_NAME}' psql -U '${DB_USER}' -d '${DB_NAME}' -v ON_ERROR_STOP=1" < "$SCRIPT_FILE"

echo "==> SQL script executed successfully!"
