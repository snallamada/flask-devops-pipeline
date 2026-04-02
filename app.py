import os
import socket
from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

APP_VERSION = os.environ.get("APP_VERSION", "1.0.0")
APP_ENV = os.environ.get("APP_ENV", "development")


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
    """Health check endpoint used by Docker and Kubernetes probes."""
    return jsonify({"status": "ok"}), 200


@app.route("/info")
def info():
    """Returns app metadata: version and hostname."""
    return jsonify({
        "version": APP_VERSION,
        "hostname": socket.gethostname(),
        "environment": APP_ENV,
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
