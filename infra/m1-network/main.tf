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

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-adp-dev-eus"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    env  = "dev"
    tier = "network"
  }
}

resource "azurerm_subnet" "hub_subnet" {
  name                 = "snet-adp-dev-eus-hub"           # shows in Azure
  resource_group_name  = azurerm_resource_group.rg.name   # ties to your RG
  virtual_network_name = azurerm_virtual_network.hub.name # inside your VNet
  address_prefixes     = ["10.0.1.0/24"]                  # leaves 10.0.0.x free
}