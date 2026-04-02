# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Run the app locally
```bash
pip install -r requirements.txt
python app.py
```

### Run with Docker Compose
```bash
docker compose up --build -d
docker compose down
```

### Tests
```bash
pytest tests/ -v                         # all tests
pytest tests/test_app.py::TestHealthRoute -v   # single class
pytest tests/test_app.py::TestHealthRoute::test_health_status_code -v  # single test
```

### Lint
```bash
flake8 app.py tests/ --max-line-length=100 --exclude=__pycache__,.git
```

### Terraform (local Docker provider)
```bash
cd terraform/
terraform init
terraform plan
terraform apply
terraform destroy
```

### Kubernetes
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
kubectl rollout status deployment/flask-app -n flask-app
kubectl port-forward svc/flask-app-service 5000:5000 -n flask-app
```

### Monitoring stack
```bash
docker compose up -d                                          # app must be running first
docker compose -f monitoring/docker-compose.monitoring.yml up -d
```

### Automation scripts
```bash
./scripts/build.sh               # docker build tagged with git SHA
./scripts/deploy.sh              # compose up + health-check loop
./scripts/rollback.sh <sha-tag>  # redeploy previous image tag
./scripts/health-check.sh        # poll /health every 5s
./scripts/cleanup.sh [--all]     # remove containers/images/volumes
```

## Architecture

The project is a Flask app wired into a complete DevOps toolchain. All infrastructure is designed to run locally — no cloud account required.

### Application (`app.py`)
A minimal Flask app with four routes:
- `GET /` — welcome JSON with version and environment
- `GET /health` — liveness probe (`{"status":"ok"}`)
- `GET /info` — version and hostname
- `GET /metrics` — auto-instrumented Prometheus metrics via `prometheus-flask-exporter`

`APP_VERSION` and `APP_ENV` are read from environment variables (defaults: `1.0.0` / `development`).

### CI/CD (`.github/workflows/ci-cd.yml`)
Five sequential jobs, each `needs:` the previous:
1. **test** — pytest with JUnit XML artifact
2. **lint** — flake8 at max-line-length=100
3. **build** — Docker Buildx → GHCR, tagged with short SHA; saves `image.tar` artifact
4. **security-scan** — Trivy on the image artifact, SARIF uploaded to GitHub Security tab
5. **deploy** — main-branch only; simulated (echo only — would be `kubectl set image` or Helm in production)

### Infrastructure as Code (`terraform/`)
Uses the `kreuzwerker/docker` Terraform provider to provision a Docker container, named network, and volume locally. Key variables: `app_name`, `container_port`, `image_tag` (overridable at `apply` time).

### Kubernetes (`k8s/`)
Production-ready manifests in the `flask-app` namespace:
- **Deployment** — 2 replicas, resource requests/limits, liveness (`/health`) and readiness probes
- **HPA** — scales 2–5 pods at 70% CPU / 80% memory
- **Service** — ClusterIP on port 5000
- **Ingress** — Nginx with TLS placeholder (`flask-app.example.com`)
- **ConfigMap** — `APP_ENV=production`, `LOG_LEVEL=info`

### Monitoring (`monitoring/`)
Prometheus scrapes `/metrics` every 15s. Grafana connects to Prometheus at `http://prometheus:9090`. Both run in a separate Compose file to keep them independent from the app stack. Recommended Grafana dashboard: ID **11074** (Flask Requests).

### Dockerfile
Multi-stage build on `python:3.11-slim`, runs as a non-root user, includes a `HEALTHCHECK` on `/health`.
