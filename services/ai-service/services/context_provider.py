from abc import ABC, abstractmethod
from typing import Dict, Any, List
import json


class ContextProvider(ABC):
    """Abstract base class for context providers"""
    
    @abstractmethod
    async def get_context(self, data: Dict[str, Any]) -> str:
        """Extract and format context from provided data"""
        pass


class DOMSnapshotProvider(ContextProvider):
    """Provides context from DOM snapshots of visible products"""
    
    async def get_context(self, data: Dict[str, Any]) -> str:
        """
        Format DOM snapshot data into a readable context string.
        
        Args:
            data: Dictionary containing:
                - visible_products: List of products visible in viewport
                - below_fold_products: List of products below the fold (require scrolling)
                - page_url: Current page URL
                - timestamp: Snapshot timestamp
        
        Returns:
            Formatted context string for the AI model
        """
        visible_products = data.get("visible_products", [])
        below_fold_products = data.get("below_fold_products", [])
        page_url = data.get("page_url", "Unknown")
        
        # Debug logging
        print(f"\n=== DOM SNAPSHOT DEBUG ===")
        print(f"Visible products: {len(visible_products)}")
        print(f"Below fold products: {len(below_fold_products)}")
        for p in visible_products:
            print(f"  VISIBLE: {p.get('name')} - Price: ${p.get('price', 0)} - Discount: {p.get('discount', 0)}%")
        for p in below_fold_products:
            print(f"  BELOW: {p.get('name')} - Price: ${p.get('price', 0)} - Discount: {p.get('discount', 0)}%")
        print(f"=========================\n")
        
        context_parts = []
        
        # Format visible products
        if visible_products:
            context_parts.append(f"User is currently viewing {len(visible_products)} products on page: {page_url}")
            context_parts.append("\n🔍 VISIBLE PRODUCTS (currently on screen):")
            
            for idx, product in enumerate(visible_products, 1):
                product_info = [
                    f"{idx}. {product.get('name', 'Unknown Product')} (ID: {product.get('id', 'unknown')})"
                ]
                
                if product.get('category'):
                    product_info.append(f"Category: {product['category']}")
                
                if product.get('price'):
                    product_info.append(f"Price: ${product['price']}")
                
                if product.get('discount'):
                    product_info.append(f"Discount: {product['discount']}% off")
                
                if product.get('description'):
                    product_info.append(f"Description: {product['description']}")
                
                context_parts.append(" | ".join(product_info))
        else:
            context_parts.append("No products are currently visible on the user's screen.")
        
        # Format below-fold products
        if below_fold_products:
            context_parts.append(f"\n📜 BELOW THE FOLD ({len(below_fold_products)} products require scrolling down):")
            
            for idx, product in enumerate(below_fold_products, 1):
                product_info = [
                    f"{idx}. {product.get('name', 'Unknown Product')} (ID: {product.get('id', 'unknown')})"
                ]
                
                if product.get('category'):
                    product_info.append(f"Category: {product['category']}")
                
                if product.get('price'):
                    product_info.append(f"Price: ${product['price']}")
                
                if product.get('discount'):
                    product_info.append(f"Discount: {product['discount']}% off")
                
                if product.get('description'):
                    product_info.append(f"Description: {product['description']}")
                
                context_parts.append(" | ".join(product_info))
        
        return "\n".join(context_parts)


class ScreenshotProvider(ContextProvider):
    """Placeholder for future screenshot-based context (GPT-4o Vision)"""
    
    async def get_context(self, data: Dict[str, Any]) -> str:
        """Extract context from screenshots using GPT-4o Vision"""
        # TODO: Implement screenshot analysis with GPT-4o vision
        return "Screenshot analysis not yet implemented."


class AccessibilityTreeProvider(ContextProvider):
    """Placeholder for future accessibility tree context"""
    
    async def get_context(self, data: Dict[str, Any]) -> str:
        """Extract context from accessibility tree"""
        # TODO: Implement accessibility tree parsing
        return "Accessibility tree analysis not yet implemented."
