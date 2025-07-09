# Example/test request for Finance Payroll
#
# This request demonstrates how to instantiate the app_sso module for a real department/application/ticket.
#
# All values are for testing/demo purposes only.

module "app_sso" {
  source              = "../../../terraform/modules/app_sso"
  app_name            = "finance-payroll-app"
  sign_in_audience    = "AzureADMyOrg"
  requester_object_id = "00000000-0000-0000-0000-000000000020"
  user_object_ids     = ["00000000-0000-0000-0000-000000000021"]
}
