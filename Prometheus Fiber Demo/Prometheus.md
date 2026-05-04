# Prometheus Setup For Fiber Apps

## How This Demo Works

Each Fiber app exposes a `/metrics` endpoint. Prometheus scrapes those endpoints every 5 seconds.

```yaml
scrape_configs:
  - job_name: fiber-apps
    metrics_path: /metrics
    static_configs:
      - targets:
          - app1:8080
        labels:
          app: app1
```

The `app` label is important. The metrics API uses it to query data for one app at a time.

## Metrics Exposed By Each App

Built-in Go/process metrics:

- `process_resident_memory_bytes`: current resident memory used by the app process
- `process_cpu_seconds_total`: total CPU seconds consumed by the app process
- `go_*`: Go runtime metrics

Custom Fiber demo metrics:

- `fiber_http_requests_total`: request count by app, method, path, and status
- `fiber_network_in_bytes_total`: request body bytes received
- `fiber_network_out_bytes_total`: response body bytes sent

## Queries

Replace `app1` with `app2` or `app3`.

### RAM

```promql
process_resident_memory_bytes{app="app1"}
```

Unit: bytes.

### CPU

```promql
rate(process_cpu_seconds_total{app="app1"}[1m]) * 100
```

Unit: percent of one CPU core.

Example: `25` means around 25% of one core. `150` means around 1.5 cores.

### Network In

```promql
rate(fiber_network_in_bytes_total{app="app1"}[1m])
```

Unit: HTTP request body bytes per second.

### Network Out

```promql
rate(fiber_network_out_bytes_total{app="app1"}[1m])
```

Unit: HTTP response body bytes per second.

## Metrics API Endpoints

Health:

```bash
curl http://localhost:8090/health
```

All apps:

```bash
curl http://localhost:8090/metrics-summary
```

One app:

```bash
curl http://localhost:8090/metrics-summary/app1
```

## Add Another Fiber App

1. Add a new service in `docker-compose.yml`.
2. Add the service to `APP_SERVICES`.
3. Add the target and `app` label in `prometheus/prometheus.yml`.

Example:

```yaml
app4:
  build:
    context: .
    args:
      TARGET: cmd/fiber-app
  environment:
    APP_NAME: app4
    PORT: 8080
  ports:
    - "8084:8080"
```

Update the metrics API environment:

```yaml
APP_SERVICES: app1,app2,app3,app4
```

Update Prometheus:

```yaml
- targets:
    - app4:8080
  labels:
    app: app4
```

Restart:

```bash
docker compose up --build
```

## Notes For Production

- Keep `/metrics` private. Expose it only inside your internal Docker/Kubernetes network.
- Use stable labels such as `app`, `service`, and `environment`.
- For container-level network metrics, add cAdvisor or your orchestrator metrics source.
- For Kubernetes, prefer `ServiceMonitor` or `PodMonitor` if you use Prometheus Operator.
- Store Prometheus data on a persistent volume.
