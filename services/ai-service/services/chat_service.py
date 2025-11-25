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
        self.openai_client = AzureOpenAI(
            api_key=settings.azure_openai_api_key,
            api_version="2024-10-21",
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
        try:
            response = self.openai_client.chat.completions.create(
                model=settings.azure_openai_deployment_name,
                messages=messages,
                temperature=0.7,
                max_tokens=800
            )
            
            assistant_message = response.choices[0].message.content
            
            # Store conversation
            if not session_id:
                session_id = str(uuid.uuid4())
            
            await self.store_message(session_id, user_id, "user", message)
            await self.store_message(session_id, user_id, "assistant", assistant_message)
            
            return {
                "response": assistant_message,
                "session_id": session_id,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            raise Exception(f"Error calling Azure OpenAI: {str(e)}")
    
    def _build_system_prompt(
        self,
        user_preferences: Dict[str, Any],
        dom_context: str
    ) -> str:
        """Build system prompt with user preferences and DOM context"""
        
        base_prompt = """You are a helpful shopping assistant for a shoe e-commerce website. 
Your role is to help users find the perfect shoes based on what they can see on their screen 
and their preferences."""
        
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
            base_prompt += "\n\nWhen answering questions, reference specific products that are visible on the user's screen."
        
        base_prompt += "\n\nBe concise, friendly, and focus on helping the user find shoes that match their needs."
        
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
