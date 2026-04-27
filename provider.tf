terraform {
  required_version = ">= 1.5.0"

  required_providers {
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 4.1.0"
    }
  }
}

provider "netbox" {
  server_url = var.netbox_url
  api_token  = var.netbox_token
  allow_insecure_https = var.netbox_insecure
}
