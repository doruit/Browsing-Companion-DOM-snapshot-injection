#!/bin/bash

# Browsing Companion - Environment Setup Script
# This script extracts deployment outputs and creates .env files for local development

set -e

echo "🔧 Setting up local development environment..."

# Check if deployment outputs exist
if [ ! -f "./deployment-outputs.json" ]; then
    echo "❌ deployment-outputs.json not found!"
    echo "   Please run ./scripts/deploy.sh first to deploy Azure resources."
    exit 1
fi

# Parse deployment outputs
RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' deployment-outputs.json)
KEY_VAULT_NAME=$(jq -r '.keyVaultName.value' deployment-outputs.json)
COSMOS_ENDPOINT=$(jq -r '.cosmosEndpoint.value' deployment-outputs.json)
COSMOS_ACCOUNT=$(jq -r '.cosmosAccountName.value' deployment-outputs.json)
OPENAI_ENDPOINT=$(jq -r '.openaiEndpoint.value' deployment-outputs.json)
OPENAI_DEPLOYMENT=$(jq -r '.openaiDeploymentName.value' deployment-outputs.json)
STORAGE_ACCOUNT=$(jq -r '.storageAccountName.value' deployment-outputs.json)
APP_INSIGHTS_CONNECTION=$(jq -r '.appInsightsConnectionString.value' deployment-outputs.json)

echo "✅ Parsed deployment outputs"

# Get secrets from Key Vault
echo "🔐 Retrieving secrets from Key Vault..."
COSMOS_CONNECTION_STRING=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "cosmos-connection-string" --query value -o tsv)
OPENAI_API_KEY=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "openai-api-key" --query value -o tsv)
STORAGE_CONNECTION_STRING=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "storage-connection-string" --query value -o tsv)

echo "✅ Retrieved secrets from Key Vault"

# Create Python AI Service .env file
echo ""
echo "📝 Creating .env file for Python AI Service..."
cat > ./services/ai-service/.env.local <<EOF
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_API_KEY
AZURE_OPENAI_DEPLOYMENT_NAME=$OPENAI_DEPLOYMENT

# Cosmos DB Configuration
COSMOS_ENDPOINT=$COSMOS_ENDPOINT
COSMOS_CONNECTION_STRING=$COSMOS_CONNECTION_STRING
COSMOS_DATABASE_NAME=browsing-companion-db

# Azure Storage Configuration
AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_CONNECTION

# Service Configuration
SERVICE_PORT=8000
ENVIRONMENT=development
EOF

echo "✅ Created ./services/ai-service/.env.local"

# Create Node.js API Gateway .env file
echo ""
echo "📝 Creating .env file for Node.js API Gateway..."
cat > ./services/api-gateway/.env.local <<EOF
# Service Configuration
PORT=3001
NODE_ENV=development

# Python AI Service
AI_SERVICE_URL=http://localhost:8000

# JWT Secret (for demo purposes only - use secure secret in production)
JWT_SECRET=demo-secret-key-change-in-production

# CORS Configuration
CORS_ORIGIN=http://localhost:3000

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=$APP_INSIGHTS_CONNECTION
EOF

echo "✅ Created ./services/api-gateway/.env.local"

# Create React Frontend .env file
echo ""
echo "📝 Creating .env file for React Frontend..."
cat > ./frontend/.env.local <<EOF
# API Gateway URL
VITE_API_URL=http://localhost:3001

# Environment
VITE_ENV=development
EOF

echo "✅ Created ./frontend/.env.local"

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "📋 Summary:"
echo "   ✓ Python AI Service: ./services/ai-service/.env.local"
echo "   ✓ Node.js API Gateway: ./services/api-gateway/.env.local"
echo "   ✓ React Frontend: ./frontend/.env.local"
echo ""
echo "🚀 Next steps:"
echo "   1. Install dependencies for each service (see README.md)"
echo "   2. Start the services in separate terminals:"
echo "      - Python AI Service: cd services/ai-service && python -m uvicorn main:app --reload --port 8000"
echo "      - Node.js Gateway: cd services/api-gateway && npm run dev"
echo "      - React Frontend: cd frontend && npm run dev"
echo ""
