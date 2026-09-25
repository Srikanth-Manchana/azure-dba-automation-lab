terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "fa62ce43-1973-4cfa-8701-52edafaeb3ac"
  tenant_id       = "f6d676f9-f942-4aa8-9e4e-ab463391f2d9"
  use_oidc        = true
}

# ── Data source — current subscription ────────────────────────────────────────
data "azurerm_subscription" "current" {}

# ── Azure Budget Alert ─────────────────────────────────────────────────────────
# Sends email when actual spend reaches 80% and 100% of the monthly budget
resource "azurerm_consumption_budget_subscription" "lab_budget" {
  name            = "adal-lab-monthly-budget"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 20
  time_grain = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z"
    end_date   = "2027-09-30T00:00:00Z"
  }

  # Alert at 80% of budget
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [
      "smanchana.work@gmail.com"
    ]
  }

  # Alert at 100% of budget
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [
      "smanchana.work@gmail.com"
    ]
  }

  # Alert when forecasted spend will exceed budget
  notification {
    enabled        = true
    threshold      = 110
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [
      "smanchana.work@gmail.com"
    ]
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "budget_name" {
  value       = azurerm_consumption_budget_subscription.lab_budget.name
  description = "Name of the Azure budget alert"
}

output "budget_amount" {
  value       = azurerm_consumption_budget_subscription.lab_budget.amount
  description = "Monthly budget amount in USD"
}
