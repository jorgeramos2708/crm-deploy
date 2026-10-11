#!/usr/bin/env bash
# Instalación en servidor bare (sin Caddy ni Cloudflare): edge Caddy propio.
# Requiere: Ubuntu + Docker, DNS A de $DOMAIN apuntando, puertos 80/443 abiertos.
# Uso: DOMAIN=crm.ejemplo.com ./scripts/bare-install.sh  (con .env ya creado)
set -euo pipefail
cd "$(dirname "$0")/.."

test -f .env || { echo "Falta .env"; exit 1; }
test -d ../crm || { echo "Falta ../crm (clona el repo app al lado)"; exit 1; }
grep -q "^DOMAIN=" .env || { echo "Falta DOMAIN= en .env (bare)"; exit 1; }

DC="docker compose -f docker-compose.yml -f docker-compose.bare.yml"
echo "== build =="
$DC build postgres redis api worker web edge
echo "== infra =="
$DC up -d postgres redis
for i in $(seq 1 36); do
  $DC exec -T postgres pg_isready -U "${POSTGRES_USER:-crm}" -d "${POSTGRES_DB:-crm}" && break
  sleep 5
done
echo "== migrate + seed =="
$DC run --rm api node dist/migrate.js
$DC run --rm api node dist/seed.js
echo "== app + edge =="
$DC up -d api worker web edge
sleep 8
DOMAIN_VAL=$(grep ^DOMAIN= .env | cut -d= -f2)
curl -sf "https://${DOMAIN_VAL}/api/auth/sso/status" && echo && echo OK
