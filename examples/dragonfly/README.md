# Dragonfly cache stack

Standalone [Dragonfly](https://www.dragonflydb.io/) deployment for use as a
shared Redis-compatible cache across projects on the CLD Portainer host.
Not currently wired into any Mautic stack.

## Layout

- `docker-compose.yml` — Dragonfly + redis_exporter + RedisInsight.
- `config/aclfile` — ACL users. Replace `REPLACE_ME_*` tokens before deploying.

## Required Portainer stack env

| Var | Purpose |
|-----|---------|
| `COMPOSE_PROJECT_NAME` | Stack/container prefix (e.g. `dragonfly`) |
| `DRAGONFLY_BIND_IP` | LAN IP to publish 6379 / 9121 / 5540 on |
| `DRAGONFLY_ADMIN_PASSWORD` | Password for the `default` user (via `--requirepass`) |
| `REDIS_EXPORTER_PASSWORD` | Must match the `metrics` user in `config/aclfile` |

## Pre-deploy (host side)

```bash
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-data
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-config
sudo cp config/aclfile /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile
sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-data
sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-config
docker volume create dragonfly-insight-data
```

## Endpoints

- LAN clients: `redis://default:<DRAGONFLY_ADMIN_PASSWORD>@<DRAGONFLY_BIND_IP>:6379`
- Host-only admin port (no auth, loopback): `redis://127.0.0.1:6380`
- Prometheus exporter: `http://<DRAGONFLY_BIND_IP>:9121/metrics`
- RedisInsight UI: `http://<DRAGONFLY_BIND_IP>:5540` (LAN-only, no public exposure)

## Networking

`redis-net` is `attachable: true`, so consumer stacks on the same host can
join it instead of going through the published LAN port. In a consumer
compose, declare it as external:

```yaml
networks:
  redis-net:
    external: true
    name: redis-net
```

Then connect using `redis://default:<password>@dragonfly:6379`.

## Operational notes

- ACL changes: edit `/portainer/${COMPOSE_PROJECT_NAME}-config/aclfile` on the
  host, then reload with
  `docker exec dragonfly-server redis-cli -a "$DRAGONFLY_ADMIN_PASSWORD" ACL LOAD`.
  No restart needed.
- Snapshots: written every 30 min to `/portainer/${COMPOSE_PROJECT_NAME}-data`
  as `dump-*.dfs`. Survive container recreate.
- Slowlog: queries > 10 ms are captured (last 256). Inspect with `SLOWLOG GET`.
- RedisInsight state lives in the `dragonfly-insight-data` named volume — not
  in `/portainer/...` — so `compose down -v` will not wipe it (the volume is
  declared `external`).
