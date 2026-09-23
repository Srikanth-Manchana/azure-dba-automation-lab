terraform {
  backend "azurerm" {
    resource_group_name  = "rg-adal-tfstate"
    storage_account_name = "stadalstateadcy0lo2"
    container_name       = "tfstate"
    key                  = "08-key-vault-zero-trust.terraform.tfstate"
  }
}
