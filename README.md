# ServiceNow Azure AD SSO Automation

This project automates the creation and management of Azure AD Single Sign-On (SSO) applications through ServiceNow ticketing and Azure DevOps pipelines, using Infrastructure as Code (IaC) with Terraform.

## ITSM Integration Abstraction

> **Note:** The integration with ServiceNow (or any ITSM system, such as HaloITSM) is handled via a dedicated script or pipeline step. This makes it easy to swap out ServiceNow for another ITSM platform by only changing the integration script, not the core automation or workflow.
>
> - All ITSM-specific logic (triggering, ticket updates, status reporting) should be implemented in a single script or pipeline task (e.g., `scripts/itsm_integration.sh` or a pipeline step).
> - To switch to a different ITSM (e.g., HaloITSM), simply replace this script or step with one that uses the new ITSM's API.
> - The rest of the automation (Terraform, request structure, pipelines) remains unchanged.

## Architecture & Design Decisions

| Decision                                      | Rationale/Notes                                                                                 |
|-----------------------------------------------|-------------------------------------------------------------------------------------------------|
| App-centric request structure                 | Enables full audit trail and lifecycle management per app                                       |
| Immutable requests, explicit decommission     | Ensures traceability and safe resource destruction                                              |
| Script-driven CRUD for requests               | Consistency, safety, and auditability                                                           |
| Pipelines for automation                      | Idempotency, auditability, and integration with ServiceNow                                      |
| Secrets in Azure Key Vault                    | Centralized, secure secret management; never in code or pipelines                              |
| Expose secrets to pipelines via variable group| Secure, dynamic secret injection to Azure DevOps pipelines                                     |
| State in Storage Account with CMK             | State is encrypted at rest with customer-managed keys                                          |
| All resources on private network              | No public endpoints; reduces attack surface                                                    |
| Self-hosted agent pool (VMSS)                 | Pipeline execution is private and under organizational control                                 |
| Service connections use least-privilege SPN   | Follows security best practices for automation identities                                      |
| RBAC for Key Vault and Storage                | Only required identities have access                                                           |
| Modular, script-driven setup                  | Easy onboarding, repeatable, and maintainable                                                  |

## Design Decisions & Architecture

  - All requests are stored under `requests/<app_name>/<ticket>-<action>/`.
  - Each request (create, update, decommission) is tracked with its own ServiceNow ticket and action type.
  - Git history provides a full audit trail for each app's lifecycle.
  - Requests are never deleted unless the app is decommissioned and resources are destroyed.
  - Decommissioning is explicit and tracked.
  - Scripts in `scripts/` provide Create, Read, Update, and Decommission operations for requests.
  - All changes are made via scripts for consistency and safety.
  - Azure DevOps pipelines process requests, apply Terraform, verify resource creation, and update ServiceNow tickets.
  - Pipelines are designed for idempotency and auditability.
  - Requests can be created/managed manually or automated via ServiceNow webhooks and pipeline triggers.

## Handling Secrets & Secure Service Connections

  - All secrets (ServiceNow credentials, Azure credentials, etc.) are stored as secure pipeline variables or in Azure Key Vault.
  - Never commit secrets to the repo or pipeline YAML.
  - Reference secrets in the pipeline using `$(secret_name)` syntax.
  - Use a Service Principal with least-privilege permissions for Azure AD and resource management.
  - Store the Service Principal credentials in Azure DevOps as a Service Connection (type: Azure Resource Manager or Azure AD, as needed).
  - Restrict access to the Service Connection to only the required pipelines and users.
  - Store ServiceNow API credentials as secure pipeline variables or in Key Vault.
  - Rotate credentials regularly and audit usage.
  - Use remote state (e.g., Azure Storage, Terraform Cloud) for production to avoid state drift and enable collaboration.
  - Secure state storage with RBAC and encryption.

## Azure DevOps PAT Management and Usage


## Project Structure

```
servicenow-azuread-sso-automation
├── .devcontainer/           # Dev container configuration
├── azure-pipelines.yml      # Azure DevOps pipeline for Terraform and ServiceNow updates
├── requests/                # New IaC service requests (by department/app/request)
├── scripts/
│   └── new_app_request.sh   # Script to create new app SSO requests from template
├── templates/
│   └── app_sso/             # Template Terraform files for new app requests
├── USER_REQUEST_LOG.md      # Persistent log of user requests and actions
└── README.md                # Project documentation
```

> **Note:** Terraform modules are now sourced from a separate, versioned modules repository using Azure DevOps pipeline resources. See below for details.

## Using Shared Terraform Modules

Modules are managed in a separate repository (e.g., `terraform-azure-modules`). The Azure DevOps pipeline checks out both the vending machine repo and the modules repo using `resources.repositories`.

### Example Pipeline Snippet

```yaml
resources:
  repositories:
    - repository: tfmodules
      type: git
      name: yourorg/terraform-azure-modules
      ref: refs/tags/v1.0.0

steps:
  - checkout: self
  - checkout: tfmodules
  - script: |
      cd requests/<app_name>/<ticket>-<action>
      terraform init -from-module=../../tfmodules/app_sso
      terraform apply -auto-approve
    displayName: 'Run Terraform'
```

### Example Module Usage in Terraform

```hcl
module "app_sso" {
  source = "../../tfmodules/app_sso"
  # ...module variables...
}
```


## Workflow Overview

1. **Create a New Request:**
   - Use `scripts/new_app_request.sh <department> <application> <request_id>` to create a new request directory from the template.
   - Fill in the required variables in the new request's `variables.tf`.

2. **Pipeline Execution:**
   - Commit and push the new request to the repo.
   - The Azure DevOps pipeline (`azure-pipelines.yml`) is triggered, running Terraform to provision the app and groups.

3. **ITSM Update:**
   - The pipeline calls the ITSM integration script/step to update the ticket (ServiceNow, HaloITSM, etc.) with the result of the deployment.

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd servicenow-azuread-sso-automation
   ```
2. **Dev Container:**
   - Open in VS Code with devcontainer support for a pre-configured environment.
3. **Configure Azure DevOps Pipelines:**
   - Set up two pipelines:
     - `azure-pipelines-create-request.yml` for creating new requests.
     - `azure-pipelines.yml` for processing requests and updating ServiceNow.
   - Add all required secrets as secure pipeline variables or link to Azure Key Vault.
   - Set up an Azure Service Connection with least-privilege permissions.
4. **ServiceNow Integration:**
   - Configure ServiceNow to trigger the create-request pipeline via webhook or manual process.
   - Ensure ticket numbers are used as request identifiers.
5. **Create/Manage Requests:**
   - Use scripts in `scripts/` to create, update, list, or decommission requests.
   - All requests are stored under `requests/<app_name>/<ticket>-<action>/`.
6. **Pipeline Execution:**
   - Pipelines will process requests, apply Terraform, verify resource creation, and update ServiceNow tickets.

## Security Best Practices


## Requirements

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## References

## Private Endpoints for Key Vault and Storage Account

This configuration uses private endpoints for both the Azure Key Vault and the Storage Account, ensuring all access is via the private subnet in the VNet. The networking resources (VNet and subnet) are created before any resources that depend on them, such as private endpoints, Key Vault, and Storage Account. This ordering ensures successful deployment and secure, private connectivity.

## Devcontainer: Automatic Azure DevOps PAT Loading

> **New:** The devcontainer now automatically loads the Azure DevOps PAT from Azure Key Vault at startup, making onboarding and local development seamless. See `setup/README.md` for details on how this works and how to configure the Key Vault name.

## Architecture Overview (C4 Model)

> **Note:** Azure DevOps and standard Mermaid do not support C4-PlantUML syntax. The following diagrams use Mermaid flowcharts to represent C4 Context and Container levels.

### C4 Context Diagram
```mermaid
flowchart TD
  User[User - ServiceNow ITSM]
  ServiceNow[ServiceNow]
  AzureDevOps[Azure DevOps]
  Azure[Azure]
  KeyVault[Azure Key Vault]
  Storage[Azure Storage Account]

  User -->|Creates SSO request| ServiceNow
  ServiceNow -->|Triggers pipeline| AzureDevOps
  AzureDevOps -->|Provisions resources| Azure
  AzureDevOps -->|Reads/writes secrets| KeyVault
  AzureDevOps -->|Stores Terraform state| Storage
  Azure -->|Uses secrets| KeyVault
```

### C4 Container Diagram
```mermaid
flowchart TD
  User[User]
  Web[VS Code Devcontainer]
  CLI[Scripts/CLI]
  Pipeline[Azure DevOps Pipeline]
  TF[Terraform]
  AKV[Azure Key Vault]
  Storage[Storage Account]
  Azure[Azure Resources]

  User --> Web
  User --> CLI
  Web --> TF
  CLI --> TF
  TF --> AKV
  TF --> Storage
  TF --> Azure
  Pipeline --> TF
  Pipeline --> AKV
  Pipeline --> Storage
  Pipeline --> Azure
```