# Example/test request for IT Support
#
# This request demonstrates how to instantiate the app_sso module for a real department/application/ticket.
#
# All values are for testing/demo purposes only.

## Faking an increment

module "app_sso" {
  source              = "../../../terraform/modules/app_sso"
  app_name            = "it-support-app"
  sign_in_audience    = "AzureADMyOrg"
  requester_object_id = "00000000-0000-0000-0000-000000000010"
  user_object_ids     = ["00000000-0000-0000-0000-000000000011", "00000000-0000-0000-0000-000000000012"]
}
