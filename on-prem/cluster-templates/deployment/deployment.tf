# Templates to be used for Deployments
resource "kubernetes_deployment" "deployment_template" {
  metadata {
    name      = var.app_name
    namespace = var.namespace
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.selector_label
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.app_image

          # define multiple container ports
          dynamic "port" {
            for_each = var.container_ports
            content {
              name           = port.value.name
              container_port = port.value.value
            }
          }

          dynamic "volume_mount" {
            for_each = var.volume_configs
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              sub_path   = lookup(volume_mount.value, "sub_path", null)
            }
          }

          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          # make optional environment variables
          dynamic "env" {
            for_each = var.env_variable
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          # liveness_probe {
          #   http_get {
          #     path = var.liveness_path
          #     port = var.probe_container_port
          #   }
          #   initial_delay_seconds = 30
          #   period_seconds        = 10
          # }

          # readiness_probe {
          #   http_get {
          #     path = var.readiness_path
          #     port = var.probe_container_port
          #   }
          #   initial_delay_seconds = 15
          #   period_seconds        = 5
          # }
        }

        # Optional Multiple Volume Mounts
        dynamic "volume" {
          for_each = var.volume_configs
          content {
            name = volume.value.name

            dynamic "persistent_volume_claim" {
              for_each = try(volume.value.pvc_name, null) == null ? [] : [volume.value.pvc_name]
              content {
                claim_name = persistent_volume_claim.value
              }
            }

            dynamic "config_map" {
              for_each = volume.value.config_map != null && volume.value.config_map != "" ? [volume.value.config_map] : []
              content {
                name = config_map.value

                dynamic "items" {
                  for_each = lookup(volume.value, "items", [])
                  content {
                    key  = items.value.key
                    path = items.value.path
                  }
                }
              }
            }
          }
        }

        # Optional: Image Pull Secrets
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secret == "" ? [] : [var.image_pull_secret]
          content {
            name = image_pull_secrets.value
          }
        }
      }
    }
  }
  depends_on = [var.depends_on_resource]

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["field.cattle.io/publicEndpoints"]
    ]
  }
}
