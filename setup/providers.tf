terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.10"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuredevops" {
  org_service_url = var.azdo_org_service_url
}
