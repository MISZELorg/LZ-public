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
  resource_group_name      = azurerm_resource_group.testRG.name
  location                 = azurerm_resource_group.testRG.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  enable_https_traffic_only = true
  public_network_access_enabled = false
  allow_nested_items_to_be_public = false
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

resource "azurerm_storage_container" "testcontainer" {
  name                  = "mycontainer"
  storage_account_name  = azurerm_storage_account.testSA.name
  container_access_type = "private"
}

resource "azurerm_storage_container_sas" "example" {
  connection_string = azurerm_storage_account.testSA.primary_connection_string
  start            = "2023-11-06"
  expiry           = "2023-12-31"
  container_name    = azurerm_storage_container.testcontainer.name
  permissions      = {
    read = true
    list = true
    write = false
    delete = false
  }
}