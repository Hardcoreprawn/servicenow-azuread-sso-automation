# Input variables for setup

# 1. Resource Group
variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "eastus"
}

# 2. Networking (VNet & Subnet)
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

# 3. Key Vault and Key
variable "key_vault_name" {
  description = "Key Vault Name"
  type        = string
}

# 4. Storage Account
variable "storage_account_name" {
  description = "Storage Account Name (must be globally unique)"
  type        = string
}

# 5. Compute (VMSS for Agents)
variable "agent_vmss_name" {
  description = "VMSS Name for self-hosted agents"
  type        = string
}

variable "agent_admin_username" {
  description = "Admin username for agent VMs"
  type        = string
}

variable "agent_count" {
  description = "Number of Azure DevOps agent containers to run on the VMSS instance."
  type        = number
  default     = 3
}

variable "agent_pool_name" {
  description = "Azure DevOps Agent Pool Name"
  type        = string
  default     = "azdo-ap-avm-agent-pool"
}

# 6. User Assigned Managed Identity
variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

# 7. Azure DevOps Project & Auth
variable "azdo_org_service_url" {
  description = "Azure DevOps organization URL (e.g. https://dev.azure.com/yourorg)"
  type        = string
}

variable "azdo_project_name" {
  description = "Azure DevOps Project Name"
  type        = string
}


# 9. Azure DevOps Git Repos
variable "vending_machine_repo_name" {
  description = "Name of the Azure DevOps repo for the vending machine logic"
  type        = string
}

variable "modules_repo_name" {
  description = "Name of the Azure DevOps repo for the shared Terraform modules"
  type        = string
}
