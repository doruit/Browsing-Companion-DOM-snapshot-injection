# Technical Deep Dive: Browsing Companion Architecture

This document provides a comprehensive technical explanation of how the Browsing Companion works, including the DOM capture mechanism, viewport awareness system, and AI integration.

## Table of Contents

1. [System Architecture Overview](#system-architecture-overview)
2. [DOM Capture Mechanism](#dom-capture-mechanism)
3. [Viewport Awareness: Three-Zone Tracking](#viewport-awareness-three-zone-tracking)
4. [Snapshot Data Structure](#snapshot-data-structure)
5. [Backend Context Processing](#backend-context-processing)
6. [Click-to-Scroll Feature](#click-to-scroll-feature)
7. [Performance Considerations](#performance-considerations)
8. [Sequence Diagrams](#sequence-diagrams)

---

## System Architecture Overview

The Browsing Companion uses a three-tier architecture:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FRONTEND (React + TypeScript)                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │  ProductGrid    │    │  ChatPanel      │    │  DOMCaptureService│   │
│  │  (renders items)│───▶│  (user chat UI) │◀──▶│  (observes DOM)  │    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│           │                      │                      │               │
│           ▼                      ▼                      ▼               │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Intersection Observer API (Browser Native)          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ HTTP/WebSocket
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY (Node.js/Express)                     │
│                    Proxies requests, handles routing                     │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ HTTP
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         AI SERVICE (Python/FastAPI)                      │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │ ContextProvider │───▶│  ChatService    │───▶│ Azure OpenAI    │     │
│  │ (formats data)  │    │ (builds prompt) │    │ (GPT-4o-mini)   │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User scrolls/browses** → ProductGrid renders product cards
2. **Intersection Observer** detects which products are visible/above/below viewport
3. **User sends message** → ChatPanel captures DOM snapshot
4. **Snapshot sent** to API Gateway → forwarded to AI Service
5. **AI Service** formats context + generates response
6. **Response returned** → ChatPanel displays + enables click-to-scroll

---

## DOM Capture Mechanism

### The DOMCaptureService Class

Located at `frontend/src/utils/domCapture.ts`, this singleton service is responsible for tracking product visibility in real-time.

```typescript
export class DOMCaptureService {
  // Three Sets to track products in each zone
  private visibleProducts: Set<string> = new Set();
  private aboveFoldProducts: Set<string> = new Set();
  private belowFoldProducts: Set<string> = new Set();
  
  // Browser's Intersection Observer instance
  private observer: IntersectionObserver | null = null;
  
  // Map of product IDs to their DOM elements (for scrolling)
  private productElements: Map<string, HTMLElement> = new Map();
}
```

### How Products Are Discovered

Products are identified by the `data-product-id` attribute on their DOM elements:

```tsx
// In ProductCard.tsx
<div 
  className={styles.productCard}
  data-product-id={product.id}  // ← This attribute enables tracking
>
  {/* Product content */}
</div>
```

The service observes all elements with this attribute:

```typescript
observeProducts(productElements: HTMLElement[], products: Product[]) {
  productElements.forEach((element) => {
    const productId = element.getAttribute('data-product-id');
    if (productId) {
      this.productElements.set(productId, element);
      this.observer?.observe(element);  // Start watching this element
    }
  });
}
```

---

## Viewport Awareness: Three-Zone Tracking

The core innovation is tracking products across three visibility zones:

```
┌─────────────────────────────────────────┐
│                                         │
│   ⬆️ ABOVE THE FOLD                     │  ← Products user scrolled past
│   (rect.bottom < 0)                     │
│                                         │
├─────────────────────────────────────────┤ ← Top of viewport (y = 0)
│                                         │
│   🔍 VISIBLE AREA                       │  ← Products currently on screen
│   (isIntersecting = true)               │
│                                         │
├─────────────────────────────────────────┤ ← Bottom of viewport (y = innerHeight)
│                                         │
│   ⬇️ BELOW THE FOLD                     │  ← Products requiring scroll down
│   (rect.top > window.innerHeight)       │
│                                         │
└─────────────────────────────────────────┘
```

### Intersection Observer Setup

```typescript
private setupObserver() {
  this.observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const productId = entry.target.getAttribute('data-product-id');
        if (!productId) return;

        if (entry.isIntersecting) {
          // Product entered the viewport - it's now VISIBLE
          this.visibleProducts.add(productId);
          this.aboveFoldProducts.delete(productId);
          this.belowFoldProducts.delete(productId);
        } else {
          // Product left the viewport - determine which zone
          this.visibleProducts.delete(productId);
          
          const rect = entry.target.getBoundingClientRect();
          
          if (rect.bottom < 0) {
            // Element's bottom edge is above viewport top
            // → User scrolled PAST this product
            this.aboveFoldProducts.add(productId);
            this.belowFoldProducts.delete(productId);
          } else if (rect.top > window.innerHeight) {
            // Element's top edge is below viewport bottom
            // → Product is further DOWN the page
            this.belowFoldProducts.add(productId);
            this.aboveFoldProducts.delete(productId);
          }
        }
      });
    },
    {
      root: null,        // Use viewport as root
      rootMargin: '0px', // No margin adjustment
      threshold: 0.5,    // Trigger when 50% visible
    }
  );
}
```

### Why 50% Threshold?

The `threshold: 0.5` means the callback fires when 50% of a product card is visible. This prevents:
- Products barely peeking into view from being counted as "visible"
- Flickering when products are at the edge of the viewport

### Zone Detection Logic

| Condition | Zone | User Context |
|-----------|------|--------------|
| `entry.isIntersecting === true` | Visible | User can see this product right now |
| `rect.bottom < 0` | Above Fold | User has scrolled past this product |
| `rect.top > window.innerHeight` | Below Fold | User needs to scroll down to see this |

---

## Snapshot Data Structure

When a user sends a message, the system captures a complete snapshot:

### TypeScript Interface

```typescript
interface DOMSnapshot {
  visible_products: ProductData[];      // Currently on screen
  above_fold_products: ProductData[];   // Scrolled past
  below_fold_products: ProductData[];   // Need to scroll to see
  page_url: string;                     // Current URL
  timestamp: number;                    // Capture time (ms)
}

interface ProductData {
  id: string;
  name: string;
  category: string;
  price: number;
  discount?: number;
  description?: string;
  visible: boolean;
}
```

### Example Snapshot JSON

```json
{
  "visible_products": [
    {
      "id": "prod-003",
      "name": "Urban Runner Elite",
      "category": "Running",
      "price": 129.99,
      "discount": 20,
      "description": "Lightweight running shoe with responsive cushioning",
      "visible": true
    },
    {
      "id": "prod-004",
      "name": "Trail Blazer Pro",
      "category": "Hiking",
      "price": 159.99,
      "discount": 0,
      "description": "Rugged hiking boot for challenging terrain",
      "visible": true
    }
  ],
  "above_fold_products": [
    {
      "id": "prod-001",
      "name": "Classic Leather Loafer",
      "category": "Formal",
      "price": 89.99,
      "discount": 15,
      "visible": false
    },
    {
      "id": "prod-002",
      "name": "Sport Flex Sneaker",
      "category": "Athletic",
      "price": 74.99,
      "discount": 25,
      "visible": false
    }
  ],
  "below_fold_products": [
    {
      "id": "prod-005",
      "name": "Beach Comfort Sandal",
      "category": "Casual",
      "price": 49.99,
      "discount": 10,
      "visible": false
    }
  ],
  "page_url": "http://localhost:3000/",
  "timestamp": 1732892400000
}
```

---

## Backend Context Processing

### Context Provider (Python)

The `DOMSnapshotProvider` class in `services/ai-service/services/context_provider.py` transforms the JSON snapshot into a human-readable format for the AI:

```python
async def get_context(self, data: Dict[str, Any]) -> str:
    visible_products = data.get("visible_products", [])
    above_fold_products = data.get("above_fold_products", [])
    below_fold_products = data.get("below_fold_products", [])
    
    context_parts = []
    
    # Summary line
    total = len(visible_products) + len(above_fold_products) + len(below_fold_products)
    context_parts.append(f"Total products tracked: {total}")
    
    # Format each zone
    if visible_products:
        context_parts.append("\n🔍 VISIBLE PRODUCTS (currently on screen):")
        for idx, product in enumerate(visible_products, 1):
            context_parts.append(self._format_product(idx, product))
    
    if above_fold_products:
        context_parts.append(f"\n⬆️ ABOVE THE FOLD ({len(above_fold_products)} products):")
        for idx, product in enumerate(above_fold_products, 1):
            context_parts.append(self._format_product(idx, product))
    
    if below_fold_products:
        context_parts.append(f"\n⬇️ BELOW THE FOLD ({len(below_fold_products)} products):")
        for idx, product in enumerate(below_fold_products, 1):
            context_parts.append(self._format_product(idx, product))
    
    return "\n".join(context_parts)
```

### Formatted Output Example

```
Total products tracked: 5 (Visible: 2, Above fold: 2, Below fold: 1)

🔍 VISIBLE PRODUCTS (currently on screen):
1. Urban Runner Elite (ID: prod-003) | Category: Running | Price: $129.99 | Discount: 20% off
2. Trail Blazer Pro (ID: prod-004) | Category: Hiking | Price: $159.99

⬆️ ABOVE THE FOLD (2 products - user scrolled past these):
1. Classic Leather Loafer (ID: prod-001) | Category: Formal | Price: $89.99 | Discount: 15% off
2. Sport Flex Sneaker (ID: prod-002) | Category: Athletic | Price: $74.99 | Discount: 25% off

⬇️ BELOW THE FOLD (1 products - require scrolling down):
1. Beach Comfort Sandal (ID: prod-005) | Category: Casual | Price: $49.99 | Discount: 10% off
```

### System Prompt Construction

The AI receives this context as part of its system prompt:

```python
system_prompt = f"""You are a helpful shopping assistant for an e-commerce shoe store.

CURRENT PAGE CONTEXT:
{formatted_context}

VIEWPORT AWARENESS:
- 🔍 VISIBLE: Products the user can see RIGHT NOW
- ⬆️ ABOVE THE FOLD: Products the user has already scrolled past
- ⬇️ BELOW THE FOLD: Products below the current view (suggest scrolling)

When answering questions:
1. Prioritize VISIBLE products in your responses
2. Mention if better options exist ABOVE or BELOW the fold
3. Use exact product names for click-to-scroll functionality
"""
```

---

## Click-to-Scroll Feature

When the AI mentions a product by name, users can click on it to scroll directly to that product.

### Frontend Detection

```typescript
// In ChatPanel.tsx - detect product names in AI responses
const detectProductMentions = (text: string): string[] => {
  const productNames = products.map(p => p.name);
  return productNames.filter(name => 
    text.toLowerCase().includes(name.toLowerCase())
  );
};
```

### Scroll Implementation

```typescript
const scrollToProduct = (productName: string) => {
  // Find the product element
  const productCards = document.querySelectorAll('[data-product-id]');
  
  for (const card of productCards) {
    if (card.textContent?.includes(productName)) {
      // Smooth scroll to the product
      card.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'center' 
      });
      
      // Add highlight animation
      card.classList.add('product-highlight');
      
      // Remove highlight after animation completes
      setTimeout(() => {
        card.classList.remove('product-highlight');
      }, 2400);  // 1.2s animation × 2 iterations
      
      break;
    }
  }
};
```

### CSS Highlight Animation

```css
@keyframes highlightPulse {
  0% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.8);
    transform: scale(1);
    outline: 3px solid transparent;
  }
  50% {
    box-shadow: 0 0 30px 20px rgba(59, 130, 246, 0.25);
    transform: scale(1.03);
    outline: 3px solid rgba(59, 130, 246, 0.8);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
    transform: scale(1);
    outline: 3px solid transparent;
  }
}

.product-highlight {
  animation: highlightPulse 1.2s ease-in-out 2;
  position: relative;
  z-index: 10;
  border-radius: 12px;
}
```

---

## Performance Considerations

### 1. Intersection Observer Efficiency

The Intersection Observer API is highly optimized by browsers:
- Runs off the main thread
- Batches callbacks for multiple elements
- Only fires when visibility actually changes

### 2. Debouncing Snapshots

To prevent excessive API calls during rapid scrolling:

```typescript
// Debounce snapshot capture (not shown in current code, but recommended)
const debouncedCapture = debounce(() => {
  const snapshot = domCaptureService.captureSnapshot();
  // Send to backend only when needed
}, 100);
```

### 3. Memory Management

The service properly cleans up when unmounting:

```typescript
disconnect() {
  if (this.observer) {
    this.observer.disconnect();  // Stop all observations
  }
  this.visibleProducts.clear();
  this.aboveFoldProducts.clear();
  this.belowFoldProducts.clear();
  this.productElements.clear();
}
```

### 4. Efficient Data Structures

Using `Set` instead of arrays for O(1) add/delete/has operations:

```typescript
// O(1) operations
this.visibleProducts.add(productId);
this.visibleProducts.delete(productId);
this.visibleProducts.has(productId);
```

---

## Sequence Diagrams

### Message Flow

```
User                Browser              API Gateway         AI Service
 │                    │                      │                   │
 │  types message     │                      │                   │
 │───────────────────▶│                      │                   │
 │                    │                      │                   │
 │                    │ captureSnapshot()    │                   │
 │                    │──────────┐           │                   │
 │                    │          │           │                   │
 │                    │◀─────────┘           │                   │
 │                    │ DOMSnapshot          │                   │
 │                    │                      │                   │
 │                    │ POST /chat           │                   │
 │                    │ {message, snapshot}  │                   │
 │                    │─────────────────────▶│                   │
 │                    │                      │                   │
 │                    │                      │ POST /chat        │
 │                    │                      │──────────────────▶│
 │                    │                      │                   │
 │                    │                      │    format context │
 │                    │                      │    build prompt   │
 │                    │                      │    call OpenAI    │
 │                    │                      │                   │
 │                    │                      │◀──────────────────│
 │                    │                      │    AI response    │
 │                    │◀─────────────────────│                   │
 │                    │                      │                   │
 │  display response  │                      │                   │
 │◀───────────────────│                      │                   │
 │                    │                      │                   │
 │  clicks product    │                      │                   │
 │───────────────────▶│                      │                   │
 │                    │                      │                   │
 │                    │ scrollIntoView()     │                   │
 │                    │ add highlight class  │                   │
 │                    │──────────┐           │                   │
 │                    │          │           │                   │
 │  sees product      │◀─────────┘           │                   │
 │  highlighted       │                      │                   │
 │                    │                      │                   │
```

### Scroll Event Processing

```
User Scrolls         Intersection Observer         DOMCaptureService
     │                        │                          │
     │ scroll event           │                          │
     │───────────────────────▶│                          │
     │                        │                          │
     │                        │ callback(entries)        │
     │                        │─────────────────────────▶│
     │                        │                          │
     │                        │    for each entry:       │
     │                        │    - check isIntersecting│
     │                        │    - check rect.bottom   │
     │                        │    - check rect.top      │
     │                        │    - update Sets         │
     │                        │                          │
     │                        │◀─────────────────────────│
     │                        │                          │
     │                        │                          │
     │                        │ (waits for next change)  │
     │                        │                          │
```

---

## Summary

The Browsing Companion achieves real-time viewport awareness through:

1. **Intersection Observer API** - Native browser API for efficient visibility tracking
2. **Three-Zone Classification** - Above fold, visible, below fold
3. **Bounding Rectangle Math** - `getBoundingClientRect()` for precise positioning
4. **Set-based Tracking** - O(1) operations for fast updates
5. **Snapshot Serialization** - Complete page state captured on each message
6. **AI Context Injection** - Formatted context in system prompt
7. **Click-to-Scroll** - Smooth navigation with visual feedback

This architecture enables the AI to understand exactly what the user sees, what they've already viewed, and what options await them below—making for a truly context-aware shopping assistant.
