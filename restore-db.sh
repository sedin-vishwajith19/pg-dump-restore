#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/restore_func.sh"

load_config "${SCRIPT_DIR}/config.env"

DUMP_FILE=""
SAFETY_SNAPSHOT="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--host) SERVER_HOST="$2"; shift 2 ;;
    -u|--user) SERVER_USER="$2"; shift 2 ;;
    -c|--container) CONTAINER_NAME="$2"; shift 2 ;;
    -d|--dbname) DB_NAME="$2"; shift 2 ;;
    -U|--dbuser) DB_USER="$2"; shift 2 ;;
    -p|--dumps-path) REMOTE_DUMPS_PATH="$2"; shift 2 ;;
    -s|--schema) SCHEMA_VERIFY="$2"; shift 2 ;;
    --no-safety) SAFETY_SNAPSHOT="false"; shift ;;
    --help)
      cat <<EOF
Usage: $0 [options] <DUMP_FILE_PATH_OR_FILENAME>

Options:
  -h, --host HOST          Remote server IP/hostname (default: $SERVER_HOST)
  -u, --user USER          Remote SSH user (default: $SERVER_USER)
  -c, --container NAME     Docker container name (default: $CONTAINER_NAME)
  -d, --dbname NAME        Database name (default: $DB_NAME)
  -U, --dbuser USER        Database user (default: $DB_USER)
  -p, --dumps-path PATH    Dumps path on remote server (default: $REMOTE_DUMPS_PATH)
  -s, --schema SCHEMA      Schema name for verification (default: $SCHEMA_VERIFY)
  --no-safety              Disable automatic pre-restore safety snapshot
  --help                   Display this help message

Example:
  $0 dumps/postgres_local_20261007_120000.dump
EOF
      exit 0
      ;;
    -*) log_error "Unknown argument: $1"; exit 1 ;;
    *) DUMP_FILE="$1"; shift ;;
  esac
done

if [ -z "$DUMP_FILE" ]; then
    log_error "No dump file specified!"
    echo "Usage: $0 [options] <DUMP_FILE_PATH_OR_FILENAME>"
    exit 1
fi

check_ssh_connection
check_remote_container "$CONTAINER_NAME"

execute_remote_restore "$DUMP_FILE" "$CONTAINER_NAME" "$DB_USER" "$DB_NAME" "$REMOTE_DUMPS_PATH" "$SCHEMA_VERIFY" "$SAFETY_SNAPSHOT"
