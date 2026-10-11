# crm-deploy — despliegue del CRM Varko

Proyecto aparte con todo lo operativo. El código vive en `jorgeramos2708/crm`
(clonado al lado: `/opt/crm` + `/opt/crm-deploy`).

## Layout

- `docker-compose.yml` — stack prod (postgres dedicado, redis, minio, api,
  worker, web). Sin puertos publicados; sin volúmenes de código.
- `docker-compose.vps.yml` — overlay VPS: `web` a `caddy_net` (Caddy existente).
- `docker-compose.bare.yml` — overlay bare: servicio `edge` (Caddy propio TLS).
- `sites/crm.edrs.xyz.Caddyfile` — bloque para el Caddy existente del VPS.
- `caddy/Caddyfile.edge` — Caddy propio (bare).
- `scripts/` — install/update/backup por objetivo.
- `docs/bare-server.md` — plan servidor bare.

## VPS (109.199.103.81 + Cloudflare, red caddy_net)

```bash
cd /opt/crm-deploy
cp .env.example .env   # rellenar secretos (openssl rand -hex 32)
./scripts/vps-install.sh
```

Hace: build → infra → migrate+seed → app → bloque Caddy + reload → verify
`https://crm.edrs.xyz/api/auth/sso/status`. Cambiar password `admin1234` al
entrar. Updates: `./scripts/vps-update.sh`. Backup: `./scripts/backup.sh`.

## Bare (ver docs/bare-server.md)

```bash
cd /opt/crm-deploy
cp .env.example .env   # + DOMAIN=...
./scripts/bare-install.sh
```
