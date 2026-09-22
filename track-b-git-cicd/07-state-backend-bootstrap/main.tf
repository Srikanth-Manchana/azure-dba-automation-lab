terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = "fa62ce43-1973-4cfa-8701-52edafaeb3ac"
  tenant_id       = "f6d676f9-f942-4aa8-9e4e-ab463391f2d9"
  use_oidc        = true
}

resource "azurerm_resource_group" "state_rg" {
  name     = "rg-adal-tfstate"
  location = "westus2"

  tags = {
    project     = "azure-dba-automation-lab"
    purpose     = "terraform-state"
    managed_by  = "terraform-bootstrap"
    environment = "lab"
    owner       = "srikanth.manchana"
  }
}

resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
  lower   = true
}

resource "azurerm_storage_account" "state_storage" {
  name                            = "stadalstate${random_string.storage_suffix.result}"
  resource_group_name             = azurerm_resource_group.state_rg.name
  location                        = azurerm_resource_group.state_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  access_tier                     = "Hot"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  public_network_access_enabled   = true

  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    last_access_time_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = azurerm_resource_group.state_rg.tags
}

resource "azurerm_storage_container" "state_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.state_storage.name
  container_access_type = "private"

  metadata = {
    purpose = "terraform-state-files"
    module  = "07-state-backend-bootstrap"
  }
}

output "container_name" {
  value       = azurerm_storage_container.state_container.name
  description = "Name of the storage container for Terraform state files"
}

output "storage_account_name" {
  value       = azurerm_storage_account.state_storage.name
  description = "Name of the storage account for Terraform state files"
}

output "resource_group_name" {
  value       = azurerm_resource_group.state_rg.name
  description = "Name of the resource group for Terraform state files"
}

output "backend_config" {
  value = {
    resource_group_name  = azurerm_resource_group.state_rg.name
    storage_account_name = azurerm_storage_account.state_storage.name
    container_name       = azurerm_storage_container.state_container.name
  }
  description = "Complete terraform backend configuration for state files - copy all values into your backend.tf file"
}


