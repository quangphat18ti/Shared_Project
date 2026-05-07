# Comprehensive Metrics Documentation

## Overview

This document explains all metrics collected from Kafka, MongoDB, MinIO, and Fiber apps, including what they measure, their units, and what they indicate about system health.

---

## KAFKA METRICS

### 1. **Consumer Lag**

- **Metric Name**: `kafka_consumer_lag`
- **What it Measures**: How many messages behind the consumer group is compared to the latest message in the partition
- **Unit**: Number of messages
- **Typical Range**: 0-1000+ (depends on message rate)
- **What It Indicates**:
  - **0 lag**: Consumer is caught up, processing messages in real-time
  - **Growing lag**: Consumer is slower than producer, falling behind
  - **High lag**: Consumer has significant delay, may lose messages if retention expires
  - **Spikes**: Temporary processing delays, consumer restarts, or producer bursts
- **Business Impact**: Higher lag means delayed data processing, increased risk of data loss, and stale information being served to applications
- **Alert Threshold**: Usually alert if lag > message_rate × 5 minutes

### 2. **Messages In Per Second (Throughput)**

- **Metric Name**: `kafka_server_brokertopicmetrics_messagesinpersec_count`
- **What it Measures**: Rate at which messages enter the Kafka broker
- **Unit**: Messages/second (msg/s)
- **Typical Range**: 100-10,000+ msgs/s (depends on workload)
- **What It Indicates**:
  - **Steady rate**: Normal, predictable workload
  - **Increasing trend**: Growing application demand
  - **Sudden spikes**: Batch processing jobs, promotional events, or crawlers
  - **Zero rate**: No producers are sending data (may be normal or a problem)
- **Business Impact**: Indicator of system load, capacity planning needs, and application health

### 3. **Bytes In Per Second (Incoming Bandwidth)**

- **Metric Name**: `kafka_server_brokertopicmetrics_bytesinpersec_count`
- **What it Measures**: Rate of data flowing into the Kafka broker
- **Unit**: Bytes/second (B/s or MB/s when converted)
- **Typical Range**: 1MB/s - 1GB/s+ (depends on infrastructure)
- **What It Indicates**:
  - **Growing bytes vs. flat messages**: Message size is increasing
  - **Correlated with message rate**: Messages are similarly sized
  - **Spikes**: Large batch uploads, multimedia data, or data exports
- **Business Impact**: Network bandwidth utilization, storage growth rate, and infrastructure costs

### 4. **Bytes Out Per Second (Outgoing Bandwidth)**

- **Metric Name**: `kafka_server_brokertopicmetrics_bytesoutpersec_count`
- **What it Measures**: Rate of data flowing out of the Kafka broker to consumers
- **Unit**: Bytes/second (B/s or MB/s when converted)
- **Typical Range**: Similar to bytes in, may vary if consumers are distributed
- **What It Indicates**:
  - **Higher than bytes in**: Multiple consumers reading the same data
  - **Much lower than bytes in**: Some messages not being read/consumed
  - **Consistent ratio**: Predictable consumption pattern
- **Business Impact**: Downstream system load, replica network usage, and network capacity needs

### 5. **Under-Replicated Partitions**

- **Metric Name**: `kafka_server_replicamanager_underreplicatedpartitions`
- **What it Measures**: Number of partitions that don't have all their replicas in sync
- **Unit**: Count (number of partitions)
- **Typical Range**: 0 (healthy) or 1-50+ (indicating issues)
- **What It Indicates**:
  - **0**: Cluster is healthy, all replicas are synced
  - **> 0**: Broker(s) are down or slow, data loss risk increases if another broker fails
  - **Growing count**: Multiple broker failures, network issues
- **Business Impact**: **Critical** - risk of data loss, eventual consistency issues, potential message loss during broker failure

### 6. **ISR (In-Sync Replicas) Shrink Rate**

- **Metric Name**: `kafka_server_replicamanager_isrshrinks_total`
- **What it Measures**: How often replicas fall out of sync with the leader
- **Unit**: Shrink events per minute
- **Typical Range**: 0 (healthy) or 1-10+ (problematic)
- **What It Indicates**:
  - **0 rate**: All replicas are stable and responsive
  - **Increasing rate**: Network latency, overloaded brokers, or slow disks
  - **Correlated with lag**: Replicas struggling to keep up
- **Business Impact**: Indicates cluster instability, potential for inconsistent data, increased risk during maintenance

### 7. **Failed Producer Requests**

- **Metric Name**: `kafka_server_delayedoperationpurgatory_purgatorysize`
- **What it Measures**: Size of the purgatory (requests waiting for conditions to be met)
- **Unit**: Count (number of requests)
- **Typical Range**: 0-100+ (low indicates good health)
- **What It Indicates**:
  - **0**: All requests are being processed normally
  - **Growing**: Broker can't process requests fast enough, backlog building
  - **High value**: Risk of producer timeouts, request rejections
- **Business Impact**: Producers may drop messages, loss of data, client-side errors

---

## MONGODB METRICS

### 1. **Operations Per Second (Ops/Sec)**

- **Metric Name**: `rate(mongodb_op_counters_total[1m])`
- **What it Measures**: Total database operations (reads, writes, commands) per second
- **Unit**: Operations/second (ops/sec)
- **Typical Range**: 10-1000+ ops/sec (depends on application)
- **What It Indicates**:
  - **Steady baseline**: Normal application operation
  - **Increasing trend**: Growing application usage, potential scaling needs
  - **Spikes**: Batch jobs, backup operations, or unusual usage
  - **Zero rate**: Database is not receiving requests (server down or connection issues)
- **Business Impact**: Application performance indicator, capacity planning metric, load assessment

### 2. **Query Latency (Operation Duration)**

- **Metric Name**: `mongodb_op_counters_latency_avg_ms`
- **What it Measures**: Average time to complete database operations (queries and writes)
- **Unit**: Milliseconds (ms)
- **Typical Range**: 1-50ms (depends on query complexity and data size)
- **What It Indicates**:
  - **< 10ms**: Query has good indexes, data fits in memory
  - **10-50ms**: Acceptable for most applications, some disk I/O involved
  - **50-200ms**: Slow queries, missing indexes, or large result sets
  - **> 200ms**: Performance problems, need optimization
- **Business Impact**: User experience, application responsiveness, backend bottleneck

### 3. **Read Operations Rate**

- **Metric Name**: `rate(mongodb_op_counters_total{type="query"}[1m])`
- **What it Measures**: Database queries/reads per second
- **Unit**: Queries/second
- **Typical Range**: 50-500+ queries/sec
- **What It Indicates**:
  - **Growing independently of writes**: Heavy reporting/analytics queries
  - **Consistent ratio**: Predictable application pattern
  - **Spikes**: Background jobs, data exports, cache misses
- **Business Impact**: Read capacity planning, cache effectiveness indicator

### 4. **Write Operations Rate**

- **Metric Name**: `rate(mongodb_op_counters_total{type=~"insert|update|delete"}[1m])`
- **What it Measures**: Database inserts, updates, and deletes per second
- **Unit**: Writes/second
- **Typical Range**: 10-100+ writes/sec
- **What It Indicates**:
  - **Consistent rate**: Steady application workload
  - **Spikes**: Data imports, bulk operations, event logging
  - **Low compared to reads**: Read-heavy application (typical)
- **Business Impact**: Write throughput, replication lag risk, transaction volume

### 5. **Current Connections**

- **Metric Name**: `mongodb_connections_current`
- **What it Measures**: Number of active client connections to MongoDB
- **Unit**: Number of connections
- **Typical Range**: 10-1000+ (depends on connection pooling)
- **What It Indicates**:
  - **Growing trend**: More clients/applications connecting
  - **Approaching max**: Connection pool saturation, may reject new connections
  - **Spikes then drops**: Application reconnecting or recovering
- **Business Impact**: Connection limit management, resource allocation, maximum concurrent users

### 6. **Memory Usage**

- **Metric Name**: `mongodb_process_resident_memory_bytes` (RAM) and `mongodb_process_virtual_memory_bytes` (Virtual)
- **What it Measures**:
  - **Resident**: Actual physical RAM used by MongoDB
  - **Virtual**: Total addressable memory (includes disk cache)
- **Unit**: Bytes (convert to GB: bytes ÷ 1,073,741,824)
- **Typical Range**: Depends on data set size (100MB-100GB+)
- **What It Indicates**:
  - **Steady state**: Working set is stable
  - **Growing**: More data being accessed, or memory leak
  - **Approaching system limit**: Out-of-memory risk, performance degradation
  - **Resident << Virtual**: Heavy disk I/O, not all data in memory
- **Business Impact**: Performance degradation risk, need for more RAM, disk I/O impact on latency

### 7. **CPU Usage**

- **Metric Name**: `rate(mongodb_process_cpu_seconds_total[1m])`
- **What it Measures**: CPU time consumed by MongoDB process per second
- **Unit**: CPU seconds/second (0-1 range for single core, multiply by 100 for percentage)
- **Typical Range**: 0.1-0.9 (for busy database)
- **What It Indicates**:
  - **< 0.2**: Light CPU usage, plenty of headroom
  - **0.2-0.7**: Moderate usage, normal operation
  - **> 0.8**: CPU bound, may need optimization or scaling
  - **Near 1.0**: Hitting CPU limit, queries are competing for CPU
- **Business Impact**: Query performance bottleneck, indexing effectiveness, need for vertical/horizontal scaling

### 8. **Network Bytes In/Out**

- **Metric Name**: `rate(mongodb_network_bytes_in_total[1m])` and `rate(mongodb_network_bytes_out_total[1m])`
- **What it Measures**: Network traffic to/from MongoDB server
- **Unit**: Bytes/second
- **Typical Range**: 100KB/s - 100MB/s (depends on query size and frequency)
- **What It Indicates**:
  - **Bytes in < Bytes out**: Read-heavy workload
  - **Similar values**: Write-heavy or balanced workload
  - **Spikes**: Bulk data transfers, large result sets
- **Business Impact**: Network bandwidth utilization, potential bottleneck if network is saturated

### 9. **Page Faults**

- **Metric Name**: `rate(mongodb_extra_info_page_faults[1m])`
- **What it Measures**: Rate at which MongoDB accesses data not in physical RAM, causing disk reads
- **Unit**: Page faults/second
- **Typical Range**: 0-10/sec (healthy), 10-100+/sec (concerning)
- **What It Indicates**:
  - **0**: Working set fits in RAM, excellent performance
  - **Low rate (< 5/sec)**: Mostly good, occasional disk access acceptable
  - **High rate (> 50/sec)**: Significant disk thrashing, severe performance impact
- **Business Impact**: **Performance critical** - causes 1000x slower access, queries become very slow

### 10. **Lock Acquisitions**

- **Metric Name**: `rate(mongodb_global_lock_acquisitions_total[1m])`
- **What it Measures**: How often the global lock is acquired (indicates lock contention)
- **Unit**: Lock acquisitions/second
- **Typical Range**: 100-10,000/sec (depends on operations count)
- **What It Indicates**:
  - **High relative to ops**: Significant lock contention, operations waiting
  - **Low relative to ops**: Lock contention is not an issue
  - **Growing trend**: More blocking operations, potential concurrency issue
- **Business Impact**: Write operation delays, reduced concurrency, need for optimization

### 11. **Replication Lag** (if using Replica Sets)

- **Metric Name**: `(mongodb_rs_members_optimedate_ms - mongodb_rs_optimedate_ms)`
- **What it Measures**: Time delay between primary and secondary replicas
- **Unit**: Milliseconds (ms)
- **Typical Range**: 0-1000ms (0 is ideal, < 100ms is good)
- **What It Indicates**:
  - **0ms**: Replicas are in sync
  - **< 100ms**: Acceptable for most use cases
  - **> 1000ms**: Significant replication lag, data inconsistency between replicas
  - **Growing lag**: Primary is overloaded, secondary can't keep up
- **Business Impact**: **Critical for HA** - risk of data loss during failover, eventual consistency issues

---

## MINIO METRICS

### 1. **Storage Usage**

- **Metric Name**: `minio_cluster_capacity_usable_total_bytes`
- **What it Measures**: Total storage capacity available in MinIO cluster
- **Unit**: Bytes (convert to GB: bytes ÷ 1,073,741,824 or TB: bytes ÷ 1,099,511,627,776)
- **Typical Range**: 100GB - 1000TB+ (depends on infrastructure)
- **What It Indicates**:
  - **Static value**: Cluster capacity is fixed
  - **Changes**: Disks added or removed
- **Business Impact**: Maximum storage capacity, planning for expansion

### 2. **Free Storage Space**

- **Metric Name**: `minio_cluster_capacity_usable_free_bytes`
- **What it Measures**: Available storage space in MinIO cluster
- **Unit**: Bytes
- **Typical Range**: Depends on total capacity and usage
- **What It Indicates**:
  - **Decreasing**: Storage filling up
  - **Approaching 0**: Critical, will reject new uploads soon
  - **Stable**: Usage pattern is balanced
- **Business Impact**: **Critical** - risk of running out of storage, affecting uploads, need for capacity planning

### 3. **Storage Usage Percentage**

- **Metric Name**: `(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100`
- **What it Measures**: Percentage of storage capacity currently in use
- **Unit**: Percentage (%)
- **Typical Range**: 0-100%
- **What It Indicates**:
  - **< 60%**: Comfortable headroom
  - **60-80%**: Monitor closely, plan expansion
  - **> 80%**: Critical, expansion needed soon
  - **> 90%**: Very risky, imminent full disk
- **Business Impact**: Storage saturation risk, performance degradation at high capacity

### 4. **Total Objects Stored**

- **Metric Name**: `minio_cluster_objects_total`
- **What it Measures**: Total number of objects/files stored in MinIO
- **Unit**: Count (number of objects)
- **Typical Range**: Thousands to billions (depends on use case)
- **What It Indicates**:
  - **Growing steadily**: Normal data accumulation
  - **Sudden spike**: Bulk upload or data migration
  - **Plateauing**: No new data being added
- **Business Impact**: Data volume indicator, compliance storage estimates, backup scope

### 5. **API Requests Per Second**

- **Metric Name**: `rate(minio_s3_requests_total[1m])`
- **What it Measures**: Total API requests (GET, PUT, DELETE, etc.) per second
- **Unit**: Requests/second (req/s)
- **Typical Range**: 10-10,000+ req/s (depends on application)
- **What It Indicates**:
  - **Consistent rate**: Predictable workload
  - **Growing trend**: Increased application usage
  - **Spikes**: Batch processing, data migrations, backup operations
- **Business Impact**: API throughput, system load, capacity planning

### 6. **Request Latency**

- **Metric Name**: `minio_s3_requests_duration_ms_bucket` (typically P95 or P99 percentile)
- **What it Measures**: Time to complete API requests
- **Unit**: Milliseconds (ms)
- **Typical Range**: 10-500ms (depends on object size and network)
- **What It Indicates**:
  - **< 50ms**: Excellent performance
  - **50-200ms**: Acceptable for most use cases
  - **200-500ms**: Slow, may impact user experience
  - **> 500ms**: Performance problem, investigate
- **Business Impact**: Application performance, user experience, API SLA compliance

### 7. **GET Requests Rate**

- **Metric Name**: `rate(minio_s3_requests_total{method="GET"}[1m])`
- **What it Measures**: Read operations per second
- **Unit**: Requests/second
- **Typical Range**: Varies by application
- **What It Indicates**:
  - **High GET vs PUT**: Read-heavy (downloads, streaming, CDN pulls)
  - **Similar GET and PUT**: Balanced workload
- **Business Impact**: Read capacity planning, bandwidth requirements

### 8. **PUT Requests Rate**

- **Metric Name**: `rate(minio_s3_requests_total{method="PUT"}[1m])`
- **What it Measures**: Write/upload operations per second
- **Unit**: Requests/second
- **Typical Range**: Varies by application
- **What It Indicates**:
  - **High PUT rate**: Heavy write workload, file uploads
  - **Spikes**: Scheduled uploads, batch jobs
  - **Zero rate**: No uploads happening
- **Business Impact**: Upload throughput, concurrent upload handling

### 9. **DELETE Requests Rate**

- **Metric Name**: `rate(minio_s3_requests_total{method="DELETE"}[1m])`
- **What it Measures**: Delete operations per second
- **Unit**: Requests/second
- **Typical Range**: Varies by application, usually lower than GET/PUT
- **What It Indicates**:
  - **Zero rate**: No deletions (data accumulates)
  - **Increasing rate**: Cleanup jobs, data rotation
- **Business Impact**: Data lifecycle management, storage efficiency

### 10. **Failed Requests Rate**

- **Metric Name**: `rate(minio_s3_requests_errors_total[1m])`
- **What it Measures**: API errors (4xx, 5xx) per second
- **Unit**: Errors/second
- **Typical Range**: 0-100/sec (0 is ideal)
- **What It Indicates**:
  - **0 errors**: All requests succeeding
  - **< 1/sec**: Occasional errors, acceptable
  - **> 10/sec**: Systematic errors, investigate
  - **Spike**: Temporary issue or misconfiguration
- **Business Impact**: **Critical** - request failures, data loss risk, user-facing issues

### 11. **Upload Bandwidth (Bytes Out)**

- **Metric Name**: `rate(minio_s3_tx_bytes_total[1m])`
- **What it Measures**: Data upload throughput
- **Unit**: Bytes/second (convert to MB/s: bytes ÷ 1,048,576)
- **Typical Range**: 1MB/s - 1GB/s+ (depends on infrastructure)
- **What It Indicates**:
  - **Steady**: Predictable upload pattern
  - **Spikes**: Large file uploads, batch operations
  - **Trending upward**: Growing upload volume
- **Business Impact**: Network capacity utilization, upload time estimates, bandwidth costs

### 12. **Download Bandwidth (Bytes In)**

- **Metric Name**: `rate(minio_s3_rx_bytes_total[1m])`
- **What it Measures**: Data download throughput
- **Unit**: Bytes/second
- **Typical Range**: Varies by use case (CDN pulls, backups, etc.)
- **What It Indicates**:
  - **Higher than uploads**: Read-heavy workload, data distribution
  - **Similar to uploads**: Balanced workload
  - **Trending upward**: Growing demand for data access
- **Business Impact**: Network capacity, egress costs, CDN efficiency

### 13. **Disk Free Space (Per Disk)**

- **Metric Name**: `minio_disk_free_bytes`
- **What it Measures**: Available space on individual disks
- **Unit**: Bytes
- **Typical Range**: Depends on disk size
- **What It Indicates**:
  - **All disks similar**: Balanced storage distribution
  - **One disk much lower**: Uneven distribution or disk issue
  - **Approaching 0 on any disk**: Immediate expansion needed
- **Business Impact**: Disk full risk, uneven load distribution, need for rebalancing

### 14. **Heal Operations Rate**

- **Metric Name**: `rate(minio_heal_objects_total[1m])`
- **What it Measures**: Objects being repaired/healed per second (part of erasure coding recovery)
- **Unit**: Heals/second
- **Typical Range**: 0-100/sec (0 is healthy)
- **What It Indicates**:
  - **0**: No healing needed, all objects intact
  - **Occasional heal**: Normal maintenance
  - **Continuous healing**: Disk failures, data corruption, or degraded performance
- **Business Impact**: **Critical** - indicates data integrity issues, potential data loss

### 15. **Bucket Count**

- **Metric Name**: `minio_cluster_buckets_total`
- **What it Measures**: Number of S3 buckets in MinIO cluster
- **Unit**: Count (number of buckets)
- **Typical Range**: 1-1000+ (depends on use case)
- **What It Indicates**:
  - **Growing**: New applications or projects added
  - **Plateauing**: Stable environment
- **Business Impact**: Multi-tenancy scope, administrative overhead

---

## FIBER APPS METRICS

### 1. **Process Resident Memory (RAM)**

- **Metric Name**: `process_resident_memory_bytes`
- **What it Measures**: Physical RAM currently used by Fiber app process
- **Unit**: Bytes
- **Typical Range**: 10MB - 500MB (depends on app size)
- **What It Indicates**:
  - **Stable**: Memory usage is predictable
  - **Growing**: Memory leak, caching too much data
  - **Spike then drop**: GC (garbage collection) activity
- **Business Impact**: Server resource utilization, pod/container allocation, performance

### 2. **CPU Usage**

- **Metric Name**: `rate(process_cpu_seconds_total[1m])`
- **What it Measures**: CPU time consumed per minute
- **Unit**: Fraction of available CPU (0-1 for single core)
- **Typical Range**: 0-0.5 (healthy apps)
- **What It Indicates**:
  - **< 0.1**: Low CPU usage, idle app
  - **0.1-0.5**: Healthy utilization
  - **> 0.8**: CPU bound, may need optimization
- **Business Impact**: Processing capacity, response time degradation risk

### 3. **Network In (Bytes/sec)**

- **Metric Name**: `rate(fiber_network_in_bytes_total[1m])`
- **What it Measures**: HTTP request body bytes received per second
- **Unit**: Bytes/second
- **Typical Range**: 1KB/s - 10MB/s (depends on API)
- **What It Indicates**:
  - **Growing**: More request traffic or larger payloads
  - **Spikes**: Bulk operations, file uploads
- **Business Impact**: Input throughput, bandwidth cost, API load

### 4. **Network Out (Bytes/sec)**

- **Metric Name**: `rate(fiber_network_out_bytes_total[1m])`
- **What it Measures**: HTTP response body bytes sent per second
- **Unit**: Bytes/second
- **Typical Range**: 1KB/s - 100MB/s (depends on API)
- **What It Indicates**:
  - **Higher than in**: Data-rich responses
  - **Lower than in**: Bulk input processing
  - **Trending upward**: Response payloads growing
- **Business Impact**: Output throughput, egress bandwidth, API efficiency

---

## Key Insights & Relationships

### Performance Indicators (Golden Signals)

1. **Latency** (What's happening now?)
   - MongoDB: Query latency
   - MinIO: Request latency
   - Kafka: Consumer lag

2. **Traffic/Throughput** (How much work?)
   - MongoDB: ops/sec
   - Kafka: msgs/sec, bytes/sec
   - MinIO: req/sec, bytes/sec

3. **Errors** (What's failing?)
   - MinIO: Failed requests
   - Kafka: Under-replicated partitions
   - MongoDB: Lock contentions

4. **Saturation** (How close to limits?)
   - MinIO: Storage usage %
   - MongoDB: Memory, connections
   - Kafka: Consumer lag growth

### Alert Thresholds (Recommendations)

| Component | Metric           | Warning     | Critical      |
| --------- | ---------------- | ----------- | ------------- |
| Kafka     | Consumer Lag     | > 1000 msgs | > 10,000 msgs |
| Kafka     | Under-replicated | > 0         | > 1           |
| MongoDB   | Query Latency    | > 50ms      | > 200ms       |
| MongoDB   | Memory %         | > 80%       | > 95%         |
| MongoDB   | Page Faults      | > 10/sec    | > 50/sec      |
| MinIO     | Storage Usage    | > 80%       | > 95%         |
| MinIO     | Failed Req Rate  | > 1/sec     | > 10/sec      |
| MinIO     | Disk Free        | < 100GB     | < 10GB        |

---

## Query Performance Tips

1. **Always use rate() for counters**: `rate(metric_total[1m])` converts counters to rates
2. **Use time ranges**: `[5m]` for short-term trends, `[1h]` for patterns
3. **Group by labels**: `by (service, instance)` to analyze per-component
4. **Use aggregations**: `sum()`, `avg()`, `max()`, `min()` for rolled-up views
5. **Combine metrics**: `metric_a / metric_b` for efficiency ratios
6. **Set recording rules**: Pre-compute complex queries for dashboard performance
