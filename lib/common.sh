#!/usr/bin/env bash
# ==============================================================================
# Shared Utility & Guardrail Functions
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

log_banner() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

load_config() {
    local config_file="${1:-config.env}"
    if [ -f "$config_file" ]; then
        log_info "Loading configuration from ${config_file}..."
        set -a
        source "$config_file"
        set +a
    else
        log_warn "Config file '${config_file}' not found. Using default environment variables."
    fi

    # Append SSH key option if SSH_KEY_PATH environment variable is provided by Jenkins withCredentials
    if [ -n "${SSH_KEY_PATH:-}" ] && [ -f "${SSH_KEY_PATH:-}" ]; then
        SSH_OPTS="-i ${SSH_KEY_PATH} ${SSH_OPTS:- -o StrictHostKeyChecking=no -o ConnectTimeout=10}"
    else
        SSH_OPTS="${SSH_OPTS:- -o StrictHostKeyChecking=no -o ConnectTimeout=10}"
    fi
}

check_ssh_connection() {
    log_info "Testing SSH connection to ${SERVER_USER}@${SERVER_HOST}..."
    if ! ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" "echo ok" >/dev/null 2>&1; then
        log_error "Unable to connect to ${SERVER_USER}@${SERVER_HOST} via SSH."
        log_error "Please check Jenkins SSH Credentials or Firewall configuration."
        exit 1
    fi
    log_success "SSH connection established successfully."
}

check_remote_container() {
    local container_name="$1"
    log_info "Checking if Docker container '${container_name}' is running on target server..."
    local status
    status=$(ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" "docker ps --format '{{.Names}}' | grep -x '${container_name}' || true")
    if [ -z "$status" ]; then
        log_error "Docker container '${container_name}' is NOT running on ${SERVER_HOST}!"
        exit 1
    fi
    log_success "Container '${container_name}' is active and running."
}

take_safety_snapshot() {
    local container_name="$1"
    local db_user="$2"
    local db_name="$3"
    local dumps_path="$4"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local safety_filename="pre_restore_safety_${db_name}_${timestamp}.dump"

    log_warn "Taking automated pre-restore safety snapshot..."
    ssh ${SSH_OPTS} "${SERVER_USER}@${SERVER_HOST}" bash -s -- \
        "$container_name" "$db_user" "$db_name" "$dumps_path" "$safety_filename" <<'REMOTE'
set -euo pipefail
CONTAINER_NAME="$1"
DB_USER="$2"
DB_NAME="$3"
DUMPS_PATH="$4"
SAFETY_FILENAME="$5"

mkdir -p "${DUMPS_PATH}"
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc -f "/dumps/${SAFETY_FILENAME}" || true
echo "[remote] Pre-restore safety snapshot created: ${DUMPS_PATH}/${SAFETY_FILENAME}"
REMOTE
    log_success "Safety snapshot complete."
}
