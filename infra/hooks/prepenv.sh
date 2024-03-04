echo "Loading azd .env file from current environment"

# Use the `get-values` azd command to retrieve environment variables from the `.env` file
while IFS='=' read -r key value; do
    value=$(echo "$value" | sed 's/^"//' | sed 's/"$//' | sed 's/\"//g')
    export "$key=$value"
done <<EOF
$(azd env get-values) 
EOF

echo "Setting up environment variables in .env file..."
# Save output values to variables
openAiService=$AZURE_OPENAI_NAME
searchService=$AZURE_SEARCH_NAME
cosmosService=$AZURE_COSMOS_NAME
searchEndpoint=$AZURE_SEARCH_ENDPOINT
openAiEndpoint=$AZURE_OPENAI_ENDPOINT
cosmosEndpoint=$AZURE_COSMOS_ENDPOINT
mlProjectName=$AZURE_ML_PROJECT_NAME
resourceGroupName=$RESOURCE_GROUP_NAME

# Get keys from services
searchKey=$(az search admin-key show --service-name $searchService --resource-group $resourceGroupName --query primaryKey --output tsv)
apiKey=$(az cognitiveservices account keys list --name $openAiService --resource-group $resourceGroupName --query key1 --output tsv)
cosmosKey=$(az cosmosdb keys list --name $cosmosService --resource-group $resourceGroupName --query primaryMasterKey --output tsv)

echo "CONTOSO_SEARCH_ENDPOINT=$searchEndpoint" >> ../../.env
echo "CONTOSO_AI_SERVICES_ENDPOINT=$openAiEndpoint" >> ../../.env
echo "COSMOS_ENDPOINT=$cosmosEndpoint" >> ../../.env
echo "CONTOSO_SEARCH_KEY=$searchKey" >> ../../.env
echo "CONTOSO_AI_SERVICES_KEY=$apiKey" >> ../../.env
echo "COSMOS_KEY=$cosmosKey" >> ../../.env

echo 'Installing dependencies from "requirements.txt"'
python -m pip install -r ../../requirements.txt

# Create connections
python ../../connections/create-connections.py