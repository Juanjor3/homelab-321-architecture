#!/usr/bin/env bash
# Shared Bash helper library for 3-2-1 backup scripts.

log()      { printf '[%s] [INFO]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
log_ok()   { printf '[%s] [OK]    %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
log_warn() { printf '[%s] [WARN]  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
log_err()  { printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

die() {
  log_err "$*"
  exit 1
}

check_disk_space() {
  local target_dir="$1"
  local min_mb="$2"
  local label="${3:-$target_dir}"

  mkdir -p "$target_dir"
  local avail_mb
  avail_mb=$(df -Pm "$target_dir" | awk 'NR==2 {print $4}')
  if [[ -z "$avail_mb" ]] || (( avail_mb < min_mb )); then
    die "Insufficient disk space on ${label}: ${avail_mb:-0} MB free (required ${min_mb} MB)"
  fi
  log_ok "Disk space check passed on ${label}: ${avail_mb} MB free"
}

rclone_sync_retry() {
  local src_dir="$1"
  local dst_remote="$2"
  local max_attempts="${3:-3}"
  local attempt=1

  while (( attempt <= max_attempts )); do
    log "Syncing ${src_dir} -> ${dst_remote} (attempt ${attempt}/${max_attempts})"
    if rclone sync "$src_dir" "$dst_remote" \
      --transfers 1 \
      --low-level-retries 2 \
      --retries-sleep 30s; then
      log_ok "Cloud sync completed: ${dst_remote}"
      return 0
    fi
    log_warn "Cloud sync failed on attempt ${attempt}"
    (( attempt++ ))
    sleep 30
  done

  return 1
}
