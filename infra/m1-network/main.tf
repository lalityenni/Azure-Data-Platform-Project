terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }
}

provider "azurerm" {
  features {}
  # CI runs fmt/validate only (no plan). Run plan locally with: az login
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-adp-dev-eus"
  location = "eastus"
}