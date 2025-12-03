# Plan: Working Mockup - Context-Aware Smart Shopping Companion

Build a functional demo of a shoe e-commerce site with an AI browsing companion that can "see" the user's visible page content via DOM snapshots. Uses Python for AI/backend logic, Node.js for web serving, React for custom chat widget UI, and Bicep for Azure infrastructure with latest API versions (post-Ignite 2024). Repo is self-contained—anyone with an Azure subscription can deploy.

> 📋 **Status**: ✅ **COMPLETED** — All core steps implemented with additional enhancements.

## Steps

1. ✅ **Create Bicep infrastructure templates with latest APIs** — Built `/infra` folder with: `main.bicep` (subscription-level orchestration), `modules/ai-foundry.bicep` (Microsoft Foundry hub/project), `modules/openai.bicep` (GPT-4o-mini deployment), `modules/cosmos-db.bicep` (serverless Cosmos DB), `modules/storage.bicep`, `modules/key-vault.bicep` (secrets), `modules/app-insights.bicep` (monitoring), `modules/secrets.bicep` (secret management); includes `parameters/dev.bicepparam` with configurable resource names and location

2. ✅ **Add deployment automation and documentation** — Created `/scripts/deploy.sh` (Azure CLI deployment script), `/scripts/setup-env.sh` (extracts outputs to `.env.local` files for local dev), comprehensive `/README.md` with prerequisites, step-by-step guide, troubleshooting section, and cost estimates; includes `.env.example` files in each service folder. Additional scripts: `start-all-services.sh`, `stop-all-services.sh`, `validate-azure-resources.sh`

3. ✅ **Build Python AI service** — Created FastAPI in `/services/ai-service` with endpoints for chat processing; implemented `chat_service.py` and `context_provider.py` with extensible `ContextProvider` base class; uses Azure OpenAI SDK; includes `requirements.txt`, `Dockerfile`, `config.py`

4. ✅ **Build Node.js API gateway** — Created Express.js in `/services/api-gateway` with routes: `chat.js`, `products.js`, `preferences.js`; middleware for `auth.js` and `cors.js`; product data in `data/products.json` (8 curated shoes with real images); health check endpoint included

5. ✅ **Create React shoe shop with custom chat widget** — Built SPA in `/frontend` with Vite + TypeScript: 
   - `ProductGrid/` - Product catalog with grid layout and `FilterBar` component
   - `ChatWidget/` - Sticky chat widget with `ChatMessage`, `ChatComposer`, `ChatSuggestions` components
   - `Login/` - Email/password authentication form
   - `Navbar/` - Navigation with B2B/B2C toggle and category filters
   - `Shop/` - Main shop container
   - CSS Modules for styling

6. ✅ **Implement DOM snapshot capture logic** — Implemented in `frontend/src/utils/domCapture.ts`: 
   - Intersection Observer API for viewport detection
   - **Three visibility zones**: visible, above-the-fold (scrolled past), below-the-fold (not yet seen)
   - Serializes products to JSON with full metadata
   - AI guides users with "scroll up/down to see..." suggestions
   - **Click-to-scroll**: Product names in chat responses auto-scroll and highlight products

## Additional Features Built (Beyond Original Plan)

- ✅ **Natural Language Filter Control** — Users can say "filter on shoes between $50 and $120" and filters update automatically
- ✅ **Viewport Zone Tracking** — Products tracked as visible/above/below the fold for smarter guidance
- ✅ **Click-to-Scroll Highlighting** — Click product names in chat to scroll and highlight them
- ✅ **Chat Suggestions** — Rotating suggested questions (16 suggestions across 4 categories)
- ✅ **Rich Markdown Responses** — AI responses with headers, lists, emoticons, formatted prices
- ✅ **Comprehensive Documentation** — 6 docs: `CONTEXT_AWARE_METHODS.md`, `TECHNICAL_DEEP_DIVE.md`, `FILTER_IMPLEMENTATION.md`, `VIEWPORT_AWARENESS_UPDATE.md`, `HOW-IT-WORKS.md`, `PROJECT-SUMMARY.md`
- ✅ **Application Insights** — Azure monitoring integration

## Decisions Made (from Further Considerations)

1. **Resource naming** — ✅ Consistent naming implemented; README includes cost estimates (free tier Cosmos DB, ~$0.01-0.03/chat for OpenAI)

2. **Local development setup** — ✅ Chose separate terminals approach (Python 8000, Node 3001, React 3000) for simpler dependencies. Docker-compose not implemented.

3. **Chat widget features** — ✅ Implemented conversation history, minimize/maximize, markdown rendering, suggestions. Thumbs up/down feedback not implemented (future enhancement).

4. **Context provider extensibility** — ✅ `ContextProvider` base class implemented in `context_provider.py`, ready for future screenshot/accessibility tree providers.

5. **Authentication approach** — ✅ Simple demo auth with hardcoded credentials (`user1@example.com`/`password`, `user2@example.com`/`password`) demonstrating B2C vs B2B user preferences.

## 💬 Note

This repository (Method 1) is open source. Methods 3-6 describe more advanced approaches — for commercial inquiries, [reach out via LinkedIn](https://www.linkedin.com/in/dvanderuit/).
