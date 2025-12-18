import asyncio
import os
import sys
# Add parent dir to path so we can import services
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from services.chat_service import ChatService
    from dotenv import load_dotenv
except ImportError as e:
    print(f"ImportError: {e}")
    print("Make sure you are running in the venv and installing requirements.")
    sys.exit(1)

# Mock context
mock_user_id = "debug-user"
mock_message = "Hello"

async def main():
    try:
        print("--- Debug Start ---")
        
        # Load env
        # File is at: services/ai-service/debug_run.py
        # dirname -> services/ai-service
        # dirname -> services
        # dirname -> root
        current_dir = os.path.dirname(os.path.abspath(__file__))
        root_dir = os.path.dirname(os.path.dirname(current_dir))
        env_path = os.path.join(root_dir, '.env.local')
        print(f"Loading env from: {env_path}")
        load_dotenv(env_path)
        
        # OVERRIDE: Test alternative endpoint format
        # Current (failed): https://aif-brow-comp-dev-qi3kpd.cognitiveservices.azure.com/agents/v1.0/projects/prj-brow-comp-dev
        # Proposal: https://<account>.services.ai.azure.com/api/projects/<project>
        
        # Hardcoded for test
        test_endpoint = "https://aif-brow-comp-dev-qi3kpd.services.ai.azure.com/api/projects/prj-brow-comp-dev"
        print(f"TESTING ENDPOINT OVERRIDE: {test_endpoint}")
        os.environ['AI_FOUNDRY_PROJECT_ENDPOINT'] = test_endpoint
        
        # Check critical vars
        print(f"AI_FOUNDRY_PROJECT_ENDPOINT: {os.environ.get('AI_FOUNDRY_PROJECT_ENDPOINT')}")
        print(f"COSMOS_CONNECTION_STRING: {os.environ.get('COSMOS_CONNECTION_STRING')[:20]}...")
        
        print("Initializing ChatService...")
        service = ChatService()
        print("ChatService initialized.")
        
        print("Processing chat...")
        response = await service.process_chat(mock_user_id, mock_message)
        print("Response received:", response)
        print("--- Debug Success ---")
    except Exception as e:
        print("\n--- CAUGHT EXCEPTION ---")
        import traceback
        traceback.print_exc()
        print("--- End Exception ---")

if __name__ == "__main__":
    asyncio.run(main())
