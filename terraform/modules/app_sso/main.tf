# This module provisions an Azure AD Application (AppID), an owners group, and a users group for SSO scenarios.
# It is designed for maintainability, testability, and safety.
#
# Usage: Use as a module in a request's main.tf. All variables must be provided by the request.
#
# - app_name: Root name for the application (used for naming all resources)
# - sign_in_audience: Azure AD audience (default: AzureADMyOrg)
# - requester_object_id: Azure AD object ID of the requester (added to owners group)
# - user_object_ids: List of Azure AD object IDs (users/groups) to add to users group
#
# All resources are named consistently and can be safely managed by Terraform.
#
# See README.md for more details and examples.

# Main resources for App SSO provisioning

resource "azuread_application" "app" {
  display_name     = var.app_name
  sign_in_audience = var.sign_in_audience
  owners           = [var.requester_object_id]
  # Optional: Add redirect URIs, app roles, required resource access as needed
  # web {
  #   redirect_uris = var.redirect_uris
  # }
}

resource "azuread_service_principal" "app_sp" {
  client_id = azuread_application.app.application_id
  owners    = [var.requester_object_id]
}

resource "azuread_group" "owners" {
  display_name     = "${var.app_name}-owners"
  description      = "Owners of ${var.app_name} SSO application"
  security_enabled = true
  owners           = [var.requester_object_id]
}

resource "azuread_group" "users" {
  display_name     = "${var.app_name}-users"
  description      = "Users of ${var.app_name} SSO application"
  security_enabled = true
  members          = var.user_object_ids
}

resource "azuread_application_owner" "app_owner" {
  application_id   = azuread_application.app.application_id
  owner_object_id  = azuread_group.owners.object_id
}
