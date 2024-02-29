param appInsightId string
param containerRegistryId string
param contosoChatSfAIName string = 'contoso-chat-sf-ai'
param contosoChatSfAiprojName string = 'contoso-chat-sf-aiproj'
param keyVaultId string
param location string
param openAIEndpoint string
param openAIName string
param searchName string
param storageAccountId string

// In ai.azure.com: Azure AI Resource
resource mlHub 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: contosoChatSfAIName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Hub' 
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: contosoChatSfAIName
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: appInsightId
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    v1LegacyMode: false
    containerRegistry: containerRegistryId
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://swedencentral.api.azureml.ms/discovery'
  }

  resource openaiDefaultEndpoint 'endpoints' = {
    name: 'Azure.OpenAI'
    properties: {
      name: 'Azure.OpenAI'
      endpointType: 'Azure.OpenAI'
      associatedResourceId: openai.id
    }
  }

  resource contentSafetyDefaultEndpoint 'endpoints' = {
    name: 'Azure.ContentSafety'
    properties: {
      name: 'Azure.ContentSafety'
      endpointType: 'Azure.ContentSafety'
      associatedResourceId: openai.id
    }
  }

  resource openaiConnection 'connections' = {
    name: 'aoai-connection'
    properties: {
      category: 'AzureOpenAI'
      target: openAIEndpoint
      authType: 'ApiKey'
      metadata: {
          ApiVersion: '2023-07-01-preview'
          ApiType: 'azure'
          ResourceId: openai.id
      }
      credentials: {
        key: openai.listKeys().key1
      }
    }
  }

  resource searchConnection 'connections' = {
    name: 'contoso-search'
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${search.name}.search.windows.net/'
      authType: 'ApiKey'
      credentials: {
        key: search.listAdminKeys().primaryKey
      }
    }
  }
}

// In ai.azure.com: Azure AI Project
resource mlProject 'Microsoft.MachineLearningServices/workspaces@2023-10-01' = {
  name: contosoChatSfAiprojName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: contosoChatSfAiprojName
    hbiWorkspace: false
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    discoveryUrl: 'https://swedencentral.api.azureml.ms/discovery'
    // most properties are not allowed for a project workspace: "Project workspace shouldn't define ..."
    hubResourceId: mlHub.id
  }
}

resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAIName
}

resource search 'Microsoft.Search/searchServices@2021-04-01-preview' existing = {
  name: searchName
}

output ml_hub_name string = mlHub.name
output ml_project_name string = mlProject.name
