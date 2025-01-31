terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.60.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "1.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}
