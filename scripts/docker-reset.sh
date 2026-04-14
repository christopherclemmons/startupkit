#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

MODE="${1:-full}"

if [[ "$MODE" != "full" && "$MODE" != "db" ]]; then
  echo "Usage: ./scripts/docker-reset.sh [full|db]" >&2
  exit 1
fi

if [[ ! -f ".env" ]]; then
  echo "Missing .env in repository root. Create it first (for example: cp .env.example .env)." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Neither 'docker compose' nor 'docker-compose' is available." >&2
  exit 1
fi

COMPOSE_FILE="docker-compose.yml"
if [[ "$MODE" == "db" ]]; then
  COMPOSE_FILE="docker-compose-db.yml"
fi

echo "Using compose command: ${COMPOSE[*]}"
echo "Reset mode: $MODE ($COMPOSE_FILE)"

echo "Tearing down existing containers and volumes..."
"${COMPOSE[@]}" -f "$COMPOSE_FILE" down -v --remove-orphans

echo "Building and starting services from scratch..."
if [[ "$MODE" == "db" ]]; then
  "${COMPOSE[@]}" -f "$COMPOSE_FILE" up -d
else
  "${COMPOSE[@]}" -f "$COMPOSE_FILE" up -d --build
fi

echo "Current container status:"
"${COMPOSE[@]}" -f "$COMPOSE_FILE" ps

PGADMIN_PORT="${PGADMIN_PORT:-5050}"
echo ""
echo "Reset complete."
if [[ "$MODE" == "full" ]]; then
  echo "Frontend: http://localhost:3000"
  echo "Backend Swagger: http://localhost:5000/swagger"
fi
echo "pgAdmin: http://localhost:${PGADMIN_PORT}"
