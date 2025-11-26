from typing import Dict, Any, List, Optional
from openai import AzureOpenAI
from azure.cosmos import CosmosClient, exceptions
from config import get_settings
from services.context_provider import DOMSnapshotProvider
import json
import uuid
from datetime import datetime

settings = get_settings()


class ChatService:
    def __init__(self):
        # Initialize Azure OpenAI client
        # Using 2024-10-01-preview for GPT-4o-mini support
        self.openai_client = AzureOpenAI(
            api_key=settings.azure_openai_api_key,
            api_version="2024-10-01-preview",
            azure_endpoint=settings.azure_openai_endpoint
        )
        
        # Initialize Cosmos DB client
        self.cosmos_client = CosmosClient.from_connection_string(
            settings.cosmos_connection_string
        )
        self.database = self.cosmos_client.get_database_client(settings.cosmos_database_name)
        self.chat_container = self.database.get_container_client("chat-sessions")
        self.preferences_container = self.database.get_container_client("preferences")
        
        # Initialize context provider
        self.context_provider = DOMSnapshotProvider()
    
    async def process_chat(
        self,
        user_id: str,
        message: str,
        dom_snapshot: Optional[Dict[str, Any]] = None,
        session_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Process a chat message with optional DOM context.
        
        Args:
            user_id: User identifier
            message: User's chat message
            dom_snapshot: Optional DOM snapshot data
            session_id: Optional session ID for conversation history
        
        Returns:
            Dictionary containing AI response and session info
        """
        # Get user preferences
        user_preferences = await self.get_user_preferences(user_id)
        
        # Extract DOM context if available
        dom_context = ""
        if dom_snapshot:
            dom_context = await self.context_provider.get_context(dom_snapshot)
        
        # Build system prompt with context
        system_prompt = self._build_system_prompt(user_preferences, dom_context)
        
        # Get conversation history if session exists
        conversation_history = []
        if session_id:
            conversation_history = await self.get_conversation_history(session_id)
        
        # Prepare messages for OpenAI
        messages = [
            {"role": "system", "content": system_prompt}
        ]
        
        # Add conversation history
        for msg in conversation_history[-10:]:  # Last 10 messages
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })
        
        # Add current user message
        messages.append({
            "role": "user",
            "content": message
        })
        
        # Call Azure OpenAI
        # GPT-4o-mini supports standard parameters including temperature
        try:
            response = self.openai_client.chat.completions.create(
                model=settings.azure_openai_deployment_name,
                messages=messages,
                max_tokens=800,
                temperature=0.7
            )
            
            assistant_message = response.choices[0].message.content
            
            # Debug logging
            print(f"OpenAI Response: {response}")
            print(f"Assistant message: {assistant_message}")
            print(f"Message type: {type(assistant_message)}")
            
            # Parse filter commands from response
            filters = self._extract_filters(assistant_message)
            
            # Remove the filters JSON block from the user-facing response
            clean_response = self._remove_filters_block(assistant_message)
            
            # Store conversation
            if not session_id:
                session_id = str(uuid.uuid4())
            
            await self.store_message(session_id, user_id, "user", message)
            await self.store_message(session_id, user_id, "assistant", clean_response)
            
            result = {
                "response": clean_response,
                "session_id": session_id,
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Add filters if found
            if filters:
                result["filters"] = filters
            
            return result
            
        except Exception as e:
            raise Exception(f"Error calling Azure OpenAI: {str(e)}")
    
    def _build_system_prompt(
        self,
        user_preferences: Dict[str, Any],
        dom_context: str
    ) -> str:
        """Build system prompt with user preferences and DOM context"""
        
        base_prompt = """You are a Smart Shopping Companion for a shoe e-commerce website. 
Your role is to help users find the perfect shoes based on what they can see on their screen 
and their preferences.

IMPORTANT FORMATTING RULES:
- Always use Markdown formatting in your responses
- Use emoticons to make responses friendly and engaging (👟 for shoes, ✨ for highlights, 💰 for prices, 🎯 for recommendations, ⚡ for quick facts)
- Structure responses with clear headings using ## and ###
- Use **bold** for product names and important information
- Use bullet points (•) or numbered lists for multiple items
- Use code blocks with backticks for prices or specific details
- Keep responses well-organized and easy to scan
- Add line breaks between sections for readability

VIEWPORT AWARENESS:
You will receive information about TWO types of products:
1. 🔍 VISIBLE PRODUCTS - Currently visible on the user's screen (no scrolling needed)
2. 📜 BELOW THE FOLD - Products that require scrolling down to see

When answering questions:
- ALWAYS check BOTH sections when answering questions about availability
- If products matching the criteria are VISIBLE, list them in a "Currently Visible" section
- If products matching the criteria are BELOW THE FOLD, list them in a separate "Below the Fold" section with a note that scrolling is needed
- Use phrases like "if you scroll down..." or "further down the page you'll find..." to introduce below-fold products
- IMPORTANT: If products meet the user's criteria (e.g., discount percentage, category, price), LIST them regardless of whether they're visible or below-fold
- Format below-fold products the same way as visible products, but group them separately

CLICKABLE PRODUCT LINKS:
When mentioning products, make product names clickable so users can scroll to them:
- Format: [Product Name](#product-id) where product-id is the product's ID (e.g., shoe-001, shoe-017)
- Example: [Patent Leather Heels](#shoe-017) - User can click to scroll and highlight
- ALWAYS include the product ID link when mentioning a specific product
- This works for both visible and below-fold products

DISCOUNT COMPARISON RULES - CRITICAL:
When users ask for discounts, you MUST filter correctly:
- "at least 25%" or "25% or more" = ONLY products with discount ≥ 25 (includes 25, 30, 35, etc.)
- "more than 25%" = ONLY products with discount > 25 (includes 30, 35, etc., but NOT 25)
- "25% discount" or "exactly 25%" = ONLY products with exactly 25% discount

PRICE COMPARISON RULES - CRITICAL:
When users ask about prices, you MUST check and list ALL matching products:
- "under $100" or "below $100" or "less than $100" = ALL products where price < 100
- "up to $100" or "$100 or less" = ALL products where price <= 100
- "over $100" or "above $100" or "more than $100" = ALL products where price > 100
- "between $50 and $100" = ALL products where 50 <= price <= 100

STRICT FILTERING - DO NOT SHOW NON-MATCHING PRODUCTS:
When a user specifies criteria (discount, price, category), you must ONLY show products that meet ALL criteria.

NEVER DO THIS:
- User asks for "25% off" → DO NOT show products with 0%, 10%, or 20% discount
- User asks for "casual shoes with 25% off" → DO NOT show casual shoes without 25%+ discount
- If no products match → Say "No products match your criteria" - do NOT list non-matching products as alternatives

ALWAYS DO THIS:
1. Filter by ALL criteria the user specified (category AND discount AND price, etc.)
2. Only list products that match EVERY criterion
3. If zero products match, clearly state that and ask if they want to adjust criteria
4. Never "helpfully" show products that don't match as if they do

FILTER CONTROL CAPABILITIES:
You can help users filter products by responding with filter commands. When users ask to filter products, include a JSON block in your response:

```filters
{
  "category": "casual",
  "min_price": 50,
  "max_price": 200,
  "has_discount": true,
  "min_discount": 10,
  "customer_type": "b2b",
  "in_stock": true
}
```

Available filters:
- category: formal, athletic, casual, outdoor, work, or empty for all
- min_price: minimum price (number)
- max_price: maximum price (number)
- has_discount: true/false/null for discounted items
- min_discount: minimum discount percentage (0-100)
- customer_type: "b2b", "b2c", or "all"
- in_stock: true/false/null for stock availability

Examples:
- "Show me discounted casual shoes" → set category="casual", has_discount=true
- "Filter by B2B shoes under $150" → set customer_type="b2b", max_price=150
- "Show shoes with at least 20% off" → set has_discount=true, min_discount=20

Example response format:
## 👟 Products I Can See

Here are the shoes currently visible on your screen:

• **Product Name** - Brief description
  - Price: `$XX.XX`
  - Category: Type
  - ✨ Special feature or discount

### 🎯 My Recommendation
Based on your preferences, I suggest..."""
        
        # Add user preferences
        if user_preferences:
            customer_type = "B2B business customer" if user_preferences.get("is_b2b") else "individual retail customer"
            base_prompt += f"\n\nCustomer Type: {customer_type}"
            
            if user_preferences.get("preferred_categories"):
                categories = ", ".join(user_preferences["preferred_categories"])
                base_prompt += f"\nPreferred Categories: {categories}"
            
            if user_preferences.get("hidden_categories"):
                hidden = ", ".join(user_preferences["hidden_categories"])
                base_prompt += f"\nCategories to avoid: {hidden}"
        
        # Add DOM context
        if dom_context:
            base_prompt += f"\n\n=== CURRENT PAGE CONTEXT ===\n{dom_context}\n=== END CONTEXT ==="
            base_prompt += "\n\nWhen answering questions, reference specific products that are visible on the user's screen using the formatting guidelines above."
        
        base_prompt += "\n\nRemember: Use Markdown, emoticons, and structured formatting to make your responses engaging and easy to read!"
        
        return base_prompt
    
    async def get_user_preferences(self, user_id: str) -> Dict[str, Any]:
        """Retrieve user preferences from Cosmos DB"""
        try:
            item = self.preferences_container.read_item(
                item=user_id,
                partition_key=user_id
            )
            return item
        except exceptions.CosmosResourceNotFoundError:
            # Return default preferences
            return {
                "userId": user_id,
                "is_b2b": False,
                "preferred_categories": [],
                "hidden_categories": []
            }
        except Exception as e:
            print(f"Error fetching preferences: {e}")
            return {}
    
    async def get_conversation_history(self, session_id: str) -> List[Dict[str, Any]]:
        """Retrieve conversation history for a session"""
        try:
            query = "SELECT * FROM c WHERE c.sessionId = @session_id ORDER BY c.timestamp ASC"
            items = list(self.chat_container.query_items(
                query=query,
                parameters=[{"name": "@session_id", "value": session_id}],
                enable_cross_partition_query=True
            ))
            return items
        except Exception as e:
            print(f"Error fetching conversation history: {e}")
            return []
    
    def _remove_filters_block(self, message: str) -> str:
        """Remove the filters JSON block from the response to keep it clean for users"""
        import re
        
        # Remove ```filters ... ``` blocks
        filter_pattern = r'```filters\s*\n.*?\n```\s*'
        clean_message = re.sub(filter_pattern, '', message, flags=re.DOTALL)
        
        # Clean up any extra blank lines
        clean_message = re.sub(r'\n{3,}', '\n\n', clean_message)
        
        return clean_message.strip()
    
    def _extract_filters(self, message: str) -> Optional[Dict[str, Any]]:
        """Extract filter commands from assistant message"""
        import re
        
        # Look for ```filters ... ``` blocks
        filter_pattern = r'```filters\s*\n(.*?)\n```'
        match = re.search(filter_pattern, message, re.DOTALL)
        
        if match:
            try:
                filters_json = match.group(1)
                filters = json.loads(filters_json)
                
                # Validate and clean filters
                valid_filters = {}
                
                if "category" in filters and filters["category"] and filters["category"] not in ["empty", "null", ""]:
                    valid_filters["category"] = filters["category"]
                
                if "min_price" in filters and filters["min_price"] is not None:
                    try:
                        valid_filters["min_price"] = float(filters["min_price"])
                    except (ValueError, TypeError):
                        pass
                
                if "max_price" in filters and filters["max_price"] is not None:
                    try:
                        valid_filters["max_price"] = float(filters["max_price"])
                    except (ValueError, TypeError):
                        pass
                
                if "has_discount" in filters and filters["has_discount"] is not None:
                    valid_filters["has_discount"] = bool(filters["has_discount"])
                
                if "min_discount" in filters and filters["min_discount"] is not None:
                    try:
                        valid_filters["min_discount"] = float(filters["min_discount"])
                    except (ValueError, TypeError):
                        pass
                
                if "customer_type" in filters:
                    if filters["customer_type"] in ["all", "b2b", "b2c"]:
                        valid_filters["customer_type"] = filters["customer_type"]
                
                if "in_stock" in filters and filters["in_stock"] is not None:
                    valid_filters["in_stock"] = bool(filters["in_stock"])
                
                return valid_filters if valid_filters else None
            except (json.JSONDecodeError, ValueError) as e:
                print(f"Error parsing filters: {e}")
                return None
        
        return None
    
    async def store_message(
        self,
        session_id: str,
        user_id: str,
        role: str,
        content: str
    ):
        """Store a message in conversation history"""
        try:
            message = {
                "id": str(uuid.uuid4()),
                "sessionId": session_id,
                "userId": user_id,
                "role": role,
                "content": content,
                "timestamp": datetime.utcnow().isoformat()
            }
            self.chat_container.create_item(body=message)
        except Exception as e:
            print(f"Error storing message: {e}")


class PreferencesService:
    def __init__(self):
        self.cosmos_client = CosmosClient.from_connection_string(
            settings.cosmos_connection_string
        )
        self.database = self.cosmos_client.get_database_client(settings.cosmos_database_name)
        self.container = self.database.get_container_client("preferences")
    
    async def get_preferences(self, user_id: str) -> Dict[str, Any]:
        """Get user preferences"""
        try:
            item = self.container.read_item(
                item=user_id,
                partition_key=user_id
            )
            return item
        except exceptions.CosmosResourceNotFoundError:
            return {
                "userId": user_id,
                "is_b2b": False,
                "preferred_categories": [],
                "hidden_categories": []
            }
    
    async def update_preferences(self, user_id: str, preferences: Dict[str, Any]) -> Dict[str, Any]:
        """Update user preferences"""
        preferences["userId"] = user_id
        preferences["id"] = user_id
        self.container.upsert_item(body=preferences)
        return preferences
