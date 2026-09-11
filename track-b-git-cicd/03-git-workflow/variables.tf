variable "sqlserver_max_memory_pct" {
  type        = number
  description = "Percentage of host RAM to allocate to SQL Server max server memory. Production best practice: 80."
  default     = 80

  validation {
    condition     = var.sqlserver_max_memory_pct >= 50 && var.sqlserver_max_memory_pct <= 90
    error_message = "max_memory_pct must be between 50 and 90. Values below 50 starve the database; above 90 leave insufficient memory for the OS."
  }
}

#Reserved for future SQL Server configuration variables, such as min memory, max degree of parallelism, etc.