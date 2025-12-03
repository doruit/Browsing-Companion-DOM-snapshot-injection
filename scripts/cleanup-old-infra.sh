#!/bin/bash

# Browsing Companion - Cleanup Old Infrastructure Script
# This script deletes unused Azure resources from the previous architecture
# (standalone Azure OpenAI accounts and old-style AI Foundry Hub/Project)

set -e

echo "🧹 Cleaning up old Azure infrastructure..."
echo ""
echo "⚠️  WARNING: This script will DELETE resources. Make sure you have backups!"
echo ""

# Check for required tools
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI (az) is required but not installed."
    echo "   Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get subscription info
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "📋 Current Azure subscription:"
echo "   Name: $SUBSCRIPTION_NAME"
echo "   ID: $SUBSCRIPTION_ID"
echo ""

# Define resource names to delete (based on the old architecture)
# These should be adjusted based on your actual resource names

# Parse deployment outputs if available
RESOURCE_GROUP=""
if [ -f "./deployment-outputs.json" ]; then
    RESOURCE_GROUP=$(jq -r '.resourceGroupName.value // empty' deployment-outputs.json 2>/dev/null || echo "")
fi

if [ -z "$RESOURCE_GROUP" ]; then
    echo "📝 Enter the resource group name containing old resources:"
    read -r RESOURCE_GROUP
fi

echo ""
echo "🔍 Checking for old resources in resource group: $RESOURCE_GROUP"
echo ""

# List resources that might need cleanup
echo "📦 Resources that may need cleanup:"
echo "   1. Standalone Azure OpenAI accounts (kind: OpenAI)"
echo "   2. Old-style AI Foundry Hub (MachineLearningServices/workspaces with kind: Hub)"
echo "   3. Old-style AI Foundry Project (MachineLearningServices/workspaces with kind: Project)"
echo ""

# Function to safely delete a resource
delete_resource() {
    local resource_id=$1
    local resource_name=$2
    local resource_type=$3
    
    echo ""
    echo "❓ Delete $resource_type: $resource_name?"
    echo "   Resource ID: $resource_id"
    read -p "   Type 'yes' to confirm deletion: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "   🗑️  Deleting $resource_name..."
        if az resource delete --ids "$resource_id" --verbose 2>&1; then
            echo "   ✅ Deleted $resource_name"
        else
            echo "   ⚠️  Failed to delete $resource_name - may need manual cleanup"
        fi
    else
        echo "   ⏭️  Skipped $resource_name"
    fi
}

# Find and delete standalone Azure OpenAI accounts
echo ""
echo "🔍 Searching for standalone Azure OpenAI accounts..."
OPENAI_ACCOUNTS=$(az cognitiveservices account list --resource-group "$RESOURCE_GROUP" --query "[?kind=='OpenAI']" -o json 2>/dev/null || echo "[]")

if [ "$OPENAI_ACCOUNTS" != "[]" ] && [ -n "$OPENAI_ACCOUNTS" ]; then
    echo "   Found standalone OpenAI accounts:"
    echo "$OPENAI_ACCOUNTS" | jq -r '.[] | "   - \(.name)"'
    
    echo "$OPENAI_ACCOUNTS" | jq -c '.[]' | while read -r account; do
        name=$(echo "$account" | jq -r '.name')
        id=$(echo "$account" | jq -r '.id')
        delete_resource "$id" "$name" "Azure OpenAI Account"
    done
else
    echo "   ✅ No standalone Azure OpenAI accounts found"
fi

# Find and delete old-style AI Foundry Hub workspaces
echo ""
echo "🔍 Searching for old-style AI Foundry Hub workspaces..."
HUB_WORKSPACES=$(az ml workspace list --resource-group "$RESOURCE_GROUP" --query "[?kind=='Hub']" -o json 2>/dev/null || echo "[]")

if [ "$HUB_WORKSPACES" != "[]" ] && [ -n "$HUB_WORKSPACES" ]; then
    echo "   Found AI Foundry Hub workspaces:"
    echo "$HUB_WORKSPACES" | jq -r '.[] | "   - \(.name)"'
    
    echo "$HUB_WORKSPACES" | jq -c '.[]' | while read -r workspace; do
        name=$(echo "$workspace" | jq -r '.name')
        # Get the full resource ID
        id=$(az ml workspace show --name "$name" --resource-group "$RESOURCE_GROUP" --query id -o tsv 2>/dev/null || echo "")
        if [ -n "$id" ]; then
            delete_resource "$id" "$name" "AI Foundry Hub"
        fi
    done
else
    echo "   ✅ No old-style AI Foundry Hub workspaces found"
fi

# Find and delete old-style AI Foundry Project workspaces
echo ""
echo "🔍 Searching for old-style AI Foundry Project workspaces..."
PROJECT_WORKSPACES=$(az ml workspace list --resource-group "$RESOURCE_GROUP" --query "[?kind=='Project']" -o json 2>/dev/null || echo "[]")

if [ "$PROJECT_WORKSPACES" != "[]" ] && [ -n "$PROJECT_WORKSPACES" ]; then
    echo "   Found AI Foundry Project workspaces:"
    echo "$PROJECT_WORKSPACES" | jq -r '.[] | "   - \(.name)"'
    
    echo "$PROJECT_WORKSPACES" | jq -c '.[]' | while read -r workspace; do
        name=$(echo "$workspace" | jq -r '.name')
        # Get the full resource ID
        id=$(az ml workspace show --name "$name" --resource-group "$RESOURCE_GROUP" --query id -o tsv 2>/dev/null || echo "")
        if [ -n "$id" ]; then
            delete_resource "$id" "$name" "AI Foundry Project"
        fi
    done
else
    echo "   ✅ No old-style AI Foundry Project workspaces found"
fi

echo ""
echo "🏁 Cleanup process completed!"
echo ""
echo "📋 Summary of new architecture:"
echo "   ✅ Using Microsoft Foundry (CognitiveServices/accounts with allowProjectManagement)"
echo "   ✅ Model deployments at Foundry account level"
echo "   ✅ Project as child resource of Foundry account"
echo "   ✅ Managed identity authentication (no API keys)"
echo "   ✅ Microsoft Agent Framework SDK for AI agent"
echo ""
echo "🔧 To deploy the new infrastructure, run:"
echo "   ./scripts/deploy.sh"
echo ""
