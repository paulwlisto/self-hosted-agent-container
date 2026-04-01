#!/bin/bash
set -euo pipefail

AZP_URL="${AZP_URL:?Environment variable AZP_URL is required (e.g. https://dev.azure.com/your-org)}"
AZP_CLIENT_ID="${AZP_CLIENT_ID:?Environment variable AZP_CLIENT_ID is required}"
AZP_CLIENT_SECRET="${AZP_CLIENT_SECRET:?Environment variable AZP_CLIENT_SECRET is required}"
AZP_TENANT_ID="${AZP_TENANT_ID:?Environment variable AZP_TENANT_ID is required}"
AZP_POOL="${AZP_POOL:-Default}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-$(hostname)}"

# Log in to Azure CLI with the service principal (available to pipeline tasks)
az login --service-principal \
  --username "${AZP_CLIENT_ID}" \
  --password "${AZP_CLIENT_SECRET}" \
  --tenant "${AZP_TENANT_ID}" \
  --output none

# Configure the agent with service principal auth
./config.sh \
  --unattended \
  --url "${AZP_URL}" \
  --auth sp \
  --clientid "${AZP_CLIENT_ID}" \
  --clientsecret "${AZP_CLIENT_SECRET}" \
  --tenantid "${AZP_TENANT_ID}" \
  --pool "${AZP_POOL}" \
  --agent "${AZP_AGENT_NAME}" \
  --replace \
  --acceptTeeEula

# Cleanup function to deregister the agent on exit
cleanup() {
  echo "Removing agent..."
  ./config.sh remove \
    --auth sp \
    --clientid "${AZP_CLIENT_ID}" \
    --clientsecret "${AZP_CLIENT_SECRET}" \
    --tenantid "${AZP_TENANT_ID}"
}
trap cleanup SIGTERM SIGINT EXIT

# Start the agent
./run.sh &
wait $!
