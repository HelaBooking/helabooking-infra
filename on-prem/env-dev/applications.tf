# Deploying following ArgoCD Application:
# - helabooking-dev

# Dev Application Set
module "argocd_helabooking_dev_app" {
  source = "../cluster-templates/application"

  argocd_application_name      = "helabooking-dev"
  argocd_repo_branch           = "main"
  argocd_application_path      = "overlays/env-dev"
  argocd_application_namespace = "env-dev"
}


########################## Secrets for Applications ##########################
# - Harbor Credentials
# - App Secrets (PostgreSQL, RabbbitMQ, JWT)

# Harbor Credentials
resource "kubernetes_secret" "harbor_creds" {
  metadata {
    name      = "harbor-pull-secret"
    namespace = var.namespace
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "harbor.management.ezbooking.lk" = {
          username = var.harbor_username
          password = var.harbor_password
          auth     = base64encode("${var.harbor_username}:${var.harbor_password}")
        }
      }
    })
  }
}

# App Credentials for all backend services
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "app-secrets"
    namespace = var.namespace
  }
  data = {
    # RabbitMQ
    "rabbitmq-username" = var.rabbitmq_username
    "rabbitmq-password" = var.rabbitmq_password
    # JWT
    "jwt-secret-key" = var.app_secrets_list["JWT_SECRET_KEY"]
    # PostgreSQL Databases (Per Service)
    "pgsql-username"                 = var.app_secrets_list["PGSQL_USERNAME"]
    "pgsql-audit-db-password"        = var.app_secrets_list["PGSQL_AUDIT_DB_PASSWORD"]
    "pgsql-booking-db-password"      = var.app_secrets_list["PGSQL_BOOKING_DB_PASSWORD"]
    "pgsql-event-db-password"        = var.app_secrets_list["PGSQL_EVENT_DB_PASSWORD"]
    "pgsql-notification-db-password" = var.app_secrets_list["PGSQL_NOTIFICATION_DB_PASSWORD"]
    "pgsql-ticketing-db-password"    = var.app_secrets_list["PGSQL_TICKETING_DB_PASSWORD"]
    "pgsql-user-db-password"         = var.app_secrets_list["PGSQL_USER_DB_PASSWORD"]
  }
}
