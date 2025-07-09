# Variables for a new app SSO request
#
# Set these values for each request. These are passed to the app_sso module.
#
# - app_name: Root name for the application
# - sign_in_audience: Azure AD audience (default: AzureADMyOrg)
# - requester_object_id: Azure AD object ID of the requester
# - user_object_ids: List of Azure AD object IDs (users/groups) to add to users group

variable "app_name" {
  description = "The root name for the application. Used for naming all resources."
  type        = string
}

variable "sign_in_audience" {
  description = "The sign-in audience for the Azure AD application."
  type        = string
  default     = "AzureADMyOrg"
}

variable "requester_object_id" {
  description = "The Azure AD object ID of the requester to be added to the owners group."
  type        = string
}

variable "user_object_ids" {
  description = "A list of Azure AD object IDs (users or groups) to be added to the app users group."
  type        = list(string)
  default     = []
}
