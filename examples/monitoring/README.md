# Monitoring stack (Prometheus + Alertmanager)

Standalone observability for any exporter on the CLD Portainer host. Currently
scrapes Dragonfly's `redis_exporter`; add more `scrape_configs` to extend.

UIs are loopback-only — access via SSH tunnel, never publish them.

## Layout

- `docker-compose.yml` — Prometheus 3.x + Alertmanager 0.28.
- `config/prometheus.yml` — scrape configs + alertmanager target.
- `config/alert.rules.yml` — alert rules (dragonfly memory, down, eviction).
- `config/alertmanager.yml` — notification routing (fill in your receiver
  before deploy).

## Required Portainer stack env

| Var | Purpose |
|---|---|
| `COMPOSE_PROJECT_NAME` | Stack/container prefix (e.g. `monitoring`) |

## Pre-deploy (host side)

```bash
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-prometheus/data
sudo mkdir -p /portainer/${COMPOSE_PROJECT_NAME}-alertmanager/data

sudo cp config/prometheus.yml   /portainer/${COMPOSE_PROJECT_NAME}-prometheus/prometheus.yml
sudo cp config/alert.rules.yml  /portainer/${COMPOSE_PROJECT_NAME}-prometheus/alert.rules.yml
sudo cp config/alertmanager.yml /portainer/${COMPOSE_PROJECT_NAME}-alertmanager/alertmanager.yml

# Fill in your notification receiver — Slack / email / webhook / etc.
sudoedit /portainer/${COMPOSE_PROJECT_NAME}-alertmanager/alertmanager.yml

# Prometheus and Alertmanager containers run as UID 65534 (nobody).
sudo chown -R 65534:65534 /portainer/${COMPOSE_PROJECT_NAME}-prometheus
sudo chown -R 65534:65534 /portainer/${COMPOSE_PROJECT_NAME}-alertmanager
```

The stack depends on `redis-net` already existing (the dragonfly stack creates
it). Deploy dragonfly first.

## Access (SSH tunnel)

```bash
ssh -L 9090:127.0.0.1:9090 -L 9093:127.0.0.1:9093 dsonnet@192.168.81.67
# then in a browser:
#   http://127.0.0.1:9090   — Prometheus UI (query, targets, rules)
#   http://127.0.0.1:9093   — Alertmanager UI (active alerts, silences)
```

## Verify after deploy

- Prometheus targets: http://127.0.0.1:9090/targets → `dragonfly` job should
  show `UP`.
- Active alerts: http://127.0.0.1:9090/alerts
- Test the notification chain by silencing-then-firing a rule, or temporarily
  lower the `DragonflyMemoryHigh` threshold and `ACL LOAD` enough fake data
  to trip it.

## Reloading config without restart

Prometheus has `--web.enable-lifecycle`, so config and rule changes can be
hot-reloaded:

```bash
docker exec monitoring-prometheus wget -q --post-data='' http://localhost:9090/-/reload -O -
```

Alertmanager has the same:

```bash
docker exec monitoring-alertmanager wget -q --post-data='' http://localhost:9093/-/reload -O -
```

## Adding more exporters

1. Drop the new exporter on `redis-net` (or whatever network its targets are
   on — Prometheus can be `network connect`ed to any).
2. Add a `scrape_configs` entry in `config/prometheus.yml`:
   ```yaml
   - job_name: my-thing
     static_configs:
       - targets: ['my-thing-exporter:9999']
   ```
3. Copy to host, reload Prometheus (see above).
4. Add alert rules in `alert.rules.yml`, reload again.

## Storage

- Prometheus TSDB at `/portainer/${COMPOSE_PROJECT_NAME}-prometheus/data`,
  30-day retention.
- Alertmanager state at `/portainer/${COMPOSE_PROJECT_NAME}-alertmanager/data`
  (silences, notification history).
