# Variable file for the AKS deployment
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
  default     = "my-aks-resource-group"
}

variable "location" {
  type        = string
  description = "The location of the resources"
  default     = "East US"
}