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
  personal_access_token = azurerm_key_vault_secret.azdo_pat.value
}

# 1. Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Networking (VNet & Subnet)
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

# 3. Key Vault and Key
resource "azurerm_key_vault" "main" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_key" "cmk" {
  name         = "tfstate-cmk"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
}

# 3b. Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "keyvault-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "keyvault-pe-connection"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

# 4. Storage Account (for Terraform State)
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  identity {
    type = "SystemAssigned"
  }
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.cmk.id
    user_assigned_identity_id = null # Uses system-assigned identity
  }
}

# 4b. Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "tfstate" {
  name                = "tfstate-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "tfstate-pe-connection"
    private_connection_resource_id = azurerm_storage_account.tfstate.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

# 5. Compute (VMSS for Agents)
resource "azurerm_linux_virtual_machine_scale_set" "agentpool" {
  name                            = var.agent_vmss_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  sku                             = "Standard_DS2_v2"
  instances                       = 1
  admin_username                  = var.agent_admin_username
  admin_password                  = var.agent_admin_password
  disable_password_authentication = false
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-noble"
    sku       = "24_04-lts"
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
  custom_data = base64encode(templatefile("${path.module}/cloud-init-azdo-agents.yaml", {
    azdo_url     = var.azdo_org_service_url
    azdo_pat     = var.azdo_pat
    agent_pool   = var.agent_pool_name
    agent_count  = var.agent_count
    agent_prefix = var.agent_vmss_name
  }))
}

# 6. User Assigned Managed Identity (for DevOps Service Connection)
resource "azurerm_user_assigned_identity" "devops" {
  name                = "devops-uami"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# 7. Azure DevOps Project
resource "azuredevops_project" "main" {
  name               = var.azdo_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

# 8. Azure DevOps Service Connection (AzureRM, UAMI)
resource "azuredevops_serviceendpoint_azurerm" "main" {
  project_id                             = azuredevops_project.main.id
  service_endpoint_name                  = "AzureRM-ServiceConnection"
  service_endpoint_authentication_scheme = "ManagedServiceIdentity"
  azurerm_spn_tenantid                   = azurerm_key_vault_secret.spn_tenant_id.value
  azurerm_subscription_id                = azurerm_key_vault_secret.subscription_id.value
  azurerm_subscription_name              = "Example Subscription Name"
  description                            = "Service connection for Terraform pipelines using UAMI"
}

# 9. Azure DevOps Variable Group (Key Vault-backed)
resource "azuredevops_variable_group" "kv" {
  project_id  = azuredevops_project.main.id
  name        = "KeyVault-Secrets"
  description = "Secrets from Azure Key Vault for pipelines"
  key_vault {
    name                = azurerm_key_vault.main.name
    service_endpoint_id = azuredevops_serviceendpoint_azurerm.main.id
  }
  variable {
    name = "TF_VAR_agent_admin_password"
  }
  variable {
    name = "TF_VAR_azdo_pat"
  }
}

# 10. Azure DevOps Git Repos
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

# 11. Azure DevOps Pipelines
resource "azuredevops_build_definition" "create_request" {
  project_id = azuredevops_project.main.id
  name       = "Create Request"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_project.main.id
    branch_name = "main"
    yml_path    = "azure-pipelines-create-request.yml"
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
    yml_path    = "azure-pipelines.yml"
  }
  ci_trigger {
    use_yaml = true
  }
  agent_pool_name = var.agent_pool_name
}

# 12. Store Azure DevOps PAT in Key Vault
resource "azurerm_key_vault_secret" "azdo_pat" {
  name         = "azdo-pat"
  value        = var.azdo_pat
  key_vault_id = azurerm_key_vault.main.id
}

# 6b. Store AzureRM SPN Tenant ID and Subscription ID in Key Vault
resource "azurerm_key_vault_secret" "spn_tenant_id" {
  name         = "azurerm-spn-tenant-id"
  value        = var.tenant_id
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "subscription_id" {
  name         = "azurerm-subscription-id"
  value        = var.subscription_id
  key_vault_id = azurerm_key_vault.main.id
}
