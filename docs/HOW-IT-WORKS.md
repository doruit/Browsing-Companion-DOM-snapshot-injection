# How It Works - DOM Snapshot Context Injection

## Overview

This demo showcases a **context-aware chatbot** that can "see" what products are visible on the user's screen by using **DOM snapshot injection**. This creates a more natural and helpful shopping assistant experience.

## Technical Implementation

### 1. DOM Snapshot Capture (Frontend)

**Technology**: Intersection Observer API

The `DOMCaptureService` class (`frontend/src/utils/domCapture.ts`) tracks product visibility:

```typescript
// Observes product cards in viewport
this.observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    const productId = entry.target.getAttribute('data-product-id');
    if (entry.isIntersecting) {
      this.visibleProducts.add(productId);  // Product is visible
    } else {
      this.visibleProducts.delete(productId);  // Product scrolled out
    }
  });
}, { threshold: 0.5 });  // 50% visible
```

When you send a chat message, the system captures:
- **visible_products**: Array of products in viewport (id, name, price, category, discount, description)
- **page_url**: Current URL
- **timestamp**: Capture time

### 2. Context Provider Pattern (AI Service)

**File**: `services/ai-service/services/context_provider.py`

The AI service uses an **extensible context provider pattern** to support multiple context capture methods:

```python
class ContextProvider(ABC):
    @abstractmethod
    async def get_context(self, data: Dict[str, Any]) -> str:
        pass

class DOMSnapshotProvider(ContextProvider):
    async def get_context(self, data: Dict[str, Any]) -> str:
        # Format DOM snapshot into readable context
        visible_products = data.get("visible_products", [])
        return f"User is viewing {len(visible_products)} products..."
```

**Future providers** (placeholders included):
- `ScreenshotProvider` - Use GPT-4o Vision to analyze screenshots
- `AccessibilityTreeProvider` - Parse semantic HTML structure

### 3. System Prompt Construction

The AI service builds a rich system prompt combining:

1. **Base instructions**: "You are a Smart Shopping Companion..."
2. **User preferences**: B2B/B2C status, preferred/hidden categories
3. **DOM context**: List of visible products with details

**Example prompt**:
```
You are a Smart Shopping Companion for a shoe e-commerce website.

Customer Type: B2B business customer
Preferred Categories: athletic, outdoor

=== CURRENT PAGE CONTEXT ===
User is viewing 6 products on page: http://localhost:3000/shop

Visible products:
1. Air Cushion Running Shoes | Category: athletic | Price: $89.99 | Discount: 15% off
2. Premium Hiking Boots | Category: outdoor | Price: $199.99 | Discount: 10% off
...
=== END CONTEXT ===

When answering questions, reference specific products that are visible on the user's screen.
```

### 4. Chat Flow

```
┌─────────┐
│  User   │ "Which running shoes do you see?"
└────┬────┘
     │
     ▼
┌─────────────────────────────┐
│ Frontend (React)            │
│ • Captures DOM snapshot     │
│ • Sends to API Gateway      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ API Gateway (Node.js)       │
│ • Validates JWT             │
│ • Forwards to AI Service    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ AI Service (Python)         │
│ • Gets user preferences     │
│ • Formats DOM context       │
│ • Builds system prompt      │
│ • Calls Azure OpenAI        │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Azure OpenAI (GPT-4o-mini)  │
│ Returns context-aware reply │
└──────────────┬──────────────┘
               │
               ▼
        "I can see the Air
        Cushion Running Shoes
        at $89.99 with 15% off..."
```

## Key Features

### Context Awareness
- **Sees visible products**: AI knows exactly what's on your screen
- **Spatial awareness**: Can reference specific products by position
- **Real-time updates**: Context updates as you scroll

### Personalization
- **User preferences**: B2B vs B2C pricing/availability
- **Category filters**: Hide/show product categories
- **Conversation history**: Maintains context across messages (stored in Cosmos DB)

### Extensibility
The architecture supports adding new context methods without changing the core logic:

```python
# Add new context provider
class ScreenshotProvider(ContextProvider):
    async def get_context(self, data: Dict[str, Any]) -> str:
        screenshot = data.get("screenshot")
        # Use GPT-4o Vision to analyze screenshot
        return vision_analysis_result
```

## Use Cases

This pattern is valuable for:

1. **E-commerce**: Product recommendations based on browsing behavior
2. **Documentation sites**: Context-aware help based on current page
3. **Data dashboards**: Answer questions about visible charts/metrics
4. **Form assistants**: Help users fill forms based on visible fields
5. **Code editors**: Provide suggestions based on visible code

## Performance Considerations

- **Intersection Observer**: Efficient viewport detection (< 1ms per frame)
- **Snapshot size**: Typically 1-5KB JSON per capture
- **API latency**: ~200-800ms for GPT-4o-mini response
- **Cosmos DB**: Serverless auto-scales with usage

## Privacy & Security

- **Client-side capture**: DOM data never leaves user's control until they send a message
- **JWT authentication**: All API requests require valid tokens
- **Key Vault**: Connection strings and API keys stored securely
- **No PII in snapshots**: Only product metadata captured (no user behavior tracking)

## Future Enhancements

1. **Screenshot Analysis**: Use a Vision capable model for richer visual context
2. **Semantic HTML**: Parse accessibility tree for better structure
3. **User behavior**: Track engagement patterns for better recommendations
4. **Multi-modal**: Combine DOM + screenshot + user history
5. **Real-time sync**: WebSocket for instant context updates
