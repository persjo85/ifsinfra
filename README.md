# Azure regional platform with Bicep

This repository deploys a regional Azure application platform with Bicep.

## Layout

- `infra/regional/` deploys one independent regional platform. Each region has
  layered parameter files per module under `parameters/regionN/`.
- `infra/global/` deploys shared global edge resources once: Azure Front Door
  Premium and WAF.

The global deployment creates the one management VNet and jumpserver. It also
peers that VNet with every regional VNet and creates a MySQL private-DNS link
for each region. A regional deployment produces a `frontDoorOrigin` object;
add it to the global Front Door parameter layer when onboarding a region.

Deploy global services first with an empty `regions` list. Copy its
`managementVnetId` and jumpserver private IP to the regional parameter file.
To add a region, deploy `infra/regional/parameters/regionN/regionN.bicepparam`,
then copy its `frontDoorOrigin` output into the `regions` array in
`infra/global/parameters/front-door.bicepparam`. Run a global `what-if` before
deploying the changed Front Door configuration. The WAF policy is global and
continues to protect every origin behind the endpoint.

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
  --parameters infra/regional/parameters/region1/region1.bicepparam \
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
