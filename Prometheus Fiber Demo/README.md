# Prometheus Fiber Demo

This demo runs:

- 3 monitored Fiber apps: `app1`, `app2`, `app3`
- 1 Fiber metrics API that queries Prometheus
- 1 Prometheus server

The metrics API collects these 4 values for every Fiber app:

- RAM: `process_resident_memory_bytes`
- CPU: `rate(process_cpu_seconds_total[1m])`
- Network In: `rate(fiber_network_in_bytes_total[1m])`
- Network Out: `rate(fiber_network_out_bytes_total[1m])`

Network In and Out are demo HTTP body byte counters exposed by each Fiber app. They do not include TCP/IP headers.

## Project Structure

```text
.
├── cmd
│   ├── fiber-app       # monitored Fiber app
│   └── metrics-api     # Fiber app that queries Prometheus
├── prometheus
│   └── prometheus.yml  # scrape configuration
├── docker-compose.yml
├── Dockerfile
├── Prometheus.md
└── README.md
```

## Run

```bash
docker compose up --build
```

Open these URLs:

- App 1: http://localhost:8081
- App 2: http://localhost:8082
- App 3: http://localhost:8083
- Metrics API: http://localhost:8090/metrics-summary
- Prometheus UI: http://localhost:9090

## Generate Traffic

Prometheus needs traffic before the network metrics become interesting.

```bash
curl http://localhost:8081/work
curl http://localhost:8082/work
curl http://localhost:8083/work
```

Run a small loop:

```bash
for i in 1 2 3 4 5; do
  curl -s http://localhost:8081/work > /dev/null
  curl -s http://localhost:8082/work > /dev/null
  curl -s http://localhost:8083/work > /dev/null
done
```

Generate request body traffic for Network In:

```bash
curl -s -X POST http://localhost:8081/echo -d '{"hello":"app1"}' > /dev/null
curl -s -X POST http://localhost:8082/echo -d '{"hello":"app2"}' > /dev/null
curl -s -X POST http://localhost:8083/echo -d '{"hello":"app3"}' > /dev/null
```

Then query the metrics API:

```bash
curl http://localhost:8090/metrics-summary
```

Example response:

```json
{
  "timestamp": "2026-05-04T01:00:00Z",
  "apps": [
    {
      "service": "app1",
      "ram_bytes": 11182080,
      "cpu_percent": 0.7,
      "network_in_bytes_per_second": 0,
      "network_out_bytes_per_second": 55.2,
      "prometheus_label": "app=\"app1\""
    }
  ]
}
```

You can query one service:

```bash
curl http://localhost:8090/metrics-summary/app1
```

## Stop

```bash
docker compose down
```

Remove Prometheus data too:

```bash
docker compose down -v
```

## Files To Reuse In Your Real Apps

- Add `/metrics` to each Fiber app using `promhttp`.
- Add app labels in `prometheus/prometheus.yml`.
- Reuse the query logic in `cmd/metrics-api/main.go`.
- Update `APP_SERVICES` in `docker-compose.yml` when app names change.

See [Prometheus.md](./Prometheus.md) for the Prometheus queries and integration notes.
