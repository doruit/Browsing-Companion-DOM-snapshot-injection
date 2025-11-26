from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Azure OpenAI
    azure_openai_endpoint: str
    azure_openai_api_key: str
    azure_openai_deployment_name: str = "gpt-5"
    
    # Cosmos DB
    cosmos_endpoint: str
    cosmos_connection_string: str
    cosmos_database_name: str = "browsing-companion-db"
    
    # Azure Storage
    azure_storage_connection_string: str
    
    # Application Insights
    applicationinsights_connection_string: str = ""
    
    # Service Configuration
    service_port: int = 8000
    environment: str = "development"
    
    class Config:
        env_file = ".env.local"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()
