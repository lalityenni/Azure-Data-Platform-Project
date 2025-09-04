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
  name                = var.adf_name
  location            = var.location          # <-- literal; no data source
  resource_group_name = var.rg_name  # <-- literal; no data source

  identity {
    type = "SystemAssigned"
  }

  tags = {
    env  = "dev"
    tier = "data"
  }
}