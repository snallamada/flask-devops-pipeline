variable "app_name" {
  description = "Name of the Flask application (used for container, network, and volume names)"
  type        = string
  default     = "flask-devops-app"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.app_name))
    error_message = "app_name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "container_port" {
  description = "Port exposed by the Flask application container"
  type        = number
  default     = 5000

  validation {
    condition     = var.container_port > 0 && var.container_port < 65536
    error_message = "container_port must be a valid port number between 1 and 65535."
  }
}

variable "image_tag" {
  description = "Docker image tag to deploy (e.g., git commit SHA or semantic version)"
  type        = string
  default     = "latest"
}
