# Quick Start Guide - Prometheus Fiber Demo

Complete setup in 5 steps. Estimated time: 5-10 minutes.

## Step 1: Start All Services (2-3 minutes)

```bash
cd "Prometheus Fiber Demo"
docker compose up --build
```

**Wait for this message in logs:**

```
prometheus_1 | level=info ts=... msg="Server is ready to receive web requests"
```

If you see errors with ports in use, run:

```bash
docker compose down -v
docker compose up --build
```

## Step 2: Verify Services Are Healthy (30 seconds)

Open new terminal and run:

```bash
docker compose ps
```

All services should show `Up (healthy)` or `Up` status.

Verify in browser:

- http://localhost:9090 - Prometheus (should load UI)
- http://localhost:9001 - MinIO Console (should show login)

## Step 3: Generate Metrics (1 minute)

Each service needs traffic to generate metrics. Run this in a terminal:

```bash
# Generate Fiber app metrics
echo "=== Fiber Apps ==="
for i in {1..10}; do
  curl -s http://localhost:8081/work > /dev/null
  curl -s http://localhost:8082/work > /dev/null
  curl -s http://localhost:8083/work > /dev/null
done
echo "Fiber app traffic generated ✓"

# Generate Kafka metrics (create topic)
echo "=== Kafka ==="
docker exec prometheus_kafka_1 kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --partitions 3 2>/dev/null || true

# Produce messages to Kafka
docker exec -i prometheus_kafka_1 kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic << 'EOF'
{"event": "user_signup", "id": "u123"}
{"event": "user_login", "id": "u124"}
{"event": "user_purchase", "id": "u125"}
EOF
echo "Kafka traffic generated ✓"

# Generate MongoDB metrics
echo "=== MongoDB ==="
docker exec -i prometheus_mongodb_1 mongosh \
  -u admin \
  -p password123 \
  --authenticationDatabase admin << 'EOF'
use metrics_db
db.users.insertMany([
  { email: "test1@example.com", name: "Test User 1" },
  { email: "test2@example.com", name: "Test User 2" }
])
db.users.find()
EOF
echo "MongoDB traffic generated ✓"

# Generate MinIO metrics
echo "=== MinIO ==="
echo "Test data" > /tmp/test.txt
curl -X PUT \
  -u minioadmin:minioadmin123 \
  --data-binary @/tmp/test.txt \
  http://localhost:9000/test-bucket/test-file 2>/dev/null || true
echo "MinIO traffic generated ✓"

echo ""
echo "✅ All metrics generated!"
echo "Now check Prometheus at: http://localhost:9090"
```

## Step 4: Query Metrics (2 minutes)

### Option A: Using Prometheus UI

Open http://localhost:9090/graph and try these queries:

**Fiber Apps:**

```promql
process_resident_memory_bytes{app="app1"}
```

**Kafka Consumer Lag:**

```promql
sum(kafka_consumer_lag) by (topic)
```

**MongoDB Ops/Sec:**

```promql
rate(mongodb_op_counters_total[1m])
```

**MinIO Storage:**

```promql
(1 - minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes) * 100
```

### Option B: Using REST HTTP File

1. Install VS Code extension: [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
2. Open `queries.rest.http` file
3. Click "Send Request" on any query
4. Response appears in right panel

## Step 5: Understand Metrics (Read Documentation)

For detailed information about each metric, see:

- **[METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md)** - Complete metric reference
  - What each metric measures
  - Expected units and ranges
  - What values indicate about system health
  - Alert thresholds

- **[Prometheus.md](Prometheus.md)** - Configuration details
  - How exporters work
  - PromQL query examples
  - Troubleshooting guide

- **[README.md](README.md)** - Full setup guide
  - Detailed architecture
  - Advanced traffic generation
  - Dashboard creation

## What You Should See

### Prometheus Targets (http://localhost:9090/targets)

All targets should show **UP** in green:

- `prometheus` - Prometheus itself
- `fiber-apps` - 3 Fiber applications
- `kafka` - Kafka broker metrics
- `mongodb` - MongoDB metrics
- `minio` - MinIO metrics

If any show DOWN, wait 1-2 minutes and refresh.

### Sample Metrics You Can Query

| Component              | Query                                       | Expected Value    |
| ---------------------- | ------------------------------------------- | ----------------- |
| **Fiber App 1 RAM**    | `process_resident_memory_bytes{app="app1"}` | ~10-50 MB (bytes) |
| **Kafka Consumer Lag** | `sum(kafka_consumer_lag)`                   | 0-100 (messages)  |
| **MongoDB Ops/Sec**    | `rate(mongodb_op_counters_total[1m])`       | 1-10 ops/sec      |
| **MinIO Storage %**    | `(1 - (free / total)) * 100`                | 0-100 (%)         |
| **API Requests/Sec**   | `rate(minio_s3_requests_total[1m])`         | 0-10 req/sec      |

## Common Issues & Fixes

### "Port already in use" error

```bash
# Stop all containers
docker compose down -v

# Wait 10 seconds
sleep 10

# Try again
docker compose up --build
```

### No metrics showing in Prometheus

1. **Wait longer**: First scrape takes ~10 seconds. Full picture takes 2-3 minutes.
2. **Generate more traffic**: Run the traffic generation script again
3. **Check targets**: http://localhost:9090/targets - should show UP status
4. **Check logs**: `docker compose logs prometheus | tail -20`

### Service not starting

```bash
# Check logs
docker compose logs <service_name>

# Examples:
docker compose logs kafka
docker compose logs mongodb
docker compose logs prometheus
```

### High CPU/Memory usage

This is normal for first 5 minutes as Prometheus initializes. If persistent:

```yaml
# Edit docker-compose.yml
prometheus:
  deploy:
    resources:
      limits:
        cpus: "1"
        memory: 1G
```

Then: `docker compose restart prometheus`

## Next Steps

1. **Create Dashboards**: Use Grafana for visualization

   ```bash
   docker run -p 3000:3000 grafana/grafana
   # Add Prometheus as datasource
   ```

2. **Set Up Alerts**: Create alert rules in `prometheus/prometheus.yml`

3. **Explore PromQL**: Try more complex queries in [queries.rest.http](queries.rest.http)

4. **Scale Up**: Add more Kafka topics, MongoDB collections, MinIO objects

## Key Files Overview

```
prometheus/
├── prometheus.yml           # Main Prometheus config
├── kafka-jmx-config.yml     # Kafka JMX exporter config
└── mongo-init.js            # MongoDB initialization

queries.rest.http            # All PromQL queries
METRICS_DOCUMENTATION.md     # Complete metric reference
Prometheus.md                # Detailed configuration
README.md                    # Full setup guide
docker-compose.yml           # All services definition
```

## Service URLs

| Service       | URL                                   | User       | Pass          |
| ------------- | ------------------------------------- | ---------- | ------------- |
| Prometheus    | http://localhost:9090                 | -          | -             |
| Metrics API   | http://localhost:8090/metrics-summary | -          | -             |
| Fiber App 1   | http://localhost:8081                 | -          | -             |
| Fiber App 2   | http://localhost:8082                 | -          | -             |
| Fiber App 3   | http://localhost:8083                 | -          | -             |
| MongoDB       | mongodb://localhost:27017             | admin      | password123   |
| MinIO Console | http://localhost:9001                 | minioadmin | minioadmin123 |
| MinIO API     | http://localhost:9000                 | minioadmin | minioadmin123 |
| Kafka         | localhost:9092                        | -          | -             |
| Zookeeper     | localhost:2181                        | -          | -             |

## Stop & Cleanup

```bash
# Stop services (keep data)
docker compose stop

# Stop and remove containers (keep data)
docker compose down

# Stop and remove everything (delete all data)
docker compose down -v

# Remove images
docker compose down --rmi all
```

## Support / Debugging

1. Check **[README.md](README.md#troubleshooting)** Troubleshooting section
2. Check **[Prometheus.md](Prometheus.md#troubleshooting)** for Prometheus issues
3. Run `docker compose logs -f <service>` to see real-time logs
4. Check Prometheus UI targets: http://localhost:9090/targets

---

**You're all set!** Start with Prometheus UI at http://localhost:9090 and explore the metrics. 🎉
