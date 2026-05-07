#!/bin/bash

# Metrics Generation Script
# Generates traffic for Fiber Apps, Kafka, MongoDB, and MinIO
# This helps populate Prometheus with real metrics data

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Prometheus Metrics Generation Script${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Function to check if service is running
check_service() {
    local port=$1
    local service=$2
    if ! curl -s http://localhost:$port > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Warning: $service (port $port) may not be running${NC}"
        echo -e "   Start services with: docker compose up --build\n"
        return 1
    fi
    return 0
}

# ============= FIBER APPS TRAFFIC =============
echo -e "${BLUE}[1] Generating Fiber Apps Traffic...${NC}"
check_service 8081 "Fiber App 1" && {
    for i in {1..10}; do
        curl -s http://localhost:8081/work > /dev/null &
        curl -s http://localhost:8082/work > /dev/null &
        curl -s http://localhost:8083/work > /dev/null &
    done
    wait
    echo -e "${GREEN}✓ Generated 30 work requests${NC}"
    
    # Generate network traffic
    for i in {1..5}; do
        curl -s -X POST http://localhost:8081/echo \
            -H "Content-Type: application/json" \
            -d '{"data":"test payload for network metrics"}' > /dev/null &
        curl -s -X POST http://localhost:8082/echo \
            -H "Content-Type: application/json" \
            -d '{"data":"test payload for network metrics"}' > /dev/null &
        curl -s -X POST http://localhost:8083/echo \
            -H "Content-Type: application/json" \
            -d '{"data":"test payload for network metrics"}' > /dev/null &
    done
    wait
    echo -e "${GREEN}✓ Generated 15 echo requests (network metrics)${NC}"
} || echo -e "${YELLOW}✗ Skipped Fiber Apps (service not available)${NC}"

echo ""

# ============= KAFKA TRAFFIC =============
echo -e "${BLUE}[2] Generating Kafka Traffic...${NC}"

# Create topic if it doesn't exist
docker exec prometheusfiberdemo-kafka-1 kafka-topics \
    --create \
    --bootstrap-server localhost:9092 \
    --topic metrics-topic \
    --partitions 3 \
    --replication-factor 1 \
    2>/dev/null || true

echo -e "${GREEN}✓ Created/verified Kafka topic${NC}"

# Produce messages
docker exec -i prometheusfiberdemo-kafka-1 kafka-console-producer \
    --bootstrap-server localhost:9092 \
    --topic metrics-topic << 'EOF'
{"event": "user_signup"}
{"event": "user_login"}
{"event": "user_purchase"}
EOF

# Consume messages to create the consumer group
docker exec prometheusfiberdemo-kafka-1 kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic metrics-topic \
    --from-beginning \
    --max-messages 3 \
    --group my-demo-group \
    --timeout-ms 5000 2>/dev/null || true

# Produce MORE messages to generate Consumer Lag
docker exec -i prometheusfiberdemo-kafka-1 kafka-console-producer \
    --bootstrap-server localhost:9092 \
    --topic metrics-topic << 'EOF'
{"event": "lag_message_1"}
{"event": "lag_message_2"}
{"event": "lag_message_3"}
{"event": "lag_message_4"}
{"event": "lag_message_5"}
EOF

echo -e "${GREEN}✓ Produced messages and generated Consumer Lag!${NC}"    
    # Create consumer group and consume to generate lag
    docker exec -d prometheus_kafka_1 kafka-console-consumer \
        --bootstrap-server localhost:9092 \
        --topic metrics-topic \
        --group test-consumer-group \
        --from-beginning \
        > /dev/null 2>&1 || true
    
    echo -e "${GREEN}✓ Created consumer group (generates consumer lag metrics)${NC}"
} || echo -e "${YELLOW}✗ Skipped Kafka (service not available)${NC}"

echo ""

# ============= MONGODB TRAFFIC =============
echo -e "${BLUE}[3] Generating MongoDB Traffic...${NC}"
check_service 27017 "MongoDB" && {
    docker exec -i prometheus_mongodb_1 mongosh \
        -u admin \
        -p password123 \
        --authenticationDatabase admin \
        --quiet << 'EOF'
use metrics_db

// Generate write operations
for (let i = 0; i < 20; i++) {
    db.users.insertOne({
        email: "user" + i + "@example.com",
        name: "User " + i,
        created_at: new Date(),
        status: ["active", "inactive", "pending"][Math.floor(Math.random() * 3)]
    });
}

// Generate read operations
for (let i = 0; i < 10; i++) {
    db.users.find({ status: "active" }).toArray();
}

// Generate update operations
for (let i = 0; i < 5; i++) {
    db.users.updateMany(
        { status: "inactive" },
        { $set: { status: "active", updated_at: new Date() } }
    );
}

// Generate aggregation (slower query for latency metrics)
db.users.aggregate([
    { $group: { _id: "$status", count: { $sum: 1 } } },
    { $sort: { count: -1 } }
]).toArray();

// Return count
print("Inserted records: " + db.users.countDocuments());
EOF
    
    echo -e "${GREEN}✓ Generated MongoDB operations (20 writes, 10 reads, 5 updates)${NC}"
} || echo -e "${YELLOW}✗ Skipped MongoDB (service not available)${NC}"

echo ""

# ============= MINIO TRAFFIC =============
echo -e "${BLUE}[4] Generating MinIO Traffic...${NC}"
check_service 9000 "MinIO" && {
    # Create temporary test file
    TEST_FILE="/tmp/metrics-test-$(date +%s).txt"
    echo "This is test data for MinIO metrics collection" > "$TEST_FILE"
    
    # Upload file
    for i in {1..5}; do
        curl -s -X PUT \
            -u minioadmin:minioadmin123 \
            --data-binary @"$TEST_FILE" \
            "http://localhost:9000/test-bucket/test-file-$i.txt" \
            > /dev/null 2>&1 || true
    done
    
    echo -e "${GREEN}✓ Uploaded 5 files to MinIO${NC}"
    
    # Download files
    for i in {1..3}; do
        curl -s -X GET \
            -u minioadmin:minioadmin123 \
            "http://localhost:9000/test-bucket/test-file-$i.txt" \
            > /dev/null 2>&1 || true
    done
    
    echo -e "${GREEN}✓ Downloaded 3 files from MinIO${NC}"
    
    # Cleanup
    rm -f "$TEST_FILE"
} || echo -e "${YELLOW}✗ Skipped MinIO (service not available)${NC}"

echo ""

# ============= SUMMARY =============
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}✓ Metrics generation complete!${NC}"
echo -e "${BLUE}=====================================${NC}\n"

echo "Metrics should now be visible in Prometheus:"
echo -e "  ${BLUE}http://localhost:9090${NC}\n"

echo "Try these queries:"
echo -e "  ${YELLOW}• Kafka consumer lag:${NC}"
echo "    sum(kafka_consumer_lag) by (topic)"
echo ""
echo -e "  ${YELLOW}• MongoDB ops/sec:${NC}"
echo "    rate(mongodb_op_counters_total[1m])"
echo ""
echo -e "  ${YELLOW}• MinIO request rate:${NC}"
echo "    rate(minio_s3_requests_total[1m])"
echo ""
echo -e "  ${YELLOW}• Fiber app memory:${NC}"
echo "    process_resident_memory_bytes{app=\"app1\"}"
echo ""

echo -e "${BLUE}Note:${NC} It may take 10-30 seconds for metrics to appear in Prometheus."
echo -e "      First check: ${BLUE}http://localhost:9090/targets${NC}"
echo ""
