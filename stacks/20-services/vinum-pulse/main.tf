module "app" {
  source = "../../../modules/fastapi-zero-cost-app"

  service_name                   = "vinum-pulse"
  environment                    = var.environment
  image_tag                      = var.image_tag
  memory_size                    = 512
  reserved_concurrent_executions = var.reserved_concurrent_executions
  app_port                       = 8000
  readiness_check_path           = "/healthz"

  environment_variables = {
    VINUM_DB_PATH = "/tmp/vinum_pulse.db"
  }
}
