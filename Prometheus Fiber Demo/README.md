# Prometheus & Grafana Monitoring Stack

## Overview

This project provides a complete, production-grade monitoring stack using Prometheus and Grafana. It is pre-configured to monitor a distributed infrastructure including Kafka, MongoDB, MinIO, as well as the host machine and individual Docker containers.

### Core Components

- **Prometheus** (Port 9090): Central metrics aggregation and time-series database.
- **Grafana** (Port 3000): Advanced visualization and dashboards.
- **Node Exporter** (Port 9100): Hardware and OS metrics (CPU, RAM, Disk, Network).
- **cAdvisor** (Port 8085): Container-level resource usage and performance metrics.

### Monitored Services

- **Kafka & Zookeeper** (Port 9092 & 2181):
  - **Kafka Exporter** (Port 9308): Tracks Consumer Lag, Topic throughput.
  - **Kafka JMX Exporter** (Port 5556): Tracks JVM Heap, Garbage Collection, CPU usage.
- **MongoDB** (Port 27017):
  - **MongoDB Exporter** (Port 9216): Tracks Ops/sec, Latency, Connections.
- **MinIO** (Port 9000 & 9001):
  - Native Prometheus integration: Tracks Storage usage, API requests, bandwidth.

---

## Quick Start

### 1. Start the Infrastructure

```bash
docker compose up -d
```

_It takes about 1-2 minutes for all services (especially Kafka and MongoDB) to fully initialize._

### 2. Verify Services

```bash
docker compose ps
```

Ensure all containers (`kafka`, `mongodb`, `prometheus`, `grafana`, etc.) are in the `Up` state.

### 3. Generate Sample Data (Crucial)

Metrics are only generated when there is traffic. Run the provided script to simulate traffic and create Consumer Lag in Kafka:

```bash
bash generate-metrics.sh
```

---

## Accessing the Dashboards

| Service           | URL                                             | Credentials (User/Pass)        |
| ----------------- | ----------------------------------------------- | ------------------------------ |
| **Grafana**       | [http://localhost:3000](http://localhost:3000)  | `admin` / `admin123`           |
| **Prometheus**    | [http://localhost:9090](http://localhost:9090)  | (No Auth)                      |
| **MinIO Console** | [http://localhost:9001](http://localhost:9001)  | `minioadmin` / `minioadmin123` |
| **MongoDB**       | `mongodb://admin:adminpassword@localhost:27017` | `admin` / `adminpassword`      |

### Setting up Grafana

1. Go to **Grafana** > **Connections** > **Data Sources** > **Add data source**.
2. Select **Prometheus**.
3. Set the connection URL to: `http://prometheus:9090`
4. Click **Save & Test**. You can now import pre-built dashboards (e.g., from Grafana Labs) for Kafka, MongoDB, Node Exporter, and cAdvisor.

---

## Useful PromQL Queries

You can test these queries directly in Prometheus ([http://localhost:9090/graph](http://localhost:9090/graph)) or use them in Grafana.

**1. Hardware & Containers (Node Exporter & cAdvisor)**

- Host CPU Usage: `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)`
- Container CPU Usage: `rate(container_cpu_usage_seconds_total{container_label_com_docker_compose_service!=""}[1m])`
- Container RAM Usage: `container_memory_usage_bytes{container_label_com_docker_compose_service!=""}`

**2. Kafka Metrics**

- Consumer Lag: `sum(kafka_consumergroup_lag) by (consumergroup, topic)`
- Message Throughput (In): `rate(kafka_server_brokertopicmetrics_messages_in_total[1m])`
- JVM Heap Used: `jvm_memory_heap_used_bytes{service="kafka"}`

**3. MongoDB Metrics**

- Operations Per Second: `rate(mongodb_op_counters_total[1m])`
- Query Latency (Reads): `rate(mongodb_mongod_op_latencies_latency_total{type="reads"}[1m]) / rate(mongodb_mongod_op_latencies_ops_total{type="reads"}[1m])`
- RAM Used (Resident): `mongodb_ss_mem_resident * 1024 * 1024`

**4. MinIO Metrics**

- Storage Usage %: `(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100`
- API Requests/sec: `rate(minio_s3_requests_total[1m])`

---

## Reference Documentation

For a deep dive into what each specific metric means, how to interpret them, and the business impact, please refer to the dedicated **[METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md)** file.

## Cleanup

To completely stop the stack and wipe all data (useful if you encounter data corruption issues):

```bash
docker compose down -v
```
