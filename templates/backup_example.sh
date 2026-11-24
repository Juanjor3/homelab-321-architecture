#!/usr/bin/env bash
# Example 3-2-1 backup script for Docker volumes and PostgreSQL databases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib_backup.sh
source "${SCRIPT_DIR}/lib_backup.sh"

if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

BACKUP_LOCAL_DIR="${BACKUP_LOCAL_DIR:-/mnt/backup_local}"
NAS_MOUNT_DIR="${NAS_MOUNT_DIR:-/mnt/nas_backups}"
RCLONE_REMOTE="${RCLONE_REMOTE:-}"
MIN_FREE_MB="${MIN_FREE_MB:-5120}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
PG_CONTAINER="${PG_CONTAINER:-app_postgres}"
PG_USER="${PG_USER:-postgres}"
PG_DB="${PG_DB:-app_db}"

STAMP="$(date '+%Y-%m-%d_%H%M%S')"
STAGE_DIR="${BACKUP_LOCAL_DIR}/db_dumps"
mkdir -p "${STAGE_DIR}"

check_disk_space "${BACKUP_LOCAL_DIR}" "${MIN_FREE_MB}" "Local Backup Storage"

DUMP_FILE="${STAGE_DIR}/${PG_DB}_${STAMP}.sql.gz"
log "Creating consistent PostgreSQL dump from container ${PG_CONTAINER}..."
if ! docker exec "${PG_CONTAINER}" pg_dump -U "${PG_USER}" "${PG_DB}" | gzip > "${DUMP_FILE}"; then
  rm -f "${DUMP_FILE}"
  die "PostgreSQL dump failed"
fi
log_ok "Dump created: ${DUMP_FILE}"

find "${STAGE_DIR}" -type f -name "*.sql.gz" -mtime +"${RETENTION_DAYS}" -delete

if [[ -d "${NAS_MOUNT_DIR}" ]]; then
  log "Replicating backups to local NAS (${NAS_MOUNT_DIR})..."
  rsync -a --delete "${STAGE_DIR}/" "${NAS_MOUNT_DIR}/db_dumps/"
  log_ok "NAS replication finished"
fi

if [[ -n "${RCLONE_REMOTE}" ]] && command -v rclone >/dev/null 2>&1; then
  rclone_sync_retry "${STAGE_DIR}" "${RCLONE_REMOTE}/db_dumps" 3 || die "Encrypted cloud sync failed"
fi

log_ok "3-2-1 backup cycle completed successfully"
