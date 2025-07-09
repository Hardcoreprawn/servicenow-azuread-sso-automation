# Variables for the HR Onboarding test request
#
# Set these values for this specific request. These are passed to the app_sso module.

variable "app_name" { default = "hr-onboarding-app" }
variable "sign_in_audience" { default = "AzureADMyOrg" }
variable "requester_object_id" { default = "00000000-0000-0000-0000-000000000001" }
variable "user_object_ids" { default = ["00000000-0000-0000-0000-000000000002"] }
