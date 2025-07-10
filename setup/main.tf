###############################################
# Azure DevOps & Secure Infra Bootstrap (TF)
###############################################

terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.10"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "azuredevops" {
  org_service_url       = var.azdo_org_service_url
  personal_access_token = var.azdo_pat
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault with Private Endpoint
resource "azurerm_key_vault" "main" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
  enable_rbac_authorization   = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# CMK for Storage Account
resource "azurerm_key_vault_key" "cmk" {
  name         = "tfstate-cmk"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
}

# Storage Account for Terraform State (private, CMK encrypted)
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
  }
  identity {
    type = "SystemAssigned"
  }
  customer_managed_key {
    key_vault_key_id = azurerm_key_vault_key.cmk.id
    user_assigned_identity_id = null # Uses system-assigned identity
  }
}

# Private Virtual Network and Subnet
resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Self-hosted Agent Pool (VMSS-based)
resource "azurerm_linux_virtual_machine_scale_set" "agentpool" {
  name                = var.agent_vmss_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_DS2_v2"
  instances           = 2
  admin_username      = var.agent_admin_username
  admin_password      = var.agent_admin_password
  disable_password_authentication = false
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  network_interface {
    name    = "agent-nic"
    primary = true
    ip_configuration {
      name      = "internal"
      subnet_id = azurerm_subnet.private.id
      primary   = true
    }
  }
}

# Azure DevOps Project
resource "azuredevops_project" "main" {
  name       = var.azdo_project_name
  visibility = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

# User Assigned Managed Identity for DevOps Service Connection
resource "azurerm_user_assigned_identity" "devops" {
  name                = "devops-uami"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Azure DevOps Service Connection (AzureRM, UAMI)
resource "azuredevops_serviceendpoint_azurerm" "main" {
  project_id                = azuredevops_project.main.id
  service_endpoint_name     = "AzureRM-ServiceConnection"
  service_endpoint_authentication_scheme = "ManagedServiceIdentity"
  azurerm_spn_tenantid                   = "00000000-0000-0000-0000-000000000000"
  azurerm_subscription_id                = "00000000-0000-0000-0000-000000000000"
  azurerm_subscription_name              = "Example Subscription Name"
  
  
  
  managed_service_identity {
    client_id = azurerm_user_assigned_identity.devops.client_id
  }
  description = "Service connection for Terraform pipelines using UAMI"
}

# Azure DevOps Variable Group (Key Vault-backed)
resource "azuredevops_variable_group_key_vault" "kv" {
  project_id   = azuredevops_project.main.id
  name         = "KeyVault-Secrets"
  description  = "Secrets from Azure Key Vault for pipelines"
  key_vault_name                = azurerm_key_vault.main.name
  service_endpoint_id           = azuredevops_serviceendpoint_azurerm.main.id
  allow_access                  = true
}

# Azure DevOps Repos
resource "azuredevops_git_repository" "vending_machine" {
  project_id = azuredevops_project.main.id
  name       = var.vending_machine_repo_name
  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository" "modules" {
  project_id = azuredevops_project.main.id
  name       = var.modules_repo_name
  initialization {
    init_type = "Clean"
  }
}

# Azure DevOps Pipelines
resource "azuredevops_build_definition" "create_request" {
  project_id = azuredevops_project.main.id
  name       = "Create Request"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_project.main.id
    branch_name = "main"
    yml_path = "azure-pipelines-create-request.yml"
  }
  ci_trigger {
    use_yaml = true
  }
  agent_pool_name = var.agent_pool_name
}

resource "azuredevops_build_definition" "process_request" {
  project_id = azuredevops_project.main.id
  name       = "Process Requests"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_project.main.id
    branch_name = "main"
    yml_path = "azure-pipelines.yml"
  }
  ci_trigger {
    use_yaml = true
  }
  agent_pool_name = var.agent_pool_name
}
