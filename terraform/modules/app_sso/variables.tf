# Terraform module for Azure AD App SSO provisioning

# Variables for the app_sso module
#
# - app_name: Root name for the application (used for naming all resources)
# - sign_in_audience: Azure AD audience (default: AzureADMyOrg)
# - requester_object_id: Azure AD object ID of the requester (added to owners group)
# - user_object_ids: List of Azure AD object IDs (users/groups) to add to users group
#
# All variables are required except where a default is provided. See main.tf for usage.

variable "app_name" {
  description = "The root name for the application. Used for naming all resources."
  type        = string
}

variable "requester_object_id" {
  description = "The Azure AD object ID of the requester to be added to the owner group."
  type        = string
}

variable "user_object_ids" {
  description = "A list of Azure AD object IDs (users or groups) to be added to the app access group."
  type        = list(string)
  default     = []
}

variable "sign_in_audience" {
  description = "The sign-in audience for the Azure AD application (e.g., AzureADMyOrg, AzureADMultipleOrgs, AzureADandPersonalMicrosoftAccount)."
  type        = string
  default     = "AzureADMyOrg"
}

# Optional: Uncomment if you want to support redirect URIs
# variable "redirect_uris" {
#   description = "A list of redirect URIs for the app's web platform."
#   type        = list(string)
#   default     = []
# }
