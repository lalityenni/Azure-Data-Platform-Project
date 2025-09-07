variable "rg_name" {
  description = "The name of the resource group"
  type        = string
}
variable "location" {
  description = "The Azure region to deploy resources in"
  type        = string
}
variable "adf_name" {
  type    = string
  default = "adf-adp-dev-eus"
}

variable "subscription_id" {
  description = "The subscription ID where resources will be deployed"
  type        = string 
}

variable "storage_account_name" {
  description = "The name of the storage account to be used by ADF"
  type        = string
  default     = "stadpadpdeveus"
}