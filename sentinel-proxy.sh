#!/bin/bash
set -euo pipefail

: "${REDIS_SENTINEL_HOSTS:?}"
: "${SENTINEL_MASTER_NAME:?}"

REDIS_SENTINEL_PORT="${REDIS_SENTINEL_PORT:-26379}"
REDIS_SESSION_PORT="${REDIS_SESSION_PORT:-6379}"
LISTEN_PORT="${LISTEN_PORT:-9736}"
LISTEN_HOST="${LISTEN_HOST:-127.0.0.1}"

SOCAT_PID=""

function find_master() {
  for host in $REDIS_SENTINEL_HOSTS; do
    echo "[INFO] Speaking Sentinel: Who is leader? $host:$REDIS_SENTINEL_PORT..."
    if MASTER_RAW=$(redis-cli -h "$host" -p "$REDIS_SENTINEL_PORT" SENTINEL get-master-addr-by-name "$SENTINEL_MASTER_NAME" 2>/dev/null); then
      local ip port
      ip=$(echo "$MASTER_RAW" | sed -n 1p)
      port=$(echo "$MASTER_RAW" | sed -n 2p)
      if [[ -n "$ip" && -n "$port" ]]; then
        echo "$ip:$port"
        return 0
      fi
    fi
  done
  return 1
}

function start_socat() {
  local target="$1"
  echo "[INFO] Starting socat proxy to $target"
  socat TCP-LISTEN:"$LISTEN_PORT",fork,reuseaddr TCP:"$target" &
  SOCAT_PID=$!
}

function stop_socat() {
  if [[ -n "$SOCAT_PID" ]] && kill -0 "$SOCAT_PID" 2>/dev/null; then
    echo "[INFO] Burning socat pid $SOCAT_PID"
    kill "$SOCAT_PID"
    wait "$SOCAT_PID" 2>/dev/null || true
  fi
}

LAST_MASTER=""
while true; do
  CURRENT_MASTER=$(find_master || true)
  if [[ -z "$CURRENT_MASTER" ]]; then
    echo "[WARN] No master was found. Waiting 5 sec..."
    sleep 5
    continue
  fi

  if [[ "$CURRENT_MASTER" != "$LAST_MASTER" ]]; then
    echo "[INFO] Master found : $CURRENT_MASTER"
    stop_socat
    start_socat "$CURRENT_MASTER"
    LAST_MASTER="$CURRENT_MASTER"
  fi

  sleep 5
done
