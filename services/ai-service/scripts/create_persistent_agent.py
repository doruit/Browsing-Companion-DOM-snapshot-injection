#!/usr/bin/env python3
"""
Script to create a persistent agent in Azure AI Foundry.

This agent will be visible in the Foundry portal and can be managed there.
Run this script once to create the agent, then use its ID in the chat service.
"""

import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from azure.identity import AzureCliCredential
from azure.ai.projects import AIProjectClient
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent.parent / ".env.local"
load_dotenv(env_path)

# Agent configuration
AGENT_NAME = "BrowsingCompanionAgent"
AGENT_INSTRUCTIONS = """You are a Smart Shopping Companion for a shoe e-commerce website. 
Your role is to help users find the perfect shoes based on what they can see on their screen 
and their preferences.

IMPORTANT FORMATTING RULES:
- Always use Markdown formatting in your responses
- Use emoticons to make responses friendly and engaging (👟 for shoes, ✨ for highlights, 💰 for prices, 🎯 for recommendations)
- Structure responses with clear headings using ## and ###
- Use **bold** for product names and important information
- Use bullet points for multiple items
- Keep responses well-organized and easy to scan

You are helpful, friendly, and knowledgeable about footwear."""


def main():
    # Get configuration from environment
    project_endpoint = os.environ.get("AI_FOUNDRY_PROJECT_ENDPOINT")
    model_deployment = os.environ.get("AI_FOUNDRY_MODEL_DEPLOYMENT_NAME", "gpt-4o-mini")
    
    if not project_endpoint:
        print("Error: AI_FOUNDRY_PROJECT_ENDPOINT environment variable not set")
        print("Make sure .env.local exists and contains the correct values")
        sys.exit(1)
    
    print(f"Project Endpoint: {project_endpoint}")
    print(f"Model Deployment: {model_deployment}")
    print(f"Agent Name: {AGENT_NAME}")
    print()
    
    # Use Azure CLI credential (you should be logged in via `az login`)
    credential = AzureCliCredential()
    
    # Create project client
    print("Connecting to Azure AI Foundry...")
    project_client = AIProjectClient(
        endpoint=project_endpoint,
        credential=credential,
    )
    
    with project_client:
        # List existing agents to check if one already exists
        print("Checking for existing agents...")
        agents = list(project_client.agents.list())
        
        existing_agent = None
        for agent in agents:
            print(f"  Found agent: {agent.name} (ID: {agent.id})")
            if agent.name == AGENT_NAME:
                existing_agent = agent
        
        if existing_agent:
            print(f"\n✅ Agent '{AGENT_NAME}' already exists!")
            print(f"   Agent ID: {existing_agent.id}")
            print(f"\nTo use this agent, set the following in your .env.local:")
            print(f"   AI_FOUNDRY_AGENT_ID={existing_agent.id}")
        else:
            # Create new persistent agent
            print(f"\nCreating new agent '{AGENT_NAME}'...")
            agent = project_client.agents.create_agent(
                model=model_deployment,
                name=AGENT_NAME,
                instructions=AGENT_INSTRUCTIONS,
            )
            print(f"\n✅ Agent created successfully!")
            print(f"   Agent ID: {agent.id}")
            print(f"   Agent Name: {agent.name}")
            print(f"\nTo use this agent, add the following to your .env.local:")
            print(f"   AI_FOUNDRY_AGENT_ID={agent.id}")
        
        print("\n📋 The agent should now be visible in the Azure AI Foundry portal.")


if __name__ == "__main__":
    main()
