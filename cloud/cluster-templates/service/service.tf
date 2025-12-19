# Templates to be used for Services
resource "kubernetes_service" "service_template" {
  metadata {
    name      = var.service_name
    namespace = var.namespace
    labels = {
      app = var.app_selector
    }
  }

  spec {
    selector = {
      app = var.app_selector
    }

    dynamic "port" {
      for_each = var.service_ports
      content {
        name        = port.value.name
        port        = port.value.value
        target_port = port.value.target_value
        protocol    = port.value.protocol
      }
    }
    type = var.service_type
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["field.cattle.io/publicEndpoints"]
    ]
  }

  depends_on = [var.depends_on_resource]
}
