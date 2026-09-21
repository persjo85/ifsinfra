# Azure regional platform with Bicep

This repository deploys a regional Azure application platform with Bicep.

## Layout

- `infra/regional/` deploys one independent regional platform. Select the
  appropriate file in `parameters/` for each region.
- `infra/global/` deploys shared global edge resources once: Azure Front Door
  Premium and WAF.

The regional deployment produces a Private Link Service ID. Add that ID, its
Private Link location, and its origin hostname to the global parameter file
when onboarding a region to Front Door.

## Before deployment

Install Azure CLI and Bicep, then authenticate with an identity that can create
resource groups, resources, provider registrations, and required RBAC role
assignments.

```bash
az bicep install
az login
az account set --subscription FILL_IN_SUBSCRIPTION_GUID
```

Copy the appropriate regional parameter file to a local, untracked file and
replace every `FILL_IN` value. Provide the MySQL administrator password as a
secure deployment parameter; never commit it, a private key, or a generated
parameter file containing secrets.

## Validate and deploy a region

```bash
az bicep build --file infra/regional/main.bicep
az deployment sub what-if \
  --location swedencentral \
  --template-file infra/regional/main.bicep \
  --parameters infra/regional/parameters/region1.bicepparam \
  mysqlAdministratorPassword='REDACTED'
```

Run `az deployment sub create` only after reviewing the what-if result.

## Deploy global edge resources

Deploy `infra/global/main.bicep` once, after the first regional Private Link
Service is ready and explicitly approved. Use `what-if` first. Do not deploy
Front Door from a regional parameter file; that would duplicate global
resources.

The Bicep conversion is still being completed. Do not deploy until the module
warnings have been resolved and a reviewed `what-if` has confirmed the intended
resource graph.
