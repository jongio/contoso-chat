import os
from pathlib import Path

from promptflow import PFClient
from promptflow.entities import (
    AzureOpenAIConnection,
    CustomConnection,
    CognitiveSearchConnection,
)
from dotenv import load_dotenv

load_dotenv()

pf = PFClient()

# Create local Azure OpenAI Connection
AOAI_KEY= os.environ["CONTOSO_AI_SERVICES_KEY"]
AOAI_ENDPOINT= os.environ["CONTOSO_AI_SERVICES_ENDPOINT"]
connection = AzureOpenAIConnection(
    name="aoai-connection",
    api_key=AOAI_KEY,
    api_base=AOAI_ENDPOINT,
    api_type="azure",
    api_version="2023-07-01-preview",
)

print(f"Creating connection {connection.name}...")
result = pf.connections.create_or_update(connection)
print(result)

# Create the local contoso-cosmos connection
COSMOS_ENDPOINT = os.environ["COSMOS_ENDPOINT"]
COSMOS_KEY = os.environ["COSMOS_KEY"]
connection = CustomConnection(
    name="contoso-cosmos",
    configs={
        "endpoint": COSMOS_ENDPOINT,
        "databaseId": "contoso-outdoor",
        "containerId": "customers",
    },
    secrets={"key": COSMOS_KEY},
)

print(f"Creating connection {connection.name}...")
result = pf.connections.create_or_update(connection)
print(result)

# Create the local contoso-search connection
SEARCH_ENDPOINT = os.environ["CONTOSO_SEARCH_ENDPOINT"]
SEARCH_KEY = os.environ["CONTOSO_SEARCH_KEY"]
connection = CognitiveSearchConnection(
    name="contoso-search",
    api_key=SEARCH_KEY,
    api_base=SEARCH_ENDPOINT,
    api_version="2023-07-01-preview",
)

print(f"Creating connection {connection.name}...")
result = pf.connections.create_or_update(connection)
print(result)

