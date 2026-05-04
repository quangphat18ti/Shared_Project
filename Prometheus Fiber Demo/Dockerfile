FROM golang:1.22-alpine AS builder

WORKDIR /src

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

ARG TARGET=cmd/fiber-app
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/app ./${TARGET}

FROM alpine:3.20

RUN adduser -D -H appuser
USER appuser

COPY --from=builder /out/app /app

EXPOSE 8080 8090

ENTRYPOINT ["/app"]
