# Outputs for integration and next steps

output "key_vault_uri" {
  description = "Key Vault URI for secret reference"
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_blob_endpoint" {
  description = "Storage Account Blob Endpoint for Terraform state"
  value       = azurerm_storage_account.tfstate.primary_blob_endpoint
}

output "agent_pool_name" {
  description = "Name of the Azure DevOps self-hosted agent pool"
  value       = var.agent_pool_name
}

output "devops_project_id" {
  description = "Azure DevOps Project ID"
  value       = azuredevops_project.main.id
}

output "service_connection_id" {
  description = "Azure DevOps Service Connection ID"
  value       = azuredevops_serviceendpoint_azurerm.main.id
}

output "variable_group_id" {
  description = "Azure DevOps Variable Group ID (Key Vault-backed)"
  value       = azuredevops_variable_group.kv.id
}
