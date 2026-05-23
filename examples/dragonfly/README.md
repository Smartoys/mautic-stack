# Dragonfly cache stack

Standalone [Dragonfly](https://www.dragonflydb.io/) deployment for use as a
shared Redis-compatible cache across projects on the CLD Portainer host.
Not currently wired into any Mautic stack.

## Layout

- `docker-compose.yml` — Dragonfly + redis_exporter + RedisInsight.
- `config/aclfile` — ACL users (template). Replace every `REPLACE_ME_*` token
  with a real password before copying to the host.

## ACL model — read this first

After Dragonfly loads `--aclfile`, the file is the **single source of truth**
for all users, including `default`. `--requirepass` only acts as a first-boot
failsafe (and a fallback if the aclfile fails to parse). Two consequences:

1. **`default` must be defined in `config/aclfile`.** If you omit it, the next
   `ACL LOAD` resets `default` to `nopass` — i.e. anyone on the LAN can connect
   to `:6379` with no auth and get full admin. (Yes, this has happened here.)
2. **Real passwords live only on the host**, in
   `/portainer/${COMPOSE_PROJECT_NAME}-config/aclfile`. The repo template ships
   with `REPLACE_ME_*` placeholders so secrets never touch git.

The `DRAGONFLY_ADMIN_PASSWORD` env var must match the password set on the
`default` user in the on-host aclfile, otherwise the failsafe (and tools like
the loopback admin port checks) become inconsistent with normal client auth.

Dragonfly's ACL parser is strict:
- **No comments.** Lines starting with `#` are accepted but the file fails to
  materialize if anything else is off. Keep it user-lines only.
- **No subcommand syntax.** Use `+config`, not `+config|get`.
- **ASCII only.** No em-dashes etc. in any line.

## Required Portainer stack env

| Var | Purpose |
|-----|---------|
| `COMPOSE_PROJECT_NAME` | Stack/container prefix (e.g. `dragonfly`) |
| `DRAGONFLY_BIND_IP` | LAN IP to publish 6379 / 9121 / 5540 on |
| `DRAGONFLY_ADMIN_PASSWORD` | First-boot/fallback password for `default` — must also be set verbatim on `user default ...` in the aclfile |
| `REDIS_EXPORTER_PASSWORD` | Must match the `metrics` user in the aclfile |

## Pre-deploy (host side)

```bash
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-data
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-config

# Copy the template, then replace every REPLACE_ME_* with a real password.
# Each `user <name> on >REPLACE_ME_... ...` line needs its own password.
sudo cp config/aclfile /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile
sudoedit /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile

sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-data
sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-config
sudo chmod 0640 /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile

docker volume create dragonfly-insight-data
```

The password you put on `user default ...` in the aclfile must also be set as
`DRAGONFLY_ADMIN_PASSWORD` in the Portainer stack env.

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

## Adding a user

Pattern for a per-app/per-env cache user, scoped to a key prefix:

```
user <name> on >PASSWORD ~<prefix>* -@all +@read +@write +@connection -@dangerous
```

- `~<prefix>*` — keyspace pattern (glob). Restricts the user to keys matching
  this prefix. Multiple `~` directives are additive.
- Omitting `&` denies all pub/sub — fine for plain caches. Add `&*` if you
  need pub/sub.
- `+@read +@write +@connection -@dangerous` gives GET/SET/DEL/MGET/MSET/SCAN/
  UNLINK/INCR/EXPIRE/TTL + AUTH/PING/CLIENT, while blocking KEYS, FLUSHDB,
  FLUSHALL, CONFIG, DEBUG, etc.

After editing the host aclfile, reload:

```bash
docker exec dragonfly-server redis-cli -p 6380 ACL LOAD
```

(`-p 6380` is the loopback admin port — no auth needed. The `redis-cli -a`
flag with the admin password works too if you prefer 6379.)

Verify with `ACL LIST` / `ACL GETUSER <name>`. Watch for `Error materializing
acl file` in `docker logs dragonfly-server` — that means the parser rejected
the file (see ACL model section for the strict rules).

## Operational notes

- **`ACL LOAD` is destructive.** Anything not in the file is removed from the
  runtime ACL. Always include `default` in the file with the same password
  as `DRAGONFLY_ADMIN_PASSWORD`.
- Snapshots: written every 30 min to `/portainer/${COMPOSE_PROJECT_NAME}-data`
  as `dump-*.dfs`. Survive container recreate.
- Slowlog: queries > 10 ms are captured (last 256). Inspect with `SLOWLOG GET`.
- RedisInsight state lives in the `dragonfly-insight-data` named volume — not
  in `/portainer/...` — so `compose down -v` will not wipe it (the volume is
  declared `external`).
