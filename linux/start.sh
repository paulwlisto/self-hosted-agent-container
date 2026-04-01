#!/bin/bash
set -euo pipefail

AZP_URL="${AZP_URL:?Environment variable AZP_URL is required (e.g. https://dev.azure.com/your-org)}"
AZP_CLIENT_ID="${AZP_CLIENT_ID:?Environment variable AZP_CLIENT_ID is required}"
AZP_CLIENT_SECRET="${AZP_CLIENT_SECRET:?Environment variable AZP_CLIENT_SECRET is required}"
AZP_TENANT_ID="${AZP_TENANT_ID:?Environment variable AZP_TENANT_ID is required}"
AZP_POOL="${AZP_POOL:-Default}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-$(hostname)}"

# Log in to Azure CLI with the service principal (available to pipeline tasks)
echo "Logging in to Azure CLI..."
az login --service-principal \
  --username "${AZP_CLIENT_ID}" \
  --password "${AZP_CLIENT_SECRET}" \
  --tenant "${AZP_TENANT_ID}" \
  --output none

# Only configure if not already configured (survives container restarts with persistent storage)
if [ ! -f .agent ]; then
  echo "Configuring agent..."
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
else
  echo "Agent already configured, skipping config."
fi

# Cleanup function to deregister the agent on exit
cleanup() {
  if [ -f .agent ]; then
    echo "Removing agent..."
    ./config.sh remove \
      --auth sp \
      --clientid "${AZP_CLIENT_ID}" \
      --clientsecret "${AZP_CLIENT_SECRET}" \
      --tenantid "${AZP_TENANT_ID}" || true
  fi
}
trap cleanup SIGTERM SIGINT

# Start the agent (foreground — keeps the container alive)
echo "Starting agent..."
exec ./run.sh
