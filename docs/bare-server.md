# Plan servidor bare (sin otros contenedores ni Cloudflare)

## Requisitos

- Ubuntu 22.04/24.04 con Docker Engine + plugin compose (verificar con
  `docker compose version`, mínimo 2.24 por `!reset` si se usa; este proyecto
  no lo necesita).
- DNS: registro A de `DOMAIN` apuntando a la IP pública (DNS directo, sin
  proxy; Let's Encrypt valida por HTTP-01 en puerto 80).
- Firewall: abiertos 80/tcp y 443/tcp al mundo; SSH restringido a tu IP.
- Mínimo 2 vCPU / 4 GB RAM / 20 GB disco (build de Vite es lo más pesado).

## Despliegue

1. Clonar app + deploy lado a lado:
   `git clone <crm> /opt/crm`, `git clone <crm-deploy> /opt/crm-deploy`.
2. `cp .env.example .env`, rellenar secretos y `DOMAIN`, con
   `FRONTEND_URL/CORS_ORIGIN/GRAPH_PUBLIC_URL=https://$DOMAIN`.
3. `./scripts/bare-install.sh` (build → infra → migrate+seed → app+edge).
4. Verificar `https://$DOMAIN/` + login + `/api/auth/sso/status`.
5. Cambiar password admin inicial.

## Diferencias vs VPS

- Sin Cloudflare: sin WAF, sin bot-fight, sin caché CDN. El rate-limit de
  nginx (`/api` 30r/s, login 15r/m) sigue aplicando en `web`.
- Sin proxy previo: Caddy `edge` termina TLS directo (cert LE automático,
  renovación sola). HSTS activado.
- Postgres/redis/minio son del stack (volúmenes `postgres_data`, etc.).
  Respaldar con `./scripts/backup.sh` a almacenamiento externo (cron
  recomendado: `0 3 * * * /opt/crm-deploy/scripts/backup.sh`).
- OAuth: registrar en Google/Entra las callbacks
  `https://$DOMAIN/api/auth/{google,microsoft}/login/callback` (+ `/callback`
  de conexión) y pegar credenciales en Configuración del CRM.
- Updates: `git pull` en ambos repos + `./scripts/bare-install.sh` no; usar
  mismo flujo que `vps-update.sh` adaptado (pull, build api/worker/web,
  migrate, up).

## Endurecimiento sugerido (no incluido)

- UFW: `ufw allow 80,443/tcp` + `limit 2222/tcp` (o puerto SSH custom).
- `unattended-upgrades` para parches del SO.
- Monitoreo externo del 200 de `https://$DOMAIN/`.
