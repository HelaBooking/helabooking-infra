# Includes: namesapces, network policies, ingress, egress used by cluster management

resource "kubernetes_namespace" "management" {
  metadata {
    name = "management"
    labels = {
      name       = "management",
      monitoring = "dev-stack"
    }
  }
  #ignore changes made by Rancher
  # lifecycle {
  #   ignore_changes = [
  #     metadata[0].labels,
  #     metadata[0].annotations,
  #   ]
  # }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name       = "cert-manager",
      monitoring = "dev-stack"
    }
  }
  #ignore changes made by Rancher
  # lifecycle {
  #   ignore_changes = [
  #     metadata[0].labels,
  #     metadata[0].annotations,
  #   ]
  # }
}

# resource "kubernetes_namespace" "rancher" {
#   metadata {
#     name = "cattle-system"
#     labels = {
#       name = "cattle-system"
#     }
#   }
#   #ignore changes made by Rancher
#   lifecycle {
#     ignore_changes = [
#       metadata[0].labels,
#       metadata[0].annotations,
#     ]
#   }
# }

resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = "longhorn-system"
    labels = {
      name       = "longhorn-system",
      monitoring = "dev-stack"
    }
  }
  #ignore changes made by Rancher
  # lifecycle {
  #   ignore_changes = [
  #     metadata[0].labels,
  #     metadata[0].annotations,
  #   ]
  # }
}
