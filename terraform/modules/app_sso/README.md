# Terraform module: app_sso

This module provisions an Azure AD Application (AppID), an owner group, and a users group for SSO scenarios.

## Inputs
- `app_name` (string, required): Root name for the application. Used for naming all resources.
- `requester_object_id` (string, required): Azure AD object ID of the requester (added to owner group).
- `user_object_ids` (list(string), optional): List of Azure AD object IDs (users or groups) to add to the app's users group.

## Outputs
- `application_id`: The Application (client) ID of the created Azure AD app.
- `owner_group_id`: The object ID of the owner group.
- `users_group_id`: The object ID of the users group.

## Example Usage

```hcl
module "app_sso" {
  source              = "./modules/app_sso"
  app_name            = "my-app"
  requester_object_id = "00000000-0000-0000-0000-000000000000"
  user_object_ids     = ["11111111-1111-1111-1111-111111111111"]
}
```

This will create:
- An Azure AD Application named `my-app`
- An owner group named `my-app-owner` with the requester as owner
- A users group named `my-app-users` with the provided users/groups as members
- Assign the owner group as an owner of the app
