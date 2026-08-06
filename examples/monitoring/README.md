# Monitoring stack — MOVED

This stack now lives in **[`Smartoys/docker-services`](https://github.com/Smartoys/docker-services)**
at `observability/monitoring` (branch `develop`).

## Why it moved

It was always documented as tenant-agnostic — *"standalone observability for
any exporter on this Portainer host"* — and it scrapes Dragonfly, ClickHouse
and Vector, none of which are Mautic. Living in a Mautic-specific repository
was a misfiling that made it hard to find and easy to forget.

All portainer1 infrastructure now lives in one repository:

| Concern | Location |
|---|---|
| Prometheus + Alertmanager | `docker-services` → `observability/monitoring` |
| Central log store (ClickHouse) | `docker-services` → `observability/logging` |
| Vector agent template | `docker-services` → `observability/agents` |
| Traefik, Portainer, Redis, RabbitMQ… | `docker-services` → top level |

## What changed in the move

- Prometheus joins the `obs-net` network and scrapes the central log store
  (`clickhouse`, `vector-aggregator`, `vector-agent`, `log-signals` jobs).
- Two new alert-rule groups: `observability-pipeline` and `application-logs`.
- Prometheus gained a `mem_limit` (it previously ran unbounded, with
  GOMEMLIMIT resolving to the whole 23 GB host).

## Nothing to do on the host

The deployed configuration was byte-identical to the copy that lived here, so
this is a repository move, not a redeploy. Apply the new configuration by
deploying `observability/monitoring` as a Portainer Git stack.

## Related documents still in this repo

`wire-percona-into-monitoring.md` still describes how to attach a new metrics
source to this stack. Its instructions remain correct; only the location of
`prometheus.yml` and `alert.rules.yml` has changed.
