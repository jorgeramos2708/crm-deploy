#!/usr/bin/env bash
# Instalación limpia en el VPS (109.199.103.81) con Caddy + Cloudflare existentes.
# Uso: ./scripts/vps-install.sh   (desde /opt/crm-deploy, con .env ya creado)
set -euo pipefail
cd "$(dirname "$0")/.."

test -f .env || { echo "Falta .env (copia .env.example y rellena secretos)"; exit 1; }
test -d ../crm || { echo "Falta /opt/crm (git clone github.com/jorgeramos2708/crm.git)"; exit 1; }
docker network inspect caddy_net >/dev/null || { echo "No existe la red caddy_net"; exit 1; }

echo "== build =="
docker compose -f docker-compose.yml -f docker-compose.vps.yml build postgres redis api worker web

echo "== infra =="
docker compose -f docker-compose.yml -f docker-compose.vps.yml up -d postgres redis minio
for i in $(seq 1 36); do
  docker compose exec -T postgres pg_isready -U "${POSTGRES_USER:-crm}" -d "${POSTGRES_DB:-crm}" && break
  sleep 5
done

echo "== migrate + seed =="
docker compose run --rm api node dist/migrate.js
docker compose run --rm api node dist/seed.js

echo "== app =="
docker compose -f docker-compose.yml -f docker-compose.vps.yml up -d api worker web

echo "== caddy (existente) =="
if ! grep -q "crm.edrs.xyz {" ~/caddy/Caddyfile; then
  cat sites/crm.edrs.xyz.Caddyfile >> ~/caddy/Caddyfile
fi
docker exec caddy caddy fmt --overwrite /etc/caddy/Caddyfile 2>/dev/null || true
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

echo "== verify =="
sleep 5
curl -sf https://crm.edrs.xyz/api/auth/sso/status && echo && echo OK
