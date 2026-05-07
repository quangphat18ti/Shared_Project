# Complete Project Guide

Welcome to the Prometheus Fiber Demo with Kafka, MongoDB, and MinIO monitoring!

This document serves as your navigation guide to all available documentation and resources.

## 📚 Documentation Map

Read these in order based on your needs:

### For Getting Started (5-10 minutes)
📖 **[QUICK_START.md](QUICK_START.md)**
- Quick 5-step setup guide
- Common issues and fixes
- Basic queries to try
- Service URLs
- **Start here if you just want it running!**

### For Understanding What's Running (15 minutes)
📖 **[SETUP_COMPLETE.md](SETUP_COMPLETE.md)**
- Summary of what was set up
- Architecture overview
- All 50+ PromQL queries listed
- What each component does
- **Read this to understand the big picture**

### For Detailed Metrics Reference (30-60 minutes)
📖 **[METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md)**
- All 42 metrics documented in detail
- What each metric measures
- Units and typical ranges
- Business impact analysis
- Alert threshold recommendations
- **Reference this when you need to understand what a metric means**

### For Configuration Details (30 minutes)
📖 **[Prometheus.md](Prometheus.md)**
- How each service is configured
- Prometheus scraping mechanism
- Configuration file explanations
- Testing metrics locally
- Troubleshooting guide
- **Read this to understand how the system works**

### For Complete Reference (1+ hour)
📖 **[README.md](README.md)**
- Full architecture explanation
- Detailed traffic generation examples
- Dashboard setup guide
- PromQL examples and patterns
- Production considerations
- **The master reference document**

## 📁 Project Structure

```
Prometheus Fiber Demo/
│
├── 📄 Documentation (Read in this order)
│   ├── QUICK_START.md              🟢 Start here! (5 min)
│   ├── SETUP_COMPLETE.md           📋 What was set up
│   ├── METRICS_DOCUMENTATION.md    📊 Metric reference
│   ├── Prometheus.md               ⚙️  Configuration details
│   ├── README.md                   📖 Full reference
│   └── GUIDE.md                    📍 You are here!
│
├── 🐳 Docker & Configuration
│   ├── docker-compose.yml          All services definition
│   ├── Dockerfile                  Fiber app builder
│   └── prometheus/
│       ├── prometheus.yml          Prometheus scrape config
│       ├── kafka-jmx-config.yml    JMX metrics rules
│       └── mongo-init.js           MongoDB setup
│
├── 📝 Queries & Scripts
│   ├── queries.rest.http           50+ PromQL queries
│   └── generate-metrics.sh         Auto traffic generator
│
└── 💻 Source Code
    ├── go.mod                      Go dependencies
    ├── cmd/
    │   ├── fiber-app/main.go       App with metrics
    │   └── metrics-api/main.go     API to query Prometheus
    └── .gitignore
```

## 🚀 Quick Navigation

### "I just want to get this running!"
1. Go to [QUICK_START.md](QUICK_START.md)
2. Follow 5 steps
3. Open http://localhost:9090
4. Done! ✓

### "What exactly was set up for me?"
→ Read [SETUP_COMPLETE.md](SETUP_COMPLETE.md)

### "What does this metric measure?"
→ Search in [METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md)
- Format: Metric name, unit, what it indicates, business impact

### "How do I query metrics?"
→ Use [queries.rest.http](queries.rest.http) with REST Client extension

### "I want to write my own queries"
→ Read PromQL examples in [README.md](README.md)

### "Something isn't working"
→ Check troubleshooting section in [README.md](README.md#troubleshooting)

### "How does Prometheus scraping work?"
→ Read [Prometheus.md](Prometheus.md)

### "I want to understand the architecture"
→ Read [README.md](README.md) architecture section

## 🎯 Common Tasks

### Task: Generate test metrics
```bash
./generate-metrics.sh
```
Or manually:
```bash
for i in {1..10}; do curl -s http://localhost:8081/work > /dev/null; done
```

### Task: Query Kafka metrics
Use [queries.rest.http](queries.rest.http) → Kafka section
Or in Prometheus UI (http://localhost:9090):
```promql
sum(kafka_consumer_lag) by (topic)
```

### Task: Query MongoDB metrics
Use [queries.rest.http](queries.rest.http) → MongoDB section
Or in Prometheus UI:
```promql
rate(mongodb_op_counters_total[1m])
```

### Task: Query MinIO metrics
Use [queries.rest.http](queries.rest.http) → MinIO section
Or in Prometheus UI:
```promql
(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100
```

### Task: See all targets Prometheus is scraping
http://localhost:9090/targets

### Task: View Prometheus configuration
http://localhost:9090/status/config

### Task: Connect to MongoDB directly
```bash
docker exec -it prometheus_mongodb_1 mongosh \
  -u admin \
  -p password123 \
  --authenticationDatabase admin
```

### Task: Produce to Kafka
```bash
docker exec -i prometheus_kafka_1 kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic test-topic
```

### Task: Access MinIO console
http://localhost:9001 (minioadmin / minioadmin123)

## 📊 What You Can Monitor

| Component | Metrics | Reference |
|-----------|---------|-----------|
| **Kafka** | Consumer lag, throughput, broker health | METRICS_DOCUMENTATION.md section "KAFKA METRICS" |
| **MongoDB** | Ops/sec, latency, memory, CPU, connections | METRICS_DOCUMENTATION.md section "MONGODB METRICS" |
| **MinIO** | Storage, requests, bandwidth, errors | METRICS_DOCUMENTATION.md section "MINIO METRICS" |
| **Fiber Apps** | CPU, RAM, network in/out | METRICS_DOCUMENTATION.md section "FIBER APPS METRICS" |

## 🔗 Service Access

| Service | URL/Connection | User | Pass | Port |
|---------|---|------|------|------|
| Prometheus | http://localhost:9090 | - | - | 9090 |
| MongoDB | mongodb://localhost:27017 | admin | password123 | 27017 |
| MinIO Console | http://localhost:9001 | minioadmin | minioadmin123 | 9001 |
| MinIO API | http://localhost:9000 | minioadmin | minioadmin123 | 9000 |
| Kafka | localhost:9092 | - | - | 9092 |
| Fiber App 1 | http://localhost:8081 | - | - | 8081 |
| Fiber App 2 | http://localhost:8082 | - | - | 8082 |
| Fiber App 3 | http://localhost:8083 | - | - | 8083 |
| Metrics API | http://localhost:8090/metrics-summary | - | - | 8090 |

## ❓ FAQ

**Q: Where do I start?**
A: Go to [QUICK_START.md](QUICK_START.md)

**Q: How long does it take to set up?**
A: 5-10 minutes to get everything running

**Q: Do I need to understand all the configuration?**
A: No! Everything is pre-configured. Start with [QUICK_START.md](QUICK_START.md) first.

**Q: What if a service isn't starting?**
A: Check [README.md](README.md#troubleshooting) troubleshooting section

**Q: How do I see what metrics are available?**
A: 
1. Go to http://localhost:9090/graph
2. Click in the search box
3. Start typing a metric name (e.g., "kafka")
4. You'll see autocomplete suggestions

**Q: What does this metric mean?**
A: Search the metric name in [METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md)

**Q: How do I write my own PromQL queries?**
A: Read "PromQL Examples" section in [README.md](README.md)

**Q: Can I use this in production?**
A: This is a demo. For production, see security section in [README.md](README.md#production-considerations)

**Q: Why is Prometheus using a lot of disk space?**
A: It stores metrics for 15 days. Configure retention in docker-compose.yml

**Q: How do I add more services to monitor?**
A: Add new scrape_config to prometheus/prometheus.yml and restart

## 📈 Learning Path

1. **Beginner** (30 minutes)
   - Read QUICK_START.md
   - Generate metrics with generate-metrics.sh
   - Try sample queries in Prometheus UI
   - Read SETUP_COMPLETE.md

2. **Intermediate** (2 hours)
   - Read METRICS_DOCUMENTATION.md
   - Understand each metric
   - Write your own queries
   - Try REST HTTP queries

3. **Advanced** (4+ hours)
   - Read Prometheus.md
   - Understand architecture
   - Set up Grafana dashboards
   - Configure alerting rules
   - Read README.md

## 🛠️ Tools You'll Need

- **Docker & Docker Compose** - To run services
- **Browser** - To access Prometheus UI (http://localhost:9090)
- **Terminal** - To run commands
- **VS Code + REST Client Extension** - To query metrics (optional)
- **MongoDB client** (mongosh) - Already in container
- **Kafka tools** - Already in container

## 📝 Key Concepts

| Term | Explanation |
|------|-------------|
| **Metric** | A measurement (e.g., cpu_usage, request_count) |
| **Label** | A dimension that identifies what/where (e.g., app="app1") |
| **PromQL** | Query language to retrieve metrics from Prometheus |
| **Exporter** | Service that converts metrics to Prometheus format |
| **Scrape** | Periodic collection of metrics from a service |
| **Target** | A service Prometheus collects metrics from |
| **Time Series** | Sequence of metric values over time |
| **Alert Rule** | Condition that triggers when metric reaches threshold |

See [Prometheus.md](Prometheus.md) for more details.

## ✨ Features Included

✅ **Kafka Monitoring**
- Consumer lag tracking
- Message throughput
- Broker health
- JMX metrics via exporter

✅ **MongoDB Monitoring**
- Operations per second
- Query latency
- Memory and CPU usage
- Connection pool
- Replication metrics

✅ **MinIO Monitoring**
- Storage usage
- Request rates
- Error tracking
- Bandwidth metrics

✅ **Fiber Apps Monitoring**
- CPU usage
- Memory usage
- Network in/out
- Request metrics

✅ **Complete Documentation**
- 50+ pre-built queries
- Detailed metric reference
- Configuration guides
- Troubleshooting

## 🎓 Next Steps

1. **Run it**: [QUICK_START.md](QUICK_START.md) (5 min)
2. **Understand it**: [SETUP_COMPLETE.md](SETUP_COMPLETE.md) (10 min)
3. **Learn metrics**: [METRICS_DOCUMENTATION.md](METRICS_DOCUMENTATION.md) (30 min)
4. **Deep dive**: [README.md](README.md) (1+ hour)

## 💬 Getting Help

1. Check the **Troubleshooting** section in [README.md](README.md)
2. Check the **Debugging** section in [Prometheus.md](Prometheus.md)
3. Verify all services are "Up (healthy)" with `docker compose ps`
4. Check service logs: `docker compose logs <service-name>`

## 📞 Useful Commands

```bash
# Start everything
docker compose up --build

# Check status
docker compose ps

# View logs
docker compose logs -f prometheus

# Generate test data
./generate-metrics.sh

# Stop services
docker compose stop

# Remove everything
docker compose down -v

# Connect to MongoDB
docker exec -it prometheus_mongodb_1 mongosh -u admin -p password123 --authenticationDatabase admin

# View Prometheus config
curl http://localhost:9090/api/v1/status/config

# Query a metric
curl 'http://localhost:9090/api/v1/query?query=up'
```

---

## 🎉 You're Ready!

Start with [QUICK_START.md](QUICK_START.md) and begin exploring your monitoring stack!

**Questions?** Check the relevant documentation above. Everything is documented!
