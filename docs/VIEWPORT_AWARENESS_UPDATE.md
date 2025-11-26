# 🔍 Viewport Awareness Enhancement

## Overview

Enhanced the chatbot to track products in three visibility zones based on scroll position:
1. **Visible** - Products currently on screen
2. **Above the fold** - Products the user has scrolled past (require scrolling up)
3. **Below the fold** - Products not yet visible (require scrolling down)

This allows the chatbot to guide users more effectively by saying things like "scroll up to see..." or "scroll down to find..."

## Problem Statement

**Before:** When users asked about products with specific criteria (e.g., "shoes with at least 25% discount"), the chatbot only knew about products currently visible in the viewport. If matching products were above or below the visible area, the chatbot would incorrectly say they don't exist.

**After:** The chatbot now tracks ALL products on the page and can tell users:
- Which matching products are currently visible
- Which matching products require scrolling up to see (already viewed)
- Which matching products require scrolling down to see

## Technical Changes

### 1. Frontend - TypeScript Types (`frontend/src/types.ts`)

**Added:**
```typescript
export interface DOMSnapshot {
  visible_products: Array<{...}>;
  above_fold_products: Array<{...}>; // Products scrolled past (above viewport)
  below_fold_products: Array<{...}>; // Products not yet visible (below viewport)
  page_url: string;
  timestamp: number;
}
```

### 2. Frontend - DOM Capture Service (`frontend/src/utils/domCapture.ts`)

**Enhanced tracking with three zones:**
- Added `visibleProducts` Set to track products currently on screen
- Added `aboveFoldProducts` Set to track products scrolled past
- Added `belowFoldProducts` Set to track products below the viewport
- Added `productElements` Map to store references to all product DOM elements
- Modified Intersection Observer callback to categorize products based on `getBoundingClientRect()`
- Updated `captureSnapshot()` to return visible, above-fold, and below-fold products

**Key logic:**
```typescript
if (entry.isIntersecting) {
  // Product is now visible
  this.visibleProducts.add(productId);
  this.aboveFoldProducts.delete(productId);
  this.belowFoldProducts.delete(productId);
} else {
  this.visibleProducts.delete(productId);
  const rect = entry.target.getBoundingClientRect();
  if (rect.bottom < 0) {
    // Product is above the viewport (scrolled past)
    this.aboveFoldProducts.add(productId);
  } else if (rect.top > window.innerHeight) {
    // Product is below the viewport (not yet scrolled to)
    this.belowFoldProducts.add(productId);
  }
}
```

### 3. Backend - Context Provider (`services/ai-service/services/context_provider.py`)

**Enhanced context formatting with three sections:**
```python
# Format visible products
🔍 VISIBLE PRODUCTS (currently on screen):
1. Product Name | Category: ... | Price: $... | Discount: ...%

# Format above-fold products (scrolled past)
⬆️ ABOVE THE FOLD (X products - user scrolled past these):
1. Product Name | Category: ... | Price: $... | Discount: ...%

# Format below-fold products  
⬇️ BELOW THE FOLD (X products - require scrolling down):
1. Product Name | Category: ... | Price: $... | Discount: ...%
```

### 4. Backend - AI System Prompt (`services/ai-service/services/chat_service.py`)

**Added instructions:**
```
VIEWPORT AWARENESS:
You will receive information about THREE types of products based on scroll position:
1. 🔍 VISIBLE PRODUCTS - Currently visible on the user's screen
2. ⬆️ ABOVE THE FOLD - Products the user has already scrolled past
3. ⬇️ BELOW THE FOLD - Products that require scrolling down

When answering questions:
- ALWAYS check ALL THREE sections when answering questions about availability
- If products matching the criteria are VISIBLE, list them in a "Currently Visible" section
- If products matching the criteria are ABOVE THE FOLD, list them in an "Above (Scroll Up)" section
- If products matching the criteria are BELOW THE FOLD, list them in a "Below (Scroll Down)" section
- Use phrases like "scroll up to see..." and "scroll down to see..." appropriately
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

### Currently Visible:
No shoes with 25%+ discount are visible right now.

### ⬆️ Scroll Up:
• **Classic Leather Oxford** - 30% off, now $111.99 (was $159.99)

### ⬇️ Scroll Down:
• **Trail Runner Pro** - 30% off, now $69.99 (was $99.99)
• **Urban Comfort Sneakers** - 25% off, now $67.49 (was $89.99)

✨ Click any product name to scroll directly to it!"
✅ CORRECT - Guides user to scroll in both directions
```

## Benefits

1. **Accurate Responses** - No longer tells users products don't exist when they're just off-screen
2. **Bi-directional Navigation** - Guides users to scroll up OR down as needed
3. **Improved UX** - Users know exactly where to find matching products
4. **Complete Context Awareness** - Chatbot understands all products on the page regardless of scroll position
5. **Click-to-Scroll** - Users can click product names to jump directly to them

## Testing

To test this feature:

1. **Load the shop page** with many products visible
2. **Scroll to the middle** so some products are above and below the fold
3. **Ask the chatbot** about products
4. **Verify** the chatbot correctly categorizes products in all three zones

Example test queries:
- "Show me shoes with at least 25% discount"
- "Which shoes have the best deals?"
- "List all athletic shoes"
- "What's the most expensive shoe on this page?"

## Architecture Impact

### Data Flow
```
User scrolls/loads page
         ↓
DOM Capture Service tracks all products
         ↓
Products categorized: Visible | Above Fold | Below Fold
         ↓
Snapshot sent to AI Service with chat message
         ↓
Context Provider formats all three sections
         ↓
AI receives complete page context
         ↓
AI responds with appropriate scroll guidance
```

### Three-Zone Tracking
```
         ⬆️ ABOVE THE FOLD (scrolled past)
    ═══════════════════════════════════
         🔍 VISIBLE (currently on screen)
    ═══════════════════════════════════
         ⬇️ BELOW THE FOLD (not yet visible)
```

### Performance Considerations

- **Minimal overhead**: Only adds Set operations and position checks
- **Efficient tracking**: Uses existing Intersection Observer API
- **No additional API calls**: All done client-side
- **Token impact**: Moderate increase in prompt size (proportional to product count)

## Future Enhancements

Possible improvements:
1. ~~Track products "above the fold" (user scrolled past)~~ ✅ DONE
2. Estimate scroll distance ("scroll down about 2 screens")
3. ~~Add scroll-to-product functionality in UI~~ ✅ DONE (Click-to-scroll feature)
4. ~~Highlight recommended products when user scrolls~~ ✅ DONE (Product highlighting animation)

## Files Modified

1. `frontend/src/types.ts` - Added `above_fold_products` and `below_fold_products` to DOMSnapshot
2. `frontend/src/utils/domCapture.ts` - Enhanced tracking logic for three zones
3. `services/ai-service/services/context_provider.py` - Updated context formatting for three sections
4. `services/ai-service/services/chat_service.py` - Enhanced system prompt with three-zone awareness

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
