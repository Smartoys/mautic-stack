# Wire a new Percona/MySQL server into an existing Prometheus + Alertmanager stack

A self-contained brief for a coding agent. No external references — everything
needed is inlined. Replace every `<tenant>`, `<db-network>`, `percona-db`,
`<host>`, `<user>`, and version pin with the real values for the new stack.

## Environment

- A standalone monitoring stack already runs on the same Docker/Portainer host
  as the new Percona server:
  - **Prometheus** v3.2.0, container `monitoring-prometheus`, UI bound to
    `127.0.0.1:9090`. Started with `--web.enable-lifecycle`, so config reloads
    over HTTP without a restart.
  - **Alertmanager** v0.28.0, container `monitoring-alertmanager`, UI bound to
    `127.0.0.1:9093`. Already sends email to the ops address through an internal
    SMTP relay.
- Prometheus reaches exporters over **Docker networks by container DNS name**,
  not over the LAN. It currently joins an internal network shared with
  Alertmanager, plus one external network per metrics source.
- Prometheus config is bind-mounted from the host:
  - `/portainer/monitoring-prometheus/prometheus.yml`
  - `/portainer/monitoring-prometheus/alert.rules.yml`

  > **Note (2026-08-06):** the monitoring stack has moved to
  > [`Smartoys/docker-services`](https://github.com/Smartoys/docker-services)
  > at `observability/monitoring`, and is deployed as a Portainer **Git
  > stack** — Portainer clones the repo on the host, so config is bind-mounted
  > from the checkout rather than hand-copied to `/portainer/...`. Edit the
  > files in that repository, not on the host. The rest of this document is
  > unchanged and still correct.
  - Both files are owned `65534:65534` (the `nobody` user the container runs as).
- The new Percona server lives in a **separate** Docker Compose stack with its
  own network.

## Goal

Expose MySQL metrics from the new Percona server, have the existing Prometheus
scrape them, and route alerts through the existing Alertmanager. **Reuse the
existing monitoring stack — do not deploy a second Prometheus or Alertmanager.**

## Step 1 — Create a metrics MySQL user on the Percona server

```sql
CREATE USER 'exporter'@'%' IDENTIFIED BY '<strong-password>' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
```

## Step 2 — Add a mysqld-exporter to the new Percona stack's compose

Recent `mysqld-exporter` versions no longer take the DSN on the command line —
pass credentials via a config file.

```yaml
services:
  mysqld-exporter:
    image: prom/mysqld-exporter:v0.16.0
    container_name: <tenant>-mysqld-exporter
    hostname: <tenant>-mysqld-exporter        # Prometheus targets this DNS name
    restart: unless-stopped
    command:
      - "--mysqld.address=percona-db:3306"     # service/host name of the DB container
      - "--config.my-cnf=/etc/mysqld-exporter/.my.cnf"
    volumes:
      - /portainer/<tenant>-mysqld-exporter/.my.cnf:/etc/mysqld-exporter/.my.cnf:ro
    networks:
      - <db-network>      # the Percona stack's own network, to reach the DB
      - metrics-net       # shared network Prometheus will join (see Step 3)

networks:
  <db-network>:
    external: true
    name: <db-network>
  metrics-net:
    external: true
    name: metrics-net
```

On the host, create the credentials file (owned so the container can read it;
keep it `600`):

```ini
# /portainer/<tenant>-mysqld-exporter/.my.cnf
[client]
user=exporter
password=<strong-password>
```

- Do **not** publish a LAN port for the exporter; keep it network-internal.
- The exporter listens on `9104` by default.

## Step 3 — Give Prometheus a network path to the exporter

Create one dedicated, attachable metrics network and put both the exporter and
Prometheus on it. Create it once on the host:

```bash
docker network create --attachable metrics-net
```

Then add `metrics-net` as an **external** network to the **monitoring stack's**
compose and attach it to the Prometheus service:

```yaml
services:
  prometheus:
    networks:
      - <existing-internal-net>   # leave existing networks in place
      - metrics-net               # add this

networks:
  metrics-net:
    external: true
    name: metrics-net
```

Redeploy the monitoring stack so Prometheus picks up the new network
(Alertmanager is unaffected). This is the only restart required; later config
changes use hot-reload.

> Design note: a dedicated `metrics-net` is preferred over attaching Prometheus
> directly to each tenant's DB network — it keeps one stable network to manage
> as more exporters are added, and avoids coupling Prometheus to per-tenant DB
> stacks.

## Step 4 — Add the scrape job

Append to `scrape_configs:` in `/portainer/monitoring-prometheus/prometheus.yml`:

```yaml
  - job_name: mysql-<tenant>
    static_configs:
      - targets: ['<tenant>-mysqld-exporter:9104']
        labels:
          instance: <tenant>
```

## Step 5 — Add alert rules

Append a new group to `/portainer/monitoring-prometheus/alert.rules.yml`. Use
both a `severity` and a `stack` label (the Alertmanager route groups on
`[alertname, stack]`, so new alerts flow to the existing email receiver
automatically — no Alertmanager change needed):

```yaml
groups:
  - name: mysql-<tenant>
    interval: 30s
    rules:
      - alert: MysqlDown
        expr: up{job="mysql-<tenant>"} == 0
        for: 2m
        labels:
          severity: critical
          stack: mysql-<tenant>
        annotations:
          summary: "MySQL exporter for <tenant> unreachable"
          description: "Prometheus has been unable to scrape <tenant>-mysqld-exporter for 2 minutes."

      - alert: MysqlTooManyConnections
        expr: (mysql_global_status_threads_connected / mysql_global_variables_max_connections) > 0.8
        for: 5m
        labels:
          severity: warning
          stack: mysql-<tenant>
        annotations:
          summary: "MySQL connections > 80% of max_connections on <tenant>"
          description: "Using {{ $value | humanizePercentage }} of max_connections. Investigate connection leaks or raise the cap."

      # Only if this server is a replica:
      - alert: MysqlReplicationLag
        expr: mysql_slave_status_seconds_behind_master > 60
        for: 5m
        labels:
          severity: warning
          stack: mysql-<tenant>
        annotations:
          summary: "MySQL replica <tenant> lagging > 60s"
          description: "Replica is {{ $value }}s behind master."
```

## Step 6 — Apply config and hot-reload (no restart)

After editing the two files on the host (keep them owned `65534:65534`):

```bash
wget --post-data='' http://127.0.0.1:9090/-/reload
```

## Step 7 — Verify

- The monitoring UIs are loopback-only; reach them via SSH tunnel from your
  workstation:

  ```bash
  ssh -L 9090:127.0.0.1:9090 -L 9093:127.0.0.1:9093 <user>@<host>
  ```

- Open `http://127.0.0.1:9090/targets` and confirm `mysql-<tenant>` shows `UP`.
- Open `http://127.0.0.1:9090/rules` and confirm the new rule group loaded.

## Constraints / gotchas

- Keep both UIs loopback-only — do not add LAN port bindings.
- Network names in the producing stack must exactly match the `external:`
  declarations on the monitoring stack, or Prometheus silently fails to resolve
  the target.
- Don't touch Alertmanager's existing email/SMTP wiring; new alerts route
  through it as-is.
- Replace every placeholder with the real values for the new stack before
  deploying.
ok 