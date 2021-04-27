# Used for the names for resources that are required to be unique
resource "random_string" "prefix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = true
}

module "demo-infrastructure" {
  # Going to use local modules for this demo, but if deploying to dev/test/prod environments may be better to deploy into a modules repo
  # and pull from different tags depending. eg:
  #source = "git::https://github.com/bashbang/demo-tfmodues.git?ref=dev-0.0.54"
  source = "./modules/azure/demo"

  # General module variables
  rg_name         = "${var.environment}-demo"
  location        = var.location
  subscription_id = var.subscription_id

  # AKS Variables
  aks_cluster_name = "${var.environment}-aks"
  dns_prefix       = "${var.environment}-k8s"
  client_id        = var.client_id
  client_secret    = var.client_secret

  # ACR variables
  acr_name = "${var.environment}${random_string.prefix.id}acr"

  # PostgreSQL variables:
  psql_name = "${var.environment}-${random_string.prefix.id}-psql"

  # Don't have AKV or CSI working yet.
  # AKV variables
  #avk_name = "${var.environment}-KeyVault"

  # CSI helm Deployment
  #namespace = var.namespace
}
