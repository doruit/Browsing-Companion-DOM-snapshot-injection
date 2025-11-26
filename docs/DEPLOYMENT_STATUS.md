# 🚀 Deployment Status - Browsing Companion Demo

**Status**: ✅ Azure Infrastructure Deployed | 🔄 Local Services Ready to Start  
**Date**: 2025-11-26  
**Environment**: Development (eastus)  
**Deployment**: browsing-companion-dev-20251126-113202

---

## ✅ Completed Steps

### 1. Azure Infrastructure Deployment
**Status**: ✅ Successfully Deployed (22 resources)  
**Deployment Time**: ~15 minutes  
**Resource Group**: `rg-browsing-companion-dev`

#### Deployed Resources:

| Resource | Name | API Version | Status |
|----------|------|-------------|--------|
| **Azure OpenAI** | openai-browsing-companion-dev | @2024-10-01 | ✅ |
| - Model | gpt-4o-mini (2024-07-18) | | ✅ |
| - Deployment | gpt-4o-mini | | ✅ |
| - SKU | GlobalStandard (capacity 10) | | ✅ |
| **Microsoft Foundry** | foundry-browsing-companion-dev | @2024-10-01 | ✅ |
| - Hub | kind: Hub | | ✅ |
| - Project | aiproject-browsing-companion-dev | | ✅ |
| - Connection | aoai-connection (AAD auth) | | ✅ |
| **Cosmos DB** | cosmos-browsing-companion-dev | @2024-05-15 | ✅ |
| - Database | browsing-companion-db | | ✅ |
| - Container | chat-sessions (TTL 30 days) | | ✅ |
| - Container | preferences | | ✅ |
| - Container | users | | ✅ |
| **Storage Account** | stbrowsingcompaniondev | @2025-06-01 | ✅ |
| - Container | dom-snapshots | | ✅ |
| **Key Vault** | kv-browse-comp-dev | @2025-05-01 | ✅ |
| - Secrets | 4 secrets stored | | ✅ |
| **App Insights** | ai-browsing-companion-dev | | ✅ |
| **Log Analytics** | ai-browsing-companion-dev-workspace | @2025-07-01 | ✅ |

#### Endpoints:
```bash
OpenAI Endpoint:  https://openai-browsing-companion-dev.openai.azure.com/
Cosmos Endpoint:  https://cosmos-browsing-companion-dev.documents.azure.com:443/
Key Vault:        https://kv-browse-comp-dev.vault.azure.net/
```

#### Stored Secrets (in Key Vault):
- ✅ `cosmos-connection-string`
- ✅ `openai-api-key`
- ✅ `openai-endpoint`
- ✅ `storage-connection-string`

### 2. Environment Configuration
**Status**: ✅ Complete

Created `.env.local` files for all services:
- ✅ `services/ai-service/.env.local` - Azure credentials
- ✅ `services/api-gateway/.env.local` - Service URLs & CORS
- ✅ `frontend/.env.local` - API Gateway URL

All secrets retrieved from Key Vault using Azure CLI authentication.

### 3. Python Environment Setup
**Status**: ✅ Complete

- ✅ Virtual environment activated: `.venv/`
- ✅ Python version: 3.13.5
- ✅ Dependencies installed: 51 packages

**Key Packages:**
```
fastapi==0.115.0
uvicorn[standard]==0.32.0
azure-cosmos==4.8.0
openai==1.54.3
azure-identity==1.19.0
azure-storage-blob==12.23.1
azure-ai-inference==1.0.0b5
pydantic==2.9.2
httpx==0.27.2
```

### 4. Node.js Environment
**Status**: ✅ Ready

- ✅ Node.js version: v23.6.1
- ✅ npm version: 10.9.2
- ⏳ Dependencies not yet installed (pending)

---

## 🎯 Next Steps - Start Local Services

You now need to start three services in separate terminals. Follow these steps:

### Step 1: Start Python AI Service (Terminal 1)

```bash
cd services/ai-service
python -m uvicorn main:app --reload --port 8000
```

**Expected Output:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Verify:** Open http://localhost:8000/docs to see FastAPI Swagger UI

**Endpoints Available:**
- `POST /process-chat` - Chat with GPT-4o-mini (with DOM context)
- `GET /preferences/{user_id}` - Get user preferences
- `PUT /preferences/{user_id}` - Update preferences

---

### Step 2: Install & Start API Gateway (Terminal 2)

```bash
cd services/api-gateway
npm install
npm run dev
```

**Expected Output:**
```
> api-gateway@1.0.0 dev
> nodemon src/index.js

[nodemon] starting `node src/index.js`
API Gateway running on http://localhost:3001
```

**Verify:** 
```bash
curl http://localhost:3001/health
# Expected: {"status":"ok","timestamp":"..."}
```

**Routes Available:**
- `POST /api/auth/login` - User authentication
- `POST /api/chat` - Proxies to AI service
- `GET /api/preferences/:userId` - User preferences
- `GET /api/products` - Product catalog

---

### Step 3: Install & Start Frontend (Terminal 3)

```bash
cd frontend
npm install
npm run dev
```

**Expected Output:**
```
VITE v5.x.x  ready in xxx ms

➜  Local:   http://localhost:3000/
➜  Network: use --host to expose
```

**Open Browser:** Navigate to http://localhost:3000

---

## 🎮 Testing the Application

### 1. Login
Use demo credentials:
- **User 1**: `user1@example.com` / `password` (B2C, likes Running shoes)
- **User 2**: `user2@example.com` / `password` (B2B, bulk orders)

### 2. Browse Products
Scroll through the shoe catalog to see different products.

### 3. Set Preferences
- Toggle B2B/B2C mode
- Select/deselect shoe categories (Running, Casual, Formal, Sports)

### 4. Chat with AI
Click the chat widget (bottom right) and try:

**Context-Aware Questions:**
```
"What products can you see on my screen?"
"Which shoes have discounts right now?"
"What's the most expensive shoe visible?"
"Recommend running shoes under $100"
"Show me all Nike products you can see"
```

**Preference-Based Questions:**
```
"Based on my preferences, what should I buy?"
"I need shoes for running, what do you recommend?"
"What's good for bulk orders?" (as B2B user)
```

### 5. Verify DOM Snapshot Capture
Open browser DevTools → Network tab:
- Look for requests to `/api/chat`
- Check request payload - should include `domSnapshot` field with visible products
- Response should reference specific products from the snapshot

---

## 🔍 Validation & Monitoring

### Check Azure Resources
```bash
# List all resources
az resource list --resource-group rg-browsing-companion-dev --output table

# Check OpenAI deployment
az cognitiveservices account deployment show \
  --name openai-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev \
  --deployment-name gpt-4o-mini

# Query Cosmos DB
az cosmosdb sql database show \
  --account-name cosmos-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev \
  --name browsing-companion-db
```

### Monitor Application Insights
```bash
# Get instrumentation key
az monitor app-insights component show \
  --app ai-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev \
  --query instrumentationKey -o tsv
```

Visit Azure Portal → Application Insights → Live Metrics to see real-time telemetry.

### Verify Key Vault Secrets
```bash
# List secrets
az keyvault secret list --vault-name kv-browse-comp-dev --output table

# Get a secret (for debugging)
az keyvault secret show --vault-name kv-browse-comp-dev --name openai-api-key --query value -o tsv
```

---

## 📊 Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  React Frontend │────▶│  Node.js Gateway│────▶│  Python AI Svc  │
│   localhost:3000│     │   localhost:3001│     │  localhost:8000 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                                                │
        │  DOM Snapshot                                  │
        │  Capture + Send                                ├──▶ Azure OpenAI
        └────────────────────────────────────────────────┤      (GPT-4o-mini)
                                                         │
                                                         ├──▶ Cosmos DB
                                                         │    (chat history)
                                                         │
                                                         └──▶ Blob Storage
                                                              (snapshots)
```

**Flow:**
1. User interacts with React frontend
2. Frontend captures DOM snapshot of visible products
3. Chat message + snapshot sent to Node.js gateway
4. Gateway authenticates and forwards to Python AI service
5. AI service processes with GPT-4o-mini (DOM context included in prompt)
6. Response returned through gateway to frontend
7. Chat history saved to Cosmos DB
8. DOM snapshots optionally stored in Blob Storage

---

## 🐛 Troubleshooting

### AI Service Won't Start
```bash
# Ensure virtual environment is activated
source .venv/bin/activate

# Reinstall dependencies
pip install -r services/ai-service/requirements.txt

# Check .env.local exists
cat services/ai-service/.env.local
```

### API Gateway Connection Error
```bash
# Verify AI service is running
curl http://localhost:8000/docs

# Check .env.local
cat services/api-gateway/.env.local | grep AI_SERVICE_URL
# Should be: AI_SERVICE_URL=http://localhost:8000
```

### Frontend Can't Reach API
```bash
# Verify API gateway is running
curl http://localhost:3001/health

# Check frontend .env.local
cat frontend/.env.local
# Should be: VITE_API_URL=http://localhost:3001
```

### Azure OpenAI Errors
```bash
# Test OpenAI endpoint directly
az cognitiveservices account keys list \
  --name openai-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev

# Check deployment status
az cognitiveservices account deployment show \
  --name openai-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev \
  --deployment-name gpt-4o-mini \
  --query '{name:name, model:properties.model.name, version:properties.model.version, provisioningState:properties.provisioningState}'
```

### Cosmos DB Connection Issues
```bash
# Verify connection string in Key Vault
az keyvault secret show \
  --vault-name kv-browse-comp-dev \
  --name cosmos-connection-string \
  --query value -o tsv

# Test Cosmos DB access
az cosmosdb sql database list \
  --account-name cosmos-browsing-companion-dev \
  --resource-group rg-browsing-companion-dev
```

---

## 💰 Cost Tracking

**Daily Estimated Costs (Development):**
- Azure OpenAI (GPT-4o-mini): $0.01-0.05 (depends on usage)
- Cosmos DB: Free tier (1000 RU/s, 25GB)
- Blob Storage: <$0.01
- Key Vault: <$0.01
- Application Insights: Free tier (5GB/month)

**Total**: ~$0.01-0.05 per day for light development usage

**To Monitor Costs:**
```bash
# View cost analysis
az consumption usage list --start-date 2025-11-26 --end-date 2025-11-27
```

Or visit Azure Portal → Cost Management → Cost Analysis

---

## 🧹 Cleanup (When Done)

To delete all resources and stop incurring costs:

```bash
# Delete resource group (removes all resources)
az group delete --name rg-browsing-companion-dev --yes --no-wait

# Verify deletion
az group show --name rg-browsing-companion-dev
# Should return: ResourceGroupNotFound
```

**Note:** This is irreversible. All data will be lost.

---

## 📝 Technical Notes

### Infrastructure Updates Made:
1. ✅ Updated all API versions to latest stable (Nov 2024)
2. ✅ Using GPT-4o-mini (2024-07-18) for optimal performance and cost
3. ✅ Standard SKU for GPT-4o-mini
4. ✅ Modernized AI Foundry to Hub/Project pattern (@2024-10-01)
5. ✅ Fixed Key Vault name length (19 chars)
6. ✅ Added ApiType metadata to OpenAI connection
7. ✅ Fixed storage blobServices typo
8. ✅ Updated terminology: Azure AI Foundry → Microsoft Foundry

### Validation Tools Created:
- `scripts/validate-azure-resources.sh` - Validates API versions, kinds, and SKUs
- Successfully validated all resources during dry-run

### Known Configuration:
- Cosmos DB: Serverless (no provisioned throughput)
- OpenAI: GlobalStandard SKU with capacity 10
- All endpoints: Public (good for dev, review for production)
- Authentication: Azure CLI credentials for local dev
- CORS: Enabled for localhost:3000

---

## 🎓 Learning Resources

- [Microsoft Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-studio/)
- [Azure OpenAI GPT-4o-mini Guide](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Cosmos DB Best Practices](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)

---

## ✅ Success Criteria

You'll know everything is working when:

1. ✅ AI Service returns Swagger UI at http://localhost:8000/docs
2. ✅ API Gateway responds to health check at http://localhost:3001/health
3. ✅ Frontend loads at http://localhost:3000
4. ✅ You can login with demo credentials
5. ✅ Product catalog displays shoe products
6. ✅ Chat widget opens and accepts messages
7. ✅ AI responds with context-aware answers mentioning visible products
8. ✅ Preferences save and affect AI recommendations
9. ✅ Application Insights shows telemetry in Azure Portal

---

**Ready to start?** Follow the "Next Steps" section above! 🚀
