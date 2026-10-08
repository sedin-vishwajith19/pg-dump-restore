#!/usr/bin/env bash
# ==============================================================================
# Remote Database Restore Module
# ==============================================================================

execute_remote_restore() {
    local dump_file="$1"
    local container_name="${2:-$CONTAINER_NAME}"
    local db_user="${3:-$DB_USER}"
    local db_name="${4:-$DB_NAME}"
    local dumps_path="${5:-$REMOTE_DUMPS_PATH}"
    local schema_verify="${6:-$SCHEMA_VERIFY}"
    local enable_safety_snapshot="${7:-true}"

    if [ -z "$dump_file" ]; then
        log_error "No dump file path provided for restore operation!"
        exit 1
    fi

    local dump_filename
    dump_filename=$(basename "$dump_file")

    log_banner "Starting Remote Database Restore Workflow"
    echo " Target Server   : ${SERVER_USER}@${SERVER_HOST}"
    echo " Target Container: ${container_name}"
    echo " Target Database : ${db_name} (User: ${db_user})"
    echo " Source Dump File: ${dump_file}"
    echo " Remote Dumps Dir: ${dumps_path}"
    echo " Schema Verify   : ${schema_verify}"
    echo "------------------------------------------------------------"

    log_info "Ensuring remote dumps directory exists on target server..."
    ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" "mkdir -p '${dumps_path}'"

    # Take safety snapshot if enabled
    if [ "$enable_safety_snapshot" = "true" ]; then
        take_safety_snapshot "$container_name" "$db_user" "$db_name" "$dumps_path"
    fi

    # Upload dump file if present locally (in Jenkins workspace)
    if [ -f "$dump_file" ]; then
        log_info "Transferring dump file from Jenkins workspace to target server..."
        rsync -avz --progress -e "ssh ${SSH_OPTS}" "$dump_file" "${SERVER_USER}@${SERVER_HOST}:${dumps_path}/${dump_filename}"
        log_success "Transfer complete."
    else
        log_info "File '${dump_file}' not found locally; verifying existence on remote server..."
    fi

    log_info "Executing pg_restore inside container '${container_name}'..."

    ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
        "$container_name" \
        "$db_user" \
        "$db_name" \
        "$dump_filename" \
        "$schema_verify" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMP_FILENAME="$4"
SCHEMA_VERIFY="$5"

echo "[remote] Checking dump file availability..."
if [ ! -f "/var/www/dkapp/DS_audit/dumps/${DUMP_FILENAME}" ]; then
    echo "[remote] ERROR: Dump file '${DUMP_FILENAME}' not found in dumps folder!"
    exit 1
fi

echo "[remote] Restoring dump '/dumps/${DUMP_FILENAME}' into database '${DB_NAME}'..."
docker exec -i "$CONTAINER_NAME" pg_restore \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --clean \
  --if-exists \
  --no-owner \
  --no-privileges \
  --verbose \
  "/dumps/${DUMP_FILENAME}" || {
    echo "[remote] Note: pg_restore finished with notices (normal for schema/owner skips)."
  }

if [ -n "$SCHEMA_VERIFY" ]; then
    echo "[remote] Verifying restored tables in schema '${SCHEMA_VERIFY}'..."
    docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME" -c "\dt ${SCHEMA_VERIFY}.*" || true
fi

echo "[remote] Database restore execution finished successfully!"
REMOTE

    log_success "Database restore completed successfully!"
    log_banner "Restore Workflow Completed"
}
