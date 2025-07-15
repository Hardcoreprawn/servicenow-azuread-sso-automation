###############################################
# Azure DevOps & Secure Infra Bootstrap (TF)
###############################################

# -----------------------------------------------------------------------------
# 1. Resource Group & Networking
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}
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

# -----------------------------------------------------------------------------
# 2. Key Vault, Key, Private Endpoint, and Role Assignments
# -----------------------------------------------------------------------------
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
    ip_rules = [
      data.external.client_ip.result.ip,
      # Azure DevOps UK South agent IPs as of July 2025 (source: MSFT public doc)
      "20.49.208.0/20",
      "51.140.190.0/23",
      "51.140.192.0/20",
      "51.140.208.0/21",
      "51.140.216.0/22",
      "51.140.220.0/23",
      "51.140.222.0/24",
      "51.140.223.0/24",
      # Directly observed Azure DevOps agent IP
      "40.74.28.19"
    ]
  }
}
resource "azurerm_key_vault_key" "cmk" {
  name         = "tfstate-cmk"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "verify", "wrapKey", "unwrapKey"]
}
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
# Key Vault Role Assignments
resource "azurerm_role_assignment" "bootstrap_kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "bootstrap_kv_certificate_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "bootstrap_kv_crypto_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "storage_cmk_kv_crypto_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = azurerm_user_assigned_identity.storage_cmk.principal_id
}

# -----------------------------------------------------------------------------
# 3. Storage Account, UAMI, Private Endpoint, and Role Assignments
# -----------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "storage_cmk" {
  name                = "devops-uami"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}
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
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.storage_cmk.id]
  }
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.cmk.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage_cmk.id
  }
}

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

# -----------------------------------------------------------------------------
# 5. Azure DevOps Project, Agent Pool, Service Connection, Variable Group, Repos, Pipelines, and Key Vault Secrets
# -----------------------------------------------------------------------------
resource "azuredevops_project" "main" {
  name               = var.azdo_project_name
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

resource "azuredevops_serviceendpoint_azurerm" "main" {
  project_id                             = azuredevops_project.main.id
  service_endpoint_name                  = "AzureRM-ServiceConnection"
  service_endpoint_authentication_scheme = "ManagedServiceIdentity"
  azurerm_spn_tenantid                   = azurerm_key_vault_secret.spn_tenant_id.value
  azurerm_subscription_id                = azurerm_key_vault_secret.subscription_id.value
  azurerm_subscription_name              = "Example Subscription Name"
  description                            = "Service connection for Terraform pipelines using UAMI"
}

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
resource "azuredevops_build_definition" "create_request" {
  project_id = azuredevops_project.main.id
  name       = "Create Request"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.vending_machine.id
    branch_name = "main"
    yml_path    = "azure-pipelines-create-request.yml"
  }
  ci_trigger {
    use_yaml = true
  }
}
resource "azuredevops_build_definition" "process_request" {
  project_id = azuredevops_project.main.id
  name       = "Process Requests"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.vending_machine.id
    branch_name = "main"
    yml_path    = "azure-pipelines.yml"
  }
  ci_trigger {
    use_yaml = true
  }
}

# -----------------------------------------------------------------------------
# 6. Key Vault Secrets for DevOps (PAT, Tenant ID, Subscription ID)
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "azdo_pat" {
  name            = "azdo-pat"
  key_vault_id    = azurerm_key_vault.main.id
  not_before_date = timestamp()
  expiration_date = timeadd(timestamp(), "744h") # 31 days
  value = "" # PAT will be set manually in Key Vault
  lifecycle {
    ignore_changes = [
      value, # PAT will be set manually in Key Vault
    ]
  }
}

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

