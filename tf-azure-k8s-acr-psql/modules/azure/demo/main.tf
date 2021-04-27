data "azurerm_client_config" "current" {}

resource "random_string" "psqladmin" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  number  = false
}

resource "random_password" "psqpassword" {
  length  = 16
  special = false
  #override_special = "_%@"
}


resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  # TODO: Add Tag support
  #tags     = local.common_tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2s_v3"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }
  }

  # TODO: add tag support
  #tags = local.common_tags
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# TODO:
# Request Github account authorization
# inject ACR secrets into Github actions - or find a way to have Github pull AKV secrets to authorize image push from github actions pipeline to ACR
# Current method is to save ACR secrets as a Github secrets and update yaml configs. 


resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  # TODO: add tag support
  #tags = local.common_tags

}

# data "azuread_service_principal" "aks_principal" {
#   application_id = var.client_id
# }

# TODO: removeing this for now - can't seem to get it working - need to manually execute the AcrPull role
# data "azurerm_subscription" "primary" {}

# resource "azurerm_role_assignment" "acrpull_role" {
#   scope                            = "/subscriptions/${var.subscription_id}"
#   #data.azurerm_client_config.current.subscription_id
#   #azurerm_container_registry.acr.id
#   role_definition_name             = "AcrPull"
#   principal_id                     = data.azuread_service_principal.aks_principal.id
#   skip_service_principal_aad_check = true
# }

# resource "azurerm_key_vault" "akv" {
#   name                        = var.avk_name
#   location                    = azurerm_resource_group.rg.location
#   resource_group_name         = azurerm_resource_group.rg.name
#   enabled_for_disk_encryption = true
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   soft_delete_enabled         = false
#   #soft_delete_retention_days  = 7
#   purge_protection_enabled    = false

#   sku_name = "standard"

#   network_acls {
#     default_action = "Allow"
#     bypass         = "AzureServices"
#   }

#   #tags     = local.common_tags
# }


# # Create a Default Azure Key Vault access policy with Admin permissions
# # This policy must be kept for a proper run of the "destroy" process
# resource "azurerm_key_vault_access_policy" "default_policy" {
#   key_vault_id = azurerm_key_vault.akv.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   lifecycle {
#     create_before_destroy = true
#   }

#   #TODO: Ths appid set for this deployment starting with 04b07795 does not have permissions to delete the AKV.  Need to investigate this as the tf destroy doesn't work fully.
#   key_permissions         = ["backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", "verify", "wrapKey"]
#   secret_permissions      = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
#   certificate_permissions = ["create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "setissuers", "update", "backup", "restore"]
#   storage_permissions     = ["backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update"]
# }

# # inject the uid/pwd directly into keyvault
# resource "azurerm_key_vault_secret" "dbuid-secret" {
#   name         = "DBUID"
#   key_vault_id = azurerm_key_vault.akv.id
#   value        = azurerm_postgresql_server.demo-postgres.administrator_login
# }

# resource "azurerm_key_vault_secret" "dbpwd-secret" {
#   name         = "DBPWD"
#   key_vault_id = azurerm_key_vault.akv.id
#   value        = azurerm_postgresql_server.demo-postgres.administrator_login_password
# }

# resource "azurerm_key_vault_secret" "dbhost-secret" {
#   name         = "DBHOST"
#   key_vault_id = azurerm_key_vault.akv.id
#   value        = azurerm_postgresql_server.demo-postgres.fqdn
# }

resource "azurerm_postgresql_server" "demo-postgres" {
  name                = var.psql_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = random_string.psqladmin.result
  administrator_login_password = random_password.psqpassword.result

  version                 = "9.5"
  ssl_enforcement_enabled = true

  # depends_on = [
  #   azurerm_key_vault.akv,
  # ]
}

resource "azurerm_postgresql_database" "postgresdb" {
  name                = "mydb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.demo-postgres.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# TODO: This is wide open - not optimial.  Better to restrict access to just the AKS.  But not sure how that's done.  Does it use public IP?  If so then 
# TODO: will have to assign a Elastic IP then setup an ingress with routes?  The default AKS loadbalancer doesn't seem to init without a deployment.
resource "azurerm_postgresql_firewall_rule" "postgresql-fw-rule" {
  name                = "AllowAll"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.demo-postgres.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# # I think we should do this with the deoployments???
# # Connect the CSI driver to copy secrets from AKV to K8S
# resource "helm_release" "secrets-store-csi-driver" {
#   name       = "secrets-store-csi-driver"
#   chart      = "secrets-store-csi-driver"
#   repository = "https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/master/charts"
#   version    = "v0.0.17"
#   namespace  = var.namespace

#   depends_on = [
#     azurerm_kubernetes_cluster.aks,
#   ]
# }

# TODO: Started to do the k8s deployment through terrform but it got too crazy.  Not convinced it's the best method anyway.  Will deploy as pipeline instead.
# provider "kubernetes" {
#   load_config_file = false
#   host             = data.azurerm_kubernetes_cluster.aks.host
#   username         = data.azurerm_kubernetes_cluster.aks.username
#   password         = data.azurerm_kubernetes_cluster.aks.password

#   client_certificate     = data.azurerm_kubernetes_cluster.aks.client_certificate
#   client_key             = data.azurerm_kubernetes_cluster.aks.client_key
#   cluster_ca_certificate = data.azurerm_kubernetes_cluster.aks.cluster_ca_certificate
# }
//kubectl apply -f https://raw.githubusercontent.com/Azure/secrets-store-csi-driver-provider-azure/master/deployment/provider-azure-installer.yaml --namespace azure-akv
