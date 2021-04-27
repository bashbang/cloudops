output "rgname" {
  value       = azurerm_resource_group.rg.name
  description = "The Resource Group Name"
}

output "aksname" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "The name of the Azure Kubernetes Cluster"
}

output "acrname" {
  value       = azurerm_container_registry.acr.name
  description = "The name of the Azure Container Registry"
}

output "psqlname" {
  value       = azurerm_postgresql_server.demo-postgres.name
  description = "The name of the Azure PSQL Database Service"
}

# TODO: Pull this out after testing - these credentials are directly stored in AKV and should be pulled from AKV
output "psqladmin" {
  value       = azurerm_postgresql_server.demo-postgres.administrator_login
  description = "This is the admin user id for the PSQL database"
  #sensitive = true
}

output "psqlpassword" {
  value       = azurerm_postgresql_server.demo-postgres.administrator_login_password
  description = "This is the temp admin password for the init of the PSQL database"
  #sensitive = true
}

output "psqlhost" {
  value       = azurerm_postgresql_server.demo-postgres.fqdn
  description = "The hostname of the PSQL server."
}

# output "akvname" {
#   value       = azurerm_key_vault.akv.name
#   description = "The Azure Key Vault Name"
# }

# TODO: Is there a way of obtaining the IP range for the k8s to update the PSQL firewall allowing pods access.
# output "aks-network" {
#   value = azurerm_kubernetes_cluster.aks.???
#   description = "The AKS network range"
# }

