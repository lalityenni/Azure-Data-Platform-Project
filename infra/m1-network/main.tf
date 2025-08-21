terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
<<<<<<< HEAD
  name     = "rg-adp-dev-eus"
=======
  name = "rg-adp-dev-eus"
>>>>>>> d4a165e (chore: add terraform.required_version and provider versions (tflint fix))
  location = "East US"
}