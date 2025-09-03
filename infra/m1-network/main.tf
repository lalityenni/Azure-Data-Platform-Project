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
# M1.1 - Create a hub VNet
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

# M1.3 — (NSG) for the hub  subnet
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

# M2.1 — Storage account for landing (ADLS Gen2)
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
# M2.1b — Containers for landing zones
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
# M2.2 — Private Endpoint for Storage (blob) in data_pe subnet
resource "azurerm_private_endpoint" "st_blob_pe" {
  name                = "pep-adp-dev-eus-st-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data_pe.id

  private_service_connection {
    name                           = "psc-st-blob"
    private_connection_resource_id = azurerm_storage_account.landing.id
    is_manual_connection           = false
    subresource_names              = ["blob"] # target the blob endpoint of the storage account
  }
  private_dns_zone_group {
    name                 = "pdnszg-st-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_p1_dns.id]
  }

  tags = {
    env  = "dev"
    tier = "network"
  }

}
# M2.3 — Private DNS for Storage (blob

# 1) DNS zone for blob private endpoint
resource "azurerm_private_dns_zone" "blob_p1_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

}

# 2) Link the zone to your hub VNet (so clients in the VNet resolve to the PE IP)
resource "azurerm_private_dns_zone_virtual_network_link" "blob_p1_dns_vnet_link" {
  name                  = "pdnslink-adp-dev-eus-hub"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_p1_dns.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
}


# M2.4 - Private Endpoint for Storage (dfs) in data_pe subnet
resource "azurerm_private_endpoint" "st_dfs_pe" {
  name                = "pep-adp-dev-eus-st-dfs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.data_pe.id # use the data_pe subnet  
  private_service_connection {
    name                           = "psc-st-dfs"
    private_connection_resource_id = azurerm_storage_account.landing.id
    is_manual_connection           = false
    subresource_names              = ["dfs"] # target the dfs endpoint of the storage account
  }
  # Bind this PE to the DFS Private DNS zone (created below)
  private_dns_zone_group {
    name                 = "pdnszg-st-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.dfs_p1_dns.id]
  }
  tags = {
    env  = "dev"
    tier = "network"
  }
}

# M2.5 — Private DNS for DFS endpoint

resource "azurerm_private_dns_zone" "dfs_p1_dns" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name

}
resource "azurerm_private_dns_zone_virtual_network_link" "dfs_p1_dns_vnet_link" {
  name                  = "pdnslink-adp-dev-eus-hub-dfs"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dfs_p1_dns.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
}
# M2.5 — RBAC for your user (pulled from current az login)
data "azurerm_client_config" "current" {}

# read blobs/lists (Safe Default)
resource "azurerm_role_assignment" "storage_blob_data_reader" {
  scope                = azurerm_storage_account.landing.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}

# write blobs (Safe Default)
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.landing.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
