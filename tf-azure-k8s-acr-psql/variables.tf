variable "location" {
  type        = string
  default     = "canadacentral"
  description = "The Azure region/location where the resources will be created"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "The current working environment"
}

variable "namespace" {
  type        = string
  default     = "development"
  description = "The k8s namespace used for this deployment -- used for helm chart deployments for CSI"
}

locals {
  common_tags = {
    environment = var.environment
    project     = "Demo Project"
    team        = "Devops"
    owner       = "CMul"
  }
}

variable "prefix" {
  type        = string
  default     = "demo"
  description = "Prefix for various named resources"
}

variable "resource_group_name" {
  type        = string
  default     = "demo"
  description = "Which Azure resrouce group is this being deployed into."
}


# client_secret, subscription_id, client_id, and tenant_id are set in Terraform Cloud as a secret
# see variables.auto.tfvars and readme for details

variable "client_secret" {
  type        = string
  description = "The Azure service principle 'password' used for Terraform Cloud deployments - this is a secret and should be deployed in Terraform Cloud - see readme.md on how to obtain this info"
}

variable "client_id" {
  type        = string
  description = "The Azure 'appId' is terraforms 'client_id'"
}

variable "subscription_id" {
  type        = string
  description = "The Azure 'subscription id'"
}

variable "tenant_id" {
  type        = string
  description = "The Azure 'tenant id'"
}