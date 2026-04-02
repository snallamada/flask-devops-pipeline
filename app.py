import os
import socket
import time
from flask import Flask, jsonify, render_template, request
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_ENV = os.environ.get("APP_ENV", "development")

START_TIME = time.time()
request_counter = {"total": 0}

# Safe env var prefixes to expose (never secrets)
_SAFE_PREFIXES = ("APP_", "FLASK_", "HOSTNAME", "PATH", "PWD", "HOME", "LANG", "TZ")


@app.before_request
def count_request():
    request_counter["total"] += 1


@app.route("/")
def home():
    """Home route — welcome message."""
    return jsonify({
        "message": "Welcome to the Flask DevOps Pipeline App!",
        "version": APP_VERSION,
        "environment": APP_ENV,
    })


@app.route("/health")
def health():
    """Liveness probe — used by Docker HEALTHCHECK and Kubernetes."""
    return jsonify({"status": "ok"}), 200


@app.route("/ready")
def ready():
    """Readiness probe — signals the app is ready to serve traffic."""
    uptime = time.time() - START_TIME
    if uptime < 2:
        return jsonify({"status": "starting", "uptime_seconds": round(uptime, 2)}), 503
    return jsonify({"status": "ready", "uptime_seconds": round(uptime, 2)}), 200


@app.route("/info")
def info():
    """Returns app metadata: version and hostname."""
    return jsonify({
        "version": APP_VERSION,
        "hostname": socket.gethostname(),
        "environment": APP_ENV,
    })


@app.route("/api/stats")
def api_stats():
    """Live runtime statistics: uptime, requests served, host info."""
    uptime = time.time() - START_TIME
    hours, remainder = divmod(int(uptime), 3600)
    minutes, seconds = divmod(remainder, 60)
    return jsonify({
        "uptime_seconds": round(uptime, 2),
        "uptime_human": f"{hours}h {minutes}m {seconds}s",
        "start_time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(START_TIME)),
        "requests_total": request_counter["total"],
        "hostname": socket.gethostname(),
        "version": APP_VERSION,
        "environment": APP_ENV,
        "python_version": __import__("sys").version.split()[0],
    })


@app.route("/api/env")
def api_env():
    """Returns non-sensitive environment variables filtered by safe prefixes."""
    safe = {
        k: v for k, v in os.environ.items()
        if any(k.startswith(p) for p in _SAFE_PREFIXES)
    }
    return jsonify({"count": len(safe), "variables": safe})


@app.route("/api/echo", methods=["POST"])
def api_echo():
    """Echoes the posted JSON payload back with metadata. Useful for debugging."""
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify({"error": "Request body must be valid JSON"}), 400
    return jsonify({
        "echo": payload,
        "received_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "content_type": request.content_type,
        "method": request.method,
    })


@app.route("/ui")
def ui():
    """Browser dashboard."""
    return render_template("index.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
