variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "westus2"
}

variable "environment" {
  description = "The environment for the deployment (dev, lab, prod)."
  type        = string
  default     = "lab"
}

variable "project" {
  description = "The project identifier used in all resource names"
  type        = string
  default     = "adal"
}