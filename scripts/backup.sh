#!/usr/bin/env bash
# Respaldo: pg_dump + lista de volúmenes. Uso: ./scripts/backup.sh [destino]
set -euo pipefail
cd "$(dirname "$0")/.."
DEST="${1:-./backups/$(date +%F)}"
mkdir -p "$DEST"
DC="docker compose"
if [ -f docker-compose.vps.yml ] && docker network inspect caddy_net >/dev/null 2>&1; then
  DC="docker compose -f docker-compose.yml -f docker-compose.vps.yml"
fi
$DC exec -T postgres pg_dump -U "${POSTGRES_USER:-crm}" -d "${POSTGRES_DB:-crm}" > "$DEST/crm.sql"
docker volume ls --format '{{.Name}}' | grep -E '^(crm-deploy_)?(postgres_data|redis_data|minio_data)$|^(crm_)?(postgres_data|redis_data|minio_data)$' > "$DEST/volumes.txt" || true
echo "Backup en $DEST (cargar con: psql < crm.sql). Volúmenes en volumes.txt."
