terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "GHAbackend-RG"
    storage_account_name = "kmiszelghatfbackend"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

# # Define any Azure resources to be created here. A simple resource group is shown here as a minimal example.
# resource "azurerm_resource_group" "rg-aks" {
#   name     = var.resource_group_name
#   location = var.location
# }

resource "azurerm_resource_group" "testRG" {
  name     = "test-RG"
  location = "westeurope"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
  depends_on = [ 
    azurerm_resource_group.testRG
  ]
}

resource "azurerm_subnet" "endpoint" {
  name                 = "endpoint"
  resource_group_name  = azurerm_resource_group.testRG.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example
  ]
}

resource "azurerm_network_security_group" "NSG" {
  name                = "NSG1"
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint
  ]
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.endpoint.id
  network_security_group_id = azurerm_network_security_group.NSG.id
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint
  ]
}

resource "azurerm_network_security_rule" "http" {
  name                        = "example"
  access                      = "Deny"
  direction                   = "Inbound"
  network_security_group_name = azurerm_network_security_group.NSG.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.testRG.name
  destination_port_range = 80
  source_port_range           = "*"
  destination_address_prefix  = "*"
  source_address_prefix  = "Internet"
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint,
    azurerm_network_security_group.NSG
  ]
}

resource "azurerm_network_security_rule" "https" {
  name                        = "example"
  access                      = "Deny"
  direction                   = "Inbound"
  network_security_group_name = azurerm_network_security_group.NSG.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.testRG.name
  destination_port_range = 443
  source_port_range           = "*"
  destination_address_prefix  = "*"
  source_address_prefix  = "Internet"
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint,
    azurerm_network_security_group.NSG
  ]
}

resource "azurerm_network_security_rule" "rdp" {
  name                        = "example2"
  access                      = "Deny"
  direction                   = "Inbound"
  network_security_group_name = azurerm_network_security_group.NSG.name
  priority                    = 110
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.testRG.name
  destination_port_range = 3389
  source_port_range           = "*"
  destination_address_prefix  = "*"
  source_address_prefix  = "Internet"
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint,
    azurerm_network_security_group.NSG
  ]
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "example3"
  access                      = "Deny"
  direction                   = "Inbound"
  network_security_group_name = azurerm_network_security_group.NSG.name
  priority                    = 120
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.testRG.name
  destination_port_range = 22
  source_port_range           = "*"
  destination_address_prefix  = "*"
  source_address_prefix  = "Internet"
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint,
    azurerm_network_security_group.NSG
  ]
}

resource "azurerm_storage_account" "testSA" {
  name                     = "kmiszeltestsa12"
  account_kind = "StorageV2"
  identity {
    type = "UserAssigned"
  }
  resource_group_name      = azurerm_resource_group.testRG.name
  location                 = azurerm_resource_group.testRG.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = false
  blob_properties {
    delete_retention_policy {
      days = 365
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  sas_policy {
    expiration_period = "2024-12-30T20:00:00Z"
  }
  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.example.id
    user_assigned_identity_id = ""
  }
  queue_properties  {
    logging {
        delete                = true
        read                  = true
        write                 = true
        version               = "1.0"
        retention_policy_days = 10
    }
  }
}

resource "azurerm_private_endpoint" "testprvendpoint" {
  name                = "testprvendpoint"
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
  subnet_id = azurerm_subnet.endpoint.id
  private_service_connection {
    name                           = "example-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.testSA.id
    is_manual_connection = false
  }
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_virtual_network.example,
    azurerm_subnet.endpoint,
    azurerm_storage_account.testSA
  ]
}

resource "azurerm_key_vault" "example" {
  name                = "kmiszelghakv"
  resource_group_name = azurerm_resource_group.testRG.name
  location            = azurerm_resource_group.testRG.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = true
  public_network_access_enabled = false
  soft_delete_retention_days  = 7
  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["Get", "Create", "WrapKey", "UnwrapKey", "Sign", "Verify"]
  }
  depends_on = [ 
    azurerm_resource_group.testRG
  ]
}

resource "azurerm_key_vault_key" "example" {
  name         = "example-cmk"
  key_vault_id = azurerm_key_vault.example.id
  expiration_date = "2024-12-30T20:00:00Z"
  key_type     = "RSA-HSM"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify"]
  depends_on = [ 
    azurerm_resource_group.testRG,
    azurerm_key_vault.example
  ]
}

data "azurerm_client_config" "current" {}

# resource "azurerm_private_endpoint" "testprvendpoint2" {
#   name                = "testprvendpoint2"
#   location            = azurerm_resource_group.testRG.location
#   resource_group_name = azurerm_resource_group.testRG.name
#   subnet_id = azurerm_subnet.endpoint.id
#   private_service_connection {
#     name                           = "example-privateserviceconnection2"
#     private_connection_resource_id = azurerm_key_vault.example.id
#     is_manual_connection = false
#   }
#   depends_on = [ 
#     azurerm_resource_group.testRG,
#     azurerm_virtual_network.example,
#     azurerm_subnet.endpoint,
#     azurerm_key_vault.example
#   ]
# }

