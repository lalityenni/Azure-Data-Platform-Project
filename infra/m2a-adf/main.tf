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
}

# M2A — Azure Data Factory 
resource "azurerm_data_factory" "adf" {
  name                = "adf-adp-dev-eus"
  location            = "eastus"           # <-- literal; no data source
  resource_group_name = "rg-adp-dev-eus"   # <-- literal; no data source

  identity {
    type = "SystemAssigned"
  }

  tags = {
    env  = "dev"
    tier = "data"
  }
}