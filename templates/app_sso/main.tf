# Template for a new app SSO request
#
# This file instantiates the app_sso module with variables provided in variables.tf.
#
# All changes should be made in the request's variables.tf for maintainability and safety.

module "app_sso" {
  source              = "../../terraform/modules/app_sso"
  app_name            = var.app_name
  sign_in_audience    = var.sign_in_audience
  requester_object_id = var.requester_object_id
  user_object_ids     = var.user_object_ids
}
