#!/bin/bash

# Browsing Companion - Azure Infrastructure Deployment Script
# This script deploys all Azure resources needed for the demo

set -e

echo "🚀 Starting Browsing Companion Azure deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
echo "📋 Checking Azure CLI login status..."
az account show &> /dev/null || {
    echo "❌ Not logged in to Azure. Please run: az login --use-device-code"
    exit 1
}

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "✅ Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Get current user's object ID for Key Vault access
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
echo "✅ Your Object ID: $PRINCIPAL_ID"

# Set deployment parameters
ENVIRONMENT="${ENVIRONMENT:-dev}"
LOCATION="${LOCATION:-eastus}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEPLOYMENT_NAME="browsing-companion-${ENVIRONMENT}-${TIMESTAMP}"

echo ""
echo "📦 Deployment Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   Location: $LOCATION"
echo "   Deployment Name: $DEPLOYMENT_NAME"
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Deploy infrastructure
echo ""
echo "🏗️  Deploying infrastructure (this may take 10-15 minutes)..."
az deployment sub create \
  --location "$LOCATION" \
  --template-file ./infra/main.bicep \
  --parameters ./infra/parameters/dev.bicepparam \
  --parameters principalId="$PRINCIPAL_ID" \
  --name "$DEPLOYMENT_NAME" \
  --output table

# Get deployment outputs
echo ""
echo "📤 Retrieving deployment outputs..."
OUTPUTS=$(az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs \
  -o json)

# Save outputs to file
echo "$OUTPUTS" > ./deployment-outputs.json
echo "✅ Deployment outputs saved to: deployment-outputs.json"

# Display summary
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Resource Summary:"
echo "   Resource Group: $(echo $OUTPUTS | jq -r '.resourceGroupName.value')"
echo "   Key Vault: $(echo $OUTPUTS | jq -r '.keyVaultName.value')"
echo "   Cosmos DB: $(echo $OUTPUTS | jq -r '.cosmosAccountName.value')"
echo "   OpenAI Endpoint: $(echo $OUTPUTS | jq -r '.openaiEndpoint.value')"
echo "   AI Hub: $(echo $OUTPUTS | jq -r '.aiHubName.value')"
echo "   AI Project: $(echo $OUTPUTS | jq -r '.aiProjectName.value')"
echo ""
echo "🔑 Next steps:"
echo "   1. Run: ./scripts/setup-env.sh to configure local environment"
echo "   2. Start the services (see README.md for instructions)"
echo ""
