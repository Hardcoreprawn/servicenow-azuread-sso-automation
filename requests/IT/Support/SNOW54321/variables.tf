# Variables for the IT Support test request
#
# Set these values for this specific request. These are passed to the app_sso module.

variable "app_name" { default = "it-support-app" }
variable "sign_in_audience" { default = "AzureADMyOrg" }
variable "requester_object_id" { default = "00000000-0000-0000-0000-000000000010" }
variable "user_object_ids" { default = ["00000000-0000-0000-0000-000000000011", "00000000-0000-0000-0000-000000000012"] }
