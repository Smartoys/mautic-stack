# Dragonfly queue stack

A second, **separate** [Dragonfly](https://www.dragonflydb.io/) instance
dedicated to the **Laravel queue backend** (the dlgamer backoffice app). It runs
alongside the cache instance in [`../dragonfly/`](../dragonfly/) on the same
Portainer host and joins the same `redis-net` network — but it is a distinct
container, volume, config, and password set.

## Why a separate instance (not a separate DB index)

A cache *expects* eviction; a queue must **never** be evicted — an evicted job
key is a job that vanishes with no error, and `ShouldBeUnique` locks would
disappear too. Dragonfly's eviction policy is **instance-wide**, not
per-logical-DB, so a different DB index on the cache instance would still be
exposed to its global eviction. Hence a dedicated no-eviction instance.

## No eviction — how it actually works on Dragonfly

Dragonfly does **not** implement Redis's `maxmemory-policy`. `CONFIG SET
maxmemory-policy …` errors, and `CONFIG GET maxmemory-policy` returns empty.
Eviction is controlled **only** by `--cache_mode`:

- The cache instance sets `--cache_mode=true` → it evicts (2Q algorithm) near
  the memory ceiling.
- This queue instance **omits `--cache_mode`** → Dragonfly reports
  `maxmemory_policy:noeviction` and returns an **OOM error on writes** once
  `--maxmemory` is reached, instead of dropping keys.

> Verify with `INFO MEMORY` (look for `maxmemory_policy:noeviction`), **not**
> `CONFIG GET maxmemory-policy` — the latter is unsupported on Dragonfly and
> returns nothing.

## Layout

- `docker-compose.yml` — Dragonfly (queue) + redis_exporter. No RedisInsight /
  Caddy here; add this instance as a second connection in the cache stack's
  existing RedisInsight if you want a UI.
- `config/aclfile` — ACL users (template). Replace every `REPLACE_ME_*` token
  with a real password before copying to the host. **Same strict parser rules
  as the cache stack** (no comments, ASCII only, no subcommand syntax) — see
  [`../dragonfly/README.md`](../dragonfly/README.md#acl-model--read-this-first).

## ACL model

Identical rules to the cache stack — read its README first. `default` **must**
be defined in the on-host aclfile (otherwise the next `ACL LOAD` resets it to
`nopass`), and `DRAGONFLY_ADMIN_PASSWORD` must match that `default` password.

The per-env queue users are scoped to the Laravel app's key prefix and granted
`+@scripting` because Laravel's Redis queue drives its atomic pop/reserve/
release operations through Lua (`EVAL`):

```
user dlgprod on >PASSWORD ~dlgamerbackoffice_database_dlgprod:* &* -@all +@read +@write +@connection -@dangerous +@scripting
```

> **Confirm the prefix.** These users assume the Laravel `redis_queue`
> connection uses the same `dlgamerbackoffice_database_<env>:` prefix as the
> cache connection. If the queue connection sets a different prefix (or none),
> the `~<prefix>*` keyspace pattern must be updated to match, or the worker will
> get `NOPERM` errors. Multiple `~` directives are additive.

## Required Portainer stack env

| Var | Purpose |
|-----|---------|
| `COMPOSE_PROJECT_NAME` | Stack/container prefix — use `dragonfly-queue` |
| `DRAGONFLY_ADMIN_PASSWORD` | First-boot/fallback password for `default` — must also be set verbatim on `user default …` in the aclfile. **Distinct from the cache instance's password.** |
| `REDIS_EXPORTER_PASSWORD` | Must match the `metrics` user in this aclfile |

> All three are a **separate, distinct** set from the cache stack. Do not reuse
> the cache passwords.

## Pre-deploy (host side)

```bash
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-data
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-config

sudo cp config/aclfile /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile
sudoedit /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile   # replace REPLACE_ME_*

sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-data
sudo chown -R 999:999 /portainer/${COMPOSE_PROJECT_NAME}-config
sudo chmod 0640 /portainer/${COMPOSE_PROJECT_NAME}-config/aclfile
```

The `redis-net` network is created by the cache stack; deploy that first (or at
least let it create the network) so this stack can join it as `external`.

## Endpoints

- Laravel worker (over `redis-net`): `redis://dlgprod:<password>@dragonfly-queue:6379`
  (use the per-env user; or `default` for admin tasks)
- Host-only admin port (no auth, loopback): `redis://127.0.0.1:6381`
- Prometheus exporter: scraped at `dragonfly-queue-exporter:9121` over
  `redis-net` (no host port). Add a scrape target in the monitoring stack.

There is **no LAN port and no Traefik route** — this instance is reachable only
from containers on `redis-net`.

## Reloading the ACL after edits

```bash
docker exec dragonfly-queue-server redis-cli -p 6380 ACL LOAD
```

`-p 6380` is the in-container loopback admin port (no auth). From the host use
`-p 6381`. `ACL LOAD` is **destructive** — anything not in the file is removed
from the runtime ACL, so always keep `default` in the file. Watch for `Error
materializing acl file` in `docker logs dragonfly-queue-server`.

## Laravel side (separate repo — follow-up, not in this stack)

1. **`config/database.php`** — add a `redis_queue` connection pointing at
   `dragonfly-queue:6379` with its own password env var, distinct from the cache
   connection. Leave the cache connection unchanged.
2. **`config/queue.php`** — point the `redis` queue connection at `redis_queue`;
   set `QUEUE_CONNECTION=redis`.
3. **`.env`** — add the queue host/port/password vars referenced above.
4. **`ShouldBeUnique` locks** use the **cache lock store**, not the queue
   connection — they can stay on the cache Dragonfly or move to `database`. They
   do **not** need to live on this instance. Document the choice.
5. After switching: `php artisan queue:restart` so workers pick up the new
   connection.

## Operational notes

- **No eviction** is the whole point — monitor memory. If usage approaches
  256 MB, the next write **errors** (jobs fail loudly) rather than silently
  dropping. Bump `--maxmemory` (and the container `memory` limit above it) if
  queue depth grows. 256 MB is deliberately modest so it can't starve the cache
  instance of RAM.
- Snapshots: every 5 min to `/portainer/${COMPOSE_PROJECT_NAME}-data` as
  `queue-dump-*.dfs`; a graceful container stop also snapshots. Survive recreate.
- Slowlog: queries > 10 ms captured (last 256). Inspect with `SLOWLOG GET`.

## Verification checklist

- [ ] `docker ps` shows `dragonfly-queue-server` healthy; cache stack unaffected.
- [ ] `redis-cli -p 6381 INFO MEMORY | grep maxmemory_policy` → `noeviction`.
- [ ] From the Laravel container: `redis-cli -h dragonfly-queue -a <pw> PING` → `PONG`.
- [ ] Dispatch a test job → `KEYS *queues:*` shows keys on **this** instance, not
      the cache instance.
- [ ] `docker restart dragonfly-queue-server` → a pending job survives.
- [ ] No LAN port / no Traefik route; queue password distinct from cache.
