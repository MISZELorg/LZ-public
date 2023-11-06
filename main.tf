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

resource "azurerm_key_vault" "example" {
  name                = "example-keyvault"
  resource_group_name = azurerm_resource_group.testRG.name
  location            = azurerm_resource_group.testRG.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["get", "create", "wrapKey", "unwrapKey", "sign", "verify"]
  }
}

resource "azurerm_key_vault_key" "example" {
  name         = "example-cmk"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify"]
}

data "azurerm_client_config" "current" {}