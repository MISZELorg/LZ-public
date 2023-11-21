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

# resource "azurerm_resource_group" "testRG2" {
#   name     = "test-RG2"
#   location = var.location
# }

resource "azurerm_storage_account" "example-sa" {
  name                     = "kmiszeltfsec"
  resource_group_name      = azurerm_resource_group.testRG.name
  location                 = azurerm_resource_group.testRG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # enable_https_traffic_only = true
  # min_tls_version           = "TLS1_2"
  # identity {
  #   type = "SystemAssigned"
  # }
}

# resource "azurerm_storage_account" "example" {
#   name                      = "kmiszelsonarcloud1"
#   resource_group_name       = azurerm_resource_group.testRG.name
#   location                  = azurerm_resource_group.testRG.location
#   account_tier              = "Standard"
#   account_replication_type  = "GRS"
#   enable_https_traffic_only = true
#   min_tls_version           = "TLS1_2"
#   identity {
#     type = "SystemAssigned"
#   }
# }

# resource "azurerm_service_plan" "example-asp" {
#   name                = "example-asp"
#   resource_group_name = azurerm_resource_group.testRG.name
#   location            = azurerm_resource_group.testRG.location
#   os_type             = "Linux"
#   sku_name            = "P1v2"
# }

# resource "azurerm_linux_web_app" "example" {
#   name                = "kmiszelsonar"
#   resource_group_name = azurerm_resource_group.testRG.name
#   location            = azurerm_resource_group.testRG.location
#   service_plan_id     = azurerm_service_plan.example-asp.id
#   # client_certificate_enabled = false
#   # client_certificate_mode    = "Required"
#   client_certificate_enabled = true
#   client_certificate_mode    = "Optional"
#   auth_settings {
#     enabled = true
#   }
#   identity {
#     type = "SystemAssigned"
#   }
#   site_config {}
# }