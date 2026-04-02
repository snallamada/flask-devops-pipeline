# Terraform — Local Docker Infrastructure

Provisions the Flask app container locally using the
[kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest)
Terraform provider. **No cloud account required.**

## Prerequisites

- [Terraform >= 1.5](https://developer.hashicorp.com/terraform/downloads)
- Docker Desktop (Mac/Windows) or Docker Engine (Linux) running

## Usage

```bash
# 1. Navigate to the terraform directory
cd terraform/

# 2. Initialise — downloads the kreuzwerker/docker provider
terraform init

# 3. Preview the execution plan
terraform plan

# 4. Apply — builds the image and starts the container
terraform apply

# 5. Verify the app is running
curl http://localhost:5000/health

# 6. Destroy all resources when done
terraform destroy
```

## Variables

| Variable         | Default            | Description                          |
|------------------|--------------------|--------------------------------------|
| `app_name`       | `flask-devops-app` | Container / network / volume prefix  |
| `container_port` | `5000`             | Host port mapped to Flask            |
| `image_tag`      | `latest`           | Docker image tag to deploy           |

Override any variable without editing files:

```bash
terraform apply -var="image_tag=sha-abc123"
```

## Outputs

After `terraform apply` you will see:

| Output           | Description                        |
|------------------|------------------------------------|
| `container_name` | Name of the running container      |
| `container_port` | Host port                          |
| `container_id`   | Docker container ID                |
| `image_name`     | Full image name                    |
| `network_name`   | Docker network name                |
| `app_url`        | URL to access the app locally      |
