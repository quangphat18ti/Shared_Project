package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

type summary struct {
	Timestamp string      `json:"timestamp"`
	Apps      []appMetric `json:"apps"`
}

type appMetric struct {
	Service         string  `json:"service"`
	RAMBytes        float64 `json:"ram_bytes"`
	CPUPercent      float64 `json:"cpu_percent"`
	NetworkInBps    float64 `json:"network_in_bytes_per_second"`
	NetworkOutBps   float64 `json:"network_out_bytes_per_second"`
	PrometheusLabel string  `json:"prometheus_label"`
}

type prometheusResponse struct {
	Status string `json:"status"`
	Data   struct {
		Result []struct {
			Value []any `json:"value"`
		} `json:"result"`
	} `json:"data"`
	Error string `json:"error"`
}

func main() {
	prometheusURL := strings.TrimRight(getenv("PROMETHEUS_URL", "http://prometheus:9090"), "/")
	services := splitCSV(getenv("APP_SERVICES", "app1,app2,app3"))
	port := getenv("PORT", "8090")

	app := fiber.New(fiber.Config{AppName: "metrics-api"})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":         "ok",
			"prometheus_url": prometheusURL,
			"services":       services,
		})
	})

	app.Get("/metrics-summary", func(c *fiber.Ctx) error {
		result, err := collectSummary(prometheusURL, services)
		if err != nil {
			return fiber.NewError(fiber.StatusBadGateway, err.Error())
		}
		return c.JSON(result)
	})

	app.Get("/metrics-summary/:service", func(c *fiber.Ctx) error {
		service := c.Params("service")
		result, err := collectSummary(prometheusURL, []string{service})
		if err != nil {
			return fiber.NewError(fiber.StatusBadGateway, err.Error())
		}
		return c.JSON(result.Apps[0])
	})

	log.Printf("metrics-api listening on :%s, prometheus=%s", port, prometheusURL)
	if err := app.Listen(fmt.Sprintf(":%s", port)); err != nil {
		log.Fatal(err)
	}
}

func collectSummary(prometheusURL string, services []string) (summary, error) {
	items := make([]appMetric, 0, len(services))
	for _, service := range services {
		selector := fmt.Sprintf(`app="%s"`, service)
		metric := appMetric{
			Service:         service,
			PrometheusLabel: selector,
		}

		var err error
		metric.RAMBytes, err = queryValue(prometheusURL, fmt.Sprintf(`process_resident_memory_bytes{%s}`, selector))
		if err != nil {
			return summary{}, fmt.Errorf("query RAM for %s: %w", service, err)
		}

		cpuCores, err := queryValue(prometheusURL, fmt.Sprintf(`rate(process_cpu_seconds_total{%s}[1m])`, selector))
		if err != nil {
			return summary{}, fmt.Errorf("query CPU for %s: %w", service, err)
		}
		metric.CPUPercent = cpuCores * 100

		metric.NetworkInBps, err = queryValue(prometheusURL, fmt.Sprintf(`rate(fiber_network_in_bytes_total{%s}[1m])`, selector))
		if err != nil {
			return summary{}, fmt.Errorf("query network in for %s: %w", service, err)
		}

		metric.NetworkOutBps, err = queryValue(prometheusURL, fmt.Sprintf(`rate(fiber_network_out_bytes_total{%s}[1m])`, selector))
		if err != nil {
			return summary{}, fmt.Errorf("query network out for %s: %w", service, err)
		}

		items = append(items, metric)
	}

	return summary{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Apps:      items,
	}, nil
}

func queryValue(prometheusURL string, expression string) (float64, error) {
	endpoint := prometheusURL + "/api/v1/query?query=" + url.QueryEscape(expression)
	req, err := http.NewRequest(http.MethodGet, endpoint, nil)
	if err != nil {
		return 0, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return 0, err
	}
	if resp.StatusCode >= 300 {
		return 0, fmt.Errorf("prometheus returned %s: %s", resp.Status, string(body))
	}

	var decoded prometheusResponse
	if err := json.Unmarshal(body, &decoded); err != nil {
		return 0, err
	}
	if decoded.Status != "success" {
		return 0, fmt.Errorf("prometheus query failed: %s", decoded.Error)
	}
	if len(decoded.Data.Result) == 0 || len(decoded.Data.Result[0].Value) < 2 {
		return 0, nil
	}

	value, ok := decoded.Data.Result[0].Value[1].(string)
	if !ok {
		return 0, fmt.Errorf("unexpected prometheus value format")
	}

	parsed, err := strconv.ParseFloat(value, 64)
	if err != nil {
		return 0, err
	}
	return parsed, nil
}

func splitCSV(value string) []string {
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func getenv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
