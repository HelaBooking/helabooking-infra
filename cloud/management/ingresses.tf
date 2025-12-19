locals {
  management_private_ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme"           = "internal"
    "alb.ingress.kubernetes.io/target-type"      = "ip"
    "alb.ingress.kubernetes.io/group.name"       = "management-private"
    "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80},{\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
    "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
    "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate_validation.wildcard.certificate_arn
  }
}

module "management_private_ingress" {
  source = "../cluster-templates/ingress"

  name               = "management-private"
  namespace          = kubernetes_namespace.management.metadata[0].name
  ingress_class_name = var.private_ingress_class_name
  annotations        = local.management_private_ingress_annotations

  rules = [
    {
      host = "jenkins.${var.cf_default_internal_domain}"
      paths = [
        {
          path         = "/"
          path_type    = "Prefix"
          service_name = "jenkins.${var.namespace}.${var.cluster_service_domain}"
          service_port = 8080
        }
      ]
    },
    {
      host = "argocd.${var.cf_default_internal_domain}"
      paths = [
        {
          path         = "/"
          path_type    = "Prefix"
          service_name = "argo-cd-argocd-server.${var.namespace}.${var.cluster_service_domain}"
          service_port = 80
        }
      ]
    }
  ]

  depends_on_resource = [module.alb_ingress_class_private, module.cert_manager_helm]
}
