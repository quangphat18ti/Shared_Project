# Prometheus Setup and Configuration Guide

## Overview

This guide explains the complete Prometheus monitoring stack including setup of Kafka, MongoDB, and MinIO exporters.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Prometheus (9090)                       │
│  Central metrics aggregation and PromQL query engine         │
└──────┬────────────────────────────────────────────────────────┘
       │ scrapes every 5 seconds
       │
       ├─► Fiber Apps (8081-8083)
       │   └─ /metrics endpoint (Prometheus client library)
       │
       ├─► JMX Exporter (5556)
       │   └─ Kafka broker JMX → Prometheus metrics
       │
       ├─► MongoDB Exporter (9216)
       │   └─ MongoDB server → Prometheus metrics
       │
       └─► MinIO (9000)
           └─ /minio/v2/metrics/cluster endpoint

```

## Service Dependencies

```
Fiber Apps
  ↓ (expose metrics)
Prometheus ← queries every 5s

Kafka ↔ JMX Exporter → Prometheus
  ↑     ↓
Zookeeper

MongoDB → MongoDB Exporter → Prometheus

MinIO → (built-in metrics) → Prometheus
```

## How This Demo Works

Each service exposes metrics in Prometheus text format. Prometheus scrapes every 5 seconds.

### Fiber Apps

Each Fiber app exposes `/metrics` endpoint:

```yaml
scrape_configs:
  - job_name: fiber-apps
    metrics_path: /metrics
    static_configs:
      - targets: [app1:8080, app2:8080, app3:8080]
        labels: {app: app1}
```

**Metrics exposed**:

- `process_resident_memory_bytes`: RAM used by app
- `process_cpu_seconds_total`: CPU time consumed
- `fiber_http_requests_total`: Request count by method/path/status
- `fiber_network_in_bytes_total`: Request body bytes
- `fiber_network_out_bytes_total`: Response body bytes
- `go_*`: Go runtime metrics

### Kafka with JMX Exporter

Kafka broker exposes JMX metrics on port 9999. JMX Exporter converts these to Prometheus format on port 5556.

```yaml
scrape_configs:
  - job_name: kafka
    static_configs:
      - targets: [kafka-exporter:5556]
```

**Metrics exposed** (samples):
- `kafka_server_brokerinfo_version`: Broker version
- `kafka_server_brokertopicmetrics_messagesinpersec_count`: Messages/sec
- `kafka_consumer_lag`: Consumer lag by topic/group
- `kafka_server_replicamanager_underreplicatedpartitions`: Cluster health

### MongoDB with MongoDB Exporter

MongoDB Exporter connects to MongoDB, queries metrics, and exposes them on port 9216.

```yaml
scrape_configs:
  - job_name: mongodb
    static_configs:
      - targets: [mongodb-exporter:9216]
```

**Metrics exposed** (samples):
- `mongodb_op_counters_total`: Operations by type
- `mongodb_op_counters_latency_avg_ms`: Query latency
- `mongodb_process_resident_memory_bytes`: Memory usage
- `mongodb_connections_current`: Active connections

### MinIO with Built-in Metrics

MinIO has native Prometheus metrics endpoint at `/minio/v2/metrics/cluster`.

```yaml
scrape_configs:
  - job_name: minio
    metrics_path: /minio/v2/metrics/cluster
    static_configs:
      - targets: [minio:9000]
```

**Metrics exposed** (samples):
- `minio_cluster_capacity_usable_total_bytes`: Total storage
- `minio_s3_requests_total`: Request count by method
- `minio_cluster_objects_total`: Object count
- `minio_disk_free_bytes`: Free disk space

## Configuration Files

### prometheus/prometheus.yml

Main configuration file with all scrape jobs:

```yaml
global:
  scrape_interval: 5s         # Scrape every 5 seconds
  evaluation_interval: 5s     # Evaluate rules every 5 seconds

scrape_configs:
  - job_name: prometheus     # Prometheus self-monitoring
    static_configs:
      - targets: [prometheus:9090]

  - job_name: fiber-apps     # Fiber applications
    metrics_path: /metrics
    static_configs:
      - targets: [app1:8080, app2:8080, app3:8080]

  - job_name: kafka          # Kafka metrics via JMX exporter
    static_configs:
      - targets: [kafka-exporter:5556]

  - job_name: mongodb        # MongoDB metrics
    static_configs:
      - targets: [mongodb-exporter:9216]

  - job_name: minio          # MinIO object storage
    metrics_path: /minio/v2/metrics/cluster
    static_configs:
      - targets: [minio:9000]
```

### prometheus/kafka-jmx-config.yml

JMX Exporter configuration file that defines which Kafka JMX beans to capture:

```yaml
lowercaseOutputName: true              # Lowercase metric names
lowercaseOutputLabelNames: true        # Lowercase label names

rules:
  # Broker metrics
  - pattern: "kafka.server<type=(.+)><name=([^,]+)><>Value"
    name: kafka_server_$1_$2

  # Consumer metrics
  - pattern: "kafka.consumer<type=(.+)><name=([^,]+)><>Value"
    name: kafka_consumer_$1_$2

  # Producer metrics
  - pattern: "kafka.producer<type=(.+)><name=([^,]+)><>Value"
    name: kafka_producer_$1_$2
```

### prometheus/mongo-init.js

MongoDB initialization script:

```javascript
// Switch to metrics database
db = db.getSiblingDB('metrics_db');

// Create collections with indexes
db.createCollection('users');
db.users.createIndex({ email: 1 }, { unique: true });

// Enable query profiling to measure latency
db.setProfilingLevel(1, { slowms: 100 });

// Insert test data
db.users.insertMany([
  { email: 'user1@example.com', name: 'User One' },
  { email: 'user2@example.com', name: 'User Two' }
]);
```

## Common PromQL Queries

### Fiber Apps

```promql
# RAM usage for app1
process_resident_memory_bytes{app="app1"}

# CPU usage percentage for app1
rate(process_cpu_seconds_total{app="app1"}[1m]) * 100

# Request rate for all apps
rate(fiber_http_requests_total[1m])

# Network throughput for app2
rate(fiber_network_out_bytes_total{app="app2"}[1m])
```

### Kafka

```promql
# Consumer lag for all topics
sum(kafka_consumer_lag) by (topic)

# Message throughput
rate(kafka_server_brokertopicmetrics_messagesinpersec_count[1m])

# Bytes per second
rate(kafka_server_brokertopicmetrics_bytesinpersec_count[1m])

# Cluster health: should be 0
kafka_server_replicamanager_underreplicatedpartitions
```

### MongoDB

```promql
# Operations per second
rate(mongodb_op_counters_total[1m])

# Query latency in milliseconds
mongodb_op_counters_latency_avg_ms

# Memory usage in GB
mongodb_process_resident_memory_bytes / 1024 / 1024 / 1024

# Active connections
mongodb_connections_current

# CPU usage percentage
rate(mongodb_process_cpu_seconds_total[1m]) * 100
```

### MinIO

```promql
# Storage usage in GB
minio_cluster_capacity_usable_total_bytes / 1024 / 1024 / 1024

# Free storage in GB
minio_cluster_capacity_usable_free_bytes / 1024 / 1024 / 1024

# Storage usage percentage
(1 - minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes) * 100

# Request rate
rate(minio_s3_requests_total[1m])

# Error rate
rate(minio_s3_requests_errors_total[1m])
```

## Testing Metrics Locally

### Generate Fiber App Traffic

```bash
# Single request
curl http://localhost:8081/work

# Batch requests
for i in {1..10}; do
  curl -s http://localhost:8081/work > /dev/null
  curl -s http://localhost:8082/work > /dev/null
  curl -s http://localhost:8083/work > /dev/null
done
```

### Generate Kafka Metrics

```bash
# Create topic
docker exec prometheus_kafka_1 kafka-topics \
  --create \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --partitions 3

# Produce messages
docker exec -i prometheus_kafka_1 kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic << EOF
{"msg": "test1"}
{"msg": "test2"}
{"msg": "test3"}
EOF

# Consume messages
docker exec prometheus_kafka_1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

### Generate MongoDB Metrics

```bash
# Connect to MongoDB
docker exec -it prometheus_mongodb_1 mongosh \
  -u admin \
  -p password123 \
  --authenticationDatabase admin

# In mongosh shell:
use metrics_db

# Insert data (write ops)
db.users.insertMany([
  { email: "test1@example.com", name: "Test 1" },
  { email: "test2@example.com", name: "Test 2" }
])

# Query data (read ops)
db.users.find()

# Update data (update ops)
db.users.updateOne({ email: "test1@example.com" }, { $set: { name: "Updated" } })
```

### Generate MinIO Metrics

```bash
# Using AWS CLI or MinIO client
mc alias set minio http://localhost:9000 minioadmin minioadmin123

# Create bucket
mc mb minio/test-bucket

# Upload file
mc cp /path/to/file minio/test-bucket/

# Download file
mc cp minio/test-bucket/file ./
```

## Accessing Prometheus UI

Open http://localhost:9090 in browser:

1. **Graph tab**: Write PromQL queries
2. **Targets tab** (http://localhost:9090/targets): Check if services are being scraped
   - Green "UP" = successfully scraping
   - Red "DOWN" = connection failed
3. **Alerts tab**: View active alerts
4. **Status > Configuration**: View loaded prometheus.yml

## Troubleshooting

### Services not appearing in Prometheus

1. Check targets: http://localhost:9090/targets
2. Look for red "DOWN" status
3. Check logs: `docker compose logs <service>`

### No metrics showing up

1. Wait 2-3 minutes (need full scrape cycle)
2. Verify services are generating traffic
3. Check if target is healthy: `docker compose ps`

### High memory usage

1. Reduce `scrape_interval` from 5s to 30s or 60s
2. Reduce retention time in docker-compose.yml
3. Drop unnecessary metrics using relabeling

## Production Considerations

**Current setup is for demo only. For production**:

1. **Security**: Add authentication, TLS, firewall rules
2. **Data Retention**: Configure appropriate retention based on disk size
3. **High Availability**: Run multiple Prometheus instances with Thanos
4. **Backup**: Regular backups of `/prometheus` directory
5. **Alerting**: Configure alert manager and notification channels
6. **Dashboards**: Create Grafana dashboards for visualization
7. **Resource Limits**: Set CPU/memory limits on containers

## Further Reading

- [Prometheus Docs](https://prometheus.io/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Kafka Monitoring](https://kafka.apache.org/documentation/#monitoring)
- [MongoDB Exporter](https://github.com/percona/mongodb_exporter)
- [MinIO Metrics](https://min.io/docs/minio/linux/operations/monitoring.html)


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
