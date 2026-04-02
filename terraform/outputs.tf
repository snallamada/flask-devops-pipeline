output "container_name" {
  description = "Name of the running Docker container"
  value       = docker_container.flask_app.name
}

output "container_port" {
  description = "Host port mapped to the Flask application"
  value       = var.container_port
}

output "container_id" {
  description = "Docker container ID"
  value       = docker_container.flask_app.id
}

output "image_name" {
  description = "Full Docker image name used by the container"
  value       = docker_image.flask_app.name
}

output "network_name" {
  description = "Docker network the container is attached to"
  value       = docker_network.flask_network.name
}

output "app_url" {
  description = "Local URL to access the Flask application"
  value       = "http://localhost:${var.container_port}"
}
