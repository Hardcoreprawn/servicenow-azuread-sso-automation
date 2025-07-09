# Example/test request for HR Onboarding
#
# This request demonstrates how to instantiate the app_sso module for a real department/application/ticket.
#
# All values are for testing/demo purposes only.

module "app_sso" {
  source              = "../../../terraform/modules/app_sso"
  app_name            = "hr-onboarding-app"
  sign_in_audience    = "AzureADMyOrg"
  requester_object_id = "00000000-0000-0000-0000-000000000001"
  user_object_ids     = ["00000000-0000-0000-0000-000000000002"]
}
