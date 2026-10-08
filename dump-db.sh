#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/dump_func.sh"

load_config "${SCRIPT_DIR}/config.env"

# CLI Options override
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--host) SERVER_HOST="$2"; shift 2 ;;
    -u|--user) SERVER_USER="$2"; shift 2 ;;
    -c|--container) CONTAINER_NAME="$2"; shift 2 ;;
    -d|--dbname) DB_NAME="$2"; shift 2 ;;
    -U|--dbuser) DB_USER="$2"; shift 2 ;;
    -p|--dumps-path) REMOTE_DUMPS_PATH="$2"; shift 2 ;;
    -l|--local-dir) LOCAL_DUMP_DIR="$2"; shift 2 ;;
    --help)
      cat <<EOF
Usage: $0 [options]

Options:
  -h, --host HOST          Remote server IP/hostname (default: $SERVER_HOST)
  -u, --user USER          Remote SSH user (default: $SERVER_USER)
  -c, --container NAME     Docker container name (default: $CONTAINER_NAME)
  -d, --dbname NAME        Database name (default: $DB_NAME)
  -U, --dbuser USER        Database user (default: $DB_USER)
  -p, --dumps-path PATH    Dumps path on remote server (default: $REMOTE_DUMPS_PATH)
  -l, --local-dir DIR      Local directory to fetch dump file into (default: $LOCAL_DUMP_DIR)
  --help                   Display this help message
EOF
      exit 0
      ;;
    *) log_error "Unknown argument: $1"; exit 1 ;;
  esac
done

check_ssh_connection
check_remote_container "$CONTAINER_NAME"

execute_remote_dump "$CONTAINER_NAME" "$DB_USER" "$DB_NAME" "$REMOTE_DUMPS_PATH"
