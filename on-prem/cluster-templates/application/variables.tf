# Variables used in templates


# For ArgoCD Applications
variable "argocd_application_name" {
  description = "Name of the ArgoCD Application"
  type        = string
}
variable "argocd_application_project" {
  description = "ArgoCD Project for the Application"
  type        = string
  default     = "default"
}
variable "argocd_repo_url" {
  description = "HTTPS URL of the helabooking-gitops repo"
  type        = string
  default     = "https://github.com/HelaBooking/helabooking-manifests.git"
}
variable "argocd_repo_branch" {
  description = "Branch to track (e.g., main or HEAD)"
  type        = string
}
variable "argocd_application_path" {
  description = "Path within the gitops repo for this environment"
  type        = string
}
variable "argocd_application_namespace" {
  description = "Namespace where the ArgoCD Application will be deployed"
  type        = string
}
