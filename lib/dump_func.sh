#!/usr/bin/env bash
# ==============================================================================
# Remote Database Dump Module
# ==============================================================================

execute_remote_dump() {
    local container_name="${1:-$CONTAINER_NAME}"
    local db_user="${2:-$DB_USER}"
    local db_name="${3:-$DB_NAME}"
    local dumps_path="${4:-$REMOTE_DUMPS_PATH}"
    local custom_filename="${5:-}"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local dump_filename="${custom_filename:-${db_name}_${timestamp}.dump}"

    log_banner "Starting Remote Database Dump Workflow"
    echo " Target Server   : ${SERVER_USER}@${SERVER_HOST}"
    echo " Container Name  : ${container_name}"
    echo " Database Name   : ${db_name} (User: ${db_user})"
    echo " Remote Path     : ${dumps_path}/${dump_filename}"
    echo " Local Fetch Dir : ${LOCAL_DUMP_DIR:-Disabled}"
    echo "------------------------------------------------------------"

    log_info "Executing pg_dump inside remote Docker container..."

    ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
        "$container_name" \
        "$db_user" \
        "$db_name" \
        "$dumps_path" \
        "$dump_filename" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMPS_PATH="$4"
DUMP_FILENAME="$5"

mkdir -p "${DUMPS_PATH}"

echo "[remote] Executing pg_dump inside container '${CONTAINER_NAME}'..."
docker exec "${CONTAINER_NAME}" pg_dump \
    -U "${DB_USER}" \
    -d "${DB_NAME}" \
    -Fc \
    -f "/dumps/${DUMP_FILENAME}"

if [ ! -f "${DUMPS_PATH}/${DUMP_FILENAME}" ]; then
    echo "[remote] ERROR: Dump file '${DUMPS_PATH}/${DUMP_FILENAME}' was not found!"
    exit 1
fi

DUMP_SIZE=$(du -h "${DUMPS_PATH}/${DUMP_FILENAME}" | cut -f1)
echo "[remote] PostgreSQL dump created successfully! File size: ${DUMP_SIZE}"
REMOTE

    log_success "Remote pg_dump finished successfully."

    # Download dump to local/Jenkins workspace directory if LOCAL_DUMP_DIR is set
    if [ -n "${LOCAL_DUMP_DIR:-}" ]; then
        log_info "Fetching dump file to Jenkins workspace directory (${LOCAL_DUMP_DIR})..."
        mkdir -p "${LOCAL_DUMP_DIR}"
        rsync -avz --progress -e "ssh ${SSH_OPTS}" "${SERVER_USER}@${SERVER_HOST}:${dumps_path}/${dump_filename}" "${LOCAL_DUMP_DIR}/${dump_filename}"
        log_success "Dump saved locally at: ${LOCAL_DUMP_DIR}/${dump_filename}"
    fi

    log_banner "Database Dump Process Finished Successfully"
    echo "Generated File: ${dump_filename}"
}
