package main

import (
	"fmt"
	"log"
	"math/rand"
	"os"
	"strconv"
	"time"

	"github.com/gofiber/adaptor/v2"
	"github.com/gofiber/fiber/v2"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fiber_http_requests_total",
			Help: "Total HTTP requests handled by the Fiber app.",
		},
		[]string{"app", "method", "path", "status"},
	)
	networkInBytesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fiber_network_in_bytes_total",
			Help: "Total HTTP request body bytes received by the Fiber app.",
		},
		[]string{"app"},
	)
	networkOutBytesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "fiber_network_out_bytes_total",
			Help: "Total HTTP response body bytes sent by the Fiber app.",
		},
		[]string{"app"},
	)
)

func main() {
	appName := getenv("APP_NAME", "fiber-app")
	port := getenv("PORT", "8080")

	registry := prometheus.NewRegistry()
	registry.MustRegister(
		collectors.NewGoCollector(),
		collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}),
		httpRequestsTotal,
		networkInBytesTotal,
		networkOutBytesTotal,
	)

	app := fiber.New(fiber.Config{
		AppName: appName,
	})

	app.Use(func(c *fiber.Ctx) error {
		networkInBytesTotal.WithLabelValues(appName).Add(float64(len(c.Body())))
		err := c.Next()

		status := strconv.Itoa(c.Response().StatusCode())
		httpRequestsTotal.WithLabelValues(appName, c.Method(), c.Path(), status).Inc()
		networkOutBytesTotal.WithLabelValues(appName).Add(float64(len(c.Response().Body())))
		return err
	})

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"app":    appName,
			"status": "ok",
		})
	})

	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"app":     appName,
			"message": "hello from " + appName,
			"time":    time.Now().UTC().Format(time.RFC3339),
		})
	})

	app.Get("/work", func(c *fiber.Ctx) error {
		iterations := rand.Intn(900000) + 100000
		total := 0
		for i := 0; i < iterations; i++ {
			total += i % 7
		}

		return c.JSON(fiber.Map{
			"app":        appName,
			"iterations": iterations,
			"result":     total,
		})
	})

	app.Post("/echo", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"app":        appName,
			"body_bytes": len(c.Body()),
			"body":       string(c.Body()),
		})
	})

	app.Get("/metrics", adaptor.HTTPHandler(promhttp.HandlerFor(registry, promhttp.HandlerOpts{})))

	log.Printf("%s listening on :%s", appName, port)
	if err := app.Listen(fmt.Sprintf(":%s", port)); err != nil {
		log.Fatal(err)
	}
}

func getenv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
