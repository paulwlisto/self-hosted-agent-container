# Self-Hosted Agent Container

An Azure DevOps self-hosted agent container image pre-loaded with common DevOps tools. Publishes to Azure Container Registry (ACR) on tag push.

## Included Tools

- Azure CLI (`az`) + Bicep
- .NET SDK 8.0
- Terraform
- Packer
- Helm
- kubectl
- Docker CLI
- ORAS CLI
- tfsec, trivy, checkov
- Node.js + npm
- Git, curl, wget, jq, unzip

## Usage

### Prerequisites

Create a service principal with the **Agent Pool Administrator** role scoped to your Azure DevOps organization (or specific pool). The service principal also needs to be registered as a user in your Azure DevOps organization.

### Run the container

```bash
docker run -d \
  -e AZP_URL=https://dev.azure.com/your-org \
  -e AZP_CLIENT_ID=<service-principal-app-id> \
  -e AZP_CLIENT_SECRET=<service-principal-secret> \
  -e AZP_TENANT_ID=<entra-tenant-id> \
  -e AZP_POOL=Default \
  -e AZP_AGENT_NAME=my-agent \
  your-acr.azurecr.io/self-hosted-agent:latest
```

### Environment Variables

| Variable           | Required | Description                                                  |
| ------------------ | -------- | ------------------------------------------------------------ |
| `AZP_URL`          | Yes      | Azure DevOps organization URL (e.g. `https://dev.azure.com/your-org`) |
| `AZP_CLIENT_ID`    | Yes      | Service principal application (client) ID                    |
| `AZP_CLIENT_SECRET` | Yes     | Service principal client secret                              |
| `AZP_TENANT_ID`    | Yes      | Microsoft Entra ID (Azure AD) tenant ID                      |
| `AZP_POOL`         | No       | Agent pool name (defaults to `Default`)                      |
| `AZP_AGENT_NAME`   | No       | Agent name (defaults to container hostname)                  |

### Service Principal Setup

1. Create an App Registration in Microsoft Entra ID
2. Create a client secret under **Certificates & secrets**
3. In Azure DevOps, add the service principal as a user (`<app-id>@<tenant-id>`) with access to the target agent pool
4. Grant the service principal **Agent Pool Administrator** on the pool

## Building Locally

```bash
docker build -t self-hosted-agent -f linux/Dockerfile .
```

To pin a specific agent version:

```bash
docker build --build-arg AGENT_VERSION=4.248.0 -t self-hosted-agent -f linux/Dockerfile .
```

## Publishing

The image is automatically built and pushed to ACR when a version tag (e.g. `v1.0.0`) is pushed. The Azure Pipelines pipeline requires two variables:

| Pipeline Variable          | Description                                      |
| -------------------------- | ------------------------------------------------ |
| `ACR_NAME`                 | Name of your Azure Container Registry            |
| `AZURE_SERVICE_CONNECTION` | Name of the Azure service connection in the project |
