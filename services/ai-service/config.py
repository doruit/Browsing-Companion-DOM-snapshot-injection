from pydantic_settings import BaseSettings
from functools import lru_cache
import logging


# Configure logging to sanitize sensitive data
class SensitiveDataFilter(logging.Filter):
    """Filter to prevent logging of sensitive information"""
    SENSITIVE_PATTERNS = [
        'api_key', 'apikey', 'key=', 'password', 'secret', 'token',
        'AccountKey=', 'InstrumentationKey=', 'connection_string'
    ]
    
    def filter(self, record):
        msg = str(record.msg).lower()
        # Block any log message containing sensitive patterns
        return not any(pattern.lower() in msg for pattern in self.SENSITIVE_PATTERNS)


# Apply filter to all loggers
logging.basicConfig(level=logging.INFO)
for handler in logging.root.handlers:
    handler.addFilter(SensitiveDataFilter())


class Settings(BaseSettings):
    # Microsoft Foundry (AI Foundry) Configuration
    # Using managed identity authentication (no API key needed)
    ai_foundry_project_endpoint: str
    ai_foundry_model_deployment_name: str = "gpt-4o-mini"
    
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
