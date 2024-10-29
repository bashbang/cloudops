terraform {
  required_providers {
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = ">=1.33.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "sysdig" {
  sysdig_monitor_url       = "https://app.sysdigcloud.com"
  sysdig_monitor_api_token = var.sysdig_api_token
}

# Define a variable for the Sysdig API token
variable "sysdig_api_token" {
  type = string
}
