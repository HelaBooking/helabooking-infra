# Deploying following ArgoCD Application:
# - helabooking-dev

# Dev Application Set
module "argocd_helabooking_dev_app" {
  source = "../cluster-templates/application"

  argocd_application_name      = "helabooking-dev"
  gitops_branch                = "dev"
  argocd_application_path      = "overlays/env-dev"
  argocd_application_namespace = "env-dev"
}
