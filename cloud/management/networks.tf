# Includes: namesapces, network policies, ingress, egress used by cluster management

resource "kubernetes_namespace" "management" {
  metadata {
    name = "management"
    labels = {
      name       = "management",
      monitoring = "dev-stack"
    }
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      name       = "istio-system",
      monitoring = "dev-stack"
    }
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      name       = "cert-manager",
      monitoring = "dev-stack"
    }
  }
}


