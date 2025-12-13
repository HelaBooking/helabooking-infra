# Templates to be used for Kubernetes Manifests
resource "kubernetes_manifest" "manifest_template" {
  # Merge the structured header with the YAML decoded body
  manifest = merge(
    {
      "apiVersion" = var.api_version
      "kind"       = var.kind
      "metadata" = {
        for k, v in {
          "name"        = var.metadata.name
          "namespace"   = try(var.metadata.namespace, null)
          "labels"      = try(var.metadata.labels, null)
          "annotations" = try(var.metadata.annotations, null)
        } : k => v if v != null
      }
    },
    # This parses the "spec" or "data" block you pass as a string
    yamldecode(var.manifest_body)
  )

  # Using a variable to force dependency order if needed
  depends_on = [var.depends_on_resource]
}
