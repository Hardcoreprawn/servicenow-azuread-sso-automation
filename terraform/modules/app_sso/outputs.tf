# Outputs for the app_sso module
#
# - application_id: The Application (client) ID of the created Azure AD app
# - owners_group_id: The object ID of the owners group
# - users_group_id: The object ID of the users group
#
# These outputs can be used for integration, testing, or further automation.

output "application_id" {
  description = "The Application (client) ID of the created Azure AD app."
  value       = azuread_application.app.application_id
}

output "owner_group_id" {
  description = "The object ID of the owner group."
  value       = azuread_group.owner.object_id
}

output "users_group_id" {
  description = "The object ID of the users group."
  value       = azuread_group.users.object_id
}
