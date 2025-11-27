# Templates to be used for ArgoCD Applications
resource "kubernetes_manifest" "argocd_root_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.argocd_application_name
      namespace = "management" # Where ArgoCD itself is installed
    }
    spec = {
      project = var.argocd_application_project
      source = {
        repoURL        = var.gitops_repo_url         # GitOps Repo URL 
        targetRevision = var.gitops_branch           # Branch to track
        path           = var.argocd_application_path # Path within the repo
      }
      destination = {
        server    = "https://kubernetes.default.svc" # Local cluster
        namespace = var.argocd_application_namespace # Target Namespace
      }
      syncPolicy = {
        automated = {
          prune    = true # Delete stuff if removed from git
          selfHeal = true # Fix stuff if changed manually in cluster
        }
        syncOptions = [
          "CreateNamespace=false" # Terraform manages the NS
        ]
      }
    }
  }
}
