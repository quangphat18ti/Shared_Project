# Prometheus Fiber Demo with Kafka, MongoDB, and MinIO

## Overview

This comprehensive demo showcases Prometheus monitoring for a complete microservices stack:

- **3 monitored Fiber apps**: `app1`, `app2`, `app3` (with CPU, RAM, network metrics)
- **Kafka**: Message broker with consumer lag and throughput metrics
- **MongoDB**: Document database with ops/sec, query latency, and resource metrics
- **MinIO**: S3-compatible object storage with usage and request metrics
- **Prometheus**: Central metrics aggregation and querying
- **Metrics API**: Aggregates and summarizes metrics across all services

## Quick Start

### 1. Start All Services

```bash
docker compose up --build
```

First startup takes 2-3 minutes for all services to initialize. Wait for messages like:
```
prometheus_1 | level=info ts=... msg="Server is ready to receive web requests"
```

### 2. Verify Services Are Running

```bash
# Check container status
docker compose ps

# Expected output (all should be healthy):
# CONTAINER     STATUS
# app1          Up (healthy)
# app2          Up (healthy)
# app3          Up (healthy)
# mongodb       Up (healthy)
# mongodb-exporter Up (healthy)
# kafka         Up (healthy)
# kafka-exporter Up (healthy)
# minio         Up (healthy)
# prometheus    Up (healthy)
# metrics-api   Up (healthy)
```

### 3. Access Web UIs

| Service | URL | Credentials |
|---------|-----|-------------|
| **App 1** | http://localhost:8081 | - |
| **App 2** | http://localhost:8082 | - |
| **App 3** | http://localhost:8083 | - |
| **Prometheus** | http://localhost:9090 | - |
| **Metrics API** | http://localhost:8090 | - |
| **MongoDB** | mongodb://admin:password123@localhost:27017 | admin/password123 |
| **MinIO Console** | http://localhost:9001 | minioadmin/minioadmin123 |

## Detailed Architecture

### Kafka Setup
- **Zookeeper** (port 2181): Kafka cluster coordination
- **Kafka Broker** (port 9092, 29092): Message broker with JMX enabled
- **JMX Exporter** (port 5556): Converts Kafka JMX metrics to Prometheus format
- **Metrics Collected**:
  - Consumer lag (messages behind)
  - Messages/bytes in and out per second
  - Under-replicated partitions
  - ISR (In-Sync Replica) shrinks
  - Producer/broker performance

### MongoDB Setup
- **MongoDB** (port 27017): Database with profiling enabled
- **MongoDB Exporter** (port 9216): Exports MongoDB metrics
- **Metrics Collected**:
  - Operations per second (read/write/update/delete)
  - Query latency (avg response time)
  - Memory usage (resident and virtual)
  - CPU usage and page faults
  - Connection pool status
  - Replication lag (if using replica sets)
  - Network in/out bytes
  - Lock acquisition times

### MinIO Setup
- **MinIO** (ports 9000 API, 9001 Console): S3-compatible object storage
- **Metrics Collected**:
  - Storage usage and free space
  - Request rates by method (GET, PUT, DELETE)
  - Request latency (response times)
  - Upload/download bandwidth
  - Error rates
  - Per-disk utilization
  - Heal operations

### Fiber Apps
- **Standard Prometheus metrics**: CPU, RAM, network
- **Custom metrics**:
  - `fiber_http_requests_total`: Total requests by method/path/status
  - `fiber_network_in_bytes_total`: Request body bytes
  - `fiber_network_out_bytes_total`: Response body bytes

## Generate Metrics Data

All services need traffic to generate meaningful metrics. Here are examples:

### For Fiber Apps

```bash
# Single request to generate work
curl http://localhost:8081/work

# Batch requests to all apps
for i in {1..10}; do
  curl -s http://localhost:8081/work > /dev/null
  curl -s http://localhost:8082/work > /dev/null
  curl -s http://localhost:8083/work > /dev/null
done

# Generate network traffic (request body bytes)
curl -X POST http://localhost:8081/echo \
  -H "Content-Type: application/json" \
  -d '{"data":"test payload"}'
```

### For Kafka

```bash
# Create a test topic
docker exec -it prometheus_kafka_1 kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1

# Produce messages (press Ctrl+C to stop)
docker exec -it prometheus_kafka_1 kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic

# Type messages:
# > {"key": "value1"}
# > {"key": "value2"}

# Consume messages in another terminal
docker exec -it prometheus_kafka_1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning
```

### For MongoDB

```bash
# Connect to MongoDB
docker exec -it prometheus_mongodb_1 mongosh \
  -u admin \
  -p password123 \
  --authenticationDatabase admin

# In MongoDB shell:
use metrics_db

# Insert documents (generates write ops)
db.users.insertMany([
  { email: "test1@example.com", name: "Test User 1" },
  { email: "test2@example.com", name: "Test User 2" }
])

# Query documents (generates read ops)
db.users.find()

# Create slow query to see latency
db.products.aggregate([
  { $match: { category: "Electronics" } },
  { $group: { _id: "$category", count: { $sum: 1 } } }
])
```

### For MinIO

```bash
# Upload a file
curl -X PUT \
  -u minioadmin:minioadmin123 \
  --data-binary @<local-file> \
  http://localhost:9000/test-bucket/test-file

# Or use MinIO Console: http://localhost:9001
# Log in with minioadmin / minioadmin123
# Create bucket → Upload files
```

## Query Metrics with REST HTTP

The repository includes a comprehensive `queries.rest.http` file with PromQL queries for all metrics.

### Using VS Code REST Client Extension

1. Install extension: [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
2. Open `queries.rest.http`
3. Click "Send Request" above any query

### Example Queries

**Kafka Consumer Lag:**
```
GET http://localhost:9090/api/v1/query?query=sum(kafka_consumer_lag)
```

**MongoDB Ops/Sec:**
```
GET http://localhost:9090/api/v1/query?query=rate(mongodb_op_counters_total[1m])
```

**MinIO Storage Usage %:**
```
GET http://localhost:9090/api/v1/query?query=(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100
```

## Understanding the Metrics

Detailed metric documentation is available in [METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md). Each metric includes:

- **What it measures**: Description of the metric
- **Unit**: Standard unit (msgs, bytes, ms, %)
- **Typical Range**: Expected values for healthy systems
- **What it indicates**: Interpretation and what values mean
- **Business Impact**: Why this metric matters
- **Alert thresholds**: When to raise alerts

### Quick Reference: Key Metrics

| Service | Metric | What It Shows |
|---------|--------|---------------|
| **Kafka** | `kafka_consumer_lag` | Messages behind (lower is better) |
| **Kafka** | `rate(kafka_server_brokertopicmetrics_messagesinpersec_count[1m])` | Message throughput |
| **Kafka** | `kafka_server_replicamanager_underreplicatedpartitions` | Cluster health (0 is good) |
| **MongoDB** | `rate(mongodb_op_counters_total[1m])` | Database operations/sec |
| **MongoDB** | `mongodb_op_counters_latency_avg_ms` | Query response time (lower is better) |
| **MongoDB** | `mongodb_process_resident_memory_bytes` | RAM usage |
| **MinIO** | `minio_cluster_capacity_usable_free_bytes` | Available storage |
| **MinIO** | `rate(minio_s3_requests_total[1m])` | API request rate |
| **MinIO** | `rate(minio_s3_requests_errors_total[1m])` | Error rate (0 is good) |
| **Fiber** | `rate(fiber_network_in_bytes_total[1m])` | API input bandwidth |
| **Fiber** | `process_resident_memory_bytes` | App memory usage |

## Prometheus Query Language (PromQL) Examples

### Filtering and Aggregation
```promql
# Get metrics for specific service
kafka_consumer_lag{topic="test-topic"}

# Sum across all topics
sum(kafka_consumer_lag) by (topic)

# Average response time
avg(mongodb_op_counters_latency_avg_ms)

# Max value across instances
max(minio_disk_free_bytes)
```

### Rate Calculations
```promql
# Requests per second (over 1 minute window)
rate(minio_s3_requests_total[1m])

# Operations per second
rate(mongodb_op_counters_total[1m])

# Bytes per second
rate(kafka_server_brokertopicmetrics_bytesinpersec_count[5m])
```

### Percentiles (Latency Analysis)
```promql
# 95th percentile latency
histogram_quantile(0.95, rate(minio_s3_requests_duration_ms_bucket[5m]))

# 99th percentile latency
histogram_quantile(0.99, rate(minio_s3_requests_duration_ms_bucket[5m]))
```

### Arithmetic Operations
```promql
# Storage usage percentage
(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100

# CPU percentage (single core)
rate(process_cpu_seconds_total[1m]) * 100

# Combined throughput
rate(kafka_server_brokertopicmetrics_messagesinpersec_count[1m]) + rate(mongodb_op_counters_total[1m])
```

### Range Vectors (Time Series Data)
```promql
# 5-minute average request rate
avg_over_time(rate(minio_s3_requests_total[1m])[5m:1m])

# Maximum memory usage over 1 hour
max_over_time(mongodb_process_resident_memory_bytes[1h:5m])
```

## Dashboard Setup

### In Prometheus UI (http://localhost:9090)

1. Click "Graph" tab
2. Enter PromQL query in search box
3. Click "Execute" or press Enter
4. Click "Graph" to visualize

### Suggested Dashboards to Create

1. **Kafka Dashboard**
   - Consumer lag by topic
   - Messages in/out rate
   - Under-replicated partitions

2. **MongoDB Dashboard**
   - Operations/sec (read vs write)
   - Query latency P95/P99
   - Memory usage trend
   - Connection count

3. **MinIO Dashboard**
   - Storage usage gauge
   - Request rate by method
   - Error rate
   - Upload/download bandwidth

4. **System Overview**
   - Combined throughput (all services)
   - Error rates (all services)
   - Resource usage (CPU, memory, disk)

## Troubleshooting

### Prometheus Can't Scrape Services

Check if services are healthy:
```bash
# Check Docker network
docker network inspect prometheus_monitoring

# Check if ports are reachable
curl http://localhost:5556/metrics      # Kafka exporter
curl http://localhost:9216/metrics      # MongoDB exporter
curl http://localhost:9000/minio/...    # MinIO
```

### No Metrics Appearing

1. Wait 2-3 minutes for scrape intervals to complete
2. Check Prometheus targets: http://localhost:9090/targets
3. Verify services are generating traffic (use examples above)
4. Check logs: `docker compose logs <service-name>`

### High Latency or Memory Issues

- Adjust `global.scrape_interval` in `prometheus/prometheus.yml` (currently 5s)
- Reduce `storage.tsdb.retention.time` (default keeps 15 days)
- Check available disk space for Prometheus data

## Cleanup

```bash
# Stop all services
docker compose down

# Remove volumes (delete all data)
docker compose down -v

# Remove images
docker compose down --rmi all
```

## Next Steps

1. **Create Dashboards**: Use Grafana to visualize metrics
2. **Set Alerts**: Configure alerting rules in Prometheus
3. **Custom Queries**: Write PromQL queries in `queries.rest.http`
4. **Integration**: Connect to external systems (PagerDuty, Slack, etc.)

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Guide](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Kafka Metrics](https://kafka.apache.org/documentation/#monitoring)
- [MongoDB Metrics](https://docs.mongodb.com/manual/reference/database-statistics/)
- [MinIO Metrics](https://min.io/docs/minio/linux/operations/monitoring.html)
- [Fiber Framework](https://docs.gofiber.io/)


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
