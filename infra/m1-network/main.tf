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

#M1.2 - Add a subnet to the hub VNet
resource "azurerm_subnet" "hub_subnet" {
  name                 = "snet-adp-dev-eus-hub"           # shows in Azure
  resource_group_name  = azurerm_resource_group.rg.name   # ties to your RG
  virtual_network_name = azurerm_virtual_network.hub.name # inside your VNet
  address_prefixes     = ["10.0.1.0/24"]                  # leaves 10.0.0.x free
}

# M1.3 — (NSG) for the hub VNet
resource "azurerm_network_security_group" "hub_nsg" {
  name                = "nsg-adp-dev-eus-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Inbound: allow intra-VNet traffic (default inbound is Deny, so we open VNet↔VNet)
  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Outbound: allow internet traffic (default outbound is Allow; explicit for clarity)
  security_rule {
    name                       = "Allow-Internet-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = {
    env  = "dev"
    tier = "network"
  }
}

# Associate the NSG to the hub subnet
resource "azurerm_subnet_network_security_group_association" "hub_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

# M1.4 — Subnet for Private Endpoints
resource "azurerm_subnet" "data_pe" {
  name                 = "snet-adp-dev-eus-data-pe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_storage_account" "landing" {
  name                     = "stladpdeveus001" # must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


  is_hns_enabled = true

  # Lock down public exposure — we’ll use Private Endpoints next
  public_network_access_enabled = false
  # Baseline security hygiene
  min_tls_version = "TLS1_2"


  tags = {
    env  = "dev"
    tier = "storage"
  }

}

resource "azurerm_storage_container" "raw" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.landing.name # fine even if public access is disabled at account level
  container_access_type = "private"

}

resource "azurerm_storage_container" "staging" {
  name                  = "staging"
  storage_account_name  = azurerm_storage_account.landing.name
  container_access_type = "private"

}