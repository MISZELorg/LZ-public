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

resource "azurerm_resource_group" "testRG" {
  name     = "test-RG"
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                      = "kmiszelsonarcloud1"
  resource_group_name       = azurerm_resource_group.testRG.name
  location                  = azurerm_resource_group.testRG.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  identity {
    type = "SystemAssigned"
  }
}