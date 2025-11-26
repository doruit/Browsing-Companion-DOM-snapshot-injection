# 🔍 Viewport Awareness Enhancement

## Overview

Enhanced the chatbot to distinguish between products currently visible on screen and products that require scrolling down (below the fold). This allows the chatbot to guide users more effectively by saying things like "if you scroll down a bit, you'll find..."

## Problem Statement

**Before:** When users asked about products with specific criteria (e.g., "shoes with at least 25% discount"), the chatbot only knew about products currently visible in the viewport. If matching products existed further down the page, the chatbot would incorrectly say they don't exist.

**After:** The chatbot now tracks ALL products on the page and can tell users:
- Which matching products are currently visible
- Which matching products require scrolling down to see

## Technical Changes

### 1. Frontend - TypeScript Types (`frontend/src/types.ts`)

**Added:**
```typescript
export interface DOMSnapshot {
  visible_products: Array<{...}>;
  below_fold_products: Array<{...}>; // NEW: Products below viewport
  page_url: string;
  timestamp: number;
}
```

### 2. Frontend - DOM Capture Service (`frontend/src/utils/domCapture.ts`)

**Enhanced tracking:**
- Added `belowFoldProducts` Set to track products below the viewport
- Added `productElements` Map to store references to all product DOM elements
- Modified Intersection Observer callback to categorize products as visible or below-fold based on `getBoundingClientRect()`
- Updated `captureSnapshot()` to return both visible and below-fold products

**Key logic:**
```typescript
// Check if product is below the viewport
const rect = entry.target.getBoundingClientRect();
if (rect.top > window.innerHeight) {
  this.belowFoldProducts.add(productId);
}
```

### 3. Backend - Context Provider (`services/ai-service/services/context_provider.py`)

**Enhanced context formatting:**
```python
# Format visible products
🔍 VISIBLE PRODUCTS (currently on screen):
1. Product Name | Category: ... | Price: $... | Discount: ...%

# Format below-fold products  
📜 BELOW THE FOLD (X products require scrolling down):
1. Product Name | Category: ... | Price: $... | Discount: ...%
```

### 4. Backend - AI System Prompt (`services/ai-service/services/chat_service.py`)

**Added instructions:**
```
VIEWPORT AWARENESS:
You will receive information about TWO types of products:
1. 🔍 VISIBLE PRODUCTS - Currently visible on the user's screen
2. 📜 BELOW THE FOLD - Products that require scrolling down

When answering questions:
- If matching products are only in the VISIBLE section, mention them directly
- If matching products are BELOW THE FOLD, tell the user they need to scroll down
- Use phrases like "if you scroll down a bit..." or "further down the page..."
- Always check BOTH sections when answering questions about availability
```

## Usage Example

### Before (Old Behavior)
```
User: "Show me shoes with at least 25% discount"
Bot: "I don't see any shoes with 25% discount in the visible products."
❌ WRONG - There ARE discounted shoes on the page, just not visible
```

### After (New Behavior)
```
User: "Show me shoes with at least 25% discount"
Bot: "I can see you're looking for great deals! 💰

While there aren't any shoes with 25% discount in the visible area, 
if you scroll down a bit, you'll find:

• **Trail Runner Pro** - 30% off, now $69.99 (was $99.99)
• **Urban Comfort Sneakers** - 25% off, now $67.49 (was $89.99)

✨ These are excellent deals that meet your criteria!"
✅ CORRECT - Guides user to scroll down
```

## Benefits

1. **Accurate Responses** - No longer tells users products don't exist when they're just below the fold
2. **Better Navigation** - Guides users to scroll when needed
3. **Improved UX** - Users don't need to manually scroll to find what they're looking for
4. **Context Awareness** - Chatbot understands the full page context, not just visible viewport

## Testing

To test this feature:

1. **Load the shop page** with filters applied (e.g., minimum 25% discount)
2. **Scroll to top** so some matching products are below the fold
3. **Ask the chatbot** about those products
4. **Verify** the chatbot mentions they need to scroll down

Example test query:
- "Show me shoes with at least 25% discount"
- "Which shoes have the best deals?"
- "Are there any running shoes on sale?"

## Architecture Impact

### Data Flow
```
User scrolls/loads page
         ↓
DOM Capture Service categorizes all products
         ↓
Visible products + Below-fold products captured
         ↓
Sent to AI Service with chat message
         ↓
Context Provider formats both sections
         ↓
AI receives full page context
         ↓
AI responds with scroll guidance when needed
```

### Performance Considerations

- **Minimal overhead**: Only adds Set operations and position checks
- **Efficient tracking**: Uses existing Intersection Observer API
- **No additional API calls**: All done client-side
- **Token impact**: Moderate increase in prompt size (proportional to product count)

## Future Enhancements

Possible improvements:
1. Track products "above the fold" (user scrolled past)
2. Estimate scroll distance ("scroll down about 2 screens")
3. Add scroll-to-product functionality in UI
4. Highlight recommended products when user scrolls

## Files Modified

1. `frontend/src/types.ts` - Added `below_fold_products` to DOMSnapshot
2. `frontend/src/utils/domCapture.ts` - Enhanced tracking logic
3. `services/ai-service/services/context_provider.py` - Updated context formatting
4. `services/ai-service/services/chat_service.py` - Enhanced system prompt

## Migration Notes

**Breaking Changes:** None - backward compatible

**Deployment:** 
1. Frontend changes require rebuild (`npm run build`)
2. Backend changes require Python service restart
3. No database schema changes needed
4. No environment variable changes needed

---

**Implementation Date:** November 26, 2025  
**Feature Status:** ✅ Complete and ready for testing
