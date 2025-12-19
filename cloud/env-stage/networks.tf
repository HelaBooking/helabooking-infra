# Includes: namesapces, network policies used by development environment

resource "kubernetes_namespace" "env_dev" {
  metadata {
    name = "env-dev"
    labels = {
      name           = "env-dev",
      monitoring     = "dev-stack",
      "istio.io/rev" = "dev"
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
