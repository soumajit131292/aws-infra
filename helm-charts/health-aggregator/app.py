#!/usr/bin/env python3
import json
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, str(default)))
    except ValueError:
        return default


def parse_services(raw: str) -> dict:
    services = {}
    for entry in raw.split(","):
        item = entry.strip()
        if not item:
            continue
        if ":" not in item:
            continue
        name, url = item.split(":", 1)
        name = name.strip()
        url = url.strip()
        if name and url:
            services[name] = url
    return services


def parse_critical(raw: str) -> set:
    return {item.strip() for item in raw.split(",") if item.strip()}


def check_one_service(name: str, url: str, timeout: float) -> dict:
    start = time.time()
    req = Request(url=url, method="GET")
    try:
        with urlopen(req, timeout=timeout) as resp:
            code = resp.getcode()
            duration_ms = int((time.time() - start) * 1000)
            return {
                "name": name,
                "url": url,
                "status": "UP" if 200 <= code < 300 else "DOWN",
                "httpStatus": code,
                "error": None,
                "durationMs": duration_ms,
            }
    except HTTPError as e:
        duration_ms = int((time.time() - start) * 1000)
        return {
            "name": name,
            "url": url,
            "status": "DOWN",
            "httpStatus": e.code,
            "error": str(e),
            "durationMs": duration_ms,
        }
    except URLError as e:
        duration_ms = int((time.time() - start) * 1000)
        return {
            "name": name,
            "url": url,
            "status": "DOWN",
            "httpStatus": None,
            "error": str(e.reason),
            "durationMs": duration_ms,
        }
    except Exception as e:  # defensive catch for robustness
        duration_ms = int((time.time() - start) * 1000)
        return {
            "name": name,
            "url": url,
            "status": "DOWN",
            "httpStatus": None,
            "error": str(e),
            "durationMs": duration_ms,
        }


def evaluate_health(services: dict, critical_services: set, timeout: float, workers: int) -> tuple:
    if not services:
        payload = {
            "status": "DOWN",
            "reason": "No SERVICES configured",
            "failedCritical": [],
            "services": {},
            "checkedAt": datetime.now(timezone.utc).isoformat(),
        }
        return 500, payload

    results = {}
    with ThreadPoolExecutor(max_workers=workers) as executor:
        future_map = {
            executor.submit(check_one_service, name, url, timeout): name
            for name, url in services.items()
        }
        for future in as_completed(future_map):
            result = future.result()
            name = result["name"]
            result["critical"] = name in critical_services
            results[name] = result

    failed_critical = sorted(
        [name for name, item in results.items() if item["critical"] and item["status"] != "UP"]
    )
    overall = "DOWN" if failed_critical else "UP"
    status_code = 500 if overall == "DOWN" else 200

    payload = {
        "status": overall,
        "failedCritical": failed_critical,
        "services": results,
        "checkedAt": datetime.now(timezone.utc).isoformat(),
    }
    return status_code, payload


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        req_start = time.time()
        if self.path not in ("/healthz", "/readyz", "/region-healthz"):
            self._send_json(404, {"status": "NOT_FOUND"})
            self._log_request_result(404, "NOT_FOUND", req_start)
            return

        services_raw = os.getenv("SERVICES", "")
        critical_raw = os.getenv("CRITICAL_SERVICES", "")
        timeout = _env_float("CHECK_TIMEOUT_SECONDS", 2.5)
        workers = _env_int("MAX_PARALLEL_CHECKS", 16)

        services = parse_services(services_raw)
        critical = parse_critical(critical_raw)
        status_code, payload = evaluate_health(services, critical, timeout, workers)
        self._send_json(status_code, payload)
        self._log_request_result(status_code, payload.get("status", "UNKNOWN"), req_start)

    def log_message(self, format, *args):
        super().log_message(format, *args)

    def _log_request_result(self, status_code: int, health_status: str, start_time: float):
        duration_ms = int((time.time() - start_time) * 1000)
        print(
            json.dumps(
                {
                    "ts": datetime.now(timezone.utc).isoformat(),
                    "path": self.path,
                    "statusCode": status_code,
                    "healthStatus": health_status,
                    "durationMs": duration_ms,
                }
            ),
            flush=True,
        )

    def _send_json(self, status_code: int, payload: dict):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    host = os.getenv("HOST", "0.0.0.0")
    port = _env_int("PORT", 8080)
    server = ThreadingHTTPServer((host, port), HealthHandler)
    print(f"health-aggregator listening on {host}:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()