"""Prometheus metrics for the Muma Bank HTTP service."""

from __future__ import annotations

from time import perf_counter

from flask import Flask, Response, g, request
from prometheus_client import CONTENT_TYPE_LATEST, CollectorRegistry, Counter, Histogram
from prometheus_client.exposition import generate_latest


class ApplicationMetrics:
    """Own an isolated registry and Flask request instrumentation."""

    def __init__(self) -> None:
        self.registry = CollectorRegistry()
        self.requests = Counter(
            "muma_bank_http_requests_total",
            "HTTP requests handled by the application.",
            ["method", "endpoint", "status"],
            registry=self.registry,
        )
        self.duration = Histogram(
            "muma_bank_http_request_duration_seconds",
            "HTTP request latency in seconds.",
            ["method", "endpoint"],
            buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5),
            registry=self.registry,
        )
        self.transfers = Counter(
            "muma_bank_transfers_total",
            "Successful banking transfers.",
            registry=self.registry,
        )

    def init_app(self, app: Flask) -> None:
        app.extensions["application_metrics"] = self

        @app.before_request
        def start_request_timer() -> None:
            g.metrics_started_at = perf_counter()

        @app.after_request
        def observe_request(response):
            endpoint = request.endpoint or "unmatched"
            if endpoint != "metrics":
                self.requests.labels(request.method, endpoint, str(response.status_code)).inc()
                self.duration.labels(request.method, endpoint).observe(
                    perf_counter() - g.metrics_started_at
                )
            return response

        @app.get("/metrics", endpoint="metrics")
        def metrics_endpoint() -> Response:
            if "X-Forwarded-For" in request.headers:
                return Response(status=404)
            return Response(generate_latest(self.registry), mimetype=CONTENT_TYPE_LATEST)
