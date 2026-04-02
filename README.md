# Flask DevOps Pipeline

> A production-grade, end-to-end DevOps project demonstrating Flask, Docker, CI/CD, Terraform, Kubernetes, and observability — all running locally.

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        Developer Laptop                            │
│                                                                    │
│   Developer                                                        │
│      │                                                             │
│      │  git push                                                   │
│      ▼                                                             │
│   ┌──────────┐                                                     │
│   │  GitHub  │──────────────────────────────────────────────────┐ │
│   └──────────┘                                                   │ │
│                                                                  │ │
│      ┌───────────────────────────────────────────────────────┐  │ │
│      │              GitHub Actions CI/CD Pipeline             │◄─┘ │
│      │                                                        │    │
│      │  [test] → [lint] → [build] → [security-scan] → [deploy]    │
│      └───────────────────────────┬───────────────────────────┘    │
│                                  │                                 │
│                    ┌─────────────▼─────────────┐                  │
│                    │        Docker              │                  │
│                    │   flask-devops-app:sha     │                  │
│                    └─────────────┬─────────────┘                  │
│                                  │                                 │
│             ┌────────────────────▼────────────────────┐           │
│             │           Kubernetes Cluster             │           │
│             │                                          │           │
│             │  Namespace: flask-app                    │           │
│             │  ┌──────────────────────────────────┐   │           │
│             │  │  Deployment (2–5 replicas / HPA)  │   │           │
│             │  │  ┌─────────┐  ┌─────────┐        │   │           │
│             │  │  │ Pod 1   │  │ Pod 2   │  ...   │   │           │
│             │  │  └────┬────┘  └────┬────┘        │   │           │
│             │  └───────┼────────────┼──────────────┘   │           │
│             │          └─────┬──────┘                  │           │
│             │         ClusterIP Service                 │           │
│             │                │                          │           │
│             │         Nginx Ingress                     │           │
│             └────────────────┼─────────────────────────┘           │
│                              │                                      │
│             ┌────────────────▼─────────────────────────┐           │
│             │        Monitoring Stack                   │           │
│             │                                          │           │
│             │  Prometheus (:9090) ──► Grafana (:3000)  │           │
│             │       ▲                                   │           │
│             │       └── /metrics (flask-app)            │           │
│             └──────────────────────────────────────────┘           │
└────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Tool               | Purpose                                    | Version    |
|--------------------|--------------------------------------------|------------|
| **Flask**          | Python web framework (app + /metrics)      | 3.0.3      |
| **Docker**         | Container runtime and image build          | 24+        |
| **Docker Compose** | Local multi-container orchestration        | 2.x        |
| **GitHub Actions** | CI/CD pipeline (test → build → deploy)     | 2024       |
| **Terraform**      | Infrastructure as Code (local Docker)      | ≥ 1.5      |
| **Kubernetes**     | Container orchestration (k8s manifests)    | 1.28+      |
| **Prometheus**     | Metrics collection and storage             | 2.51       |
| **Grafana**        | Metrics visualisation and dashboards       | 10.4       |
| **Trivy**          | Container image vulnerability scanning     | latest     |
| **pytest**         | Python unit testing framework              | 8.2        |
| **flake8**         | Python linting / code quality              | 7.1        |

---

## How to Run Locally

### Prerequisites

- Python 3.11+
- Docker & Docker Compose
- (Optional) Terraform ≥ 1.5, kubectl

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/flask-devops-pipeline.git
cd flask-devops-pipeline

# 2. Run with Docker Compose
docker compose up --build -d

# 3. Open in browser
open http://localhost:5000          # Home page
curl http://localhost:5000/health   # {"status":"ok"}
curl http://localhost:5000/info     # version + hostname
curl http://localhost:5000/metrics  # Prometheus metrics
```

### Run Tests Locally

```bash
pip install -r requirements.txt
pytest tests/ -v
```

---

## CI/CD Pipeline Explained

The pipeline is defined in `.github/workflows/ci-cd.yml` and runs on every `push` to `main` and on all pull requests.

**Job 1 — test**
Installs Python dependencies and runs `pytest` against all tests in `tests/`. Uploads JUnit XML results as an artifact.

**Job 2 — lint** *(needs: test)*
Runs `flake8` across `app.py` and `tests/` to enforce PEP 8 code style with a max line length of 100 characters.

**Job 3 — build** *(needs: lint)*
Sets up Docker Buildx, logs in to GitHub Container Registry (GHCR), and builds and pushes the image tagged with the short commit SHA. A `.tar` file of the image is saved for the security scan job.

**Job 4 — security-scan** *(needs: build)*
Loads the image artifact and runs `aquasecurity/trivy-action` to scan for CRITICAL and HIGH CVEs. Results are uploaded to the GitHub Security tab in SARIF format.

**Job 5 — deploy** *(needs: security-scan, main branch only)*
Simulates a production deployment. In a real pipeline this would SSH to a server, run `kubectl set image`, or trigger a Helm upgrade.

---

## Infrastructure as Code

Terraform provisions the entire app stack locally using the `kreuzwerker/docker` provider — no cloud account needed.

```bash
cd terraform/

# Download the Docker provider plugin
terraform init

# Preview resources to be created
terraform plan

# Create the container, network, and volume
terraform apply

# Verify
curl http://localhost:5000/health

# Tear everything down
terraform destroy
```

Override variables at apply time:

```bash
terraform apply -var="image_tag=sha-abc123" -var="container_port=8080"
```

---

## Kubernetes Deployment

Apply all manifests to a running cluster (Docker Desktop, kind, or minikube):

```bash
# Create the namespace first
kubectl apply -f k8s/namespace.yaml

# Apply everything else
kubectl apply -f k8s/

# Verify rollout
kubectl rollout status deployment/flask-app -n flask-app

# Check pods and services
kubectl get pods,svc,hpa -n flask-app

# Port-forward for local testing (bypasses Ingress)
kubectl port-forward svc/flask-app-service 5000:5000 -n flask-app
```

### Ingress (Nginx)

Install the Nginx ingress controller, then apply `k8s/ingress.yaml`. Update `flask-app.example.com` to your actual domain and configure a TLS certificate via `cert-manager`.

---

## Monitoring

### Start the Monitoring Stack

```bash
# Make sure the main app is running first
docker compose up -d

# Start Prometheus + Grafana
docker compose -f monitoring/docker-compose.monitoring.yml up -d
```

### Access

| Service    | URL                          | Credentials   |
|------------|------------------------------|---------------|
| Prometheus | http://localhost:9090        | None required |
| Grafana    | http://localhost:3000        | admin / admin |
| App        | http://localhost:5000        | None required |
| Metrics    | http://localhost:5000/metrics| None required |

### Grafana Setup

1. Log in to Grafana at http://localhost:3000
2. Add a Prometheus data source pointing to `http://prometheus:9090`
3. Import the Flask Request dashboard (ID **11074** from grafana.com)

---

## DevOps Automation Scripts

All scripts live in `scripts/` and are executable (`chmod +x`).

```bash
# Build image tagged with git SHA
./scripts/build.sh

# Deploy via docker-compose (builds + starts + health checks)
./scripts/deploy.sh

# Roll back to a previous image tag
./scripts/rollback.sh sha-abc123

# Poll /health every 5 seconds (Ctrl+C to stop)
./scripts/health-check.sh

# Clean up containers, dangling images, and volumes
./scripts/cleanup.sh          # gentle
./scripts/cleanup.sh --all    # remove everything including named volumes
```

---

## Git Setup

```bash
# Inside the project root
git init
git branch -m main
git add .
git commit -m "feat: initial devops project setup with Flask, Docker, Terraform, K8s, GitHub Actions, and Prometheus monitoring"

# Push to GitHub
git remote add origin https://github.com/<your-username>/flask-devops-pipeline.git
git push -u origin main
```

---

## Project Structure

```
flask-devops-pipeline/
│
├── app.py                          # Flask application (/, /health, /info, /metrics)
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Multi-stage container image (python:3.11-slim)
├── docker-compose.yml              # App service with healthcheck, volume, network
├── .gitignore                      # Excludes .terraform/, *.tfstate, venv/, etc.
│
├── tests/
│   ├── __init__.py
│   └── test_app.py                 # pytest unit tests for all 3 routes (12 tests)
│
├── .github/
│   └── workflows/
│       └── ci-cd.yml               # 5-job CI/CD pipeline (test→lint→build→scan→deploy)
│
├── terraform/
│   ├── main.tf                     # Docker container, network, volume resources
│   ├── variables.tf                # app_name, container_port, image_tag
│   ├── outputs.tf                  # container_name, port, image, network, URL
│   ├── terraform.tfvars            # Default variable values
│   └── README.md                   # Terraform usage guide
│
├── k8s/
│   ├── namespace.yaml              # Namespace: flask-app
│   ├── configmap.yaml              # APP_ENV=production, LOG_LEVEL=info
│   ├── deployment.yaml             # 2 replicas, resource limits, liveness/readiness probes
│   ├── service.yaml                # ClusterIP on port 5000
│   ├── hpa.yaml                    # HPA: 2–5 pods at 70% CPU / 80% memory
│   └── ingress.yaml                # Nginx Ingress with TLS
│
├── monitoring/
│   ├── prometheus.yml              # Scrape config: Flask /metrics every 15s
│   └── docker-compose.monitoring.yml # Prometheus (:9090) + Grafana (:3000)
│
└── scripts/
    ├── build.sh                    # docker build tagged with git SHA
    ├── deploy.sh                   # docker-compose up with health-check loop
    ├── rollback.sh                 # Stop + redeploy previous image tag
    ├── health-check.sh             # Poll /health every 5s with alerting
    └── cleanup.sh                  # Remove containers, dangling images, volumes
```

---

## Interview Talking Points

This project demonstrates end-to-end DevOps competency across seven domains:

**Containerisation** — A production-hardened Dockerfile using a non-root user, layer-caching for fast rebuilds, and an embedded HEALTHCHECK. Docker Compose wires up named volumes, a custom bridge network, and a health probe.

**CI/CD** — A 5-stage GitHub Actions pipeline where every job depends on the previous (needs:), enforcing a quality gate from test to production. Trivy security scanning is integrated at the image level with SARIF reporting.

**Infrastructure as Code** — Terraform provisions the full Docker stack (container, network, volume) using the kreuzwerker provider — reproducible, version-controlled infrastructure with input validation.

**Kubernetes** — Production-ready manifests: rolling-update Deployment with resource requests/limits, liveness and readiness probes, a ClusterIP Service, Nginx Ingress with TLS, HPA for CPU-driven autoscaling, and a dedicated namespace.

**Observability** — prometheus-flask-exporter auto-instruments every route. Prometheus scrapes `/metrics` every 15 s and Grafana visualises request rates, latency, and error rates.

**Automation** — Five Bash scripts cover the full ops lifecycle: build, deploy, rollback, health monitoring, and cleanup — all safe with `set -euo pipefail`.

**Security** — Non-root container user, read-only filesystem options, Trivy CVE scanning in CI, Kubernetes securityContext dropping all capabilities, and `.gitignore` excluding secrets and state files.
