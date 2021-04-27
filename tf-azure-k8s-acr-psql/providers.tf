# #
# # This TF sets up an environment for an Azure
# #

# The basic setup of the TF environment
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

# #setup for TF cloud - CLI version
# terraform {
#   backend "remote" {
#     organization = "<MyTerraformCloudOrg>"
#     workspaces {
#       name = "<MyTFCloudWorkspace>"
#     }
#   }
# }


provider "azurerm" {
  version         = "~>2.0"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  features {}
}
