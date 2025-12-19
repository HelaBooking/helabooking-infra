# Templates to be used for PVC

resource "kubernetes_persistent_volume_claim" "pvc_template" {
  metadata {
    name      = var.pvc_name
    namespace = var.namespace
    labels = {
      app = var.app_selector
    }
  }

  spec {
    access_modes = var.access_modes
    resources {
      requests = {
        storage = var.storage_request
      }
    }
    storage_class_name = var.storage_class_name
  }

  depends_on = [var.depends_on_resource]
}
