#!/usr/bin/env bash
# Read-only sanitized inventory. Do NOT emit docker compose config or env values.
set -euo pipefail
SOURCE_DIR="${1:-/opt/supabase}"
cd "$SOURCE_DIR"
test -f docker-compose.yml
test -f docker-compose.override.yml
printf 'SERVICES\n'
docker compose -f docker-compose.yml -f docker-compose.override.yml config --services
printf '\nRUNNING CONTAINERS (names, images, state only)\n'
docker ps --format '{{.Names}} | {{.Image}} | {{.Status}}' | grep -E '^(supabase-|realtime-)' || true
printf '\nENV VARIABLE NAMES (not values)\n'
if test -f .env; then
  awk '/^[[:space:]]*[A-Za-z_][A-Za-z_0-9]*[[:space:]]*=/ {split($0,a,"="); gsub(/^[[:space:]]+|[[:space:]]+$/,"",a[1]); print a[1]}' .env | sort -u
else
  echo 'No .env file found'
fi
printf '\nDone. No environment values, compose bodies or secrets are intentionally printed.\n'
