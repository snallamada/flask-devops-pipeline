terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ── Provider Configuration ─────────────────────────────────────────────────────
provider "docker" {
  # Uses local Docker daemon by default (no AWS required)
  # On Linux  : unix:///var/run/docker.sock
  # On Mac/Win: tcp://localhost:2375 (Docker Desktop)
}

# ── Docker Image ───────────────────────────────────────────────────────────────
resource "docker_image" "flask_app" {
  name         = "${var.app_name}:${var.image_tag}"
  keep_locally = true

  build {
    context    = "${path.module}/.."
    dockerfile = "${path.module}/../Dockerfile"
  }
}

# ── Docker Network ─────────────────────────────────────────────────────────────
resource "docker_network" "flask_network" {
  name   = "${var.app_name}-tf-network"
  driver = "bridge"
}

# ── Docker Volume ──────────────────────────────────────────────────────────────
resource "docker_volume" "flask_data" {
  name = "${var.app_name}-tf-data"
}

# ── Docker Container ──────────────────────────────────────────────────────────
resource "docker_container" "flask_app" {
  name  = "${var.app_name}-container"
  image = docker_image.flask_app.image_id

  ports {
    internal = var.container_port
    external = var.container_port
  }

  env = [
    "APP_ENV=production",
    "APP_VERSION=${var.image_tag}",
  ]

  volumes {
    volume_name    = docker_volume.flask_data.name
    container_path = "/app/data"
  }

  networks_advanced {
    name = docker_network.flask_network.name
  }

  healthcheck {
    test         = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:${var.container_port}/health')"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "10s"
  }

  restart = "unless-stopped"

  labels {
    label = "managed-by"
    value = "terraform"
  }
}
