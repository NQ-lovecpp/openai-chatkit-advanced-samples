#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY must be set before launching the ChatKit backends." >&2
  exit 1
fi

SERVICES=(
  "cat-lounge|/srv/cat-lounge/backend|8000"
  "customer-support|/srv/customer-support/backend|8001"
  "news-guide|/srv/news-guide/backend|8002"
  "metro-map|/srv/metro-map/backend|8003"
)

PIDS=()

shutdown() {
  for pid in "${PIDS[@]:-}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
    fi
  done
  wait
}

trap shutdown EXIT

for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name app_dir port <<<"$entry"
  python -m uvicorn app.main:app --app-dir "$app_dir" --host 0.0.0.0 --port "$port" --log-level info &
  PIDS+=("$!")
  echo "Started $name on port $port (PID ${PIDS[-1]})"
done

wait
