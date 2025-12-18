#!/bin/bash

# Start-Local.sh - Run Browsing Companion Locally

echo "Starting Browsing Companion locally..."

# Check dependencies
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed (required for frontend and gateway)."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed (required for AI service)."
    exit 1
fi

# Load existing environment if available
if [ -f .env.local ]; then
    echo "Loading cached credentials from .env.local..."
    source .env.local
fi

# --- credential-fetch-logic ---
if [ -z "$COSMOS_CONNECTION_STRING" ] || [ -z "$AI_FOUNDRY_PROJECT_ENDPOINT" ] || [ -z "$AZURE_STORAGE_CONNECTION_STRING" ]; then
    echo "Service credentials missing. Attempting to fetch from Azure..."
    
    RG_NAME="rg-brow-comp-dev"
    
    # 1. Fetch AI Foundry Project Endpoint (Fully Automated Construction)
    if [ -z "$AI_FOUNDRY_PROJECT_ENDPOINT" ]; then
        echo "Fetching AI Foundry Details..."
        
        # Get Account Name
        FOUNDRY_NAME=$(az cognitiveservices account list --resource-group $RG_NAME --query "[?kind=='AIServices' || kind=='CognitiveServices'].name | [0]" -o tsv 2>/dev/null)
        
        # Get Project Name
        PROJECT_NAME=$(az resource list --resource-group $RG_NAME --resource-type "Microsoft.CognitiveServices/accounts/projects" --query "[0].name" -o tsv 2>/dev/null)
        
        if [ ! -z "$FOUNDRY_NAME" ] && [ ! -z "$PROJECT_NAME" ]; then
            # Clean name logic
            PROJECT_NAME_CLEAN=$(echo $PROJECT_NAME | awk -F/ '{print $NF}')
            
            echo "Found Account: $FOUNDRY_NAME, Project: $PROJECT_NAME_CLEAN"
            
            # Construct the endpoint URL 
            # Format: https://<account>.services.ai.azure.com/api/projects/<project>
            CONSTRUCTED_ENDPOINT="https://${FOUNDRY_NAME}.services.ai.azure.com/api/projects/${PROJECT_NAME_CLEAN}"
            export AI_FOUNDRY_PROJECT_ENDPOINT=$CONSTRUCTED_ENDPOINT
        else
            echo "Warning: Could not find AI Foundry Account or Project."
        fi
    fi
    
    # 2. Fetch Cosmos Connection String (Smart Discovery)
    if [ -z "$COSMOS_CONNECTION_STRING" ]; then
        echo "Fetching Cosmos DB Connection String..."
        COSMOS_ACCOUNTS=$(az cosmosdb list --resource-group $RG_NAME --query "[].name" -o tsv 2>/dev/null)
        
        FOUND_COSMOS=""
        for account in $COSMOS_ACCOUNTS; do
            echo "Checking account: $account..."
            HAS_DB=$(az cosmosdb sql database show --account-name $account --resource-group $RG_NAME --name "browsing-companion-db" --query "id" -o tsv 2>/dev/null)
            if [ ! -z "$HAS_DB" ]; then
                echo "Found valid database in: $account"
                FOUND_COSMOS=$account
                break
            fi
        done
        
        if [ ! -z "$FOUND_COSMOS" ]; then
            CONN_STR=$(az cosmosdb keys list --name $FOUND_COSMOS --resource-group $RG_NAME --type connection-strings --query "connectionStrings[0].connectionString" -o tsv 2>/dev/null)
            if [ ! -z "$CONN_STR" ]; then
                export COSMOS_CONNECTION_STRING=$CONN_STR
                export COSMOS_ENDPOINT=$(az cosmosdb show --name $FOUND_COSMOS --resource-group $RG_NAME --query "documentEndpoint" -o tsv 2>/dev/null)
            fi
        else
            # Fallback
            FIRST_ACC=$(echo $COSMOS_ACCOUNTS | awk '{print $1}')
             if [ ! -z "$FIRST_ACC" ]; then
                echo "Falling back to $FIRST_ACC"
                export COSMOS_CONNECTION_STRING=$(az cosmosdb keys list --name $FIRST_ACC --resource-group $RG_NAME --type connection-strings --query "connectionStrings[0].connectionString" -o tsv)
             fi
        fi
    fi

    # 3. Fetch Storage Connection String
    if [ -z "$AZURE_STORAGE_CONNECTION_STRING" ]; then
        echo "Fetching Storage Connection String..."
        STORAGE_NAME=$(az storage account list --resource-group $RG_NAME --query "[0].name" -o tsv 2>/dev/null)
        if [ ! -z "$STORAGE_NAME" ]; then
             STR=$(az storage account show-connection-string --name $STORAGE_NAME --resource-group $RG_NAME --query connectionString -o tsv 2>/dev/null)
             if [ ! -z "$STR" ]; then
                export AZURE_STORAGE_CONNECTION_STRING=$STR
             fi
        fi
    fi
fi

# Interactive Prompt ONLY if automation failed
if [ -z "$COSMOS_CONNECTION_STRING" ] || [ -z "$AI_FOUNDRY_PROJECT_ENDPOINT" ]; then
    echo ""
    echo "----------------------------------------------------------------"
    echo "Missing Credentials! Automation Failed."
    echo "----------------------------------------------------------------"
    
    if [ -z "$AI_FOUNDRY_PROJECT_ENDPOINT" ]; then
        read -p "Enter AI Foundry Project Endpoint: " AI_FOUNDRY_PROJECT_ENDPOINT
        export AI_FOUNDRY_PROJECT_ENDPOINT
    fi
    
    if [ -z "$COSMOS_CONNECTION_STRING" ]; then
        read -s -p "Enter Cosmos DB Connection String: " COSMOS_CONNECTION_STRING
        echo ""
        export COSMOS_CONNECTION_STRING
    fi

    if [ -z "$AZURE_STORAGE_CONNECTION_STRING" ]; then
        read -s -p "Enter Azure Storage Connection String: " AZURE_STORAGE_CONNECTION_STRING
        echo ""
        export AZURE_STORAGE_CONNECTION_STRING
    fi
fi

# --- Save credentials to .env.local (Always) ---
echo "Saving credentials to .env.local..."
echo "export AI_FOUNDRY_PROJECT_ENDPOINT=\"$AI_FOUNDRY_PROJECT_ENDPOINT\"" > .env.local
echo "export COSMOS_CONNECTION_STRING=\"$COSMOS_CONNECTION_STRING\"" >> .env.local
if [ -z "$COSMOS_ENDPOINT" ]; then
    COSMOS_ENDPOINT=$(echo $COSMOS_CONNECTION_STRING | grep -o 'AccountEndpoint=[^;]*' | cut -d= -f2)
fi
echo "export COSMOS_ENDPOINT=\"$COSMOS_ENDPOINT\"" >> .env.local
echo "export AZURE_STORAGE_CONNECTION_STRING=\"$AZURE_STORAGE_CONNECTION_STRING\"" >> .env.local
if [ ! -z "$AZURE_OPENAI_API_KEY" ]; then
    echo "export AZURE_OPENAI_API_KEY=\"$AZURE_OPENAI_API_KEY\"" >> .env.local
    echo "export AZURE_OPENAI_ENDPOINT=\"$AZURE_OPENAI_ENDPOINT\"" >> .env.local
fi
cp .env.local services/ai-service/.env.local
echo "Copied .env.local to services/ai-service/.env.local"
# --- end-credential-fetch-logic ---

# Export Variables for Python
export AI_FOUNDRY_PROJECT_ENDPOINT
export COSMOS_CONNECTION_STRING
export COSMOS_ENDPOINT
export AZURE_STORAGE_CONNECTION_STRING

# Trap to kill all background processes on exit
trap 'kill 0' SIGINT

# 1. Start AI Service
echo ""
echo "[1/3] Starting AI Service (Port 8000)..."
cd services/ai-service || exit
if [ ! -d "venv" ]; then
    echo "Creating Python venv..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi
pip install uvicorn
python -m uvicorn main:app --host 0.0.0.0 --port 8000 &
cd ../..

# 2. Start Gateway
echo "[2/3] Starting API Gateway (Port 3001)..."
cd services/api-gateway || exit
if [ ! -d "node_modules" ]; then
    npm install
fi
export PORT=3001
export AI_SERVICE_URL="http://localhost:8000"
export CORS_ORIGIN="http://localhost:3000" 
npm run dev &
cd ../..

# 3. Start Frontend
echo "[3/3] Starting Frontend (Port 3000)..."
cd frontend || exit
if [ ! -d "node_modules" ]; then
    npm install
fi
export VITE_API_URL="http://localhost:3001"
# Small delay to let backend start
sleep 5
npm run dev

# Wait for all background jobs
wait
