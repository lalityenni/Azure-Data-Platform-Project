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