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
                - page_url: Current page URL
                - timestamp: Snapshot timestamp
        
        Returns:
            Formatted context string for the AI model
        """
        visible_products = data.get("visible_products", [])
        page_url = data.get("page_url", "Unknown")
        
        if not visible_products:
            return "No products are currently visible on the user's screen."
        
        # Format product information
        context_parts = [
            f"User is viewing {len(visible_products)} products on page: {page_url}",
            "\nVisible products:"
        ]
        
        for idx, product in enumerate(visible_products, 1):
            product_info = [
                f"{idx}. {product.get('name', 'Unknown Product')}"
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
    """Placeholder for future screenshot-based context (GPT-4 Vision)"""
    
    async def get_context(self, data: Dict[str, Any]) -> str:
        """Extract context from screenshots using GPT-4 Vision"""
        # TODO: Implement screenshot analysis with GPT-5 vision
        return "Screenshot analysis not yet implemented."


class AccessibilityTreeProvider(ContextProvider):
    """Placeholder for future accessibility tree context"""
    
    async def get_context(self, data: Dict[str, Any]) -> str:
        """Extract context from accessibility tree"""
        # TODO: Implement accessibility tree parsing
        return "Accessibility tree analysis not yet implemented."
