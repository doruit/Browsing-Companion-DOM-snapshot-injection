# Plan: Working Mockup - Context-Aware Smart Shopping Companion

Build a functional demo of a shoe e-commerce site with an AI chatbot that can "see" the user's visible page content via DOM snapshots. Uses Python for AI/backend logic, Node.js for web serving, React for custom chat widget UI, and Bicep for Azure infrastructure with latest API versions (post-Ignite 2024). Repo is self-contained—anyone with an Azure subscription can deploy.

## Steps

1. **Create Bicep infrastructure templates with latest APIs** — Build `/infra` folder with: `main.bicep` (subscription-level orchestration), `modules/ai-foundry.bicep` (Microsoft Foundry hub/project `@2024-04-01`), `modules/openai.bicep` (GPT-4o-mini deployment `@2025-10-01-preview`), `modules/cosmos-db.bicep` (serverless Cosmos DB `@2024-05-15`), `modules/storage.bicep` (`@2025-06-01`), `modules/key-vault.bicep` (secrets); include `parameters/dev.bicepparam` with configurable resource names and location

2. **Add deployment automation and documentation** — Create `/scripts/deploy.sh` (Azure CLI deployment script), `/scripts/setup-env.sh` (extracts outputs to `.env.local` files for local dev), comprehensive `/README.md` (prerequisites: Azure subscription, Azure CLI installed; step-by-step: clone repo → login → run deploy.sh → run setup-env.sh → start services); include `.env.example` files in each service folder

3. **Build Python AI service** — Create FastAPI in `/services/ai-service` with endpoints: `/process-chat` (DOM snapshot + message → Foundry GPT-4o-mini), `/analyze-preferences` (recommendation logic); use `azure-ai-inference`, `azure-cosmos`, `azure-identity` SDKs; read config from environment (Foundry endpoint, Cosmos connection string from Key Vault); include `requirements.txt`, `Dockerfile`, startup script

4. **Build Node.js API gateway** — Create Express.js in `/services/api-gateway` with: `/api/chat` (validates request, proxies to Python AI service), `/api/products` (returns filtered product list from JSON file), `/api/preferences` (CRUD to Cosmos DB via Python service), simple JWT auth (mock tokens for demo); include `package.json`, health check endpoint, CORS config for local dev

5. **Create React shoe shop with custom chat widget** — Build SPA in `/frontend` with Vite: product catalog page (grid of 20-30 mock shoes with categories/prices/discounts), custom sticky chat widget component (styled similar to example: header with title/controls, scrollable message area, composer with textarea/buttons), login page (email/password form), preferences panel (B2B/B2C toggle, category checkboxes); include TypeScript, styled-components/CSS modules

6. **Implement DOM snapshot capture logic** — In chat widget component: use Intersection Observer API to detect visible product cards in viewport, on send button click serialize visible products to JSON array `[{id, name, price, category, discount, visible: true}]`, include page URL and timestamp, send to `/api/chat` with user message; Python AI service injects DOM context into system prompt: "You're a Smart Shopping Companion. User currently sees: {PRODUCTS}. Their preferences: {USER_PREFS}. Help them find shoes."

## Further Considerations

1. **Resource naming and regions** — Use consistent naming in Bicep parameters: `rg-browsing-companion-{env}`, `openai-browsing-{env}`, `cosmos-browsing-{env}`; default to `eastus` but allow region override? Should README include cost estimates (free tiers: Cosmos DB 1000 RU/s, pay-as-you-go OpenAI ~$0.01-0.03 per chat)?

2. **Local development setup** — Run all three services locally with separate terminals (Python on 8000, Node on 3001, React on 3000) or provide `docker-compose.yml` for one-command startup? Docker = easier but requires Docker Desktop; separate terminals = simpler dependencies

3. **Chat widget features** — Implement full feature set from example (conversation history, minimize/maximize, clear conversation, thumbs up/down feedback, share response) or start with minimal MVP (just messages + composer)? MVP = faster delivery, can iterate later

4. **Future context provider extensibility** — Add abstract `ContextProvider` base class in Python with `get_context(page_url, user_id)` method, implement `DOMSnapshotProvider` as first concrete class; creates clean pattern for adding screenshot/accessibility tree providers later without refactoring API contracts

5. **Authentication approach** — Use simple hardcoded JWT tokens (e.g., `user1-token`, `user2-token`) for demo with user ID in payload, or implement basic email/password with bcrypt in Cosmos DB? Hardcoded = faster testing, still demonstrates user-specific preferences
