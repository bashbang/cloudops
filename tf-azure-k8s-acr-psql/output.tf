# TODO: maybe we can just inject the secrets directly into AKV since we have all the info here now.
output "rgname" {
  value       = module.demo-infrastructure.rgname
  description = "The Resource Group Name"
}

output "aks" {
  value       = module.demo-infrastructure.aksname
  description = "The name of the Azure Kubernetes Cluster"
}

output "acr" {
  value       = module.demo-infrastructure.acrname
  description = "The name of the Azure Container Registry"
}

# output "akv" {
#   value       = module.demo-infrastructure.akvname
#   description = "The Azure Key Vault Name"
# }

# TODO: remove this once AKV is fully working
output "psqluid" {
  value       = module.demo-infrastructure.psqladmin
  description = "The admin PSQL UID"
}

# TODO: remove this once AKV is fully working
output "psqlpwd" {
  value       = module.demo-infrastructure.psqlpassword
  description = "The admin PSQL PWD"
}

# output "aks-network" {
#   value = what_is_the_AKV_network_for_accessing_psql
#   description = "What is the network range for the aks"
# }
