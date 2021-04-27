# This isn't really needed as a module.  Added here so when it's a seperate git repo a TF validate will be able to run.
terraform {
  required_providers {
    # kubernetes = {
    #   source = "hashicorp/kubernetes"
    # }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}
