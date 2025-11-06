terraform {
  required_providers {
    nginxproxymanager = {
      source  = "Sander0542/nginxproxymanager"
      version = "~> 1.2.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.10.1"
    }
  }
}

provider "nginxproxymanager" {
  url      = var.nginx_proxy_manager_url
  username = var.nginx_proxy_manager_username
  password = var.nginx_proxy_manager_password
}
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
