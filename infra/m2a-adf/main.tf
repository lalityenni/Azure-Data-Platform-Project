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
  location            = var.rg_name
  resource_group_name = var.rg_name

  #managed identity block to enable ADF to access other resources securely
  identity {
    type = "SystemAssigned"
  }

  tags = {
    env  = "dev"
    tier = "data"
  }
}

# Reference existing resource group
data "azurerm_resource_group" "rg" {
  name = var.location
}

# Reference existing storage account
data "azurerm_storage_account" "landing" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

#grant adf's managed identity write access to the blobs (includes read)

resource "azurerm_role_assignment" "adf_blob_contributor" {
  scope                = data.azurerm_storage_account.landing.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# (Optional) Explicit read-only role (you can skip this if Contributor is enough)

resource "azurerm_role_assignment" "adf_blob_reader" {
  scope                = data.azurerm_storage_account.landing.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}