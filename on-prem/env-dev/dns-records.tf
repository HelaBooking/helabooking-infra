# Deploying following dns-record resources with Proxy:
# - CouchDB Server

# Deploying following dns-record only on Cloudflare:
# - PostgreSQL Server

# Deploying PostgreSQL DNS Record (Cloudflare only, no proxy)
module "pgsql_db_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "pgsql.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # Disable NGINX Proxy Manager
  enable_proxy = false
}

# Deploying CouchDB DNS Record
module "couchdb_dns" {
  source = "../cluster-templates/dns-record"

  # Cloudflare variables
  cf_dns_record_name  = "couchdb.${var.cf_default_root_domain}"
  cf_dns_record_value = var.cf_default_record_value

  # NGINX Proxy Manager variables
  nginx_proxy_manager_forward_protocol = "http"
  nginx_proxy_manager_forward_service  = "couchdb-service.${var.namespace}.${var.cluster_service_domain}"
  nginx_proxy_manager_forward_port     = 5984

  depends_on_resource = [module.pgsql_db_dns] # To prevent 500 error when letsencrypt tries to create mutiple certificates
}
