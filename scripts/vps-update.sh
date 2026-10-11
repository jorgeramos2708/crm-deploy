#!/usr/bin/env bash
# Update en VPS: pull + rebuild + migrate (idempotente) + up.
# Uso: ./scripts/vps-update.sh   (desde /opt/crm-deploy)
set -euo pipefail
cd "$(dirname "$0")/.."

DC="docker compose -f docker-compose.yml -f docker-compose.vps.yml"
(cd ../crm && git pull --ff-only)
$DC build api worker web
$DC run --rm api node dist/migrate.js
$DC up -d api worker web
sleep 5
curl -sf https://crm.edrs.xyz/api/auth/sso/status && echo && echo OK
