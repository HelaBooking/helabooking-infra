resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    annotations = var.annotations
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "rule" {
      for_each = var.rules
      content {
        host = rule.value.host

        http {
          dynamic "path" {
            for_each = rule.value.paths
            content {
              path      = path.value.path
              path_type = try(path.value.path_type, "Prefix")

              backend {
                service {
                  name = path.value.service_name
                  port {
                    number = path.value.service_port
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [var.depends_on_resource]
}

output "name" {
  value = kubernetes_ingress_v1.ingress.metadata[0].name
}
