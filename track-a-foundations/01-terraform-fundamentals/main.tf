resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.project}-01-${var.environment}"
  location = var.location

  tags = {
    project     = "azure-dba-automation-lab"
    module      = "01"
    environment = var.environment
    managed_by  = "terraform"
  }
}