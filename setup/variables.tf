# Input variables for setup

variable "azdo_org_service_url" {
  description = "Azure DevOps organization URL (e.g. https://dev.azure.com/yourorg)"
  type        = string
}

variable "azdo_pat" {
  description = "Azure DevOps Personal Access Token (set via env var)"
  type        = string
  sensitive   = true
}

variable "azdo_project_name" {
  description = "Azure DevOps Project Name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "eastus"
}

variable "key_vault_name" {
  description = "Key Vault Name"
  type        = string
}

variable "storage_account_name" {
  description = "Storage Account Name (must be globally unique)"
  type        = string
}

variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet Address Space (e.g. 10.0.0.0/16)"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Subnet Address Prefix (e.g. 10.0.1.0/24)"
  type        = string
}

variable "agent_vmss_name" {
  description = "VMSS Name for self-hosted agents"
  type        = string
}

variable "agent_admin_username" {
  description = "Admin username for agent VMs"
  type        = string
}

variable "agent_admin_password" {
  description = "Admin password for agent VMs (set via env var)"
  type        = string
  sensitive   = true
}

variable "agent_pool_name" {
  description = "Azure DevOps Agent Pool Name"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret (set via env var)"
  type        = string
  sensitive   = true
}

variable "vending_machine_repo_name" {
  description = "Name of the Azure DevOps repo for the vending machine logic"
  type        = string
}

variable "modules_repo_name" {
  description = "Name of the Azure DevOps repo for the shared Terraform modules"
  type        = string
}
