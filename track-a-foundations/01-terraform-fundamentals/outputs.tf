output "resource_group_name" {
  description = "The name of the resource group that was craeted"
  value       = azurerm_resource_group.lab.name
}

output "resource_group_location" {
  description = "The location of the resource group that was created"
  value       = azurerm_resource_group.lab.location
}