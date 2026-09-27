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
  }
  subscription_id = "fa62ce43-1973-4cfa-8701-52edafaeb3ac"
  tenant_id       = "f6d676f9-f942-4aa8-9e4e-ab463391f2d9"
  use_oidc        = true
}

# ── Data sources ───────────────────────────────────────────────────────────────
# Read the Key Vault created in Module 08
data "azurerm_key_vault" "sql_secrets" {
  name                = "kv-adal-08-47v7at"
  resource_group_name = "rg-adal-08-lab"
}

# Read the SQL admin password stored in Module 08
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.sql_secrets.id
}

# ── Resource group ─────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "module11_rg" {
  name     = "rg-adal-11-lab"
  location = "westus2"

  tags = {
    project     = "azure-dba-automation-lab"
    module      = "11"
    environment = "lab"
    managed_by  = "terraform"
    owner       = "srikanth.manchana"
  }
}

# ── Random suffix for SQL Server name ─────────────────────────────────────────
# SQL Server names must be globally unique across all of Azure
resource "random_string" "sql_suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# ── Azure SQL Server (logical server) ─────────────────────────────────────────
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-adal-11-${random_string.sql_suffix.result}"
  resource_group_name          = azurerm_resource_group.module11_rg.name
  location                     = azurerm_resource_group.module11_rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value

  # Disable public network access in production
  # Keeping enabled for lab to allow Azure services connectivity
  public_network_access_enabled = true

  # Minimum TLS version for all connections
  minimum_tls_version = "1.2"

  tags = azurerm_resource_group.module11_rg.tags
}

# ── Azure SQL Database ─────────────────────────────────────────────────────────
resource "azurerm_mssql_database" "sql_db" {
  name      = "sqldb-adal-11-lab"
  server_id = azurerm_mssql_server.sql_server.id

  # Basic tier — cheapest option for lab (~$5/month)
  # 5 DTUs, 2 GB storage max
  sku_name = "Basic"

  # Maximum storage for Basic tier
  max_size_gb = 2

  # Collation — SQL_Latin1_General_CP1_CI_AS is the default
  # and most compatible with on-prem SQL Server migrations
  collation = "SQL_Latin1_General_CP1_CI_AS"

  # Zone redundancy not available on Basic tier
  zone_redundant = false

  # Keep backups for 7 days (minimum)
  short_term_retention_policy {
    retention_days           = 7
    backup_interval_in_hours = 12
  }

  tags = azurerm_resource_group.module11_rg.tags
}

# ── Firewall rule — allow Azure services ──────────────────────────────────────
# Allows other Azure services (Azure Data Factory, Logic Apps, etc.)
# to connect to the SQL Server
# Start and end IP of 0.0.0.0 is a special Azure rule meaning
# "allow all Azure-originated traffic"
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "sql_server_name" {
  value       = azurerm_mssql_server.sql_server.name
  description = "SQL Server logical server name"
}

output "sql_server_fqdn" {
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
  description = "SQL Server FQDN — use this to connect"
}

output "sql_database_name" {
  value       = azurerm_mssql_database.sql_db.name
  description = "SQL Database name"
}

output "sql_connection_string" {
  value       = "Server=${azurerm_mssql_server.sql_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.sql_db.name};User Id=sqladmin;Password=<from-key-vault>;Encrypt=true;TrustServerCertificate=false;"
  description = "ADO.NET connection string — password must be retrieved from Key Vault"
  sensitive   = false
}