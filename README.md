# Browsing Companion - DOM Snapshot Injection Demo

A context-aware chatbot demo for e-commerce that "sees" what the user is viewing through DOM snapshot injection. Built with React, Node.js, Python, and Microsoft Azure AI Foundry.

## 🎯 Overview

This project demonstrates a shoe e-commerce website where an AI chatbot assistant can:
- See which products are currently visible on the user's screen
- Provide personalized recommendations based on user preferences (B2B/B2C, category filters)
- Answer questions about visible products using context from DOM snapshots
- Maintain conversation history and user preferences

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────────┐
│   React     │────▶│   Node.js    │────▶│   Python    │────▶│  Azure OpenAI    │
│   Frontend  │     │   Gateway    │     │  AI Service │     │  (GPT-4o)        │
│  (Port 3000)│     │  (Port 3001) │     │ (Port 8000) │     │                  │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────────────┘
       │                    │                     │
       │                    │                     ├──────▶ Cosmos DB (user data)
       │                    │                     └──────▶ Blob Storage (snapshots)
       │                    │
       └────── DOM Snapshot Capture ──────────────┘
```

### Tech Stack
- **Frontend**: React 18 + TypeScript + Vite
- **API Gateway**: Node.js + Express
- **AI Service**: Python + FastAPI
- **AI Platform**: Microsoft Foundry + Azure OpenAI (GPT-4o)
- **Database**: Azure Cosmos DB (serverless)
- **Storage**: Azure Blob Storage
- **Infrastructure**: Azure Bicep (latest API versions)

## 📋 Prerequisites

Before you begin, ensure you have:

1. **Azure Subscription** with permissions to create resources
2. **Azure CLI** installed ([Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
3. **Node.js** v18+ and npm ([Download](https://nodejs.org/))
4. **Python** 3.11+ and pip ([Download](https://www.python.org/))
5. **Git** for cloning the repository

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/doruit/Browsing-Companion-DOM-snapshot-injection.git
cd Browsing-Companion-DOM-snapshot-injection
```

### 2. Login to Azure

```bash
az login
# If you have multiple subscriptions, set the desired one:
# az account set --subscription <subscription-id>
```

### 3. Deploy Azure Infrastructure

This will create all required Azure resources (OpenAI, Cosmos DB, Storage, etc.):

```bash
./scripts/deploy.sh
```

The deployment takes approximately 10-15 minutes. Resources created:
- Resource Group
- Azure OpenAI with GPT-4o deployment
- Microsoft Foundry Hub and Project
- Cosmos DB (serverless) with containers
- Azure Storage with blob container
- Key Vault for secrets
- Application Insights for monitoring

**💰 Estimated Cost**: 
- Cosmos DB: Free tier (1000 RU/s, 25GB)
- OpenAI: Pay-as-you-go (~$0.01-0.03 per chat interaction)
- Storage: Minimal (<$1/month for demo usage)

### 4. Configure Local Environment

Extract deployment outputs and create `.env.local` files:

```bash
./scripts/setup-env.sh
```

This creates environment files for all three services with connection strings and API keys from Azure.

### 5. Install Dependencies

**Python AI Service:**
```bash
cd services/ai-service
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cd ../..
```

**Node.js API Gateway:**
```bash
cd services/api-gateway
npm install
cd ../..
```

**React Frontend:**
```bash
cd frontend
npm install
cd ..
```

### 6. Start the Services

Open **three separate terminal windows** and run:

**Terminal 1 - Python AI Service:**
```bash
cd services/ai-service
source venv/bin/activate  # On Windows: venv\Scripts\activate
python -m uvicorn main:app --reload --port 8000
```

**Terminal 2 - Node.js API Gateway:**
```bash
cd services/api-gateway
npm run dev
```

**Terminal 3 - React Frontend:**
```bash
cd frontend
npm run dev
```

### 7. Open the Application

Navigate to **http://localhost:3000** in your browser.

**Demo Credentials:**
- User 1: `user1@example.com` / `password` (B2C, likes Running shoes)
- User 2: `user2@example.com` / `password` (B2B, bulk orders)

## 🎮 Using the Demo

1. **Login** with one of the demo accounts
2. **Browse products** - scroll through the shoe catalog
3. **Set preferences** - Toggle B2B/B2C mode, select/deselect categories
4. **Chat with AI** - Click the chat widget in the bottom right
5. **Ask questions** like:
   - "What products can you see on my screen?"
   - "Which shoes have discounts right now?"
   - "Recommend running shoes under $100"
   - "What's the most expensive shoe visible?"

The AI can see which products are currently visible in your viewport!

## 📁 Project Structure

```
.
├── frontend/                 # React application
│   ├── src/
│   │   ├── components/
│   │   │   ├── ChatWidget/   # Sticky chat interface
│   │   │   ├── ProductGrid/  # Product catalog
│   │   │   └── Preferences/  # User settings
│   │   ├── utils/
│   │   │   └── domCapture.ts # DOM snapshot logic
│   │   └── App.tsx
│   ├── .env.example
│   └── package.json
│
├── services/
│   ├── ai-service/           # Python FastAPI service
│   │   ├── main.py           # API endpoints
│   │   ├── services/
│   │   │   ├── chat_service.py
│   │   │   └── context_provider.py
│   │   ├── requirements.txt
│   │   └── .env.example
│   │
│   └── api-gateway/          # Node.js Express gateway
│       ├── src/
│       │   ├── routes/       # API routes
│       │   └── middleware/   # Auth, validation
│       ├── data/
│       │   └── products.json # Mock product data
│       ├── package.json
│       └── .env.example
│
├── infra/                    # Azure Bicep templates
│   ├── main.bicep
│   ├── modules/
│   │   ├── openai.bicep
│   │   ├── cosmos-db.bicep
│   │   ├── storage.bicep
│   │   ├── key-vault.bicep
│   │   └── ai-foundry.bicep
│   └── parameters/
│       └── dev.bicepparam
│
├── scripts/
│   ├── deploy.sh             # Azure deployment script
│   └── setup-env.sh          # Local environment setup
│
└── README.md
```

## 🔧 Configuration

### Environment Variables

Each service has its own `.env.local` file (created by `setup-env.sh`):

**Python AI Service** (`services/ai-service/.env.local`):
- `AZURE_OPENAI_ENDPOINT` - Azure OpenAI endpoint
- `AZURE_OPENAI_API_KEY` - API key
- `AZURE_OPENAI_DEPLOYMENT_NAME` - Model deployment name
- `COSMOS_CONNECTION_STRING` - Cosmos DB connection
- `COSMOS_DATABASE_NAME` - Database name

**Node.js Gateway** (`services/api-gateway/.env.local`):
- `PORT` - Server port (default: 3001)
- `AI_SERVICE_URL` - Python service URL
- `JWT_SECRET` - JWT signing secret (demo only)
- `CORS_ORIGIN` - Frontend URL

**React Frontend** (`frontend/.env.local`):
- `VITE_API_URL` - API Gateway URL

## 🧪 Development

### Adding New Product Categories

Edit `services/api-gateway/data/products.json` to add more shoes or categories.

### Customizing the Chat Widget

Modify `frontend/src/components/ChatWidget/` to change appearance or add features.

### Extending Context Providers

The Python AI service uses a `ContextProvider` base class. To add new context methods (screenshots, accessibility tree):

1. Create new provider in `services/ai-service/services/context_provider.py`
2. Implement `get_context()` method
3. Register in `services/ai-service/main.py`

## 🧹 Cleanup

To delete all Azure resources:

```bash
RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' deployment-outputs.json)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 🐛 Troubleshooting

### "Deployment failed" error
- Ensure you have Contributor role on the subscription
- Check if you have available quota for Azure OpenAI in the selected region
- Try a different region (e.g., `westus`, `swedencentral`)

### "Cannot connect to AI service" error
- Verify all three services are running
- Check `.env.local` files have correct URLs
- Ensure ports 3000, 3001, 8000 are not in use

### "Key Vault access denied" error
- Run: `az ad signed-in-user show --query id -o tsv` and verify the Object ID
- Ensure you ran `deploy.sh` which grants you Key Vault access

## 📚 Learn More

- [Microsoft Foundry Documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Cosmos DB Best Practices](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

This is a demo project. Feel free to fork and adapt for your needs!

---

Built with ❤️ using Microsoft Foundry and Azure AI Services
