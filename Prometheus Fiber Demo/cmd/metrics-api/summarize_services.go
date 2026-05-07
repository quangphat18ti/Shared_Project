package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

// ─────────────────────────────────────────────────────────────────────────────
// Prometheus client
// ─────────────────────────────────────────────────────────────────────────────

type PrometheusClient struct {
	baseURL    string
	httpClient *http.Client
}

func NewPrometheusClient(baseURL string) *PrometheusClient {
	return &PrometheusClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

type promResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"` // [timestamp, "value"]
		} `json:"result"`
	} `json:"data"`
}

func (c *PrometheusClient) Query(ctx context.Context, promQL string) (float64, error) {
	endpoint := fmt.Sprintf("%s/api/v1/query", c.baseURL)
	params := url.Values{}
	params.Set("query", promQL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint+"?"+params.Encode(), nil)
	if err != nil {
		return 0, fmt.Errorf("build request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return 0, fmt.Errorf("prometheus request: %w", err)
	}
	defer resp.Body.Close()

	var pr promResponse
	if err := json.NewDecoder(resp.Body).Decode(&pr); err != nil {
		return 0, fmt.Errorf("decode response: %w", err)
	}

	if pr.Status != "success" {
		return 0, fmt.Errorf("prometheus returned status: %s", pr.Status)
	}

	if len(pr.Data.Result) == 0 {
		return 0, nil // no data yet
	}

	valStr, ok := pr.Data.Result[0].Value[1].(string)
	if !ok {
		return 0, fmt.Errorf("unexpected value type")
	}

	val, err := strconv.ParseFloat(valStr, 64)
	if err != nil {
		return 0, fmt.Errorf("parse value %q: %w", valStr, err)
	}
	return val, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// Response types for /api/summary
// ─────────────────────────────────────────────────────────────────────────────

type SummaryResponse struct {
	Timestamp time.Time    `json:"timestamp"`
	Kafka     KafkaMetrics `json:"kafka"`
	MongoDB   MongoMetrics `json:"mongodb"`
	MinIO     MinIOMetrics `json:"minio"`
}

// KafkaMetrics - metrics cho Kafka broker
type KafkaMetrics struct {
	// consumer lag: số message chưa được xử lý
	// đơn vị: messages, càng cao càng chậm
	ConsumerLagTotal float64 `json:"consumer_lag_total"`

	// cpu: tỷ lệ CPU Kafka JVM đang dùng
	// đơn vị: 0.0-1.0 (0%=idle, 1.0=1 core full)
	CPUUsage float64 `json:"cpu_usage_cores"`

	// ram: heap memory JVM đang dùng
	// đơn vị: bytes
	HeapUsedBytes float64 `json:"heap_used_bytes"`

	// network in: bytes/sec producer gửi vào broker
	// đơn vị: bytes/second
	NetworkInBytesPerSec float64 `json:"network_in_bytes_per_sec"`

	// network out: bytes/sec consumer đọc ra từ broker
	// đơn vị: bytes/second
	NetworkOutBytesPerSec float64 `json:"network_out_bytes_per_sec"`
}

// MongoMetrics - metrics cho MongoDB
type MongoMetrics struct {
	// ops/sec: số operations/giây (tổng hợp insert+query+update+delete)
	// đơn vị: ops/second
	OpsPerSec float64 `json:"ops_per_sec"`

	// query latency: thời gian trung bình xử lý 1 read operation
	// đơn vị: milliseconds
	ReadLatencyMs float64 `json:"read_latency_ms"`

	// ram: resident memory MongoDB đang dùng
	// đơn vị: bytes
	ResidentMemoryBytes float64 `json:"resident_memory_bytes"`

	// cpu: CPU container MongoDB
	// đơn vị: cores
	CPUUsageCores float64 `json:"cpu_usage_cores"`

	// network in: bytes/sec clients gửi vào MongoDB
	// đơn vị: bytes/second
	NetworkInBytesPerSec float64 `json:"network_in_bytes_per_sec"`

	// network out: bytes/sec MongoDB trả về cho clients
	// đơn vị: bytes/second
	NetworkOutBytesPerSec float64 `json:"network_out_bytes_per_sec"`
}

// MinIOMetrics - metrics cho MinIO object storage
type MinIOMetrics struct {
	// storage usage: dung lượng đã dùng
	// đơn vị: bytes
	StorageUsedBytes float64 `json:"storage_used_bytes"`

	// storage total: tổng dung lượng khả dụng
	// đơn vị: bytes
	StorageTotalBytes float64 `json:"storage_total_bytes"`

	// storage % đã dùng
	StorageUsedPercent float64 `json:"storage_used_percent"`

	// requests/sec: số S3 API calls/giây
	// đơn vị: requests/second
	RequestsPerSec float64 `json:"requests_per_sec"`

	// cpu: CPU container MinIO
	// đơn vị: cores
	CPUUsageCores float64 `json:"cpu_usage_cores"`

	// ram: RAM MinIO process đang dùng
	// đơn vị: bytes
	MemoryBytes float64 `json:"memory_bytes"`

	// network in: bytes upload/sec vào MinIO
	// đơn vị: bytes/second
	NetworkInBytesPerSec float64 `json:"network_in_bytes_per_sec"`

	// network out: bytes download/sec từ MinIO
	// đơn vị: bytes/second
	NetworkOutBytesPerSec float64 `json:"network_out_bytes_per_sec"`
}

// ─────────────────────────────────────────────────────────────────────────────
// SummaryService
// ─────────────────────────────────────────────────────────────────────────────

type SummaryService struct {
	prom *PrometheusClient
}

func NewSummaryService(prometheusURL string) *SummaryService {
	return &SummaryService{
		prom: NewPrometheusClient(prometheusURL),
	}
}

// GetSummary queries all metrics concurrently and returns SummaryResponse
func (s *SummaryService) GetSummary(ctx context.Context) (*SummaryResponse, error) {
	type result struct {
		key string
		val float64
		err error
	}

	// PromQL queries map
	queries := map[string]string{
		// ── KAFKA ──────────────────────────────────────────────────────────────
		"kafka_lag":     `sum(kafka_consumergroup_lag)`,
		"kafka_cpu":     `sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_compose_service="kafka"}[5m]))`,
		"kafka_ram":     `sum(jvm_memory_heap_used_bytes{service="kafka"})`,
		"kafka_net_in":  `sum(rate(kafka_server_brokertopicmetrics_BytesInPerSec_total[5m]))`,
		"kafka_net_out": `sum(rate(kafka_server_brokertopicmetrics_BytesOutPerSec_total[5m]))`,

		// ── MONGODB ────────────────────────────────────────────────────────────
		"mongo_ops":     `sum(rate(mongodb_op_counters_total[5m]))`,
		"mongo_latency": `(rate(mongodb_mongod_op_latencies_latency_total{type="reads"}[5m]) / rate(mongodb_mongod_op_latencies_ops_total{type="reads"}[5m])) / 1000`,
		"mongo_ram":     `mongodb_ss_mem_resident * 1024 * 1024`,
		"mongo_cpu":     `sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_compose_service="mongodb"}[5m]))`,
		"mongo_net_in":  `rate(mongodb_ss_network_bytesIn[5m])`,
		"mongo_net_out": `rate(mongodb_ss_network_bytesOut[5m])`,

		// ── MINIO ──────────────────────────────────────────────────────────────
		"minio_storage_used":  `minio_cluster_capacity_usable_total_bytes - minio_cluster_capacity_usable_free_bytes`,
		"minio_storage_total": `minio_cluster_capacity_usable_total_bytes`,
		"minio_storage_pct":   `(1 - (minio_cluster_capacity_usable_free_bytes / minio_cluster_capacity_usable_total_bytes)) * 100`,
		"minio_requests":      `sum(rate(minio_s3_requests_total[5m]))`,
		"minio_cpu":           `sum(rate(container_cpu_usage_seconds_total{container_label_com_docker_compose_service="minio"}[5m]))`,
		"minio_ram":           `minio_node_process_resident_memory_bytes`,
		"minio_net_in":        `rate(minio_s3_traffic_received_bytes[5m])`,
		"minio_net_out":       `rate(minio_s3_traffic_sent_bytes[5m])`,
	}

	ch := make(chan result, len(queries))

	// Fan-out: query concurrently
	for key, query := range queries {
		go func(k, q string) {
			val, err := s.prom.Query(ctx, q)
			ch <- result{key: k, val: val, err: err}
		}(key, query)
	}

	// Fan-in: collect results
	values := make(map[string]float64, len(queries))
	for range queries {
		r := <-ch
		if r.err != nil {
			// log error but continue - partial data is better than no data
			fmt.Printf("warn: query %s failed: %v\n", r.key, r.err)
		}
		values[r.key] = r.val
	}

	return &SummaryResponse{
		Timestamp: time.Now().UTC(),
		Kafka: KafkaMetrics{
			ConsumerLagTotal:      values["kafka_lag"],
			CPUUsage:              values["kafka_cpu"],
			HeapUsedBytes:         values["kafka_ram"],
			NetworkInBytesPerSec:  values["kafka_net_in"],
			NetworkOutBytesPerSec: values["kafka_net_out"],
		},
		MongoDB: MongoMetrics{
			OpsPerSec:             values["mongo_ops"],
			ReadLatencyMs:         values["mongo_latency"],
			ResidentMemoryBytes:   values["mongo_ram"],
			CPUUsageCores:         values["mongo_cpu"],
			NetworkInBytesPerSec:  values["mongo_net_in"],
			NetworkOutBytesPerSec: values["mongo_net_out"],
		},
		MinIO: MinIOMetrics{
			StorageUsedBytes:      values["minio_storage_used"],
			StorageTotalBytes:     values["minio_storage_total"],
			StorageUsedPercent:    values["minio_storage_pct"],
			RequestsPerSec:        values["minio_requests"],
			CPUUsageCores:         values["minio_cpu"],
			MemoryBytes:           values["minio_ram"],
			NetworkInBytesPerSec:  values["minio_net_in"],
			NetworkOutBytesPerSec: values["minio_net_out"],
		},
	}, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP Handler - /api/summary
// ─────────────────────────────────────────────────────────────────────────────

func SummaryHandler(svc *SummaryService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 15*time.Second)
		defer cancel()

		summary, err := svc.GetSummary(ctx)
		if err != nil {
			http.Error(w, `{"error":"failed to fetch metrics"}`, http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(summary)
	}
}
